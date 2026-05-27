import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemonade_mobile/models/server_config.dart';
import 'package:lemonade_mobile/providers/servers_provider.dart';
import 'package:lemonade_mobile/providers/vision_provider.dart';

class _ServerStub extends SelectedServerNotifier {
  final ServerConfig? _initial;
  _ServerStub(super.ref, this._initial) {
    state = _initial;
  }
}

void main() {
  test('visionClientProvider returns null when no server selected', () {
    final container = ProviderContainer(
      overrides: [
        selectedServerProvider.overrideWith((ref) => _ServerStub(ref, null)),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(visionClientProvider), isNull);
  });

  test('visionClientProvider derives port 8787 from selected server', () {
    final container = ProviderContainer(
      overrides: [
        selectedServerProvider.overrideWith(
          (ref) => _ServerStub(
            ref,
            ServerConfig(
              name: 'Test',
              baseUrl: 'http://10.64.0.5:13305',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final client = container.read(visionClientProvider);
    expect(client, isNotNull);
    expect(client!.baseUrl, 'http://10.64.0.5:8787');
  });

  test('visionClientProvider preserves scheme from selected server', () {
    final container = ProviderContainer(
      overrides: [
        selectedServerProvider.overrideWith(
          (ref) => _ServerStub(
            ref,
            ServerConfig(
              name: 'Test',
              baseUrl: 'https://myserver.local:13305',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final client = container.read(visionClientProvider);
    expect(client!.baseUrl, 'https://myserver.local:8787');
  });
}
