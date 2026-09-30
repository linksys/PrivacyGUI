import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_device_role.dart';
import 'package:privacy_gui/page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

final uspInstantPrivacyServiceProvider = Provider<UspInstantPrivacyService>(
  (ref) => UspInstantPrivacyService(ref.read(uspClientProvider)!),
);

/// Opaque write context for MAC filtering.
///
/// Notifiers and state hold this without knowing how the write is made. Since
/// #1636 the backend is the network-wide `X_LINKSYS_SetMACFilter` (Instant
/// Privacy is that filter in `Allow` mode), so the context carries the current
/// allow-list plus the always-allowed set rather than the dead per-AP
/// `MacFilterAccessPoints` it held before. Only [UspInstantPrivacyService]
/// creates and consumes it.
class MacFilterContext extends Equatable {
  /// The customer-facing allow-list as last read (normalized MACs), without the
  /// always-allowed node MACs — those are unioned in at write time.
  final List<String> _currentMacs;

  /// MACs that every write must keep in the allow-list (REQ-10a) — the mesh's
  /// own nodes, both their host MACs and their backhaul MACs.
  ///
  /// Captured at fetch time and carried here rather than passed by the caller,
  /// because the write methods never see [ConnectedDevices] and because an
  /// invariant a caller can forget is not an invariant. On FLWRT 2.0 this reads
  /// empty (`DeviceRole` was removed, linksys/PrivacyGUI#1612); the union is
  /// kept because it is inert when empty and correct again once node identity
  /// returns.
  final List<String> _alwaysAllowedMacs;

  const MacFilterContext._(this._currentMacs, this._alwaysAllowedMacs);

  /// Empty context for initial state.
  static const empty = MacFilterContext._([], []);

  @override
  List<Object?> get props => [_currentMacs, _alwaysAllowedMacs];
}

/// Fetch result returned by [UspInstantPrivacyService.fetchAll].
class InstantPrivacyFetchResult {
  final bool isEnabled;
  final List<InstantPrivacyDeviceUIModel> connectedDevices;
  final List<InstantPrivacyDeviceUIModel> allowedDevices;
  final MacFilterContext macFilterContext;

  const InstantPrivacyFetchResult({
    required this.isEnabled,
    required this.connectedDevices,
    required this.allowedDevices,
    required this.macFilterContext,
  });
}

/// Service layer for Instant Privacy.
///
/// Since #1636 this is a thin adapter over the shared [UspMacFilterService]:
/// Instant Privacy is the network-wide MAC filter in [MacFilterMode.allow]. The
/// old per-AP `Device.WiFi.AccessPoint.*` write path is gone — it is dead on
/// FLWRT 2.0 (refused with "not configurable for EasyMesh network node"). The
/// public API (`fetchAll`/`enable`/`disable`/`addMac`) is unchanged, so the
/// notifier, state and views are untouched.
class UspInstantPrivacyService {
  final UspClient _usp;

  UspInstantPrivacyService(this._usp);

  UspMacFilterService get _macFilter => UspMacFilterService(_usp);

  // ---------------------------------------------------------------------------
  // Read helpers
  // ---------------------------------------------------------------------------

  /// Filters [data] to the currently active devices shown to the customer, and
  /// maps them to UI models.
  ///
  /// Mesh nodes are excluded explicitly by `DeviceRole` (REQ-10a: a customer
  /// must not be able to block their own mesh node). This list is **display
  /// only** — mesh-node MACs are still written to the firmware allow-list on
  /// every write via [meshNodeMacs] / [meshBackhaulMacs].
  List<InstantPrivacyDeviceUIModel> activeDevices(ConnectedDevices data) {
    return data.items
        .where((d) =>
            !isMeshNodeRole(d.deviceRole) &&
            d.isActive &&
            d.interface_.isNotEmpty)
        .map((d) {
      final mac = normalizeMac(d.macAddress);
      return InstantPrivacyDeviceUIModel(
        mac: mac,
        displayName: d.hostName.isNotEmpty ? d.hostName : mac,
        isPrivateMac: OuiLookup.isRandomizedMac(mac),
        ipAddress: d.ipAddress,
      );
    }).toList();
  }

  /// The nodes' *host* MACs — `Device.Hosts.Host.{i}.PhysAddress` of every row
  /// whose `DeviceRole` marks it as one of the mesh's own nodes (REQ-10a).
  ///
  /// Deliberately does not test [ConnectedDevice.isActive] or the interface: a
  /// node that firmware reports as momentarily down must keep its place in the
  /// allow-list, or it cannot come back.
  List<String> meshNodeMacs(ConnectedDevices data) {
    final seen = <String>{};
    return data.items
        .where((d) => isMeshNodeRole(d.deviceRole))
        .map((d) => d.macAddress)
        .where((m) => m.isNotEmpty)
        .map(normalizeMac)
        .where(seen.add)
        .toList();
  }

