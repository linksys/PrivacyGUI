import 'package:equatable/equatable.dart';
import 'package:privacy_gui/usp_page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:privacy_gui/usp_page/instant_privacy/services/instant_privacy_service.dart';

/// State for the Instant Privacy feature page.
class UspInstantPrivacyState extends Equatable {
  /// Whether MAC address filtering is currently active on the router.
  final bool isEnabled;

  /// Devices currently connected to the router (isActive = true).
  final List<InstantPrivacyDeviceUIModel> connectedDevices;

  /// Devices currently on the MAC whitelist.
  final List<InstantPrivacyDeviceUIModel> allowedDevices;

  /// Whether the toggle is locked during a save operation.
  final bool isToggleLocked;

  /// Opaque context holding MAC filter AP data for service operations.
  final MacFilterContext macFilterContext;

  const UspInstantPrivacyState({
    required this.isEnabled,
    required this.connectedDevices,
    required this.allowedDevices,
    required this.macFilterContext,
    this.isToggleLocked = false,
  });

  /// Whether the toggle should be disabled in the UI.
  bool get isToggleDisabled =>
      isToggleLocked || (!isEnabled && connectedDevices.isEmpty);

  UspInstantPrivacyState copyWith({
    bool? isEnabled,
    List<InstantPrivacyDeviceUIModel>? connectedDevices,
    List<InstantPrivacyDeviceUIModel>? allowedDevices,
    bool? isToggleLocked,
    MacFilterContext? macFilterContext,
  }) {
    return UspInstantPrivacyState(
      isEnabled: isEnabled ?? this.isEnabled,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      allowedDevices: allowedDevices ?? this.allowedDevices,
      isToggleLocked: isToggleLocked ?? this.isToggleLocked,
      macFilterContext: macFilterContext ?? this.macFilterContext,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        connectedDevices,
        allowedDevices,
        isToggleLocked,
        macFilterContext,
      ];
}
