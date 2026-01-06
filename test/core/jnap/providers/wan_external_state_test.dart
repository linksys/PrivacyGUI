import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/page/instant_verify/providers/wan_external_state.dart';

void main() {
  group('WANExternalState', () {
    test('creates instance with default values', () {
      const state = WANExternalState();

      expect(state.wanExternal, isNull);
      expect(state.lastUpdate, 0);
    });

    test('creates instance with all fields', () {
      const wanExternal = WanExternalUIModel(
        publicWanIPv4: '1.1.1.1',
      );
      const state = WANExternalState(
        wanExternal: wanExternal,
        lastUpdate: 1000,
      );

      expect(state.wanExternal, wanExternal);
      expect(state.lastUpdate, 1000);
    });

    group('copyWith', () {
      test('copies with new wanExternal', () {
        const original = WANExternalState(lastUpdate: 1000);
        const newWanExternal = WanExternalUIModel(publicWanIPv4: '1.1.1.1');

        final copied = original.copyWith(wanExternal: newWanExternal);

        expect(copied.wanExternal, newWanExternal);
        expect(copied.lastUpdate, 1000);
      });

      test('copies with new lastUpdate', () {
        const wanExternal = WanExternalUIModel(publicWanIPv4: '1.1.1.1');
        const original = WANExternalState(
          wanExternal: wanExternal,
          lastUpdate: 1000,
        );

        final copied = original.copyWith(lastUpdate: 2000);

        expect(copied.wanExternal, wanExternal);
        expect(copied.lastUpdate, 2000);
      });

      test('preserves values when not specified', () {
        const wanExternal = WanExternalUIModel(publicWanIPv4: '1.1.1.1');
        const original = WANExternalState(
          wanExternal: wanExternal,
          lastUpdate: 1000,
        );

        final copied = original.copyWith();

        expect(copied.wanExternal, wanExternal);
        expect(copied.lastUpdate, 1000);
      });
    });

    group('serialization', () {
      test('toMap creates correct map', () {
        const wanExternal = WanExternalUIModel(
          publicWanIPv4: '1.1.1.1',
          privateWanIPv4: '192.168.1.1',
        );
        const state = WANExternalState(
          wanExternal: wanExternal,
          lastUpdate: 1000,
        );

        final map = state.toMap();

        expect(map['lastUpdate'], 1000);
        expect(map['wanExternal'], isA<Map>());
        expect(map['wanExternal']['publicWanIPv4'], '1.1.1.1');
      });

      test('fromMap creates correct instance', () {
        final map = {
          'wanExternal': {
            'publicWanIPv4': '1.1.1.1',
          },
          'lastUpdate': 1000,
        };

        final state = WANExternalState.fromMap(map);

        expect(state.wanExternal?.publicWanIPv4, '1.1.1.1');
        expect(state.lastUpdate, 1000);
      });

      test('fromMap handles null wanExternal', () {
        final map = {
          'wanExternal': null,
          'lastUpdate': 1000,
        };

        final state = WANExternalState.fromMap(map);

        expect(state.wanExternal, isNull);
        expect(state.lastUpdate, 1000);
      });

      test('toJson and fromJson roundtrip', () {
        const wanExternal = WanExternalUIModel(
          publicWanIPv4: '1.1.1.1',
          publicWanIPv6: '::1',
        );
        const original = WANExternalState(
          wanExternal: wanExternal,
          lastUpdate: 1000,
        );

        final json = original.toJson();
        final restored = WANExternalState.fromJson(json);

        expect(restored.wanExternal, wanExternal);
        expect(restored.lastUpdate, 1000);
      });
    });

    group('equality', () {
      test('equal instances have same props', () {
        const wanExternal = WanExternalUIModel(publicWanIPv4: '1.1.1.1');
        const state1 = WANExternalState(
          wanExternal: wanExternal,
          lastUpdate: 1000,
        );
        const state2 = WANExternalState(
          wanExternal: wanExternal,
          lastUpdate: 1000,
        );

        expect(state1, state2);
      });

      test('different instances have different props', () {
        const state1 = WANExternalState(lastUpdate: 1000);
        const state2 = WANExternalState(lastUpdate: 2000);

        expect(state1, isNot(state2));
      });
    });

    test('toString returns correct string', () {
      const state = WANExternalState(lastUpdate: 1000);

      expect(state.toString(), contains('WanExternalState'));
      expect(state.toString(), contains('lastUpdate: 1000'));
    });
  });
}
