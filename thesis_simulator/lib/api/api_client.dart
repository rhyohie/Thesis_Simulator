import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.baseUrl);

  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse(baseUrl).replace(path: path, queryParameters: query);

  Future<bool> health() async {
    try {
      final response = await http.get(_uri('/health')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<ModelInfo> modelInfo() async {
    final response = await http.get(_uri('/model-info')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw ApiException('Could not load model information (${response.statusCode}).');
    }
    return ModelInfo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  Uri ablationFigureUri() => _uri('/ablation-figure');

  Future<AnalysisBundle> analyzeAll(Uint8List bytes, String filename) async {
    final request = http.MultipartRequest('POST', _uri('/analyze-all'));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      var detail = 'Server error (${response.statusCode}).';
      try {
        detail = (jsonDecode(body) as Map<String, dynamic>)['detail'].toString();
      } catch (_) {}
      throw ApiException(detail);
    }
    return AnalysisBundle.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  Future<AnalysisResult> analyze(
    Uint8List bytes,
    String filename,
    String model,
    String checkpoint,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/analyze', {'model': model, 'checkpoint': checkpoint}),
    );
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      var detail = 'Server error (${response.statusCode}).';
      try {
        detail = (jsonDecode(body) as Map<String, dynamic>)['detail'].toString();
      } catch (_) {}
      throw ApiException(detail);
    }
    return AnalysisResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }
}
