import 'package:flutter/material.dart';
import '../domain/enums.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';

class LayerSelector extends StatelessWidget {
  final Set<TwinLayer> active;
  final ValueChanged<TwinLayer> onToggle;
  final AppStrings s;
  final bool dense;
  const LayerSelector({
    super.key,
    required this.active,
    required this.onToggle,
    required this.s,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final layer in TwinLayer.values)
          FilterChip(
            selected: active.contains(layer),
            onSelected: (_) => onToggle(layer),
            showCheckmark: false,
            avatar: Icon(
              layer.icon,
              size: 13,
              color: active.contains(layer) ? Colors.white : AppColors.muted,
            ),
            label: Text(layer.label(s)),
            labelStyle: TextStyle(
              fontSize: dense ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
              color: active.contains(layer) ? Colors.white : AppColors.text,
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.action,
            side: BorderSide(
              color: active.contains(layer)
                  ? AppColors.action
                  : AppColors.border,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}
