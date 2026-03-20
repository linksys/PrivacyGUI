import 'package:privacy_gui/page/_framework/feature_state.dart';
import 'package:privacy_gui/page/_framework/preservable.dart';
import 'package:privacy_gui/page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/page/local_network/models/local_network_status.dart';

/// Composed FeatureState for the local network page.
class LocalNetworkFeatureState
    extends FeatureState<LocalNetworkSettings, LocalNetworkStatus> {
  const LocalNetworkFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory LocalNetworkFeatureState.initial() {
    return LocalNetworkFeatureState(
      settings: Preservable(
        original: LocalNetworkSettings.empty(),
        current: LocalNetworkSettings.empty(),
      ),
      status: const LocalNetworkStatus(isLoading: true),
    );
  }

  /// True when router IP or subnet mask changed — save needs confirmation.
  bool get hasNetworkChange =>
      settings.original.model.ipAddress != settings.current.model.ipAddress ||
      settings.original.model.subnetMask != settings.current.model.subnetMask;

  @override
  LocalNetworkFeatureState copyWith({
    Preservable<LocalNetworkSettings>? settings,
    LocalNetworkStatus? status,
  }) {
    return LocalNetworkFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
