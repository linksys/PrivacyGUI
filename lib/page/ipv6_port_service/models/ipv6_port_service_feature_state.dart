import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_rule_list.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';

/// Composed FeatureState for the IPv6 port service page.
class Ipv6PortServiceFeatureState
    extends FeatureState<Ipv6PortServiceRuleList, Ipv6PortServiceStatus> {
  const Ipv6PortServiceFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory Ipv6PortServiceFeatureState.initial() {
    return Ipv6PortServiceFeatureState(
      settings: Preservable(
        original: const Ipv6PortServiceRuleList(),
        current: const Ipv6PortServiceRuleList(),
      ),
      status: const Ipv6PortServiceStatus(isLoading: true),
    );
  }

  @override
  Ipv6PortServiceFeatureState copyWith({
    Preservable<Ipv6PortServiceRuleList>? settings,
    Ipv6PortServiceStatus? status,
  }) {
    return Ipv6PortServiceFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
