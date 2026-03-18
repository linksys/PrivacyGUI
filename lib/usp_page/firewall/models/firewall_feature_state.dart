import 'package:privacy_gui/usp_page/_framework/feature_state.dart';
import 'package:privacy_gui/usp_page/_framework/preservable.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_status.dart';

/// Composed FeatureState for the firewall page.
class FirewallFeatureState
    extends FeatureState<FirewallSettings, FirewallStatus> {
  const FirewallFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory FirewallFeatureState.initial() {
    return FirewallFeatureState(
      settings: Preservable(
        original: FirewallSettings.empty(),
        current: FirewallSettings.empty(),
      ),
      status: const FirewallStatus(isLoading: true),
    );
  }

  @override
  FirewallFeatureState copyWith({
    Preservable<FirewallSettings>? settings,
    FirewallStatus? status,
  }) {
    return FirewallFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
