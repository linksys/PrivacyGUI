import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/sip_alg.g.dart';
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
///
/// SIP ALG: `Device.Firewall.ConnectionTracking.SIP.Enable` (linksys/FWDEV#217),
/// 1.x's one ALG switch. Not `Device.NAT.ALG.*`, which FLWRT does not serve.
class UspAdministrationService {
  final UspClient _usp;

  UspAdministrationService(this._usp);

  /// Reads the page's settings from the device.
  ///
  /// Every leaf is required by its definition, so a firmware without
  /// `Device.UPnP.` or the SIP leaf fails this fetch rather than reading as off.
  Future<AdministrationSettings> fetch() async {
    try {
      final results = await Future.wait<Object>([
        UpnpDevice.fetch(_usp),
        SipAlg.fetch(_usp),
      ]);
      return AdministrationSettings(
        upnpEnabled: (results[0] as UpnpDevice).enable,
        sipAlgEnabled: (results[1] as SipAlg).enable,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Writes `Device.UPnP.Device.Enable` — and only that leaf: `UPnPIGD` is
  /// read-only and follows it.
  Future<void> setUpnpEnabled(bool enabled) =>
      _write('UPnP', () => UpnpDevice.update(_usp, enable: enabled));

  /// Writes `Device.Firewall.ConnectionTracking.SIP.Enable`. The router takes
  /// about 9 s to answer (measured on 2.0.3.26101472): the setter rebuilds the
  /// `lan` and `guest` zones' conntrack helper lists.
  Future<void> setSipAlgEnabled(bool enabled) =>
      _write('SIP ALG', () => SipAlg.update(_usp, enable: enabled));

  /// Sends one Set and turns anything but a full success into a [ServiceError].
  Future<void> _write(
    String what,
    Future<Map<String, dynamic>> Function() set,
  ) async {
    try {
      final parsed = UspResultParser.parseSetResult(await set());
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(failures: final f):
          throw UspPartialFailureError(
            summary: '$what update partial failure: ${f.first.errorMessage}',
            successPaths: const [],
            failures: f,
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: '$what update failed: ${e.first.errorMessage}',
            failures: e,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }
}
