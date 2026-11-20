import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cairo_airport_web/core/l10n/strings.dart';
import 'package:cairo_airport_web/core/theme/app_theme.dart';
import 'package:cairo_airport_web/core/theme/tokens.dart';
import 'package:cairo_airport_web/core/widgets/badges.dart';
import 'package:cairo_airport_web/core/widgets/data_table.dart';
import 'package:cairo_airport_web/core/widgets/details_panel.dart';

void main() {
  group('Phase 01 tokens', () {
    test('palette uses the approved hex values', () {
      expect(AppColors.canvas.toARGB32(), 0xFFF5F7FA);
      expect(AppColors.surface.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.surfaceSoft.toARGB32(), 0xFFF8FAFB);
      expect(AppColors.surfaceHover.toARGB32(), 0xFFF2F7F8);
      expect(AppColors.surfaceSelected.toARGB32(), 0xFFEAF5F5);
      expect(AppColors.border.toARGB32(), 0xFFDCE5EA);
      expect(AppColors.divider.toARGB32(), 0xFFE5ECF1);
      expect(AppColors.sidebar.toARGB32(), 0xFF183448);
      expect(AppColors.sidebarHover.toARGB32(), 0xFF24485C);
      expect(AppColors.sidebarSelected.toARGB32(), 0xFF2B5262);
      expect(AppColors.sidebarText.toARGB32(), 0xFFF7FAFC);
      expect(AppColors.sidebarMuted.toARGB32(), 0xFFADC2CD);
      expect(AppColors.primary.toARGB32(), 0xFF0B8588);
      expect(AppColors.primaryStrong.toARGB32(), 0xFF08666B);
      expect(AppColors.textPrimary.toARGB32(), 0xFF243746);
      expect(AppColors.error.toARGB32(), 0xFFAD4141);
    });

    test('typography scale matches the specification', () {
      expect(AppTypography.display.fontSize, 32);
      expect(AppTypography.pageTitle.fontSize, 28);
      expect(AppTypography.sectionTitle.fontSize, 20);
      expect(AppTypography.cardTitle.fontSize, 16);
      expect(AppTypography.bodyPrimary.fontSize, 14);
      expect(AppTypography.tableText.fontSize, 13);
      expect(AppTypography.buttonText.fontSize, 13);
      expect(AppTypography.label.fontSize, 12);
      expect(AppTypography.metadata.fontSize, 12);
      expect(AppTypography.kpiValue.fontSize, 30);
      expect(
        AppTypography.kpiValue.fontFeatures?.any((f) => f.feature == 'tnum'),
        isTrue,
      );
    });

    test('spacing, radius and elevation are tokenized', () {
      expect(AppSpace.space1, 4);
      expect(AppSpace.space6, 24);
      expect(AppSpace.space7, 32);
      expect(AppSpace.space10, 64);
      expect(AppRadius.card, 14);
      expect(AppRadius.panel, 16);
      expect(AppRadius.dialog, 18);
      expect(AppShadows.level1.first.offset, const Offset(0, 2));
      expect(AppShadows.level2.first.blurRadius, 24);
      expect(AppShadows.level3.first.offset, const Offset(0, 16));
    });

    test('semantic mapping keeps legacy status colours safe', () {
      expect(AppTones.from(AppColors.success).text, AppColors.success);
      expect(AppTones.from(AppColors.danger).background, AppColors.errorSoft);
      expect(AppTones.from(AppColors.action).text, AppColors.primaryStrong);
      expect(AppTones.from(AppColors.unknown).background, AppColors.neutralSoft);
    });
  });

  group('ThemeData integration', () {
    test('theme consumes tokens and switches font by locale', () {
      final arabic = buildAppTheme(const AppStrings(arabic: true));
      final english = buildAppTheme(const AppStrings(arabic: false));

      expect(arabic.textTheme.displaySmall?.fontFamily, 'Cairo');
      expect(english.textTheme.displaySmall?.fontFamily, 'Inter');
      expect(arabic.scaffoldBackgroundColor, AppColors.canvas);
      expect(arabic.colorScheme.primary, AppColors.primaryStrong);
      expect(arabic.textTheme.displaySmall?.fontSize, 28);
      expect(arabic.textTheme.bodySmall?.fontSize, 12);

      final cardShape = arabic.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(AppRadius.card));
      expect(arabic.cardTheme.elevation, 0);
    });
  });

  group('Shared components', () {
    testWidgets('StatusPill renders semantic text and soft background',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusPill(label: 'Operational', color: AppColors.success),
        ),
      ));

      final label = tester.widget<Text>(find.text('Operational'));
      expect(label.style?.color, AppColors.success);
      expect(label.style?.fontSize, 12);

      final background = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == AppColors.successSoft,
        ),
      );
      expect(background, isNotNull);
    });

    testWidgets('LtrText forces Inter for identifiers', (tester) async {
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.rtl,
        child: LtrText('MS561'),
      ));

      final text = tester.widget<Text>(find.text('MS561'));
      expect(text.style?.fontFamily, 'Inter');
      expect(
        text.style?.fontFeatures?.any((f) => f.feature == 'tnum'),
        isTrue,
      );
      expect(
        Directionality.of(tester.element(find.text('MS561'))),
        TextDirection.ltr,
      );
    });

    testWidgets('AppTable keeps the 44px header and horizontal scroll',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppTable(
            columns: [AppTableColumn('Flight')],
            rows: [
              AppTableRow(cells: [Text('MS561')]),
            ],
          ),
        ),
      ));

      final headerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.color == AppColors.surfaceSoft,
      );
      final header = tester.widget<Container>(headerFinder);
      expect(header.color, AppColors.surfaceSoft);
      expect(tester.getSize(headerFinder).height, 44);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('DetailsPanel applies elevation 2 and 340px minimum width',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DetailsPanel(title: 'Inspector'),
        ),
      ));

      final constrained = tester.widget<ConstrainedBox>(
        find.byWidgetPredicate(
          (w) =>
              w is ConstrainedBox && w.constraints.minWidth == 340,
        ),
      );
      expect(constrained.constraints.minWidth, 340);
      expect(constrained.constraints.maxWidth, 420);

      final panel = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).boxShadow == AppShadows.level2,
        ),
      );
      expect(panel, isNotNull);
    });
  });
}
