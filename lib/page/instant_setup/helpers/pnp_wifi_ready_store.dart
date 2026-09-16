import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';

/// The storage key. New rather than one of the two dead PnP keys in
/// `pref_key.dart` (`PnPSetup`, `FwUpdated`, both zero-reference): those name
/// nothing in particular, and a key whose name does not say what it holds is how
/// they came to mean nothing.
const _kStorageKey = 'pnp_wifi_ready_credentials';

final pnpWifiReadyStoreProvider = Provider<PnpWifiReadyStore>((ref) {
  return PnpWifiReadyStore(const FlutterSecureStorage());
});

/// The credentials the setup-complete screen shows, kept across one reboot.
///
/// REQ-B4. The firmware stage sits between [WizardSaved] and [WizardWifiReady]
/// and reboots the router once — and if the user changed the main WiFi, they are
/// by then already associated to the new SSID, so the reboot drops them a second
/// time. Coming back has to land on the same screen with the same SSID and
/// passphrase, because that screen is the only place those were ever shown.
///
/// **Secure storage, not `SharedPreferences`.** A WiFi passphrase is a
/// credential; `pref_key.dart` splits its keys into unsecured and secured for
/// exactly this reason, and the secured half is where every other secret in this
/// app lives. Shaped after `RouterFingerprintService` — one key, three verbs, the
/// storage injected so a test can supply a mock rather than a platform channel.
///
/// **Every method swallows.** This store exists to make a good outcome better; a
/// storage failure must never be the thing that stops PnP finishing (REQ-B3's
/// principle, applied to the same stage). A failed [store] costs the restore, a
/// failed [read] falls back to the in-memory phase — which normally survives
/// anyway, since `pnpProvider` is not `autoDispose` and the app has one
/// container. What it does not survive is a page reload, and that is the case
/// this store is for.
class PnpWifiReadyStore {
  PnpWifiReadyStore(this._storage);

  final FlutterSecureStorage _storage;

  /// Writes [phase] as the credentials to show when setup finishes.
  ///
  /// Called **before** anything can reboot the router, which is the only ordering
  /// that works: after the dispatch there may be no session left to write from.
  Future<void> store(WizardWifiReady phase) async {
    try {
      await _storage.write(
        key: _kStorageKey,
        value: jsonEncode(phase.toJson()),
      );
    } catch (e) {
      logger.w('[PnP] could not persist the WiFi-ready credentials', error: e);
    }
  }

  /// The persisted credentials, or null when there are none to restore.
  ///
  /// Malformed JSON reads as absent rather than throwing: the only thing that can
  /// have written this key is [store], so a value that does not parse is a
  /// format change or a corrupt keystore, and neither is worth failing setup for.
  Future<WizardWifiReady?> read() async {
    try {
      final raw = await _storage.read(key: _kStorageKey);
      if (raw == null || raw.isEmpty) return null;
      return WizardWifiReady.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      logger.w('[PnP] could not read the WiFi-ready credentials', error: e);
      return null;
    }
  }

  /// Drops the credentials once they have been shown.
  ///
  /// Called when the flow leaves [WizardWifiReady], so a passphrase does not
  /// outlive the screen that needed it. A setup that is re-run writes its own.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _kStorageKey);
    } catch (e) {
      logger.w('[PnP] could not clear the WiFi-ready credentials', error: e);
    }
  }
}
