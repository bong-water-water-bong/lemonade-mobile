import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lemonade_mobile/api/vision_client.dart';
import 'package:lemonade_mobile/api/types/vision_types.dart';

void main() {
  group('VisionApiClient.startSession', () {
    test('returns sessionId from response', () async {
      final client = VisionApiClient(
        'http://localhost:8787',
        httpClient: MockClient((_) async =>
            http.Response(jsonEncode({'session_id': 'abc123', 'qr_png_b64': 'x'}), 200)),
      );
      final sid = await client.startSession();
      expect(sid, 'abc123');
    });

    test('throws VisionException on 500', () async {
      final client = VisionApiClient(
        'http://localhost:8787',
        httpClient: MockClient((_) async => http.Response('error', 500)),
      );
      expect(client.startSession(), throwsA(isA<VisionException>()));
    });
  });

  group('VisionApiClient.finalize', () {
    test('returns jobId from response', () async {
      final client = VisionApiClient(
        'http://localhost:8787',
        httpClient: MockClient((_) async =>
            http.Response(jsonEncode({'job_id': 'job-xyz', 'message': 'processing'}), 200)),
      );
      final jobId = await client.finalize('sid-1');
      expect(jobId, 'job-xyz');
    });
  });

  group('VisionApiClient.deduceText', () {
    test('sends query and topK, returns DeduceResponse', () async {
      http.Request? captured;
      final client = VisionApiClient(
        'http://localhost:8787',
        httpClient: MockClient((req) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'candidates': [
                {'sku': 'E1', 'confidence': 0.9, 'match_reason': 'upc'},
              ],
              'query_used': 'elf bar',
            }),
            200,
          );
        }),
      );
      final resp = await client.deduceText('elf bar', topK: 2);
      expect(resp.candidates, hasLength(1));
      expect(resp.candidates.first.sku, 'E1');
      final body = jsonDecode(captured!.body) as Map;
      expect(body['query'], 'elf bar');
      expect(body['top_k'], 2);
    });
  });

  group('VisionApiClient.deduceAudio', () {
    test('sends bytes as multipart and returns DeduceResponse', () async {
      final client = VisionApiClient(
        'http://localhost:8787',
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'candidates': [],
                'query_used': '',
              }),
              200,
            )),
      );
      final resp = await client.deduceAudio(
          Uint8List.fromList([0, 1, 2]), 'audio/m4a');
      expect(resp.candidates, isEmpty);
    });

    test('throws VisionException on 503', () async {
      final client = VisionApiClient(
        'http://localhost:8787',
        httpClient: MockClient((_) async => http.Response('unavailable', 503)),
      );
      expect(
        client.deduceAudio(Uint8List(4), 'audio/m4a'),
        throwsA(isA<VisionException>()),
      );
    });
  });

  group('VisionApiClient.pollJob', () {
    test('returns draft when status is ready on first poll', () async {
      final client = VisionApiClient(
        'http://localhost:8787',
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({'job_id': 'j1', 'status': 'ready', 'brand': 'Elf Bar'}),
              200,
            )),
      );
      final draft = await client.pollJob('j1', maxAttempts: 1);
      expect(draft.status, 'ready');
      expect(draft.brand, 'Elf Bar');
    });

    test('throws after maxAttempts when still processing', () async {
      final client = VisionApiClient(
        'http://localhost:8787',
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({'job_id': 'j1', 'status': 'processing'}),
              200,
            )),
      );
      expect(
        client.pollJob('j1', maxAttempts: 1),
        throwsA(isA<VisionException>()),
      );
    });
  });
}
