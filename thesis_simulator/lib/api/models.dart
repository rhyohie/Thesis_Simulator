import 'dart:convert';
import 'dart:typed_data';

List<double> _doubles(dynamic list) =>
    [for (final x in list as List<dynamic>) (x as num).toDouble()];

List<int> _ints(dynamic list) => [for (final x in list as List<dynamic>) (x as num).toInt()];

/// A small grid of numbers (one feature map or evidence map).
/// [v] is stretched to this map's own range; [vs] (feature maps only) uses one scale shared by all
/// maps of the block.
class MapData {
  const MapData(this.h, this.w, this.v, [this.vs]);

  final int h;
  final int w;
  final List<double> v; // row-major, length h * w
  final List<double>? vs;

  double at(int y, int x) => v[y * w + x];

  /// True when every cell has the same value (an inactive map).
  bool get isFlat {
    if (v.isEmpty) return true;
    final first = v.first;
    for (final x in v) {
      if (x != first) return false;
    }
    return true;
  }

  factory MapData.fromJson(Map<String, dynamic> j) => MapData(
        (j['h'] as num).toInt(),
        (j['w'] as num).toInt(),
        _doubles(j['v']),
        j['vs'] == null ? null : _doubles(j['vs']),
      );
}

class BlockData {
  const BlockData({
    required this.index,
    required this.shape,
    required this.channels,
    required this.shown,
    required this.maps,
  });

  final int index;
  final String shape;
  final int channels;
  final List<int> shown; // channel numbers of the drawn maps
  final List<MapData> maps;

  factory BlockData.fromJson(Map<String, dynamic> j) => BlockData(
        index: (j['index'] as num).toInt(),
        shape: j['shape'] as String,
        channels: (j['channels'] as num).toInt(),
        shown: _ints(j['shown_channels']),
        maps: [
          for (final m in j['maps'] as List<dynamic>) MapData.fromJson(m as Map<String, dynamic>),
        ],
      );
}

class ContributionRow {
  const ContributionRow({
    required this.feature,
    required this.weight,
    required this.average,
    required this.product,
  });

  final int feature;
  final double weight;
  final double average;
  final double product;

  factory ContributionRow.fromJson(Map<String, dynamic> j) => ContributionRow(
        feature: (j['feature'] as num).toInt(),
        weight: (j['weight'] as num).toDouble(),
        average: (j['average'] as num).toDouble(),
        product: (j['product'] as num).toDouble(),
      );
}

class ClassScore {
  const ClassScore({
    required this.name,
    required this.logit,
    required this.bias,
    required this.sumAll,
    required this.top,
  });

  final String name;
  final double logit;
  final double bias;
  final double sumAll;
  final List<ContributionRow> top;

  factory ClassScore.fromJson(Map<String, dynamic> j) => ClassScore(
        name: j['name'] as String,
        logit: (j['logit'] as num).toDouble(),
        bias: (j['bias'] as num).toDouble(),
        sumAll: (j['sum_all'] as num).toDouble(),
        top: [
          for (final r in j['top'] as List<dynamic>)
            ContributionRow.fromJson(r as Map<String, dynamic>),
        ],
      );
}

class Previews {
  const Previews({required this.original, required this.small, required this.model224});

  final Uint8List original;
  final Uint8List small;
  final Uint8List model224;

  factory Previews.fromJson(Map<String, dynamic> prev) => Previews(
        original: base64Decode(prev['original_png_b64'] as String),
        small: base64Decode(prev['small_60_png_b64'] as String),
        model224: base64Decode(prev['model_224_png_b64'] as String),
      );
}

class AverageData {
  const AverageData({
    required this.channels,
    required this.maps,
    required this.channelAverages,
    required this.allAverages,
  });

  final List<int> channels;
  final List<MapData> maps;
  final List<double> channelAverages;
  final List<double> allAverages;

  factory AverageData.fromJson(Map<String, dynamic> j) => AverageData(
        channels: _ints(j['channels']),
        maps: [
          for (final m in j['maps'] as List<dynamic>) MapData.fromJson(m as Map<String, dynamic>),
        ],
        channelAverages: _doubles(j['channel_averages']),
        allAverages: _doubles(j['all_averages']),
      );
}

class HeadStage {
  const HeadStage({
    required this.name,
    required this.units,
    required this.activeFraction,
    required this.bars,
  });

  final String name;
  final int units;
  final double activeFraction;
  final List<double> bars;

  factory HeadStage.fromJson(Map<String, dynamic> j) => HeadStage(
        name: j['name'] as String,
        units: (j['units'] as num).toInt(),
        activeFraction: (j['active_fraction'] as num).toDouble(),
        bars: _doubles(j['bars']),
      );
}

class HeadData {
  const HeadData({required this.flattenValues, required this.stages});

