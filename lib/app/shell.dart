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
    final wide = MediaQuery.sizeOf(context).width >= 1080;

    return Scaffold(
      backgroundColor: AppColors.page,
      drawerScrimColor: AppColors.navy.withValues(alpha: 0.35),
      drawer: wide
          ? null
          : Drawer(
              width: 276,
              backgroundColor: AppColors.sidebarTop,
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
            if (wide)
              SizedBox(
                width: 252,
                child: Sidebar(
                  currentPath: currentPath,
                  s: s,
                  onNavigate: (path) {
                    if (path != currentPath) context.go(path);
                  },
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  TopBar(currentPath: currentPath, s: s, showMenu: !wide),
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
  final ValueChanged<String> onNavigate;
  const Sidebar({
    super.key,
    required this.currentPath,
    required this.s,
    required this.onNavigate,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarTop, AppColors.sidebarBottom],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.flight_takeoff,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tr('Operations Center', 'مركز العمليات'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        s.tr(
                          'Cairo International Airport',
                          'مطار القاهرة الدولي',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.onSidebarMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      s.tr(
                        'Demo mode · simulated data',
                        'وضع تجريبي · بيانات محاكاة',
                      ),
                      style: const TextStyle(
                        color: AppColors.onSidebar,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.sm,
                0,
                AppSpace.sm,
                AppSpace.md,
              ),
              children: [
                for (final group in NavGroup.values) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      AppSpace.md,
                      AppSpace.md,
                      6,
                    ),
                    child: Text(
                      groupLabel(group, s),
                      style: const TextStyle(
                        color: AppColors.onSidebarMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  for (final d in Routes.destinations.where(
                    (d) => d.group == group,
                  ))
                    _SidebarItem(
                      destination: d,
                      s: s,
                      selected:
                          currentPath == d.path ||
                          currentPath.startsWith('${d.path}/'),
                      badge: badgeFor(d.path),
                      onTap: () => onNavigate(d.path),
                    ),
                ],
                const SizedBox(height: AppSpace.md),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.md,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _LiveDot(),
                    const SizedBox(width: 6),
                    Text(
                      s.tr('Connected', 'متصل'),
                      style: const TextStyle(
                        color: AppColors.onSidebar,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        'T2 · CAI',
                        style: TextStyle(
                          color: AppColors.onSidebarMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.tr(
                    'Frontend demo · fixture repository · no live feed',
                    'واجهة تجريبية · مستودع بيانات ثابت · لا يوجد بث مباشر',
                  ),
                  style: const TextStyle(
                    color: AppColors.onSidebarMuted,
                    fontSize: 8.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'v1.0.0 · build 2026.11',
                      style: TextStyle(
                        color: AppColors.onSidebarMuted,
                        fontSize: 8.5,
                      ),
                    ),
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

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final NavDestination destination;
  final AppStrings s;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.s,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.28)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),
                Icon(
                  destination.icon,
                  size: 17,
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSidebarMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destination.label(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.onSidebar,
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSidebarMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
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

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 720;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? AppSpace.md : AppSpace.xl,
            vertical: AppSpace.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (showMenu) ...[
                IconButton(
                  tooltip: s.tr('Open navigation', 'فتح القائمة'),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!narrow)
                      Text(
                        group == null
                            ? s.tr('Command Center', 'مركز القيادة')
                            : groupLabel(group, s),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: narrow ? 14 : 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              if (!narrow) const _ClockChip(),
              if (!narrow) const SizedBox(width: AppSpace.sm),
              if (!narrow)
                StatusPill(
                  label: s.tr('Connected', 'متصل'),
                  color: AppColors.success,
                  icon: Icons.wifi_tethering,
                  compact: true,
                ),
              if (!narrow) const SizedBox(width: AppSpace.sm),
              _RoleMenu(s: s, compact: narrow),
              const SizedBox(width: AppSpace.sm),
              _LanguageToggle(s: s),
              const SizedBox(width: 2),
              IconButton(
                tooltip: s.tr('Sign out', 'تسجيل الخروج'),
                onPressed: () {
                  ref.read(sessionProvider.notifier).logout();
                  context.go(Routes.login);
                },
                icon: const Icon(Icons.logout, size: 18),
                visualDensity: VisualDensity.compact,
                color: AppColors.muted,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClockChip extends ConsumerWidget {
  const _ClockChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(demoClockProvider).value ?? Fixtures.reference;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 12, color: AppColors.muted),
            const SizedBox(width: 4),
            Text(
              '${cairoDate(now)} · ${cairoClock(now)}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'UTC+2',
              style: TextStyle(fontSize: 8, color: AppColors.muted),
            ),
          ],
        ),
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
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
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
                  size: 14,
                  color: user.role == r ? AppColors.action : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Text(r.label(s), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        if (compact) ...[
          const PopupMenuDivider(),
          PopupMenuItem<Object>(
            value: 'lang',
            child: Text(
              s.arabic ? 'English' : 'العربية',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          PopupMenuItem<Object>(
            value: 'logout',
            child: Text(
              s.tr('Sign out', 'تسجيل الخروج'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 7, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.action.withValues(alpha: 0.12),
              child: Text(
                user.nameEn.split(' ').map((e) => e[0]).take(2).join(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.action,
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.arabic ? user.nameAr : user.nameEn,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    user.role.label(s),
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(width: 2),
            const Icon(Icons.expand_more, size: 14, color: AppColors.muted),
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
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.action : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [item('AR', s.arabic, true), item('EN', !s.arabic, false)],
      ),
    );
  }
}
