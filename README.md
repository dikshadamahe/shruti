# Shruti

Shruti is a **non-profit, ad-free** mobile app delivering a Spotify-grade audio experience for Osho's teachings, with **real-time synced transcript scrolling**.

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| State | Riverpod 2.x |
| Backend | Firebase (Firestore + Storage) |
| Audio | just_audio + audio_service |
| AI | faster-whisper (local) |
| Scraper | Python on Cloud Run |

## Team

| Dev | GitHub | Role |
|---|---|---|
| Diksha | [@dikshadamahe](https://github.com/dikshadamahe) | Backend, Audio Engine, Infra |
| Pracheer | [@pracheersrivastava](https://github.com/pracheersrivastava) | Frontend, UI/UX, Transcripts |

## Project Structure

```
shruti/
├── flutter_app/     ← Flutter project (Android + iOS)
├── scraper/         ← Python scraper (Cloud Run)
├── ai_pipeline/     ← Local AI transcription (never deployed)
├── firebase/        ← Firestore & Storage rules
└── docs/            ← KT document & design refs
```

## Getting Started

```bash
cd flutter_app
flutter pub get
flutter run
```

## License

Non-profit educational use only.