  final int flattenValues;
  final List<HeadStage> stages;

  factory HeadData.fromJson(Map<String, dynamic> j) => HeadData(
        flattenValues: (j['flatten_values'] as num).toInt(),
        stages: [
          for (final s in j['stages'] as List<dynamic>) HeadStage.fromJson(s as Map<String, dynamic>),
        ],
      );
}

class AnalysisResult {
  const AnalysisResult({
    required this.modelId,
    required this.modelLabel,
    required this.checkpoint,
    required this.checkpointLabel,
    required this.elapsedMs,
    required this.classNames,
    required this.predIndex,
    required this.predLabel,
    required this.probability,
    required this.probabilities,
    required this.logits,
    required this.previews,
    required this.blocks,
    required this.featuresTotal,
    required this.featureLabel,
    required this.classScores,
    this.average,
    this.evidenceMaps,
    this.head,
  });

  final String modelId;
  final String modelLabel;
  final String checkpoint;
  final String checkpointLabel;
  final int elapsedMs;
  final List<String> classNames;
  final int predIndex;
  final String predLabel;
  final double probability;
  final List<double> probabilities;
  final List<double> logits;
  final Previews previews;
  final List<BlockData> blocks;
  final int featuresTotal;
  final String featureLabel;
  final List<ClassScore> classScores;
  final AverageData? average; // modified model only
  final List<MapData>? evidenceMaps; // modified model only
  final HeadData? head; // baseline only

  factory AnalysisResult.fromJson(Map<String, dynamic> j, {Previews? previews}) {
    final meta = j['meta'] as Map<String, dynamic>;
    final pred = j['prediction'] as Map<String, dynamic>;
    final classify = j['classify'] as Map<String, dynamic>;
    final avg = j['average'];
    final evidence = j['evidence'];
    final head = j['head'];
    return AnalysisResult(
      modelId: meta['model'] as String,
      modelLabel: meta['model_label'] as String,
      checkpoint: meta['checkpoint'] as String,
      checkpointLabel: meta['checkpoint_label'] as String,
      elapsedMs: (meta['elapsed_ms'] as num).toInt(),
      classNames: [for (final s in j['class_names'] as List<dynamic>) s as String],
      predIndex: (pred['index'] as num).toInt(),
      predLabel: pred['label'] as String,
      probability: (pred['probability'] as num).toDouble(),
      probabilities: _doubles(pred['probabilities']),
      logits: _doubles(pred['logits']),
      previews: previews ?? Previews.fromJson(j['previews'] as Map<String, dynamic>),
      blocks: [
        for (final b in j['blocks'] as List<dynamic>) BlockData.fromJson(b as Map<String, dynamic>),
      ],
      featuresTotal: (classify['features_total'] as num).toInt(),
      featureLabel: classify['feature_label'] as String,
      classScores: [
        for (final c in classify['classes'] as List<dynamic>)
          ClassScore.fromJson(c as Map<String, dynamic>),
      ],
      average: avg == null ? null : AverageData.fromJson(avg as Map<String, dynamic>),
      evidenceMaps: evidence == null
          ? null
          : [
              for (final m in (evidence as Map<String, dynamic>)['maps'] as List<dynamic>)
                MapData.fromJson(m as Map<String, dynamic>),
            ],
      head: head == null ? null : HeadData.fromJson(head as Map<String, dynamic>),
    );
  }
}

/// The answer of /analyze-all: one set of previews and one result per loaded model.
class AnalysisBundle {
  const AnalysisBundle({required this.previews, required this.results});

  final Previews previews;
  final List<AnalysisResult> results;

  factory AnalysisBundle.fromJson(Map<String, dynamic> j) {
    final previews = Previews.fromJson(j['previews'] as Map<String, dynamic>);
    return AnalysisBundle(
      previews: previews,
      results: [
        for (final r in j['results'] as List<dynamic>)
          AnalysisResult.fromJson(r as Map<String, dynamic>, previews: previews),
      ],
    );
  }
}

/// Recorded evaluation of one checkpoint on one image set.
class EvalInfo {
  const EvalInfo({
    required this.on,
    required this.images,
    required this.accuracy,
    required this.macroF1,
    required this.balancedAccuracy,
    required this.precision,
    required this.recall,
    required this.f1,
    required this.support,
    this.meanMaxProbability,
  });

  final String on; // 'validation' or 'test'
  final int images;
  final double accuracy;
  final double macroF1;
  final double balancedAccuracy;
  final List<double> precision;
  final List<double> recall;
  final List<double> f1;
  final List<int> support;
  final double? meanMaxProbability;

