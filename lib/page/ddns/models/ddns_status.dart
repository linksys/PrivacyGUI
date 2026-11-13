import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/has_service_error.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';

/// Transient (non-editable) status of the DDNS page.
///
/// The update status the router reports is not here: it is read-only and
/// pushed, so the page reads it from `ddnsStatusDataProvider` (constitution
/// Article IV §4.2).
class DdnsStatus extends Equatable implements HasServiceError {
  final bool isLoading;
  final bool isSaving;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  @override
  final ServiceError? error;

  /// The fields shown as failing their check.
  ///
  /// A field joins or leaves this set as it loses focus, one field at a time,
  /// not on every keystroke, so a field does not turn red while it is being
  /// typed into, nor before the user reaches it. Whether Save is allowed is
  /// decided from the settings themselves (`invalidDdnsFields`), so it does
  /// not wait for a field to lose focus.
  final Set<DdnsField> fieldErrors;

  const DdnsStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.error,
    this.fieldErrors = const {},
  });

  DdnsStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
    Set<DdnsField>? fieldErrors,
  }) {
    return DdnsStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error, fieldErrors];
}
