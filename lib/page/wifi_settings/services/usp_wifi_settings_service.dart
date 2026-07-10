import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
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
      final key = _ensureTrailingDot(ap.ssidReference);
      if (key.isNotEmpty) apBySsidRef[key] = ap;
    }

    final radioByPath = <String, WiFiRadio>{};
    for (final r in radios.items) {
      radioByPath[_ensureTrailingDot(r.instancePath)] = r;
    }

    logger.d('[USP][WiFi]: Building networks: '
        '${ssids.items.length} SSIDs, '
        '${accessPoints.items.length} APs, '
        '${radios.items.length} radios');

    final networks = <WifiNetworkUIModel>[];
    for (final ssid in ssids.items) {
      final ssidPath = _ensureTrailingDot(ssid.instancePath);

      // Find matching AccessPoint via ssidReference
      final ap = apBySsidRef[ssidPath];

      // Find matching Radio via SSID.lowerLayers
      final radioPath = _ensureTrailingDot(ssid.lowerLayers);
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
      final possibleChannels =
          _parsePossibleChannels(radio?.possibleChannels ?? '');
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

  /// Saves WiFi settings in Quick Setup mode.
  ///
  /// Writes are gated by field-level diff against [original] so that firmware
  /// only receives the parameters the user actually changed:
  ///   - SSID update is issued only when ssid name or enabled flag changed.
  ///   - AP update is issued only when password or securityMode changed.
  ///
  /// This prevents `KeyPassphrase (Invalid value)` errors from firmware when
  /// the user toggles Guest enable without (re-)entering a passphrase.
  Future<void> saveQuickSetup({
    required WifiSettingsSettings original,
    required WifiSettingsSettings current,
    required WifiSettingsStatus status,
  }) async {
    try {
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
            final result = await WiFiSsids.update(_usp, [
              WiFiSsidUpdate(
                instancePath: p,
                ssid: pending.ssid,
                enable: pending.enabled,
              ),
            ]);
            final parsed = UspResultParser.parseSetResult(result);
            switch (parsed) {
              case UspSuccess():
                break;
              case UspPartialSuccess(failures: final f):
                throw UspPartialFailureError(
                  summary:
                      'WiFi SSID update partial failure: ${f.first.errorMessage}',
                  successPaths: [],
                  failures: f,
                );
              case UspFailure(errors: final e):
                throw UspCompleteFailureError(
                  summary: 'WiFi SSID update failed: ${e.first.errorMessage}',
                  failures: e,
                );
            }
          }
        }

        // ── AP layer — when password, securityMode, or enabled changed ─────
        // enabled is mirrored onto AccessPoint.Enable alongside SSID.Enable
        // because SSID.Enable alone does not stop broadcasting on this
        // firmware (see #972).
        final passwordChanged =
            orig == null || orig.password != pending.password;
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
            final result = await WiFiAccessPoints.update(
              _usp,
              [
                WiFiAccessPointUpdate(
                  instancePath: p,
                  enable: enabledChanged ? pending.enabled : null,
                  // Omit an empty passphrase (e.g. when only securityMode
                  // changed to an open mode) so firmware does not reject it.
                  keyPassphrase: securityChanged && pending.password.isNotEmpty
                      ? pending.password
                      : null,
                  securityModeEnabled: securityChanged ? securityMode : null,
                )
              ],
            );
            final parsed = UspResultParser.parseSetResult(result);
            switch (parsed) {
              case UspSuccess():
                break;
              case UspPartialSuccess(failures: final f):
                throw UspPartialFailureError(
                  summary:
                      'WiFi AP update partial failure: ${f.first.errorMessage}',
                  successPaths: [],
                  failures: f,
                );
              case UspFailure(errors: final e):
                throw UspCompleteFailureError(
                  summary: 'WiFi AP update failed: ${e.first.errorMessage}',
                  failures: e,
                );
            }
          }
        }
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Save — Advanced
  // ---------------------------------------------------------------------------

  /// Saves WiFi settings in Advanced mode (per-network).
  Future<void> saveAdvanced({
    required List<WifiNetworkUIModel> original,
    required List<WifiNetworkUIModel> current,
  }) async {
    try {
      for (var i = 0; i < current.length; i++) {
        final curr = current[i];
        final orig = original.length > i ? original[i] : null;

        // Skip unchanged networks.
        if (orig != null && orig == curr) continue;

        // ── SSID layer ─────────────────────────────────────────────────────
        if (orig == null ||
            orig.enabled != curr.enabled ||
            orig.ssid != curr.ssid) {
          final result = await WiFiSsids.update(
            _usp,
            [
              WiFiSsidUpdate(
                instancePath: curr.ssidInstancePath,
                enable: curr.enabled,
                ssid: curr.ssid,
              )
            ],
          );
          final parsed = UspResultParser.parseSetResult(result);
          switch (parsed) {
            case UspSuccess():
              break;
            case UspPartialSuccess(failures: final f):
              throw UspPartialFailureError(
                summary:
                    'WiFi SSID update partial failure: ${f.first.errorMessage}',
                successPaths: [],
                failures: f,
              );
            case UspFailure(errors: final e):
              throw UspCompleteFailureError(
                summary: 'WiFi SSID update failed: ${e.first.errorMessage}',
                failures: e,
              );
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
          final result = await WiFiAccessPoints.update(
            _usp,
            [
              WiFiAccessPointUpdate(
                instancePath: ap,
                enable: enabledChanged ? curr.enabled : null,
                keyPassphrase: securityChanged && curr.keyPassphrase.isNotEmpty
                    ? curr.keyPassphrase
                    : null,
                securityModeEnabled:
                    securityChanged && curr.securityMode.isNotEmpty
                        ? curr.securityMode
                        : null,
                ssidAdvertisementEnabled:
                    broadcastChanged ? curr.ssidAdvertisementEnabled : null,
              )
            ],
          );
          final parsed = UspResultParser.parseSetResult(result);
          switch (parsed) {
            case UspSuccess():
              break;
            case UspPartialSuccess(failures: final f):
              throw UspPartialFailureError(
                summary:
                    'WiFi AP update partial failure: ${f.first.errorMessage}',
                successPaths: [],
                failures: f,
              );
            case UspFailure(errors: final e):
              throw UspCompleteFailureError(
                summary: 'WiFi AP update failed: ${e.first.errorMessage}',
                failures: e,
              );
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
          final result = await WiFiRadios.update(
            _usp,
            [
              WiFiRadioUpdate(
                instancePath: radio,
                operatingStandards: curr.operatingStandards.isNotEmpty
                    ? curr.operatingStandards
                    : null,
                operatingChannelBandwidth: curr.channelBandwidth.isNotEmpty
                    ? curr.channelBandwidth
                    : null,
                autoChannelEnable: curr.autoChannelEnable,
                channel: curr.autoChannelEnable ? null : curr.channel,
              )
            ],
          );
          final parsed = UspResultParser.parseSetResult(result);
          switch (parsed) {
            case UspSuccess():
              break;
            case UspPartialSuccess(failures: final f):
              throw UspPartialFailureError(
                summary:
                    'WiFi Radio update partial failure: ${f.first.errorMessage}',
                successPaths: [],
                failures: f,
              );
            case UspFailure(errors: final e):
              throw UspCompleteFailureError(
                summary: 'WiFi Radio update failed: ${e.first.errorMessage}',
                failures: e,
              );
          }
        }
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Mutations — WiFi Radio quick actions (from Dashboard cards)
  // ---------------------------------------------------------------------------

  /// Updates a WiFi radio's channel and auto-channel setting.
  Future<void> updateRadioChannel(
    String instancePath, {
    required int channel,
    required bool autoChannel,
  }) async {
    try {
      final result = await WiFiRadios.update(
        _usp,
        [
          WiFiRadioUpdate(
            instancePath: instancePath,
            channel: channel,
            autoChannelEnable: autoChannel,
          )
        ],
      );
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(failures: final f):
          throw UspPartialFailureError(
            summary:
                'Update radio channel partial failure: ${f.first.errorMessage}',
            successPaths: [],
            failures: f,
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'Update radio channel failed: ${e.first.errorMessage}',
            failures: e,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Toggles all networks with a given SSID name on or off across all bands.
  ///
  /// Finds all SSID instances matching [ssidName] and toggles both their
  /// SSID.Enable and the matching AccessPoint.Enable. Writing both layers is
  /// required because SSID.Enable alone does not stop the AP broadcasting on
  /// this firmware (see #972). The AccessPoint match is resolved via
  /// AccessPoint.SSIDReference → SSID.instancePath.
  ///
  /// Returns the number of SSIDs toggled.
  Future<int> toggleSsidsByName(
    WiFiSsids ssids,
    WiFiAccessPoints accessPoints,
    String ssidName,
    bool enable,
  ) async {
    final ssidPaths = ssids.items
        .where((s) => s.ssid == ssidName)
        .map((s) => s.instancePath)
        .toList();

    if (ssidPaths.isEmpty) return 0;

    // Resolve AccessPoint paths whose SSIDReference points at a matched SSID.
    final matchedSsidPathSet = ssidPaths.map(_ensureTrailingDot).toSet();
    final apPaths = accessPoints.items
        .where((ap) =>
            matchedSsidPathSet.contains(_ensureTrailingDot(ap.ssidReference)))
        .map((ap) => ap.instancePath)
        .toList();

    try {
      final ssidUpdates = ssidPaths
          .map((p) => WiFiSsidUpdate(instancePath: p, enable: enable))
          .toList();
      final ssidResult = await WiFiSsids.update(_usp, ssidUpdates);
      _throwIfNotSuccess(ssidResult, 'Toggle SSIDs');

      if (apPaths.isNotEmpty) {
        final apUpdates = apPaths
            .map((p) => WiFiAccessPointUpdate(instancePath: p, enable: enable))
            .toList();
        final apResult = await WiFiAccessPoints.update(_usp, apUpdates);
        _throwIfNotSuccess(apResult, 'Toggle AccessPoints');
      }

      return ssidPaths.length;
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Parses a USP Set result and throws the appropriate [ServiceError] when it
  /// is not a complete success. [label] prefixes the error summary.
  void _throwIfNotSuccess(Map<String, dynamic> result, String label) {
    final parsed = UspResultParser.parseSetResult(result);
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
  ///   - Open / Enhanced-Open selected → send "Enhanced-Open"
  ///   - Any other mode               → send "WPA3-Personal"
  ///
  /// All other bands: return [selectedMode] unchanged.
  String _securityModeFor6GHz({
    required String band,
    required String selectedMode,
  }) {
    if (!band.contains('6')) return selectedMode;
    const openModes = {'None', 'Enhanced-Open', ''};
    return openModes.contains(selectedMode) ? 'Enhanced-Open' : 'WPA3-Personal';
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

/// Parses a TR-181 PossibleChannels string into a sorted list of channel numbers.
/// Handles both comma-separated values and range notation.
/// e.g. "1-13,36,40,44,48" → [1,2,3,4,5,6,7,8,9,10,11,12,13,36,40,44,48]
List<int> _parsePossibleChannels(String raw) {
  if (raw.isEmpty) return [];
  final result = <int>[];
  for (final part in raw.split(',')) {
    final trimmed = part.trim();
    if (trimmed.contains('-')) {
      final bounds = trimmed.split('-');
      final start = int.tryParse(bounds[0].trim());
      final end = int.tryParse(bounds[1].trim());
      if (start != null && end != null) {
        for (var i = start; i <= end; i++) {
          result.add(i);
        }
      }
    } else {
      final ch = int.tryParse(trimmed);
      if (ch != null) result.add(ch);
    }
  }
  result.sort();
  return result;
}

/// Ensures a TR-181 path ends with a dot.
String _ensureTrailingDot(String path) {
  if (path.isEmpty) return path;
  return path.endsWith('.') ? path : '$path.';
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
