import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/upnp_device.g.dart';

final uspUpnpDataServiceProvider = Provider<UspUpnpDataService>((ref) {
  final usp = ref.read(uspClientProvider);
  if (usp == null) {
    throw const ServiceNotInitializedError(detail: 'USP service not available');
  }
  return UspUpnpDataService(usp);
});

/// Stateless L1 Service for whether UPnP is on (`Device.UPnP.Device.Enable`).
///
/// Owns the codegen call and error mapping for `upnpDataProvider`, which the
/// dashboard's Firewall card reads (#1130). The Administration page reads and
/// writes the same leaf through its own service.
class UspUpnpDataService {
  final UspClient _usp;

  UspUpnpDataService(this._usp);

  /// Whether UPnP is on. A failed read throws rather than reading as off.
  Future<bool> fetchEnabled() async {
    try {
      return (await UpnpDevice.fetch(_usp)).enable;
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }
}
