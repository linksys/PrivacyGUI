import 'package:privacy_gui/usp_page/_framework/feature_state.dart';
import 'package:privacy_gui/usp_page/_framework/preservable.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_forwarding_page_settings.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_forwarding_page_status.dart';

/// Composed FeatureState for the port forwarding detail page.
class PortForwardingPageFeatureState extends FeatureState<
    PortForwardingPageSettings, PortForwardingPageStatus> {
  const PortForwardingPageFeatureState({
    required super.settings,
    required super.status,
  });

  factory PortForwardingPageFeatureState.initial() {
    return PortForwardingPageFeatureState(
      settings: Preservable(
        original: const PortForwardingPageSettings(),
        current: const PortForwardingPageSettings(),
      ),
      status: const PortForwardingPageStatus(isLoading: true),
    );
  }

  @override
  PortForwardingPageFeatureState copyWith({
    Preservable<PortForwardingPageSettings>? settings,
    PortForwardingPageStatus? status,
  }) {
    return PortForwardingPageFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
