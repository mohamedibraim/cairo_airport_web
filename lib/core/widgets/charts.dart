import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../theme/tokens.dart';

class ChartSeries {
  final String label;
  final List<SeriesPoint> points;
  final Color color;
  final bool dashed;
  final bool band;
  const ChartSeries({
    required this.label,
    required this.points,
    this.color = AppColors.primaryStrong,
    this.dashed = false,
    this.band = false,
  });
}

/// Flat line chart for observed / forecast / simulated series.
/// Observed series are solid, forecasts are dashed and simulated uncertainty
/// is rendered as a soft band, matching the blueprint's chart conventions.
class SeriesChart extends StatelessWidget {
  final List<ChartSeries> series;
  final double height;
  final String yUnit;
  final bool showLegend;
  final String? xAxisNote;
  const SeriesChart({
    super.key,
    required this.series,
    this.height = 200,
    this.yUnit = '',
    this.showLegend = true,
    this.xAxisNote,
  });

  @override
  Widget build(BuildContext context) {
    final visible = series.where((s) => s.points.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLegend && visible.isNotEmpty) ...[
          Wrap(
            spacing: AppSpace.md,
            runSpacing: 6,
            children: [
              for (final s in visible)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendMark(color: s.color, dashed: s.dashed, band: s.band),
                    const SizedBox(width: 5),
                    Text(
                      s.label,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        SizedBox(
          height: height,
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    'No series in this range',
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                )
              : CustomPaint(
                  painter: _SeriesPainter(series: visible, yUnit: yUnit),
                  size: Size.infinite,
                ),
        ),
        if (xAxisNote != null) ...[
          const SizedBox(height: 4),
          Text(
            xAxisNote!,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

class _LegendMark extends StatelessWidget {
  final Color color;
  final bool dashed;
  final bool band;
  const _LegendMark({
    required this.color,
    required this.dashed,
    required this.band,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 8,
      child: CustomPaint(painter: _MarkPainter(color, dashed, band)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  final bool band;
  _MarkPainter(this.color, this.dashed, this.band);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (band) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = color.withValues(alpha: 0.18),
      );
    }
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      return;
    }
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, y), Offset((x + 3).clamp(0, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeriesPainter extends CustomPainter {
  final List<ChartSeries> series;
  final String yUnit;
  _SeriesPainter({required this.series, required this.yUnit});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 46.0;
    const right = AppSpace.space3;
    const top = AppSpace.space3;
    const bottom = 28.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      (size.width - left - right).clamp(10.0, size.width),
      (size.height - top - bottom).clamp(10.0, size.height),
    );

    var minX = double.infinity, maxX = -double.infinity;
    var maxY = 0.0;
    for (final s in series) {
      for (final p in s.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }
    if (!minX.isFinite || !maxX.isFinite) return;
    if (maxX == minX) maxX = minX + 1;
    maxY = maxY <= 0 ? 10 : maxY * 1.15;

    // horizontal grid + y labels
    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final value = maxY * i / 4;
      _text(
        canvas,
        _compact(value),
        Offset(plot.left - 6, y),
        align: TextAlign.right,
        color: AppColors.textTertiary,
        size: 12,
        anchorRight: true,
        centerVertically: true,
      );
    }

    // x labels
    final xs = <double>{};
    for (final s in series) {
      for (final p in s.points) {
        xs.add(p.x);
      }
    }
    final sortedX = xs.toList()..sort();
    final step = (sortedX.length / 6).ceil().clamp(1, 12);
    for (var i = 0; i < sortedX.length; i += step) {
      final x = _x(sortedX[i], minX, maxX, plot);
      _text(
        canvas,
        _hourLabel(sortedX[i]),
        Offset(x, plot.bottom + 8),
        align: TextAlign.center,
        color: AppColors.textTertiary,
        size: 12,
        centerHorizontally: true,
      );
    }

    for (final s in series) {
      if (s.points.isEmpty) continue;
      final path = Path();
      for (var i = 0; i < s.points.length; i++) {
        final p = s.points[i];
        final dx = _x(p.x, minX, maxX, plot);
        final dy = plot.bottom - (p.y / maxY) * plot.height;
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      if (s.band) {
        final fill = Path.from(path);
        final first = s.points.first;
        final last = s.points.last;
        fill.lineTo(_x(last.x, minX, maxX, plot), plot.bottom);
        fill.lineTo(_x(first.x, minX, maxX, plot), plot.bottom);
        fill.close();
        canvas.drawPath(fill, Paint()..color = s.color.withValues(alpha: 0.12));
      }
      final line = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      if (s.dashed) {
        _drawDashed(canvas, path, line);
      } else {
        canvas.drawPath(path, line);
      }
      final lastPoint = s.points.last;
      final lastX = _x(lastPoint.x, minX, maxX, plot);
      final lastY = plot.bottom - (lastPoint.y / maxY) * plot.height;
      canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = s.color);
      canvas.drawCircle(
        Offset(lastX, lastY),
        5.5,
        Paint()
          ..color = s.color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (yUnit.isNotEmpty) {
      _text(
        canvas,
        yUnit,
        const Offset(0, 0),
        color: AppColors.textTertiary,
        size: 12,
      );
    }
  }

  double _x(double value, double min, double max, Rect plot) =>
      plot.left + ((value - min) / (max - min)) * plot.width;

  String _hourLabel(double value) {
    final hour = value.floor();
    final minutes = ((value - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _compact(double value) {
    if (value >= 1000) {
      final k = value / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return value.toStringAsFixed(0);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 6.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    Color color = AppColors.text,
    double size = 12,
    TextAlign align = TextAlign.left,
    bool anchorRight = false,
    bool centerHorizontally = false,
    bool centerVertically = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    var offset = at;
    if (anchorRight) offset = Offset(at.dx - tp.width, at.dy);
    if (centerHorizontally) offset = Offset(at.dx - tp.width / 2, at.dy);
    if (centerVertically) offset = Offset(offset.dx, at.dy - tp.height / 2);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SeriesPainter old) => true;
}

class ScoreBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const ScoreBar({super.key, required this.value, this.color, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final c =
        color ??
        (value >= 80
            ? AppColors.success
            : (value >= 60 ? AppColors.warning : AppColors.danger));
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Stack(
        children: [
          Container(height: height, color: AppColors.neutralSoft),
          FractionallySizedBox(
            widthFactor: (value / 100).clamp(0.02, 1.0),
            child: Container(height: height, color: c),
          ),
        ],
      ),
    );
  }
}

/// Simple horizontal bar chart with labels, used where a line chart would
/// imply continuity that the data does not have.
class HBarChart extends StatelessWidget {
  final List<(String, double, String)> data;
  final Color color;
  const HBarChart({
    super.key,
    required this.data,
    this.color = AppColors.primaryStrong,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        '—',
        style: AppTypography.metadata.copyWith(color: AppColors.textTertiary),
      );
    }
    final max = data.map((d) => d.$2).fold<double>(0, (a, b) => b > a ? b : a);
    final safe = max <= 0 ? 1.0 : max;
    return Column(
      children: [
        for (final d in data)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    d.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Stack(
                      children: [
                        Container(height: 8, color: AppColors.neutralSoft),
                        FractionallySizedBox(
                          widthFactor: (d.$2 / safe).clamp(0.02, 1.0),
                          child: Container(
                            height: 8,
                            color: color.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 52,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      d.$3,
                      textAlign: TextAlign.end,
                      style: AppTypography.label.copyWith(
                        fontFamily: 'Inter',
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
