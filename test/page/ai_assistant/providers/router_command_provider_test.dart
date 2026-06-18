import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/ai/_ai.dart';
import 'package:privacy_gui/page/ai_assistant/providers/router_command_provider.dart';

void main() {
  group('routerCommandProviderProvider', () {
    test('provides UspCommandProvider instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerCommandProviderProvider);

      expect(provider, isA<IRouterCommandProvider>());
      expect(provider, isA<UspCommandProvider>());
    });

    test('returns same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider1 = container.read(routerCommandProviderProvider);
      final provider2 = container.read(routerCommandProviderProvider);

      expect(identical(provider1, provider2), isTrue);
    });

    test('provides access to available commands', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerCommandProviderProvider);
      final commands = await provider.listCommands();

      expect(commands, isNotEmpty);
      expect(commands.any((c) => c.name == 'getSystemInfo'), isTrue);
      expect(commands.any((c) => c.name == 'getConnectedDevices'), isTrue);
      expect(commands.any((c) => c.name == 'getWifiSettings'), isTrue);
    });

    test('provides access to available resources', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerCommandProviderProvider);
      final resources = provider.listResources();

      expect(resources, isNotEmpty);
      expect(resources.any((r) => r.uri == 'router://system'), isTrue);
      expect(resources.any((r) => r.uri == 'router://devices'), isTrue);
    });
  });
}
