import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppAccentOption {
  final String name;
  final Color color;

  const AppAccentOption({
    required this.name,
    required this.color,
  });
}

class AppTheme {
  // Brand Color Tokens — Warm Korean Minimalist Base Palette
  static const Color textMain = Color(0xFF1C1917); // Dark stone
  static const Color textMuted = Color(0xFF78716C); // Muted stone
  static const Color textLight = Color(0xFFA8A29E); // Soft grey

  static const Color defaultAccent = Color(0xFFE76F51); // Default warm terracotta
  static const Color accentTerracotta = Color(0xFFE76F51); // Terracotta alias
  static const Color accentAmber = Color(0xFFD97706); // Warm highlight amber
  static const Color accentOrange = Color(0xFFEA580C); // Warm alert orange
  static const Color accentDanger = Color(0xFFDC2626); // Danger red
  static const Color accentGreen = Color(0xFF2D6A4F); // Soft match green
  static const Color bgGreenLight = Color(0xFFE8F5E9); // Light match badge
  
  static const Color glassBorder = Color(0x66FFFFFF); // Glassmorphism white border

  // Preset Accent Color Selection Palette (including B&W Monochrome)
  static const List<AppAccentOption> accentPresets = [
    AppAccentOption(name: 'Terracotta', color: Color(0xFFE76F51)),
    AppAccentOption(name: 'Amber', color: Color(0xFFD97706)),
    AppAccentOption(name: 'Persimmon', color: Color(0xFFC05621)),
    AppAccentOption(name: 'Berry', color: Color(0xFF7C3AED)),
    AppAccentOption(name: 'Matcha', color: Color(0xFF2D6A4F)),
    AppAccentOption(name: 'Olive', color: Color(0xFF556B2F)),
    AppAccentOption(name: 'Indigo', color: Color(0xFF1E3A8A)),
    AppAccentOption(name: 'Black', color: Color(0xFF1C1917)),
  ];

  // Dynamic Background Derivation Engine based on Accent Color
  static Color getPrimaryBg(Color accentColor) {
    if (accentColor.toARGB32() == const Color(0xFF1C1917).toARGB32()) {
      return const Color(0xFFFAFAFA); // Crisp studio white for B&W theme
    }
    final hsl = HSLColor.fromColor(accentColor);
    return hsl.withLightness(0.975).withSaturation((hsl.saturation * 0.35).clamp(0.05, 0.30)).toColor();
  }

  static Color getCardBg(Color accentColor) {
    if (accentColor.toARGB32() == const Color(0xFF1C1917).toARGB32()) {
      return const Color(0xFFF4F4F5); // Crisp studio light grey for B&W theme
    }
    final hsl = HSLColor.fromColor(accentColor);
    return hsl.withLightness(0.94).withSaturation((hsl.saturation * 0.40).clamp(0.08, 0.35)).toColor();
  }

  static Color getSubtleBg(Color accentColor) {
    if (accentColor.toARGB32() == const Color(0xFF1C1917).toARGB32()) {
      return const Color(0xFFE4E4E7);
    }
    final hsl = HSLColor.fromColor(accentColor);
    return hsl.withLightness(0.91).withSaturation((hsl.saturation * 0.40).clamp(0.08, 0.35)).toColor();
  }

  static Color getGlassBg(Color accentColor) {
    final bg = getPrimaryBg(accentColor);
    return bg.withValues(alpha: 0.88);
  }

  // Fallbacks for static references
  static const Color bgPrimary = Color(0xFFFAF7F2);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFF5F0EB);
  static const Color bgSubtle = Color(0xFFEFEBE4);
  static const Color glassBg = Color(0xD9FAF7F2);

  // Helper to inject CJK fallback into every TextStyle
  static TextStyle? _withCjkFallback(TextStyle? style) {
    if (style == null) return null;
    return style.copyWith(
      fontFamilyFallback: [
        GoogleFonts.notoSansKr().fontFamily!,
        'Noto Sans',
        'sans-serif',
      ],
    );
  }

  static TextTheme _applyFallbacks(TextTheme theme) {
    return TextTheme(
      displayLarge: _withCjkFallback(theme.displayLarge),
      displayMedium: _withCjkFallback(theme.displayMedium),
      displaySmall: _withCjkFallback(theme.displaySmall),
      headlineLarge: _withCjkFallback(theme.headlineLarge),
      headlineMedium: _withCjkFallback(theme.headlineMedium),
      headlineSmall: _withCjkFallback(theme.headlineSmall),
      titleLarge: _withCjkFallback(theme.titleLarge),
      titleMedium: _withCjkFallback(theme.titleMedium),
      titleSmall: _withCjkFallback(theme.titleSmall),
      bodyLarge: _withCjkFallback(theme.bodyLarge),
      bodyMedium: _withCjkFallback(theme.bodyMedium),
      bodySmall: _withCjkFallback(theme.bodySmall),
      labelLarge: _withCjkFallback(theme.labelLarge),
      labelMedium: _withCjkFallback(theme.labelMedium),
      labelSmall: _withCjkFallback(theme.labelSmall),
    );
  }

  static ThemeData buildTheme(Color accentColor) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final bgPri = getPrimaryBg(accentColor);
    final bgCrd = getCardBg(accentColor);

    final styledTextTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: textMain,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: textMain,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: textMain,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: textMain,
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: textMuted,
        height: 1.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: textMain,
        fontWeight: FontWeight.w600,
      ),
    );

    final textThemeWithFallbacks = _applyFallbacks(styledTextTheme);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgPri,
      colorScheme: ColorScheme.light(
        surface: bgSurface,
        primary: accentColor,
        secondary: accentColor,
        onSurface: textMain,
        onPrimary: Colors.white,
      ),
      textTheme: textThemeWithFallbacks,
      chipTheme: ChipThemeData(
        backgroundColor: bgCrd,
        selectedColor: accentColor,
        secondarySelectedColor: accentColor,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: bgCrd,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgPri,
        selectedItemColor: accentColor,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.6,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgPri,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textMain),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => buildTheme(defaultAccent);
}
