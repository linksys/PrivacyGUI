/// Provider overrides for `usp_administration_view` — Advanced Settings →
/// Administration (#1660). Not `mock_admin.dart`, which is the menu's
/// password / time zone / reboot page.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/administration/models/administration_feature_state.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/models/administration_status.dart';
import 'package:privacy_gui/page/administration/providers/usp_administration_notifier.dart';

import '../test_data/scenes/administration_scene_data.dart';

/// A `uspAdministrationProvider` pinned to one state.
///
/// Every mutating path is stubbed, so a cell's own layout pass cannot change the
/// state it is measuring.
class FixedAdministrationNotifier extends UspAdministrationNotifier {
  final AdministrationFeatureState _fixedState;

  FixedAdministrationNotifier(this._fixedState);

  @override
  AdministrationFeatureState build() => _fixedState;

  @override
  Future<(AdministrationSettings?, AdministrationStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void setUpnpEnabled(bool enabled) {}
}

/// Overrides for `usp_administration_view`, defaulting to [upnpOnState], the
/// router's own default and what the gate sweeps.
///
/// Not the dirty state: the page's content is the same one card either way, and
/// what dirty adds is the Save bar, which is ui_kit's `UiKitBottomBarConfig` and
/// out of the gate's scope — `gateDmzState` makes the same call for the same
/// reason.
List<Override> administrationOverrides([AdministrationFeatureState? state]) => [
      uspAdministrationProvider.overrideWith(
          () => FixedAdministrationNotifier(state ?? upnpOnState)),
    ];
