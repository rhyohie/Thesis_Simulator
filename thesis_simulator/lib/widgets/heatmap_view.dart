import 'package:flutter/material.dart';

import '../api/models.dart';
import 'heat_color.dart';

/// Draws a [MapData] as colored cells.
/// Default: stretched from this map's own lowest value (dark blue) to its own highest (yellow).
/// With [shared] = true the block-wide scale is used instead, so different maps can be compared.
class HeatmapView extends StatelessWidget {
  const HeatmapView({
    super.key,
    required this.map,
    this.size = 96,
    this.alpha = 255,
    this.shared = false,
  });

  final MapData map;
  final double size;
  final int alpha;
  final bool shared;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HeatmapPainter(map, alpha, shared && map.vs != null)),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter(this.map, this.alpha, this.shared);

  final MapData map;
  final int alpha;
  final bool shared;

  @override
  void paint(Canvas canvas, Size size) {
    final values = shared ? map.vs! : map.v;
    var lo = 0.0;
    var hi = 255.0;
    if (!shared) {
      lo = double.infinity;
      hi = double.negativeInfinity;
      for (final v in values) {
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
    }
    final range = hi - lo;
    final cellW = size.width / map.w;
    final cellH = size.height / map.h;
    final paint = Paint();
    for (var y = 0; y < map.h; y++) {
      for (var x = 0; x < map.w; x++) {
        final t = range > 1e-12 ? (values[y * map.w + x] - lo) / range : 0.0;
        paint.color = heatColor(t, alpha);
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.6, cellH + 0.6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) =>
      oldDelegate.map != map || oldDelegate.alpha != alpha || oldDelegate.shared != shared;
}

/// A colour bar that explains the heat-map colours.
class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key, required this.lowLabel, required this.highLabel});

  final String lowLabel;
  final String highLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodySmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lowLabel, style: text),
        const SizedBox(width: 8),
        Container(
          width: 140,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(colors: [heatColor(0), heatColor(0.5), heatColor(1)]),
          ),
        ),
        const SizedBox(width: 8),
        Text(highLabel, style: text),
      ],
    );
  }
}
