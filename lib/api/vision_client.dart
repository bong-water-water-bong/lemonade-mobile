import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'types/vision_types.dart';

class VisionApiClient {
  final String baseUrl;
  final http.Client _http;

  VisionApiClient(this.baseUrl, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  void dispose() => _http.close();

  // ---- Session ----

  Future<String> startSession() async {
    final uri = Uri.parse('$baseUrl/session/start');
    final resp = await _http.post(uri);
    _check(resp);
    return SessionStartResponse.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>).sessionId;
  }

  Future<void> deleteSession(String sessionId) async {
    final uri = Uri.parse('$baseUrl/session/$sessionId');
    await _http.delete(uri);
  }

  // ---- Capture ----

  Future<void> uploadVideo(String sessionId, File video) async {
    final uri = Uri.parse('$baseUrl/capture/video');
    final req = http.MultipartRequest('POST', uri)
      ..headers['X-Session-Token'] = sessionId
      ..files.add(await http.MultipartFile.fromPath(
        'file', video.path,
        contentType: MediaType('video', 'mp4'),
      ));
    _checkStreamed(await _http.send(req));
  }

  Future<void> uploadStill(
      String sessionId, String angle, File image) async {
    final uri = Uri.parse('$baseUrl/capture/still');
    final req = http.MultipartRequest('POST', uri)
      ..headers['X-Session-Token'] = sessionId
      ..fields['angle'] = angle
      ..files.add(await http.MultipartFile.fromPath(
        'file', image.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    _checkStreamed(await _http.send(req));
  }

  Future<void> uploadNarration(String sessionId, File audio) async {
    final uri = Uri.parse('$baseUrl/capture/audio');
    final ext = audio.path.split('.').last;
    final req = http.MultipartRequest('POST', uri)
      ..headers['X-Session-Token'] = sessionId
      ..files.add(await http.MultipartFile.fromPath(
        'file', audio.path,
        contentType: MediaType('audio', ext),
      ));
    _checkStreamed(await _http.send(req));
  }

  Future<String> finalize(String sessionId) async {
    final uri = Uri.parse('$baseUrl/capture/finalize');
    final req = http.Request('POST', uri)
      ..headers['X-Session-Token'] = sessionId
      ..headers['Content-Length'] = '0';
    final streamed = await _http.send(req);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw VisionException(body, statusCode: streamed.statusCode);
    }
    return (jsonDecode(body) as Map<String, dynamic>)['job_id'] as String;
  }

  // ---- Pipeline ----

  Future<DraftProduct> pollJob(String jobId, {int maxAttempts = 60}) async {
    for (var i = 0; i < maxAttempts; i++) {
      final uri = Uri.parse('$baseUrl/product/draft/$jobId');
      final resp = await _http.get(uri);
      _check(resp);
      final draft = DraftProduct.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
      if (draft.status == 'ready' || draft.status == 'failed') return draft;
      if (i < maxAttempts - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw VisionException('Pipeline timed out after ${maxAttempts * 2}s');
  }

  // ---- Product ----

  Future<CommitResponse> commitProduct(CommitRequest request) async {
    final uri = Uri.parse('$baseUrl/product/commit');
    final resp = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    _check(resp);
    return CommitResponse.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // ---- Deduce ----

  Future<DeduceResponse> deduceText(String query, {int topK = 3}) async {
    final uri = Uri.parse('$baseUrl/deduce/text');
    final resp = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query, 'top_k': topK}),
    );
    _check(resp);
    return DeduceResponse.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<DeduceResponse> deduceAudio(
      Uint8List bytes, String mimeType, {int topK = 3}) async {
    final uri = Uri.parse('$baseUrl/deduce/audio');
    final parts = mimeType.split('/');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file', bytes,
        filename: 'query.${parts.last}',
        contentType: MediaType(parts[0], parts[1]),
      ));
    final streamed = await _http.send(req);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw VisionException(body, statusCode: streamed.statusCode);
    }
    return DeduceResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  // ---- Helpers ----

  void _check(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw VisionException(resp.body, statusCode: resp.statusCode);
    }
  }

  void _checkStreamed(http.StreamedResponse resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw VisionException(
          'HTTP ${resp.statusCode}', statusCode: resp.statusCode);
    }
  }
}
