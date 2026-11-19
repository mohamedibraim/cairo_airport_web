import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/navigation.dart';
import '../../core/data/fixtures.dart';
import '../../core/data/repository.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/l10n/strings.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/data_table.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';
import '../../core/widgets/timeline.dart';

class FlightsScreen extends ConsumerStatefulWidget {
  const FlightsScreen({super.key});

  @override
  ConsumerState<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends ConsumerState<FlightsScreen> {
  String _movement = 'all';
  String _status = 'all';
  String _query = '';
  bool _conflictsOnly = false;
  String? _selectedId = 'FL-103';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final all = repo.flights;

    final filtered =
        all.where((f) {
          final movementOk =
              _movement == 'all' ||
              (_movement == 'arr' && f.movement == Movement.arrival) ||
              (_movement == 'dep' && f.movement == Movement.departure);
          final statusOk = _status == 'all' || _status == f.status.name;
          final q = _query.trim().toLowerCase();
          final queryOk =
              q.isEmpty ||
              f.flightNo.toLowerCase().contains(q) ||
              f.gate.toLowerCase().contains(q) ||
              f.carrierEn.toLowerCase().contains(q) ||
              f.carrierAr.contains(q) ||
              f.origin.toLowerCase().contains(q) ||
              f.destination.toLowerCase().contains(q);
          final conflictOk = !_conflictsOnly || f.gateConflict;
          return movementOk && statusOk && queryOk && conflictOk;
        }).toList()..sort(
          (a, b) => (a.scheduled ?? a.serviceDate).compareTo(
            b.scheduled ?? b.serviceDate,
          ),
        );

    FlightLeg? selected;
    for (final f in all) {
      if (f.id == _selectedId) selected = f;
    }

    final arrivals = all.where((f) => f.movement == Movement.arrival).length;
    final departures = all
        .where((f) => f.movement == Movement.departure)
        .length;
    final delayed = all.where((f) => f.status == FlightStatus.delayed).length;
    final conflicts = all.where((f) => f.gateConflict).length;

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Operations', 'العمليات التشغيلية'),
          title: s.tr('Flights & gates', 'الرحلات والبوابات'),
          subtitle: s.tr(
            'Movements, gate allocation and boarding state for the Terminal 2 sample window. Times are service-local (UTC+2).',
            'الحركات وتخصيص البوابات وحالة الصعود لنافذة عينة مبنى الركاب 2. الأوقات محلية (UTC+2).',
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      s.tr(
                        'DCS reconciliation is queued in the demo. No external system was called.',
                        'تم إدراج مطابقة DCS في العرض التجريبي. لم يتم استدعاء أي نظام خارجي.',
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.sync, size: 16),
              label: Text(s.tr('Reconcile DCS', 'مطابقة DCS')),
            ),
            FilledButton.icon(
              onPressed: () => context.go(Routes.twin),
              icon: const Icon(Icons.hub_outlined, size: 16),
              label: Text(
                s.tr('Show gates on twin', 'عرض البوابات على التوأم'),
              ),
            ),
          ],
        ),
        ResponsiveGrid(
          desktop: 5,
          tablet: 3,
          mobile: 2,
          children: [
            _MiniCard(
              label: s.tr('Sample legs', 'رحلات العينة'),
              value: '${all.length}',
              hint: s.tr(
                '12 legs in the 08:20–17:10 window',
                '12 رحلة بين 08:20 و17:10',
              ),
            ),
            _MiniCard(
              label: s.tr('Arrivals', 'وصول'),
              value: '$arrivals',
              hint: s.tr('Inbound to CAI', 'قادمة إلى القاهرة'),
            ),
            _MiniCard(
              label: s.tr('Departures', 'مغادرة'),
              value: '$departures',
              hint: s.tr('Outbound from CAI', 'مغادرة من القاهرة'),
            ),
            _MiniCard(
              label: s.tr('Delayed', 'متأخرة'),
              value: '$delayed',
              hint: s.tr('Est. +17 min', 'تقدير +17 دقيقة'),
              color: AppColors.warning,
            ),
            _MiniCard(
              label: s.tr('Gate conflicts', 'تعارضات البوابات'),
              value: '$conflicts',
              hint: s.tr('B12 · QR1208 / LH586', 'B12 · QR1208 / LH586'),
              color: AppColors.danger,
            ),
          ],
        ),
        if (conflicts > 0)
          InfoBanner(
            icon: Icons.report_problem_outlined,
            title: s.tr(
              'Gate B12 double allocation',
              'تخصيص مزدوج للبوابة B12',
            ),
            message: s.tr(
              'QR1208 and LH586 overlap at B12. The conflict is derived from gate.assignment events and remains unresolved in this demo.',
              'تتداخل QR1208 و LH586 عند B12. التعارض مشتق من أحداث تخصيص البوابات وما زال غير محلول في هذا العرض.',
            ),
            color: AppColors.warning,
            trailing: TextButton(
              onPressed: () => setState(() {
                _conflictsOnly = true;
                _status = 'all';
                _movement = 'all';
              }),
              child: Text(s.tr('Filter', 'تصفية')),
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Flight board', 'لوحة الرحلات'),
                subtitle: s.tr(
                  '${filtered.length} of ${all.length} legs match the current filters',
                  '${filtered.length} من ${all.length} رحلة تطابق عوامل التصفية',
                ),
                trailing: Text(
                  s.tr('as of 10:18', 'اعتبارًا من 10:18'),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChips<String>(
                    selected: _movement,
                    onChanged: (v) => setState(() => _movement = v),
                    options: [
                      ('all', s.tr('All', 'الكل')),
                      ('arr', s.tr('Arrivals', 'وصول')),
                      ('dep', s.tr('Departures', 'مغادرة')),
                    ],
                  ),
                  ChoiceChips<String>(
                    selected: _status,
                    onChanged: (v) => setState(() => _status = v),
                    options: [
                      ('all', s.tr('Any status', 'أي حالة')),
                      for (final st in [
                        FlightStatus.scheduled,
                        FlightStatus.boarding,
                        FlightStatus.delayed,
                        FlightStatus.departed,
                        FlightStatus.arrived,
                      ])
                        (st.name, st.label(s)),
                    ],
                  ),
                  SearchField(
                    hint: s.tr('Flight, gate, carrier', 'رحلة، بوابة، ناقل'),
                    width: 210,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  FilterChip(
                    label: Text(s.tr('Conflicts only', 'التعارضات فقط')),
                    selected: _conflictsOnly,
                    onSelected: (v) => setState(() => _conflictsOnly = v),
                    showCheckmark: false,
                    selectedColor: AppColors.dangerSoft,
                    side: BorderSide(
                      color: _conflictsOnly
                          ? AppColors.danger
                          : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _conflictsOnly ? AppColors.danger : AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              AppTable(
                minWidth: 1040,
                emptyMessage: s.tr(
                  'No flights match these filters. Clear the search or status filter.',
                  'لا توجد رحلات مطابقة. امسح البحث أو عامل الحالة.',
                ),
                columns: const [
                  AppTableColumn('Flight', flex: 2),
                  AppTableColumn('Route', flex: 3),
                  AppTableColumn('Scheduled', flex: 2),
                  AppTableColumn('Estimated', flex: 2),
                  AppTableColumn('Gate', flex: 1),
                  AppTableColumn('Load', flex: 2),
                  AppTableColumn('Pax', flex: 2),
                  AppTableColumn('Status', flex: 2),
                  AppTableColumn('Source', flex: 2),
                ],
                rows: [
                  for (final f in filtered)
                    AppTableRow(
                      selected: f.id == selected?.id,
                      onTap: () => setState(() => _selectedId = f.id),
                      cells: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IdText(
                              f.flightNo,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              s.arabic ? f.carrierAr : f.carrierEn,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '${f.origin} → ${f.destination}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              s.arabic
                                  ? '${f.originCityAr} → ${f.destinationCityAr}'
                                  : '${f.originCityEn} → ${f.destinationCityEn}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            Fixtures.clock(f.scheduled ?? f.serviceDate),
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            Fixtures.clock(
                              f.estimated ?? f.scheduled ?? f.serviceDate,
                            ),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: f.status == FlightStatus.delayed
                                  ? AppColors.warning
                                  : AppColors.text,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IdText(
                              f.gate,
                              style: const TextStyle(fontSize: 10),
                            ),
                            if (f.gateConflict) ...[
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.priority_high,
                                size: 11,
                                color: AppColors.danger,
                              ),
                            ],
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ScoreBar(
                              value: f.gateOccupancyPct.toDouble(),
                              color: f.gateOccupancyPct > 85
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                            Text(
                              '${f.gateOccupancyPct}%',
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            f.movement == Movement.departure
                                ? '${f.checkedIn}/${f.expectedPax}'
                                : '${f.expectedPax}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        StatusPill(
                          label: f.status.label(s),
                          color: f.status.color,
                          compact: true,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusPill(
                              label: f.source.mode.label(s),
                              color: f.source.mode.color,
                              compact: true,
                            ),
                            IdText(
                              f.source.sourceId,
                              style: const TextStyle(
                                fontSize: 8,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              TableCaption(
                s.tr(
                  'Load = gate occupancy percentage. Pax = checked-in / expected for departures, expected for arrivals. Source is the DCS adapter (external) unless marked simulated.',
                  'الحمل = نسبة إشغال البوابة. المسافرون = المسجلون/المتوقعون للمغادرة، والمتوقعون للوصول. المصدر مهايئ DCS ما لم يُذكر محاكى.',
                ),
              ),
            ],
          ),
        ),
        if (selected != null) _FlightDetail(flight: selected, s: s),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color? color;
  const _MiniCard({
    required this.label,
    required this.value,
    required this.hint,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(fontSize: 9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FlightDetail extends StatelessWidget {
  final FlightLeg flight;
  final AppStrings s;
  const _FlightDetail({required this.flight, required this.s});

  @override
  Widget build(BuildContext context) {
    final f = flight;
    final t = Theme.of(context).textTheme;
    final events = f.timeline.isEmpty
        ? [
            EventRecord(
              eventId: 'E-DCS-${f.id}',
              type: 'flight.leg.observed.v1',
              entityId: f.id,
              entityType: 'flight_leg',
              summaryEn:
                  '${f.flightNo} observed at ${f.gate} · ${f.status.name}',
              summaryAr: '${f.flightNo} عند ${f.gate} · ${f.status.label(s)}',
              observedAt: f.source.observedAt,
              source: f.source,
            ),
          ]
        : f.timeline;

    return SplitPane(
      breakpoint: 1040,
      sideWidth: 380,
      main: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: '${s.tr('Flight detail', 'تفاصيل الرحلة')} ${f.flightNo}',
              subtitle: s.arabic
                  ? '${f.carrierAr} · ${f.originCityAr} → ${f.destinationCityAr}'
                  : '${f.carrierEn} · ${f.originCityEn} → ${f.destinationCityEn}',
              trailing: StatusPill(
                label: f.status.label(s),
                color: f.status.color,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.xl,
              runSpacing: AppSpace.md,
              children: [
                _Kv(
                  label: s.tr('Scheduled', 'مجدولة'),
                  value: Fixtures.clock(f.scheduled ?? f.serviceDate),
                  ltr: true,
                ),
                _Kv(
                  label: s.tr('Estimated', 'متوقعة'),
                  value: Fixtures.clock(
                    f.estimated ?? f.scheduled ?? f.serviceDate,
                  ),
                  ltr: true,
                ),
                _Kv(
                  label: s.tr('Actual', 'الفعلية'),
                  value: f.actual == null ? '—' : Fixtures.clock(f.actual!),
                  ltr: true,
                ),
                _Kv(label: s.tr('Gate', 'البوابة'), value: f.gate, ltr: true),
                _Kv(
                  label: s.tr('Terminal', 'المبنى'),
                  value: f.terminal,
                  ltr: true,
                ),
                _Kv(
                  label: s.tr('Load', 'الحمل'),
                  value: '${f.gateOccupancyPct}%',
                  ltr: true,
                  color: f.gateOccupancyPct > 85 ? AppColors.warning : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.tr('Boarding progression', 'تقدم الصعود'),
                        style: t.titleSmall,
                      ),
                      const Spacer(),
                      StatusPill(
                        label: s.tr('single source', 'مصدر واحد'),
                        color: AppColors.info,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  ScoreBar(
                    value: f.movement == Movement.departure
                        ? (f.checkedIn /
                              (f.expectedPax == 0 ? 1 : f.expectedPax) *
                              100)
                        : (f.gateOccupancyPct.toDouble()),
                    color: AppColors.action,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f.movement == Movement.departure
                        ? s.tr(
                            '${f.checkedIn} of ${f.expectedPax} expected passengers checked in.',
                            'تم تسجيل ${f.checkedIn} من ${f.expectedPax} مسافرًا متوقعًا.',
                          )
                        : s.tr(
                            '${f.expectedPax} passengers expected on arrival; no checked-in count applies.',
                            '${f.expectedPax} مسافرًا متوقعًا عند الوصول؛ لا ينطبق عدد المسجلين.',
                          ),
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                Text(
                  s.tr('Flight event history', 'سجل أحداث الرحلة'),
                  style: t.titleSmall,
                ),
                const Spacer(),
                Text(
                  s.tr('derived from source events', 'مشتق من أحداث المصدر'),
                  style: t.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            EventTimeline(events: events, s: s, maxItems: 6),
          ],
        ),
      ),
      side: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.tr('Provenance', 'المصدر'), style: t.titleSmall),
            const SizedBox(height: AppSpace.sm),
            SourceBadge(meta: f.source, s: s, showStream: true),
            const SizedBox(height: AppSpace.md),
            DetailRow(
              label: s.tr('Leg ID', 'معرف الرحلة'),
              value: DetailValue(f.id, ltr: true),
            ),
            DetailRow(
              label: s.tr('Movement', 'الحركة'),
              value: DetailValue(f.movement.label(s)),
            ),
            DetailRow(
              label: s.tr('Zone', 'المنطقة'),
              value: DetailValue(f.zoneId, ltr: true, color: AppColors.action),
            ),
            DetailRow(
              label: s.tr('Gate conflict', 'تعارض البوابة'),
              value: DetailValue(
                f.gateConflict
                    ? s.tr('Yes · B12', 'نعم · B12')
                    : s.tr('No', 'لا'),
                color: f.gateConflict ? AppColors.danger : AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            InfoBanner(
              icon: Icons.info_outline,
              title: s.tr('Fixture schedule', 'جدول ثابت'),
              message: s.tr(
                'Schedules and gate assignments are static demo fixtures. No real airline or DCS data is displayed.',
                'الجداول وتخصيص البوابات بيانات تجريبية ثابتة. لا تُعرض بيانات شركات طيران أو DCS حقيقية.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  final String label;
  final String value;
  final bool ltr;
  final Color? color;
  const _Kv({
    required this.label,
    required this.value,
    this.ltr = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.navy,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        if (ltr)
          Directionality(textDirection: TextDirection.ltr, child: valueWidget)
        else
          valueWidget,
      ],
    );
  }
}
