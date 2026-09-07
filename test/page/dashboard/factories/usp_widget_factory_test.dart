import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/views/components/_components.dart';
import 'package:privacy_gui/page/admin/cards/usp_device_info_card.dart';
import 'package:privacy_gui/page/internet_settings/cards/usp_network_status_card.dart';
import 'package:privacy_gui/page/topology/cards/usp_network_topology_card.dart';

/// Unwraps the [CardDensityHost] the factory wraps every card in (#1232), so
/// these tests keep asserting which *card* an ID maps to. That the wrapper is
/// there at all is asserted in `card_density_scope_test.dart`.
Widget? cardOf(Widget? built) => built is CardDensityHost ? built.child : built;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UspWidgetFactory factory;

  setUp(() {
    factory = UspWidgetFactory();
  });

  group('buildWidget', () {
    test('returns non-null for all 18 valid IDs', () {
      for (final spec in UspWidgetSpecs.all) {
        expect(
          factory.buildWidget(spec.id, cardWidth: 400),
          isNotNull,
          reason: '${spec.id} should return a widget',
        );
      }
    });

    test('stats_panel returns UspStatsPanel', () {
      expect(cardOf(factory.buildWidget('stats_panel', cardWidth: 400)),
          isA<UspStatsPanel>());
    });

    test('device_info returns UspDeviceInfoCard', () {
      expect(cardOf(factory.buildWidget('device_info', cardWidth: 400)),
          isA<UspDeviceInfoCard>());
    });

    test('network_status returns UspNetworkStatusCard', () {
      expect(cardOf(factory.buildWidget('network_status', cardWidth: 400)),
          isA<UspNetworkStatusCard>());
    });

    test('topology returns UspNetworkTopologyCard', () {
      expect(cardOf(factory.buildWidget('topology', cardWidth: 400)),
          isA<UspNetworkTopologyCard>());
    });

    test('returns null for unknown ID', () {
      expect(factory.buildWidget('invalid_widget', cardWidth: 400), isNull);
    });

    test('threads the supplied width down to the host it wraps', () {
      final host =
          factory.buildWidget('device_info', cardWidth: 208) as CardDensityHost;
      expect(host.cardWidth, 208);
      // A caller with no box says so, rather than saying nothing (#1401).
      final unmeasured = factory.buildWidget('device_info', cardWidth: null)
          as CardDensityHost;
      expect(unmeasured.cardWidth, isNull);
    });
  });

  group('densityBandFor', () {
    // The resolver the grid asks "has this width changed the form" (#1401). It
    // has to answer with the same band the host would publish from the same
    // width, or a card would sit in its old form until something else
    // invalidated the tile.
    test('agrees with the host for every spec, on both sides of its threshold',
        () {
      for (final spec in UspWidgetSpecs.all) {
        final threshold = spec.normalAbove;
        final widths = <double?>[
          null,
          0,
          double.nan,
          150,
          199,
          200,
          320,
          600,
          if (threshold != null) ...[threshold - 1, threshold, threshold + 1],
        ];
        for (final width in widths) {
          expect(
            factory.densityBandFor(spec.id, width),
            densityForSuppliedWidth(width: width, normalAbove: threshold),
            reason: '${spec.id} at $width',
          );
        }
      }
    });

    test('an unknown ID has no threshold, so every width is normal', () {
      expect(factory.densityBandFor('invalid_widget', 10), CardDensity.normal);
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
