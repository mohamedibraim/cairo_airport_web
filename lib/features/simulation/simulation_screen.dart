import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../core/widgets/data_table.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  static const _simVersion = 'queue-sim-v0.3';

  final _nameController = TextEditingController();
  final _seedController = TextEditingController();
  final List<ScenarioRun> _queued = [];
  String? _selectedId = 'SCEN-B01';
  double _replayMinute = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _runScenario() {
    final name = _nameController.text.trim();
    final seed = _seedController.text.trim();
    if (name.isEmpty || seed.isEmpty) {
      _toast(
        ref
            .read(stringsProvider)
            .tr(
              'Enter both a scenario name and a seed.',
              'أدخل اسم السيناريو والبذرة.',
            ),
      );
      return;
    }
    final run = ScenarioRun(
      id: 'SCEN-L${(_queued.length + 1).toString().padLeft(2, '0')}',
      nameEn: name,
      nameAr: name,
      baselineId: 'RUN-B-LOCAL-$seed',
      alternativeId: 'RUN-A-LOCAL-$seed',
      seed: seed,
      simulatorVersion: _simVersion,
      forkAt: Fixtures.reference,
      statusEn: 'Queued',
      statusAr: 'في الطابور',
      metrics: const [],
      comparison: const [],
    );
    setState(() {
      _queued.insert(0, run);
      _selectedId = run.id;
      _replayMinute = 0;
    });
    _nameController.clear();
    _seedController.clear();
    _toast(
      ref
          .read(stringsProvider)
          .tr(
            'Scenario ${run.id} queued locally. No worker was started.',
            'تم إدراج السيناريو ${run.id} محليًا. لم يُشغّل أي عامل.',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final user = ref.watch(currentUserProvider);
    final canRun =
        user != null && Capability.allows(user.role, Capability.runScenarios);

    final runs = [..._queued, ...repo.scenarios];
    ScenarioRun? selected;
    for (final r in runs) {
      if (r.id == _selectedId) selected = r;
    }
    selected ??= runs.isEmpty ? null : runs.first;

    final complete = repo.scenarios
        .where((r) => r.statusEn.toLowerCase().contains('complete'))
        .length;
    final seeds = repo.scenarios.map((r) => r.seed).toSet();
    final comparisons = repo.scenarios.fold<int>(
      0,
      (a, r) => a + r.comparison.length,
    );

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Monitoring & intelligence', 'المراقبة والذكاء'),
          title: s.tr('Simulation & replay', 'المحاكاة وإعادة العرض'),
          subtitle: s.tr(
            'Baseline and alternative runs forked at the same moment with matched seeds. Simulation shows what the queue model computes, never a promise of what operations will do.',
            'تشغيل الأساس والبديل من نفس اللحظة ببذور متطابقة. تعرض المحاكاة ما يحسبه نموذج الطوابير، وليست وعدًا بما ستفعله العمليات.',
          ),
          actions: [
            const StatusPill(
              label: _simVersion,
              color: AppColors.info,
              icon: Icons.science_outlined,
            ),
            StatusPill(
              label: s.tr('replay is visual only', 'إعادة العرض بصرية فقط'),
              color: AppColors.warning,
              compact: true,
            ),
          ],
        ),
        InfoBanner(
          icon: Icons.balance_outlined,
          title: s.tr('Compare only like with like', 'قارن المتماثل بالمتماثل'),
          message: s.tr(
            'A delta is only shown when the baseline and alternative share the seed and the fork time. Runs are fixture output; no live model, no GPU worker and no socket is attached.',
            'لا يُعرض الفارق إلا عندما يتشارك الأساس والبديل البذرة ووقت التفرع. النتائج من بيانات ثابتة؛ لا نموذج حي ولا عامل حساب ولا اتصال مفتوح.',
          ),
          color: AppColors.info,
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Metric(
              label: s.tr('Completed runs', 'تشغيلات مكتملة'),
              value: '$complete',
              unit: s.tr('runs', 'تشغيل'),
              hint: s.tr(
                'Matched baseline/alternative pairs',
                'أزواج أساس/بديل متطابقة',
              ),
            ),
            _Metric(
              label: s.tr('Simulator version', 'إصدار المحاكي'),
              value: _simVersion,
              unit: '',
              hint: s.tr(
                'Pinned in fixture provenance',
                'مثبت في مصدر البيانات',
              ),
            ),
            _Metric(
              label: s.tr('Seeds in window', 'بذور في النافذة'),
              value: '${seeds.length}',
              unit: s.tr('seeds', 'بذرة'),
              hint: seeds.join(', '),
            ),
            _Metric(
              label: s.tr('Chart series', 'سلاسل الرسم'),
              value: '$comparisons',
              unit: s.tr('series', 'سلسلة'),
              hint: s.tr(
                'Baseline solid · alternative dashed',
                'الأساس متصل · البديل متقطع',
              ),
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Scenario library', 'مكتبة السيناريوهات'),
                subtitle: s.tr(
                  'Select a run to inspect its comparison and provenance.',
                  'اختر تشغيلًا لعرض مقارنته ومصدره.',
                ),
                trailing: StatusPill(
                  label: s.tr('${runs.length} runs', '${runs.length} تشغيل'),
                  color: AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              if (runs.isEmpty)
                ViewStateMessage(
                  icon: Icons.science_outlined,
                  title: s.tr('No scenarios yet', 'لا سيناريوهات بعد'),
                  message: s.tr(
                    'Queue a scenario below to see it listed here.',
                    'أدرج سيناريو أدناه ليظهر هنا.',
                  ),
                )
              else
                ChoiceChips<String>(
                  selected: selected?.id ?? '',
                  onChanged: (v) => setState(() {
                    _selectedId = v;
                    _replayMinute = 0;
                  }),
                  options: [
                    for (final r in runs)
                      (r.id, s.arabic ? r.nameAr : r.nameEn),
                  ],
                ),
            ],
          ),
        ),
        if (selected != null)
          SplitPane(
            sideWidth: 388,
            breakpoint: 1080,
            main: _ComparisonCard(run: selected, s: s),
            side: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProvenanceCard(run: selected, s: s),
                const SizedBox(height: AppSpace.lg),
                _ReplayCard(
                  run: selected,
                  s: s,
                  minute: _replayMinute,
                  onChanged: (v) => setState(() => _replayMinute = v),
                ),
              ],
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('New scenario', 'سيناريو جديد'),
                subtitle: s.tr(
                  'Queue a local comparison request. In the real system this posts to the simulation API; here it only creates a queued fixture row.',
                  'أدرج طلب مقارنة محليًا. في النظام الحقيقي يُرسل إلى واجهة المحاكاة؛ هنا يُنشئ صف بيانات في الطابور فقط.',
                ),
                trailing: StatusPill(
                  label: canRun
                      ? s.tr('run permitted', 'التشغيل مسموح')
                      : s.tr('analyst/admin only', 'للمحلل/المدير فقط'),
                  color: canRun ? AppColors.success : AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 620;
                  final nameField = TextField(
                    controller: _nameController,
                    enabled: canRun,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: s.tr('Scenario name', 'اسم السيناريو'),
                      hintText: s.tr(
                        'T2-S3 · two extra lanes',
                        'T2-S3 · ممران إضافيان',
                      ),
                      isDense: true,
                    ),
                  );
                  final seedField = TextField(
                    controller: _seedController,
                    enabled: canRun,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: s.tr('Seed', 'البذرة'),
                      hintText: '0116-03',
                      isDense: true,
                    ),
                  );
                  final button = FilledButton.icon(
                    onPressed: canRun ? _runScenario : null,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(s.tr('Queue run', 'إدراج التشغيل')),
                  );
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        nameField,
                        const SizedBox(height: AppSpace.md),
                        seedField,
                        const SizedBox(height: AppSpace.md),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: button,
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(flex: 3, child: nameField),
                      const SizedBox(width: AppSpace.md),
                      Expanded(flex: 2, child: seedField),
                      const SizedBox(width: AppSpace.md),
                      button,
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.tr(
                        'Locally queued in this session',
                        'في طابور هذه الجلسة',
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const IdText(
                    _simVersion,
                    style: TextStyle(fontSize: 9, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              if (_queued.isEmpty)
                Text(
                  s.tr(
                    'Nothing queued. Completed fixture runs above remain the only comparisons.',
                    'لا يوجد شيء في الطابور. التشغيلات المكتملة أعلاه هي المقارنات الوحيدة.',
                  ),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                )
              else
                AppTable(
                  minWidth: 560,
                  columns: [
                    AppTableColumn(s.tr('Scenario', 'السيناريو'), flex: 3),
                    AppTableColumn(
                      s.tr('Seed', 'البذرة'),
                      flex: 2,
                      numeric: true,
                    ),
                    AppTableColumn(s.tr('Status', 'الحالة'), flex: 2),
                    AppTableColumn(
                      s.tr('Queued at', 'وقت الإدراج'),
                      flex: 2,
                      numeric: true,
                    ),
                  ],
                  rows: [
                    for (final r in _queued)
                      AppTableRow(
                        onTap: () => setState(() => _selectedId = r.id),
                        selected: r.id == selected?.id,
                        cells: [
                          Text(
                            s.arabic ? r.nameAr : r.nameEn,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          LtrText(
                            r.seed,
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          StatusPill(
                            label: s.arabic ? r.statusAr : r.statusEn,
                            color: AppColors.info,
                            compact: true,
                          ),
                          LtrText(
                            '${Fixtures.clock(r.forkAt)} UTC+2',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: AppSpace.sm),
              CardNote(
                s.tr(
                  'Queued runs have no metrics or series because no simulator executed. The table intentionally does not invent results.',
                  'التشغيلات في الطابور بلا مقاييس أو سلاسل لأن أي محاكي لم ينفذ. الجدول لا يختلق نتائج عمدًا.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String hint;
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: MiniStat(label: label, value: value, unit: unit, hint: hint),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final ScenarioRun run;
  final AppStrings s;
  const _ComparisonCard({required this.run, required this.s});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final series = <ChartSeries>[
      for (var i = 0; i < run.comparison.length; i++)
        ChartSeries(
          label: s.arabic
              ? run.comparison[i].labelAr
              : run.comparison[i].labelEn,
          points: run.comparison[i].points,
          color: i == 0 ? AppColors.action : AppColors.warning,
          dashed: run.comparison[i].dashed,
          band: run.comparison[i].band,
        ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: s.arabic ? run.nameAr : run.nameEn,
            subtitle: s.tr(
              'Wait by hour · same seed and fork · measured model output',
              'الانتظار بالساعة · نفس البذرة والتفرع · مخرج نموذج مقاس',
            ),
            trailing: StatusPill(
              label: s.arabic ? run.statusAr : run.statusEn,
              color: run.statusEn.toLowerCase().contains('complete')
                  ? AppColors.success
                  : AppColors.info,
              compact: true,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          if (series.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(AppRadius.nested),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Text(
                  s.tr(
                    'This run is queued. No baseline or alternative series exists until a simulator executes it.',
                    'هذا التشغيل في الطابور. لا توجد سلاسل أساس أو بديل حتى ينفذها محاكي.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else ...[
            SeriesChart(
              series: series,
              height: 220,
              yUnit: s.tr('min', 'دقيقة'),
              xAxisNote: s.tr(
                'Hour of day (UTC+2) · fork at ${Fixtures.clock(run.forkAt)} · fixture replay',
                'ساعة اليوم (UTC+2) · التفرع عند ${Fixtures.clock(run.forkAt)} · إعادة عرض ثابتة',
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpace.md),
            Text(
              s.tr('Metric comparison', 'مقارنة المقاييس'),
              style: t.titleSmall,
            ),
            const SizedBox(height: AppSpace.sm),
            AppTable(
              minWidth: 460,
              columns: [
                AppTableColumn(s.tr('Metric', 'المقياس'), flex: 3),
                AppTableColumn(
                  s.tr('Baseline', 'الأساس'),
                  flex: 2,
                  numeric: true,
                  alignment: AlignmentDirectional.centerEnd,
                ),
                AppTableColumn(
                  s.tr('Alternative', 'البديل'),
                  flex: 2,
                  numeric: true,
                  alignment: AlignmentDirectional.centerEnd,
                ),
                AppTableColumn(
                  s.tr('Delta', 'الفارق'),
                  flex: 2,
                  numeric: true,
                  alignment: AlignmentDirectional.centerEnd,
                ),
              ],
              rows: [
                for (final m in run.metrics)
                  AppTableRow(
                    cells: [
                      Text(
                        s.arabic ? m.nameAr : m.nameEn,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      LtrText(
                        '${m.baseline} ${s.arabic ? m.unitAr : m.unitEn}',
                        style: const TextStyle(fontSize: 10.5),
                      ),
                      LtrText(
                        '${m.alternative} ${s.arabic ? m.unitAr : m.unitEn}',
                        style: const TextStyle(fontSize: 10.5),
                      ),
                      LtrText(
                        m.delta,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color:
                              m.delta.startsWith('−') || m.delta.startsWith('-')
                              ? AppColors.success
                              : (m.delta == '0'
                                    ? AppColors.muted
                                    : AppColors.warning),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            CardNote(
              s.tr(
                'Deltas are model arithmetic at matched inputs, not realized savings. A negative wait delta is not a staff decision.',
                'الفوارق حساب نموذجي عند مدخلات متطابقة وليست وفورات محققة. انخفاض الانتظار ليس قرارًا إداريًا.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProvenanceCard extends StatelessWidget {
  final ScenarioRun run;
  final AppStrings s;
  const _ProvenanceCard({required this.run, required this.s});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: s.tr('Run provenance', 'مصدر التشغيل'),
            subtitle: s.tr(
              'Reproduce this comparison only with all five values below.',
              'لا تُعِد هذه المقارنة إلا بالقيم الخمس أدناه.',
            ),
            trailing: const StatusPill(
              label: 'SIM',
              color: AppColors.info,
              compact: true,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          DetailRow(
            label: s.tr('Scenario', 'السيناريو'),
            value: DetailValue(run.id, ltr: true),
          ),
          DetailRow(
            label: s.tr('Baseline', 'الأساس'),
            value: DetailValue(run.baselineId, ltr: true),
          ),
          DetailRow(
            label: s.tr('Alternative', 'البديل'),
            value: DetailValue(run.alternativeId, ltr: true),
          ),
          DetailRow(
            label: s.tr('Seed', 'البذرة'),
            value: DetailValue(run.seed, ltr: true, color: AppColors.action),
          ),
          DetailRow(
            label: s.tr('Simulator', 'المحاكي'),
            value: DetailValue(run.simulatorVersion, ltr: true),
          ),
          DetailRow(
            label: s.tr('Fork at', 'وقت التفرع'),
            value: DetailValue(
              '${Fixtures.clock(run.forkAt)} UTC+2 · ${Fixtures.date(run.forkAt)}',
              ltr: true,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          SourceBadge(
            meta: SourceMeta(
              sourceId: run.simulatorVersion,
              kind: SourceKind.simulator,
              mode: SourceMode.simulated,
              observedAt: run.forkAt,
              version: 3,
            ),
            s: s,
            showStream: true,
          ),
          const SizedBox(height: AppSpace.sm),
          CardNote(
            s.tr(
              'A fork at a different time invalidates the comparison, even if the seed is unchanged.',
              'التفرع في وقت مختلف يُبطل المقارنة حتى لو بقيت البذرة كما هي.',
            ),
            icon: Icons.content_cut,
          ),
        ],
      ),
    );
  }
}

class _ReplayCard extends StatelessWidget {
  final ScenarioRun run;
  final AppStrings s;
  final double minute;
  final ValueChanged<double> onChanged;
  const _ReplayCard({
    required this.run,
    required this.s,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final at = run.forkAt.add(Duration(minutes: minute.round()));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: s.tr('Replay scrub', 'شريط إعادة العرض'),
            subtitle: s.tr(
              'Move the playhead to read the fixture timeline. Nothing is re-simulated.',
              'حرّك المؤشر لقراءة الجدول الزمني الثابت. لا يُعاد أي حساب.',
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              LtrText(
                '+${minute.round()} min',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              LtrText(
                '${Fixtures.clock(at)} UTC+2',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          Slider(
            value: minute,
            min: 0,
            max: 60,
            divisions: 12,
            label: '${minute.round()} min',
            onChanged: onChanged,
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill(
                label: s.tr('visual only', 'بصري فقط'),
                color: AppColors.warning,
                compact: true,
              ),
              StatusPill(
                label: s.tr('no socket', 'بدون اتصال'),
                color: AppColors.muted,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          CardNote(
            s.tr(
              'The scrubber never changes the selected run or its metrics. Reset it before quoting a time.',
              'شريط التمرير لا يغيّر التشغيل المحدد ولا مقاييسه. أعد ضبطه قبل الاستشهاد بوقت.',
            ),
            icon: Icons.timer_outlined,
          ),
        ],
      ),
    );
  }
}
