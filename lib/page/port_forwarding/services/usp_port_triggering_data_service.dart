import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/port_forwarding_transforms.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspPortTriggeringDataServiceProvider =
    Provider<UspPortTriggeringDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
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
  final UspClient _usp;

  UspPortTriggeringDataService(this._usp);

  /// Fetches port triggering rules and transforms to UI models.
  Future<List<PortTriggeringRuleUIModel>> fetch() async {
    try {
      final raw = await PortTriggering.fetch(_usp);
      return transformTriggeringRules(raw);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }
}
