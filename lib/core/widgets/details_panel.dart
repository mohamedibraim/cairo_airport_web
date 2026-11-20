import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Reusable right/left details surface for Phase 01 and the upcoming Live
/// Events redesign. It stays 340–420px wide and never assumes live data.
class DetailsPanel extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final Widget? status;
  final String? closeTooltip;
  final VoidCallback? onClose;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool showDividers;

  const DetailsPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.status,
    this.closeTooltip,
    this.onClose,
    this.children = const [],
    this.padding = const EdgeInsets.all(AppSpace.space6),
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 340, maxWidth: 420),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.panel),
            boxShadow: AppShadows.level2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpace.space2),
                          DefaultTextStyle(
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            child: subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClose != null) ...[
                    const SizedBox(width: AppSpace.space3),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: closeTooltip,
                    ),
                  ],
                ],
              ),
              if (status != null) ...[
                const SizedBox(height: AppSpace.space4),
                status!,
              ],
              for (var i = 0; i < children.length; i++) ...[
                const SizedBox(height: AppSpace.space5),
                if (showDividers && i != 0)
                  const Divider(
                    height: 1,
                    color: AppColors.divider,
                  ),
                if (showDividers && i != 0)
                  const SizedBox(height: AppSpace.space5),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const DetailsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.bodyEmphasis.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpace.space3),
        for (final child in children) child,
      ],
    );
  }
}
