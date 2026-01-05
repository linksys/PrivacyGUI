import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/wan_external_ui_model.dart';

void main() {
  group('WanExternalUIModel', () {
    test('creates instance with all fields', () {
      const model = WanExternalUIModel(
        publicWanIPv4: '203.0.113.1',
        publicWanIPv6: '2001:db8::1',
        privateWanIPv4: '192.168.1.1',
        privateWanIPv6: 'fe80::1',
      );

      expect(model.publicWanIPv4, '203.0.113.1');
      expect(model.publicWanIPv6, '2001:db8::1');
      expect(model.privateWanIPv4, '192.168.1.1');
      expect(model.privateWanIPv6, 'fe80::1');
    });

    test('creates instance with null fields', () {
      const model = WanExternalUIModel();

      expect(model.publicWanIPv4, isNull);
      expect(model.publicWanIPv6, isNull);
      expect(model.privateWanIPv4, isNull);
      expect(model.privateWanIPv6, isNull);
    });

    group('copyWith', () {
      test('copies with new values', () {
        const original = WanExternalUIModel(
          publicWanIPv4: '1.1.1.1',
        );

        final copied = original.copyWith(
          publicWanIPv6: '::1',
        );

        expect(copied.publicWanIPv4, '1.1.1.1');
        expect(copied.publicWanIPv6, '::1');
      });

      test('preserves original values when not specified', () {
        const original = WanExternalUIModel(
          publicWanIPv4: '1.1.1.1',
          privateWanIPv4: '192.168.1.1',
        );

        final copied = original.copyWith();

        expect(copied.publicWanIPv4, '1.1.1.1');
        expect(copied.privateWanIPv4, '192.168.1.1');
      });
    });

    group('serialization', () {
      test('toMap creates correct map', () {
        const model = WanExternalUIModel(
          publicWanIPv4: '203.0.113.1',
          publicWanIPv6: '2001:db8::1',
        );

        final map = model.toMap();

        expect(map['publicWanIPv4'], '203.0.113.1');
        expect(map['publicWanIPv6'], '2001:db8::1');
        expect(map['privateWanIPv4'], isNull);
        expect(map['privateWanIPv6'], isNull);
      });

      test('fromMap creates correct instance', () {
        final map = {
          'publicWanIPv4': '203.0.113.1',
          'privateWanIPv4': '192.168.1.1',
        };

        final model = WanExternalUIModel.fromMap(map);

        expect(model.publicWanIPv4, '203.0.113.1');
        expect(model.publicWanIPv6, isNull);
        expect(model.privateWanIPv4, '192.168.1.1');
        expect(model.privateWanIPv6, isNull);
      });

      test('toJson and fromJson roundtrip', () {
        const original = WanExternalUIModel(
          publicWanIPv4: '203.0.113.1',
          publicWanIPv6: '2001:db8::1',
          privateWanIPv4: '192.168.1.1',
          privateWanIPv6: 'fe80::1',
        );

        final json = original.toJson();
        final restored = WanExternalUIModel.fromJson(json);

        expect(restored, original);
      });
    });

    group('equality', () {
      test('equal instances have same props', () {
        const model1 = WanExternalUIModel(
          publicWanIPv4: '1.1.1.1',
        );
        const model2 = WanExternalUIModel(
          publicWanIPv4: '1.1.1.1',
        );

        expect(model1, model2);
        expect(model1.hashCode, model2.hashCode);
      });

      test('different instances have different props', () {
        const model1 = WanExternalUIModel(
          publicWanIPv4: '1.1.1.1',
        );
        const model2 = WanExternalUIModel(
          publicWanIPv4: '2.2.2.2',
        );

        expect(model1, isNot(model2));
      });
    });
  });
}
