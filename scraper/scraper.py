import requests
from requests.adapters import HTTPAdapter
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore
import logging
import json
from datetime import datetime
import os
from urllib3.util.retry import Retry

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OshoScraper:
    def __init__(self):
        self.base_url = "https://oshoworld.com"
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        retries = Retry(
            total=3,
            connect=3,
            read=3,
            backoff_factor=0.5,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET", "HEAD"],
        )
        adapter = HTTPAdapter(max_retries=retries)
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)
        self.db = self._init_firebase()

    def _init_firebase(self):
        """Initializes Firebase Admin SDK."""
        sa_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
        if not firebase_admin._apps:
            cred = credentials.Certificate(sa_path)
            firebase_admin.initialize_app(cred)
        return firestore.client()

    def scrape_catalog(self, catalog_url):
        """Scrapes the main series catalog and starts scraping each series."""
        logger.info(f"Starting catalog scrape: {catalog_url}")
        try:
            response = self.session.get(catalog_url, timeout=15)
            soup = BeautifulSoup(response.text, 'lxml')
            
            script_tag = soup.find("script", id="__NEXT_DATA__")
            if not script_tag:
                logger.error("Could not find __NEXT_DATA__ in catalog")
                return

            data = json.loads(script_tag.string)
            page_data = data.get('props', {}).get('pageProps', {}).get('data', {}).get('pageData', {})
            series_list = page_data.get('items', [])

            if not series_list:
                logger.warning("No series found in catalog items")
                return

            for series_info in series_list:
                title = series_info.get('title')
                slug = series_info.get('slug')
                image_relative = series_info.get('image')
                
                if not slug: continue
                
                series_id = slug
                series_url = f"{self.base_url}/{slug}"
                # Construct thumbnail image url
                image_url = ""
                if image_relative:
                    if image_relative.startswith('http'):
                        image_url = image_relative
                    else:
                        image_url = f"{self.base_url}/{image_relative}"
                
                series_data = {
                    'title': title,
                    'slug': slug,
                    'cover_image_url': image_url,
                    'discourse_count': series_info.get('count', 0),
                    'language': page_data.get('language', 'hi'),
                }
                
                # Update Series metadata
                logger.info(f"Syncing series: {title} ({slug})")
                self.db.collection('series').document(series_id).set(series_data, merge=True)
                
                # Scrape tracks for this series
                self.scrape_series_details(series_url, series_id, series_data)

        except Exception as e:
            logger.error(f"Error scraping catalog: {e}")

    def scrape_series_details(self, series_url, series_id, series_data):
        """Scrapes tracks for a specific series using __NEXT_DATA__."""
        logger.info(f"  Scraping tracks for: {series_data['title']}")
        
        try:
            response = self.session.get(series_url, timeout=15)
            soup = BeautifulSoup(response.text, 'lxml')
            
            script_tag = soup.find("script", id="__NEXT_DATA__")
            if not script_tag:
                logger.error(f"    No __NEXT_DATA__ for {series_url}")
                return

            data = json.loads(script_tag.string)
            page_data = data.get('props', {}).get('pageProps', {}).get('data', {}).get('pageData', {})
            tracks_data = page_data.get('listData', [])
            
            if not tracks_data:
                logger.warning(f"    No tracks found for series {series_id}")
                return

            discourses_ref = self.db.collection('series').document(series_id).collection('discourses')
            
            synced_count = 0
            for track_info in tracks_data:
                title = track_info.get('title')
                relative_file = track_info.get('file') # Correct field name from Next.js data
                if not relative_file: continue
                
                audio_url = f"{self.base_url}{relative_file}"
                duration_str = track_info.get('duration', '00:00:00')
                
                # Convert duration HH:MM:SS to seconds
                try:
                    parts = list(map(int, duration_str.split(':')))
                    if len(parts) == 3:
                        h, m, s = parts
                        duration_seconds = h * 3600 + m * 60 + s
                    elif len(parts) == 2:
                        m, s = parts
                        duration_seconds = m * 60 + s
                    else:
                        duration_seconds = 0
                except:
                    duration_seconds = 0

                track_number = track_info.get('audio_index', synced_count + 1)
                # Use a track number based ID to keep it stable
                track_doc_id = str(track_number).zfill(3)
                is_broken = self.check_url_broken(audio_url)

                if is_broken is None:
                    existing_data = discourses_ref.document(track_doc_id).get().to_dict() or {}
                    is_broken = existing_data.get('is_broken', False)
                    logger.warning(
                        "    Could not verify audio URL for %s track %s. Preserving is_broken=%s",
                        series_id,
                        track_doc_id,
                        is_broken,
                    )
                elif is_broken:
                    logger.warning(
                        "    Broken audio URL detected for %s track %s: %s",
                        series_id,
                        track_doc_id,
                        audio_url,
                    )
                
                discourse_data = {
                    'track_number': track_number,
                    'title': title,
                    'audio_url': audio_url,
                    'duration_seconds': duration_seconds,
                    'is_broken': is_broken,
                    'has_transcript': False,
                    'url_last_verified': datetime.now()
                }

                discourses_ref.document(track_doc_id).set(discourse_data, merge=True)
                synced_count += 1

            logger.info(f"    Successfully synced {synced_count} tracks for {series_id}")

        except Exception as e:
            logger.error(f"    Error scraping series {series_id}: {e}")

    def check_url_broken(self, url):
        """Verifies if an audio URL is still valid."""
        try:
            response = self.session.head(url, allow_redirects=True, timeout=5)
            # Some servers block HEAD, so we might need to handle 405 or other errors
            if response.status_code == 405:
                response = self.session.get(url, stream=True, timeout=5)
            if response.status_code in {404, 410}:
                return True
            if response.status_code >= 500:
                return None
            return False
        except requests.RequestException as exc:
            logger.warning("    URL verification failed for %s: %s", url, exc)
            return None

if __name__ == "__main__":
    scraper = OshoScraper()
    # Main Hindi Audio series home
    scraper.scrape_catalog("https://oshoworld.com/audio-series-home-hindi")
