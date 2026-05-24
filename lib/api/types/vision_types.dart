// ---------- Deduce ----------

class DeduceCandidate {
  final String sku;
  final double confidence;
  final String matchReason;
  final String? brand;
  final String? flavor;

  const DeduceCandidate({
    required this.sku,
    required this.confidence,
    required this.matchReason,
    this.brand,
    this.flavor,
  });

  factory DeduceCandidate.fromJson(Map<String, dynamic> j) => DeduceCandidate(
        sku: j['sku'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        matchReason: j['match_reason'] as String,
        brand: j['brand'] as String?,
        flavor: j['flavor'] as String?,
      );
}

class DeduceResponse {
  final List<DeduceCandidate> candidates;
  final String queryUsed;

  const DeduceResponse({required this.candidates, required this.queryUsed});

  factory DeduceResponse.fromJson(Map<String, dynamic> j) => DeduceResponse(
        candidates: (j['candidates'] as List)
            .map((e) => DeduceCandidate.fromJson(e as Map<String, dynamic>))
            .toList(),
        queryUsed: (j['query_used'] as String?) ?? '',
      );
}

// ---------- Session ----------

class SessionStartResponse {
  final String sessionId;

  const SessionStartResponse({required this.sessionId});

  factory SessionStartResponse.fromJson(Map<String, dynamic> j) =>
      SessionStartResponse(sessionId: j['session_id'] as String);
}

// ---------- Pipeline ----------

class SignalScores {
  final double upc;
  final double vlm;
  final double embedding;
  final double dimension;

  const SignalScores({
    required this.upc,
    required this.vlm,
    required this.embedding,
    required this.dimension,
  });

  factory SignalScores.fromJson(Map<String, dynamic> j) => SignalScores(
        upc: (j['upc'] as num?)?.toDouble() ?? 0.0,
        vlm: (j['vlm'] as num?)?.toDouble() ?? 0.0,
        embedding: (j['embedding'] as num?)?.toDouble() ?? 0.0,
        dimension: (j['dimension'] as num?)?.toDouble() ?? 0.0,
      );
}

class DraftProduct {
  final String jobId;
  final String status;
  final String? upc;
  final String? brand;
  final String? flavor;
  final String? category;
  final int? puffCount;
  final int? nicotineMg;
  final String? ocrText;
  final SignalScores? signalScores;

  const DraftProduct({
    required this.jobId,
    required this.status,
    this.upc,
    this.brand,
    this.flavor,
    this.category,
    this.puffCount,
    this.nicotineMg,
    this.ocrText,
    this.signalScores,
  });

  factory DraftProduct.fromJson(Map<String, dynamic> j) {
    final scores = j['signal_scores'];
    return DraftProduct(
      jobId: j['job_id'] as String,
      status: j['status'] as String,
      upc: j['upc'] as String?,
      brand: j['brand'] as String?,
      flavor: j['flavor'] as String?,
      category: j['category'] as String?,
      puffCount: j['puff_count'] as int?,
      nicotineMg: j['nicotine_mg'] as int?,
      ocrText: j['ocr_text'] as String?,
      signalScores: scores != null
          ? SignalScores.fromJson(scores as Map<String, dynamic>)
          : null,
    );
  }
}

// ---------- Commit ----------

class CommitRequest {
  final String jobId;
  final String sku;
  final String brand;
  final String flavor;
  final String category;
  final int? puffCount;
  final int? nicotineMg;
  final bool requiresAttendant;
  final double confidenceThreshold;
  final List<String> aliases;

  const CommitRequest({
    required this.jobId,
    required this.sku,
    required this.brand,
    required this.flavor,
    required this.category,
    this.puffCount,
    this.nicotineMg,
    this.requiresAttendant = false,
    this.confidenceThreshold = 0.85,
    this.aliases = const [],
  });

  Map<String, dynamic> toJson() => {
        'job_id': jobId,
        'sku': sku,
        'brand': brand,
        'flavor': flavor,
        'category': category,
        if (puffCount != null) 'puff_count': puffCount,
        if (nicotineMg != null) 'nicotine_mg': nicotineMg,
        'requires_attendant': requiresAttendant,
        'confidence_threshold': confidenceThreshold,
        'aliases': aliases,
      };
}

class CommitResponse {
  final String sku;
  final String message;

  const CommitResponse({required this.sku, required this.message});

  factory CommitResponse.fromJson(Map<String, dynamic> j) => CommitResponse(
        sku: j['sku'] as String,
        message: (j['message'] as String?) ?? 'committed',
      );
}

// ---------- Error ----------

class VisionException implements Exception {
  final String message;
  final int? statusCode;

  const VisionException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'VisionException($statusCode): $message'
      : 'VisionException: $message';
}
