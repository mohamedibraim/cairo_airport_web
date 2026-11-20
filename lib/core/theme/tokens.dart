import 'package:flutter/material.dart';

/// Phase 01 — Aviation Operations Workspace / Light Premium.
///
/// These tokens are the single source of truth for the whole application.
/// Legacy names are kept as aliases so existing features keep compiling while
/// new work should prefer the semantic names below.
abstract final class AppColors {
  // Main surfaces
  static const Color canvas = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFB);
  static const Color surfaceHover = Color(0xFFF2F7F8);
  static const Color surfaceSelected = Color(0xFFEAF5F5);
  static const Color border = Color(0xFFDCE5EA);
  static const Color divider = Color(0xFFE5ECF1);

  // Sidebar
  static const Color sidebar = Color(0xFF183448);
  static const Color sidebarHover = Color(0xFF24485C);
  static const Color sidebarSelected = Color(0xFF2B5262);
  static const Color sidebarText = Color(0xFFF7FAFC);
  static const Color sidebarMuted = Color(0xFFADC2CD);

  // Brand & actions
  static const Color primary = Color(0xFF0B8588);
  static const Color primaryHover = Color(0xFF096F73);
  static const Color primaryPressed = Color(0xFF075A5E);
  static const Color primaryStrong = Color(0xFF08666B);
  static const Color primarySoft = Color(0xFFE6F4F3);
  static const Color primaryBorder = Color(0xFFB9D9D8);

  // Text
  static const Color textPrimary = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF596D7B);
  static const Color textTertiary = Color(0xFF788B98);
  static const Color textDisabled = Color(0xFF94A3AE);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Semantic — success
  static const Color success = Color(0xFF247A5A);
  static const Color successSoft = Color(0xFFE9F6EF);
  static const Color successBorder = Color(0xFFBFE5D0);

  // Semantic — warning
  static const Color warning = Color(0xFF946112);
  static const Color warningSoft = Color(0xFFFFF5E7);
  static const Color warningBorder = Color(0xFFF1D8A6);

  // Semantic — error
  static const Color error = Color(0xFFAD4141);
  static const Color errorSoft = Color(0xFFFDEFEF);
  static const Color errorBorder = Color(0xFFF0CBCB);

  // Semantic — info
  static const Color info = Color(0xFF315E91);
  static const Color infoSoft = Color(0xFFEAF2FC);
  static const Color infoBorder = Color(0xFFC8DBF2);

  // Semantic — neutral
  static const Color neutral = Color(0xFF617581);
  static const Color neutralSoft = Color(0xFFF0F3F5);
  static const Color neutralBorder = Color(0xFFDCE4E8);

  // ---------------------------------------------------------------------------
  // Backward-compatible aliases. Prefer the semantic names above in new code.
  // `action` intentionally points to primaryStrong: it is used as accent text
  // and as a background for white text, where #0B8588 falls just under 4.5:1.
  // ---------------------------------------------------------------------------
  static const Color page = canvas;
  static const Color icy = primarySoft;
  static const Color soft = surfaceSoft;
  static const Color sidebarTop = sidebar;
  static const Color sidebarBottom = sidebar;
  static const Color onSidebar = sidebarText;
  static const Color onSidebarMuted = sidebarMuted;
  static const Color action = primaryStrong;
  static const Color navy = textPrimary;
  static const Color text = textPrimary;
  static const Color muted = textSecondary;
  static const Color tealSoft = primarySoft;
  static const Color danger = error;
  static const Color dangerSoft = errorSoft;
  static const Color unknown = neutral;
}

/// Text + background + optional border for a semantic state.
@immutable
class AppSemanticTone {
  final Color text;
  final Color background;
  final Color border;

  const AppSemanticTone({
    required this.text,
    required this.background,
    required this.border,
  });
}

