import 'package:collection/collection.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/util/wifi_credential.dart';

/// One network the user can be handed a QR code for.
class WiFiQRBand {
  final String label;

  /// What the QR code, and the printed or downloaded copy of it, encodes.
  final WiFiCredential credential;

  const WiFiQRBand({required this.label, required this.credential});

  /// An open network has no password to show or copy.
  bool get hasPassword => credential.type != SecurityType.none;
}

/// The security type a WiFi QR code for a [type] network is written with: an
/// open network joins without a password, every personal WPA mode joins as WPA.
SecurityType wifiQRSecurityType(WifiSecurityType type) =>
    type.isOpenVariant ? SecurityType.none : SecurityType.wpa;

/// The QR codes to hand the user once [saved] is what the router broadcasts.
///
/// Bands whose codes come out identical are one network to the user, so they
/// collapse into a single code rather than the same code repeated per band.
List<WiFiQRBand> wifiQRBandsFor(WiFiState saved) {
  final bands = saved.mainWiFi
      .where((e) => e.isEnabled)
      .map((e) => WiFiQRBand(
            label: e.radioID.bandName,
            credential: WiFiCredential(
              ssid: e.ssid,
              password: e.password,
              type: wifiQRSecurityType(e.securityType),
              isHidden: !e.isBroadcast,
            ),
          ))
      .toList();
  if (bands.isEmpty) return bands;

  final first = bands.first.credential.generate();
  final isUnified = bands.every((b) => b.credential.generate() == first);
  return isUnified ? [bands.first] : bands;
}

/// Whether saving [state] would change what the printed QR codes encode for a
/// band [preserved] broadcasts today.
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
        _printedQRFields(radio) !=
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
        _printedQRFields(before) != _printedQRFields(radio);
  });
}

/// What the printed QR codes encode for [radio].
(String, String, WifiSecurityType) _printedQRFields(WiFiItem radio) =>
    (radio.ssid, radio.password, radio.securityType);
