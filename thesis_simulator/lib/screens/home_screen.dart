import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/models.dart';
import '../state/app_controller.dart';
import '../widgets/ablation_dialog.dart';
import '../widgets/class_table.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/probability_bars.dart';
import '../widgets/processing_panel.dart';
import '../widgets/settings_dialog.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cacao Pod Model Simulator'),
            backgroundColor: scheme.primaryContainer,
            actions: [
              _ServerChip(controller: controller),
              IconButton(
                tooltip: 'About the models',
                icon: const Icon(Icons.info_outline),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => AboutScreen(controller: controller)),
                ),
              ),
              IconButton(
                tooltip: 'Server settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => showServerDialog(context, controller),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _Body(controller: controller),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServerChip extends StatelessWidget {
  const _ServerChip({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final ok = controller.serverOk;
    final label = ok == null ? 'Connecting…' : (ok ? 'Server connected' : 'Server offline');
    final icon = ok == null ? Icons.sync : (ok ? Icons.check_circle : Icons.error_outline);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: controller.connect,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final results = controller.results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.serverOk == false) _OfflineBanner(controller: controller),
        _InputCard(controller: controller),
        const SizedBox(height: 16),
        if (results.isEmpty)
          const _EmptyResultCard()
        else ...[
          _AgreementBanner(results: results),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                for (final r in results) _ModelResultCard(controller: controller, result: r),
              ];
              if (constraints.maxWidth >= 820 && cards.length > 1) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    cards[i],
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ProcessingPanel(controller: controller),
        ],
        const SizedBox(height: 16),
        const DisclaimerCard(),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Cannot reach the Python service at ${controller.baseUrl}. Start it (see the README), '
          'then press the server chip at the top to reconnect.',
          style: TextStyle(color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.controller});

  final AppController controller;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      controller.setImage(bytes, file.name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final canAnalyze =
        controller.imageBytes != null && controller.serverOk == true && !controller.busy;

    final preview = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: controller.imageBytes == null
          ? const Center(child: Icon(Icons.photo_outlined, size: 64))
          : Image.memory(controller.imageBytes!, fit: BoxFit.contain),
    );

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. Choose a photo', style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Both models analyze the same photo and show their answers side by side.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _pick(context, ImageSource.gallery),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(context, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: canAnalyze ? controller.analyze : null,
          icon: controller.busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.analytics_outlined),
          label: Text(controller.busy ? 'Analyzing…' : 'Analyze photo'),
        ),
        if (controller.error != null) ...[
          const SizedBox(height: 8),
          Text(controller.error!, style: TextStyle(color: scheme.error)),
        ],
        const SizedBox(height: 8),
        Text(
          'On a computer the Camera button opens a file chooser; it uses the camera on a phone.',
          style: text.bodySmall,
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 640) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 240, height: 240, child: preview),
                  const SizedBox(width: 20),
                  Expanded(child: controls),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(aspectRatio: 1, child: preview),
                const SizedBox(height: 12),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2. Results', style: text.titleMedium),
            const SizedBox(height: 12),
            const Text(
              'Choose a photo and press Analyze photo. Each model\'s prediction, its probability for '
              'every class, and its recorded F1 score for each class will appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementBanner extends StatelessWidget {
  const _AgreementBanner({required this.results});

  final List<AnalysisResult> results;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = {for (final r in results) r.predLabel};
    final agree = labels.length == 1;
    return Card(
      color: agree ? scheme.secondaryContainer : scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(agree ? Icons.handshake_outlined : Icons.compare_arrows),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                agree
                    ? 'Both models answer ${results.first.predLabel}.'
                    : 'The models disagree: '
                        '${[for (final r in results) '${r.modelLabel} says ${r.predLabel}'].join(', ')}.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelResultCard extends StatelessWidget {
  const _ModelResultCard({required this.controller, required this.result});

  final AppController controller;
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final checkpoint = controller.checkpointFor(result);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(result.modelLabel, style: text.titleMedium)),
                if (result.modelId == 'modified')
                  IconButton(
                    tooltip: 'Why BN+GAP instead of BN-only or GAP-only?',
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => showAblationDialog(context, controller),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.predLabel, style: text.headlineMedium),
                  Text(
                    '${(result.probability * 100).toStringAsFixed(1)}% probability · '
                    '${result.checkpointLabel}',
                    style: text.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A high probability does not mean the answer is right: these models are often '
              'overconfident.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            ProbabilityBars(
              names: result.classNames,
              probabilities: result.probabilities,
              best: result.predIndex,
            ),
            const SizedBox(height: 12),
            Text('Class-level results', style: text.titleSmall),
            const SizedBox(height: 4),
            ClassTable(result: result, checkpoint: checkpoint),
            const SizedBox(height: 4),
            Text(
              checkpoint == null
                  ? 'Analysis took ${result.elapsedMs} ms.'
                  : 'Macro F1 on the ${checkpoint.evaluation.on} images: '
                      '${checkpoint.evaluation.macroF1.toStringAsFixed(3)}. '
                      'Analysis took ${result.elapsedMs} ms.',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
