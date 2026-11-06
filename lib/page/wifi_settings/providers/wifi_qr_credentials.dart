import 'package:collection/collection.dart';
import 'package:privacy_gui/page/components/widgets/wifi_qr/wifi_qr_band.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/util/wifi_credential.dart';

/// The security type a WiFi QR code for a [type] network is written with: an
/// open network joins without a password, every personal WPA mode joins as WPA.
SecurityType wifiQRSecurityType(WifiSecurityType type) =>
    type.isOpenVariant ? SecurityType.none : SecurityType.wpa;

/// What the QR code for a network broadcasting [ssid] with [password] and
/// [securityType] encodes. A network whose security mode is not known gets a
/// WPA code, as the router ships.
WiFiCredential wifiQRCredential({
  required String ssid,
  required String password,
  WifiSecurityType? securityType,
  bool isBroadcast = true,
}) =>
    WiFiCredential(
      ssid: ssid,
      password: password,
      type: securityType == null
          ? SecurityType.wpa
          : wifiQRSecurityType(securityType),
      isHidden: !isBroadcast,
    );

/// The QR codes to hand the user once [saved] is what the router broadcasts.
///
/// Bands whose codes come out identical are one network to the user, so they
/// collapse into a single code rather than the same code repeated per band.
List<WiFiQRBand> wifiQRBandsFor(WiFiState saved) {
  final bands = saved.mainWiFi
      .where((e) => e.isEnabled)
      .map((e) => WiFiQRBand(
            label: e.radioID.bandName,
            credential: wifiQRCredential(
              ssid: e.ssid,
              password: e.password,
              securityType: e.securityType,
              isBroadcast: e.isBroadcast,
            ),
          ))
      .toList();
  if (bands.isEmpty) return bands;

  final first = bands.first.credential.generate();
  final isUnified = bands.every((b) => b.credential.generate() == first);
  return isUnified ? [bands.first] : bands;
}

/// Whether saving [state] would change a band's WiFi name, password or
/// security mode from what [preserved] broadcasts today - the changes the
/// printed-QR warning covers.
///
/// A security mode change counts even where the code itself would not change
/// (WPA2 to WPA3 is still a WPA code), since a phone may not join a WPA3-only
/// network from it. Hiding the name is left out on purpose: the warning
/// covers the name, password and security mode only.
bool wifiQRCredentialsChanged({
  required WiFiState state,
  WiFiState? preserved,
}) {
  if (preserved == null) return false;

  if (state.isSimpleMode) {
    // Saving in simple mode pushes one name, password and security mode onto
    // every band, so compare what each band would be saved with against what
    // it broadcasts today. This also covers switching over from advanced mode
    // with per-band settings.
    final simple = state.simpleModeWifi;
    return preserved.mainWiFi.any((radio) =>
        _qrWarningFields(radio) !=
        (
          simple.ssid,
          simple.password,
          radio.radioID.simpleModeSecurityType(simple.securityType),
        ));
  }
  return state.mainWiFi.any((radio) {
    final before =
        preserved.mainWiFi.firstWhereOrNull((e) => e.radioID == radio.radioID);
    return before != null &&
        _qrWarningFields(before) != _qrWarningFields(radio);
  });
}

/// The settings of [radio] whose change raises the printed-QR warning.
(String, String, WifiSecurityType) _qrWarningFields(WiFiItem radio) =>
    (radio.ssid, radio.password, radio.securityType);