  factory EvalInfo.fromJson(Map<String, dynamic> v) {
    final mmp = v['mean_max_probability'];
    return EvalInfo(
      on: v['on'] as String,
      images: (v['images'] as num).toInt(),
      accuracy: (v['accuracy'] as num).toDouble(),
      macroF1: (v['macro_f1'] as num).toDouble(),
      balancedAccuracy: (v['balanced_accuracy'] as num).toDouble(),
      precision: _doubles(v['precision']),
      recall: _doubles(v['recall']),
      f1: _doubles(v['f1']),
      support: _ints(v['support']),
      meanMaxProbability: mmp == null ? null : (mmp as num).toDouble(),
    );
  }
}

class CheckpointInfo {
  const CheckpointInfo({
    required this.id,
    required this.label,
    required this.epoch,
    required this.selectionRule,
    required this.evaluation,
    this.alsoEvaluated,
  });

  final String id;
  final String label;
  final int epoch;
  final String selectionRule;
  final EvalInfo evaluation;
  final EvalInfo? alsoEvaluated;

  factory CheckpointInfo.fromJson(Map<String, dynamic> j) => CheckpointInfo(
        id: j['id'] as String,
        label: j['label'] as String,
        epoch: (j['epoch'] as num).toInt(),
        selectionRule: j['selection_rule'] as String,
        evaluation: EvalInfo.fromJson(j['evaluation'] as Map<String, dynamic>),
        alsoEvaluated: j['also_evaluated'] == null
            ? null
            : EvalInfo.fromJson(j['also_evaluated'] as Map<String, dynamic>),
      );
}

class ModelEntry {
  const ModelEntry({
    required this.id,
    required this.label,
    required this.description,
    required this.parameters,
    required this.inputDescription,
    required this.defaultCheckpoint,
    required this.checkpoints,
  });

  final String id;
  final String label;
  final String description;
  final int parameters;
  final String inputDescription;
  final String defaultCheckpoint;
  final List<CheckpointInfo> checkpoints;

  factory ModelEntry.fromJson(Map<String, dynamic> j) => ModelEntry(
        id: j['id'] as String,
        label: j['label'] as String,
        description: j['description'] as String,
        parameters: (j['parameters'] as num).toInt(),
        inputDescription: j['input_description'] as String,
        defaultCheckpoint: j['default_checkpoint'] as String,
        checkpoints: [
          for (final c in j['checkpoints'] as List<dynamic>)
            CheckpointInfo.fromJson(c as Map<String, dynamic>),
        ],
      );
}

class AblationRow {
  const AblationRow({
    required this.model,
    required this.checkpoint,
    required this.epoch,
    required this.accuracy,
    required this.macroF1,
    required this.podBorerFound,
    required this.loss,
  });

  final String model;
  final String checkpoint;
  final int epoch;
  final double accuracy;
  final double macroF1;
  final int podBorerFound;
  final double loss;

  factory AblationRow.fromJson(Map<String, dynamic> j) => AblationRow(
        model: j['model'] as String,
        checkpoint: j['checkpoint'] as String,
        epoch: (j['epoch'] as num).toInt(),
        accuracy: (j['accuracy'] as num).toDouble(),
        macroF1: (j['macro_f1'] as num).toDouble(),
        podBorerFound: (j['pod_borer_found'] as num).toInt(),
        loss: (j['loss'] as num).toDouble(),
      );
}

class AblationInfo {
  const AblationInfo({
    required this.title,
    required this.source,
    required this.rows,
    required this.podBorerTotal,
    required this.takeaways,
    required this.caveats,
  });

  final String title;
  final String source;
  final List<AblationRow> rows;
  final int podBorerTotal;
  final List<String> takeaways;
  final List<String> caveats;

  factory AblationInfo.fromJson(Map<String, dynamic> j) => AblationInfo(
        title: j['title'] as String,
        source: j['source'] as String,
        rows: [
          for (final r in j['rows'] as List<dynamic>) AblationRow.fromJson(r as Map<String, dynamic>),
        ],
        podBorerTotal: (j['pod_borer_total'] as num).toInt(),
        takeaways: [for (final s in j['takeaways'] as List<dynamic>) s as String],
        caveats: [for (final s in j['caveats'] as List<dynamic>) s as String],
      );
}

class ModelInfo {
  const ModelInfo({
    required this.classNames,
    required this.models,
    required this.limits,
    required this.ablation,
  });

  final List<String> classNames;
  final List<ModelEntry> models;
  final List<String> limits;
  final AblationInfo ablation;

  factory ModelInfo.fromJson(Map<String, dynamic> j) => ModelInfo(
        classNames: [for (final s in j['class_names'] as List<dynamic>) s as String],
        models: [
          for (final m in j['models'] as List<dynamic>) ModelEntry.fromJson(m as Map<String, dynamic>),
        ],
        limits: [for (final s in j['limits'] as List<dynamic>) s as String],
        ablation: AblationInfo.fromJson(j['ablation'] as Map<String, dynamic>),
      );
}
