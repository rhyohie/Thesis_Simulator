import 'package:flutter/material.dart';

import '../api/models.dart';

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

/// Explains the F1 column in plain language.
Future<void> showF1Help(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('What is the F1 column?'),
      content: const SingleChildScrollView(
        child: Text(
          'This column is not about your photo. It shows how well the model did on that class '
          'across a fixed set of recorded images (validation or test images, as labelled).\n\n'
          'F1 is one score from 0 to 1 that combines two questions:\n'
          '• Precision: when the model says "Pod Borer", how often is it right?\n'
          '• Recall: of the real Pod Borer images, how many did the model find?\n\n'
          'F1 is high only when both are high. That matters here because the classes are uneven '
          '(most images are Healthy): a model that answers "Healthy" for everything gets about 76% '
          'accuracy but an F1 of 0 for the other two classes. The small line under each F1 shows '
          'precision (P) and recall (R).',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
      ],
    ),
  );
}

/// Class-level results: this photo's probability next to the recorded per-class F1 score.
class ClassTable extends StatelessWidget {
  const ClassTable({super.key, required this.result, required this.checkpoint});

  final AnalysisResult result;
  final CheckpointInfo? checkpoint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final head = text.labelLarge;
    final ev = checkpoint?.evaluation;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.0),
        1: FlexColumnWidth(1.3),
        2: FlexColumnWidth(2.2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            Padding(padding: const EdgeInsets.all(6), child: Text('Class', style: head)),
            Padding(padding: const EdgeInsets.all(6), child: Text('This photo', style: head)),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      ev == null ? 'F1 (recorded)' : 'F1 on ${ev.on} images',
                      style: head,
                    ),
                  ),
                  InkWell(
                    onTap: () => showF1Help(context),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.help_outline, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        for (var i = 0; i < result.classNames.length; i++)
          TableRow(
            decoration: i == result.predIndex
                ? BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer)
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  result.classNames[i],
                  style: TextStyle(
                    fontWeight: i == result.predIndex ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(_pct(result.probabilities[i])),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: ev == null
                    ? const Text('—')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev.f1[i].toStringAsFixed(3)),
                          Text(
                            'P ${ev.precision[i].toStringAsFixed(2)} · R ${ev.recall[i].toStringAsFixed(2)} · n=${ev.support[i]}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
              ),
            ],
          ),
      ],
    );
  }
}
