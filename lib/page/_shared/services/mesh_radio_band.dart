/// The band a DataElements radio is on, from its operating class (#1686).
///
/// **Why not from `Device.WiFi.Radio`.** The app's other band source,
/// `UspWifiDataService.buildBssidToBandMap`, reads the router's own
/// `Device.WiFi.SSID` and `Radio` tables, so it knows only the **controller's**
/// BSSIDs: a client on an agent had no band (#1118). DataElements describes
/// every node's radios. And the two tables cannot be joined by index:
/// on `2.0.3.26101482` DataElements `Radio.1` is the 5 GHz radio while
/// TR-181 `Device.WiFi.Radio.1` is the 2.4 GHz one.
///
/// **The source.** `Radio.{i}.CurrentOperatingClassProfile.{j}.Class` is "the
/// Operating Class per 802.11 Table E-4 that this radio is currently operating
/// on" (TR-181). Architecture#191 made FL-WRT fill it; a profile it has not
/// filled reads `0`. The ranges below are Table E-4's global operating
/// classes as Linux's `net/wireless/util.c` lists them. Note that
/// `ieee80211_operating_class_to_band` there omits 136 while
/// `ieee80211_operating_class_to_chandef` in the same file maps it to 6 GHz
/// (20 MHz, channel 2); 136 is a 6 GHz class, so it is included here.
/// Measured on the bench: the 5 GHz radio reported 125, 127 and 128, the
/// 2.4 GHz radio 81.
library;

import 'package:privacy_gui/generated/data_elements_network.g.dart';

/// The band [operatingClass] belongs to, spelled the way the app spells bands
/// everywhere else (`2.4GHz` / `5GHz` / `6GHz`), or null when the class names
/// none of them: `0` (not filled), 60 GHz (180), or a class Table E-4 does
/// not define.
String? meshBandOfOperatingClass(int operatingClass) {
  if (operatingClass >= 81 && operatingClass <= 84) return '2.4GHz';
  if (operatingClass == 112 ||
      (operatingClass >= 115 && operatingClass <= 130)) {
    return '5GHz';
  }
  if (operatingClass >= 131 && operatingClass <= 137) return '6GHz';
  return null;
}

/// The band [radio] is currently on, or null when its profiles name none, or
/// name more than one.
///
/// A radio reports one profile per bandwidth it runs (the 5 GHz radio above
/// listed three classes), so several profiles naming one band is normal.
/// Profiles naming two bands are a contradiction, and the answer is "unknown"
/// rather than a guess: a wrong band is shown, a missing one says nothing.
String? meshRadioBand(MeshRadio radio) {
  final bands = {
    for (final profile in radio.currentOperatingClassProfiles)
      meshBandOfOperatingClass(profile.operatingClass),
  }..remove(null);
  return bands.length == 1 ? bands.single : null;
}
