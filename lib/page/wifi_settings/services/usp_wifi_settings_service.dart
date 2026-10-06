import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';
import 'package:privacy_gui/core/utils/wifi_channel.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_quick_setup_network.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_channel_bonding.dart';
import 'package:privacy_gui/page/_shared/utils/wifi_guest_detection.dart';

final uspWifiSettingsServiceProvider = Provider<UspWifiSettingsService>(
  (ref) => UspWifiSettingsService(ref.read(uspClientProvider)!),
);

/// What the router said about a WiFi write.
///
/// [unanswered] is the ordinary outcome on FL-WRT 2.0, not a fault: every WiFi
/// write reloads all the radios, and the reply often has nowhere to arrive (the
/// browser is on the WiFi being reloaded, or a Remote Assistance proxy outlasts
/// the wait). The caller then reads the router back ([UspWifiSettingsService
/// .isApplied]) before deciding — #1460's single DFS SET (a different service,
/// same shape) took 35.4 s and had succeeded when the app reported it failed.
enum WifiWriteOutcome { confirmed, unanswered }

/// A WiFi write that has been worked out but not yet sent.
///
/// [params] are known **before** the write goes out, so a caller whose wait
/// runs out still knows what to read back — reading back from the write's own
/// reply would read nothing exactly when the reply is lost. [count] is the
/// number of SSIDs a toggle matched, and 1 otherwise. [send] issues the one SET.
///
/// [proof] is the subset of [params] that can tell a landed write from the old
/// state: the values this save **changes** and the router reads back. It never
/// holds a passphrase (TR-181 reads those back empty) nor a value resent
/// unchanged alongside a change — a password-only save resends the current
/// `ModeEnabled`, which reads back "matching" whether or not the write arrived
/// (CLOUD_GUARDIANS#215's exact case). Empty proof means a lost reply cannot be
/// confirmed by reading back, so it must not be reported as a success.
class WifiWritePlan {
  final Map<String, dynamic> params;
  final Map<String, dynamic> proof;
  final int count;
  final Future<WifiWriteOutcome> Function() send;

  const WifiWritePlan({
    required this.params,
    required this.send,
    this.proof = const {},
    this.count = 1,
  });
}

/// Stateless service for transforming raw USP WiFi data into [WifiNetworkUIModel] list.
///
/// Cross-references three TR-181 collections:
///   - Device.WiFi.SSID.{i}          (ssid, enable, advertisement)
///   - Device.WiFi.AccessPoint.{i}   (security mode, passphrase, MAC control)
///   - Device.WiFi.Radio.{i}         (band, channel, bandwidth)
///
/// Relationship:
///   SSID.lowerLayers  → Radio instance path
///   AccessPoint.ssidReference → SSID instance path
class UspWifiSettingsService {
  final UspClient _usp;

  UspWifiSettingsService(this._usp);

