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
import '../../core/widgets/data_table.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';
import '../../core/widgets/timeline.dart';

class BaggageScreen extends ConsumerStatefulWidget {
  const BaggageScreen({super.key});

  @override
  ConsumerState<BaggageScreen> createState() => _BaggageScreenState();
}

class _BaggageScreenState extends ConsumerState<BaggageScreen> {
  String _status = 'all';
  String _query = '';
  String? _selectedId = 'BG-2041';

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final ops = ref.watch(opsProvider);
    final user = ref.watch(currentUserProvider);
    final bags = repo.bagCases;

    final filtered = bags.where((b) {
      final statusOk =
          _status == 'all' ||
          (_status == 'exception' &&
              b.status != CaseStatus.resolved &&
              b.status != CaseStatus.closed) ||
          b.status.name == _status;
      final q = _query.trim().toLowerCase();
      final queryOk =
          q.isEmpty ||
          b.id.toLowerCase().contains(q) ||
          b.tagRef.toLowerCase().contains(q) ||
          b.flightNo.toLowerCase().contains(q) ||
          b.caseRef.toLowerCase().contains(q);
      return statusOk && queryOk;
    }).toList();

    BagCase? selected;
    for (final b in bags) {
      if (b.id == _selectedId) selected = b;
    }

    final exceptions = bags
        .where(
          (b) =>
              b.status != CaseStatus.resolved && b.status != CaseStatus.closed,
        )
        .length;
    final canManage =
        user != null && Capability.allows(user.role, Capability.manageBaggage);

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Operations', 'العمليات التشغيلية'),
          title: s.tr('Smart baggage', 'الأمتعة الذكية'),
          subtitle: s.tr(
            'Bag-level tracking, exception cases and reader provenance across bag drop, sortation, load and claim.',
            'تتبع الحقيبة وحالات الاستثناء ومصدر القراءات عبر التسليم والفرز والتحميل والاستلام.',
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => _toast(
                s.tr(
                  'Exception export queued (demo only, no file generated).',
                  'تم إدراج تصدير الاستثناءات (عرض تجريبي، دون إنشاء ملف).',
                ),
              ),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: Text(s.tr('Export exceptions', 'تصدير الاستثناءات')),
            ),
            FilledButton.icon(
              onPressed: () => context.go(Routes.twin),
              icon: const Icon(Icons.hub_outlined, size: 16),
              label: Text(s.tr('Locate on twin', 'الموقع على التوأم')),
            ),
          ],
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Stat(
              label: s.tr('Bags tracked today', 'حقيبة متتبعة اليوم'),
              value: '21,487',
              unit: s.tr('bags', 'حقيبة'),
              hint: s.tr(
                'Simulated BHS rollup · 10:24',
                'تجميع BHS محاكى · 10:24',
              ),
            ),
            _Stat(
              label: s.tr('Open exceptions', 'استثناءات مفتوحة'),
              value: '$exceptions',
              unit: s.tr('cases', 'حالة'),
              hint: s.tr(
                'Overdue scan + stale transfer',
                'تسجيل متأخر + ترانزيت قديم',
              ),
              color: AppColors.warning,
            ),
            _Stat(
              label: s.tr('Overdue next scan', 'تسجيل تالٍ متأخر'),
              value: '1',
              unit: s.tr('bag', 'حقيبة'),
              hint: s.tr('BG-2041 · CASE-412', 'BG-2041 · CASE-412'),
              color: AppColors.danger,
            ),
            _Stat(
              label: s.tr('Readers online', 'قرّاء متصلون'),
              value: '11/12',
              unit: s.tr('readers', 'قارئ'),
              hint: s.tr(
                'One reader offline in sortation',
                'قارئ واحد غير متصل في الفرز',
              ),
              color: AppColors.info,
            ),
          ],
        ),
        InfoBanner(
          icon: Icons.info_outline,
          title: s.tr(
            'A missing scan is not a lost bag',
            'التسجيل المفقود لا يعني فقدان الحقيبة',
          ),
          message: s.tr(
            'BG-2041 has no load or claim scan yet; the tracing rule opened CASE-412 for investigation. Loss must never be inferred from a single gap.',
            'لا يوجد تسجيل تحميل أو استلام لـ BG-2041 بعد؛ فتحت قاعدة التتبع CASE-412 للتحقق. لا يجوز استنتاج الفقدان من فجوة واحدة.',
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Bag case board', 'لوحة حالات الأمتعة'),
                subtitle: s.tr(
                  '${filtered.length} of ${bags.length} cases shown · unit values are per bag',
                  '${filtered.length} من ${bags.length} حالة معروضة · القيم لكل حقيبة',
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChips<String>(
                    selected: _status,
                    onChanged: (v) => setState(() => _status = v),
                    options: [
                      ('all', s.tr('All', 'الكل')),
                      ('exception', s.tr('Exceptions', 'استثناءات')),
                      ('open', s.tr('Open', 'مفتوحة')),
                      ('assigned', s.tr('Assigned', 'مُسندة')),
                      ('inProgress', s.tr('In progress', 'قيد التنفيذ')),
                      ('resolved', s.tr('Resolved', 'محلولة')),
                    ],
                  ),
                  SearchField(
                    hint: s.tr(
                      'Bag, tag, case, flight',
                      'حقيبة، وسم، حالة، رحلة',
                    ),
                    width: 220,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              AppTable(
                minWidth: 980,
                emptyMessage: s.tr(
                  'No baggage cases match these filters.',
                  'لا توجد حالات أمتعة مطابقة لعوامل التصفية.',
                ),
                columns: const [
                  AppTableColumn('Bag', flex: 2),
                  AppTableColumn('Flight', flex: 1),
                  AppTableColumn('Case', flex: 2),
                  AppTableColumn('Stage', flex: 2),
                  AppTableColumn('Last scan', flex: 2),
                  AppTableColumn('Status', flex: 2),
                  AppTableColumn('Severity', flex: 2),
                  AppTableColumn('Owner', flex: 2),
                  AppTableColumn('Source', flex: 2),
                ],
                rows: [
                  for (final b in filtered)
                    AppTableRow(
                      selected: b.id == selected?.id,
                      onTap: () => setState(() => _selectedId = b.id),
                      cells: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IdText(
                              b.id,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              b.tagRef,
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        IdText(
                          b.flightNo,
                          style: const TextStyle(fontSize: 10),
                        ),
                        IdText(
                          b.caseRef,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.action,
                          ),
                        ),
                        Text(
                          s.arabic ? b.stageAr : b.stageEn,
                          style: const TextStyle(fontSize: 10),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                Fixtures.clock(b.lastScanAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              s.tr(
                                '${_minutesAgo(b.lastScanAt)} min ago',
                                'قبل ${_minutesAgo(b.lastScanAt)} دقيقة',
                              ),
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CaseStatusBadge(status: b.status, s: s),
                            if (ops.bagAcknowledged(b.id)) ...[
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.verified,
                                size: 11,
                                color: AppColors.success,
                              ),
                            ],
                          ],
                        ),
                        SeverityBadge(severity: b.severity, s: s),
                        Text(
                          s.arabic ? b.ownerAr : b.ownerEn,
                          style: const TextStyle(fontSize: 9.5),
                        ),
                        StatusPill(
                          label: b.source.mode.label(s),
                          color: b.source.mode.color,
                          compact: true,
                        ),
                      ],
                    ),
                ],
              ),
              TableCaption(
                s.tr(
                  'Case status is distinct from bag physical state: an open case does not imply loss. Stale feeds are flagged individually.',
                  'حالة الحالة المكتبية تختلف عن الحالة الفيزيائية للحقيبة: الحالة المفتوحة لا تعني الفقدان. تُوسم البيانات القديمة منفردة.',
                ),
              ),
            ],
          ),
        ),
        if (selected != null)
          _BagDetail(
            bag: selected,
            ops: ops,
            s: s,
            canManage: canManage,
            onAcknowledge: () {
              if (!canManage) {
                _toast(
                  s.tr(
                    'Your demo role cannot manage baggage cases.',
                    'دورك التجريبي لا يملك صلاحية إدارة حالات الأمتعة.',
                  ),
                );
                return;
              }
              ref.read(opsProvider.notifier).acknowledgeBag(selected!, user);
              _toast(
                s.tr(
                  'Tracing acknowledged for ${selected.id}. Recorded in the demo audit log.',
                  'تم الإقرار بتتبع ${selected.id}. سُجل في سجل التدقيق التجريبي.',
                ),
              );
            },
          ),
      ],
    );
  }

  int _minutesAgo(DateTime utc) {
    final diff = Fixtures.reference.difference(utc).inMinutes;
    return diff < 0 ? 0 : diff;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String hint;
  final Color? color;
  const _Stat({
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

class _BagDetail extends StatelessWidget {
  final BagCase bag;
  final OpsState ops;
  final AppStrings s;
  final bool canManage;
  final VoidCallback onAcknowledge;
  const _BagDetail({
    required this.bag,
    required this.ops,
    required this.s,
    required this.canManage,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final relatedAudit = ops.audit.where((a) => a.target == bag.id).toList();
    return SplitPane(
      breakpoint: 1040,
      sideWidth: 360,
      main: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: '${s.tr('Bag', 'الحقيبة')} ${bag.id}',
              subtitle: '${bag.tagRef} · ${bag.flightNo} · ${bag.caseRef}',
              trailing: Wrap(
                spacing: 6,
                children: [
                  CaseStatusBadge(status: bag.status, s: s),
                  SeverityBadge(severity: bag.severity, s: s),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(s.tr('Journey stages', 'مراحل الرحلة'), style: t.titleSmall),
            const SizedBox(height: AppSpace.sm),
            _StageTracker(bag: bag, s: s),
            const SizedBox(height: AppSpace.lg),
            if (bag.reasonEn != null)
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: bag.severity.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: bag.severity.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 16,
                      color: bag.severity.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.tr('Exception reason', 'سبب الاستثناء'),
                            style: t.labelMedium?.copyWith(
                              color: bag.severity.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.arabic ? bag.reasonAr! : bag.reasonEn!,
                            style: t.bodySmall?.copyWith(color: AppColors.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Text(
                  s.tr('Bag event timeline', 'سجل أحداث الحقيبة'),
                  style: t.titleSmall,
                ),
                const Spacer(),
                StatusPill(
                  label: ops.bagAcknowledged(bag.id)
                      ? s.tr('acknowledged', 'تم الإقرار')
                      : s.tr('unacknowledged', 'دون إقرار'),
                  color: ops.bagAcknowledged(bag.id)
                      ? AppColors.success
                      : AppColors.warning,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            EventTimeline(
              events: bag.timeline.isEmpty
                  ? [
                      EventRecord(
                        eventId: 'E-BAG-${bag.id}',
                        type: 'bag.scan.v1',
                        entityId: bag.id,
                        entityType: 'bag',
                        summaryEn: 'Last confirmed scan at ${bag.stageEn}',
                        summaryAr: 'آخر تسجيل مؤكد عند ${bag.stageAr}',
                        observedAt: bag.lastScanAt,
                        source: bag.source,
                      ),
                    ]
                  : bag.timeline,
              s: s,
              maxItems: 6,
            ),
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
                Text(
                  s.tr('Case actions', 'إجراءات الحالة'),
                  style: t.titleSmall,
                ),
                const SizedBox(height: AppSpace.sm),
                SourceBadge(meta: bag.source, s: s, showStream: true),
                const SizedBox(height: AppSpace.md),
                DetailRow(
                  label: s.tr('Owner', 'المسؤول'),
                  value: DetailValue(s.arabic ? bag.ownerAr : bag.ownerEn),
                ),
                DetailRow(
                  label: s.tr('Zone', 'المنطقة'),
                  value: DetailValue(bag.zoneId, ltr: true),
                ),
                DetailRow(
                  label: s.tr('Last scan', 'آخر تسجيل'),
                  value: DetailValue(
                    '${Fixtures.clock(bag.lastScanAt)} UTC+2',
                    ltr: true,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                FilledButton.icon(
                  onPressed: onAcknowledge,
                  icon: Icon(
                    canManage ? Icons.check_circle_outline : Icons.lock_outline,
                    size: 16,
                  ),
                  label: Text(s.tr('Acknowledge tracing', 'الإقرار بالتتبع')),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        s.tr(
                          'Assignment to the baggage tracing desk is simulated in this demo.',
                          'الإسناد إلى مكتب تتبع الأمتعة محاكى في هذا العرض.',
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                  label: Text(s.tr('Assign tracer desk', 'إسناد مكتب التتبع')),
                ),
                if (!canManage) ...[
                  const SizedBox(height: 6),
                  CardNote(
                    s.tr(
                      'Read-only for this role. Switch to Duty Operator or Admin to acknowledge.',
                      'للقراءة فقط لهذا الدور. بدّل إلى مشغّل الخدمة أو المدير للإقرار.',
                    ),
                    icon: Icons.lock_outline,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.tr('Decision trail', 'مسار القرار'),
                  style: t.titleSmall,
                ),
                const SizedBox(height: 4),
                if (relatedAudit.isEmpty)
                  Text(
                    s.tr(
                      'No local decisions recorded for this bag yet.',
                      'لا توجد قرارات محلية مسجلة لهذه الحقيبة بعد.',
                    ),
                    style: t.bodySmall,
                  ),
                for (final a in relatedAudit)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${s.arabic ? a.actionAr : a.actionEn} · ${s.arabic ? a.actorAr : a.actorEn}',
                            style: const TextStyle(fontSize: 10, height: 1.4),
                          ),
                        ),
                        Text(
                          Fixtures.clock(a.at),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: AppSpace.lg),
                CardNote(
                  s.tr(
                    'No purchase or passenger-contact action is performed from this screen.',
                    'لا يتم تنفيذ أي شراء أو تواصل مع المسافر من هذه الشاشة.',
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

class _StageTracker extends StatelessWidget {
  final BagCase bag;
  final AppStrings s;
  const _StageTracker({required this.bag, required this.s});

  @override
  Widget build(BuildContext context) {
    final stages = bag.stages;
    if (stages.isEmpty) {
      return Text(
        s.tr(
          'Stage-level scans are not available for this bag; last known stage: ${bag.stageEn}.',
          'لا تتوفر تسجيلات المراحل لهذه الحقيبة؛ آخر مرحلة معروفة: ${bag.stageAr}.',
        ),
        style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 640;
        final children = [
          for (var i = 0; i < stages.length; i++)
            _StageNode(
              stage: stages[i],
              s: s,
              last: i == stages.length - 1,
              narrow: narrow,
            ),
        ];
        if (narrow) return Column(children: children);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final node in children) Expanded(child: node)],
        );
      },
    );
  }
}

class _StageNode extends StatelessWidget {
  final BagStage stage;
  final AppStrings s;
  final bool last;
  final bool narrow;
  const _StageNode({
    required this.stage,
    required this.s,
    required this.last,
    required this.narrow,
  });

  @override
  Widget build(BuildContext context) {
    final color = stage.confirmed
        ? AppColors.success
        : (stage.expected ? AppColors.muted : AppColors.warning);
    final icon = stage.confirmed
        ? Icons.check_circle
        : (stage.expected ? Icons.radio_button_unchecked : Icons.error_outline);
    final circle = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, size: 13, color: color),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.arabic ? stage.stageAr : stage.stageEn,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 1),
        Text(
          s.arabic ? stage.readerAr : stage.readerEn,
          style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
        ),
        Text(
          stage.at == null
              ? s.tr('expected', 'متوقع')
              : Fixtures.clock(stage.at!),
          style: TextStyle(
            fontSize: 8.5,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (narrow) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            circle,
            const SizedBox(width: 8),
            Expanded(child: info),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            circle,
            if (!last)
              Expanded(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: AppColors.border,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        info,
      ],
    );
  }
}
