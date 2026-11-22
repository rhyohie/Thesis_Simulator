import 'package:flutter/material.dart';

import '../api/models.dart';
import '../state/app_controller.dart';

String _lossText(double v) => v >= 1e4 ? v.toStringAsExponential(2) : v.toStringAsFixed(4);

/// The "?" panel: why BN+GAP was chosen over BN-only and GAP-only.
Future<void> showAblationDialog(BuildContext context, AppController controller) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
        child: _AblationBody(controller: controller),
      ),
    ),
  );
}

class _AblationBody extends StatelessWidget {
  const _AblationBody({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final info = controller.info?.ablation;
    final text = Theme.of(context).textTheme;
    if (info == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Connect to the Python service to load the comparison.'),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(
            children: [
              Expanded(child: Text(info.title, style: text.titleLarge)),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Text(info.source, style: text.bodySmall),
              const SizedBox(height: 12),
              Image.network(
                controller.ablationFigureUri.toString(),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                errorBuilder: (context, error, stack) => const Text(
                  'The learning-history figure could not be loaded from the service '
                  '(server/assets/ablation_histories.png).',
                ),
              ),
              const SizedBox(height: 16),
              Text('Recorded results', style: text.titleMedium),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Model')),
                    const DataColumn(label: Text('Checkpoint')),
                    const DataColumn(label: Text('Epoch'), numeric: true),
                    const DataColumn(label: Text('Accuracy'), numeric: true),
                    const DataColumn(label: Text('Macro F1'), numeric: true),
                    DataColumn(label: Text('Pod Borer found (of ${info.podBorerTotal})'), numeric: true),
                    const DataColumn(label: Text('Loss'), numeric: true),
                  ],
                  rows: [
                    for (final r in info.rows)
                      DataRow(
                        cells: [
                          for (final cell in [
                            r.model,
                            r.checkpoint,
                            '${r.epoch}',
                            '${(r.accuracy * 100).toStringAsFixed(2)}%',
                            r.macroF1.toStringAsFixed(4),
                            '${r.podBorerFound}',
                            _lossText(r.loss),
                          ])
                            DataCell(
                              Text(
                                cell,
                                style: TextStyle(
                                  fontWeight: r.model == 'BN+GAP' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('What the comparison shows', style: text.titleMedium),
              const SizedBox(height: 6),
              for (final t in info.takeaways) _Bullet(t),
              const SizedBox(height: 12),
              Text('Read with care', style: text.titleMedium),
              const SizedBox(height: 6),
              for (final c in info.caveats) _Bullet(c),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
