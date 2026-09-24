import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';

void main() {
  group('InternetSettingsStatus', () {
    test('default values', () {
      const status = InternetSettingsStatus();
      expect(status.isLoading, true);
      expect(status.isSaving, false);
      expect(status.isEditing, false);
      expect(status.error, isNull);
      expect(status.activeMutation, isNull);
      expect(status.pppInstancePath, isNull);
      expect(status.vlanInstancePath, isNull);
      expect(status.mtuModeSupported, isFalse);
    });

    group('copyWith', () {
      test('updates individual fields', () {
        const status = InternetSettingsStatus();
        final updated = status.copyWith(
          isLoading: false,
          isSaving: true,
          isEditing: true,
          error: const NetworkError(detail: 'error'),
          activeMutation: 'save',
          pppInstancePath: 'Device.PPP.Interface.1.',
          vlanInstancePath: 'Device.Ethernet.VLANTermination.1.',
          mtuModeSupported: true,
        );

        expect(updated.isLoading, false);
        expect(updated.isSaving, true);
        expect(updated.isEditing, true);
        expect(updated.error, isA<NetworkError>());
        expect(updated.activeMutation, 'save');
        expect(updated.pppInstancePath, 'Device.PPP.Interface.1.');
        expect(updated.vlanInstancePath, 'Device.Ethernet.VLANTermination.1.');
        expect(updated.mtuModeSupported, isTrue);
      });

      test('preserves unchanged fields', () {
        const status = InternetSettingsStatus(
          isLoading: false,
          pppInstancePath: 'Device.PPP.Interface.1.',
        );
        final updated = status.copyWith(isSaving: true);

        expect(updated.isLoading, false);
        expect(updated.isSaving, true);
        expect(updated.pppInstancePath, 'Device.PPP.Interface.1.');
      });

      test('clearActiveMutation sets activeMutation to null', () {
        const status = InternetSettingsStatus(activeMutation: 'save');
        final updated = status.copyWith(clearActiveMutation: true);

        expect(updated.activeMutation, isNull);
      });

      test('clearPppInstancePath sets pppInstancePath to null', () {
        const status = InternetSettingsStatus(
          pppInstancePath: 'Device.PPP.Interface.1.',
        );
        final updated = status.copyWith(clearPppInstancePath: true);

        expect(updated.pppInstancePath, isNull);
      });

      test('clearVlanInstancePath sets vlanInstancePath to null', () {
        const status = InternetSettingsStatus(
          vlanInstancePath: 'Device.Ethernet.VLANTermination.1.',
        );
        final updated = status.copyWith(clearVlanInstancePath: true);

        expect(updated.vlanInstancePath, isNull);
      });

      test('error is preserved when not provided', () {
        const status =
            InternetSettingsStatus(error: NetworkError(detail: 'error'));
        final updated = status.copyWith(isLoading: false);

        expect(updated.error, isA<NetworkError>());
      });

      test('clearError sets error to null', () {
        const status =
            InternetSettingsStatus(error: NetworkError(detail: 'error'));
        final updated = status.copyWith(clearError: true);

        expect(updated.error, isNull);
      });
    });

    group('Equatable', () {
      test('equal instances', () {
        const a = InternetSettingsStatus(isLoading: false, isSaving: true);
        const b = InternetSettingsStatus(isLoading: false, isSaving: true);
        expect(a, equals(b));
      });

      test('different instances', () {
        const a = InternetSettingsStatus(isLoading: false);
        const b = InternetSettingsStatus(isLoading: true);
        expect(a, isNot(equals(b)));
      });

      test('mtuModeSupported is part of equality', () {
        const a = InternetSettingsStatus(mtuModeSupported: true);
        const b = InternetSettingsStatus(mtuModeSupported: false);
        expect(a, isNot(equals(b)));
      });

      test('readOnlyInfo is part of equality', () {
        // Any differing field will do — this test is about `readOnlyInfo` participating
        // in `InternetSettingsStatus`'s equality, not about which field differs. It used
        // `currentMacAddress` until that field was deleted in #1613; `dhcpv6Duid` is the
        // replacement because it is still a live read-only value.
        const info1 = InternetSettingsReadOnlyInfo(dhcpv6Duid: 'AA');
        const info2 = InternetSettingsReadOnlyInfo(dhcpv6Duid: 'BB');
        const a = InternetSettingsStatus(readOnlyInfo: info1);
        const b = InternetSettingsStatus(readOnlyInfo: info2);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
