import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colours ───────────────────────────────────────────────
  // Neumorphism requires background matches surface, so we elevate deepBlack.
  static const Color deepBlack = Color(0xFF14171E);
  static const Color surface = Color(0xFF1B1E26);
  static const Color surfaceLight = Color(0xFF222731);
  static const Color amberFire = Color(0xFFFF7849);
  static const Color amberFireLight = Color(0xFFFFAA85);
  static const Color warmIvory = Color(0xFFE2D4C0);
  static const Color mutedTeal = Color(0xFF4A7FA5);
  static const Color neumorphicDarkShadow = Color(0xFF12141A);
  static const Color neumorphicLightShadow = Color(0xFF262A36);
  static const Color errorRed = Color(0xFFEF4444);

  // ─── Gradient Presets ────────────────────────────────────────────
  static const LinearGradient amberGradient = LinearGradient(
    colors: [amberFire, Color(0xFFFF9A76)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkFadeBottom = LinearGradient(
    colors: [Colors.transparent, deepBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Text Styles (standalone, for non-themed usage) ──────────────
  static TextStyle get displayTitle => GoogleFonts.cormorantGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: warmIvory,
      );

  static TextStyle get heading => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: warmIvory,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: warmIvory,
      );

  static TextStyle get transcript => GoogleFonts.notoSerifDevanagari(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        color: warmIvory,
      );

  static TextStyle get mono => GoogleFonts.ibmPlexMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: mutedTeal,
      );

  // ─── Theme Data ──────────────────────────────────────────────────
  static NeumorphicThemeData get darkNeumorphicTheme {
    return NeumorphicThemeData(
      baseColor: surface,
      lightSource: LightSource.topLeft,
      depth: 6,
      intensity: 0.65,
      shadowDarkColorEmboss: neumorphicDarkShadow,
      shadowLightColorEmboss: neumorphicLightShadow,
      shadowDarkColor: neumorphicDarkShadow,
      shadowLightColor: neumorphicLightShadow,
      appBarTheme: NeumorphicAppBarThemeData(
        color: surface,
        buttonStyle: const NeumorphicStyle(
          depth: 4,
          intensity: 0.8,
          boxShape: NeumorphicBoxShape.circle(),
        ),
        textStyle: GoogleFonts.cormorantGaramond(
          color: warmIvory,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        iconTheme: const IconThemeData(color: warmIvory),
      ),
      defaultTextColor: warmIvory,
      accentColor: amberFire,
      variantColor: mutedTeal,
      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      primaryColor: amberFire,

      colorScheme: const ColorScheme.dark(
        primary: amberFire,
        onPrimary: Colors.white,
        secondary: mutedTeal,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: warmIvory,
        error: errorRed,
        onError: Colors.white,
      ),

      splashColor: amberFire.withValues(alpha: 0.08),
      highlightColor: amberFire.withValues(alpha: 0.04),

      textTheme: TextTheme(
        // Display — Cormorant Garamond (screen hero titles)
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: warmIvory,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: warmIvory,
        ),
        displaySmall: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: warmIvory,
        ),

        // Title — Plus Jakarta Sans (section headings)
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: warmIvory,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: warmIvory,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: warmIvory.withValues(alpha: 0.9),
        ),

        // Body — Plus Jakarta Sans (readable content)
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: warmIvory,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: warmIvory.withValues(alpha: 0.8),
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: warmIvory.withValues(alpha: 0.6),
        ),

        // Label — IBM Plex Mono (metadata, timestamps)
        labelLarge: GoogleFonts.ibmPlexMono(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mutedTeal,
        ),
        labelMedium: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: mutedTeal,
        ),
        labelSmall: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: mutedTeal,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          color: warmIvory,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        iconTheme: const IconThemeData(color: warmIvory),
      ),

      iconTheme: const IconThemeData(color: warmIvory, size: 24),

      sliderTheme: SliderThemeData(
        activeTrackColor: amberFire,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        thumbColor: amberFire,
        overlayColor: amberFire.withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: amberFire,
        linearTrackColor: Colors.transparent,
      ),
    );
  }
}