  /// Builds a list of [WifiNetworkUIModel], one per SSID instance.
  ///
  /// Ordering follows the SSID instance ID sort (numeric), which matches
  /// the band ordering (e.g. SSID.1=2.4GHz, SSID.2=5GHz, SSID.3=6GHz).
  List<WifiNetworkUIModel> buildWifiNetworks({
    required WiFiSsids ssids,
    required WiFiAccessPoints accessPoints,
    required WiFiRadios radios,
  }) {
    // Build lookup maps with normalized trailing-dot paths
    final apBySsidRef = <String, WiFiAccessPoint>{};
    for (final ap in accessPoints.items) {
      final key = ensureTrailingDot(ap.ssidReference);
      if (key.isNotEmpty) apBySsidRef[key] = ap;
    }

    final radioByPath = <String, WiFiRadio>{};
    for (final r in radios.items) {
      radioByPath[ensureTrailingDot(r.instancePath)] = r;
    }

    logger.d('[USP][WiFi]: Building networks: '
        '${ssids.items.length} SSIDs, '
        '${accessPoints.items.length} APs, '
        '${radios.items.length} radios');

    final networks = <WifiNetworkUIModel>[];
    for (final ssid in ssids.items) {
      final ssidPath = ensureTrailingDot(ssid.instancePath);

      // Find matching AccessPoint via ssidReference
      final ap = apBySsidRef[ssidPath];

      // Find matching Radio via SSID.lowerLayers
      final radioPath = ensureTrailingDot(ssid.lowerLayers);
      final radio = radioByPath[radioPath];

      logger.d('[USP][WiFi]: SSID ${ssid.ssid}: '
          'AP=${ap?.instancePath ?? "none"}, '
          'radio=${radio?.operatingFrequencyBand ?? "none"}, '
          'alias=${ssid.alias ?? "none"}');

      // Guest detection via the canonical alias rule (see wifi_guest_detection).
      final isGuest = isGuestSsid(ssid);

      // Parse Security.ModesSupported comma-separated string into a list.
      // e.g. "None, WPA2-Personal, WPA3-Personal" → ['None', 'WPA2-Personal', 'WPA3-Personal']
      final supportedModes = _parseModesSupported(ap?.modesSupported ?? '');

      final band = _normalizeBand(radio?.operatingFrequencyBand ?? '');
      // DFS (IEEE 802.11h) channels must not appear when DFS is disabled. The
      // firmware leaves them in PossibleChannels regardless, so filter here —
      // before computing per-bandwidth lists — so both the dropdown and the
      // "N channels available" counts stay consistent.
      final dfsEnabled = radio?.ieee80211hEnabled ?? false;
      final possibleChannels = filterDfsChannels(
        parsePossibleChannels(radio?.possibleChannels ?? ''),
        band: band,
        dfsEnabled: dfsEnabled,
      );
      final supportedBandwidths = _parseSupportedBandwidths(
          radio?.supportedOperatingChannelBandwidths ?? '');

      final channelsPerBw = computeChannelsPerBandwidth(
        band: band,
        possibleChannels: possibleChannels,
        supportedBandwidths: supportedBandwidths,
      );

      networks.add(WifiNetworkUIModel(
        ssidInstancePath: ssid.instancePath,
        accessPointInstancePath: ap?.instancePath,
        radioInstancePath: radio?.instancePath,
        ssid: ssid.ssid,
        enabled: ssid.enable,
        ssidAdvertisementEnabled: ap?.ssidAdvertisementEnabled ?? true,
        supportedSecurityModes: supportedModes,
        securityMode: ap?.securityModeEnabled ?? '',
        keyPassphrase: ap?.keyPassphrase ?? '',
        isGuest: isGuest,
        band: band,
        channel: radio?.channel ?? 0,
        channelBandwidth: radio?.operatingChannelBandwidth ?? '',
        autoChannelEnable: radio?.autoChannelEnable ?? true,
        possibleChannels: possibleChannels,
        operatingStandards: radio?.operatingStandards ?? '',
        supportedStandards: radio?.supportedStandards ?? '',
        supportedBandwidths: supportedBandwidths,
        availableChannelsPerBandwidth: channelsPerBw,
      ));
    }

    return networks;
  }

  /// Builds [WifiQuickSetupNetwork] aggregates from the network list.
  ///
  /// Returns a record of (main, guest, isQuickSetup):
  ///   - `main`         — all non-guest networks combined; null if none exist.
  ///   - `guest`        — all guest networks combined; null if none exist.
  ///   - `isQuickSetup` — true when all main networks share the same `ssid`
  ///                      and `enabled` state. Mirrors the old JNAP logic but
  ///                      excludes `securityMode` since 6 GHz is forced to WPA3
  ///                      and would almost always differ from 2.4/5 GHz.
  ({
    WifiQuickSetupNetwork? main,
    WifiQuickSetupNetwork? guest,
    bool isQuickSetup
  }) buildQuickSetupNetworks(List<WifiNetworkUIModel> networks) {
    final mainNetworks = networks.where((n) => !n.isGuest).toList();
    final guestNetworks = networks.where((n) => n.isGuest).toList();

    // Quick Setup requires all networks (main AND guest) to share the same
    // enabled state and SSID within their group. If any group is inconsistent,
    // the aggregated view would be misleading — fall back to Advanced mode.
    bool isConsistent(List<WifiNetworkUIModel> nets) {
      if (nets.isEmpty) return true;
      final first = nets.first;
      return nets.every(
        (n) => n.enabled == first.enabled && n.ssid == first.ssid,
      );
    }

    final isQuickSetup =
        isConsistent(mainNetworks) && isConsistent(guestNetworks);

    return (
      main: mainNetworks.isEmpty
          ? null
          : _buildAggregate(mainNetworks, isGuest: false),
      guest: guestNetworks.isEmpty
          ? null
          : _buildAggregate(guestNetworks, isGuest: true),
      isQuickSetup: isQuickSetup,
    );
  }

