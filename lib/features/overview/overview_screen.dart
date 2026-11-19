import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/navigation.dart';
import '../../core/data/fixtures.dart';
import '../../core/data/repository.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/l10n/strings.dart';
import '../../core/state/ops_state.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/inspector.dart';
import '../../core/widgets/layer_selector.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';
import '../../core/widgets/timeline.dart';
import '../../core/widgets/twin_schematic.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  String? _selectedId = 'T2-BHS';
  final Set<TwinLayer> _layers = {
    TwinLayer.flow,
    TwinLayer.baggage,
    TwinLayer.equipment,
    TwinLayer.incidents,
  };

  TwinEntity? _selected(List<TwinEntity> entities) {
    for (final e in entities) {
      if (e.id == _selectedId) return e;
    }
    return entities.isEmpty ? null : entities.first;
  }

  List<TwinEntity> _related(TwinEntity? zone, List<TwinEntity> all) {
    if (zone == null) return const [];
    if (!zone.isZone) {
      return all.where((e) => e.isZone).take(2).toList();
    }
    return all.where((e) {
      if (e.isZone) return false;
      final cx = e.x + e.w / 2;
      final cy = e.y + e.h / 2;
      return cx >= zone.x &&
          cx <= zone.x + zone.w &&
          cy >= zone.y &&
          cy <= zone.y + zone.h;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final ops = ref.watch(opsProvider);
    final user = ref.watch(currentUserProvider);
    final entities = repo.twinEntities;
    final selected = _selected(entities);
    final events = [...repo.events]
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    final activeAlerts =
        repo.incidents
            .where(
              (a) => !{
                CaseStatus.resolved,
                CaseStatus.closed,
              }.contains(ops.alertStatus(a)),
            )
            .toList()
          ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr(
            'Terminal 2 · command center',
            'مبنى الركاب 2 · مركز القيادة',
          ),
          title: s.tr('Operations overview', 'نظرة عامة على العمليات'),
          subtitle: s.tr(
            'One operational picture for flights, passenger flow, baggage, equipment and incidents. Reference window 16 Nov 2026 · 10:24 Cairo.',
            'صورة تشغيلية واحدة للرحلات وتدفق الركاب والأمتعة والمعدات والحوادث. نافذة المرجع 16 نوفمبر 2026 · 10:24 القاهرة.',
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      s.tr(
                        'Fixture snapshot refreshed. Live feeds are not connected in this demo.',
                        'تم تحديث لقطة البيانات الثابتة. لا توجد بثوث حية في هذا العرض.',
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(s.tr('Refresh snapshot', 'تحديث اللقطة')),
            ),
            FilledButton.icon(
              onPressed: () => context.go(Routes.twin),
              icon: const Icon(Icons.hub_outlined, size: 16),
              label: Text(s.tr('Open digital twin', 'فتح التوأم الرقمي')),
            ),
          ],
        ),
        if (activeAlerts.isNotEmpty)
          InfoBanner(
            icon: Icons.warning_amber_rounded,
            title: s.tr(
              '${activeAlerts.length} active alerts need attention',
              '${activeAlerts.length} تنبيهات نشطة تحتاج إلى متابعة',
            ),
            message: s.arabic
                ? '${activeAlerts.first.titleAr} · ${activeAlerts.first.detailAr}'
                : '${activeAlerts.first.titleEn} · ${activeAlerts.first.detailEn}',
            color: AppColors.warning,
            trailing: TextButton(
              onPressed: () => context.go(Routes.incidents),
              child: Text(s.tr('Review', 'مراجعة')),
            ),
          ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 1,
          children: [
            for (final kpi in repo.overviewKpis)
              KpiTileCard(
                kpi: kpi,
                s: s,
                onTap: () => context.go(kpi.destination),
              ),
          ],
        ),
        SplitPane(
          sideWidth: 372,
          breakpoint: 1000,
          main: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: s.tr(
                    'Digital twin · Terminal 2',
                    'التوأم الرقمي · مبنى الركاب 2',
                  ),
                  subtitle: s.tr(
                    'Interactive schematic · normalized zone coordinates · select a zone to inspect',
                    'مخطط تفاعلي · إحداثيات مناطق معيارية · اختر منطقة للفحص',
                  ),
                  trailing: TextButton.icon(
                    onPressed: () => context.go(Routes.twin),
                    icon: const Icon(Icons.open_in_full, size: 14),
                    label: Text(s.tr('Full view', 'عرض كامل')),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                LayerSelector(
                  active: _layers,
                  s: s,
                  dense: true,
                  onToggle: (layer) {
                    setState(() {
                      if (_layers.contains(layer)) {
                        _layers.remove(layer);
                      } else {
                        _layers.add(layer);
                      }
                    });
                  },
                ),
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  height: 320,
                  child: TwinSchematic(
                    entities: entities,
                    activeLayers: _layers,
                    selectedId: selected?.id,
                    onSelect: (e) => setState(() => _selectedId = e.id),
                    s: s,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: CardNote(
                        s.tr(
                          'Schematic is drawn in Flutter (CustomPainter + widgets), not a screenshot.',
                          'المخطط مرسوم بـ Flutter وليس صورة جاهزة.',
                        ),
                        icon: Icons.draw_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: s.tr('simulated', 'محاكى'),
                      color: AppColors.info,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          side: EntityInspector(
            entity: selected,
            related: _related(selected, entities),
            s: s,
            onOpenInTwin: () => context.go(Routes.twin),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 1000;
            final alerts = _AlertsPanel(
              alerts: activeAlerts,
              ops: ops,
              s: s,
              onOpen: () => context.go(Routes.incidents),
            );
            final eventsPanel = _EventsPanel(
              events: events,
              s: s,
              onOpen: () => context.go(Routes.events),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  alerts,
                  const SizedBox(height: AppSpace.lg),
                  eventsPanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: alerts),
                const SizedBox(width: AppSpace.lg),
                Expanded(flex: 6, child: eventsPanel),
              ],
            );
          },
        ),
        LayoutBuilder(
          builder: (context, c) {
            final flights = _FlightsPanel(flights: repo.flights, s: s);
            final queues = _QueuePanel(stations: repo.stations, s: s);
            final equipment = _EquipmentPanel(assets: repo.assets, s: s);
            if (c.maxWidth < 1180) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  flights,
                  const SizedBox(height: AppSpace.lg),
                  queues,
                  const SizedBox(height: AppSpace.lg),
                  equipment,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: flights),
                const SizedBox(width: AppSpace.lg),
                Expanded(flex: 4, child: queues),
                const SizedBox(width: AppSpace.lg),
                Expanded(flex: 4, child: equipment),
              ],
            );
          },
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 15,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.arabic
                      ? 'الجلسة: ${user?.nameAr ?? '—'} · ${user?.role.label(s) ?? '—'} · كل الإجراءات تُسجل في سجل التدقيق التجريبي.'
                      : 'Session: ${user?.nameEn ?? '—'} · ${user?.role.label(s) ?? '—'} · every action is written to the demo audit log.',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ),
              StatusPill(
                label: s.tr('fixtures', 'بيانات ثابتة'),
                color: AppColors.muted,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  final List<OpsAlert> alerts;
  final OpsState ops;
  final AppStrings s;
  final VoidCallback onOpen;
  const _AlertsPanel({
    required this.alerts,
    required this.ops,
    required this.s,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: s.tr('Alerts & incidents', 'التنبيهات والحوادث'),
      subtitle: s.tr(
        'Active operational exceptions by severity',
        'الاستثناءات التشغيلية النشطة حسب الخطورة',
      ),
      trailing: TextButton(
        onPressed: onOpen,
        child: Text(s.tr('All alerts', 'كل التنبيهات')),
      ),
      child: Column(
        children: [
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
              child: Text(
                s.tr('No active alerts.', 'لا توجد تنبيهات نشطة.'),
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          for (final a in alerts.take(4))
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 34,
                      decoration: BoxDecoration(
                        color: a.severity.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.arabic ? a.titleAr : a.titleEn,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              IdText(
                                a.id,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  s.arabic ? a.moduleAr : a.moduleEn,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                Fixtures.clock(a.createdAt),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusPill(
                      label: ops.alertStatus(a).label(s),
                      color: ops.alertStatus(a).color,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventsPanel extends StatelessWidget {
  final List<EventRecord> events;
  final AppStrings s;
  final VoidCallback onOpen;
  const _EventsPanel({
    required this.events,
    required this.s,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: s.tr('Live event stream', 'الأحداث المباشرة'),
      subtitle: s.tr(
        'Ingestion log with status and provenance · demo replay',
        'سجل الاستيعاب مع الحالة والمصدر · إعادة عرض تجريبية',
      ),
      trailing: TextButton(
        onPressed: onOpen,
        child: Text(s.tr('Event log', 'سجل الأحداث')),
      ),
      child: EventTimeline(events: events, s: s, maxItems: 6, dense: true),
    );
  }
}

class _FlightsPanel extends StatelessWidget {
  final List<FlightLeg> flights;
  final AppStrings s;
  const _FlightsPanel({required this.flights, required this.s});

  @override
  Widget build(BuildContext context) {
    final list = [...flights]
      ..sort((a, b) {
        final ax = a.scheduled ?? a.serviceDate;
        final bx = b.scheduled ?? b.serviceDate;
        return ax.compareTo(bx);
      });
    return _Panel(
      title: s.tr('Flights & gates', 'الرحلات والبوابات'),
      subtitle: s.tr(
        'Sample movement window · Terminal 2',
        'نافذة حركة تجريبية · مبنى 2',
      ),
      trailing: TextButton(
        onPressed: () => context.go(Routes.flights),
        child: Text(s.tr('All flights', 'كل الرحلات')),
      ),
      child: Column(
        children: [
          for (final f in list.take(6))
            InkWell(
              onTap: () => context.go(Routes.flights),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          Fixtures.clock(
                            f.estimated ?? f.scheduled ?? f.serviceDate,
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 62,
                      child: IdText(
                        f.flightNo,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.arabic ? f.carrierAr : f.carrierEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${f.origin} → ${f.destination}',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (f.gateConflict)
                      const Padding(
                        padding: EdgeInsetsDirectional.only(end: 4),
                        child: Icon(
                          Icons.report_problem_outlined,
                          size: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    IdText(f.gate, style: const TextStyle(fontSize: 9.5)),
                    const SizedBox(width: 6),
                    StatusPill(
                      label: f.status.label(s),
                      color: f.status.color,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          CardNote(
            s.tr(
              'Gate allocation shows 1 conflict at B12 across QR1208 and LH586.',
              'تخصيص البوابات يُظهر تعارضًا واحدًا عند B12 بين QR1208 و LH586.',
            ),
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

class _QueuePanel extends StatelessWidget {
  final List<QueueStation> stations;
  final AppStrings s;
  const _QueuePanel({required this.stations, required this.s});

  @override
  Widget build(BuildContext context) {
    final maxCount = stations.fold<int>(1, (a, b) => b.count > a ? b.count : a);
    return _Panel(
      title: s.tr('Passenger flow', 'تدفق الركاب'),
      subtitle: s.tr(
        'Queue length and wait band by station',
        'طول الطابور ونطاق الانتظار حسب المحطة',
      ),
      trailing: TextButton(
        onPressed: () => context.go(Routes.flow),
        child: Text(s.tr('Flow board', 'لوحة التدفق')),
      ),
      child: Column(
        children: [
          for (final q in stations)
            InkWell(
              onTap: () => context.go(Routes.flow),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.arabic ? q.nameAr : q.nameEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IdText(
                          q.id,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${q.count} · ${q.waitBand} min',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          Container(height: 5, color: AppColors.neutralSoft),
                          FractionallySizedBox(
                            widthFactor: (q.count / maxCount).clamp(0.03, 1.0),
                            child: Container(
                              height: 5,
                              color: q.waitHigh >= 14
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          CardNote(
            s.tr(
              'Wait bands are observation windows, not guarantees. T2-S3 feed is stale.',
              'نطاقات الانتظار نوافذ رصد وليست ضمانات. بيانات T2-S3 قديمة.',
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentPanel extends StatelessWidget {
  final List<AssetRecord> assets;
  final AppStrings s;
  const _EquipmentPanel({required this.assets, required this.s});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: s.tr('Equipment & maintenance', 'المعدات والصيانة'),
      subtitle: s.tr(
        'Health score and active work order',
        'مؤشر الصحة وأمر العمل النشط',
      ),
      trailing: TextButton(
        onPressed: () => context.go(Routes.maintenance),
        child: Text(s.tr('Maintenance', 'الصيانة')),
      ),
      child: Column(
        children: [
          for (final a in assets)
            InkWell(
              onTap: () => context.go(Routes.maintenance),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.arabic ? a.nameAr : a.nameEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        StateBadge(state: a.state, s: s),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ScoreBar(value: a.healthScore.toDouble()),
                        ),
                        const SizedBox(width: 6),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${a.healthScore}/100',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        if (a.activeOrderId != null) ...[
                          const SizedBox(width: 6),
                          IdText(
                            a.activeOrderId!,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.action,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          CardNote(
            s.tr(
              'Readiness rollup: 96% (24 of 25 assets). CON-003 is faulted.',
              'إجمالي الجاهزية: 96% (24 من 25 أصلًا). CON-003 في حالة عطل.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: subtitle, trailing: trailing),
          const SizedBox(height: AppSpace.sm),
          child,
        ],
      ),
    );
  }
}
