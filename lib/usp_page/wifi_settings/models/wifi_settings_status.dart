import 'package:equatable/equatable.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_quick_setup_network.dart';

/// Read-only system state for the WiFi Settings page.
///
/// Holds data that the user cannot directly modify. Separated from
/// [WifiSettingsSettings] to prevent false-positive dirty checks.
class WifiSettingsStatus extends Equatable {
  /// True while the initial fetch is in progress.
  final bool isLoading;

  /// True while a save operation is in progress.
  final bool isSaving;

  /// Non-null when the fetch failed.
  final String? errorMessage;

  /// Aggregated Quick Setup data for main (non-guest) networks.
  /// Contains [WifiQuickSetupNetwork.ssidInstancePaths] and
  /// [WifiQuickSetupNetwork.apInstancePaths] needed for fan-out saves.
  final WifiQuickSetupNetwork? quickSetupMainAggregate;

  /// Aggregated Quick Setup data for guest networks.
  final WifiQuickSetupNetwork? quickSetupGuestAggregate;

  const WifiSettingsStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.quickSetupMainAggregate,
    this.quickSetupGuestAggregate,
  });

  const WifiSettingsStatus.loading()
      : isLoading = true,
        isSaving = false,
        errorMessage = null,
        quickSetupMainAggregate = null,
        quickSetupGuestAggregate = null;

  WifiSettingsStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    WifiQuickSetupNetwork? quickSetupMainAggregate,
    WifiQuickSetupNetwork? quickSetupGuestAggregate,
  }) {
    return WifiSettingsStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      quickSetupMainAggregate:
          quickSetupMainAggregate ?? this.quickSetupMainAggregate,
      quickSetupGuestAggregate:
          quickSetupGuestAggregate ?? this.quickSetupGuestAggregate,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        errorMessage,
        quickSetupMainAggregate,
        quickSetupGuestAggregate,
      ];
}
