import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';

/// Transient (non-editable) status for the internet settings feature page.
///
/// Holds read-only display info, edit mode flag, and loading/mutation states.
class InternetSettingsStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final bool isEditing;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  final ServiceError? error;

  /// Tracks active mutation: null (idle), 'save', 'renewIpv4', 'renewIpv6'.
  final String? activeMutation;

  /// Read-only fields from WAN/IPv6 for display purposes.
  final InternetSettingsReadOnlyInfo readOnlyInfo;

  /// PPP instance path from last fetch (e.g. 'Device.PPP.Interface.1.').
  /// Null if no PPP instance exists on the device.
  final String? pppInstancePath;

  /// VLAN instance path from last fetch (e.g. 'Device.Ethernet.VLANTermination.1.').
  /// Null if no VLAN instance exists on the device.
  final String? vlanInstancePath;

  const InternetSettingsStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.isEditing = false,
    this.error,
    this.activeMutation,
    this.readOnlyInfo = const InternetSettingsReadOnlyInfo(),
    this.pppInstancePath,
    this.vlanInstancePath,
  });

  InternetSettingsStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isEditing,
    ServiceError? error,
    bool clearError = false,
    String? activeMutation,
    bool clearActiveMutation = false,
    InternetSettingsReadOnlyInfo? readOnlyInfo,
    String? pppInstancePath,
    bool clearPppInstancePath = false,
    String? vlanInstancePath,
    bool clearVlanInstancePath = false,
  }) {
    return InternetSettingsStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isEditing: isEditing ?? this.isEditing,
      error: clearError ? null : (error ?? this.error),
      activeMutation:
          clearActiveMutation ? null : (activeMutation ?? this.activeMutation),
      readOnlyInfo: readOnlyInfo ?? this.readOnlyInfo,
      pppInstancePath: clearPppInstancePath
          ? null
          : (pppInstancePath ?? this.pppInstancePath),
      vlanInstancePath: clearVlanInstancePath
          ? null
          : (vlanInstancePath ?? this.vlanInstancePath),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        isEditing,
        error,
        activeMutation,
        readOnlyInfo,
        pppInstancePath,
        vlanInstancePath,
      ];
}
