import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/vision_client.dart';
import 'servers_provider.dart';

final visionClientProvider = Provider<VisionApiClient?>((ref) {
  final server = ref.watch(selectedServerProvider);
  if (server == null) return null;
  final uri = Uri.parse(server.baseUrl);
  final baseUrl = '${uri.scheme}://${uri.host}:8787';
  return VisionApiClient(baseUrl);
});