  /// The nodes' *backhaul* MACs — the address a node associates with, which is
  /// not its host MAC. Union of the device backhaul MAC and each radio's
  /// backhaul STA MAC (REQ-10a).
  List<String> meshBackhaulMacs(DataElementsNetwork data) {
    final seen = <String>{};
    final out = <String>[];
    for (final node in data.items) {
      final candidates = <String?>[
        node.backhaulBackhaulMacAddress,
        for (final radio in node.radios) radio.backhaulStaMacAddress,
      ];
      for (final mac in candidates) {
        final trimmed = mac?.trim() ?? '';
        if (trimmed.isEmpty || isUnsetMac(trimmed)) continue;
        final normalized = normalizeMac(trimmed);
        if (seen.add(normalized)) out.add(normalized);
      }
    }
    return out;
  }

  /// Whether the filter is currently on (Allow mode).
  bool isEnabled(MacFilterData data) => data.mode == MacFilterMode.allow;

  /// The configured allow-list as UI models (MAC as display name; the fetch
  /// enriches names from the host table).
  List<InstantPrivacyDeviceUIModel> allowedDevices(MacFilterData data) {
    final seen = <String>{};
    return data.macs
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .map(normalizeMac)
        .where(seen.add)
        .map((mac) => InstantPrivacyDeviceUIModel(mac: mac, displayName: mac))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  Future<InstantPrivacyFetchResult> fetchAll() async {
    final List<Object> results;
    try {
      results = await Future.wait([
        ConnectedDevices.fetch(_usp),
        _macFilter.fetch(),
        DataElementsNetwork.fetch(_usp),
      ]);
    } on ServiceError {
      // _macFilter.fetch() already maps to ServiceError — preserve its type.
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final devices = results[0] as ConnectedDevices;
    final filter = results[1] as MacFilterData;
    final network = results[2] as DataElementsNetwork;

    final active = activeDevices(devices);
    final nodeMacSet = <String>{
      ...meshNodeMacs(devices),
      ...meshBackhaulMacs(network),
    };
    final nodeMacs = nodeMacSet.toList();

    final hostnameByMac = {
      for (final d in devices.items)
        if (d.macAddress.isNotEmpty)
          normalizeMac(d.macAddress):
              d.hostName.isNotEmpty ? d.hostName : normalizeMac(d.macAddress),
    };

    // The allow-list minus the node MACs (which are always on the wire but must
    // not render as customer rows — a backhaul MAC has no hostname), enriched
    // with hostnames where known.
    final visibleMacs =
        filter.macs.map(normalizeMac).where((m) => !nodeMacSet.contains(m));
    final allowed = visibleMacs.map((mac) {
      return InstantPrivacyDeviceUIModel(
        mac: mac,
        displayName: hostnameByMac[mac] ?? mac,
        isPrivateMac: OuiLookup.isRandomizedMac(mac),
      );
    }).toList();

    return InstantPrivacyFetchResult(
      isEnabled: isEnabled(filter),
      connectedDevices: active,
      allowedDevices: allowed,
      // The context's "current" list excludes node MACs — they are re-unioned
      // at write time from _alwaysAllowedMacs.
      macFilterContext: MacFilterContext._(
        filter.macs
            .map(normalizeMac)
            .where((m) => !nodeMacSet.contains(m))
            .toList(),
        nodeMacs,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Writes — delegate to the shared MAC filter service (Allow mode)
  // ---------------------------------------------------------------------------

  /// Enable Instant Privacy with the given whitelist. Writes Allow mode with the
  /// customer's MACs plus the always-allowed node MACs (REQ-10a).
  Future<void> enable(List<String> macs, MacFilterContext ctx) async {
    await _macFilter.setMacFilter(
      MacFilterMode.allow,
      _union(macs, ctx._alwaysAllowedMacs),
    );
  }

  /// Disable Instant Privacy — turn the whole filter off.
  Future<void> disable(MacFilterContext ctx) async {
    await _macFilter.setMacFilter(MacFilterMode.disabled, const []);
  }

  /// Add a MAC to the allow-list. Returns true if added, false if already
  /// present (no write made).
  Future<bool> addMac(String mac, MacFilterContext ctx) async {
    final normalized = normalizeMac(mac);
    final present = ctx._currentMacs
        .map((m) => m.toUpperCase())
        .contains(normalized.toUpperCase());
    if (present) return false;
    await _macFilter.setMacFilter(
      MacFilterMode.allow,
      _union([...ctx._currentMacs, normalized], ctx._alwaysAllowedMacs),
    );
    return true;
  }

  /// Union two MAC lists, normalized and de-duplicated, [macs] first so the
  /// customer-visible order is preserved. Mirrors the old `_withAlwaysAllowed`.
  static List<String> _union(List<String> macs, List<String> alwaysAllowed) {
    final seen = <String>{};
    final out = <String>[];
    for (final mac in [...macs, ...alwaysAllowed]) {
      final normalized = normalizeMac(mac);
      if (normalized.isEmpty) continue;
      if (seen.add(normalized.toUpperCase())) out.add(normalized);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // MAC address utilities (delegated so callers keep one import)
  // ---------------------------------------------------------------------------

  static bool validateMac(String mac) => UspMacFilterService.validateMac(mac);

  static String normalizeMac(String mac) =>
      UspMacFilterService.normalizeMac(mac);
}
