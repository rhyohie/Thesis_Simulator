import 'package:flutter/material.dart';

/// Thin vertical bars, one per value (used for the 512 averages).
class BarsView extends StatelessWidget {
  const BarsView({super.key, required this.values, this.highlight, this.height = 120});

  final List<double> values;
  final int? highlight;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarsPainter(values, highlight, scheme.primary, scheme.tertiary),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.values, this.highlight, this.color, this.highlightColor);

  final List<double> values;
  final int? highlight;
  final Color color;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    var maxValue = 0.0;
    for (final v in values) {
      if (v > maxValue) maxValue = v;
    }
    if (maxValue <= 0) maxValue = 1.0;
    final barW = size.width / values.length;
    final paint = Paint();
    for (var i = 0; i < values.length; i++) {
      final h = (values[i] / maxValue) * size.height;
      paint.color = i == highlight ? highlightColor : color;
      final w = i == highlight ? barW * 2.5 : barW * 0.8;
      canvas.drawRect(
        Rect.fromLTWH(i * barW, size.height - h, w < 1.2 ? 1.2 : w, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.highlight != highlight;
}
