import 'package:privacy_gui/framework/empty_status.dart';
import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';

import 'pnp_wifi_settings.dart';

/// The PnP Wi-Fi step's draft: the main network as read and as edited.
class PnpMainWifiDraftState
    extends FeatureState<PnpMainWifiSettings, EmptyStatus> {
  const PnpMainWifiDraftState(
      {required super.settings, super.status = const EmptyStatus()});

  /// A draft that begins at [read] — what the wizard read from the router.
  factory PnpMainWifiDraftState.from(PnpMainWifiSettings read) =>
      PnpMainWifiDraftState(
          settings: Preservable(original: read, current: read));

  @override
  PnpMainWifiDraftState copyWith({
    Preservable<PnpMainWifiSettings>? settings,
    EmptyStatus? status,
  }) =>
      PnpMainWifiDraftState(
        settings: settings ?? this.settings,
        status: status ?? this.status,
      );

  /// Empty on purpose: it would carry the passphrase.
  @override
  Map<String, dynamic> toMap() => {};
}

/// The PnP guest step's draft: the guest network as read and as edited.
class PnpGuestWifiDraftState
    extends FeatureState<PnpGuestWifiSettings, EmptyStatus> {
  const PnpGuestWifiDraftState(
      {required super.settings, super.status = const EmptyStatus()});

  /// A draft that begins at [read] — what the wizard read from the router.
  factory PnpGuestWifiDraftState.from(PnpGuestWifiSettings read) =>
      PnpGuestWifiDraftState(
          settings: Preservable(original: read, current: read));

  @override
  PnpGuestWifiDraftState copyWith({
    Preservable<PnpGuestWifiSettings>? settings,
    EmptyStatus? status,
  }) =>
      PnpGuestWifiDraftState(
        settings: settings ?? this.settings,
        status: status ?? this.status,
      );

  /// Empty on purpose: it would carry the passphrase.
  @override
  Map<String, dynamic> toMap() => {};
}
