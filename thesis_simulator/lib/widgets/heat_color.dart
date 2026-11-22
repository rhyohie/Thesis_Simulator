import 'package:flutter/material.dart';

/// Maps 0..1 to a dark-blue -> green -> yellow scale.
Color heatColor(double t, [int alpha = 255]) {
  final double c = t.clamp(0.0, 1.0).toDouble();
  const stops = <List<int>>[
    [20, 30, 80],
    [40, 160, 120],
    [250, 230, 60],
  ];
  final scaled = c * 2;
  final int i = scaled.floor() >= 2 ? 1 : scaled.floor();
  final double f = scaled - i;
  final a = stops[i];
  final b = stops[i + 1];
  int mix(int p, int q) => (p + (q - p) * f).round();
  return Color.fromARGB(alpha, mix(a[0], b[0]), mix(a[1], b[1]), mix(a[2], b[2]));
}
