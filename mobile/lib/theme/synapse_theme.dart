import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "The Kinetic Glass Ethos" Design System
/// Pixel-perfect from Stitch Monitor IA Pro Trading Dashboard.
///
/// Typography: Space Grotesk (headlines/prices) + Inter (body/labels)
/// Glass: rgba(53,53,52,0.4) + blur(24px) + border white 5%
/// No 1px solid borders for sectioning — use tonal shifts + luminous depth.
class SynapseTheme {
  // ═══════════════════════════════════════════
  //  PALETTE — "The Kinetic Observatory"
  // ═══════════════════════════════════════════

  // Foundations
  static const Color surface = Color(0xFF131313);
  static const Color background = Color(0xFF131313);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceBright = Color(0xFF3A3939);
  static const Color surfaceVariant = Color(0xFF353534);

  // Primary — Success / Buy / Profit
  static const Color primaryContainer = Color(0xFF00FF88);  // Electric Green
  static const Color primaryFixedDim = Color(0xFF00E479);   // Surface Tint
  static const Color primaryFixed = Color(0xFF60FF99);
  static const Color primary = Color(0xFFF1FFEF);           // Almost-white green tint
  static const Color onPrimary = Color(0xFF003919);
  static const Color onPrimaryContainer = Color(0xFF007139);

  // Secondary — Alert / Sell / Loss
  static const Color secondaryContainer = Color(0xFFD5033C);  // Vibrant Red CTA
  static const Color secondary = Color(0xFFFFB3B5);            // Light red text
  static const Color secondaryFixedDim = Color(0xFFFFB3B5);
  static const Color onSecondary = Color(0xFF680018);

  // Tertiary — Info / Accent
  static const Color tertiaryFixedDim = Color(0xFF00DAF8);
  static const Color tertiaryContainer = Color(0xFF96ECFF);

  // Text
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFB9CBB9);
  static const Color outlineVariant = Color(0xFF3B4B3D);
  static const Color outline = Color(0xFF849585);

  // Legacy aliases (backwards compat)
  static const Color electricGreen = primaryContainer;
  static const Color crimsonPulse = secondaryContainer;
  static const Color gold = Color(0xFFD4AF37);

  // ═══════════════════════════════════════════
  //  GLASS RECIPE — "Kinetic Glass Ethos"
  // ═══════════════════════════════════════════
  //  Background: rgba(53, 53, 52, 0.4)
  //  Backdrop-filter: blur(24px)
  //  Border: 1px solid rgba(255, 255, 255, 0.05)
  //  Glow: box-shadow 0 0 15px rgba(0,255,136, 0.2) for success

  static const double glassBlur = 24.0;
  static Color glassBackground = const Color(0xFF353534).withOpacity(0.4);
  static Color glassBorder = Colors.white.withOpacity(0.05);
  static Color glassBorderHover = Colors.white.withOpacity(0.15);

  // ═══════════════════════════════════════════
  //  THEME DATA
  // ═══════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primaryContainer,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiaryFixedDim,
        error: Color(0xFFFFB4AB),
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: _buildTextTheme(),
      cardTheme: CardThemeData(
        color: surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryContainer,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryContainer,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TYPOGRAPHY — Space Grotesk + Inter
  // ═══════════════════════════════════════════
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display — large price points (Space Grotesk)
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -2,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: onSurface,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: onSurface,
      ),
      // Headlines — section titles (Space Grotesk)
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      // Titles — functional headings (Inter)
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Body — functional data (Inter)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      // Labels (Inter)
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: onSurfaceVariant,
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  HELPER — Headline text style (for inline use)
  // ═══════════════════════════════════════════
  static TextStyle headline({
    num fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color color = onSurface,
    num letterSpacing = 0,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize.toDouble(),
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing.toDouble(),
    );
  }

  static TextStyle label({
    num fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color color = onSurfaceVariant,
    num letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize.toDouble(),
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing.toDouble(),
    );
  }
}
