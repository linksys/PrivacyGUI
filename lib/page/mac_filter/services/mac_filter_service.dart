import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/mac_filter_network.g.dart';
import 'package:privacy_gui/generated/mac_filter_network_operations.g.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_device_role.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';

/// The network-wide MAC filter mode (`X_LINKSYS_MACFilterMode`).
///
/// Instant Privacy is this feature in [allow] mode; the MAC Filter page also
/// offers [deny]. The wire values are the exact strings the firmware accepts.
enum MacFilterMode {
  disabled('Disabled'),
  allow('Allow'),
  deny('Deny');

  const MacFilterMode(this.wire);
  final String wire;

  static MacFilterMode fromWire(String value) => switch (value) {
        'Allow' => MacFilterMode.allow,
        'Deny' => MacFilterMode.deny,
        // Anything else (including 'Disabled' and any unexpected value) is
        // treated as off — the safe default for a filter.
        _ => MacFilterMode.disabled,
      };
}

/// The resolved MAC filter state read from the device.
class MacFilterData {
  final MacFilterMode mode;
  final List<String> macs;

  const MacFilterData({required this.mode, required this.macs});
}

final uspMacFilterServiceProvider = Provider<UspMacFilterService>(
  (ref) => UspMacFilterService(ref.read(uspClientProvider)!),
);

/// The one service both the MAC Filter page and Instant Privacy write through.
///
/// Read via [MacFilterNetwork.fetch] (the mode leaf plus a comma-joined list);
/// write via [MacFilterNetworkOperations.setMacFilter], which takes the list as
/// the JSON array the firmware requires. Instant Privacy drives it in
/// [MacFilterMode.allow]; the MAC Filter page can also select [MacFilterMode.deny].
///
/// **Validation is client-side.** The firmware answers an over-limit or
/// malformed list with only a generic 7012 and silently de-duplicates
/// (linksys/PrivacyGUI#1612), so this service normalizes, de-duplicates, checks
/// the 64-address limit and rejects a malformed MAC or an empty Allow list
/// *before* calling — surfacing an [InvalidInputError] the UI can act on.
class UspMacFilterService {
  UspMacFilterService(this._usp);

  final UspClient _usp;

  /// Firmware default (linksys/FWDEV#194); not exposed as a data-model path.
  static const int maxAddresses = 64;

  static final _macRegExp = RegExp(
    r'^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$',
  );

  static bool validateMac(String mac) => _macRegExp.hasMatch(mac.trim());

  /// Uppercase colon-separated canonical form. Precondition: passes [validateMac].
  static String normalizeMac(String mac) =>
      mac.trim().toUpperCase().replaceAll('-', ':');

  /// Fetches everything the page needs: the mode + list, and the connected
  /// devices to populate the picker (mesh nodes excluded by role, as they are
  /// never user-filterable clients).
  Future<MacFilterFetchResult> fetchAll() async {
    try {
      final results = await Future.wait([
        MacFilterNetwork.fetch(_usp),
        ConnectedDevices.fetch(_usp),
      ]);
      final network = results[0] as MacFilterNetwork;
      final devices = results[1] as ConnectedDevices;

      final macs = _parseList(network.macFilterList);

      final connected = devices.items
          .where((d) =>
              !isMeshNodeRole(d.deviceRole) &&
              d.isActive &&
              d.interface_.isNotEmpty &&
              d.macAddress.isNotEmpty)
          .map((d) => MacFilterDeviceUIModel(
                mac: normalizeMac(d.macAddress),
                displayName: d.hostName.isNotEmpty ? d.hostName : d.macAddress,
                isPrivateMac: OuiLookup.isRandomizedMac(d.macAddress),
                ipAddress: d.ipAddress,
              ))
          .toList();

      return MacFilterFetchResult(
        mode: MacFilterMode.fromWire(network.macFilterMode),
        macs: macs,
        connectedDevices: connected,
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Reads the current mode and list. The list leaf is comma-joined with no
  /// spaces (empty string when the list is empty), so split on ',' after
  /// guarding for empty.
  Future<MacFilterData> fetch() async {
    try {
      final raw = await MacFilterNetwork.fetch(_usp);
      return MacFilterData(
        mode: MacFilterMode.fromWire(raw.macFilterMode),
        macs: _parseList(raw.macFilterList),
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Splits the comma-joined `X_LINKSYS_MACFilterList` read-back into MACs,
  /// guarding the empty-string case (which reads as an empty list, not `['']`).
  static List<String> _parseList(String raw) {
    final list = raw.trim();
    if (list.isEmpty) return const [];
    return list
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Sets mode and list atomically. The list is normalized and de-duplicated,
  /// then validated (syntax, count, and the Allow-not-empty rule) before the
  /// write. Throws [InvalidInputError] on a validation failure and never calls
  /// the firmware in that case.
  Future<void> setMacFilter(MacFilterMode mode, List<String> macs) async {
    final normalized = _normalizeAndDedupe(macs);

    if (mode == MacFilterMode.allow && normalized.isEmpty) {
      throw const InvalidInputError(
          detail: 'Allow mode requires at least one address');
    }
    for (final mac in normalized) {
      if (!validateMac(mac)) {
        throw InvalidInputError(detail: 'Invalid MAC address: $mac');
      }
    }
    if (normalized.length > maxAddresses) {
      throw InvalidInputError(
          detail:
              'At most $maxAddresses addresses (${normalized.length} given)');
    }

    try {
      await MacFilterNetworkOperations.setMacFilter(
        _usp,
        mode: mode.wire,
        // Disabled clears the list; the generated wrapper omits the arg on null.
        macAddressList: mode == MacFilterMode.disabled ? null : normalized,
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Normalize every entry and drop duplicates, order-preserving.
  static List<String> _normalizeAndDedupe(List<String> macs) {
    final seen = <String>{};
    final out = <String>[];
    for (final mac in macs) {
      // Normalize only well-formed entries; a malformed one is passed through
      // unchanged so the syntax check below can reject it with its raw text.
      final value = validateMac(mac) ? normalizeMac(mac) : mac.trim();
      if (value.isEmpty || !seen.add(value.toUpperCase())) continue;
      out.add(value);
    }
    return out;
  }
}
