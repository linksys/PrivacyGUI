import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/mesh_mlo.g.dart';
import 'package:privacy_gui/generated/mesh_steering.g.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

final uspWifiAdvancedServiceProvider = Provider<UspWifiAdvancedService>(
  (ref) => UspWifiAdvancedService(ref.read(uspClientProvider)!),
);

/// Stateless service for the Wi-Fi Settings Advanced tab.
///
/// - IEEE 802.11h (DFS + TPC): `Device.WiFi.Radio.{i}.IEEE80211hEnabled`, via
///   raw USP get/set (no codegen definition exists for this path).
/// - Client and node steering: `Device.X_LINKSYS_Mesh.{Client,Node}SteeringEnabled`
///   (linksys/FWDEV#192), through the `MeshSteering` codegen class.
/// - MLO: `Device.X_LINKSYS_Mesh.{MLOEnabled,MLOStatus}` (linksys/FWDEV#201),
///   through the `MeshMlo` codegen class (#1692).
///
/// A save is one Set for the whole tab ([planSave]).
class UspWifiAdvancedService {
  static const _ieee80211hPath = 'Device.WiFi.Radio.*.IEEE80211hEnabled';

  final UspClient _usp;

  UspWifiAdvancedService(this._usp);

  /// Fetches IEEE 802.11h enabled state per radio.
  ///
  /// Returns a map of radio instance path → enabled flag.
  /// e.g. `{"Device.WiFi.Radio.1." : true, "Device.WiFi.Radio.2." : false}`
  Future<Map<String, bool>> fetchIeee80211h() async {
    try {
      final response = await _usp.get([_ieee80211hPath]);

      final result = <String, bool>{};
      for (final key in response.keys) {
        if (key.startsWith('Device.WiFi.Radio.') &&
            key.endsWith('.IEEE80211hEnabled')) {
          final radioPath =
              key.substring(0, key.length - 'IEEE80211hEnabled'.length);
          final val = response[key];
          result[radioPath] = _asBool(val);
        }
      }
      return result;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Fetches the two network-wide steering switches.
  ///
  /// Both leaves are required by the definition, so a firmware without
  /// `Device.X_LINKSYS_Mesh.` fails this fetch rather than reading as two OFF
  /// switches.
  Future<({bool clientSteering, bool nodeSteering})> fetchSteering() async {
    try {
      final mesh = await MeshSteering.fetch(_usp);
      return (
        clientSteering: mesh.clientSteeringEnabled,
        nodeSteering: mesh.nodeSteeringEnabled,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Fetches the network-wide MLO switch, the tab's editable value.
  ///
  /// Both leaves are required by the definition, so a router that offers MLO
  /// but answers without them fails the fetch rather than reading as "off".
  /// Called only when the router offers MLO (`DeviceCapability.wifiMlo`). What
  /// the router reports for it, `MLOStatus`, is L1's (`mloStatusProvider`).
  Future<bool> fetchMloEnabled() async {
    try {
      return (await MeshMlo.fetch(_usp)).mloEnabled;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The tab's save, as **one** Set: every switch that changed between
  /// [original] and [current] — steering, MLO and IEEE 802.11h together.
  ///
  /// **One Set.** An MLO or DFS change restarts Wi-Fi, so the tab's changes go
  /// out together rather than one Set landing in another's restart. On the
  /// bench (FW 2.0.3.26101472, 2026-10-15) one Set of MLO and DFS reloaded
  /// Wi-Fi once; so did the same leaves in two Sets, so one Set is chosen for
  /// one answer and one read-back, not for fewer reloads.
  ///
  /// **`allowPartial: true`, and it has to be.** The mesh leaves are served by
  /// dm-reflector and the radios by wifidmd, and an atomic Set across two USP
  /// services is refused with 7005. With `allowPartial` one part can be refused
  /// on its own, which [WifiWritePlan.send] throws for when the router says so;
  /// the caller still reads the [WifiWritePlan.proof] back before it reports
  /// success.
  ///
  /// [forceAutoChannelPaths] also get `AutoChannelEnable = true`: a radio
  /// parked on a DFS channel when DFS goes off is not moved by the firmware
  /// (SSH-verified), and auto-channel makes it pick a legal one.
  ///
  /// The proof is every value that changes, except the radios already at the
  /// new DFS value and the forced `AutoChannelEnable`, neither of which tells a
  /// landed write from the old state.
  WifiWritePlan planSave({
    required WifiAdvancedSettings original,
    required WifiAdvancedSettings current,
    List<String> forceAutoChannelPaths = const [],
  }) {
    bool? changed(bool? before, bool? after) => before == after ? null : after;
    final steering = _steeringParams(
      clientSteering: changed(original.clientSteering, current.clientSteering),
      nodeSteering: changed(original.nodeSteering, current.nodeSteering),
    );
    final mlo = _mloParams(
      mloEnabled: changed(original.mloEnabled, current.mloEnabled),
    );
    final dfs = <String, bool>{
      for (final MapEntry(key: path, value: on)
          in current.ieee80211hByRadio.entries)
        if (original.ieee80211hByRadio[path] != on) path: on,
    };
    final radios = dfs.isEmpty
        ? const <String, dynamic>{}
        : _radioParams(
            ieee80211hByRadio: current.ieee80211hByRadio,
            forceAutoChannelPaths: forceAutoChannelPaths,
          );
    final params = {...steering, ...mlo, ...radios};
    return WifiWritePlan(
      params: params,
      proof: {
        ...steering,
        ...mlo,
        for (final MapEntry(key: path, value: on) in dfs.entries)
          '${path}IEEE80211hEnabled': on,
      },
      send: () => _writeOnce(params),
    );
  }

  // One builder per part, merged into [planSave]'s one Set. Each is what the
  // part's codegen `updateParams()` builds once #1654 vendors 0.18.1
  // (`MeshSteering`, `MeshMlo`, `WiFiRadios`); that swap changes the bodies
  // and nothing else.

  Map<String, dynamic> _steeringParams({
    bool? clientSteering,
    bool? nodeSteering,
  }) =>
      {
        if (clientSteering != null)
          'Device.X_LINKSYS_Mesh.ClientSteeringEnabled': clientSteering,
        if (nodeSteering != null)
          'Device.X_LINKSYS_Mesh.NodeSteeringEnabled': nodeSteering,
      };

  Map<String, dynamic> _mloParams({bool? mloEnabled}) => {
        if (mloEnabled != null) 'Device.X_LINKSYS_Mesh.MLOEnabled': mloEnabled,
      };

  Map<String, dynamic> _radioParams({
    required Map<String, bool> ieee80211hByRadio,
    required List<String> forceAutoChannelPaths,
  }) =>
      {
        for (final MapEntry(key: path, value: on) in ieee80211hByRadio.entries)
          '${path}IEEE80211hEnabled': on,
        for (final path in forceAutoChannelPaths)
          '${path}AutoChannelEnable': true,
      };

  /// Sends [params] as one Set and says whether the router answered.
  ///
  /// Returns [WifiWriteOutcome.unanswered] when every error says the request
  /// never got an answer: the Wi-Fi restart can take the reply with it, and
  /// over Remote Assistance #1460's DFS Set took 35.4 s and had applied when
  /// the app reported a failure. A refusal, whole or in part, throws.
  Future<WifiWriteOutcome> _writeOnce(Map<String, dynamic> params) async {
    if (params.isEmpty) return WifiWriteOutcome.confirmed;
    try {
      final result = await _usp.set(params, allowPartial: true);
      final parsed = UspResultParser.parseSetResult(result);
      if (parsed is UspFailure &&
          parsed.errors.every((e) => isUnansweredWifiWrite(e.errorMessage))) {
        logger.i('[USP][WiFi][Advanced]: Set unanswered — Wi-Fi restarted '
            'under the request');
        return WifiWriteOutcome.unanswered;
      }
      switch (parsed) {
        case UspSuccess():
          return WifiWriteOutcome.confirmed;
        case UspPartialSuccess(failures: final f):
          throw UspPartialFailureError(
            summary: 'WiFi Advanced partial failure: ${f.first.errorMessage}',
            successPaths: const [],
            failures: f,
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'WiFi Advanced update failed: ${e.first.errorMessage}',
            failures: e,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Whether the router now carries every value in [proof] — a [planSave]
  /// plan's proof — read in one Get.
  ///
  /// **Fails closed:** an empty [proof] is not applied. A proved leaf missing
  /// from the answer is a failed read, not "not applied": FW 2.0.2 answers with
  /// no rows while Wi-Fi reloads (bench 2026-10-07), so the caller retries.
  Future<bool> isApplied(Map<String, dynamic> proof) async {
    if (proof.isEmpty) return false;
    final Map<String, dynamic> now;
    try {
      now = await _usp.get(proof.keys.toList());
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    final missing = proof.keys.where((k) => !now.containsKey(k));
    if (missing.isNotEmpty) {
      throw NetworkError(
          detail: 'WiFi Advanced read-back had no value for ${missing.first}');
    }
    return proof.entries.every((e) => _asBool(now[e.key]) == e.value);
  }

  /// A TR-181 boolean as the firmware sends it: `true`, `"true"` or `"1"`.
  static bool _asBool(Object? v) => v == true || v == 'true' || v == '1';
}
