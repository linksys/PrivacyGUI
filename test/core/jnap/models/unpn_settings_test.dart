import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/unpn_settings.dart';

/// `GetUPnPSettings` output.
const _output = <String, dynamic>{
  'isUPnPEnabled': true,
  'canUsersConfigure': true,
  'canUsersDisableWANAccess': false,
};

void main() {
  test('reads the UPnP switches', () {
    final settings = UPnPSettings.fromMap(_output);

    expect(settings.isUPnPEnabled, isTrue);
    expect(settings.canUsersConfigure, isTrue);
    expect(settings.canUsersDisableWANAccess, isFalse);
  });

  test('writes the fields it read', () {
    expect(UPnPSettings.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final settings = UPnPSettings.fromMap(_output);

    expect(UPnPSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    final settings = UPnPSettings.fromMap(_output);

    final changed = settings.copyWith(isUPnPEnabled: false);

    expect(changed.isUPnPEnabled, isFalse);
    expect(changed.copyWith(isUPnPEnabled: true), settings);
    expect(settings.copyWith(canUsersConfigure: false).isUPnPEnabled, isTrue);
  });
}
