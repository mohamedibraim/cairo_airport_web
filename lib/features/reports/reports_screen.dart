import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/fixtures.dart';
import '../../core/data/repository.dart';
import '../../core/domain/enums.dart';
import '../../core/l10n/strings.dart';
import '../../core/state/ops_state.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/data_table.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';

class _ReportSpec {
  final String id;
  final String titleEn;
  final String titleAr;
  final String descEn;
  final String descAr;
  final String cadenceEn;
  final String cadenceAr;
  final String sourceEn;
  final String sourceAr;
  final IconData icon;
  const _ReportSpec({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descEn,
    required this.descAr,
    required this.cadenceEn,
    required this.cadenceAr,
    required this.sourceEn,
    required this.sourceAr,
    required this.icon,
  });
}

const _reports = <_ReportSpec>[
  _ReportSpec(
    id: 'RPT-FLIGHTS',
    titleEn: 'Flight & gate reliability',
    titleAr: 'موثوقية الرحلات والبوابات',
    descEn:
        'Leg status, gate conflicts, boarding loads and check-in progress for the window.',
    descAr:
        'حالة الرحلات وتعارض البوابات وأحمال الصعود وتقدم التسجيل في النافذة.',
    cadenceEn: 'daily · 06:00',
    cadenceAr: 'يومي · 06:00',
    sourceEn: 'DCS-ADAPTER',
    sourceAr: 'DCS-ADAPTER',
    icon: Icons.flight_takeoff,
  ),
  _ReportSpec(
    id: 'RPT-FLOW',
    titleEn: 'Passenger flow & wait compliance',
    titleAr: 'تدفق الركاب والالتزام بالانتظار',
    descEn:
        'Stations, lanes, throughput and observed wait bands against the declared target.',
    descAr:
        'المحطات والممرات والمعالجة ونطاقات الانتظار المرصودة مقابل الهدف المعلن.',
    cadenceEn: 'hourly',
    cadenceAr: 'كل ساعة',
    sourceEn: 'QUEUE-SNS-*',
    sourceAr: 'QUEUE-SNS-*',
    icon: Icons.people_alt_outlined,
  ),
  _ReportSpec(
    id: 'RPT-BAGS',
    titleEn: 'Baggage exception ledger',
    titleAr: 'سجل استثناءات الأمتعة',
    descEn:
        'Cases, last confirmed scan, reason code and acknowledgement state per bag.',
    descAr: 'الحالات وآخر تسجيل مؤكد ورمز السبب وحالة الإقرار لكل حقيبة.',
    cadenceEn: 'daily · 07:00',
    cadenceAr: 'يومي · 07:00',
    sourceEn: 'READER-*',
    sourceAr: 'READER-*',
    icon: Icons.luggage_outlined,
  ),
  _ReportSpec(
    id: 'RPT-MAINT',
    titleEn: 'Equipment health & work orders',
    titleAr: 'صحة المعدات وأوامر العمل',
    descEn:
        'Asset health scores, open orders, assigned owners and low-stock parts.',
    descAr:
        'درجات صحة الأصول والأوامر المفتوحة والمسؤولون وقطع الغيار المنخفضة.',
    cadenceEn: 'daily · 06:30',
    cadenceAr: 'يومي · 06:30',
    sourceEn: 'ASSET-ROLLUP',
    sourceAr: 'ASSET-ROLLUP',
    icon: Icons.precision_manufacturing_outlined,
  ),
  _ReportSpec(
    id: 'RPT-INC',
    titleEn: 'Incident & response audit',
    titleAr: 'تدقيق الحوادث والاستجابة',
    descEn:
        'Operational alerts and restricted security summaries with status and owner.',
    descAr: 'التنبيهات التشغيلية والملخصات الأمنية المقيدة مع الحالة والمسؤول.',
    cadenceEn: 'on demand',
    cadenceAr: 'عند الطلب',
    sourceEn: 'CASE-SVC · SEC-SYNTH',
    sourceAr: 'CASE-SVC · SEC-SYNTH',
    icon: Icons.notification_important_outlined,
  ),
  _ReportSpec(
    id: 'RPT-EXEC',
    titleEn: 'Executive shift summary',
    titleAr: 'ملخص الوردية التنفيذي',
    descEn:
        'The KPI strip with unit, as-of time, source mode and drill-down destination.',
    descAr: 'شريط المؤشرات مع الوحدة ووقت الرصد ونمط المصدر وجهة التفصيل.',
    cadenceEn: 'per shift',
    cadenceAr: 'كل وردية',
    sourceEn: 'TWIN-AGG',
    sourceAr: 'TWIN-AGG',
    icon: Icons.insights_outlined,
  ),
];

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _period = 'today';
  String _format = 'pdf';
  String _selectedId = 'RPT-FLIGHTS';
  String? _lastExport;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  _ReportSpec get _selected {
    return _reports.firstWhere(
      (r) => r.id == _selectedId,
      orElse: () => _reports.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final ops = ref.watch(opsProvider);
    final user = ref.watch(currentUserProvider);
    final canExport =
        user != null && Capability.allows(user.role, Capability.exportReports);

    final spec = _selected;
    final pinned = _reports.where((r) => ops.reportPinned(r.id)).toList();

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Monitoring & intelligence', 'المراقبة والذكاء'),
          title: s.tr(
            'Historical analytics & reports',
            'التحليلات التاريخية والتقارير',
          ),
          subtitle: s.tr(
            'Catalogued reports over the frozen fixture window. Every preview aggregates real fixture records; no report invents a metric that the source does not carry.',
            'تقارير مفهرسة على نافذة بيانات ثابتة. كل معاينة تجمع سجلات ثابتة حقيقية؛ لا يختلق أي تقرير مقياسًا غير موجود في المصدر.',
          ),
          actions: [
            StatusPill(
              label: s.tr('fixture window only', 'نافذة بيانات ثابتة فقط'),
              color: AppColors.warning,
              compact: true,
            ),
            OutlinedButton.icon(
              onPressed: () {
                final wasPinned = ops.reportPinned(spec.id);
                ref.read(opsProvider.notifier).toggleReportPin(spec.id, user);
                _toast(
                  wasPinned
                      ? s.tr(
                          '${spec.id} unpinned from the workspace.',
                          'أُلغي تثبيت ${spec.id} من مساحة العمل.',
                        )
                      : s.tr(
                          '${spec.id} pinned to the workspace.',
                          'تم تثبيت ${spec.id} في مساحة العمل.',
                        ),
                );
              },
              icon: Icon(
                ops.reportPinned(spec.id)
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                size: 15,
              ),
              label: Text(
                ops.reportPinned(spec.id)
                    ? s.tr('Unpin', 'إلغاء التثبيت')
                    : s.tr('Pin report', 'تثبيت التقرير'),
              ),
            ),
          ],
        ),
        InfoBanner(
          icon: Icons.date_range_outlined,
          title: s.tr('One frozen data window', 'نافذة بيانات واحدة مجمّدة'),
          message: s.tr(
            'All aggregates cover 16/11/2026, 06:00–10:24 Cairo (UTC+2). Period controls relabel the request; the fixture does not slice, and exports write no file.',
            'كل المجاميع تغطي 16/11/2026 من 06:00 إلى 10:24 بتوقيت القاهرة (UTC+2). خيارات الفترة تعيد تسمية الطلب فقط؛ البيانات لا تُقسّم، والتصدير لا يكتب ملفًا.',
          ),
          color: AppColors.info,
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Metric(
              label: s.tr('Catalogued reports', 'تقارير مفهرسة'),
              value: '${_reports.length}',
              unit: s.tr('reports', 'تقرير'),
              hint: s.tr(
                'Purpose-built previews, not templates',
                'معاينات مبنية للغرض وليست قوالب',
              ),
            ),
            _Metric(
              label: s.tr('Pinned', 'مثبتة'),
              value: '${pinned.length}',
              unit: s.tr('reports', 'تقرير'),
              hint: pinned.isEmpty
                  ? s.tr(
                      'Pin a report to keep it here',
                      'ثبّت تقريرًا ليبقى هنا',
                    )
                  : pinned.map((p) => p.id).join(', '),
              color: pinned.isEmpty ? null : AppColors.action,
            ),
            _Metric(
              label: s.tr('Data window', 'نافذة البيانات'),
              value: '06:00–10:24',
              unit: 'UTC+2',
              hint: s.tr(
                '16/11/2026 · frozen reference clock',
                '16/11/2026 · ساعة مرجعية مجمّدة',
              ),
            ),
            _Metric(
              label: s.tr('Last export', 'آخر تصدير'),
              value: _lastExport ?? '—',
              unit: '',
              hint: s.tr(
                'Demo only · no file written',
                'عرض تجريبي · لا يُكتب ملف',
              ),
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Report catalog', 'فهرس التقارير'),
                subtitle: s.tr(
                  'Select a report to preview its real aggregate below.',
                  'اختر تقريرًا لمعاينة تجميعه الحقيقي أدناه.',
                ),
                trailing: StatusPill(
                  label: s.tr(
                    '${_reports.length} available',
                    '${_reports.length} متاح',
                  ),
                  color: AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              for (var i = 0; i < _reports.length; i++) ...[
                if (i != 0) const SizedBox(height: 6),
                _ReportRow(
                  spec: _reports[i],
                  s: s,
                  selected: _reports[i].id == _selectedId,
                  pinned: ops.reportPinned(_reports[i].id),
                  onTap: () => setState(() => _selectedId = _reports[i].id),
                  onPin: () {
                    ref
                        .read(opsProvider.notifier)
                        .toggleReportPin(_reports[i].id, user);
                  },
                ),
              ],
            ],
          ),
        ),
        SplitPane(
          sideWidth: 360,
          breakpoint: 1040,
          main: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: s.arabic ? spec.titleAr : spec.titleEn,
                  subtitle: s.arabic ? spec.descAr : spec.descEn,
                  trailing: StatusPill(
                    label: s.arabic ? spec.cadenceAr : spec.cadenceEn,
                    color: AppColors.info,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    IdText(
                      spec.id,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.muted,
                      ),
                    ),
                    IdText(
                      s.arabic ? spec.sourceAr : spec.sourceEn,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.action,
                      ),
                    ),
                    StatusPill(
                      label: _periodLabel(s),
                      color: AppColors.muted,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSpace.md),
                _preview(spec.id, repo, ops, s),
              ],
            ),
          ),
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: s.tr('Export request', 'طلب التصدير'),
                      subtitle: s.arabic ? spec.titleAr : spec.titleEn,
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      s.tr('Period', 'الفترة'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ChoiceChips<String>(
                      selected: _period,
                      onChanged: (v) => setState(() => _period = v),
                      options: [
                        ('today', s.tr('Today', 'اليوم')),
                        ('7d', s.tr('Last 7 days', 'آخر 7 أيام')),
                        ('30d', s.tr('Last 30 days', 'آخر 30 يومًا')),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      s.tr('Format', 'الصيغة'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ChoiceChips<String>(
                      selected: _format,
                      onChanged: (v) => setState(() => _format = v),
                      options: const [
                        ('pdf', 'PDF'),
                        ('csv', 'CSV'),
                        ('xlsx', 'XLSX'),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    FilledButton.icon(
                      onPressed: canExport
                          ? () {
                              final label =
                                  '${_format.toUpperCase()} · ${spec.id} · ${_periodLabel(s)}';
                              setState(() => _lastExport = label);
                              _toast(
                                s.tr(
                                  'Export request recorded locally: $label. No file was generated.',
                                  'تم تسجيل طلب التصدير محليًا: $label. لم يُنشأ ملف.',
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: Text(s.tr('Request export', 'طلب التصدير')),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (!canExport)
                      CardNote(
                        s.tr(
                          'Your role cannot export reports. Ask an Admin or Analyst to run it.',
                          'دورك لا يملك تصدير التقارير. اطلب من المدير أو المحلل تنفيذه.',
                        ),
                        icon: Icons.lock_outline,
                      )
                    else
                      CardNote(
                        s.tr(
                          'The export button records an audit entry only; no PDF, CSV or XLSX engine is bundled.',
                          'زر التصدير يسجل إدخال تدقيق فقط؛ لا يوجد محرك PDF أو CSV أو XLSX مضمّن.',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: s.tr('Pinned reports', 'التقارير المثبتة'),
                      subtitle: s.tr(
                        'Workspace shortcuts for this session.',
                        'اختصارات مساحة العمل لهذه الجلسة.',
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (pinned.isEmpty)
                      Text(
                        s.tr(
                          'No pinned report. Use the pin icon in the catalog.',
                          'لا تقارير مثبتة. استخدم أيقونة التثبيت في الفهرس.',
                        ),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.muted,
                        ),
                      )
                    else
                      for (final p in pinned)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: InkWell(
                            onTap: () => setState(() => _selectedId = p.id),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Icon(
                                    p.icon,
                                    size: 14,
                                    color: AppColors.action,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      s.arabic ? p.titleAr : p.titleEn,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
        CardNote(
          s.tr(
            'Report previews read directly from the repository fixtures. When a live API is connected, the same preview widgets can render returned aggregates without redesign.',
            'معاينات التقارير تقرأ مباشرة من بيانات المستودع. عند ربط واجهة حية، يمكن لنفس عناصر المعاينة عرض المجاميع المُعادة دون إعادة تصميم.',
          ),
          icon: Icons.storage_outlined,
        ),
      ],
    );
  }

  String _periodLabel(AppStrings s) => switch (_period) {
    '7d' => s.tr('last 7 days', 'آخر 7 أيام'),
    '30d' => s.tr('last 30 days', 'آخر 30 يومًا'),
    _ => s.tr('today', 'اليوم'),
  };

  Widget _preview(String id, TwinRepository repo, OpsState ops, AppStrings s) {
    switch (id) {
      case 'RPT-FLOW':
        return _flowPreview(repo, s);
      case 'RPT-BAGS':
        return _bagPreview(repo, ops, s);
      case 'RPT-MAINT':
        return _maintenancePreview(repo, ops, s);
      case 'RPT-INC':
        return _incidentPreview(repo, ops, s);
      case 'RPT-EXEC':
        return _executivePreview(repo, s);
      default:
        return _flightPreview(repo, s);
    }
  }

  Widget _flightPreview(TwinRepository repo, AppStrings s) {
    final flights = repo.flights;
    final conflicts = flights.where((f) => f.gateConflict).length;
    final delayed = flights
        .where((f) => f.status == FlightStatus.delayed)
        .length;
    final expected = flights.fold<int>(0, (a, f) => a + f.expectedPax);
    final checked = flights.fold<int>(0, (a, f) => a + f.checkedIn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          desktop: 3,
          tablet: 3,
          mobile: 1,
          children: [
            _InlineStat(
              label: s.tr('Gate conflicts', 'تعارض البوابات'),
              value: '$conflicts',
              unit: s.tr('legs', 'رحلة'),
              color: AppColors.danger,
            ),
            _InlineStat(
              label: s.tr('Delayed legs', 'رحلات متأخرة'),
              value: '$delayed',
              unit: s.tr('legs', 'رحلة'),
              color: AppColors.warning,
            ),
            _InlineStat(
              label: s.tr('Checked in / expected', 'المسجلون / المتوقعون'),
              value: '$checked / $expected',
              unit: s.tr('pax', 'مسافر'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AppTable(
          minWidth: 560,
          columns: [
            AppTableColumn(s.tr('Flight', 'الرحلة'), flex: 2),
            AppTableColumn(s.tr('Route', 'المسار'), flex: 2),
            AppTableColumn(
              s.tr('Scheduled', 'المجدول'),
              flex: 2,
              numeric: true,
            ),
            AppTableColumn(s.tr('Gate', 'البوابة'), flex: 1, numeric: true),
            AppTableColumn(s.tr('Expected', 'المتوقع'), flex: 2, numeric: true),
            AppTableColumn(s.tr('Status', 'الحالة'), flex: 2),
          ],
          rows: [
            for (final f in flights.take(7))
              AppTableRow(
                emphasized: f.gateConflict,
                cells: [
                  IdText(f.flightNo, style: const TextStyle(fontSize: 10.5)),
                  LtrText(
                    '${f.origin} → ${f.destination}',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  LtrText(
                    '${Fixtures.clock(f.scheduled ?? Fixtures.reference)} UTC+2',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  LtrText(f.gate, style: const TextStyle(fontSize: 10.5)),
                  LtrText(
                    '${f.expectedPax}',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  StatusPill(
                    label: f.status.label(s),
                    color: f.gateConflict ? AppColors.danger : f.status.color,
                    compact: true,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _flowPreview(TwinRepository repo, AppStrings s) {
    final stations = repo.stations;
    final fresh = stations
        .where((q) => q.source.freshness == Freshness.fresh)
        .length;
    final stale = stations.length - fresh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          desktop: 3,
          tablet: 3,
          mobile: 1,
          children: [
            _InlineStat(
              label: s.tr('Stations sampled', 'محطات معاينة'),
              value: '${stations.length}',
              unit: s.tr('stations', 'محطة'),
            ),
            _InlineStat(
              label: s.tr('Fresh feeds', 'بيانات حديثة'),
              value: '$fresh',
              unit: s.tr('stations', 'محطة'),
              color: AppColors.success,
            ),
            _InlineStat(
              label: s.tr('Stale feeds', 'بيانات قديمة'),
              value: '$stale',
              unit: s.tr('stations', 'محطة'),
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          s.tr(
            'Observed throughput by station',
            'المعالجة المرصودة حسب المحطة',
          ),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        HBarChart(
          data: [
            for (final q in stations)
              (q.id, q.throughputPerHour.toDouble(), '${q.throughputPerHour}'),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AppTable(
          minWidth: 600,
          columns: [
            AppTableColumn(s.tr('Station', 'المحطة'), flex: 2),
            AppTableColumn(s.tr('Zone', 'المنطقة'), flex: 2, numeric: true),
            AppTableColumn(s.tr('Lanes', 'الممرات'), flex: 1, numeric: true),
            AppTableColumn(
              s.tr('Wait band', 'نطاق الانتظار'),
              flex: 2,
              numeric: true,
            ),
            AppTableColumn(s.tr('Provenance', 'المصدر'), flex: 3),
          ],
          rows: [
            for (final q in stations)
              AppTableRow(
                cells: [
                  IdText(q.id, style: const TextStyle(fontSize: 10.5)),
                  IdText(
                    q.zoneId,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                  LtrText('${q.lanes}', style: const TextStyle(fontSize: 10.5)),
                  LtrText(
                    '${q.waitLow}–${q.waitHigh} min',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  SourceBadge(meta: q.source, s: s),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        CardNote(
          s.tr(
            'The immigration feed (T2-S3) is stale; its wait band is quoted as the last good sample, not a current reading.',
            'بيانات الجوازات (T2-S3) قديمة؛ نطاق انتظارها منقول من آخر عينة سليمة وليس قراءة حالية.',
          ),
          icon: Icons.history_toggle_off,
        ),
      ],
    );
  }

  Widget _bagPreview(TwinRepository repo, OpsState ops, AppStrings s) {
    final bags = repo.bagCases;
    final exceptions = bags
        .where(
          (b) => !{CaseStatus.resolved, CaseStatus.closed}.contains(b.status),
        )
        .length;
    final acknowledged = bags.where((b) => ops.bagAcknowledged(b.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          desktop: 3,
          tablet: 3,
          mobile: 1,
          children: [
            _InlineStat(
              label: s.tr('Cases in window', 'حالات في النافذة'),
              value: '${bags.length}',
              unit: s.tr('bags', 'حقيبة'),
            ),
            _InlineStat(
              label: s.tr('Open exceptions', 'استثناءات مفتوحة'),
              value: '$exceptions',
              unit: s.tr('cases', 'حالة'),
              color: AppColors.warning,
            ),
            _InlineStat(
              label: s.tr('Acknowledged', 'تم الإقرار'),
              value: '$acknowledged',
              unit: s.tr('cases', 'حالة'),
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AppTable(
          minWidth: 620,
          columns: [
            AppTableColumn(s.tr('Bag', 'الحقيبة'), flex: 2),
            AppTableColumn(s.tr('Flight', 'الرحلة'), flex: 2, numeric: true),
            AppTableColumn(s.tr('Stage', 'المرحلة'), flex: 3),
            AppTableColumn(
              s.tr('Last scan', 'آخر تسجيل'),
              flex: 2,
              numeric: true,
            ),
            AppTableColumn(s.tr('Status', 'الحالة'), flex: 2),
            AppTableColumn(s.tr('Ack', 'الإقرار'), flex: 1),
          ],
          rows: [
            for (final b in bags)
              AppTableRow(
                cells: [
                  IdText(b.id, style: const TextStyle(fontSize: 10.5)),
                  IdText(b.flightNo, style: const TextStyle(fontSize: 10.5)),
                  Text(
                    s.arabic ? b.stageAr : b.stageEn,
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  LtrText(
                    Fixtures.clock(b.lastScanAt),
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  CaseStatusBadge(status: b.status, s: s),
                  Icon(
                    ops.bagAcknowledged(b.id)
                        ? Icons.check_circle
                        : Icons.remove,
                    size: 15,
                    color: ops.bagAcknowledged(b.id)
                        ? AppColors.success
                        : AppColors.muted,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        CardNote(
          s.tr(
            'A missing scan is not a lost bag. The report keeps the last confirmed stage and never extrapolates a location.',
            'التسجيل المفقود ليس حقيبة مفقودة. يحتفظ التقرير بآخر مرحلة مؤكدة ولا يستنتج موقعًا.',
          ),
          icon: Icons.travel_explore,
        ),
      ],
    );
  }

  Widget _maintenancePreview(TwinRepository repo, OpsState ops, AppStrings s) {
    final assets = repo.assets;
    final openOrders = repo.workOrders
        .where(
          (o) => !{
            CaseStatus.resolved,
            CaseStatus.closed,
          }.contains(ops.workOrderStatus(o)),
        )
        .length;
    final lowStock = repo.parts
        .where((p) => p.balance <= p.reorderPoint)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          desktop: 3,
          tablet: 3,
          mobile: 1,
          children: [
            _InlineStat(
              label: s.tr('Faulted assets', 'أصول معطلة'),
              value:
                  '${assets.where((a) => a.state == EntityState.fault).length}',
              unit: s.tr('assets', 'أصل'),
              color: AppColors.danger,
            ),
            _InlineStat(
              label: s.tr('Open work orders', 'أوامر عمل مفتوحة'),
              value: '$openOrders',
              unit: s.tr('orders', 'أمر'),
              color: AppColors.info,
            ),
            _InlineStat(
              label: s.tr('Low-stock parts', 'قطع منخفضة'),
              value: '${lowStock.length}',
              unit: s.tr('parts', 'قطعة'),
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AppTable(
          minWidth: 620,
          columns: [
            AppTableColumn(s.tr('Asset', 'الأصل'), flex: 3),
            AppTableColumn(s.tr('Type', 'النوع'), flex: 2),
            AppTableColumn(s.tr('State', 'الحالة'), flex: 2),
            AppTableColumn(s.tr('Health', 'الصحة'), flex: 2, numeric: true),
            AppTableColumn(
              s.tr('Open order', 'أمر مفتوح'),
              flex: 2,
              numeric: true,
            ),
          ],
          rows: [
            for (final a in assets)
              AppTableRow(
                cells: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.arabic ? a.nameAr : a.nameEn,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IdText(
                        a.id,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    s.arabic ? a.typeAr : a.typeEn,
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  StateBadge(state: a.state, s: s),
                  Row(
                    children: [
                      Expanded(
                        child: ScoreBar(value: a.healthScore.toDouble()),
                      ),
                      const SizedBox(width: 6),
                      LtrText(
                        '${a.healthScore}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IdText(
                    a.activeOrderId ?? '—',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.action,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          s.tr('Low-stock parts', 'قطع الغيار المنخفضة'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        if (lowStock.isEmpty)
          Text(
            s.tr(
              'All part balances are above their reorder points.',
              'كل أرصدة القطع أعلى من حدود إعادة الطلب.',
            ),
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
          )
        else
          for (final p in lowStock)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.arabic ? p.nameAr : p.nameEn,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IdText(
                    p.id,
                    style: const TextStyle(fontSize: 9, color: AppColors.muted),
                  ),
                  const SizedBox(width: 8),
                  LtrText(
                    '${p.balance} / reorder ${p.reorderPoint}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _incidentPreview(TwinRepository repo, OpsState ops, AppStrings s) {
    final alerts = repo.incidents;
    final open = alerts
        .where(
          (a) => !{
            CaseStatus.resolved,
            CaseStatus.closed,
          }.contains(ops.alertStatus(a)),
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          desktop: 3,
          tablet: 3,
          mobile: 1,
          children: [
            _InlineStat(
              label: s.tr('Alerts in ledger', 'تنبيهات في السجل'),
              value: '${alerts.length}',
              unit: s.tr('alerts', 'تنبيه'),
            ),
            _InlineStat(
              label: s.tr('Still open', 'ما زال مفتوحًا'),
              value: '$open',
              unit: s.tr('alerts', 'تنبيه'),
              color: AppColors.warning,
            ),
            _InlineStat(
              label: s.tr('Security reviews', 'مراجعات أمنية'),
              value: '${repo.securityIncidents.length}',
              unit: s.tr('cases', 'حالة'),
              color: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AppTable(
          minWidth: 620,
          columns: [
            AppTableColumn(s.tr('Alert', 'التنبيه'), flex: 2),
            AppTableColumn(s.tr('Module', 'الوحدة'), flex: 2),
            AppTableColumn(s.tr('Severity', 'الخطورة'), flex: 2),
            AppTableColumn(s.tr('Status', 'الحالة'), flex: 2),
            AppTableColumn(s.tr('Created', 'أُنشئ'), flex: 2, numeric: true),
          ],
          rows: [
            for (final a in alerts)
              AppTableRow(
                cells: [
                  IdText(a.id, style: const TextStyle(fontSize: 10.5)),
                  Text(
                    s.arabic ? a.moduleAr : a.moduleEn,
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  SeverityBadge(severity: a.severity, s: s),
                  CaseStatusBadge(status: ops.alertStatus(a), s: s),
                  LtrText(
                    Fixtures.clock(a.createdAt),
                    style: const TextStyle(fontSize: 10.5),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          s.tr('Restricted security summaries', 'الملخصات الأمنية المقيدة'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        for (final i in repo.securityIncidents)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IdText(
                  i.id,
                  style: const TextStyle(fontSize: 10, color: AppColors.action),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.arabic ? i.summaryAr : i.summaryEn,
                    style: const TextStyle(fontSize: 10.5, height: 1.4),
                  ),
                ),
                const SizedBox(width: 8),
                SeverityBadge(severity: i.severity, s: s),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.sm),
        CardNote(
          s.tr(
            'Security entries are abstract aggregate patterns with no identity fields. They are reports, not evidence.',
            'المداخل الأمنية أنماط مجمعة مجردة بلا حقول هوية. هي تقارير وليست أدلة.',
          ),
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }

  Widget _executivePreview(TwinRepository repo, AppStrings s) {
    final kpis = repo.overviewKpis.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTable(
          minWidth: 680,
          columns: [
            AppTableColumn(s.tr('KPI', 'المؤشر'), flex: 3),
            AppTableColumn(s.tr('Value', 'القيمة'), flex: 2, numeric: true),
            AppTableColumn(s.tr('Unit', 'الوحدة'), flex: 1, numeric: true),
            AppTableColumn(
              s.tr('As of', 'اعتبارًا من'),
              flex: 2,
              numeric: true,
            ),
            AppTableColumn(s.tr('Mode', 'النمط'), flex: 2),
          ],
          rows: [
            for (final k in kpis)
              AppTableRow(
                cells: [
                  Text(
                    s.arabic ? k.labelAr : k.labelEn,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  LtrText(
                    k.value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    s.arabic ? k.unitAr : k.unitEn,
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  LtrText(
                    Fixtures.clock(k.asOf),
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  StatusPill(
                    label: k.source.mode.label(s),
                    color: k.source.mode.color,
                    compact: true,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        CardNote(
          s.tr(
            'Each row carries its own as-of time. Do not present the strip as a single synchronized snapshot.',
            'كل صف يحمل وقت رصده. لا تُعرض القائمة كلقطة واحدة متزامنة.',
          ),
          icon: Icons.schedule,
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
  final Color? color;
  const _Metric({
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
      child: MiniStat(
        label: label,
        value: value,
        unit: unit,
        hint: hint,
        color: color,
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;
  const _InlineStat({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.nested),
        border: Border.all(color: AppColors.border),
      ),
      child: MiniStat(label: label, value: value, unit: unit, color: color),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final _ReportSpec spec;
  final AppStrings s;
  final bool selected;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onPin;

  const _ReportRow({
    required this.spec,
    required this.s,
    required this.selected,
    required this.pinned,
    required this.onTap,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.surface
                      : AppColors.tealSoft.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(spec.icon, size: 16, color: AppColors.action),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.arabic ? spec.titleAr : spec.titleEn,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IdText(
                          spec.id,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.arabic ? spec.descAr : spec.descEn,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        StatusPill(
                          label: s.arabic ? spec.cadenceAr : spec.cadenceEn,
                          color: AppColors.info,
                          compact: true,
                        ),
                        IdText(
                          s.arabic ? spec.sourceAr : spec.sourceEn,
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
              IconButton(
                onPressed: onPin,
                tooltip: pinned
                    ? s.tr('Unpin report', 'إلغاء تثبيت التقرير')
                    : s.tr('Pin report', 'تثبيت التقرير'),
                icon: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                  color: pinned ? AppColors.action : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
