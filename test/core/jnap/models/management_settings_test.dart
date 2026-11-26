import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';

/// `GetManagementSettings2` output on a router that supports wireless
/// management.
const _output = <String, dynamic>{
  'canManageUsingHTTP': true,
  'canManageUsingHTTPS': false,
  'isManageWirelesslySupported': true,
  'canManageWirelessly': true,
  'canManageRemotely': false,
};

void main() {
  test('reads the router management access', () {
    final settings = ManagementSettings.fromMap(_output);

    expect(settings.canManageUsingHTTP, isTrue);
    expect(settings.canManageUsingHTTPS, isFalse);
    expect(settings.isManageWirelesslySupported, isTrue);
    expect(settings.canManageWirelessly, isTrue);
    expect(settings.canManageRemotely, isFalse);
  });

  test('has no wireless setting on a router that does not support it', () {
    final settings = ManagementSettings.fromMap(const {
      'canManageUsingHTTP': true,
      'canManageUsingHTTPS': true,
      'isManageWirelesslySupported': false,
      'canManageRemotely': false,
    });

    expect(settings.canManageWirelessly, isNull);
  });

  test('writes the fields it read', () {
    expect(ManagementSettings.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final settings = ManagementSettings.fromMap(_output);

    expect(ManagementSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    final settings = ManagementSettings.fromMap(_output);

    final changed = settings.copyWith(canManageWirelessly: false);

    expect(changed.canManageWirelessly, isFalse);
    expect(changed.copyWith(canManageWirelessly: true), settings);
    expect(
        settings.copyWith(canManageRemotely: true).canManageWirelessly, isTrue);
  });
}
