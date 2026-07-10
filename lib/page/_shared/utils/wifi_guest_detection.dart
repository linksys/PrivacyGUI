import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';

/// Canonical guest WiFi detection rule for the whole app.
///
/// A WiFi SSID is a guest network when its TR-181 `Alias` ends with the
/// `-guest` suffix, which firmware auto-provisions from FW 1.2.1+
/// (e.g. `wifi-2g-guest`, `wifi-5g-guest`).
///
/// This is the single source of truth for the Main-vs-Guest distinction.
/// Do not reintroduce instance-index or radio-occupancy heuristics — those
/// disagree with this rule and cause guest networks to be misclassified.
bool isGuestSsidAlias(String? alias) => alias?.endsWith('-guest') ?? false;

/// Convenience overload for a generated [WiFiSsid] instance.
bool isGuestSsid(WiFiSsid ssid) => isGuestSsidAlias(ssid.alias);
