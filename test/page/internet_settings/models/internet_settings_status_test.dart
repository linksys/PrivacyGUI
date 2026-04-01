import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';

void main() {
  group('InternetSettingsStatus', () {
    test('default values', () {
      const status = InternetSettingsStatus();
      expect(status.isLoading, true);
      expect(status.isSaving, false);
      expect(status.isEditing, false);
      expect(status.errorMessage, isNull);
      expect(status.activeMutation, isNull);
      expect(status.pppInstancePath, isNull);
      expect(status.vlanInstancePath, isNull);
    });

    group('copyWith', () {
      test('updates individual fields', () {
        const status = InternetSettingsStatus();
        final updated = status.copyWith(
          isLoading: false,
          isSaving: true,
          isEditing: true,
          errorMessage: 'error',
          activeMutation: 'save',
          pppInstancePath: 'Device.PPP.Interface.1.',
          vlanInstancePath: 'Device.Ethernet.VLANTermination.1.',
        );

        expect(updated.isLoading, false);
        expect(updated.isSaving, true);
        expect(updated.isEditing, true);
        expect(updated.errorMessage, 'error');
        expect(updated.activeMutation, 'save');
        expect(updated.pppInstancePath, 'Device.PPP.Interface.1.');
        expect(updated.vlanInstancePath, 'Device.Ethernet.VLANTermination.1.');
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

      test('errorMessage resets to null when not provided', () {
        const status = InternetSettingsStatus(errorMessage: 'error');
        final updated = status.copyWith(isLoading: false);

        expect(updated.errorMessage, isNull);
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

      test('readOnlyInfo is part of equality', () {
        const info1 = InternetSettingsReadOnlyInfo(currentMacAddress: 'AA');
        const info2 = InternetSettingsReadOnlyInfo(currentMacAddress: 'BB');
        const a = InternetSettingsStatus(readOnlyInfo: info1);
        const b = InternetSettingsStatus(readOnlyInfo: info2);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
