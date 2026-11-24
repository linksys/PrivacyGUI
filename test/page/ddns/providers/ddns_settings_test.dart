import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';

import '../../../mocks/test_data/ddns_test_data.dart';

void main() {
  group('DdnsSettings - provider', () {
    test('no provider is "Disabled"', () {
      expect(DdnsTestData.settings().isEnabled, isFalse);
      expect(const DdnsSettings.empty().isEnabled, isFalse);
    });

    test('a provider path enables it', () {
      expect(DdnsTestData.configuredSettings().isEnabled, isTrue);
    });

    test('an enabled client with no provider chosen writes no account', () {
      final settings = DdnsTestData.settings(clientEnabled: true);

      expect(settings.clientEnabled, isTrue);
      expect(settings.isEnabled, isFalse);
    });

    test('a provider on a disabled client writes no account', () {
      final settings = DdnsTestData.settings(
          clientEnabled: false, providerPath: DdnsTestData.noIpPath);

      expect(settings.isEnabled, isFalse);
    });

    test('the client Enable is part of equality', () {
      final enabled = DdnsTestData.settings(clientEnabled: true);

      expect(enabled.copyWith(clientEnabled: false), isNot(enabled));
    });

    test('clearProviderPath chooses "Disabled" and keeps the account', () {
      final disabled =
          DdnsTestData.configuredSettings().copyWith(clearProviderPath: true);

      expect(disabled.providerPath, isNull);
      expect(disabled.username, 'user@example.com');
      expect(disabled.hostname, 'home.example.net');
    });
  });

  group('DdnsSettings - stored account', () {
    test('a stored user name is a stored account', () {
      expect(DdnsTestData.settings().hasStoredAccount, isFalse);
      expect(DdnsTestData.configuredSettings().hasStoredAccount, isTrue);
    });

    test('the stored password may be kept only for the stored account', () {
      final stored = DdnsTestData.configuredSettings();

      expect(stored.canKeepStoredPassword, isTrue);
      expect(stored.copyWith(username: 'bob').canKeepStoredPassword, isFalse);
      expect(
          stored
              .copyWith(providerPath: DdnsTestData.dynDnsPath)
              .canKeepStoredPassword,
          isFalse);
      expect(DdnsTestData.settings().canKeepStoredPassword, isFalse,
          reason: 'nothing stored');
    });
  });

  group('DdnsSettings - copyWith', () {
    test('changes only the fields given', () {
      final original = DdnsTestData.configuredSettings();

      final next = original.copyWith(password: 'secret');

      expect(next.password, 'secret');
      expect(next.username, original.username);
      expect(next.providerPath, original.providerPath);
      expect(next.providers, original.providers);
      expect(next.storedUsername, original.storedUsername);
      expect(next.storedServerPath, original.storedServerPath);
      expect(next.clientPath, original.clientPath);
      expect(next.hostnamePath, original.hostnamePath);
    });
  });

  group('DdnsSettings - equality', () {
    test('a typed password makes the settings differ, so the page is dirty',
        () {
      final original = DdnsTestData.configuredSettings();

      expect(original.copyWith(password: 'secret'), isNot(original));
      expect(original.copyWith(password: ''), original);
    });
  });

  group('DdnsSettings - toString', () {
    test('leaves the user name and password out', () {
      final text =
          DdnsTestData.configuredSettings(password: 'secret').toString();

      expect(text, isNot(contains('secret')));
      expect(text, isNot(contains('user@example.com')));
      expect(text, contains('password: typed'));
      expect(text, contains('username: set'));
    });
  });
}
