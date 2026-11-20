import 'package:flutter/material.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'badges.dart';

/// Vertical event timeline with time, provenance and outcome for each event.
class EventTimeline extends StatelessWidget {
  final List<EventRecord> events;
  final AppStrings s;
  final int maxItems;
  final bool dense;
  final ValueChanged<EventRecord>? onTap;
  const EventTimeline({
    super.key,
    required this.events,
    required this.s,
    this.maxItems = 8,
    this.dense = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 22, color: AppColors.muted),
            const SizedBox(height: 6),
            Text(
              s.tr(
                'No events recorded for this entity yet.',
                'لا توجد أحداث مسجلة لهذا العنصر بعد.',
              ),
              textAlign: TextAlign.center,
              style: AppTypography.metadata.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }
    final list = events.take(maxItems).toList();
    return Column(
      children: [
        for (var i = 0; i < list.length; i++)
          _EventRow(
            event: list[i],
            s: s,
            last: i == list.length - 1,
            dense: dense,
            onTap: onTap,
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  final EventRecord event;
  final AppStrings s;
  final bool last;
  final bool dense;
  final ValueChanged<EventRecord>? onTap;

  const _EventRow({
    required this.event,
    required this.s,
    required this.last,
    required this.dense,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.severity.color;
    final content = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Padding(
              padding: EdgeInsets.only(top: dense ? 2 : 3),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  _time(event.observedAt),
                  style: AppTypography.metadata.copyWith(
                    fontFamily: 'Inter',
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(top: dense ? 3 : 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : (dense ? 10 : 14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.arabic ? event.summaryAr : event.summaryEn,
                    style: AppTypography.tableText.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
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
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        event.type,
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textTertiary,
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
                      if (event.actor != null)
                        StatusPill(
                          label: event.actor!,
                          color: AppColors.muted,
                          compact: true,
                        ),
                    ],
                  ),
                  if (!dense && event.outcomeEn != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        s.arabic ? (event.outcomeAr ?? '') : event.outcomeEn!,
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.primaryStrong,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return content;
  }

  String _time(DateTime utc) {
    final local = utc.add(const Duration(hours: 2));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }
}

/// Compact horizontal activity item used inside dense dashboard panels.
class ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String meta;
  final String? trailing;
  final VoidCallback? onTap;
  const ActivityItem({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.meta,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.tableText.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                trailing!,
                style: AppTypography.label.copyWith(
                  fontFamily: 'Inter',
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: content,
    );
  }
}
