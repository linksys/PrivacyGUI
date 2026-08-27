/// Provider overrides for `usp_internet_settings_view`.
///
/// Moved out of `test/golden_test/golden_framework/mocks/` by #1380 (wave 4) so the
/// layout gate can reach it — `internet_settings_scene_data.dart` says why a move and
/// not a copy. The class below is unchanged from what the golden suite has been using;
/// the argument became optional so the gate can take the default scene without naming
/// it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';

import '../test_data/scenes/internet_settings_scene_data.dart';

/// A `uspInternetSettingsProvider` pinned to one state, with every mutating path
/// stubbed.
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

/// Overrides for `usp_internet_settings_view`, defaulting to
/// [gateInternetSettingsState].
List<Override> internetSettingsOverrides(
        [InternetSettingsFeatureState? state]) =>
    [
      uspInternetSettingsProvider.overrideWith(
        () => FixedInternetSettingsNotifier(state ?? gateInternetSettingsState),
      ),
    ];
