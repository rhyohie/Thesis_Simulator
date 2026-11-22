import 'package:flutter/material.dart';

import '../api/models.dart';
import '../core/captions.dart';
import '../state/app_controller.dart';
import 'bars_view.dart';
import 'heatmap_view.dart';
import 'probability_bars.dart';

class PrepareView extends StatelessWidget {
  const PrepareView({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Captions.prepare, style: text.bodyMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Labeled(
              title: 'Your photo',
              note: 'shown smaller here',
              child: Image.memory(result.previews.original, height: 160, fit: BoxFit.contain),
            ),
            const Icon(Icons.arrow_forward),
            _Labeled(
              title: 'Shrunk to 60 × 60',
              note: 'blocky on purpose',
              child: Image.memory(
                result.previews.small,
                width: 120,
                height: 120,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
            const Icon(Icons.arrow_forward),
            _Labeled(
              title: 'Enlarged to 224 × 224',
              note: 'what the model sees',
              child: Image.memory(result.previews.model224, width: 160, height: 160, fit: BoxFit.fill),
            ),
            const Icon(Icons.arrow_forward),
            const _Labeled(
              title: 'Scaled',
              note: 'each value ÷ 255',
              child: SizedBox(
                width: 120,
                height: 120,
                child: Center(child: Text('0.00 … 1.00', textAlign: TextAlign.center)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.title, required this.note, required this.child});

  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: text.titleSmall),
        const SizedBox(height: 6),
        child,
        const SizedBox(height: 4),
        Text(note, style: text.bodySmall),
      ],
    );
  }
}

class BlocksView extends StatelessWidget {
  const BlocksView({super.key, required this.controller, required this.result});

  final AppController controller;
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final block = result.blocks[controller.blockIndex];
    final shared = controller.sharedScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.modelId == 'modified' ? Captions.insideUnit : Captions.insideUnitPlain,
          style: text.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < result.blocks.length; i++)
              ChoiceChip(
                label: Text('Block ${i + 1}'),
                selected: controller.blockIndex == i,
                onSelected: (_) => controller.setBlock(i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(Captions.blocks[controller.blockIndex], style: text.bodyMedium),
        const SizedBox(height: 8),
        Text('After pooling: ${block.shape} (${block.channels} maps)', style: text.titleSmall),
        const SizedBox(height: 4),
        Text(Captions.blocksNote, style: text.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Contrast each map'),
              selected: !shared,
              onSelected: (_) => controller.setSharedScale(false),
            ),
            ChoiceChip(
              label: const Text('Same scale for all maps'),
              selected: shared,
              onSelected: (_) => controller.setSharedScale(true),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(shared ? Captions.scaleShared : Captions.scaleContrast, style: text.bodySmall),
        const SizedBox(height: 8),
        HeatLegend(
          lowLabel: shared ? 'low (0)' : 'lowest in this map',
          highLabel: shared ? 'high (block max)' : 'highest in this map',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < block.maps.length; i++)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeatmapView(map: block.maps[i], size: 96, shared: shared),
                  Text(
                    block.maps[i].isFlat ? 'ch ${block.shown[i]} · inactive' : 'ch ${block.shown[i]}',
                    style: text.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class AverageView extends StatelessWidget {
  const AverageView({super.key, required this.controller, required this.result});

  final AppController controller;
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final avg = result.average!;
    final i = controller.averageIndex;
    final count = avg.maps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Captions.average, style: text.bodyMedium),
        const SizedBox(height: 12),
        Text('Pick one of the $count most active block 5 maps:', style: text.titleSmall),
        Slider(
          value: i.toDouble(),
          min: 0,
          max: (count - 1).toDouble(),
          divisions: count - 1,
          label: 'channel ${avg.channels[i]}',
          onChanged: (v) => controller.setAverageIndex(v.round()),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            HeatmapView(map: avg.maps[i], size: 160),
            const Icon(Icons.arrow_forward),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Channel ${avg.channels[i]}: average of its 49 values',
                    style: text.bodyMedium),
                Text(avg.channelAverages[i].toStringAsFixed(4), style: text.headlineMedium),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'All ${avg.allAverages.length} averages (the highlighted bar is channel '
          '${avg.channels[i]})',
          style: text.titleSmall,
        ),
        const SizedBox(height: 8),
        BarsView(values: avg.allAverages, highlight: avg.channels[i], height: 130),
      ],
    );
  }
}

class ClassifyView extends StatelessWidget {
  const ClassifyView({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = result.featuresTotal;
    final label = result.featureLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Captions.classify(total, label), style: text.bodyMedium),
        const SizedBox(height: 8),
        for (final c in result.classScores)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text('Top 5 of $total contributions (weight × average):', style: text.bodySmall),
                  const SizedBox(height: 4),
                  for (final r in c.top)
                    Text(
                      '$label ${r.feature}:  ${r.weight.toStringAsFixed(3)} × '
                      '${r.average.toStringAsFixed(3)} = ${r.product.toStringAsFixed(4)}',
                      style: text.bodyMedium,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'All $total contributions add up to ${c.sumAll.toStringAsFixed(3)}; '
                    'plus bias ${c.bias.toStringAsFixed(3)} = raw score ${c.logit.toStringAsFixed(3)}',
                    style: text.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text('Softmax: raw scores → probabilities', style: text.titleMedium),
        const SizedBox(height: 8),
        ProbabilityBars(
          names: result.classNames,
          probabilities: result.probabilities,
          best: result.predIndex,
        ),
      ],
    );
  }
}

class EvidenceView extends StatelessWidget {
  const EvidenceView({super.key, required this.controller, required this.result});

  final AppController controller;
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final maps = result.evidenceMaps!;
    final c = controller.evidenceClass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Captions.evidence, style: text.bodyMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < result.classNames.length; i++)
              ChoiceChip(
                label: Text(result.classNames[i]),
                selected: c == i,
                onSelected: (_) => controller.setEvidenceClass(i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            children: [
              Image.memory(result.previews.model224, width: 280, height: 280, fit: BoxFit.fill),
              HeatmapView(map: maps[c], size: 280, alpha: 150),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Brighter cells = more evidence for "${result.classNames[c]}" '
          '(a 7×7 map stretched over the 224×224 image the model saw).',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class HeadView extends StatelessWidget {
  const HeadView({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final head = result.head!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Captions.head, style: text.bodyMedium),
        const SizedBox(height: 12),
        Text('Flatten: ${head.flattenValues} numbers', style: text.titleSmall),
        const SizedBox(height: 12),
        for (final stage in head.stages) ...[
          Text('${stage.name}: ${stage.units} units', style: text.titleSmall),
          Text(
            '${(stage.activeFraction * 100).toStringAsFixed(1)}% of the units are active '
            '(not exactly zero) for this photo',
            style: text.bodySmall,
          ),
          const SizedBox(height: 6),
          BarsView(values: stage.bars, height: 90),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
