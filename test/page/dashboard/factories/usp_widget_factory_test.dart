import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/views/components/_components.dart';
import 'package:privacy_gui/page/admin/cards/usp_device_info_card.dart';
import 'package:privacy_gui/page/internet_settings/cards/usp_network_status_card.dart';
import 'package:privacy_gui/page/topology/cards/usp_network_topology_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UspWidgetFactory factory;

  setUp(() {
    factory = UspWidgetFactory();
  });

  group('buildWidget', () {
    test('returns non-null for all 17 valid IDs', () {
      for (final spec in UspWidgetSpecs.all) {
        expect(
          factory.buildWidget(spec.id),
          isNotNull,
          reason: '${spec.id} should return a widget',
        );
      }
    });

    test('stats_panel returns UspStatsPanel', () {
      expect(factory.buildWidget('stats_panel'), isA<UspStatsPanel>());
    });

    test('device_info returns UspDeviceInfoCard', () {
      expect(factory.buildWidget('device_info'), isA<UspDeviceInfoCard>());
    });

    test('network_status returns UspNetworkStatusCard', () {
      expect(
          factory.buildWidget('network_status'), isA<UspNetworkStatusCard>());
    });

    test('topology returns UspNetworkTopologyCard', () {
      expect(factory.buildWidget('topology'), isA<UspNetworkTopologyCard>());
    });

    test('returns null for unknown ID', () {
      expect(factory.buildWidget('invalid_widget'), isNull);
    });
  });

  group('shouldWrapInCard', () {
    test('always returns false', () {
      for (final spec in UspWidgetSpecs.all) {
        expect(
          factory.shouldWrapInCard(spec.id),
          isFalse,
          reason: '${spec.id} should not wrap in card',
        );
      }
    });
  });

  group('getSpec', () {
    test('returns correct spec for valid ID', () {
      final spec = factory.getSpec('device_info');
      expect(spec, isNotNull);
      expect(spec!.id, 'device_info');
    });

    test('returns null for unknown ID', () {
      expect(factory.getSpec('invalid'), isNull);
    });
  });

  group('Provider', () {
    test('uspWidgetFactoryProvider provides UspWidgetFactory', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final instance = container.read(uspWidgetFactoryProvider);
      expect(instance, isA<UspWidgetFactory>());
    });
  });
}
