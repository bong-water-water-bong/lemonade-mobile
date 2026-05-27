import 'package:flutter_test/flutter_test.dart';
import 'package:lemonade_mobile/api/types/vision_types.dart';

void main() {
  group('DeduceCandidate.fromJson', () {
    test('parses all fields', () {
      final c = DeduceCandidate.fromJson({
        'sku': 'ELFBAR001',
        'confidence': 0.92,
        'match_reason': 'brand match',
        'brand': 'Elf Bar',
        'flavor': 'Mango Ice',
      });
      expect(c.sku, 'ELFBAR001');
      expect(c.confidence, 0.92);
      expect(c.matchReason, 'brand match');
      expect(c.brand, 'Elf Bar');
      expect(c.flavor, 'Mango Ice');
    });

    test('nullable brand and flavor', () {
      final c = DeduceCandidate.fromJson({
        'sku': 'X1',
        'confidence': 0.5,
        'match_reason': 'embedding similarity',
      });
      expect(c.brand, isNull);
      expect(c.flavor, isNull);
    });
  });

  group('DeduceResponse.fromJson', () {
    test('parses candidates and queryUsed', () {
      final r = DeduceResponse.fromJson({
        'candidates': [
          {'sku': 'A', 'confidence': 0.9, 'match_reason': 'upc'},
        ],
        'query_used': 'elf bar mango',
      });
      expect(r.candidates, hasLength(1));
      expect(r.queryUsed, 'elf bar mango');
    });
  });

  group('DraftProduct.fromJson', () {
    test('parses ready draft with signal scores', () {
      final d = DraftProduct.fromJson({
        'job_id': 'j1',
        'status': 'ready',
        'brand': 'Elf Bar',
        'flavor': 'Mango Ice',
        'category': 'disposable_vape',
        'puff_count': 5000,
        'nicotine_mg': 50,
        'upc': '012345678901',
        'ocr_text': 'ELF BAR',
        'signal_scores': {
          'upc': 1.0, 'vlm': 0.8, 'embedding': 0.9, 'dimension': 0.5,
        },
      });
      expect(d.status, 'ready');
      expect(d.brand, 'Elf Bar');
      expect(d.puffCount, 5000);
      expect(d.signalScores!.upc, 1.0);
    });

    test('parses minimal processing draft', () {
      final d = DraftProduct.fromJson({'job_id': 'j2', 'status': 'processing'});
      expect(d.brand, isNull);
      expect(d.signalScores, isNull);
    });
  });

  group('CommitRequest.toJson', () {
    test('serialises required fields', () {
      final req = CommitRequest(
        jobId: 'j1', sku: 'ELF-MANGO-5K',
        brand: 'Elf Bar', flavor: 'Mango Ice',
        category: 'disposable_vape',
      );
      final j = req.toJson();
      expect(j['job_id'], 'j1');
      expect(j['sku'], 'ELF-MANGO-5K');
      expect(j['requires_attendant'], false);
      expect(j['confidence_threshold'], 0.85);
      expect(j['aliases'], isEmpty);
      expect(j.containsKey('puff_count'), isFalse);
    });

    test('includes optional fields when set', () {
      final req = CommitRequest(
        jobId: 'j1', sku: 'S', brand: 'B', flavor: 'F',
        category: 'other', puffCount: 1000, nicotineMg: 50,
        requiresAttendant: true, aliases: ['elfie'],
      );
      final j = req.toJson();
      expect(j['puff_count'], 1000);
      expect(j['nicotine_mg'], 50);
      expect(j['requires_attendant'], true);
      expect(j['aliases'], ['elfie']);
    });
  });

  group('CommitResponse.fromJson', () {
    test('parses sku and message', () {
      final r = CommitResponse.fromJson({'sku': 'ELF-001', 'message': 'committed'});
      expect(r.sku, 'ELF-001');
    });
  });

  group('VisionException', () {
    test('toString includes status code', () {
      final e = VisionException('not found', statusCode: 404);
      expect(e.toString(), contains('404'));
    });
  });
}
