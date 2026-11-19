import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'badges.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool flat;
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.major),
        border: Border.all(color: AppColors.border),
        boxShadow: flat ? null : const [AppShadow.card],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.major),
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
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: t.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
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
    final t = Theme.of(context).textTheme;
    final label = s.arabic ? kpi.labelAr : kpi.labelEn;
    final unit = s.arabic ? kpi.unitAr : kpi.unitEn;
    final ctx = s.arabic ? (kpi.contextAr ?? '') : (kpi.contextEn ?? '');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: t.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_outward,
                size: 14,
                color: AppColors.muted.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LtrText(
                kpi.value,
                style: t.headlineSmall?.copyWith(
                  color: AppColors.navy,
                  height: 1.0,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          if (ctx.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ctx,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          SourceBadge(meta: kpi.source, s: s),
        ],
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
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: AppColors.primary),
              const SizedBox(height: AppSpace.md),
              Text(title, style: t.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.xs),
              Text(message, style: t.bodySmall, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpace.lg),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.action,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: LtrText(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium,
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
                padding: const EdgeInsets.symmetric(horizontal: 3),
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
                              color: color.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    LtrText(
                      d.$1,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.muted,
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
