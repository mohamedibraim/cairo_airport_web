import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'badges.dart';

/// Standard surface. Elevation 1, 14px radius, 20px padding and no default
/// border. Provide [color] only for a real semantic surface, never decoration.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool flat;
  final bool selected;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.flat = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = color ??
        (selected ? AppColors.surfaceSelected : AppColors.surface);
    final content = AnimatedContainer(
      duration: AppMotion.effective(context, AppMotion.selection),
      curve: AppMotion.easeOut,
      padding: padding ?? const EdgeInsets.all(AppSpace.space5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: flat ? AppShadows.none : AppShadows.level1,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        hoverColor: selected ? AppColors.surfaceSelected : AppColors.surfaceHover,
        focusColor: AppColors.primarySoft,
        splashColor: AppColors.primarySoft,
        child: content,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpace.space2),
                Text(
                  subtitle!,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpace.space4),
          trailing!,
        ],
      ],
    );
  }
}

class KpiTileCard extends StatelessWidget {
  final KpiTile kpi;
  final AppStrings s;
  final VoidCallback? onTap;
  const KpiTileCard({
    super.key,
    required this.kpi,
    required this.s,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = s.arabic ? kpi.labelAr : kpi.labelEn;
    final unit = s.arabic ? kpi.unitAr : kpi.unitEn;
    final ctx = s.arabic ? (kpi.contextAr ?? '') : (kpi.contextEn ?? '');

    return AppCard(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.tableText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.space4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LtrText(
                  kpi.value,
                  style: AppTypography.kpiValue.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: AppSpace.metadataGap),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (ctx.isNotEmpty) ...[
              const SizedBox(height: AppSpace.space2),
              Text(
                ctx,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.metadata.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.space3),
            SourceBadge(meta: kpi.source, s: s),
          ],
        ),
      ),
    );
  }
}

/// Neutral, non-animated placeholder that preserves the final content height.
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppRadius.small,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neutralSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ViewStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const ViewStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpace.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppColors.primaryStrong),
              const SizedBox(height: AppSpace.space4),
              Text(
                title,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.space2),
              Text(
                message,
                style: AppTypography.bodyPrimary.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpace.space6),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingBlock extends StatelessWidget {
  final String? message;
  const LoadingBlock({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message ?? 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSkeleton(width: 160, height: 14),
          const SizedBox(height: AppSpace.space3),
          const AppSkeleton(height: 12),
          const SizedBox(height: AppSpace.space2),
          const AppSkeleton(width: 220, height: 12),
          if (message != null) ...[
            const SizedBox(height: AppSpace.space4),
            Text(
              message!,
              style: AppTypography.metadata.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const MetricRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.metadata.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.space3),
          Flexible(
            child: LtrText(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleBarChart extends StatelessWidget {
  final List<(String, double)> data;
  final Color color;
  final double height;
  const SimpleBarChart({
    super.key,
    required this.data,
    this.color = AppColors.primary,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    final max = data.map((e) => e.$2).fold<double>(0, (a, b) => b > a ? b : a);
    final safeMax = max <= 0 ? 1.0 : max;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.space1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: (d.$2 / safeMax).clamp(0.05, 1.0),
                          widthFactor: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.metadataGap),
                    LtrText(
                      d.$1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textTertiary,
                      ),
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
