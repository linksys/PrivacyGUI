import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/mesh_mlo.g.dart';
import 'package:privacy_gui/page/wifi_settings/models/mlo_status.dart';

final uspMeshMloDataServiceProvider = Provider<UspMeshMloDataService>((ref) {
  final usp = ref.read(uspClientProvider);
  if (usp == null) {
    throw const ServiceNotInitializedError(detail: 'USP service not available');
  }
  return UspMeshMloDataService(usp);
});

/// Stateless L1 Service for `mloStatusProvider`: what the router reports for
/// MLO, `Device.X_LINKSYS_Mesh.MLOStatus` (linksys/FWDEV#201, #1692).
///
/// Owns the `MeshMlo` read and its error mapping for the L1 side. The switch
/// itself, `MLOEnabled`, is the WiFi Advanced tab's editable value and is read
/// by `UspWifiAdvancedService`.
class UspMeshMloDataService {
  final UspClient _usp;

  UspMeshMloDataService(this._usp);

  /// Reads the status. A value outside the contract's three is
  /// [MloStatus.unknown]; a failed read throws a [ServiceError].
  Future<MloStatus> fetchStatus() async {
    try {
      final mlo = await MeshMlo.fetch(_usp);
      return MloStatus.fromTr181(mlo.mloStatus);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }
}
