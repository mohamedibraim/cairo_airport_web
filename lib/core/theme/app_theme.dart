import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import 'tokens.dart';

ThemeData buildAppTheme(AppStrings s) {
  final colorScheme = const ColorScheme.light(
    primary: AppColors.action,
    onPrimary: Colors.white,
    primaryContainer: AppColors.tealSoft,
    onPrimaryContainer: AppColors.navy,
    secondary: AppColors.primary,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.border,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: s.fontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.page,
    visualDensity: VisualDensity.compact,
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.major),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 24,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.soft,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.action, width: 1.6),
      ),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.action,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.action,
        minimumSize: const Size(0, 44),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.action,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.soft,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
    ),
    textTheme: _textTheme(),
  );
}

TextTheme _textTheme() {
  const base = TextStyle(color: AppColors.text, height: 1.35);
  return TextTheme(
    displaySmall: base.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
    headlineSmall: base.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
    titleLarge: base.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
    titleMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
    titleSmall: base.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
    bodyLarge: base.copyWith(fontSize: 14),
    bodyMedium: base.copyWith(fontSize: 13),
    bodySmall: base.copyWith(fontSize: 11, color: AppColors.muted),
    labelLarge: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    labelMedium: base.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    labelSmall: base.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
  );
}
