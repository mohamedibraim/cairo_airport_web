import 'package:flutter/material.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'badges.dart';
import 'layout.dart';
import 'primitives.dart';
import 'timeline.dart';

/// Selected-entity inspector for the Digital Twin. Every value shows its unit,
/// observation time, source mode and freshness; the panel never hides that the
/// data is simulated.
class EntityInspector extends StatelessWidget {
  final TwinEntity? entity;
  final List<TwinEntity> related;
  final AppStrings s;
  final VoidCallback? onClose;
  final VoidCallback? onOpenInTwin;

  const EntityInspector({
    super.key,
    required this.entity,
    required this.s,
    this.related = const [],
    this.onClose,
    this.onOpenInTwin,
  });

  @override
  Widget build(BuildContext context) {
    if (entity == null) {
      return AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpace.lg),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.tealSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app_outlined,
                color: AppColors.action,
                size: 22,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              s.tr('Select a zone', 'اختر منطقة'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              s.tr(
                'Tap any zone or asset on the schematic to inspect its state, metrics and event history.',
                'اضغط على أي منطقة أو أصل في المخطط لعرض حالته ومؤشراته وسجل أحداثه.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      );
    }

    final e = entity!;
    final t = Theme.of(context).textTheme;
    final name = s.arabic ? e.nameAr : e.nameEn;
    final type = s.arabic ? e.typeAr : e.typeEn;
    final status = s.arabic ? e.statusAr : e.statusEn;
    final zoneRelated = related.where((r) => r.id != e.id).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
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
                    Text(
                      s.tr('Entity inspector', 'مفتش العنصر'),
                      style: t.labelSmall?.copyWith(
                        color: AppColors.action,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(name, style: t.titleLarge),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        IdText(
                          e.id,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('· $type', style: t.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: s.tr('Close', 'إغلاق'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: e.state.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: e.state.color.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                StateBadge(state: e.state, s: s),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    status,
                    style: t.bodySmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          SourceBadge(meta: e.source, s: s),
          const SizedBox(height: AppSpace.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpace.sm),
          DetailRow(
            label: s.tr('Layer', 'الطبقة'),
            value: Row(
              children: [
                Icon(e.layer.icon, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(e.layer.label(s), style: t.labelMedium),
              ],
            ),
          ),
          DetailRow(
            label: s.tr('Zone type', 'نوع العنصر'),
            value: DetailValue(
              e.isZone
                  ? s.tr('Operational zone', 'منطقة تشغيلية')
                  : s.tr('Asset node', 'عقدة أصل'),
            ),
          ),
          DetailRow(
            label: s.tr('Stream', 'التدفق'),
            value: DetailValue(e.source.streamId, ltr: true),
          ),
          DetailRow(
            label: s.tr('Last update', 'آخر تحديث'),
            value: DetailValue(_time(e.source.observedAt), ltr: true),
          ),
          DetailRow(
            label: s.tr('Freshness', 'حداثة البيانات'),
            value: StatusPill(
              label: e.source.freshness.label(s),
              color: e.source.freshness.color,
              compact: true,
            ),
          ),
          if (e.source.correlationId != null)
            DetailRow(
              label: s.tr('Correlation', 'الارتباط'),
              value: DetailValue(
                e.source.correlationId!,
                ltr: true,
                color: AppColors.action,
              ),
            ),
          const SizedBox(height: AppSpace.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpace.sm),
          Text(
            s.tr('Operational metrics', 'المؤشرات التشغيلية'),
            style: t.titleSmall,
          ),
          const SizedBox(height: 2),
          if (e.metrics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                s.tr(
                  'No metrics attached to this entity.',
                  'لا توجد مؤشرات مرتبطة بهذا العنصر.',
                ),
                style: t.bodySmall,
              ),
            ),
          for (final m in e.metrics)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.arabic ? m.labelAr : m.labelEn,
                          style: t.bodySmall?.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${m.source.mode.label(s)} · ${_time(m.asOf)}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          m.value,
                          style: t.titleMedium?.copyWith(color: AppColors.navy),
                        ),
                        if ((s.arabic ? m.unitAr : m.unitEn).isNotEmpty) ...[
                          const SizedBox(width: 3),
                          Text(
                            s.arabic ? m.unitAr : m.unitEn,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (e.latestEventEn != null) ...[
            const SizedBox(height: AppSpace.sm),
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.bolt_outlined,
                    size: 14,
                    color: AppColors.action,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.arabic ? (e.latestEventAr ?? '') : e.latestEventEn!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.4,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (zoneRelated.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              s.tr('Related entities', 'العناصر المرتبطة'),
              style: t.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in zoneRelated.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(r.layer.icon, size: 11, color: r.state.color),
                        const SizedBox(width: 4),
                        IdText(r.id, style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.tr('Event history', 'سجل الأحداث'),
                  style: t.titleSmall,
                ),
              ),
              if (onOpenInTwin != null)
                TextButton.icon(
                  onPressed: onOpenInTwin,
                  icon: const Icon(Icons.open_in_new, size: 13),
                  label: Text(s.tr('Open twin', 'فتح التوأم')),
                ),
            ],
          ),
          EventTimeline(events: e.history, s: s, maxItems: 5, dense: true),
          const SizedBox(height: AppSpace.sm),
          CardNote(
            s.tr(
              'Simulated fixture values for UI demonstration — not live Cairo Airport telemetry.',
              'قيم تجريبية محاكاة لعرض الواجهة — ليست بيانات حية من مطار القاهرة.',
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime utc) {
    final local = utc.add(const Duration(hours: 2));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
