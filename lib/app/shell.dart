import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/data/fixtures.dart';
import '../core/domain/enums.dart';
import '../core/l10n/strings.dart';
import '../core/state/clock.dart';
import '../core/state/ops_state.dart';
import '../core/state/session.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/badges.dart';
import 'navigation.dart';

class AppShell extends ConsumerWidget {
  final String currentPath;
  final Widget child;
  const AppShell({super.key, required this.currentPath, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= AppBreakpoints.tablet;
    final compact = width >= AppBreakpoints.tablet &&
        width < AppBreakpoints.smallDesktop;
    final drawerWidth = width > 360 ? 320.0 : width * 0.86;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      drawerScrimColor: AppColors.sidebar.withValues(alpha: 0.45),
      drawer: showSidebar
          ? null
          : Drawer(
              width: drawerWidth,
              backgroundColor: AppColors.sidebar,
              shape: const RoundedRectangleBorder(),
              child: SafeArea(
                child: Sidebar(
                  currentPath: currentPath,
                  s: s,
                  onNavigate: (path) {
                    Navigator.of(context).maybePop();
                    if (path != currentPath) context.go(path);
                  },
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSidebar)
              SizedBox(
                width: compact ? 72 : 256,
                child: Sidebar(
                  currentPath: currentPath,
                  s: s,
                  compact: compact,
                  onNavigate: (path) {
                    if (path != currentPath) context.go(path);
                  },
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  TopBar(currentPath: currentPath, s: s, showMenu: !showSidebar),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Sidebar extends ConsumerWidget {
  final String currentPath;
  final AppStrings s;
  final bool compact;
  final ValueChanged<String> onNavigate;
  const Sidebar({
    super.key,
    required this.currentPath,
    required this.s,
    required this.onNavigate,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(opsProvider);
    final alertCount = Fixtures.alerts
        .where(
          (a) => !{
            CaseStatus.resolved,
            CaseStatus.closed,
          }.contains(ops.alertStatus(a)),
        )
        .length;
    final orderCount = Fixtures.workOrders
        .where(
          (o) => !{
            CaseStatus.resolved,
            CaseStatus.closed,
          }.contains(ops.workOrderStatus(o)),
        )
        .length;
    final bagCount = Fixtures.bagCases
        .where(
          (b) =>
              b.status != CaseStatus.resolved && b.status != CaseStatus.closed,
        )
        .length;

    int? badgeFor(String path) {
      if (path == Routes.incidents) return alertCount;
      if (path == Routes.maintenance) return orderCount;
      if (path == Routes.baggage) return bagCount;
      return null;
    }

    return Container(
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpace.space3 : AppSpace.space4,
                vertical: AppSpace.space4,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: const Icon(
                      Icons.flight_takeoff,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: AppSpace.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.tr('Operations Center', 'مركز العمليات'),
                            style: AppTypography.bodyEmphasis.copyWith(
                              color: AppColors.sidebarText,
                            ),
                          ),
                          const SizedBox(height: AppSpace.space1),
                          Text(
                            s.tr(
                              'Cairo International Airport',
                              'مطار القاهرة الدولي',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.sidebarMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.space4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.space3,
                  vertical: AppSpace.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sidebarSelected,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.space2),
                    Expanded(
                      child: Text(
                        s.tr(
                          'Demo mode · fixture data',
                          'وضع تجريبي · بيانات ثابتة',
                        ),
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.sidebarMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpace.space4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.space2,
                vertical: AppSpace.space1,
              ),
              children: [
                for (final group in NavGroup.values) ...[
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.space3,
                        AppSpace.space6,
                        AppSpace.space3,
                        AppSpace.space2,
                      ),
                      child: Text(
                        groupLabel(group, s),
                        style: AppTypography.label.copyWith(
                          color: AppColors.sidebarMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpace.space4),
                  for (final d in Routes.destinations.where(
                    (d) => d.group == group,
                  ))
                    _SidebarItem(
                      destination: d,
                      s: s,
                      compact: compact,
                      selected:
                          currentPath == d.path ||
                          currentPath.startsWith('${d.path}/'),
                      badge: badgeFor(d.path),
                      onTap: () => onNavigate(d.path),
                    ),
                ],
                const SizedBox(height: AppSpace.space6),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              compact ? AppSpace.space2 : AppSpace.space4,
              AppSpace.space3,
              compact ? AppSpace.space2 : AppSpace.space4,
              AppSpace.space4,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.sidebarText.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: compact
                ? Center(
                    child: LtrText(
                      'v1.0',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.sidebarMuted,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tr(
                          'Fixture repository · no live feed',
                          'مستودع بيانات ثابت · لا يوجد بث مباشر',
                        ),
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.sidebarMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpace.space1),
                      LtrText(
                        'v1.0.0 · CAI · T2',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.sidebarMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final NavDestination destination;
  final AppStrings s;
  final bool selected;
  final bool compact;
  final int? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.s,
    required this.selected,
    required this.onTap,
    required this.compact,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final label = destination.label(s);
    final content = AnimatedContainer(
      duration: AppMotion.effective(context, AppMotion.hover),
      curve: AppMotion.easeOut,
      constraints: const BoxConstraints(minHeight: 42),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.space3 : AppSpace.space3,
        vertical: AppSpace.space2,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          SizedBox(width: compact ? AppSpace.space2 : AppSpace.space3),
          Icon(
            destination.icon,
            size: 19,
            color: selected
                ? AppColors.sidebarText
                : AppColors.sidebarMuted,
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpace.space3),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: selected
                      ? AppColors.sidebarText
                      : AppColors.onSidebar,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (badge != null && badge! > 0)
              LtrText(
                '$badge',
                style: AppTypography.metadata.copyWith(
                  color: AppColors.sidebarMuted,
                ),
              ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.space1),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: compact ? label : '',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.control),
            hoverColor: AppColors.sidebarHover,
            focusColor: AppColors.sidebarHover,
            child: Semantics(button: true, label: label, child: content),
          ),
        ),
      ),
    );
  }
}

class TopBar extends ConsumerWidget {
  final String currentPath;
  final AppStrings s;
  final bool showMenu;
  const TopBar({
    super.key,
    required this.currentPath,
    required this.s,
    required this.showMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        Routes.titleForPath(currentPath, s) ??
        s.tr('Operations Overview', 'نظرة عامة على العمليات');
    NavGroup? group;
    for (final g in NavGroup.values) {
      final match = Routes.destinations.any(
        (d) =>
            d.group == g &&
            (currentPath == d.path || currentPath.startsWith('${d.path}/')),
      );
      if (match) {
        group = g;
        break;
      }
    }

    final narrow = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: narrow ? AppSpace.space4 : AppSpace.space6,
          vertical: AppSpace.space2,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            if (showMenu) ...[
              IconButton(
                tooltip: s.tr('Open navigation', 'فتح القائمة'),
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, size: 20),
              ),
              const SizedBox(width: AppSpace.space1),
            ],
            Expanded(
              child: Row(
                children: [
                  if (!narrow && group != null) ...[
                    Text(
                      groupLabel(group, s),
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpace.space2),
                    const Icon(
                      Icons.chevron_left,
                      size: 14,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(width: AppSpace.space2),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyEmphasis.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.space3),
            if (!narrow) const _ClockChip(),
            if (!narrow) const SizedBox(width: AppSpace.space2),
            if (!narrow)
              StatusPill(
                label: s.tr('Fixture data', 'بيانات ثابتة'),
                color: AppColors.primary,
                compact: true,
              ),
            if (!narrow) const SizedBox(width: AppSpace.space2),
            _RoleMenu(s: s, compact: narrow),
            const SizedBox(width: AppSpace.space2),
            _LanguageToggle(s: s),
            const SizedBox(width: AppSpace.space1),
            IconButton(
              tooltip: s.tr('Sign out', 'تسجيل الخروج'),
              onPressed: () {
                ref.read(sessionProvider.notifier).logout();
                context.go(Routes.login);
              },
              icon: const Icon(Icons.logout, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockChip extends ConsumerWidget {
  const _ClockChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(demoClockProvider).value ?? Fixtures.reference;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.space3,
        vertical: AppSpace.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: AppSpace.space1),
          LtrText(
            '${cairoDate(now)} · ${cairoClock(now)}',
            style: AppTypography.metadata.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpace.space2),
          LtrText(
            'UTC+2',
            style: AppTypography.metadata.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleMenu extends ConsumerWidget {
  final AppStrings s;
  final bool compact;
  const _RoleMenu({required this.s, required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    return PopupMenuButton<Object>(
      tooltip: s.tr('Switch demo role', 'تغيير الدور التجريبي'),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      onSelected: (value) {
        if (value is WebRole) {
          ref.read(sessionProvider.notifier).switchRole(value);
        } else if (value == 'lang') {
          ref.read(sessionProvider.notifier).setArabic(!s.arabic);
        } else if (value == 'logout') {
          ref.read(sessionProvider.notifier).logout();
          context.go(Routes.login);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<Object>(
          enabled: false,
          child: Text(
            s.tr('Switch demo role', 'تغيير الدور التجريبي'),
            style: AppTypography.metadata.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final r in WebRole.values)
          PopupMenuItem<Object>(
            value: r,
            child: Row(
              children: [
                Icon(
                  user.role == r
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: user.role == r
                      ? AppColors.primaryStrong
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpace.space2),
                Text(r.label(s), style: AppTypography.tableText),
              ],
            ),
          ),
        if (compact) ...[
          const PopupMenuDivider(),
          PopupMenuItem<Object>(
            value: 'lang',
            child: Text(
              s.arabic ? 'English' : 'العربية',
              style: AppTypography.tableText,
            ),
          ),
          PopupMenuItem<Object>(
            value: 'logout',
            child: Text(
              s.tr('Sign out', 'تسجيل الخروج'),
              style: AppTypography.tableText,
            ),
          ),
        ],
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpace.space2 : AppSpace.space3,
          vertical: AppSpace.space1,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                user.nameEn.split(' ').map((e) => e[0]).take(2).join(),
                style: AppTypography.label.copyWith(
                  color: AppColors.primaryStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppSpace.space2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.arabic ? user.nameAr : user.nameEn,
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.role.label(s),
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(width: AppSpace.space1),
            const Icon(
              Icons.expand_more,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends ConsumerWidget {
  final AppStrings s;
  const _LanguageToggle({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget item(String label, bool active, bool arabic) {
      return InkWell(
        onTap: () => ref.read(sessionProvider.notifier).setArabic(arabic),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: AnimatedContainer(
          duration: AppMotion.effective(context, AppMotion.selection),
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.space3,
            vertical: AppSpace.space2,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: active ? AppColors.textOnDark : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.space1),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [item('AR', s.arabic, true), item('EN', !s.arabic, false)],
      ),
    );
  }
}
