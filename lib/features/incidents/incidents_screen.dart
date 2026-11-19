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

class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  int _tab = 0;
  String _severity = 'all';
  String _status = 'all';
  String _query = '';
  String? _alertId = 'ALT-701';
  String? _securityId = 'SEC-201';

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  bool _match(
    String title,
    String detail,
    String id,
    Severity severity,
    CaseStatus status,
  ) {
    final sevOk = _severity == 'all' || severity.name == _severity;
    final statusOk = _status == 'all' || status.name == _status;
    final q = _query.trim().toLowerCase();
    final queryOk =
        q.isEmpty ||
        title.toLowerCase().contains(q) ||
        detail.toLowerCase().contains(q) ||
        id.toLowerCase().contains(q);
    return sevOk && statusOk && queryOk;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final ops = ref.watch(opsProvider);
    final user = ref.watch(currentUserProvider);
    final canAck =
        user != null &&
        Capability.allows(user.role, Capability.acknowledgeAlerts);
    final canReview =
        user != null &&
        Capability.allows(user.role, Capability.reviewIncidents);

    final alerts = repo.incidents.where((a) {
      final st = ops.alertStatuses[a.id] ?? a.status;
      return _match(a.titleEn, a.detailEn, a.id, a.severity, st);
    }).toList()..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    final security = repo.securityIncidents.where((i) {
      final st = ops.alertStatuses[i.id] ?? i.status;
      return _match(i.summaryEn, i.classificationEn, i.id, i.severity, st);
    }).toList();

    OpsAlert? selectedAlert;
    for (final a in repo.incidents) {
      if (a.id == _alertId) selectedAlert = a;
    }
    SecurityIncident? selectedSecurity;
    for (final i in repo.securityIncidents) {
      if (i.id == _securityId) selectedSecurity = i;
    }

    final activeAlerts = repo.incidents
        .where(
          (a) => !{
            CaseStatus.resolved,
            CaseStatus.closed,
          }.contains(ops.alertStatuses[a.id] ?? a.status),
        )
        .length;
    final highSeverity = repo.incidents
        .where(
          (a) =>
              a.severity.index >= Severity.high.index &&
              !{
                CaseStatus.resolved,
                CaseStatus.closed,
              }.contains(ops.alertStatuses[a.id] ?? a.status),
        )
        .length;
    final staleFeeds = repo.stations
        .where((q) => q.source.freshness == Freshness.stale)
        .length;

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Monitoring & intelligence', 'المراقبة والذكاء'),
          title: s.tr('Alerts & incidents', 'التنبيهات والحوادث'),
          subtitle: s.tr(
            'Operational exceptions and restricted security summaries. Every decision is attributed and audit-logged in the demo session.',
            'استثناءات تشغيلية وملخصات أمنية مقيدة. كل قرار موثق في سجل التدقيق التجريبي.',
          ),
          actions: [
            StatusPill(
              label: s.tr('audit on', 'التدقيق مفعّل'),
              color: AppColors.success,
              icon: Icons.verified_user_outlined,
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _severity = 'all';
                  _status = 'open';
                  _query = '';
                });
              },
              icon: const Icon(Icons.filter_alt_outlined, size: 16),
              label: Text(s.tr('Open only', 'المفتوحة فقط')),
            ),
          ],
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Stat(
              label: s.tr('Active alerts', 'تنبيهات نشطة'),
              value: '$activeAlerts',
              unit: s.tr('alerts', 'تنبيه'),
              hint: s.tr(
                'Excludes resolved and closed',
                'باستثناء المحلولة والمغلقة',
              ),
              color: AppColors.warning,
            ),
            _Stat(
              label: s.tr('High / critical', 'عالية / حرجة'),
              value: '$highSeverity',
              unit: s.tr('alerts', 'تنبيه'),
              hint: s.tr('CON-003 and BG-2041', 'CON-003 و BG-2041'),
              color: AppColors.danger,
            ),
            _Stat(
              label: s.tr('Security reviews', 'مراجعات أمنية'),
              value: '${repo.securityIncidents.length}',
              unit: s.tr('cases', 'حالة'),
              hint: s.tr(
                'Restricted aggregate summaries',
                'ملخصات مجمعة مقيدة',
              ),
            ),
            _Stat(
              label: s.tr('Stale feeds', 'بيانات قديمة'),
              value: '$staleFeeds',
              unit: s.tr('stations', 'محطة'),
              hint: s.tr(
                'Immigration feed 26 min old',
                'بيانات الجوازات أقدم 26 دقيقة',
              ),
              color: AppColors.info,
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
              ChoiceChips<int>(
                selected: _tab,
                onChanged: (v) => setState(() => _tab = v),
                options: [
                  (0, s.tr('Operational alerts', 'تنبيهات تشغيلية')),
                  (1, s.tr('Security incidents', 'حوادث أمنية')),
                ],
              ),
              const SizedBox(width: 8),
              ChoiceChips<String>(
                selected: _severity,
                onChanged: (v) => setState(() => _severity = v),
                options: [
                  ('all', s.tr('Any severity', 'أي خطورة')),
                  for (final sev in Severity.values) (sev.name, sev.label(s)),
                ],
              ),
              ChoiceChips<String>(
                selected: _status,
                onChanged: (v) => setState(() => _status = v),
                options: [
                  ('all', s.tr('Any status', 'أي حالة')),
                  for (final st in [
                    CaseStatus.open,
                    CaseStatus.assigned,
                    CaseStatus.inProgress,
                    CaseStatus.resolved,
                  ])
                    (st.name, st.label(s)),
                ],
              ),
              SearchField(
                hint: s.tr('Search alerts', 'بحث التنبيهات'),
                width: 200,
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        if (_tab == 1)
          InfoBanner(
            icon: Icons.shield_outlined,
            title: s.tr('Restricted security workspace', 'مساحة أمنية مقيدة'),
            message: s.tr(
              'Only aggregate, synthetic summaries are shown. No passenger identity, biometric data or personal record is displayed or stored in this frontend.',
              'تُعرض ملخصات مجمعة اصطناعية فقط. لا تُعرض أو تُخزن أي هوية مسافر أو بيانات حيوية أو سجل شخصي في هذه الواجهة.',
            ),
            color: AppColors.navy,
          ),
        if (_tab == 0)
          SplitPane(
            breakpoint: 1000,
            sideWidth: 380,
            main: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: s.tr(
                      'Operational alert queue',
                      'طابور التنبيهات التشغيلية',
                    ),
                    subtitle: s.tr(
                      '${alerts.length} matching · sorted by severity',
                      '${alerts.length} مطابق · مرتبة حسب الخطورة',
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  if (alerts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpace.xxl),
                      child: Center(
                        child: Text(
                          'No alerts match these filters.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  for (final a in alerts)
                    _AlertTile(
                      alert: a,
                      status: ops.alertStatuses[a.id] ?? a.status,
                      assignee: ops.alertAssignees[a.id],
                      s: s,
                      selected: a.id == (_alertId ?? ''),
                      onTap: () => setState(() => _alertId = a.id),
                      onAck: () {
                        if (!canAck) {
                          _toast(
                            s.tr(
                              'Your demo role cannot acknowledge alerts.',
                              'دورك التجريبي لا يملك صلاحية الإقرار بالتنبيهات.',
                            ),
                          );
                          return;
                        }
                        ref
                            .read(opsProvider.notifier)
                            .setAlertStatus(a, CaseStatus.assigned, user);
                        _toast(
                          s.tr(
                            '${a.id} acknowledged and assigned to the queue.',
                            'تم الإقرار بـ ${a.id} وإسناده إلى الطابور.',
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            side: _AlertDetail(
              alert: selectedAlert,
              ops: ops,
              s: s,
              events: repo.events,
              canAck: canAck,
              onStatus: (status) {
                if (selectedAlert == null) return;
                ref
                    .read(opsProvider.notifier)
                    .setAlertStatus(selectedAlert, status, user);
                _toast(
                  s.tr(
                    '${selectedAlert.id} set to ${status.label(s)}.',
                    '${selectedAlert.id} حُدّث إلى ${status.label(s)}.',
                  ),
                );
              },
              onAssign: () {
                if (selectedAlert == null) return;
                ref
                    .read(opsProvider.notifier)
                    .assignAlert(
                      selectedAlert,
                      user?.nameEn ?? 'Demo operator',
                      user?.nameAr ?? 'مشغّل تجريبي',
                      user,
                    );
                _toast(
                  s.tr(
                    '${selectedAlert.id} assigned to you.',
                    '${selectedAlert.id} أُسند إليك.',
                  ),
                );
              },
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: s.tr(
                        'Security incident register',
                        'سجل الحوادث الأمنية',
                      ),
                      subtitle: s.tr(
                        'Restricted fields · classification and zone only',
                        'حقول مقيدة · التصنيف والمنطقة فقط',
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    AppTable(
                      minWidth: 860,
                      emptyMessage: s.tr(
                        'No security incidents match these filters.',
                        'لا توجد حوادث أمنية مطابقة.',
                      ),
                      columns: const [
                        AppTableColumn('Incident', flex: 2),
                        AppTableColumn('Summary', flex: 4),
                        AppTableColumn('Classification', flex: 2),
                        AppTableColumn('Zone', flex: 1),
                        AppTableColumn('Severity', flex: 2),
                        AppTableColumn('Status', flex: 2),
                        AppTableColumn('Detected', flex: 2),
                      ],
                      rows: [
                        for (final i in security)
                          AppTableRow(
                            selected: i.id == (_securityId ?? ''),
                            onTap: () => setState(() => _securityId = i.id),
                            cells: [
                              IdText(
                                i.id,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.navy,
                                ),
                              ),
                              Text(
                                s.arabic ? i.summaryAr : i.summaryEn,
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.35,
                                ),
                              ),
                              Text(
                                s.arabic
                                    ? i.classificationAr
                                    : i.classificationEn,
                                style: const TextStyle(fontSize: 9.5),
                              ),
                              IdText(
                                i.zoneId,
                                style: const TextStyle(fontSize: 9.5),
                              ),
                              SeverityBadge(severity: i.severity, s: s),
                              CaseStatusBadge(
                                status: ops.alertStatuses[i.id] ?? i.status,
                                s: s,
                              ),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  Fixtures.clock(i.detectedAt),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    TableCaption(
                      s.tr(
                        'Security entries are synthetic review summaries. Identity, camera footage and personal data are out of scope for this web frontend.',
                        'المدخلات الأمنية ملخصات مراجعة اصطناعية. الهوية وتسجيلات الكاميرا والبيانات الشخصية خارج نطاق هذه الواجهة.',
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedSecurity != null) ...[
                const SizedBox(height: AppSpace.lg),
                _SecurityDetail(
                  incident: selectedSecurity,
                  ops: ops,
                  s: s,
                  canReview: canReview,
                  onAssign: () {
                    ref
                        .read(opsProvider.notifier)
                        .assignSecurityIncident(
                          selectedSecurity!,
                          user?.nameEn ?? 'Demo operator',
                          user?.nameAr ?? 'مشغّل تجريبي',
                          user,
                        );
                    _toast(
                      s.tr(
                        '${selectedSecurity.id} assigned to you.',
                        '${selectedSecurity.id} أُسند إليك.',
                      ),
                    );
                  },
                  onStatus: (status) {
                    ref
                        .read(opsProvider.notifier)
                        .setSecurityStatus(selectedSecurity!, status, user);
                    _toast(
                      s.tr(
                        '${selectedSecurity.id} set to ${status.label(s)}.',
                        '${selectedSecurity.id} حُدّث إلى ${status.label(s)}.',
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        if (ops.audit.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: s.tr(
                    'Session decision trail',
                    'مسار القرارات في الجلسة',
                  ),
                  subtitle: s.tr(
                    'Newest first · fixture clock',
                    'الأحدث أولًا · ساعة العرض',
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                for (final a in ops.audit.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${s.arabic ? a.actionAr : a.actionEn} — ${a.target}',
                            style: const TextStyle(fontSize: 10, height: 1.4),
                          ),
                        ),
                        Text(
                          '${s.arabic ? a.actorAr : a.actorEn} · ${Fixtures.clock(a.at)}',
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
          ),
      ],
    );
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

class _AlertTile extends StatelessWidget {
  final OpsAlert alert;
  final CaseStatus status;
  final String? assignee;
  final AppStrings s;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onAck;
  const _AlertTile({
    required this.alert,
    required this.status,
    required this.assignee,
    required this.s,
    required this.selected,
    required this.onTap,
    required this.onAck,
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
                Container(
                  width: 3,
                  height: 48,
                  decoration: BoxDecoration(
                    color: alert.severity.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IdText(
                            alert.id,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.arabic ? alert.moduleAr : alert.moduleEn,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Fixtures.clock(alert.createdAt),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.arabic ? alert.titleAr : alert.titleEn,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.arabic ? alert.detailAr : alert.detailEn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SeverityBadge(severity: alert.severity, s: s),
                          CaseStatusBadge(status: status, s: s),
                          IdText(
                            alert.entityId,
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.muted,
                            ),
                          ),
                          if (assignee != null)
                            StatusPill(
                              label: assignee!,
                              color: AppColors.info,
                              compact: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status == CaseStatus.open)
                  IconButton(
                    tooltip: s.tr('Acknowledge', 'إقرار'),
                    onPressed: onAck,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 17,
                      color: AppColors.action,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertDetail extends StatelessWidget {
  final OpsAlert? alert;
  final OpsState ops;
  final AppStrings s;
  final List<EventRecord> events;
  final bool canAck;
  final ValueChanged<CaseStatus> onStatus;
  final VoidCallback onAssign;

  const _AlertDetail({
    required this.alert,
    required this.ops,
    required this.s,
    required this.events,
    required this.canAck,
    required this.onStatus,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final a = alert;
    if (a == null) {
      return const AppCard(
        child: SizedBox(
          height: 220,
          child: ViewStateMessage(
            icon: Icons.notifications_none,
            title: 'Select an alert',
            message: 'Pick an alert to inspect its provenance and act.',
          ),
        ),
      );
    }
    final related = events
        .where(
          (e) =>
              e.correlationId == a.source.correlationId ||
              e.entityId == a.entityId,
        )
        .toList();
    final trail = ops.audit.where((x) => x.target == a.id).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.arabic ? a.titleAr : a.titleEn,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              IdText(
                a.id,
                style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
              ),
              const Spacer(),
              SeverityBadge(severity: a.severity, s: s),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            s.arabic ? a.detailAr : a.detailEn,
            style: const TextStyle(fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: [
              CaseStatusBadge(status: ops.alertStatus(a), s: s),
              if (ops.alertAssignees[a.id] != null)
                StatusPill(
                  label: ops.alertAssignees[a.id]!,
                  color: AppColors.info,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SourceBadge(meta: a.source, s: s, showStream: true),
          const SizedBox(height: AppSpace.md),
          DetailRow(
            label: s.tr('Module', 'الوحدة'),
            value: DetailValue(s.arabic ? a.moduleAr : a.moduleEn),
          ),
          DetailRow(
            label: s.tr('Linked entity', 'العنصر المرتبط'),
            value: TextButton(
              onPressed: () => context.go(Routes.twin),
              child: IdText(a.entityId, style: const TextStyle(fontSize: 10)),
            ),
          ),
          DetailRow(
            label: s.tr('Opened', 'فُتح'),
            value: DetailValue(
              '${Fixtures.clock(a.createdAt)} UTC+2',
              ltr: true,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton.icon(
            onPressed: canAck
                ? () {
                    if (ops.alertStatus(a) == CaseStatus.open) {
                      onStatus(CaseStatus.assigned);
                    } else if (ops.alertStatus(a) != CaseStatus.resolved) {
                      onStatus(CaseStatus.resolved);
                    }
                  }
                : null,
            icon: Icon(
              ops.alertStatus(a) == CaseStatus.resolved
                  ? Icons.verified_outlined
                  : Icons.check_circle_outline,
              size: 16,
            ),
            label: Text(
              ops.alertStatus(a) == CaseStatus.resolved
                  ? s.tr('Resolved', 'تم الحل')
                  : s.tr('Acknowledge / resolve', 'إقرار / حل'),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: canAck ? onAssign : null,
            icon: const Icon(Icons.person_add_alt, size: 16),
            label: Text(s.tr('Assign to me', 'إسناد إليّ')),
          ),
          if (!canAck) ...[
            const SizedBox(height: 6),
            CardNote(
              s.tr('Read-only for this role.', 'للقراءة فقط لهذا الدور.'),
              icon: Icons.lock_outline,
            ),
          ],
          const Divider(height: AppSpace.xl),
          Text(
            s.tr('Evidence events', 'أحداث الإثبات'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          EventTimeline(
            events: related.isEmpty
                ? [
                    EventRecord(
                      eventId: 'E-${a.id}',
                      type: 'alert.opened.v1',
                      entityId: a.entityId,
                      entityType: 'alert',
                      summaryEn: a.detailEn,
                      summaryAr: a.detailAr,
                      observedAt: a.createdAt,
                      source: a.source,
                      severity: a.severity,
                    ),
                  ]
                : related,
            s: s,
            maxItems: 4,
            dense: true,
          ),
          if (trail.isNotEmpty) ...[
            const Divider(height: AppSpace.xl),
            Text(
              s.tr('Local decisions', 'القرارات المحلية'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final x in trail.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${s.arabic ? x.actionAr : x.actionEn} · ${Fixtures.clock(x.at)}',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SecurityDetail extends StatelessWidget {
  final SecurityIncident incident;
  final OpsState ops;
  final AppStrings s;
  final bool canReview;
  final VoidCallback onAssign;
  final ValueChanged<CaseStatus> onStatus;

  const _SecurityDetail({
    required this.incident,
    required this.ops,
    required this.s,
    required this.canReview,
    required this.onAssign,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = ops.alertStatuses[incident.id] ?? incident.status;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: '${s.tr('Security review', 'مراجعة أمنية')} ${incident.id}',
            subtitle: s.arabic
                ? incident.classificationAr
                : incident.classificationEn,
            trailing: Wrap(
              spacing: 6,
              children: [
                SeverityBadge(severity: incident.severity, s: s),
                CaseStatusBadge(status: status, s: s),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            s.arabic ? incident.summaryAr : incident.summaryEn,
            style: const TextStyle(fontSize: 11.5, height: 1.5),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.xl,
            runSpacing: AppSpace.md,
            children: [
              _Kv(
                label: s.tr('Zone', 'المنطقة'),
                value: incident.zoneId,
                ltr: true,
              ),
              _Kv(
                label: s.tr('Detected', 'وقت الرصد'),
                value: Fixtures.clock(incident.detectedAt),
                ltr: true,
              ),
              _Kv(
                label: s.tr('Assignee', 'المسؤول'),
                value:
                    ops.alertAssignees[incident.id] ??
                    (s.arabic ? incident.assigneeAr : incident.assigneeEn),
              ),
              _Kv(
                label: s.tr('Source', 'المصدر'),
                value: incident.source.mode.label(s),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (!canReview)
            InfoBanner(
              icon: Icons.lock_outline,
              title: s.tr(
                'Security reviewer role required',
                'يتطلب دور مراجع الأمن',
              ),
              message: s.tr(
                'This account can view the aggregate summary but cannot change its state. Switch to Security Reviewer to act.',
                'يمكن لهذا الحساب عرض الملخص المجمع دون تغيير حالته. بدّل إلى مراجع الأمن لاتخاذ إجراء.',
              ),
            )
          else
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                FilledButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                  label: Text(s.tr('Assign to me', 'إسناد إليّ')),
                ),
                OutlinedButton.icon(
                  onPressed: () => onStatus(CaseStatus.inProgress),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text(s.tr('Start review', 'بدء المراجعة')),
                ),
                OutlinedButton.icon(
                  onPressed: () => onStatus(CaseStatus.pendingVerification),
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: Text(s.tr('Send for verification', 'إرسال للتحقق')),
                ),
                TextButton.icon(
                  onPressed: () => onStatus(CaseStatus.resolved),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(s.tr('Resolve', 'حل')),
                ),
              ],
            ),
          const SizedBox(height: AppSpace.md),
          CardNote(
            s.tr(
              'No identity or personal record is displayed. Case content is a synthetic review summary.',
              'لا تُعرض هوية أو سجل شخصي. محتوى الحالة ملخص مراجعة اصطناعي.',
            ),
            icon: Icons.shield_outlined,
          ),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  final String label;
  final String value;
  final bool ltr;
  const _Kv({required this.label, required this.value, this.ltr = false});
  @override
  Widget build(BuildContext context) {
    final v = Text(
      value,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        if (ltr)
          Directionality(textDirection: TextDirection.ltr, child: v)
        else
          v,
      ],
    );
  }
}
