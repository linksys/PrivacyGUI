import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspPortTriggeringDataServiceProvider =
    Provider<UspPortTriggeringDataService>(
  (ref) {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }
    return UspPortTriggeringDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching port triggering rules.
///
/// Owns the codegen call, error mapping, and UI model transform for
/// [portTriggeringDataProvider].
class UspPortTriggeringDataService {
  final UspService _usp;

  UspPortTriggeringDataService(this._usp);

  /// Fetches port triggering rules and transforms to UI models.
  Future<List<PortTriggeringRuleUIModel>> fetch() async {
    try {
      final raw = await PortTriggering.fetch(_usp);
      return buildUIModels(raw);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Transforms raw codegen [PortTriggering] to UI models.
  ///
  /// Exposed for reuse by [UspPortForwardingService] (L2) to avoid
  /// duplicating the transform logic.
  List<PortTriggeringRuleUIModel> buildUIModels(PortTriggering data) {
    return data.items
        .map((t) => PortTriggeringRuleUIModel(
              instancePath: t.instancePath,
              enabled: t.enabled,
              description: t.description,
              triggerPort: t.triggerPort,
              triggerPortEndRange: t.triggerPortEndRange,
              triggerProtocol: t.triggerProtocol,
              forwardRules: t.rules
                  .map((r) => PortTriggerForwardRuleUIModel(
                        instancePath: r.instancePath,
                        forwardPort: r.forwardPort,
                        forwardPortEndRange: r.forwardPortEndRange,
                        forwardProtocol: r.forwardProtocol,
                      ))
                  .toList(),
            ))
        .toList();
  }
}
