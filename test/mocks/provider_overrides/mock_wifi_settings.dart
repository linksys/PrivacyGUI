import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/models/mlo_status.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_feature_state.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/mlo_status_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

class FixedWifiSettingsNotifier extends UspWifiSettingsNotifier {
  final UspWifiSettingsState _fixedState;

  FixedWifiSettingsNotifier(this._fixedState);

  @override
  UspWifiSettingsState build() => _fixedState;

  @override
  Future<(WifiSettingsSettings?, WifiSettingsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}
}

class FixedWifiAdvancedNotifier extends UspWifiAdvancedNotifier {
  final WifiAdvancedFeatureState _fixedState;

  FixedWifiAdvancedNotifier(this._fixedState);

  @override
  WifiAdvancedFeatureState build() => _fixedState;

  @override
  Future<(WifiAdvancedSettings?, WifiAdvancedStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void setDfsEnabled(bool enabled) {}
}

/// [mloStatus] is the MLO card's badge, read from L1 (`mloStatusProvider`);
/// it shows only when [advancedState] carries an MLO value.
List<Override> wifiSettingsOverrides({
  required UspWifiSettingsState wifiState,
  required WifiAdvancedFeatureState advancedState,
  MloStatus? mloStatus = MloStatus.inactive,
}) =>
    [
      uspWifiSettingsProvider
          .overrideWith(() => FixedWifiSettingsNotifier(wifiState)),
      uspWifiAdvancedProvider
          .overrideWith(() => FixedWifiAdvancedNotifier(advancedState)),
      mloStatusProvider.overrideWith((ref) async => mloStatus),
    ];

class MockUspWifiAdvancedService extends Mock
    implements UspWifiAdvancedService {}

/// The plan builder never touches the client; this only satisfies its type.
class _NoUsp extends Mock implements UspClient {}

/// What the real [UspWifiAdvancedService.fetchIeee80211h] makes of a router
/// whose Get answers [answer] — its radios' `IEEE80211hEnabled` and
/// `OperatingFrequencyBand` — for a mocked service to return, so the radios
/// under test are the ones production keeps: the 5 GHz radios (#1973).
Future<Map<String, bool>> realIeee80211hRead(Map<String, dynamic> answer) =>
    UspWifiAdvancedService(_AnsweringUsp(answer)).fetchIeee80211h();

/// A client whose every Get answers [_answer].
class _AnsweringUsp extends Mock implements UspClient {
  _AnsweringUsp(this._answer);

  final Map<String, dynamic> _answer;

  @override
  Future<Map<String, dynamic>> get(
    List<String> paths, {
    RequestPriority? priority,
    bool fresh = false,
  }) async =>
      _answer;
}

/// Stubs [svc]'s `planSave` with the real [UspWifiAdvancedService.planSave],
/// so the Set's params and proof under test are production's, and sends the
/// plan through [send] instead of a router.
///
/// Register `WifiAdvancedSettings` and `Map<String, dynamic>` fallbacks
/// before calling it.
void stubRealPlanSave(
  MockUspWifiAdvancedService svc, {
  required Future<WifiWriteOutcome> Function(Map<String, dynamic> params) send,
}) {
  when(() => svc.planSave(
        original: any(named: 'original'),
        current: any(named: 'current'),
        forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
      )).thenAnswer((inv) {
    final real = UspWifiAdvancedService(_NoUsp()).planSave(
      original: inv.namedArguments[#original] as WifiAdvancedSettings,
      current: inv.namedArguments[#current] as WifiAdvancedSettings,
      forceAutoChannelPaths:
          inv.namedArguments[#forceAutoChannelPaths] as List<String>,
    );
    return WifiWritePlan(
      params: real.params,
      proof: real.proof,
      send: () => send(real.params),
    );
  });
}
