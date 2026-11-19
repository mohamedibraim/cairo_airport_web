import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/fixtures.dart';
import '../../core/data/repository.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/data_table.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  int _refreshCount = 0;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Color _statusColor(HealthCheck h) {
    final v = h.statusEn.toLowerCase();
    if (v.contains('stopped')) return AppColors.danger;
    if (v.contains('degraded') || v.contains('partial')) {
      return AppColors.warning;
    }
    if (v.contains('healthy') || v.contains('running')) {
      return AppColors.success;
    }
    return AppColors.muted;
  }

  IconData _kindIcon(HealthCheck h) {
    return switch (h.kindEn) {
      'external' => Icons.cloud_outlined,
      'device' => Icons.sensors_outlined,
      'worker' => Icons.settings_suggest_outlined,
      _ => Icons.hub_outlined,
    };
  }

  bool _isHealthy(HealthCheck h) {
    final v = h.statusEn.toLowerCase();
    return v.contains('healthy') || v.contains('running');
  }

  bool _isStopped(HealthCheck h) =>
      h.statusEn.toLowerCase().contains('stopped');

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);

    final checks = repo.health;
    final healthy = checks.where(_isHealthy).length;
    final stopped = checks.where(_isStopped).length;
    final degraded = checks.length - healthy - stopped;
    final rejects = checks.fold<int>(0, (a, h) => a + (h.rejectCount ?? 0));
    final attention = checks
        .where((h) => !_isHealthy(h) || h.freshness != Freshness.fresh)
        .toList();

    final ingestion = <(EventStatus, int)>[
      for (final st in EventStatus.values)
        (st, repo.events.where((e) => e.status == st).length),
    ].where((e) => e.$2 > 0).toList();

    final freshnessCounts = <(Freshness, int)>[
      for (final f in Freshness.values)
        (f, checks.where((h) => h.freshness == f).length),
    ].where((e) => e.$2 > 0).toList();

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('System', 'النظام'),
          title: s.tr('System health', 'صحة النظام'),
          subtitle: s.tr(
            'Connector lag, rejected records, ingestion outcomes and the API contract this frontend expects. No socket is open; this is a fixture snapshot.',
            'تأخر المهايئات والسجلات المرفوضة ونتائج الاستيعاب وعقد الواجهة الذي يتوقعه هذا الواجهة. لا اتصال مفتوح؛ هذه لقطة بيانات ثابتة.',
          ),
          actions: [
            StatusPill(
              label: s.tr('fixture snapshot', 'لقطة ثابتة'),
              color: AppColors.info,
              compact: true,
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _refreshCount++);
                _toast(
                  s.tr(
                    'Health check requested (refresh #$_refreshCount). The fixture snapshot is re-read; no backend call was made.',
                    'طُلب فحص الصحة (تحديث #$_refreshCount). أُعيدت قراءة اللقطة الثابتة؛ لم يُجرَ اتصال بالخادم.',
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(s.tr('Re-check', 'إعادة الفحص')),
            ),
          ],
        ),
        if (attention.isNotEmpty)
          InfoBanner(
            icon: Icons.report_problem_outlined,
            title: s.tr(
              '${attention.length} connector(s) need attention',
              '${attention.length} مهايئًا يحتاج انتباهًا',
            ),
            message: s.tr(
              'Flight adapter is degraded, asset telemetry is partial, and the AI worker is stopped with catch-up pending. Values that depend on them must be labelled stale or unknown.',
              'مهايئ الرحلات متدهور، وبيانات المعدات جزئية، وعامل التحليل متوقف مع تعافٍ معلّق. القيم التابعة لها يجب أن تُصنّف قديمة أو غير معروفة.',
            ),
            color: AppColors.warning,
          ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Metric(
              label: s.tr('Healthy connectors', 'مهايئات سليمة'),
              value: '$healthy',
              unit: s.tr('of ${checks.length}', 'من ${checks.length}'),
              hint: s.tr('Healthy or running', 'سليم أو يعمل'),
              color: AppColors.success,
            ),
            _Metric(
              label: s.tr('Degraded / partial', 'متدهور / جزئي'),
              value: '$degraded',
              unit: s.tr('connectors', 'مهايئ'),
              hint: s.tr('AD-FLIGHT, AD-ASSET', 'AD-FLIGHT، AD-ASSET'),
              color: degraded > 0 ? AppColors.warning : AppColors.muted,
            ),
            _Metric(
              label: s.tr('Stopped', 'متوقف'),
              value: '$stopped',
              unit: s.tr('workers', 'عامل'),
              hint: s.tr('WK-AI · catch-up pending', 'WK-AI · تعافٍ معلّق'),
              color: stopped > 0 ? AppColors.danger : AppColors.muted,
            ),
            _Metric(
              label: s.tr('Rejected records', 'سجلات مرفوضة'),
              value: '$rejects',
              unit: s.tr('records', 'سجل'),
              hint: s.tr(
                'Across connectors in this window',
                'عبر المهايئات في هذه النافذة',
              ),
              color: rejects > 0 ? AppColors.warning : AppColors.success,
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Connector health', 'صحة المهايئات'),
                subtitle: s.tr(
                  'Lag is measured from the source clock, never recomputed from page load.',
                  'التأخر مقاس من ساعة المصدر ولا يُحسب من وقت تحميل الصفحة.',
                ),
                trailing: StatusPill(
                  label: s.tr(
                    '${checks.length} checks',
                    '${checks.length} فحص',
                  ),
                  color: AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              AppTable(
                minWidth: 780,
                emptyMessage: s.tr(
                  'No connectors are registered.',
                  'لا مهايئات مسجلة.',
                ),
                columns: [
                  AppTableColumn(s.tr('Connector', 'المهايئ'), flex: 4),
                  AppTableColumn(s.tr('Kind', 'النوع'), flex: 2),
                  AppTableColumn(s.tr('Status', 'الحالة'), flex: 3),
                  AppTableColumn(s.tr('Lag', 'التأخر'), flex: 2, numeric: true),
                  AppTableColumn(
                    s.tr('Rejects', 'المرفوض'),
                    flex: 2,
                    numeric: true,
                  ),
                  AppTableColumn(
                    s.tr('Last success', 'آخر نجاح'),
                    flex: 2,
                    numeric: true,
                  ),
                  AppTableColumn(s.tr('Freshness', 'الحداثة'), flex: 2),
                ],
                rows: [
                  for (final h in checks)
                    AppTableRow(
                      cells: [
                        Row(
                          children: [
                            Icon(
                              _kindIcon(h),
                              size: 15,
                              color: _statusColor(h),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.arabic ? h.nameAr : h.nameEn,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IdText(
                                    h.id,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          s.arabic ? h.kindAr : h.kindEn,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        StatusPill(
                          label: s.arabic ? h.statusAr : h.statusEn,
                          color: _statusColor(h),
                          compact: true,
                        ),
                        LtrText(
                          h.lagSeconds == null ? '—' : '${h.lagSeconds}s',
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        LtrText(
                          '${h.rejectCount ?? 0}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: (h.rejectCount ?? 0) > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: (h.rejectCount ?? 0) > 0
                                ? AppColors.danger
                                : AppColors.text,
                          ),
                        ),
                        LtrText(
                          Fixtures.clock(h.lastSuccess),
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        StatusPill(
                          label: h.freshness.label(s),
                          color: h.freshness.color,
                          compact: true,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              TableCaption(
                s.tr(
                  'Re-check only re-reads the fixture. Lag, reject counts and last-success times are frozen at 16/11/2026 10:24 UTC+2.',
                  'إعادة الفحص تعيد قراءة البيانات الثابتة فقط. التأخر وعدد المرفوضات وأوقات آخر نجاح مجمّدة عند 16/11/2026 10:24 UTC+2.',
                ),
              ),
            ],
          ),
        ),
        if (attention.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: s.tr('Attention required', 'يحتاج انتباهًا'),
                  subtitle: s.tr(
                    'Each item names the blocked capability, not just a colour.',
                    'كل بند يحدد القدرة المتأثرة وليس مجرد لون.',
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                for (final h in attention)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isStopped(h)
                              ? Icons.stop_circle_outlined
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: _statusColor(h),
                        ),
                        const SizedBox(width: 8),
                        IdText(
                          h.id,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.tr(
                              '${s.arabic ? h.nameAr : h.nameEn}: ${s.arabic ? h.statusAr : h.statusEn}. Last success ${Fixtures.clock(h.lastSuccess)}; freshness ${h.freshness.label(s)}.',
                              '${s.arabic ? h.nameAr : h.nameEn}: ${s.arabic ? h.statusAr : h.statusEn}. آخر نجاح ${Fixtures.clock(h.lastSuccess)}؛ الحداثة ${h.freshness.label(s)}.',
                            ),
                            style: const TextStyle(
                              fontSize: 10.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(
                          label: s.tr('investigate', 'تحت الفحص'),
                          color: _statusColor(h),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ResponsiveGrid(
          desktop: 2,
          tablet: 2,
          mobile: 1,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: s.tr('Ingestion outcomes', 'نتائج الاستيعاب'),
                    subtitle: s.tr(
                      'Every event carries a status; rejected and duplicate rows are retained.',
                      'كل حدث يحمل حالة؛ الصفوف المرفوضة والمكررة محفوظة.',
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  if (ingestion.isEmpty)
                    Text(
                      s.tr('No events in the ledger.', 'لا أحداث في السجل.'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                      ),
                    )
                  else
                    HBarChart(
                      data: [
                        for (final e in ingestion)
                          (e.$1.label(s), e.$2.toDouble(), '${e.$2}'),
                      ],
                      color: AppColors.action,
                    ),
                  const SizedBox(height: AppSpace.sm),
                  CardNote(
                    s.tr(
                      'A rejected event is never silently dropped and never applied to the twin.',
                      'الحدث المرفوض لا يُحذف بصمت ولا يُطبق على التوأم.',
                    ),
                    icon: Icons.rule,
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: s.tr('Freshness distribution', 'توزيع الحداثة'),
                    subtitle: s.tr(
                      'How many connectors currently claim fresh, stale or unknown data.',
                      'عدد المهايئات التي تصنّف بياناتها حديثة أو قديمة أو غير معروفة.',
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  for (final f in freshnessCounts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          StatusPill(
                            label: f.$1.label(s),
                            color: f.$1.color,
                            compact: true,
                          ),
                          const Spacer(),
                          LtrText(
                            '${f.$2} ${s.tr('connector(s)', 'مهايئ')}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpace.sm),
                  CardNote(
                    s.tr(
                      'Freshness is copied from each record. It is not inferred from how recently the page was opened.',
                      'الحداثة منقولة من كل سجل. لا تُستنتج من قرب وقت فتح الصفحة.',
                    ),
                    icon: Icons.verified_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr(
                  'API contract expected by this frontend',
                  'عقد الواجهة الذي يتوقعه هذا الواجهة',
                ),
                subtitle: s.tr(
                  'Frontend-only delivery. The repository is fixture-backed; swapping one provider for HTTP keeps every screen unchanged.',
                  'تسليم واجهة فقط. المستودع مبني على بيانات ثابتة؛ استبدال مزوّد واحد بـ HTTP يبقي كل الشاشات دون تغيير.',
                ),
                trailing: StatusPill(
                  label: s.tr('no HTTP client', 'لا عميل HTTP'),
                  color: AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              AppTable(
                minWidth: 640,
                columns: [
                  AppTableColumn(
                    s.tr('Group', 'المجموعة'),
                    flex: 1,
                    numeric: true,
                  ),
                  AppTableColumn(s.tr('Capability', 'القدرة'), flex: 3),
                  AppTableColumn(s.tr('Contracts', 'العقود'), flex: 5),
                  AppTableColumn(s.tr('State', 'الحالة'), flex: 2),
                ],
                rows: [
                  AppTableRow(
                    cells: [
                      const _ApiGroupCell('A1'),
                      const _ApiText(
                        'Session & demo users',
                        'الجلسة والمستخدمون التجريبيون',
                      ),
                      const _ApiMono('/v1/session · /v1/users'),
                      StatusPill(
                        label: s.tr('fixture', 'ثابت'),
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      const _ApiGroupCell('A2'),
                      const _ApiText('Flights & gates', 'الرحلات والبوابات'),
                      const _ApiMono('/v1/flights · /v1/gates'),
                      StatusPill(
                        label: s.tr('fixture', 'ثابت'),
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      const _ApiGroupCell('A3'),
                      const _ApiText('Baggage', 'الأمتعة'),
                      const _ApiMono('/v1/bags · /v1/bags/{id}/scans'),
                      StatusPill(
                        label: s.tr('fixture', 'ثابت'),
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      const _ApiGroupCell('A4'),
                      const _ApiText(
                        'Twin, flow & maps',
                        'التوأم والتدفق والخرائط',
                      ),
                      const _ApiMono('/v1/twin/entities · /v1/flow/stations'),
                      StatusPill(
                        label: s.tr('fixture', 'ثابت'),
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      const _ApiGroupCell('A5'),
                      const _ApiText('Maintenance', 'الصيانة'),
                      const _ApiMono(
                        '/v1/assets · /v1/work-orders · /v1/parts',
                      ),
                      StatusPill(
                        label: s.tr('fixture', 'ثابت'),
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      const _ApiGroupCell('A6'),
                      const _ApiText('Ingestion & history', 'الاستيعاب والسجل'),
                      const _ApiMono('/v1/events · /v1/health'),
                      StatusPill(
                        label: s.tr('fixture', 'ثابت'),
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      const _ApiGroupCell('A7'),
                      const _ApiText(
                        'Decisions & scenarios',
                        'القرارات والسيناريوهات',
                      ),
                      const _ApiMono(
                        '/v1/alerts · /v1/predictions · /v1/scenarios',
                      ),
                      StatusPill(
                        label: s.tr('fixture', 'ثابت'),
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      const _ApiGroupCell('A8'),
                      const _ApiText('Delivery & admin', 'التسليم والإدارة'),
                      const _ApiMono('/v1/staff · /v1/reports'),
                      StatusPill(
                        label: s.tr('fixture', 'ثابت'),
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              CardNote(
                s.tr(
                  'Reports and exports are UI-only. No production endpoint, authentication exchange or write path is implemented.',
                  'التقارير والتصدير واجهة فقط. لا توجد نقطة إنتاجية أو تبادل مصادقة أو مسار كتابة منفذ.',
                ),
                icon: Icons.api,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small private cells keep the contract table readable without leaking a
/// table-specific API into the shared widget kit.
class _ApiGroupCell extends StatelessWidget {
  final String group;
  const _ApiGroupCell(this.group);
  @override
  Widget build(BuildContext context) {
    return IdText(
      group,
      style: const TextStyle(fontSize: 10.5, color: AppColors.action),
    );
  }
}

class _ApiText extends StatelessWidget {
  final String en;
  final String ar;
  const _ApiText(this.en, this.ar);
  @override
  Widget build(BuildContext context) {
    return Text(
      Directionality.of(context) == TextDirection.rtl ? ar : en,
      style: const TextStyle(fontSize: 10.5),
    );
  }
}

class _ApiMono extends StatelessWidget {
  final String text;
  const _ApiMono(this.text);
  @override
  Widget build(BuildContext context) {
    return LtrText(
      text,
      style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
