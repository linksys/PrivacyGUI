import 'package:privacy_gui/framework/empty_status.dart';
import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';

import 'pnp_wifi_settings.dart';

/// The PnP Wi-Fi step's draft: the main network as read and as edited.
class PnpMainWifiDraft extends FeatureState<PnpMainWifiSettings, EmptyStatus> {
  const PnpMainWifiDraft(
      {required super.settings, super.status = const EmptyStatus()});

  /// A draft that begins at [read] — what the wizard read from the router.
  factory PnpMainWifiDraft.from(PnpMainWifiSettings read) =>
      PnpMainWifiDraft(settings: Preservable(original: read, current: read));

  @override
  PnpMainWifiDraft copyWith({
    Preservable<PnpMainWifiSettings>? settings,
    EmptyStatus? status,
  }) =>
      PnpMainWifiDraft(
        settings: settings ?? this.settings,
        status: status ?? this.status,
      );

  /// Empty on purpose: it would carry the passphrase.
  @override
  Map<String, dynamic> toMap() => {};
}

/// The PnP guest step's draft: the guest network as read and as edited.
class PnpGuestWifiDraft
    extends FeatureState<PnpGuestWifiSettings, EmptyStatus> {
  const PnpGuestWifiDraft(
      {required super.settings, super.status = const EmptyStatus()});

  /// A draft that begins at [read] — what the wizard read from the router.
  factory PnpGuestWifiDraft.from(PnpGuestWifiSettings read) =>
      PnpGuestWifiDraft(settings: Preservable(original: read, current: read));

  @override
  PnpGuestWifiDraft copyWith({
    Preservable<PnpGuestWifiSettings>? settings,
    EmptyStatus? status,
  }) =>
      PnpGuestWifiDraft(
        settings: settings ?? this.settings,
        status: status ?? this.status,
      );

  /// Empty on purpose: it would carry the passphrase.
  @override
  Map<String, dynamic> toMap() => {};
}
