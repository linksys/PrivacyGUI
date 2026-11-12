/// Provider overrides for `usp_ddns_view` (#641).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/ddns/models/ddns_feature_state.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';
import 'package:privacy_gui/page/ddns/providers/ddns_status_data_provider.dart';
import 'package:privacy_gui/page/ddns/providers/usp_ddns_notifier.dart';

import '../test_data/scenes/ddns_scene_data.dart';
import 'mock_wan_data.dart';

/// A `uspDdnsProvider` pinned to one state.
///
/// Every mutating path is stubbed: the page writes through `updateSetting` on
/// every keystroke, `selectProvider` on the dropdown and `validate` when a
/// field loses focus, so a live one would let a cell's own layout pass change
/// the state it is measuring.
class FixedDdnsNotifier extends UspDdnsNotifier {
  final DdnsFeatureState _fixedState;

  FixedDdnsNotifier(this._fixedState);

  @override
  DdnsFeatureState build() => _fixedState;

  @override
  Future<(DdnsSettings?, DdnsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void selectProvider(String? providerPath) {}

  @override
  void updateSetting(DdnsSettings Function(DdnsSettings) updater) {}

  @override
  void validate() {}

  @override
  void validateField(DdnsField field) {}
}

/// A `ddnsStatusDataProvider` that settles with one status and reads nothing.
class FixedDdnsStatusData extends DdnsStatusDataNotifier {
  final DdnsUpdateStatus _status;

  FixedDdnsStatusData(this._status);

  @override
  Future<DdnsUpdateStatus> build() async => _status;

  @override
  Future<void> refresh() async {}
}

/// Overrides for `usp_ddns_view`, defaulting to [gateDdnsState] beside
/// [gateDdnsUpdateStatus] on a WAN at [wanUpModel]'s private address.
List<Override> ddnsOverrides({
  DdnsFeatureState? state,
  DdnsUpdateStatus? status,
  WanStatusUIModel? wan,
}) =>
    [
      uspDdnsProvider
          .overrideWith(() => FixedDdnsNotifier(state ?? gateDdnsState)),
      ddnsStatusDataProvider.overrideWith(
          () => FixedDdnsStatusData(status ?? gateDdnsUpdateStatus)),
      wanDataOverride(wan ?? wanUpModel),
    ];
