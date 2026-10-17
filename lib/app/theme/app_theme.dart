import 'package:flutter/material.dart';

/// Colors for the Shader Studio dark theme.
///
/// The palette stays near-black with a teal accent so the shaders, not the
/// chrome, carry the color. Widgets should read these constants instead of
/// inventing nearby hex values.
abstract final class AppColors {
  static const background = Color(0xFF080B10);
  static const surface = Color(0xFF111720);
  static const surfaceHigh = Color(0xFF18202C);
  static const accent = Color(0xFF14E6CF);
  static const accentSecondary = Color(0xFF4DBBFF);
  static const text = Color(0xFFF4F7FB);
  static const textMuted = Color(0xFF9AA6B2);
  static const border = Color(0xFF243041);
  static const danger = Color(0xFFFF8B7B);
}

/// Material 3 theme used by the Shader Studio root widget.
///
/// Controls inherit the teal accent so sliders and switches match the shader
/// palette without a second visual system.
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accent,
      onPrimary: Color(0xFF04221E),
      secondary: AppColors.accentSecondary,
      onSecondary: Color(0xFF041824),
      onSurface: AppColors.text,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        thumbColor: AppColors.accent,
        inactiveTrackColor: AppColors.border,
        overlayColor: Color(0x3314E6CF),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x6614E6CF);
          }
          return AppColors.surfaceHigh;
        }),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: AppColors.text, height: 1.45),
        bodySmall: TextStyle(color: AppColors.textMuted, height: 1.4),
        labelLarge: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
