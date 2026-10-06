import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';

/// Transient (non-editable) status for a MAC-filter feature page.
///
/// Carries the read-only connected-device list the picker / pre-populate use,
/// plus the loading/saving/error flags. Not dirty-tracked — only
/// [MacFilterSettings] is. [isLoading] is checked before [error] in the view, so
/// a status that carries an error while still loading would render an endless
/// loader; only the `.initial()` state opts into `isLoading: true`.
class MacFilterStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final ServiceError? error;

  /// Devices currently online — the add-device picker's options, and Instant
  /// Privacy's "pre-populate all online devices" source. Read-only.
  final List<MacFilterDeviceUIModel> connectedDevices;

  const MacFilterStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.connectedDevices = const [],
  });

  MacFilterStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
    List<MacFilterDeviceUIModel>? connectedDevices,
  }) {
    return MacFilterStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error, connectedDevices];
}
