import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// `Device.X_LINKSYS_Mesh.MLOStatus` (linksys/FWDEV#201): whether MLO runs.
enum MloStatus {
  /// The switch is off.
  disabled,

  /// The 2.4 and 5 GHz main networks run as one AP MLD.
  active,

  /// The switch is on, but the bands' SSID, password or security do not allow
  /// MLO. WPA2 and Open never do.
  inactive,

  /// A value outside the contract's three.
  unknown;

  static MloStatus fromTr181(String value) => switch (value) {
        'Disabled' => disabled,
        'Active' => active,
        'Inactive' => inactive,
        _ => unknown,
      };
}

/// Transient (non-editable) status for the WiFi Advanced feature page.
class WifiAdvancedStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  final ServiceError? error;

  /// What the router reports for MLO, read with the switch (#1692). Null when
  /// the router does not offer MLO.
  final MloStatus? mloStatus;

  const WifiAdvancedStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.mloStatus,
  });

  const WifiAdvancedStatus.loading()
      : isLoading = true,
        isSaving = false,
        error = null,
        mloStatus = null;

  WifiAdvancedStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
    MloStatus? mloStatus,
  }) {
    return WifiAdvancedStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      mloStatus: mloStatus ?? this.mloStatus,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error, mloStatus];
}
