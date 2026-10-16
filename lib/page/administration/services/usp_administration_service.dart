import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
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
///
/// Management over Wi-Fi: the `RULE_MGMT_WIFI_ACCESS` firewall rule
/// (linksys/FWDEV#216), 1.x's `canManageWirelessly`.
class UspAdministrationService {
  final UspClient _usp;

  UspAdministrationService(this._usp);

  /// Reads the page's settings from the device.
  ///
  /// Every leaf is required by its definition, so a firmware without
  /// `Device.UPnP.` or the SIP leaf fails this fetch rather than reading as off.
  /// The management rule is the one thing that may be absent: a firmware
  /// without it reads [AdministrationSettings.mgmtWifiEnabled] as null.
  Future<AdministrationSettings> fetch() async {
    try {
      final results = await Future.wait<Object?>([
        UpnpDevice.fetch(_usp),
        SipAlg.fetch(_usp),
        _mgmtWifiRule(),
      ]);
      return AdministrationSettings(
        upnpEnabled: (results[0] as UpnpDevice).enable,
        sipAlgEnabled: (results[1] as SipAlg).enable,
        mgmtWifiEnabled: (results[2] as FirewallChainRule?)?.enable,
      );
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The `RULE_MGMT_WIFI_ACCESS` rule, or null when the firmware has none.
  ///
  /// Found by `Description`, never by instance number — the way the Firewall
  /// page finds linksys/FWDEV#204's rules. An empty table is a failed read, not
  /// a firmware without the rule: the WASM client resolves a failed GET with an
  /// empty data map, and the router's firewall always carries rules of its own.
  /// So only a table that read back and lacks the rule hides the switch.
  Future<FirewallChainRule?> _mgmtWifiRule() async {
    final rules = await FirewallChainRules.fetch(_usp);
    if (rules.items.isEmpty) {
      throw const ResourceNotFoundError(
        detail: 'Device.Firewall.Chain.1 read back no rules',
      );
    }
    return rules.items
        .where((r) => r.description == _mgmtWifiRuleName)
        .firstOrNull;
  }

  static const _mgmtWifiRuleName = 'RULE_MGMT_WIFI_ACCESS';

  /// Writes `Device.UPnP.Device.Enable` — and only that leaf: `UPnPIGD` is
  /// read-only and follows it.
  Future<void> setUpnpEnabled(bool enabled) =>
      _write('UPnP', () => UpnpDevice.update(_usp, enable: enabled));

  /// Writes `Device.Firewall.ConnectionTracking.SIP.Enable`. The router takes
  /// about 9 s to answer (measured on 2.0.3.26101472): the setter rebuilds the
  /// `lan` and `guest` zones' conntrack helper lists.
  Future<void> setSipAlgEnabled(bool enabled) =>
      _write('SIP ALG', () => SipAlg.update(_usp, enable: enabled));

  /// Writes the `Enable` of the `RULE_MGMT_WIFI_ACCESS` rule. Off stops every
  /// node's Wi-Fi clients reaching this GUI on 80/443; wired clients still can.
  /// The firewall reloads and the agents follow within a second — no reboot,
  /// no Wi-Fi restart (linksys/FWDEV#216).
  ///
  /// The rule is looked up again rather than taken from the page's read, so
  /// the write goes to wherever the rule is now.
  Future<void> setMgmtWifiEnabled(bool enabled) async {
    final FirewallChainRule? found;
    try {
      found = await _mgmtWifiRule();
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
    final rule = found;
    if (rule == null) {
      throw const ResourceNotFoundError(
        detail: 'No $_mgmtWifiRuleName rule on the router',
      );
    }
    await _write(
      'Management over Wi-Fi',
      () => FirewallChainRules.update(_usp, [
        FirewallChainRuleUpdate(
            instancePath: rule.instancePath, enable: enabled),
      ]),
    );
  }

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
