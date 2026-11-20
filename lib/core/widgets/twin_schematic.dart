import 'package:flutter/material.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'badges.dart';

class TwinSchematic extends StatelessWidget {
  final List<TwinEntity> entities;
  final Set<TwinLayer> activeLayers;
  final String? selectedId;
  final ValueChanged<TwinEntity> onSelect;
  final AppStrings s;
  final bool compact;

  const TwinSchematic({
    super.key,
    required this.entities,
    required this.activeLayers,
    required this.selectedId,
    required this.onSelect,
    required this.s,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final zones = entities
        .where((e) => e.isZone && activeLayers.contains(e.layer))
        .toList();
    final nodes = entities
        .where((e) => !e.isZone && activeLayers.contains(e.layer))
        .toList();
    // incidents layer overlays: show fault/pending/warning entities as incident markers
    final incidentNodes = activeLayers.contains(TwinLayer.incidents)
        ? entities
              .where(
                (e) =>
                    !e.isZone &&
                    (e.state == EntityState.fault ||
                        e.state == EntityState.warning ||
                        e.state == EntityState.pending),
              )
              .toList()
        : const <TwinEntity>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (compact ? 260.0 : 360.0);
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(AppRadius.nested),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.nested),
            child: Stack(
              children: [
                CustomPaint(size: Size(w, h), painter: _GridPainter()),
                for (final z in zones) _entityBox(z, w, h, isZone: true),
                for (final n in nodes) _entityBox(n, w, h, isZone: false),
                for (final n in incidentNodes.where((e) => !nodes.contains(e)))
                  _entityBox(n, w, h, isZone: false, incidentOverlay: true),
                Positioned(left: 10, top: 10, child: _legend(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _entityBox(
    TwinEntity e,
    double w,
    double h, {
    required bool isZone,
    bool incidentOverlay = false,
  }) {
    final selected = e.id == selectedId;
    final left = e.x * w;
    final top = e.y * h;
    final bw = e.w * w;
    final bh = e.h * h;
    final color = e.state.color;
    final name = s.arabic ? e.nameAr : e.nameEn;

    if (isZone) {
      return Positioned(
        left: left,
        top: top,
        width: bw,
        height: bh,
        child: Semantics(
          button: true,
          label: '${e.id} $name ${e.state.label(s)}',
          child: Tooltip(
            message: '${e.id} · ${s.tr(e.statusEn, e.statusAr)}',
            child: InkWell(
              onTap: () => onSelect(e),
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.10)
                      : AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: selected ? color : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IdText(
                      e.id,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // node marker
    return Positioned(
      left: left,
      top: top,
      width: bw.clamp(34.0, 54.0),
      height: bh.clamp(34.0, 54.0),
      child: Semantics(
        button: true,
        label: '${e.id} $name',
        child: Tooltip(
          message: '${e.id} · ${s.tr(e.statusEn, e.statusAr)}',
          child: InkWell(
            onTap: () => onSelect(e),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: selected ? color : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: color, width: selected ? 2 : 1),
              ),
              child: Icon(
                e.layer == TwinLayer.baggage
                    ? Icons.luggage
                    : (e.layer == TwinLayer.equipment
                          ? Icons.memory
                          : Icons.warning_amber_rounded),
                size: 16,
                color: selected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final st in const [
            EntityState.operational,
            EntityState.warning,
            EntityState.fault,
            EntityState.maintenance,
            EntityState.pending,
          ])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: st.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    st.label(s),
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
