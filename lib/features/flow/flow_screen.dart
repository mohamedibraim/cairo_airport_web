import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/navigation.dart';
import '../../core/data/fixtures.dart';
import '../../core/data/repository.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/l10n/strings.dart';
import '../../core/state/clock.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';
import '../../core/widgets/timeline.dart';

class FlowScreen extends ConsumerStatefulWidget {
  const FlowScreen({super.key});

  @override
  ConsumerState<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends ConsumerState<FlowScreen> {
  String _stationId = 'T2-S2';
  String _window = '4h';
  bool _loading = false;

  void _refresh() {
    setState(() => _loading = true);
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref
                .read(stringsProvider)
                .tr(
                  'Queue samples reloaded from the fixture repository.',
                  'أُعيد تحميل عينات الطوابير من مستودع البيانات الثابتة.',
                ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final stations = repo.stations;
    QueueStation? station;
    for (final st in stations) {
      if (st.id == _stationId) station = st;
    }
    final now = ref.watch(demoClockProvider).value ?? Fixtures.reference;
    final totalWaiting = stations.fold<int>(0, (a, b) => a + b.count);
    final stale = stations
        .where((q) => q.source.freshness == Freshness.stale)
        .length;
    final slowest = stations.isEmpty
        ? null
        : stations.reduce((a, b) => b.waitHigh > a.waitHigh ? b : a);
    final scenario = Fixtures.scenarios.first;

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Operations', 'العمليات التشغيلية'),
          title: s.tr('Passenger flow & queues', 'تدفق الركاب والطوابير'),
          subtitle: s.tr(
            'Station-level queue length, throughput and wait bands with forecast separation. Measured and simulated series are never blended.',
            'طول الطابور ومعدل المعالجة ونطاقات الانتظار لكل محطة مع فصل التوقع. لا تُدمج السلاسل المُرصدة والمحاكاة.',
          ),
          actions: [
            StatusPill(
              label: s.tr(
                '${cairoClock(now, seconds: false)} demo clock',
                'ساعة العرض ${cairoClock(now, seconds: false)}',
              ),
              color: AppColors.info,
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(s.tr('Reload samples', 'إعادة تحميل العينات')),
            ),
          ],
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _StatCard(
              label: s.tr('Passengers waiting', 'مسافرون في الانتظار'),
              value: '$totalWaiting',
              unit: s.tr('pax', 'مسافر'),
              hint: s.tr('Sum of 4 observed stations', 'مجموع 4 محطات مرصودة'),
            ),
            _StatCard(
              label: s.tr('Aggregate throughput', 'إجمالي المعالجة'),
              value:
                  '${stations.fold<int>(0, (a, b) => a + b.throughputPerHour)}',
              unit: s.tr('pax/h', 'مسافر/ساعة'),
              hint: s.tr(
                'Observed + simulated station rollup',
                'تجميع محطات مرصودة ومحاكاة',
              ),
            ),
            _StatCard(
              label: s.tr('Longest wait band', 'أطول نطاق انتظار'),
              value: slowest == null
                  ? '—'
                  : '${slowest.waitLow}–${slowest.waitHigh}',
              unit: s.tr('min', 'دقيقة'),
              hint: slowest == null
                  ? ''
                  : '${slowest.id} · ${s.arabic ? slowest.nameAr : slowest.nameEn}',
              color: AppColors.warning,
            ),
            _StatCard(
              label: s.tr('Stale feeds', 'بيانات قديمة'),
              value: '$stale',
              unit: s.tr('stations', 'محطة'),
              hint: s.tr('Freshness > 10 min', 'الحداثة > 10 دقائق'),
              color: stale > 0 ? AppColors.warning : AppColors.success,
            ),
          ],
        ),
        SplitPane(
          sideWidth: 340,
          breakpoint: 1020,
          main: _loading
              ? const AppCard(
                  child: SizedBox(
                    height: 420,
                    child: LoadingBlock(message: 'Loading queue samples…'),
                  ),
                )
              : station == null
              ? const AppCard(
                  child: SizedBox(
                    height: 360,
                    child: ViewStateMessage(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'No station selected',
                      message:
                          'Select a queue station to load its throughput and wait series.',
                    ),
                  ),
                )
              : _StationDetail(
                  station: station,
                  s: s,
                  window: _window,
                  onWindow: (w) => setState(() => _window = w),
                  scenario: scenario,
                ),
          side: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: s.tr('Stations', 'المحطات'),
                  subtitle: s.tr(
                    'Observed every 60 s · simulated at bag drop',
                    'تُرصد كل 60 ثانية · محاكاة عند تسليم الأمتعة',
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                for (final st in stations)
                  _StationTile(
                    station: st,
                    s: s,
                    selected: st.id == _stationId,
                    onTap: () => setState(() => _stationId = st.id),
                  ),
                const SizedBox(height: AppSpace.md),
                InfoBanner(
                  icon: Icons.speed_outlined,
                  title: s.tr(
                    'Wait bands, not point estimates',
                    'نطاقات لا أرقام قاطعة',
                  ),
                  message: s.tr(
                    'Bands combine queue length and staffed lanes. Treat them as an observation window, not a service guarantee.',
                    'تُجمع النطاقات من طول الطابور والممرات المأهولة. اعتبرها نافذة رصد لا ضمان خدمة.',
                  ),
                ),
              ],
            ),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Station comparison', 'مقارنة المحطات'),
                subtitle: s.tr(
                  'Queue length vs. wait band · bars scale to the largest observed queue',
                  'طول الطابور مقابل نطاق الانتظار · الأشرطة نسبة إلى أكبر طابور مرصود',
                ),
              ),
              const SizedBox(height: AppSpace.md),
              HBarChart(
                data: [
                  for (final st in stations)
                    (
                      s.arabic ? st.nameAr : st.nameEn,
                      st.count.toDouble(),
                      '${st.count} · ${st.waitBand}m',
                    ),
                ],
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpace.sm),
              CardNote(
                s.tr(
                  'T2-S3 uses a stale immigration feed (last success 09:58). The dashboard keeps the value visible but marks freshness explicitly.',
                  'يستخدم T2-S3 بيانات جوازات قديمة (آخر نجاح 09:58). تُعرض القيمة مع وسم الحداثة صراحةً.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String hint;
  final Color? color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.navy,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  final QueueStation station;
  final AppStrings s;
  final bool selected;
  final VoidCallback onTap;
  const _StationTile({
    required this.station,
    required this.s,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stale = station.source.freshness == Freshness.stale;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: selected ? AppColors.tealSoft : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: stale
                        ? AppColors.warning
                        : (station.waitHigh >= 14
                              ? AppColors.warning
                              : AppColors.success),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.arabic ? station.nameAr : station.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          IdText(
                            station.id,
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${station.count} · ${station.waitBand} min',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (stale)
                  const Icon(Icons.schedule, size: 12, color: AppColors.warning)
                else
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StationDetail extends StatelessWidget {
  final QueueStation station;
  final AppStrings s;
  final String window;
  final ValueChanged<String> onWindow;
  final ScenarioRun scenario;

  const _StationDetail({
    required this.station,
    required this.s,
    required this.window,
    required this.onWindow,
    required this.scenario,
  });

  List<SeriesPoint> _clip(List<SeriesPoint> pts) {
    if (pts.isEmpty) return pts;
    if (window == '60m') {
      return pts.length <= 2 ? pts : pts.sublist(pts.length - 2);
    }
    if (window == '4h') {
      return pts.length <= 5 ? pts : pts.sublist(pts.length - 5);
    }
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final waitColor = station.waitHigh >= 14
        ? AppColors.warning
        : (station.waitHigh >= 10 ? AppColors.info : AppColors.success);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          s.arabic ? station.nameAr : station.nameEn,
                          style: t.titleLarge,
                        ),
                        const SizedBox(width: 8),
                        IdText(
                          station.id,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.arabic ? station.domainAr : station.domainEn,
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: station.source.freshness.label(s),
                color: station.source.freshness.color,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.xl,
            runSpacing: AppSpace.md,
            children: [
              _Kpi(
                label: s.tr('Waiting', 'في الانتظار'),
                value: '${station.count}',
                unit: s.tr('pax', 'مسافر'),
              ),
              _Kpi(
                label: s.tr('Wait band', 'نطاق الانتظار'),
                value: station.waitBand,
                unit: s.tr('min', 'دقيقة'),
                color: waitColor,
              ),
              _Kpi(
                label: s.tr('Throughput', 'المعالجة'),
                value: '${station.throughputPerHour}',
                unit: s.tr('pax/h', 'مسافر/ساعة'),
              ),
              _Kpi(
                label: s.tr('Staffed lanes', 'ممرات مأهولة'),
                value: '${station.lanes}',
                unit: s.tr('lanes', 'ممر'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SourceBadge(meta: station.source, s: s),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(s.tr('Window', 'النافذة'), style: t.labelMedium),
              ChoiceChips<String>(
                selected: window,
                onChanged: onWindow,
                options: [
                  ('60m', s.tr('Last 60 min', 'آخر 60 دقيقة')),
                  ('4h', s.tr('Last 4 h', 'آخر 4 ساعات')),
                  ('all', s.tr('Full sample', 'العينة الكاملة')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            s.tr(
              'Throughput · observed vs forecast',
              'المعالجة · المرصود مقابل المتوقع',
            ),
            style: t.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            s.tr(
              'Solid = observed meter rolls. Dashed = forecast after the 10:24 cutoff. Uncertainty above ±15% is hidden rather than implied.',
              'متصل = عدادات مرصودة. متقطع = توقع بعد قطع 10:24. لا تُعرض اللايقينيات فوق ±15% بدلًا من افتراضها.',
            ),
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpace.sm),
          SeriesChart(
            height: 220,
            yUnit: 'pax/h',
            series: [
              for (final fs in station.throughputSeries)
                ChartSeries(
                  label: s.arabic ? fs.labelAr : fs.labelEn,
                  points: _clip(fs.points),
                  color: fs.dashed ? AppColors.warning : AppColors.action,
                  dashed: fs.dashed,
                ),
            ],
            xAxisNote: s.tr('Hour of service (UTC+2)', 'ساعة الخدمة (UTC+2)'),
          ),
          const Divider(height: AppSpace.xl),
          Text(
            s.tr(
              'Wait · observed vs simulated',
              'الانتظار · المرصود مقابل المحاكى',
            ),
            style: t.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            s.tr(
              'Simulated wait is shown as a band, never as an observed measurement.',
              'الانتظار المحاكى يُعرض كنطاق، وليس قياسًا مرصودًا.',
            ),
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpace.sm),
          SeriesChart(
            height: 200,
            yUnit: 'min',
            series: [
              for (final fs in station.waitSeries)
                ChartSeries(
                  label: s.arabic ? fs.labelAr : fs.labelEn,
                  points: _clip(fs.points),
                  color: fs.band ? AppColors.info : AppColors.primary,
                  dashed: fs.dashed,
                  band: fs.band,
                ),
            ],
            xAxisNote: s.tr('Hour of service (UTC+2)', 'ساعة الخدمة (UTC+2)'),
          ),
          const Divider(height: AppSpace.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.tr('Approved what-if', 'سيناريو معتمد'),
                  style: t.titleSmall,
                ),
              ),
              if (station.id == 'T2-S3')
                StatusPill(
                  label: s.tr(
                    'scenario ${scenario.id}',
                    'سيناريو ${scenario.id}',
                  ),
                  color: AppColors.action,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (station.id == 'T2-S3')
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.arabic ? scenario.nameAr : scenario.nameEn,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final m in scenario.metrics.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.arabic ? m.nameAr : m.nameEn,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '${m.baseline} → ${m.alternative} ${s.arabic ? m.unitAr : m.unitEn}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(
                            label: m.delta,
                            color: m.delta.startsWith('−')
                                ? AppColors.success
                                : AppColors.warning,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () => context.go(Routes.simulation),
                      icon: const Icon(Icons.science_outlined, size: 13),
                      label: Text(s.tr('Open simulation', 'فتح المحاكاة')),
                    ),
                  ),
                ],
              ),
            )
          else
            ViewStateMessage(
              icon: Icons.science_outlined,
              title: s.tr(
                'No approved what-if for this station',
                'لا يوجد سيناريو معتمد لهذه المحطة',
              ),
              message: s.tr(
                'Create a matched-seed baseline and alternative in Simulation & Replay before showing an expected wait reduction.',
                'أنشئ أساسًا وبديلًا بنفس البذرة في المحاكاة وإعادة العرض قبل عرض خفض متوقع للانتظار.',
              ),
              actionLabel: s.tr('Open scenarios', 'فتح السيناريوهات'),
              onAction: () => context.go(Routes.simulation),
            ),
          if (station.evidence.isNotEmpty) ...[
            const Divider(height: AppSpace.xl),
            Text(s.tr('Evidence events', 'أحداث الإثبات'), style: t.titleSmall),
            const SizedBox(height: AppSpace.sm),
            EventTimeline(
              events: station.evidence,
              s: s,
              maxItems: 3,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;
  const _Kpi({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.navy,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
