import 'package:flutter/material.dart';

class ProbabilityBars extends StatelessWidget {
  const ProbabilityBars({super.key, required this.names, required this.probabilities, this.best});

  final List<String> names;
  final List<double> probabilities;
  final int? best;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < names.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    names[i],
                    style: TextStyle(fontWeight: i == best ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(value: probabilities[i], minHeight: 14),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${(probabilities[i] * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
