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
import '../../core/state/ops_state.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _paused = false;
  String _status = 'all';
  String _type = 'all';
  String _query = '';
  String? _selectedId = 'E-423';

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  bool _matchType(EventRecord e) {
    return switch (_type) {
      'sensor' => e.type.startsWith('sensor'),
      'queue' => e.type.startsWith('queue'),
      'bag' => e.type.startsWith('bag'),
      'gate' => e.type.startsWith('gate'),
      'automation' => e.type.startsWith('automation'),
      'incident' => e.type.startsWith('incident'),
      'adapter' =>
        e.type.startsWith('adapter') || e.type.startsWith('work_order'),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final ops = ref.watch(opsProvider);
    final user = ref.watch(currentUserProvider);
    final clock = ref.watch(demoClockProvider).value ?? Fixtures.reference;
    final canManageAutomation =
        user != null && Capability.allows(user.role, Capability.manageSettings);

    final sorted = [...repo.events]
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    final filtered = sorted.where((e) {
      final statusOk = _status == 'all' || e.status.name == _status;
      final q = _query.trim().toLowerCase();
      final queryOk =
          q.isEmpty ||
          e.eventId.toLowerCase().contains(q) ||
          e.entityId.toLowerCase().contains(q) ||
          e.type.toLowerCase().contains(q) ||
          e.summaryEn.toLowerCase().contains(q) ||
          e.summaryAr.contains(q) ||
          (e.correlationId?.toLowerCase().contains(q) ?? false);
      return statusOk && _matchType(e) && queryOk;
    }).toList();

    EventRecord? selected;
    for (final e in repo.events) {
      if (e.eventId == _selectedId) selected = e;
    }

    final committed = repo.events
        .where((e) => e.status == EventStatus.committed)
        .length;
    final exceptions = repo.events
        .where(
          (e) =>
              e.status == EventStatus.rejected ||
              e.status == EventStatus.duplicate ||
              e.status == EventStatus.retried,
        )
        .length;
    final correlations = repo.events
        .map((e) => e.correlationId)
        .whereType<String>()
        .toSet()
        .length;

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Monitoring & intelligence', 'المراقبة والذكاء'),
          title: s.tr('Live events & automation', 'الأحداث المباشرة والأتمتة'),
          subtitle: s.tr(
            'The ingestion ledger: what arrived, in what order, under which correlation chain, and which automation policy acted. This is a fixture replay, not a live socket.',
            'سجل الاستيعاب: ما وصل، وبأي ترتيب، وتحت أي سلسلة ارتباط، وأي سياسة أتمتة تصرفت. هذه إعادة عرض لبيانات ثابتة وليست بثًا حيًا.',
          ),
          actions: [
            StatusPill(
              label: _paused
                  ? s.tr('Replay paused', 'إعادة العرض متوقفة')
                  : s.tr(
                      'Replay ${cairoClock(clock)}',
                      'إعادة عرض ${cairoClock(clock)}',
                    ),
              color: _paused ? AppColors.warning : AppColors.success,
              icon: _paused
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
            ),
            FilledButton.icon(
              onPressed: () {
                setState(() => _paused = !_paused);
                _toast(
                  _paused
                      ? s.tr(
                          'Replay paused at the current fixture position.',
                          'توقفت إعادة العرض عند الموضع الحالي للبيانات الثابتة.',
                        )
                      : s.tr(
                          'Replay resumed. Fixture events are read-only.',
                          'استُئنفت إعادة العرض. أحداث البيانات الثابتة للقراءة فقط.',
                        ),
                );
              },
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 16),
              label: Text(
                _paused
                    ? s.tr('Resume replay', 'استئناف العرض')
                    : s.tr('Pause replay', 'إيقاف العرض'),
              ),
            ),
          ],
        ),
        if (_paused)
          InfoBanner(
            icon: Icons.pause_circle_outline,
            title: s.tr('Replay is paused', 'إعادة العرض متوقفة'),
            message: s.tr(
              'The visible ledger is frozen at the current fixture snapshot. No socket is open and no new event will be appended in this demo.',
              'السجل الظاهر مجمّد عند اللقطة الحالية. لا يوجد اتصال مفتوح ولن يُضاف حدث جديد في هذا العرض.',
            ),
            color: AppColors.warning,
          ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Metric(
              label: s.tr('Events in window', 'أحداث في النافذة'),
              value: '${repo.events.length}',
              unit: s.tr('events', 'حدث'),
              hint: s.tr('Ingestion ledger sample', 'عينة من سجل الاستيعاب'),
            ),
            _Metric(
              label: s.tr('Committed', 'مُثبّتة'),
              value: '$committed',
              unit: s.tr('events', 'حدث'),
              hint: s.tr(
                'Passed validation and dedupe',
                'اجتازت التحقق وإزالة التكرار',
              ),
              color: AppColors.success,
            ),
            _Metric(
              label: s.tr('Rejected / duplicate', 'مرفوضة / مكررة'),
              value: '$exceptions',
              unit: s.tr('events', 'حدث'),
              hint: s.tr(
                'Held for review, not applied',
                'محجوزة للمراجعة، غير مطبقة',
              ),
              color: AppColors.warning,
            ),
            _Metric(
              label: s.tr('Correlation chains', 'سلاسل الارتباط'),
              value: '$correlations',
              unit: s.tr('chains', 'سلسلة'),
              hint: s.tr('Traceable cause → effect', 'سبب → أثر قابل للتتبع'),
            ),
          ],
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChips<String>(
                selected: _status,
                onChanged: (v) => setState(() => _status = v),
                options: [
                  ('all', s.tr('Any status', 'أي حالة')),
                  for (final st in EventStatus.values) (st.name, st.label(s)),
                ],
              ),
              ChoiceChips<String>(
                selected: _type,
                onChanged: (v) => setState(() => _type = v),
                options: [
                  ('all', s.tr('All types', 'كل الأنواع')),
                  ('sensor', s.tr('Sensor', 'حساس')),
                  ('queue', s.tr('Queue', 'طابور')),
                  ('bag', s.tr('Baggage', 'أمتعة')),
                  ('gate', s.tr('Gate', 'بوابة')),
                  ('incident', s.tr('Incident', 'حادث')),
                  ('automation', s.tr('Automation', 'أتمتة')),
                  ('adapter', s.tr('Adapter', 'مهايئ')),
                ],
              ),
              SearchField(
                hint: s.tr('Event, entity, correlation', 'حدث، عنصر، ارتباط'),
                width: 240,
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        SplitPane(
          sideWidth: 396,
          breakpoint: 1040,
          main: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: s.tr('Event stream', 'تيار الأحداث'),
                  subtitle: s.tr(
                    '${filtered.length} of ${repo.events.length} events match · newest first',
                    '${filtered.length} من ${repo.events.length} حدثًا مطابق · الأحدث أولًا',
                  ),
                  trailing: StatusPill(
                    label: s.tr('read-only', 'للقراءة فقط'),
                    color: AppColors.muted,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
                    child: Center(
                      child: Text(
                        s.tr(
                          'No events match these filters. Clear the search or status filter.',
                          'لا توجد أحداث مطابقة. امسح البحث أو عامل الحالة.',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                for (final e in filtered)
                  _EventRow(
                    event: e,
                    s: s,
                    selected: e.eventId == (_selectedId ?? ''),
                    onTap: () => setState(() => _selectedId = e.eventId),
                  ),
                const SizedBox(height: AppSpace.sm),
                CardNote(
                  s.tr(
                    'Rejected and duplicate events remain visible in the ledger; they are never silently dropped. Status is per event, not per entity.',
                    'تظل الأحداث المرفوضة والمكررة ظاهرة في السجل ولا تُحذف بصمت. الحالة لكل حدث وليست لكل عنصر.',
                  ),
                ),
              ],
            ),
          ),
          side: _EventDetail(
            event: selected,
            events: repo.events,
            s: s,
            onOpen: _openEntity,
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Automation policies', 'سياسات الأتمتة'),
                subtitle: s.tr(
                  'Rule-driven actions with their trigger, actor and correlation trail. Toggles are local demo state only.',
                  'إجراءات مدفوعة بقواعد مع محفزها ومنفذها ومسار ارتباطها. المفاتيح حالة تجريبية محلية فقط.',
                ),
                trailing: StatusPill(
                  label: s.tr('no purchase executed', 'لا تنفيذ لشراء'),
                  color: AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              for (final run in repo.automationRuns)
                _AutomationRow(
                  run: run,
                  enabled: ops.automationEnabled(run.id),
                  canManage: canManageAutomation,
                  s: s,
                  onToggle: (value) {
                    ref
                        .read(opsProvider.notifier)
                        .toggleAutomation(run.id, value, user);
                    _toast(
                      value
                          ? s.tr(
                              '${run.id} enabled in the demo. No policy engine was invoked.',
                              'تم تمكين ${run.id} في العرض. لم يُستدعَ محرك سياسات.',
                            )
                          : s.tr(
                              '${run.id} disabled in the demo. Real automation remains unchanged.',
                              'تم تعطيل ${run.id} في العرض. الأتمتة الحقيقية دون تغيير.',
                            ),
                    );
                  },
                ),
              const SizedBox(height: AppSpace.sm),
              CardNote(
                s.tr(
                  'A disabled policy does not cancel actions already applied. The low-stock policy only queues a request and never creates a purchase.',
                  'تعطيل السياسة لا يلغي الإجراءات المطبقة سابقًا. سياسة المخزون المنخفض تدرج طلبًا فقط ولا تنشئ عملية شراء.',
                ),
                icon: Icons.policy_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openEntity(String entityType) {
    switch (entityType) {
      case 'asset':
        context.go(Routes.maintenance);
      case 'bag':
        context.go(Routes.baggage);
      case 'flight_leg':
        context.go(Routes.flights);
      case 'queue_station':
        context.go(Routes.flow);
      case 'incident':
        context.go(Routes.incidents);
      default:
        break;
    }
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

class _EventRow extends StatelessWidget {
  final EventRecord event;
  final AppStrings s;
  final bool selected;
  final VoidCallback onTap;
  const _EventRow({
    required this.event,
    required this.s,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
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
                SizedBox(
                  width: 44,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LtrText(
                        Fixtures.clock(event.observedAt),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        '${Fixtures.reference.difference(event.observedAt).inMinutes}m',
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, right: 6, left: 0),
                  decoration: BoxDecoration(
                    color: event.severity.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.arabic ? event.summaryAr : event.summaryEn,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IdText(
                            event.eventId,
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            event.type,
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.muted,
                            ),
                          ),
                          IdText(
                            event.entityId,
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.action,
                            ),
                          ),
                          StatusPill(
                            label: event.status.label(s),
                            color: event.status.color,
                            compact: true,
                          ),
                          StatusPill(
                            label: event.source.mode.label(s),
                            color: event.source.mode.color,
                            compact: true,
                          ),
                          if (event.correlationId != null)
                            IdText(
                              event.correlationId!,
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                      if (event.outcomeEn != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            s.arabic
                                ? (event.outcomeAr ?? '')
                                : event.outcomeEn!,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.action,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (event.severity.index >= Severity.high.index)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 4),
                    child: Icon(
                      Icons.priority_high,
                      size: 14,
                      color: AppColors.danger,
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

class _EventDetail extends StatelessWidget {
  final EventRecord? event;
  final List<EventRecord> events;
  final AppStrings s;
  final ValueChanged<String> onOpen;

  const _EventDetail({
    required this.event,
    required this.events,
    required this.s,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;
    if (e == null) {
      return AppCard(
        child: SizedBox(
          height: 240,
          child: ViewStateMessage(
            icon: Icons.bolt_outlined,
            title: s.tr('Select an event', 'اختر حدثًا'),
            message: s.tr(
              'Pick an entry in the stream to inspect its source, status and correlation chain.',
              'اختر مدخلًا من التيار لعرض مصدره وحالته وسلسلة ارتباطه.',
            ),
          ),
        ),
      );
    }

    final chain =
        events
            .where(
              (x) =>
                  x.correlationId != null && x.correlationId == e.correlationId,
            )
            .toList()
          ..sort((a, b) => a.observedAt.compareTo(b.observedAt));
    final t = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.tr('Event detail', 'تفاصيل الحدث'),
                  style: t.labelSmall?.copyWith(
                    color: AppColors.action,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              StatusPill(
                label: e.status.label(s),
                color: e.status.color,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          IdText(
            e.eventId,
            style: t.titleMedium?.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: 2),
          Text(e.type, style: t.bodySmall),
          const SizedBox(height: AppSpace.md),
          Text(
            s.arabic ? e.summaryAr : e.summaryEn,
            style: const TextStyle(fontSize: 11.5, height: 1.5),
          ),
          if (e.outcomeEn != null) ...[
            const SizedBox(height: 4),
            Text(
              s.arabic ? (e.outcomeAr ?? '') : e.outcomeEn!,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.action,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          SourceBadge(meta: e.source, s: s, showStream: true),
          const SizedBox(height: AppSpace.sm),
          DetailRow(
            label: s.tr('Entity', 'العنصر'),
            value: Row(
              children: [
                IdText(
                  e.entityId,
                  style: const TextStyle(fontSize: 10, color: AppColors.action),
                ),
                const SizedBox(width: 4),
                Text('· ${e.entityType}', style: t.bodySmall),
              ],
            ),
          ),
          DetailRow(
            label: s.tr('Observed', 'وقت الرصد'),
            value: DetailValue(
              '${Fixtures.clock(e.observedAt)} UTC+2',
              ltr: true,
            ),
          ),
          DetailRow(
            label: s.tr('Received', 'وقت الاستلام'),
            value: DetailValue(
              e.receivedAt == null
                  ? '—'
                  : '${Fixtures.clock(e.receivedAt!)} UTC+2',
              ltr: true,
            ),
          ),
          DetailRow(
            label: s.tr('Severity', 'الخطورة'),
            value: SeverityBadge(severity: e.severity, s: s),
          ),
          if (e.source.version != null)
            DetailRow(
              label: s.tr('Version', 'الإصدار'),
              value: DetailValue('${e.source.version}', ltr: true),
            ),
          if (e.actor != null)
            DetailRow(
              label: s.tr('Actor', 'المنفذ'),
              value: DetailValue(e.actor!, ltr: true),
            ),
          if (e.causationId != null)
            DetailRow(
              label: s.tr('Caused by', 'بسبب'),
              value: DetailValue(
                e.causationId!,
                ltr: true,
                color: AppColors.action,
              ),
            ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.tr('Correlation chain', 'سلسلة الارتباط'),
                  style: t.titleSmall,
                ),
              ),
              if (e.correlationId != null)
                IdText(
                  e.correlationId!,
                  style: const TextStyle(fontSize: 9, color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (chain.isEmpty)
            Text(
              s.tr(
                'No correlated events in this window.',
                'لا توجد أحداث مرتبطة في هذه النافذة.',
              ),
              style: t.bodySmall,
            )
          else
            for (var i = 0; i < chain.length; i++)
              _ChainStep(
                event: chain[i],
                current: chain[i].eventId == e.eventId,
                last: i == chain.length - 1,
                s: s,
              ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (e.entityType != 'automation_run' && e.entityType != 'alert')
                OutlinedButton.icon(
                  onPressed: () => onOpen(e.entityType),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: Text(
                    s.tr('Open linked module', 'فتح الوحدة المرتبطة'),
                  ),
                ),
              TextButton.icon(
                onPressed: () => context.go(Routes.incidents),
                icon: const Icon(
                  Icons.notification_important_outlined,
                  size: 14,
                ),
                label: Text(s.tr('Related alerts', 'التنبيهات المرتبطة')),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          CardNote(
            s.tr(
              'Event records are append-only fixture data. Status describes ingestion outcome, not operational severity.',
              'سجلات الأحداث بيانات ثابتة للإضافة فقط. الحالة تصف نتيجة الاستيعاب لا الخطورة التشغيلية.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainStep extends StatelessWidget {
  final EventRecord event;
  final bool current;
  final bool last;
  final AppStrings s;
  const _ChainStep({
    required this.event,
    required this.current,
    required this.last,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.severity.color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: current ? 10 : 8,
                height: current ? 10 : 8,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: current ? color : color.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: current
                      ? Border.all(color: AppColors.surface, width: 1.5)
                      : null,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IdText(
                        event.eventId,
                        style: TextStyle(
                          fontSize: 9,
                          color: current ? AppColors.navy : AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        Fixtures.clock(event.observedAt),
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: AppColors.muted,
                        ),
                      ),
                      if (current) ...[
                        const SizedBox(width: 4),
                        StatusPill(
                          label: s.tr('this event', 'هذا الحدث'),
                          color: AppColors.action,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    s.arabic ? event.summaryAr : event.summaryEn,
                    style: const TextStyle(fontSize: 9.5, height: 1.35),
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

class _AutomationRow extends StatelessWidget {
  final AutomationRun run;
  final bool enabled;
  final bool canManage;
  final AppStrings s;
  final ValueChanged<bool> onToggle;

  const _AutomationRow({
    required this.run,
    required this.enabled,
    required this.canManage,
    required this.s,
    required this.onToggle,
  });

  Color get _statusColor {
    if (run.statusEn.contains('Completed')) return AppColors.success;
    if (run.statusEn.contains('Queued')) return AppColors.info;
    if (run.statusEn.contains('Rejected')) return AppColors.danger;
    return AppColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Switch(
              value: enabled,
              onChanged: canManage ? onToggle : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.arabic ? run.ruleAr : run.ruleEn,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IdText(
                        run.id,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.arabic ? run.triggerAr : run.triggerEn,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusPill(
                        label: s.arabic ? run.statusAr : run.statusEn,
                        color: _statusColor,
                        compact: true,
                      ),
                      StatusPill(
                        label: enabled
                            ? s.tr('enabled', 'مفعّلة')
                            : s.tr('disabled', 'معطّلة'),
                        color: enabled ? AppColors.success : AppColors.muted,
                        compact: true,
                      ),
                      IdText(
                        run.actor,
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: AppColors.muted,
                        ),
                      ),
                      if (run.correlationId != null)
                        IdText(
                          run.correlationId!,
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: AppColors.muted,
                          ),
                        ),
                      LtrText(
                        Fixtures.clock(run.at),
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
            if (!canManage)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 6),
                child: Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
