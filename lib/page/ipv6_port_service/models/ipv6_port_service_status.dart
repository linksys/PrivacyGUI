import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/has_service_error.dart';

/// Transient status for the IPv6 port service page.
class Ipv6PortServiceStatus extends Equatable implements HasServiceError {
  final bool isLoading;
  final bool isSaving;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  @override
  final ServiceError? error;

  /// Descriptions of the firewall rules the page does not list. FW refuses a
  /// rule whose description one of them already has (ErrorDescriptionInUse,
  /// FWDEV#204), so the rule dialog checks against them. Read with the rules;
  /// not editable.
  final Set<String> hiddenRuleDescriptions;

  const Ipv6PortServiceStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.hiddenRuleDescriptions = const {},
  });

  Ipv6PortServiceStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
    Set<String>? hiddenRuleDescriptions,
  }) {
    return Ipv6PortServiceStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      hiddenRuleDescriptions:
          hiddenRuleDescriptions ?? this.hiddenRuleDescriptions,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isSaving, error, hiddenRuleDescriptions];
}
