import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/express_forwarding_settings.dart';

/// `GetExpressForwardingSettings` output on a router that supports it.
const _output = <String, dynamic>{
  'isExpressForwardingSupported': true,
  'isExpressForwardingEnabled': true,
};

void main() {
  test('reads whether express forwarding is supported and on', () {
    final settings = ExpressForwardingSettings.fromMap(_output);

    expect(settings.isExpressForwardingSupported, isTrue);
    expect(settings.isExpressForwardingEnabled, isTrue);
  });

  test('has no on/off state on a router that does not support it', () {
    // The spec leaves isExpressForwardingEnabled out when unsupported.
    final settings = ExpressForwardingSettings.fromMap(
        const {'isExpressForwardingSupported': false});

    expect(settings.isExpressForwardingSupported, isFalse);
    expect(settings.isExpressForwardingEnabled, isNull);
  });

  test('writes the fields it read', () {
    expect(ExpressForwardingSettings.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final settings = ExpressForwardingSettings.fromMap(_output);

    expect(ExpressForwardingSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    final settings = ExpressForwardingSettings.fromMap(_output);

    final changed = settings.copyWith(isExpressForwardingEnabled: false);

    expect(changed.isExpressForwardingEnabled, isFalse);
    expect(changed.isExpressForwardingSupported, isTrue);
    expect(changed.copyWith(isExpressForwardingEnabled: true), settings);
  });
}
