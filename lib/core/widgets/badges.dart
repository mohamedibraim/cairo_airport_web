import 'package:flutter/material.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';

/// A 24px semantic status pill. The incoming [color] is mapped to the approved
/// soft palette so status is expressed by text + colour, never by colour alone.
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
    final tone = AppTones.from(color);
    return Container(
      height: 24,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.space2 : 9,
      ),
      decoration: BoxDecoration(
        color: background ?? tone.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: tone.text),
            const SizedBox(width: AppSpace.metadataGap),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tone.text, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpace.metadataGap),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                color: tone.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataDot extends StatelessWidget {
  final String label;
  final AppSemanticTone tone;
  const _MetadataDot({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: tone.text, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.metadataGap),
        Text(
          label,
          style: AppTypography.metadata.copyWith(color: tone.text),
        ),
      ],
    );
  }
}

/// Compact provenance line: mode · freshness · as-of · optional stream.
/// Rendered as metadata text instead of stacked badges to avoid visual noise.
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
      spacing: AppSpace.space3,
      runSpacing: AppSpace.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetadataDot(label: mode, tone: AppTones.from(meta.mode.color)),
        _MetadataDot(label: fresh, tone: AppTones.from(meta.freshness.color)),
        LtrText(
          '$asOf $time',
          style: AppTypography.metadata.copyWith(color: AppColors.textTertiary),
        ),
        if (showStream)
          LtrText(
            meta.streamId,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textTertiary,
            ),
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

/// Forces LTR rendering and Inter tabular figures for IDs, flight numbers,
/// codes and times inside both Arabic and English layouts.
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
        style: (style ?? const TextStyle()).copyWith(
          fontFamily: 'Inter',
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
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
      style: (style ?? AppTypography.metadata).copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
