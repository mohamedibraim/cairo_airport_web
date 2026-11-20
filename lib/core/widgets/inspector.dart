import 'package:flutter/material.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'badges.dart';
import 'details_panel.dart';
import 'layout.dart';
import 'timeline.dart';

/// Selected-entity inspector for the Digital Twin. Every value keeps its unit,
/// observation time, source mode and freshness; the panel never implies live
/// Cairo Airport telemetry.
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
      return DetailsPanel(
        title: s.tr('Select a zone', 'اختر منطقة'),
        subtitle: Text(
          s.tr('Twin entity inspector', 'مفتش عناصر التوأم'),
          style: AppTypography.metadata.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        children: [
          Column(
            children: [
              const SizedBox(height: AppSpace.space4),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app_outlined,
                  color: AppColors.primaryStrong,
                  size: 22,
                ),
              ),
              const SizedBox(height: AppSpace.space4),
              Text(
                s.tr(
                  'Tap any zone or asset on the schematic to inspect its state, metrics and event history.',
                  'اضغط على أي منطقة أو أصل في المخطط لعرض حالته ومؤشراته وسجل أحداثه.',
                ),
                textAlign: TextAlign.center,
                style: AppTypography.bodyPrimary.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpace.space4),
            ],
          ),
        ],
      );
    }

    final e = entity!;
    final name = s.arabic ? e.nameAr : e.nameEn;
    final type = s.arabic ? e.typeAr : e.typeEn;
    final status = s.arabic ? e.statusAr : e.statusEn;
    final zoneRelated = related.where((r) => r.id != e.id).toList();
    final tone = AppTones.from(e.state.color);

    return DetailsPanel(
      title: name,
      subtitle: Row(
        children: [
          IdText(
            e.id,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpace.space2),
          Flexible(
            child: Text(
              '· $type',
              overflow: TextOverflow.ellipsis,
              style: AppTypography.metadata.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      status: Container(
        padding: const EdgeInsets.all(AppSpace.space3),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            StateBadge(state: e.state, s: s),
            const SizedBox(width: AppSpace.space3),
            Expanded(
              child: Text(
                status,
                style: AppTypography.bodyEmphasis.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      closeTooltip: s.tr('Close', 'إغلاق'),
      onClose: onClose,
      children: [
        SourceBadge(meta: e.source, s: s),
        DetailsSection(
          title: s.tr('Entity details', 'تفاصيل العنصر'),
          children: [
            DetailRow(
              label: s.tr('Layer', 'الطبقة'),
              value: Row(
                children: [
                  Icon(e.layer.icon, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpace.space1),
                  Text(
                    e.layer.label(s),
                    style: AppTypography.tableText,
                  ),
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
                  color: AppColors.primaryStrong,
                ),
              ),
          ],
        ),
        DetailsSection(
          title: s.tr('Operational metrics', 'المؤشرات التشغيلية'),
          children: [
            if (e.metrics.isEmpty)
              Text(
                s.tr(
                  'No metrics attached to this entity.',
                  'لا توجد مؤشرات مرتبطة بهذا العنصر.',
                ),
                style: AppTypography.bodyPrimary.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            for (final m in e.metrics)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.space2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.arabic ? m.labelAr : m.labelEn,
                            style: AppTypography.tableText.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${m.source.mode.label(s)} · ${_time(m.asOf)}',
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.space3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        LtrText(
                          m.value,
                          style: AppTypography.cardTitle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if ((s.arabic ? m.unitAr : m.unitEn).isNotEmpty) ...[
                          const SizedBox(width: AppSpace.space1),
                          Text(
                            s.arabic ? m.unitAr : m.unitEn,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (e.latestEventEn != null)
          Container(
            padding: const EdgeInsets.all(AppSpace.space3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.bolt_outlined,
                  size: 15,
                  color: AppColors.primaryStrong,
                ),
                const SizedBox(width: AppSpace.space2),
                Expanded(
                  child: Text(
                    s.arabic ? (e.latestEventAr ?? '') : e.latestEventEn!,
                    style: AppTypography.tableText.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (zoneRelated.isNotEmpty)
          DetailsSection(
            title: s.tr('Related entities', 'العناصر المرتبطة'),
            children: [
              Wrap(
                spacing: AppSpace.space2,
                runSpacing: AppSpace.space2,
                children: [
                  for (final r in zoneRelated.take(6))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.space2,
                        vertical: AppSpace.space1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(r.layer.icon, size: 13, color: r.state.color),
                          const SizedBox(width: AppSpace.space1),
                          IdText(
                            r.id,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        DetailsSection(
          title: s.tr('Event history', 'سجل الأحداث'),
          children: [
            if (onOpenInTwin != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onOpenInTwin,
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: Text(s.tr('Open twin', 'فتح التوأم')),
                ),
              ),
            EventTimeline(events: e.history, s: s, maxItems: 5, dense: true),
          ],
        ),
        CardNote(
          s.tr(
            'Simulated fixture values for UI demonstration — not live Cairo Airport telemetry.',
            'قيم تجريبية محاكاة لعرض الواجهة — ليست بيانات حية من مطار القاهرة.',
          ),
        ),
      ],
    );
  }

  String _time(DateTime utc) {
    final local = utc.add(const Duration(hours: 2));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
