import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';

/// Transient (non-editable) status for the internet settings feature page.
///
/// Holds raw codegen data for read-only display, edit mode flag,
/// and loading/mutation states.
class InternetSettingsStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final bool isEditing;
  final String? errorMessage;

  /// Tracks active mutation: null (idle), 'save', 'renewIpv4', 'renewIpv6'.
  final String? activeMutation;

  /// Raw WAN settings for read-only display fields.
  final WanSettings? rawWan;

  /// Raw IPv6 settings for read-only display fields.
  final Ipv6Settings? rawIpv6;

  const InternetSettingsStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.isEditing = false,
    this.errorMessage,
    this.activeMutation,
    this.rawWan,
    this.rawIpv6,
  });

  InternetSettingsStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isEditing,
    String? errorMessage,
    String? activeMutation,
    bool clearActiveMutation = false,
    WanSettings? rawWan,
    Ipv6Settings? rawIpv6,
  }) {
    return InternetSettingsStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: errorMessage,
      activeMutation:
          clearActiveMutation ? null : (activeMutation ?? this.activeMutation),
      rawWan: rawWan ?? this.rawWan,
      rawIpv6: rawIpv6 ?? this.rawIpv6,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        isEditing,
        errorMessage,
        activeMutation,
        rawWan?.toString(),
        rawIpv6?.toString(),
      ];
}
