import 'package:flutter/material.dart';

import '../api/models.dart';
import '../state/app_controller.dart';
import 'stage_views.dart';

class _PanelTab {
  const _PanelTab(this.label, this.build);

  final String label;
  final Widget Function(AppController controller, AnalysisResult result) build;
}

/// Optional panel that shows how a model processed the analyzed photo.
/// The tabs depend on the model: only the modified model has averages and an evidence map.
class ProcessingPanel extends StatelessWidget {
  const ProcessingPanel({super.key, required this.controller});

  final AppController controller;

  List<_PanelTab> _tabs(AnalysisResult result) => [
        _PanelTab('Prepare', (c, r) => PrepareView(result: r)),
        _PanelTab('Blocks', (c, r) => BlocksView(controller: c, result: r)),
        if (result.average != null)
          _PanelTab('Average', (c, r) => AverageView(controller: c, result: r)),
        if (result.head != null) _PanelTab('Classifier layers', (c, r) => HeadView(result: r)),
        _PanelTab('Classify', (c, r) => ClassifyView(result: r)),
        if (result.evidenceMaps != null)
          _PanelTab('Where it looked', (c, r) => EvidenceView(controller: c, result: r)),
      ];

  @override
  Widget build(BuildContext context) {
    final results = controller.results;
    if (results.isEmpty) return const SizedBox.shrink();
    final modelIndex = controller.panelModel >= results.length ? 0 : controller.panelModel;
    final result = results[modelIndex];
    final tabs = _tabs(result);
    final selected = controller.panelTab >= tabs.length ? 0 : controller.panelTab;
    return Card(
      child: ExpansionTile(
        title: const Text('How the models processed this photo'),
        subtitle: const Text('Optional: the steps from your photo to each model\'s answer'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Show the steps of:', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < results.length; i++)
                ChoiceChip(
                  label: Text(results[i].modelLabel),
                  selected: modelIndex == i,
                  onSelected: (_) => controller.setPanelModel(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < tabs.length; i++)
                ChoiceChip(
                  label: Text('${i + 1}. ${tabs[i].label}'),
                  selected: selected == i,
                  onSelected: (_) => controller.setPanelTab(i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          tabs[selected].build(controller, result),
        ],
      ),
    );
  }
}
