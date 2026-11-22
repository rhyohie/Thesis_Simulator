import 'package:flutter/material.dart';

import '../api/models.dart';
import '../state/app_controller.dart';
import '../widgets/ablation_dialog.dart';

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final info = controller.info;
        return Scaffold(
          appBar: AppBar(title: const Text('About the models')),
          body: info == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Connect to the Python service to load the model details.'),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: controller.connect, child: const Text('Retry')),
                    ],
                  ),
                )
              : _Content(info: info, controller: controller),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.info, required this.controller});

  final ModelInfo info;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final m in info.models) ...[
              _ModelSection(model: m, classNames: info.classNames),
              const SizedBox(height: 24),
            ],
            Text('Why BN+GAP?', style: text.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'The recorded comparison of the baseline, BN-only, GAP-only and BN+GAP, with the '
              'learning histories.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => showAblationDialog(context, controller),
                icon: const Icon(Icons.help_outline),
                label: const Text('Open the comparison'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Limits to keep in mind', style: text.titleMedium),
            const SizedBox(height: 8),
            for (final limit in info.limits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(limit)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelSection extends StatelessWidget {
  const _ModelSection({required this.model, required this.classNames});

  final ModelEntry model;
  final List<String> classNames;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cps = model.checkpoints;

    DataRow row(String label, String Function(CheckpointInfo) value) => DataRow(
          cells: [
            DataCell(Text(label)),
            for (final c in cps) DataCell(Text(value(c))),
          ],
        );

    String prf(EvalInfo e, int i) =>
        '${e.precision[i].toStringAsFixed(2)} / ${e.recall[i].toStringAsFixed(2)} / ${e.f1[i].toStringAsFixed(2)}';

    final extras = [
      for (final c in cps)
        if (c.alsoEvaluated != null) (c, c.alsoEvaluated!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(model.label, style: text.titleLarge),
        const SizedBox(height: 4),
        Text(model.description),
        const SizedBox(height: 4),
        Text('${model.parameters} parameters. Input: ${model.inputDescription}.',
            style: text.bodySmall),
        const SizedBox(height: 12),
        Text('Recorded results', style: text.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Metric')),
              for (final c in cps) DataColumn(label: Text(c.label)),
            ],
            rows: [
              row('Evaluated on', (c) => '${c.evaluation.on} set, ${c.evaluation.images} images'),
              row('Macro F1', (c) => c.evaluation.macroF1.toStringAsFixed(3)),
              row('Accuracy', (c) => _pct(c.evaluation.accuracy)),
              row('Balanced accuracy', (c) => _pct(c.evaluation.balancedAccuracy)),
              for (var i = 0; i < classNames.length; i++)
                row('${classNames[i]} (P / R / F1)', (c) => prf(c.evaluation, i)),
              row(
                'Average top probability',
                (c) => c.evaluation.meanMaxProbability == null
                    ? 'not recorded'
                    : c.evaluation.meanMaxProbability!.toStringAsFixed(3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('P = precision, R = recall, F1 = their combined score. Macro F1 averages the three '
            'class F1 scores equally.', style: text.bodySmall),
        for (final c in cps) Text('${c.label}: ${c.selectionRule}.', style: text.bodySmall),
        for (final pair in extras) ...[
          const SizedBox(height: 8),
          Text(
            '${pair.$1.label}, also on the ${pair.$2.on} set (${pair.$2.images} images): '
            'macro F1 ${pair.$2.macroF1.toStringAsFixed(3)}, accuracy ${_pct(pair.$2.accuracy)}.',
            style: text.bodySmall,
          ),
        ],
      ],
    );
  }
}
