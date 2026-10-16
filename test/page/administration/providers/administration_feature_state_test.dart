import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/administration/models/administration_feature_state.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/models/administration_status.dart';

void main() {
  group('AdministrationFeatureState - dirty state and copy', () {
    test('initial() is loading with UPnP off and nothing dirty', () {
      final state = AdministrationFeatureState.initial();

      expect(state.status.isLoading, isTrue);
      expect(state.status.isSaving, isFalse);
      expect(state.status.error, isNull);
      expect(state.settings.current.upnpEnabled, isFalse);
      expect(state.isDirty, isFalse);
    });

    test('isDirty follows the UPnP switch', () {
      AdministrationFeatureState of(bool original, bool current) =>
          AdministrationFeatureState(
            settings: Preservable(
              original: AdministrationSettings(
                  upnpEnabled: original,
                  sipAlgEnabled: false,
                  mgmtWifiEnabled: true),
              current: AdministrationSettings(
                  upnpEnabled: current,
                  sipAlgEnabled: false,
                  mgmtWifiEnabled: true),
            ),
            status: const AdministrationStatus(),
          );

      expect(of(true, false).isDirty, isTrue);
      expect(of(true, true).isDirty, isFalse);
    });

    test('isDirty follows the SIP ALG switch', () {
      const off = AdministrationSettings(
          upnpEnabled: true, sipAlgEnabled: false, mgmtWifiEnabled: true);
      final state = AdministrationFeatureState(
        settings: Preservable(
            original: off, current: off.copyWith(sipAlgEnabled: true)),
        status: const AdministrationStatus(),
      );

      expect(state.isDirty, isTrue);
    });

    test('isDirty follows the management-over-Wi-Fi switch', () {
      const on = AdministrationSettings(
          upnpEnabled: true, sipAlgEnabled: false, mgmtWifiEnabled: true);
      final state = AdministrationFeatureState(
        settings: Preservable(
            original: on, current: on.copyWith(mgmtWifiEnabled: false)),
        status: const AdministrationStatus(),
      );

      expect(state.isDirty, isTrue);
    });

    test('copyWith replaces only what it is given', () {
      final state = AdministrationFeatureState.initial();

      final updated =
          state.copyWith(status: const AdministrationStatus(isSaving: true));

      expect(updated.status.isSaving, isTrue);
      expect(updated.settings, state.settings);
    });

    test('toMap reports the switch and the flags', () {
      final map = AdministrationFeatureState.initial().toMap();

      expect(map, {
        'upnpEnabled': false,
        'sipAlgEnabled': false,
        'mgmtWifiEnabled': null,
        'isDirty': false,
        'isLoading': true,
      });
    });
  });

  group('AdministrationSettings - value semantics', () {
    test('copyWith and equality', () {
      const on = AdministrationSettings(
          upnpEnabled: true, sipAlgEnabled: true, mgmtWifiEnabled: true);

      expect(
          on.copyWith(upnpEnabled: false),
          const AdministrationSettings(
              upnpEnabled: false, sipAlgEnabled: true, mgmtWifiEnabled: true));
      expect(
          on.copyWith(sipAlgEnabled: false),
          const AdministrationSettings(
              upnpEnabled: true, sipAlgEnabled: false, mgmtWifiEnabled: true));
      expect(
          on.copyWith(mgmtWifiEnabled: false),
          const AdministrationSettings(
              upnpEnabled: true, sipAlgEnabled: true, mgmtWifiEnabled: false));
      expect(on.copyWith(), on);
      expect(
          const AdministrationSettings.empty(),
          const AdministrationSettings(
              upnpEnabled: false, sipAlgEnabled: false, mgmtWifiEnabled: null));
    });

    test('a firmware without the rule stays without it through an edit', () {
      const noRule = AdministrationSettings(
          upnpEnabled: true, sipAlgEnabled: false, mgmtWifiEnabled: null);

      expect(noRule.copyWith(upnpEnabled: false).mgmtWifiEnabled, isNull);
    });
  });

  group('AdministrationStatus - copyWith', () {
    test('copyWith keeps or clears the error', () {
      const failed = AdministrationStatus(error: NetworkError(detail: 'x'));

      expect(failed.copyWith(isSaving: true).error, isA<NetworkError>());
      expect(failed.copyWith(clearError: true).error, isNull);
      expect(const AdministrationStatus.loading().isLoading, isTrue);
    });
  });
}
