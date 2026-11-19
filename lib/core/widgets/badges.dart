import 'package:flutter/material.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool compact;
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? color.withValues(alpha: 0.12);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 13, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: compact ? 6 : 7,
              height: compact ? 6 : 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SourceBadge extends StatelessWidget {
  final SourceMeta meta;
  final AppStrings s;
  final bool showStream;
  const SourceBadge({
    super.key,
    required this.meta,
    required this.s,
    this.showStream = false,
  });

  String _fmt(DateTime utc) {
    final l = utc.add(const Duration(hours: 2));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final mode = meta.mode.label(s);
    final fresh = meta.freshness.label(s);
    final time = _fmt(meta.observedAt);
    final asOf = s.tr('as of', 'اعتبارًا من');
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusPill(label: mode, color: meta.mode.color, compact: true),
        StatusPill(label: fresh, color: meta.freshness.color, compact: true),
        LtrText(
          '$asOf $time',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (showStream)
          LtrText(
            meta.streamId,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
      ],
    );
  }
}

class SeverityBadge extends StatelessWidget {
  final Severity severity;
  final AppStrings s;
  const SeverityBadge({super.key, required this.severity, required this.s});
  @override
  Widget build(BuildContext context) => StatusPill(
    label: severity.label(s),
    color: severity.color,
    compact: true,
  );
}

class StateBadge extends StatelessWidget {
  final EntityState state;
  final AppStrings s;
  const StateBadge({super.key, required this.state, required this.s});
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: state.label(s), color: state.color, compact: true);
}

class CaseStatusBadge extends StatelessWidget {
  final CaseStatus status;
  final AppStrings s;
  const CaseStatusBadge({super.key, required this.status, required this.s});
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: status.label(s), color: status.color, compact: true);
}

/// Forces LTR rendering for IDs, flight numbers, codes and times, as required
/// by the blueprint for Arabic contexts.
class LtrText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  const LtrText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign ?? TextAlign.start,
      ),
    );
  }
}

class IdText extends StatelessWidget {
  final String id;
  final TextStyle? style;
  const IdText(this.id, {super.key, this.style});
  @override
  Widget build(BuildContext context) {
    return LtrText(
      id,
      style: (style ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
