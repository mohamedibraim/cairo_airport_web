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
import '../../core/widgets/timeline.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  String _state = 'all';
  String _query = '';
  String? _assetId = 'CAI-T2-BHS-CON-003';

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
    final canAssign =
        user != null &&
        Capability.allows(user.role, Capability.assignWorkOrders);
    final canInventory =
        user != null &&
        Capability.allows(user.role, Capability.manageInventory);

    final assets = repo.assets.where((a) {
      final stateOk = _state == 'all' || a.state.name == _state;
      final q = _query.trim().toLowerCase();
      final queryOk =
          q.isEmpty ||
          a.id.toLowerCase().contains(q) ||
          a.nameEn.toLowerCase().contains(q) ||
          a.nameAr.contains(q) ||
          a.zoneId.toLowerCase().contains(q);
      return stateOk && queryOk;
    }).toList();

    AssetRecord? selected;
    for (final a in repo.assets) {
      if (a.id == _assetId) selected = a;
    }

    final avgHealth = repo.assets.isEmpty
        ? 0
        : (repo.assets.fold<int>(0, (a, b) => a + b.healthScore) /
                  repo.assets.length)
              .round();
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

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Operations', 'العمليات التشغيلية'),
          title: s.tr('Equipment & maintenance', 'المعدات والصيانة'),
          subtitle: s.tr(
            'Asset health, sensor provenance, work orders and spare-part balances for Terminal 2 equipment.',
            'صحة الأصول ومصدر الحساسات وأوامر العمل وأرصدة قطع الغيار لمعدات مبنى الركاب 2.',
          ),
          actions: [
            StatusPill(
              label: s.tr('telemetry simulated', 'بيانات محاكاة'),
              color: AppColors.info,
            ),
            OutlinedButton.icon(
              onPressed: () => _toast(
                s.tr(
                  'Maintenance report export queued (demo only).',
                  'تم إدراج تصدير تقرير الصيانة (عرض تجريبي).',
                ),
              ),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: Text(s.tr('Export report', 'تصدير التقرير')),
            ),
          ],
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Stat(
              label: s.tr('Monitored assets', 'أصول مراقبة'),
              value: '${repo.assets.length}',
              unit: s.tr('assets', 'أصل'),
              hint: s.tr(
                'Sample of 25 in the readiness rollup',
                'عينة من 25 في تجميع الجاهزية',
              ),
            ),
            _Stat(
              label: s.tr('Faulted assets', 'أصول معطلة'),
              value:
                  '${repo.assets.where((a) => a.state == EntityState.fault).length}',
              unit: s.tr('assets', 'أصل'),
              hint: s.tr(
                'CON-003 · vibration 7.1 mm/s',
                'CON-003 · اهتزاز 7.1 ملم/ث',
              ),
              color: AppColors.danger,
            ),
            _Stat(
              label: s.tr('Average health', 'متوسط الصحة'),
              value: '$avgHealth',
              unit: '/100',
              hint: s.tr(
                'Simple mean of sampled assets',
                'متوسط بسيط للأصول المعاينة',
              ),
              color: avgHealth >= 80 ? AppColors.success : AppColors.warning,
            ),
            _Stat(
              label: s.tr('Open work orders', 'أوامر عمل مفتوحة'),
              value: '$openOrders',
              unit: s.tr('orders', 'أمر'),
              hint: s.tr(
                '${lowStock.length} low-stock part(s)',
                '${lowStock.length} قطعة منخفضة',
              ),
              color: AppColors.info,
            ),
          ],
        ),
        if (lowStock.isNotEmpty)
          InfoBanner(
            icon: Icons.inventory_2_outlined,
            title: s.tr(
              'Spare part reorder points reached',
              'بلوغ حدود إعادة طلب قطع الغيار',
            ),
            message: s.arabic
                ? lowStock
                      .map((p) => '${p.nameAr}: ${p.balance}/${p.reorderPoint}')
                      .join(' · ')
                : lowStock
                      .map((p) => '${p.nameEn}: ${p.balance}/${p.reorderPoint}')
                      .join(' · '),
            color: AppColors.warning,
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Asset register', 'سجل الأصول'),
                subtitle: s.tr(
                  'Health score is a derived indicator, not a guarantee of remaining life.',
                  'مؤشر الصحة مؤشر مشتق وليس ضمانًا لعمر التشغيل المتبقي.',
                ),
                trailing: Text(
                  s.tr('${assets.length} shown', '${assets.length} معروض'),
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
                    selected: _state,
                    onChanged: (v) => setState(() => _state = v),
                    options: [
                      ('all', s.tr('All states', 'كل الحالات')),
                      for (final st in [
                        EntityState.operational,
                        EntityState.warning,
                        EntityState.fault,
                        EntityState.maintenance,
                      ])
                        (st.name, st.label(s)),
                    ],
                  ),
                  SearchField(
                    hint: s.tr(
                      'Asset ID, zone, name',
                      'معرف الأصل، المنطقة، الاسم',
                    ),
                    width: 230,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              AppTable(
                minWidth: 900,
                emptyMessage: s.tr(
                  'No assets match these filters.',
                  'لا توجد أصول مطابقة.',
                ),
                columns: const [
                  AppTableColumn('Asset', flex: 3),
                  AppTableColumn('Zone', flex: 1),
                  AppTableColumn('State', flex: 2),
                  AppTableColumn('Health', flex: 2),
                  AppTableColumn('Sensors', flex: 2),
                  AppTableColumn('Order', flex: 1),
                  AppTableColumn('Source', flex: 2),
                ],
                rows: [
                  for (final a in assets)
                    AppTableRow(
                      selected: a.id == selected?.id,
                      onTap: () => setState(() => _assetId = a.id),
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
                                fontSize: 8.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        IdText(a.zoneId, style: const TextStyle(fontSize: 9.5)),
                        StateBadge(state: a.state, s: s),
                        Row(
                          children: [
                            Expanded(
                              child: ScoreBar(
                                value: a.healthScore.toDouble(),
                                color: a.healthScore < 50
                                    ? AppColors.danger
                                    : (a.healthScore < 80
                                          ? AppColors.warning
                                          : AppColors.success),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '${a.healthScore}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          a.sensorIds.length == 1
                              ? a.sensorIds.first
                              : '${a.sensorIds.length} sensors',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                        if (a.activeOrderId != null)
                          IdText(
                            a.activeOrderId!,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.action,
                            ),
                          )
                        else
                          const Text(
                            '—',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                            ),
                          ),
                        StatusPill(
                          label: a.source.mode.label(s),
                          color: a.source.mode.color,
                          compact: true,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        if (selected != null)
          _AssetDetail(
            asset: selected,
            s: s,
            ops: ops,
            user: user,
            canAssign: canAssign,
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Work order board', 'لوحة أوامر العمل'),
                subtitle: s.tr(
                  'Assignment and status changes are local demo decisions with an audit trail.',
                  'الإسناد وتغيير الحالة قرارات محلية تجريبية مع سجل تدقيق.',
                ),
                trailing: StatusPill(
                  label: s.tr('versioned', 'بإصدارات'),
                  color: AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              LayoutBuilder(
                builder: (context, c) {
                  final columns = [
                    CaseStatus.assigned,
                    CaseStatus.inProgress,
                    CaseStatus.pendingVerification,
                    CaseStatus.resolved,
                  ];
                  if (c.maxWidth < 1000) {
                    return Column(
                      children: [
                        for (final st in columns)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.md),
                            child: _BoardColumn(
                              status: st,
                              orders: repo.workOrders
                                  .where((o) => ops.workOrderStatus(o) == st)
                                  .toList(),
                              ops: ops,
                              s: s,
                              canAssign: canAssign,
                              onMove: (o, target) {
                                ref
                                    .read(opsProvider.notifier)
                                    .setWorkOrderStatus(o, target, user);
                                _toast(
                                  s.tr(
                                    '${o.id} moved to ${target.label(s)}.',
                                    '${o.id} نُقل إلى ${target.label(s)}.',
                                  ),
                                );
                              },
                              onAssign: (o) {
                                ref
                                    .read(opsProvider.notifier)
                                    .assignWorkOrder(
                                      o,
                                      user?.nameEn ?? 'Demo operator',
                                      user?.nameAr ?? 'مشغّل تجريبي',
                                      user,
                                    );
                                _toast(
                                  s.tr(
                                    '${o.id} assigned to you.',
                                    '${o.id} أُسند إليك.',
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final st in columns) ...[
                        Expanded(
                          child: _BoardColumn(
                            status: st,
                            orders: repo.workOrders
                                .where((o) => ops.workOrderStatus(o) == st)
                                .toList(),
                            ops: ops,
                            s: s,
                            canAssign: canAssign,
                            onMove: (o, target) {
                              ref
                                  .read(opsProvider.notifier)
                                  .setWorkOrderStatus(o, target, user);
                              _toast(
                                s.tr(
                                  '${o.id} moved to ${target.label(s)}.',
                                  '${o.id} نُقل إلى ${target.label(s)}.',
                                ),
                              );
                            },
                            onAssign: (o) {
                              ref
                                  .read(opsProvider.notifier)
                                  .assignWorkOrder(
                                    o,
                                    user?.nameEn ?? 'Demo operator',
                                    user?.nameAr ?? 'مشغّل تجريبي',
                                    user,
                                  );
                              _toast(
                                s.tr(
                                  '${o.id} assigned to you.',
                                  '${o.id} أُسند إليك.',
                                ),
                              );
                            },
                          ),
                        ),
                        if (st != columns.last)
                          const SizedBox(width: AppSpace.md),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              CardNote(
                s.tr(
                  'Verification requires a fresh same-asset reading; closing an order without confirmation is blocked in the real workflow.',
                  'يتطلب التحقق قراءة جديدة من نفس الأصل؛ إغلاق الأمر دون تأكيد محظور في سير العمل الحقيقي.',
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Spare parts', 'قطع الغيار'),
                subtitle: s.tr(
                  'Balance vs. reorder point · requesting stock never creates a purchase.',
                  'الرصيد مقابل حد إعادة الطلب · طلب المخزون لا ينشئ عملية شراء.',
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              AppTable(
                minWidth: 680,
                columns: const [
                  AppTableColumn('Part', flex: 3),
                  AppTableColumn('Balance', flex: 2),
                  AppTableColumn('Reorder point', flex: 2),
                  AppTableColumn('Location', flex: 2),
                  AppTableColumn('Status', flex: 2),
                  AppTableColumn('Action', flex: 2),
                ],
                rows: [
                  for (final p in repo.parts)
                    AppTableRow(
                      emphasized: p.balance <= p.reorderPoint,
                      cells: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.arabic ? p.nameAr : p.nameEn,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IdText(
                              p.id,
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
                            '${p.balance} ${p.unit}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${p.reorderPoint}',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ),
                        IdText(
                          p.location,
                          style: const TextStyle(fontSize: 9.5),
                        ),
                        StatusPill(
                          label: p.balance <= p.reorderPoint
                              ? s.tr('Low · reorder', 'منخفض · إعادة طلب')
                              : s.tr('Sufficient', 'كافٍ'),
                          color: p.balance <= p.reorderPoint
                              ? AppColors.warning
                              : AppColors.success,
                          compact: true,
                        ),
                        if (p.balance <= p.reorderPoint)
                          ops.restockRequested(p.id)
                              ? Text(
                                  s.tr('Queued', 'في الطابور'),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.success,
                                  ),
                                )
                              : TextButton(
                                  onPressed: canInventory
                                      ? () {
                                          ref
                                              .read(opsProvider.notifier)
                                              .requestRestock(p, user);
                                          _toast(
                                            s.tr(
                                              'Restock request for ${p.id} queued.',
                                              'تم إدراج طلب إعادة تخزين ${p.id}.',
                                            ),
                                          );
                                        }
                                      : () => _toast(
                                          s.tr(
                                            'Your demo role cannot manage inventory.',
                                            'دورك التجريبي لا يملك صلاحية إدارة المخزون.',
                                          ),
                                        ),
                                  child: Text(
                                    canInventory
                                        ? s.tr('Request', 'طلب')
                                        : s.tr('Read-only', 'للقراءة'),
                                    style: const TextStyle(fontSize: 9.5),
                                  ),
                                )
                        else
                          const Text(
                            '—',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                ],
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

class _AssetDetail extends ConsumerWidget {
  final AssetRecord asset;
  final AppStrings s;
  final OpsState ops;
  final DemoUser? user;
  final bool canAssign;
  const _AssetDetail({
    required this.asset,
    required this.s,
    required this.ops,
    required this.user,
    required this.canAssign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    WorkOrder? order;
    if (asset.activeOrderId != null) {
      for (final o in Fixtures.workOrders) {
        if (o.id == asset.activeOrderId) order = o;
      }
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: s.arabic ? asset.nameAr : asset.nameEn,
            subtitle:
                '${asset.id} · ${s.arabic ? asset.typeAr : asset.typeEn} · ${asset.zoneId}',
            trailing: StateBadge(state: asset.state, s: s),
          ),
          const SizedBox(height: AppSpace.md),
          SourceBadge(meta: asset.source, s: s, showStream: true),
          const SizedBox(height: AppSpace.md),
          LayoutBuilder(
            builder: (context, c) {
              final readings = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.tr('Latest readings', 'أحدث القراءات'),
                    style: t.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  if (asset.readings.isEmpty)
                    Text(
                      s.tr('No readings attached.', 'لا توجد قراءات مرتبطة.'),
                      style: t.bodySmall,
                    ),
                  for (final r in asset.readings)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(AppSpace.sm),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.arabic ? r.labelAr : r.labelEn,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${r.source.sourceId} · ${Fixtures.clock(r.asOf)} · ${r.source.mode.label(s)}',
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '${r.value} ${s.arabic ? r.unitAr : r.unitEn}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        s.tr('Health score', 'مؤشر الصحة'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                      const Spacer(),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${asset.healthScore}/100',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ScoreBar(value: asset.healthScore.toDouble()),
                ],
              );

              final orderPanel = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.tr('Active work order', 'أمر العمل النشط'),
                    style: t.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  if (order == null)
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        s.tr(
                          'No open work order for this asset.',
                          'لا يوجد أمر عمل مفتوح لهذا الأصل.',
                        ),
                        style: t.bodySmall,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: order.severity.color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(
                          color: order.severity.color.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IdText(
                                order.id,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.action,
                                ),
                              ),
                              const Spacer(),
                              SeverityBadge(severity: order.severity, s: s),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.arabic ? order.titleAr : order.titleEn,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CaseStatusBadge(
                                status: ops.workOrderStatus(order),
                                s: s,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${s.tr('Assignee', 'المسؤول')}: ${ops.workOrderAssignee(order)}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.tr('version', 'الإصدار')} ${order.version} · ${Fixtures.clock(order.createdAt)}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (canAssign)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      ref
                                          .read(opsProvider.notifier)
                                          .assignWorkOrder(
                                            order!,
                                            user?.nameEn ?? 'Demo operator',
                                            user?.nameAr ?? 'مشغّل تجريبي',
                                            user,
                                          );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            s.tr(
                                              'Assigned to you in the demo. Reassignment is audit-logged.',
                                              'أُسند إليك في العرض التجريبي. تُسجل إعادة الإسناد في التدقيق.',
                                            ),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      s.tr('Assign to me', 'إسناد إليّ'),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            s.tr(
                                              'Verification requires a fresh reading from ${asset.sensorIds.join(', ')}.',
                                              'يتطلب التحقق قراءة جديدة من ${asset.sensorIds.join(', ')}.',
                                            ),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      s.tr('Verify repair', 'تحقق من الإصلاح'),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            CardNote(
                              s.tr(
                                'Read-only for this role. Switch to Maintenance/Inventory to act.',
                                'للقراءة فقط لهذا الدور. بدّل إلى الصيانة/المخزون لاتخاذ إجراء.',
                              ),
                              icon: Icons.lock_outline,
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    s.tr('Asset event history', 'سجل أحداث الأصل'),
                    style: t.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  EventTimeline(
                    events: asset.history,
                    s: s,
                    maxItems: 4,
                    dense: true,
                  ),
                ],
              );

              if (c.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    readings,
                    const SizedBox(height: AppSpace.lg),
                    orderPanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: readings),
                  const SizedBox(width: AppSpace.xl),
                  Expanded(child: orderPanel),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final sensor in asset.sensorIds)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sensors,
                        size: 11,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      IdText(sensor, style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_2,
                      size: 11,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    IdText(asset.serial, style: const TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              if (asset.replacesId != null)
                StatusPill(
                  label: '${s.tr('replaces', 'يستبدل')} ${asset.replacesId}',
                  color: AppColors.muted,
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  final CaseStatus status;
  final List<WorkOrder> orders;
  final OpsState ops;
  final AppStrings s;
  final bool canAssign;
  final void Function(WorkOrder, CaseStatus) onMove;
  final ValueChanged<WorkOrder> onAssign;

  const _BoardColumn({
    required this.status,
    required this.orders,
    required this.ops,
    required this.s,
    required this.canAssign,
    required this.onMove,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.nested),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  status.label(s),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${orders.length}',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
              alignment: Alignment.center,
              child: Text(
                s.tr('No orders', 'لا أوامر'),
                style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
              ),
            ),
          for (final o in orders)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IdText(
                        o.id,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.action,
                        ),
                      ),
                      const Spacer(),
                      SeverityBadge(severity: o.severity, s: s),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.arabic ? o.titleAr : o.titleEn,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  IdText(
                    o.assetId,
                    style: const TextStyle(fontSize: 8, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ops.workOrderAssignee(o),
                    style: const TextStyle(fontSize: 9, color: AppColors.muted),
                  ),
                  if (canAssign) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: PopupMenuButton<CaseStatus>(
                            tooltip: s.tr('Move order', 'نقل الأمر'),
                            onSelected: (target) => onMove(o, target),
                            itemBuilder: (context) => [
                              for (final st in CaseStatus.values)
                                PopupMenuItem(
                                  value: st,
                                  child: Text(
                                    st.label(s),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.soft,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.swap_horiz,
                                    size: 11,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    s.tr('Move', 'نقل'),
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        InkWell(
                          onTap: () => onAssign(o),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.soft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.person_add_alt,
                              size: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
