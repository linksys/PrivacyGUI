import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/upnp_device.g.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';

final uspAdministrationServiceProvider = Provider<UspAdministrationService>(
  (ref) => UspAdministrationService(ref.read(uspClientProvider)!),
);

/// Stateless service for the Advanced Settings → Administration page.
///
/// UPnP: `Device.UPnP.Device.Enable` (linksys/FWDEV#190). One Set of `Enable`
/// commits and reloads the UPnP service — no reboot, no Wi-Fi restart. Off stops
/// the service and removes its port mappings; on restores them.
class UspAdministrationService {
  final UspClient _usp;

  UspAdministrationService(this._usp);

  /// Reads the page's settings from the device.
  ///
  /// Both UPnP leaves are required by the definition, so a firmware without
  /// `Device.UPnP.` fails this fetch rather than reading as UPnP off.
  Future<AdministrationSettings> fetch() async {
    try {
      final upnp = await UpnpDevice.fetch(_usp);
      return AdministrationSettings(upnpEnabled: upnp.enable);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Writes `Device.UPnP.Device.Enable` — and only that leaf: `UPnPIGD` is
  /// read-only and follows it.
  Future<void> setUpnpEnabled(bool enabled) async {
    try {
      final result = await UpnpDevice.update(_usp, enable: enabled);
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(failures: final f):
          throw UspPartialFailureError(
            summary: 'UPnP update partial failure: ${f.first.errorMessage}',
            successPaths: const [],
            failures: f,
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'UPnP update failed: ${e.first.errorMessage}',
            failures: e,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }
}
