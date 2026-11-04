import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/mac_filter_network.g.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_data.dart';

final uspMacFilterDataServiceProvider = Provider<UspMacFilterDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspMacFilterDataService(usp);
  },
);

/// Stateless L1 Service for the applied MAC filter: the mode and the list, and
/// nothing the pages add to it (the device picker is `UspMacFilterService`'s).
///
/// Owns the codegen read for `macFilterDataProvider`.
class UspMacFilterDataService {
  final UspClient _usp;

  UspMacFilterDataService(this._usp);

  /// Reads the current mode and list.
  Future<MacFilterData> fetch() async {
    try {
      final raw = await MacFilterNetwork.fetch(_usp);
      return MacFilterData.fromWire(raw.macFilterMode, raw.macFilterList);
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }
}
