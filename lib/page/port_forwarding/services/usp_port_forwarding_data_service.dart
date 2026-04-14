import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/port_forwarding_transforms.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspPortForwardingDataServiceProvider =
    Provider<UspPortForwardingDataService>(
  (ref) {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }
    return UspPortForwardingDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching port forwarding rules.
///
/// Owns the codegen call, error mapping, and UI model transform for
/// [portForwardingDataProvider].
class UspPortForwardingDataService {
  final UspService _usp;

  UspPortForwardingDataService(this._usp);

  /// Fetches port forwarding rules and transforms to UI models.
  Future<List<PortForwardingRuleUIModel>> fetch() async {
    try {
      final raw = await PortForwarding.fetch(_usp);
      return transformForwardingRules(raw);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }
}
