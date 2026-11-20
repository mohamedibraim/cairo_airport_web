import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import 'tokens.dart';

ThemeData buildAppTheme(AppStrings s) {
  final colorScheme = const ColorScheme.light(
    primary: AppColors.primaryStrong,
    onPrimary: AppColors.textOnDark,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.primary,
    onSecondary: AppColors.textOnDark,
    secondaryContainer: AppColors.surfaceSelected,
    onSecondaryContainer: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    error: AppColors.error,
    onError: AppColors.textOnDark,
    surfaceTint: Colors.transparent,
  );

  final buttonRadius = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: s.fontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    canvasColor: AppColors.canvas,
    visualDensity: VisualDensity.standard,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: AppSpace.space6,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppSpace.space3,
      ),
      hintStyle: AppTypography.metadata.copyWith(color: AppColors.textTertiary),
      labelStyle: AppTypography.label.copyWith(color: AppColors.textSecondary),
      floatingLabelStyle: AppTypography.label.copyWith(
        color: AppColors.primaryStrong,
      ),
      border: _inputBorder(AppColors.border),
      enabledBorder: _inputBorder(AppColors.border),
      focusedBorder: _inputBorder(AppColors.primary, width: 2),
      errorBorder: _inputBorder(AppColors.error),
      focusedErrorBorder: _inputBorder(AppColors.error, width: 2),
      disabledBorder: _inputBorder(AppColors.divider),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.neutralSoft;
          if (states.contains(WidgetState.pressed)) return AppColors.primaryPressed;
          if (states.contains(WidgetState.hovered)) return AppColors.primaryHover;
          return AppColors.primaryStrong;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.textDisabled;
          return AppColors.textOnDark;
        }),
        minimumSize: WidgetStateProperty.all(const Size(0, 42)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppSpace.space4),
        ),
        shape: WidgetStateProperty.all(buttonRadius),
        textStyle: WidgetStateProperty.all(AppTypography.buttonText),
        elevation: WidgetStateProperty.all(0),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) return AppColors.surfaceHover;
          return AppColors.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.textDisabled;
          return AppColors.textPrimary;
        }),
        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
          if (states.contains(WidgetState.hovered)) {
            return const BorderSide(color: AppColors.primaryBorder);
          }
          return const BorderSide(color: AppColors.border);
        }),
        minimumSize: WidgetStateProperty.all(const Size(0, 42)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppSpace.space4),
        ),
        shape: WidgetStateProperty.all(buttonRadius),
        textStyle: WidgetStateProperty.all(AppTypography.buttonText),
        elevation: WidgetStateProperty.all(0),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.textDisabled;
          return AppColors.primaryStrong;
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) return AppColors.primarySoft;
          return Colors.transparent;
        }),
        minimumSize: WidgetStateProperty.all(const Size(0, 42)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppSpace.space3),
        ),
        shape: WidgetStateProperty.all(buttonRadius),
        textStyle: WidgetStateProperty.all(AppTypography.buttonText),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.textSecondary),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) return AppColors.surfaceHover;
          return Colors.transparent;
        }),
        minimumSize: WidgetStateProperty.all(const Size(40, 40)),
        shape: WidgetStateProperty.all(buttonRadius),
        iconSize: WidgetStateProperty.all(18),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceSoft,
      selectedColor: AppColors.surfaceSelected,
      disabledColor: AppColors.neutralSoft,
      showCheckmark: false,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      labelStyle: AppTypography.label,
      secondaryLabelStyle: AppTypography.label.copyWith(
        color: AppColors.primaryStrong,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.space3,
        vertical: AppSpace.space2,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      textStyle: AppTypography.metadata.copyWith(color: AppColors.textOnDark),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.space3,
        vertical: AppSpace.space2,
      ),
      waitDuration: const Duration(milliseconds: 400),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      titleTextStyle: AppTypography.sectionTitle.copyWith(
        color: AppColors.textPrimary,
      ),
      contentTextStyle: AppTypography.bodyPrimary.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primaryStrong,
      selectionColor: AppColors.primarySoft,
      selectionHandleColor: AppColors.primaryStrong,
    ),
    textTheme: _textTheme(),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
    borderSide: BorderSide(color: color, width: width),
  );
}

TextTheme _textTheme() {
  return TextTheme(
    displayLarge: AppTypography.display.copyWith(color: AppColors.textPrimary),
    displayMedium: AppTypography.display.copyWith(color: AppColors.textPrimary),
    displaySmall: AppTypography.pageTitle.copyWith(color: AppColors.textPrimary),
    headlineMedium: AppTypography.display.copyWith(color: AppColors.textPrimary),
    headlineSmall: AppTypography.kpiValue.copyWith(color: AppColors.textPrimary),
    titleLarge: AppTypography.cardTitle.copyWith(color: AppColors.textPrimary),
    titleMedium: AppTypography.sectionTitle.copyWith(
      color: AppColors.textPrimary,
    ),
    titleSmall: AppTypography.bodyEmphasis.copyWith(color: AppColors.textPrimary),
    bodyLarge: AppTypography.bodyPrimary.copyWith(color: AppColors.textPrimary),
    bodyMedium: AppTypography.bodyPrimary.copyWith(color: AppColors.textPrimary),
    bodySmall: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
    labelLarge: AppTypography.buttonText.copyWith(color: AppColors.textPrimary),
    labelMedium: AppTypography.label.copyWith(color: AppColors.textSecondary),
    labelSmall: AppTypography.metadata.copyWith(color: AppColors.textTertiary),
  );
}
