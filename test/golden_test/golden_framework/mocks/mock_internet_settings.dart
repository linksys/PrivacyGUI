import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';

class FixedInternetSettingsNotifier extends UspInternetSettingsNotifier {
  final InternetSettingsFeatureState _fixedState;

  FixedInternetSettingsNotifier(this._fixedState);

  @override
  InternetSettingsFeatureState build() => _fixedState;

  @override
  Future<(InternetSettingsSettings?, InternetSettingsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {}

  @override
  void updateConnectionType(UspWanConnectionType type) {}

  @override
  void enterEditMode() {}

  @override
  void exitEditMode() {}

  @override
  void revert() {}

  @override
  Future<void> renewDhcpLease() async {}

  @override
  Future<void> renewDhcpv6Lease() async {}
}

/// Returns provider overrides for internet settings golden tests.
List<Override> internetSettingsOverrides(InternetSettingsFeatureState state) =>
    [
      uspInternetSettingsProvider
          .overrideWith(() => FixedInternetSettingsNotifier(state)),
    ];