abstract final class AppTones {
  static const AppSemanticTone primary = AppSemanticTone(
    text: AppColors.primaryStrong,
    background: AppColors.primarySoft,
    border: AppColors.primaryBorder,
  );
  static const AppSemanticTone success = AppSemanticTone(
    text: AppColors.success,
    background: AppColors.successSoft,
    border: AppColors.successBorder,
  );
  static const AppSemanticTone warning = AppSemanticTone(
    text: AppColors.warning,
    background: AppColors.warningSoft,
    border: AppColors.warningBorder,
  );
  static const AppSemanticTone error = AppSemanticTone(
    text: AppColors.error,
    background: AppColors.errorSoft,
    border: AppColors.errorBorder,
  );
  static const AppSemanticTone info = AppSemanticTone(
    text: AppColors.info,
    background: AppColors.infoSoft,
    border: AppColors.infoBorder,
  );
  static const AppSemanticTone neutral = AppSemanticTone(
    text: AppColors.neutral,
    background: AppColors.neutralSoft,
    border: AppColors.neutralBorder,
  );

  /// Keeps the public `color` API of StatusPill/InfoBanner while routing
  /// legacy colours to the correct soft palette.
  static AppSemanticTone from(Color color) {
    if (color == AppColors.success) return success;
    if (color == AppColors.warning) return warning;
    if (color == AppColors.error || color == AppColors.danger) return error;
    if (color == AppColors.info) return info;
    if (color == AppColors.primary ||
        color == AppColors.primaryStrong ||
        color == AppColors.action) {
      return primary;
    }
    return neutral;
  }
}

/// Typography scale in logical pixels. Font family is supplied by the active
/// locale (Cairo for Arabic, Inter for English) in ThemeData.
abstract final class AppTypography {
  static const TextStyle display = TextStyle(
    fontSize: 32,
    height: 1.30,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    height: 1.40,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyPrimary = TextStyle(
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyEmphasis = TextStyle(
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle tableText = TextStyle(
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle metadata = TextStyle(
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle kpiValue = TextStyle(
    fontSize: 30,
    height: 1.20,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Identifiers, times and numeric data are always Inter with tabular figures,
  /// even inside Arabic layouts.
  static const TextStyle numeric = TextStyle(
    fontFamily: 'Inter',
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

abstract final class AppSpace {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 48;
  static const double space10 = 64;

  // Legacy aliases
  static const double xs = space1;
  static const double sm = space2;
  static const double md = space3;
  static const double lg = space4;
  static const double xl = space6;
  static const double xxl = space7;

  // Named layout gaps
  static const double cardGap = space4;
  static const double sectionGap = space7;
  static const double fieldGap = space4;
  static const double labelGap = space2;
  static const double iconGap = 10;
  static const double metadataGap = 6;
  static const double maxPageWidth = 1560;

  static double pagePadding(double width) {
    if (width < AppBreakpoints.tablet) return space4;
    if (width < AppBreakpoints.smallDesktop) return space5;
    return 28;
  }
}

abstract final class AppRadius {
  static const double small = 6;
  static const double chip = 8;
  static const double control = 10;
  static const double card = 14;
  static const double panel = 16;
  static const double dialog = 18;
  static const double pill = 999;

  // Legacy aliases
  static const double major = card;
  static const double nested = panel;
}

abstract final class AppShadows {
  static const List<BoxShadow> none = <BoxShadow>[];
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F183448),
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(
      color: Color(0x17183448),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 6),
    ),
  ];
  static const List<BoxShadow> level3 = <BoxShadow>[
    BoxShadow(
      color: Color(0x24183448),
      blurRadius: 40,
      spreadRadius: 0,
      offset: Offset(0, 16),
    ),
  ];

  // Legacy aliases
  static const List<BoxShadow> card = level1;
  static const List<BoxShadow> raised = level2;
}

abstract final class AppBreakpoints {
  static const double mobile = 640;
  static const double tablet = 1024;
  static const double smallDesktop = 1280;
  static const double desktop = 1600;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isSmallDesktop(double width) =>
      width >= tablet && width < smallDesktop;
  static bool isDesktop(double width) =>
      width >= smallDesktop && width < desktop;
  static bool isWideDesktop(double width) => width >= desktop;
}

abstract final class AppMotion {
  static const Duration hover = Duration(milliseconds: 150);
  static const Duration selection = Duration(milliseconds: 150);
  static const Duration panel = Duration(milliseconds: 200);
  static const Duration dialog = Duration(milliseconds: 200);
  static const Cubic easeOut = Cubic(0.33, 1, 0.68, 1);

  static Duration effective(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
