import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/models.dart';

class AppController extends ChangeNotifier {
  AppController({String baseUrl = 'http://localhost:8000'})
      : baseUrl = baseUrl,
        _client = ApiClient(baseUrl);

  String baseUrl;
  ApiClient _client;

  bool? serverOk; // null = checking
  ModelInfo? info;

  Uint8List? imageBytes;
  String? imageName;
  bool busy = false;
  String? error;
  AnalysisBundle? bundle;

  // Processing panel selections
  int panelModel = 0; // index into results
  int panelTab = 0;
  int blockIndex = 0;
  int averageIndex = 0;
  int evidenceClass = 0;
  bool sharedScale = false;

  List<AnalysisResult> get results => bundle?.results ?? const <AnalysisResult>[];

  Uri get ablationFigureUri => _client.ablationFigureUri();

  Future<void> connect() async {
    serverOk = null;
    notifyListeners();
    serverOk = await _client.health();
    if (serverOk == true) {
      try {
        info = await _client.modelInfo();
      } catch (e) {
        error = 'Connected, but model information could not be loaded: $e';
      }
    }
    notifyListeners();
  }

  void setBaseUrl(String url) {
    baseUrl = url.trim();
    _client = ApiClient(baseUrl);
    connect();
  }

  void setImage(Uint8List bytes, String name) {
    imageBytes = bytes;
    imageName = name;
    bundle = null;
    error = null;
    notifyListeners();
  }

  Future<void> analyze() async {
    final bytes = imageBytes;
    if (bytes == null) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final b = await _client.analyzeAll(bytes, imageName ?? 'photo.jpg');
      bundle = b;
      panelModel = 0;
      panelTab = 0;
      blockIndex = 0;
      averageIndex = 0;
      evidenceClass = b.results.isEmpty ? 0 : b.results.first.predIndex;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not reach the server at $baseUrl. Is it running? ($e)';
    }
    busy = false;
    notifyListeners();
  }

  /// Recorded evaluation info for the checkpoint a result came from.
  CheckpointInfo? checkpointFor(AnalysisResult r) {
    final models = info?.models;
    if (models == null) return null;
    for (final m in models) {
      if (m.id != r.modelId) continue;
      for (final c in m.checkpoints) {
        if (c.id == r.checkpoint) return c;
      }
    }
    return null;
  }

  void setPanelModel(int i) {
    if (i == panelModel) return;
    panelModel = i;
    panelTab = 0;
    blockIndex = 0;
    averageIndex = 0;
    if (i < results.length) evidenceClass = results[i].predIndex;
    notifyListeners();
  }

  void setPanelTab(int i) {
    panelTab = i;
    notifyListeners();
  }

  void setBlock(int i) {
    blockIndex = i;
    notifyListeners();
  }

  void setAverageIndex(int i) {
    averageIndex = i;
    notifyListeners();
  }

  void setEvidenceClass(int i) {
    evidenceClass = i;
    notifyListeners();
  }

  void setSharedScale(bool value) {
    sharedScale = value;
    notifyListeners();
  }
}
