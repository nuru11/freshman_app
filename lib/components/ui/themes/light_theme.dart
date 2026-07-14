import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_academy/models/models.dart';

// Campus Academic palette — distinct from Entrance Tricks indigo/purple
Color primaryColor = const Color(0xFF0B5F56);
Color primaryVariant = const Color(0xFF084840);
Color secondaryColor = const Color(0xFFC48A1A);
Color secondaryVariant = const Color(0xFFA37112);
Color surfaceColor = const Color(0xFFFFFFFF);
Color backgroundColor = const Color(0xFFF7F4EF);
Color headerBackgroundColor = const Color(0xFFF7F4EF);
const Color borderColor = Color(0xFFE7E2D9);
const errorColor = Color(0xFFEF4444);
const warningColor = Color(0xFFC48A1A);
const successColor = Color(0xFF0B5F56);
const infoColor = Color(0xFF0EA5E9);

const darkColor = Color(0xFF1C1917);
const darkVariant = Color(0xFF0C0A09);
const onSurfaceColor = Color(0xFF292524);
const onSurfaceVariant = Color(0xFF78716C);

Color _parseHexColor(String? value, Color fallback) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  final hex = value.replaceAll('#', '').trim();
  if (hex.length != 6 && hex.length != 8) {
    return fallback;
  }

  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final colorValue = int.tryParse(normalized, radix: 16);
  if (colorValue == null) {
    return fallback;
  }
  return Color(colorValue);
}

Color _darken(Color color, [double amount = 0.15]) {
  final hsl = HSLColor.fromColor(color);
  final adjusted = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return adjusted.toColor();
}

void applyDynamicPalette(AppBranding? appBranding) {
  if (appBranding == null) {
    return;
  }

  primaryColor = _parseHexColor(appBranding.primaryColor, primaryColor);
  secondaryColor = _parseHexColor(appBranding.secondaryColor, secondaryColor);
  backgroundColor = _parseHexColor(appBranding.backgroundColor, backgroundColor);
  surfaceColor = _parseHexColor(appBranding.surfaceColor, surfaceColor);
  headerBackgroundColor = _parseHexColor(
    appBranding.headerBackgroundColor,
    headerBackgroundColor,
  );
  primaryVariant = _darken(primaryColor);
  secondaryVariant = _darken(secondaryColor);
}

ThemeData lightTheme(BuildContext context) {
  final jakarta = GoogleFonts.plusJakartaSansTextTheme();
  final fraunces = GoogleFonts.frauncesTextTheme();

  final textTheme = jakarta.copyWith(
    displayLarge: fraunces.displayLarge?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: darkColor,
      letterSpacing: -0.5,
    ),
    displayMedium: fraunces.displayMedium?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: darkColor,
    ),
    displaySmall: fraunces.displaySmall?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: darkColor,
    ),
    headlineLarge: fraunces.headlineLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: darkColor,
    ),
    headlineMedium: fraunces.headlineMedium?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: darkColor,
    ),
    headlineSmall: fraunces.headlineSmall?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: darkColor,
    ),
    titleLarge: jakarta.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: darkColor,
    ),
    titleMedium: jakarta.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: darkColor,
    ),
    titleSmall: jakarta.titleSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: darkColor,
    ),
    bodyLarge: jakarta.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: onSurfaceColor,
      height: 1.5,
    ),
    bodyMedium: jakarta.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: onSurfaceColor,
      height: 1.5,
    ),
    bodySmall: jakarta.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: onSurfaceVariant,
      height: 1.4,
    ),
    labelLarge: jakarta.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: onSurfaceColor,
    ),
    labelMedium: jakarta.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: onSurfaceColor,
    ),
    labelSmall: jakarta.labelSmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: onSurfaceVariant,
      letterSpacing: 0.4,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryColor.withValues(alpha: 0.12),
      secondary: secondaryColor,
      secondaryContainer: secondaryColor.withValues(alpha: 0.14),
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: onSurfaceColor,
      onSurfaceVariant: onSurfaceVariant,
      onError: Colors.white,
      outline: borderColor,
      shadow: darkColor.withValues(alpha: 0.06),
    ),
    textTheme: textTheme,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: surfaceColor,
    dividerColor: borderColor,
    appBarTheme: AppBarTheme(
      backgroundColor: headerBackgroundColor,
      foregroundColor: darkColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: darkColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      labelStyle: TextStyle(
        color: onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: onSurfaceVariant.withValues(alpha: 0.8),
        fontWeight: FontWeight.w400,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: borderColor),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: primaryColor.withValues(alpha: 0.14),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? primaryColor : onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? primaryColor : onSurfaceVariant,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      selectedColor: secondaryColor.withValues(alpha: 0.18),
      side: const BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: primaryColor.withValues(alpha: 0.15),
      circularTrackColor: primaryColor.withValues(alpha: 0.15),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
