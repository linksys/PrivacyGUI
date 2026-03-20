import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';

/// Transient (non-editable) status for the internet settings feature page.
///
/// Holds read-only display info, edit mode flag, and loading/mutation states.
class InternetSettingsStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final bool isEditing;
  final String? errorMessage;

  /// Tracks active mutation: null (idle), 'save', 'renewIpv4', 'renewIpv6'.
  final String? activeMutation;

  /// Read-only fields from WAN/IPv6 for display purposes.
  final InternetSettingsReadOnlyInfo readOnlyInfo;

  const InternetSettingsStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.isEditing = false,
    this.errorMessage,
    this.activeMutation,
    this.readOnlyInfo = const InternetSettingsReadOnlyInfo(),
  });

  InternetSettingsStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isEditing,
    String? errorMessage,
    String? activeMutation,
    bool clearActiveMutation = false,
    InternetSettingsReadOnlyInfo? readOnlyInfo,
  }) {
    return InternetSettingsStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: errorMessage,
      activeMutation:
          clearActiveMutation ? null : (activeMutation ?? this.activeMutation),
      readOnlyInfo: readOnlyInfo ?? this.readOnlyInfo,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        isEditing,
        errorMessage,
        activeMutation,
        readOnlyInfo,
      ];
}