  WifiQuickSetupNetwork _buildAggregate(
    List<WifiNetworkUIModel> networks, {
    required bool isGuest,
  }) {
    final first = networks.first;

    // Intersection of supported security modes, preserving first network's order.
    var modesSet = first.supportedSecurityModes.toSet();
    for (final n in networks.skip(1)) {
      modesSet = modesSet.intersection(n.supportedSecurityModes.toSet());
    }
    final orderedModes =
        first.supportedSecurityModes.where(modesSet.contains).toList();

    return WifiQuickSetupNetwork(
      isGuest: isGuest,
      ssid: first.ssid,
      securityMode: first.securityMode,
      keyPassphrase: first.keyPassphrase,
      supportedSecurityModes: orderedModes,
      ssidInstancePaths: networks.map((n) => n.ssidInstancePath).toList(),
      apInstancePaths: networks
          .where((n) => n.accessPointInstancePath != null)
          .map((n) => n.accessPointInstancePath!)
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Save — Quick Setup
  // ---------------------------------------------------------------------------

  /// Plans a Quick Setup save: **one** SET, sent by the plan's `send`.
  ///
  /// Writes are gated by field-level diff against [original] so that firmware
  /// only receives the parameters the user actually changed:
  ///   - SSID params only when ssid name or enabled flag changed.
  ///   - AP params only when password, securityMode or enabled changed.
  ///
  /// This prevents `KeyPassphrase (Invalid value)` errors from firmware when
  /// the user toggles Guest enable without (re-)entering a passphrase.
  ///
  /// One SET because every WiFi SET reloads all radios: written one row at a
  /// time, each write waited ~25 s for a reload and the next landed mid-reload,
  /// so a name change stuck and the password did not (#1499, CLOUD_GUARDIANS
  /// #215). See [_writeOnce].
  WifiWritePlan saveQuickSetup({
    required WifiSettingsSettings original,
    required WifiSettingsSettings current,
    required WifiSettingsStatus status,
  }) {
    final params = <String, dynamic>{};
    final proof = <String, dynamic>{};
    final groups = [
      (
        pending: current.quickSetupMain,
        orig: original.quickSetupMain,
        isGuest: false,
      ),
      (
        pending: current.quickSetupGuest,
        orig: original.quickSetupGuest,
        isGuest: true,
      ),
    ];

    for (final group in groups) {
      final pending = group.pending;
      if (pending == null) continue;
      final orig = group.orig;

      final aggregate = group.isGuest
          ? status.quickSetupGuestAggregate
          : status.quickSetupMainAggregate;
      if (aggregate == null) continue;

      // ── SSID layer — only when ssid name or enabled changed ────────────
      final ssidChanged = orig == null || orig.ssid != pending.ssid;
      final enabledChanged = orig == null || orig.enabled != pending.enabled;
      if (aggregate.ssidInstancePaths.isNotEmpty &&
          (ssidChanged || enabledChanged)) {
        if (ssidChanged) {
          if (pending.ssid.isEmpty) {
            throw InvalidInputError(detail: 'SSID name cannot be empty');
          }
          if (pending.ssid.length > 32) {
            throw InvalidInputError(
                detail: 'SSID name cannot exceed 32 characters');
          }
        }
        for (final p in aggregate.ssidInstancePaths) {
          params['${p}SSID'] = pending.ssid;
          params['${p}Enable'] = pending.enabled;
          if (ssidChanged) proof['${p}SSID'] = pending.ssid;
          if (enabledChanged) proof['${p}Enable'] = pending.enabled;
        }
      }

      // ── AP layer — when password, securityMode, or enabled changed ─────
      // enabled is mirrored onto AccessPoint.Enable alongside SSID.Enable
      // because SSID.Enable alone does not stop broadcasting on this
      // firmware (see #972).
      final passwordChanged = orig == null || orig.password != pending.password;
      final modeChanged =
          orig == null || orig.securityMode != pending.securityMode;
      if (aggregate.apInstancePaths.isNotEmpty &&
          (passwordChanged || modeChanged || enabledChanged)) {
        // Build a band lookup: AP instance path → band string.
        // Used to apply the 6 GHz security override (Wi-Fi 6E mandates WPA3).
        final bandByApPath = <String, String>{
          for (final n in current.networks)
            if (n.accessPointInstancePath != null)
              n.accessPointInstancePath!: n.band,
        };
        // Each row's mode as the router holds it now, so a coerced 6 GHz
        // mode that equals it is not mistaken for a change it can prove.
        final modeByApPath = <String, String>{
          for (final n in original.networks)
            if (n.accessPointInstancePath != null)
              n.accessPointInstancePath!: n.securityMode,
        };

        // Whether the security layer (mode + passphrase) needs writing.
        // When only `enabled` changed we mirror AccessPoint.Enable without
        // re-sending security params, so an enable toggle never mutates the
        // security mode (e.g. the 6 GHz WPA3 override).
        final securityChanged = passwordChanged || modeChanged;
        for (final p in aggregate.apInstancePaths) {
          final band = bandByApPath[p] ?? '';
          final securityMode = _securityModeFor6GHz(
            band: band,
            selectedMode: pending.securityMode,
          );
          if (enabledChanged) {
            params['${p}Enable'] = pending.enabled;
            proof['${p}Enable'] = pending.enabled;
          }
          if (securityChanged) {
            params['${p}Security.ModeEnabled'] = securityMode;
            if (modeByApPath[p] != securityMode) {
              proof['${p}Security.ModeEnabled'] = securityMode;
            }
            // Omit an empty passphrase (e.g. when only securityMode
            // changed to an open mode) so firmware does not reject it.
            if (pending.password.isNotEmpty) {
              params['${p}Security.KeyPassphrase'] = pending.password;
            }
          }
        }
      }
    }
    return _plan(params, 'WiFi Quick Setup update', proof: proof);
  }

  // ---------------------------------------------------------------------------
  // Save — Advanced
  // ---------------------------------------------------------------------------

  /// Plans an Advanced save (per-network): **one** SET, sent by `send`.
  ///
  /// One SET across every network and layer, for the reason in [_writeOnce].
  /// Its outcome can still be [WifiWriteOutcome.unanswered] — the reply lost to
  /// the reload it caused — so the caller reads [WifiWritePlan.params] back
  /// instead of reporting a failure.
  ///
  /// Validation runs while the plan is built, so a bad value throws before any
  /// SET goes out.
  WifiWritePlan saveAdvanced({
    required List<WifiNetworkUIModel> original,
    required List<WifiNetworkUIModel> current,
  }) {
    final params = <String, dynamic>{};
    final proof = <String, dynamic>{};
    for (var i = 0; i < current.length; i++) {
      final curr = current[i];
      final orig = original.length > i ? original[i] : null;

      // Skip unchanged networks.
      if (orig != null && orig == curr) continue;

      // ── SSID layer ─────────────────────────────────────────────────────
      if (orig == null ||
          orig.enabled != curr.enabled ||
          orig.ssid != curr.ssid) {
        params['${curr.ssidInstancePath}Enable'] = curr.enabled;
        params['${curr.ssidInstancePath}SSID'] = curr.ssid;
        if (orig == null || orig.enabled != curr.enabled) {
          proof['${curr.ssidInstancePath}Enable'] = curr.enabled;
        }
        if (orig == null || orig.ssid != curr.ssid) {
          proof['${curr.ssidInstancePath}SSID'] = curr.ssid;
        }
      }

      // ── AccessPoint layer ───────────────────────────────────────────────
      // Mirror the enabled flag onto AccessPoint.Enable alongside SSID.Enable:
      // on this firmware SSID.Enable alone does not stop the AP broadcasting,
      // so the enable state must be written to both layers (see #972).
      //
      // Each field is gated on its own diff so a pure enable toggle sends
      // only AccessPoint.Enable and never re-writes the security mode or the
      // advertisement flag (mirrors saveQuickSetup's AP gating).
      final ap = curr.accessPointInstancePath;
      final enabledChanged = orig == null || orig.enabled != curr.enabled;
      final securityChanged = orig == null ||
          orig.keyPassphrase != curr.keyPassphrase ||
          orig.securityMode != curr.securityMode;
      final broadcastChanged = orig == null ||
          orig.ssidAdvertisementEnabled != curr.ssidAdvertisementEnabled;
      if (ap != null &&
          (enabledChanged || securityChanged || broadcastChanged)) {
        // Apply the 6 GHz security override (Wi-Fi 6E mandates WPA3), the
        // same way saveQuickSetup does, so both save paths write a
        // firmware-valid mode on 6 GHz. Skip the override for enable-only
        // toggles (securityChanged false) so the mode is never re-written.
        final securityMode = securityChanged && curr.securityMode.isNotEmpty
            ? _securityModeFor6GHz(
                band: curr.band,
                selectedMode: curr.securityMode,
              )
            : null;
        if (enabledChanged) {
          params['${ap}Enable'] = curr.enabled;
          proof['${ap}Enable'] = curr.enabled;
        }
        if (securityMode != null) {
          params['${ap}Security.ModeEnabled'] = securityMode;
          // A password-only change resends the current mode: it proves
          // nothing (CLOUD_GUARDIANS#215).
          if (orig?.securityMode != securityMode) {
            proof['${ap}Security.ModeEnabled'] = securityMode;
          }
        }
        if (securityChanged && curr.keyPassphrase.isNotEmpty) {
          params['${ap}Security.KeyPassphrase'] = curr.keyPassphrase;
        }
        if (broadcastChanged) {
          params['${ap}SSIDAdvertisementEnabled'] =
              curr.ssidAdvertisementEnabled;
          proof['${ap}SSIDAdvertisementEnabled'] =
              curr.ssidAdvertisementEnabled;
        }
      }

      // ── Radio layer ─────────────────────────────────────────────────────
      final radio = curr.radioInstancePath;
      if (radio != null &&
          (orig == null ||
              orig.operatingStandards != curr.operatingStandards ||
              orig.channelBandwidth != curr.channelBandwidth ||
              orig.channel != curr.channel ||
              orig.autoChannelEnable != curr.autoChannelEnable)) {
        if (curr.operatingStandards.isNotEmpty) {
          params['${radio}OperatingStandards'] = curr.operatingStandards;
          if (orig?.operatingStandards != curr.operatingStandards) {
            proof['${radio}OperatingStandards'] = curr.operatingStandards;
          }
        }
        if (curr.channelBandwidth.isNotEmpty) {
          params['${radio}OperatingChannelBandwidth'] = curr.channelBandwidth;
          if (orig?.channelBandwidth != curr.channelBandwidth) {
            proof['${radio}OperatingChannelBandwidth'] = curr.channelBandwidth;
          }
        }
        params['${radio}AutoChannelEnable'] = curr.autoChannelEnable;
        if (orig?.autoChannelEnable != curr.autoChannelEnable) {
          proof['${radio}AutoChannelEnable'] = curr.autoChannelEnable;
        }
        // Only a manual channel is ours to prove; on auto the firmware picks.
        if (!curr.autoChannelEnable) {
          params['${radio}Channel'] = curr.channel;
          if (orig?.channel != curr.channel) {
            proof['${radio}Channel'] = curr.channel;
          }
        }
      }
    }
    return _plan(params, 'WiFi Advanced update', proof: proof);
  }

  // ---------------------------------------------------------------------------
  // Mutations — WiFi Radio quick actions (from Dashboard cards)
  // ---------------------------------------------------------------------------

  /// Plans a WiFi radio's channel and auto-channel change.
  ///
  /// Already one SET, but a channel change reloads the radio like any other
  /// WiFi write, so its reply can be lost the same way: the outcome is returned
  /// for the caller to read back rather than reporting a failure at 30 s.
  ///
  /// On auto channel the proof is `AutoChannelEnable` alone: the dialog sends
  /// the radio's current channel with it, and the firmware then picks another,
  /// so a landed write would never read that channel back.
  WifiWritePlan updateRadioChannel(
    String instancePath, {
    required int channel,
    required bool autoChannel,
  }) =>
      _plan(
          {
            '${instancePath}Channel': channel,
            '${instancePath}AutoChannelEnable': autoChannel,
          },
          'Update radio channel',
          allowPartial: false,
          proof: {
            if (!autoChannel) '${instancePath}Channel': channel,
            '${instancePath}AutoChannelEnable': autoChannel,
          });

  /// Toggles all networks with a given SSID name on or off across all bands.
  ///
  /// Finds all SSID instances matching [ssidName] and toggles both their
  /// SSID.Enable and the matching AccessPoint.Enable. Writing both layers is
  /// required because SSID.Enable alone does not stop the AP broadcasting on
  /// this firmware (see #972). The AccessPoint match is resolved via
  /// AccessPoint.SSIDReference → SSID.instancePath.
  ///
  /// Both layers go out in **one** SET, for the reason in [_writeOnce].
  ///
  /// Returns the plan; its [WifiWritePlan.count] is the number of SSIDs
  /// matched, 0 (and no SET) when none was.
  WifiWritePlan toggleSsidsByName(
    WiFiSsids ssids,
    WiFiAccessPoints accessPoints,
    String ssidName,
    bool enable,
  ) {
    final ssidPaths = ssids.items
        .where((s) => s.ssid == ssidName)
        .map((s) => s.instancePath)
        .toList();

    if (ssidPaths.isEmpty) {
      return _plan(const {}, 'Toggle SSIDs', proof: const {}, count: 0);
    }

    // Resolve AccessPoint paths whose SSIDReference points at a matched SSID.
    final matchedSsidPathSet = ssidPaths.map(ensureTrailingDot).toSet();
    final apPaths = accessPoints.items
        .where((ap) =>
            matchedSsidPathSet.contains(ensureTrailingDot(ap.ssidReference)))
        .map((ap) => ap.instancePath)
        .toList();

    final params = <String, dynamic>{
      for (final p in ssidPaths) '${p}Enable': enable,
      for (final p in apPaths) '${p}Enable': enable,
    };
    // Every Enable written is the change, so all of it is proof.
    return _plan(params, 'Toggle SSIDs',
        proof: params, count: ssidPaths.length);
  }

  WifiWritePlan _plan(
    Map<String, dynamic> params,
    String label, {
    required Map<String, dynamic> proof,
    bool allowPartial = true,
    int count = 1,
  }) =>
      WifiWritePlan(
        params: params,
        proof: proof,
        count: count,
        send: () => _writeOnce(params, label, allowPartial: allowPartial),
      );

  /// Sends [params] as **one** SET and says whether the router answered.
  ///
  /// **One SET.** Every WiFi SET reloads all the radios on FL-WRT 2.0 (#1000,
  /// bench 2.0.2), so a save split into several SETs only ever had a live
  /// connection under the first. One SET means one reload: on the bench the new
  /// SSIDs were on the air in 15 s, against 40 s for two SETs.
  ///
  /// **[allowPartial] is true for a SET that spans tables, and has to be.** The
  /// OBUSPA broker refuses an atomic SET across more than one USP Service with
  /// 7005; SSID, AccessPoint and Radio rows together do (the same wall
  /// `PnpService.saveWifi` and `_saveIpv6Settings` hit). A Radio-only write is
  /// one service, so it stays atomic and cannot half-apply. A per-leaf failure
  /// the router does report still throws.
  ///
  /// Returns [WifiWriteOutcome.unanswered] when every error says the request
  /// never got an answer ([isUnansweredTransportFailure]) — the reply was lost to
  /// the reload. A refusal throws: a router that answered applied nothing, and
  /// the WASM client stamps `9999` on both, so only the message tells them apart.
  /// Nothing to write is [WifiWriteOutcome.confirmed] with no SET at all.
  Future<WifiWriteOutcome> _writeOnce(
    Map<String, dynamic> params,
    String label, {
    required bool allowPartial,
  }) async {
    if (params.isEmpty) return WifiWriteOutcome.confirmed;
    try {
      final result = await _usp.set(params, allowPartial: allowPartial);
      final parsed = UspResultParser.parseSetResult(result);
      if (parsed is UspFailure &&
          parsed.errors.every((e) => isUnansweredWifiWrite(e.errorMessage))) {
        logger.i('[USP][WiFi]: $label unanswered — the WiFi reloaded under '
            'the request');
        return WifiWriteOutcome.unanswered;
      }
      _throwIfParsedNotSuccess(parsed, label);
      return WifiWriteOutcome.confirmed;
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Whether the router now carries the values in [written] — a plan's
  /// [WifiWritePlan.proof], for a write whose own answer never arrived.
  ///
  /// Read back through the generated models rather than the raw leaves, because
  /// they already normalise the firmware's `true` / `"true"` / `"1"` into one
  /// `bool`; a raw compare would call a landed write "not yet".
  ///
  /// **Passphrases are not compared.** TR-181 reads `KeyPassphrase` back empty,
  /// and they went out in the same SET as everything else, so the rest landing
  /// means they did — the rule `PnpService.isWifiApplied` follows.
  ///
  /// **Fails closed.** Nothing comparable reads as NOT applied: with no changed
  /// value to look at, a "yes" would be a guess, and #215's false success was
  /// exactly that guess.
  ///
  /// Throws [ServiceError] when the read itself fails; the caller treats that
  /// as "not yet" while the radios settle.
  Future<bool> isApplied(Map<String, dynamic> written) async {
    bool wants(String table) => written.keys.any((k) =>
        k.startsWith('Device.WiFi.$table.') && !k.endsWith('KeyPassphrase'));
    final needSsids = wants('SSID');
    final needAps = wants('AccessPoint');
    final needRadios = wants('Radio');
    if (!needSsids && !needAps && !needRadios) return false;

    final WiFiSsids? ssids;
    final WiFiAccessPoints? aps;
    final WiFiRadios? radios;
    try {
      ssids = needSsids ? await WiFiSsids.fetch(_usp) : null;
      aps = needAps ? await WiFiAccessPoints.fetch(_usp) : null;
      radios = needRadios ? await WiFiRadios.fetch(_usp) : null;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final readBack = <String, Object?>{
      for (final s in ssids?.items ?? const <WiFiSsid>[]) ...{
        '${s.instancePath}SSID': s.ssid,
        '${s.instancePath}Enable': s.enable,
      },
      for (final a in aps?.items ?? const <WiFiAccessPoint>[]) ...{
        '${a.instancePath}Enable': a.enable,
        '${a.instancePath}Security.ModeEnabled': a.securityModeEnabled,
        '${a.instancePath}SSIDAdvertisementEnabled': a.ssidAdvertisementEnabled,
      },
      for (final r in radios?.items ?? const <WiFiRadio>[]) ...{
        '${r.instancePath}Channel': r.channel,
        '${r.instancePath}OperatingChannelBandwidth':
            r.operatingChannelBandwidth,
        '${r.instancePath}OperatingStandards': r.operatingStandards,
        '${r.instancePath}AutoChannelEnable': r.autoChannelEnable,
      },
    };

    return written.entries
        .where((e) => !e.key.endsWith('KeyPassphrase'))
        .every((e) => readBack[e.key] == e.value);
  }

  /// Throws the appropriate [ServiceError] when [parsed] is not a complete
  /// success. [label] prefixes the error summary.
  void _throwIfParsedNotSuccess(UspSetResult parsed, String label) {
    switch (parsed) {
      case UspSuccess():
        return;
      case UspPartialSuccess(failures: final f):
        throw UspPartialFailureError(
          summary: '$label partial failure: ${f.first.errorMessage}',
          successPaths: [],
          failures: f,
        );
      case UspFailure(errors: final e):
        throw UspCompleteFailureError(
          summary: '$label failed: ${e.first.errorMessage}',
          failures: e,
        );
    }
  }

  /// Returns the effective security mode to apply to a given band.
  ///
  /// 6 GHz (Wi-Fi 6E) mandates WPA3:
  ///   - Open / OWE (Enhanced Open) selected → send "OWE"
  ///   - Any other mode                      → send "WPA3-Personal"
  ///
  /// 'OWE' is the TR-181 token firmware accepts for Enhanced Open.
  /// All other bands: return [selectedMode] unchanged.
  String _securityModeFor6GHz({
    required String band,
    required String selectedMode,
  }) {
    if (!band.contains('6')) return selectedMode;
    const openModes = {'None', 'OWE', ''};
    return openModes.contains(selectedMode) ? 'OWE' : 'WPA3-Personal';
  }
}

/// Parses a comma-separated TR-181 Security.ModesSupported string into a trimmed list.
/// e.g. "None, WPA2-Personal, WPA3-Personal" → ['None', 'WPA2-Personal', 'WPA3-Personal']
List<String> _parseModesSupported(String raw) {
  if (raw.isEmpty) return [];
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Parses a TR-181 SupportedOperatingChannelBandwidths string.
/// e.g. "Auto,20MHz,40MHz,80MHz" → ['Auto', '20MHz', '40MHz', '80MHz']
List<String> _parseSupportedBandwidths(String raw) {
  if (raw.isEmpty) return [];
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Normalizes TR-181 OperatingFrequencyBand to display string.
String _normalizeBand(String rawBand) {
  final lower = rawBand.toLowerCase();
  if (lower.contains('6g') || lower.contains('6 g')) return '6GHz';
  if (lower.contains('5g') || lower.contains('5 g')) return '5GHz';
  if (lower.contains('2.4') || lower.contains('2_4')) return '2.4GHz';
  return rawBand;
}
