import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/mac_filter_access_points.g.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_device_role.dart';
import 'package:privacy_gui/page/instant_privacy/models/instant_privacy_device_ui_model.dart';

final uspInstantPrivacyServiceProvider = Provider<UspInstantPrivacyService>(
  (ref) => UspInstantPrivacyService(ref.read(uspClientProvider)!),
);

/// Opaque write context for MAC filtering.
///
/// Notifiers and state hold this without knowing the inner codegen type.
/// Only [UspInstantPrivacyService] can create and consume it.
class MacFilterContext extends Equatable {
  final MacFilterAccessPoints _data;

  /// MACs that every write must keep in the allow-list (REQ-10a) — the mesh's
  /// own nodes.
  ///
  /// Captured at fetch time and carried here rather than passed by the caller,
  /// because the write methods never see [ConnectedDevices] and because an
  /// invariant a caller can forget is not an invariant.
  final List<String> _alwaysAllowedMacs;

  const MacFilterContext._(this._data, this._alwaysAllowedMacs);

  /// Empty context for initial state.
  static const empty = MacFilterContext._(
    MacFilterAccessPoints(items: []),
    [],
  );

  @override
  List<Object?> get props => [_data.items.length, _alwaysAllowedMacs];
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

/// Service layer for Instant Privacy — encapsulates codegen CRUD + transform.
class UspInstantPrivacyService {
  final UspClient _usp;

  UspInstantPrivacyService(this._usp);
  static final _macRegExp = RegExp(
    r'^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$',
  );

  // ---------------------------------------------------------------------------
  // Read helpers
  // ---------------------------------------------------------------------------

  /// Filters [data] to the currently active devices shown to the customer, and
  /// maps them to UI models.
  ///
  /// Mesh nodes are excluded explicitly by `DeviceRole` (REQ-10a: a customer
  /// must not be able to block their own mesh node), so a node never becomes a
  /// customer-facing row. The exclusion is by role, not a side effect of
  /// [ConnectedDevice.isActive] or an empty interface, so it keeps working after
  /// the firmware node-row PhysAddress fix (FWDEV#166) gives node rows a real
  /// MAC, interface, and truthful Active.
  ///
  /// This list is **display only**. Mesh-node MACs are still written to the
  /// firmware allow-list on every write — see [meshNodeMacs]. On an
  /// allow-list-mode MAC filter an absent MAC is a denied MAC, so dropping a
  /// node here *and* on the wire would lock the customer's own node out of its
  /// network, which is the other half of REQ-10a.
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
      );
    }).toList();
  }

  /// The MACs of the mesh's own nodes, which must always be in the allow-list.
  ///
  /// REQ-10a — "Nodes can never be locked out": device-blocking features always
  /// include the mesh's own nodes. 1.x does the same union at write time
  /// (`InstantPrivacyNotifier.save()` on `main`); this is the 2.x equivalent.
  ///
  /// Unlike [activeDevices] this deliberately does **not** test
  /// [ConnectedDevice.isActive] or the interface: a node that firmware reports
  /// as momentarily down must keep its place in the allow-list, or it cannot
  /// come back.
  List<String> meshNodeMacs(ConnectedDevices data) {
    final macs = <String>{};
    for (final d in data.items) {
      if (!isMeshNodeRole(d.deviceRole)) continue;
      if (d.macAddress.trim().isEmpty) continue;
      macs.add(normalizeMac(d.macAddress));
    }
    return macs.toList();
  }

  /// Returns true if any AP in [data] has MAC filtering enabled.
  bool isEnabled(MacFilterAccessPoints data) {
    return data.items.any((ap) => ap.macAddressControlEnabled);
  }

  /// Parses the current allowed MAC list from [data] and converts to UI models.
  ///
  /// Uses the first AP's [allowedMACAddress] as the source (all APs share the
  /// same list). Deduplicates by MAC address.
  List<InstantPrivacyDeviceUIModel> allowedDevices(MacFilterAccessPoints data) {
    if (data.items.isEmpty) return [];
    final raw = data.items.first.allowedMACAddress;
    final seen = <String>{};
    return raw
        .split(',')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .map(normalizeMac)
        .where(seen.add)
        .map((mac) => InstantPrivacyDeviceUIModel(mac: mac, displayName: mac))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Write helpers — build update descriptors for MacFilterAccessPoints.updateMany()
  // ---------------------------------------------------------------------------

  /// Unions [macs] with [alwaysAllowedMacs] — normalized, de-duplicated, and in
  /// order, with [macs] first so the customer-visible list reads unchanged.
  static List<String> _withAlwaysAllowed(
    List<String> macs,
    List<String> alwaysAllowedMacs,
  ) {
    final seen = <String>{};
    final result = <String>[];
    for (final mac in [...macs, ...alwaysAllowedMacs]) {
      final normalized = normalizeMac(mac);
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) result.add(normalized);
    }
    return result;
  }

  /// Builds update descriptors to ENABLE MAC filtering on all APs.
  ///
  /// Sets [macAddressControlEnabled] = true and [allowedMACAddress] to the
  /// comma-joined [macs] list on every AP instance in [data].
  ///
  /// [alwaysAllowedMacs] (the mesh's own nodes — see [meshNodeMacs]) is unioned
  /// in unconditionally. REQ-10a: whatever the customer's snapshot contains, the
  /// written allow-list always contains the nodes, because a node whose MAC is
  /// missing from an allow-list-mode filter is a node denied its own network.
  List<MacFilterAccessPointUpdate> buildEnableUpdates(
    List<String> macs,
    MacFilterAccessPoints data, {
    List<String> alwaysAllowedMacs = const [],
  }) {
    final macList = _withAlwaysAllowed(macs, alwaysAllowedMacs).join(',');
    return data.items
        .map((ap) => MacFilterAccessPointUpdate(
              instancePath: ap.instancePath,
              macAddressControlEnabled: true,
              allowedMACAddress: macList,
            ))
        .toList();
  }

  /// Builds update descriptors to DISABLE MAC filtering on all APs.
  ///
  /// Sets [macAddressControlEnabled] = false and clears [allowedMACAddress]
  /// on every AP instance in [data].
  List<MacFilterAccessPointUpdate> buildDisableUpdates(
      MacFilterAccessPoints data) {
    return data.items
        .map((ap) => MacFilterAccessPointUpdate(
              instancePath: ap.instancePath,
              macAddressControlEnabled: false,
              allowedMACAddress: '',
            ))
        .toList();
  }

  /// Builds update descriptors to ADD [newMac] to the existing allowed list.
  ///
  /// Reads the current list from the first AP (all APs share the same list),
  /// appends [newMac] if not already present, and updates every AP.
  /// Precondition: [newMac] is already validated and normalized.
  ///
  /// [alwaysAllowedMacs] is unioned in for the same reason as in
  /// [buildEnableUpdates] — every write keeps the mesh's nodes allowed, not just
  /// the enable snapshot. Whether [newMac] was already present is still decided
  /// by the stored list alone, so the return contract is unchanged.
  List<MacFilterAccessPointUpdate> buildAddMacUpdates(
    String newMac,
    MacFilterAccessPoints data, {
    List<String> alwaysAllowedMacs = const [],
  }) {
    if (data.items.isEmpty) return [];

    final existing = data.items.first.allowedMACAddress
        .split(',')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .map(normalizeMac)
        .toList();

    if (existing.contains(newMac)) return [];

    final updated =
        _withAlwaysAllowed([...existing, newMac], alwaysAllowedMacs).join(',');
    return data.items
        .map((ap) => MacFilterAccessPointUpdate(
              instancePath: ap.instancePath,
              macAddressControlEnabled: true,
              allowedMACAddress: updated,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // High-level CRUD (for Notifier consumption)
  // ---------------------------------------------------------------------------

  /// Fetch all data needed for Instant Privacy and return UI-safe result.
  Future<InstantPrivacyFetchResult> fetchAll() async {
    final List<Object> results;
    try {
      results = await Future.wait([
        ConnectedDevices.fetch(_usp),
        MacFilterAccessPoints.fetch(_usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final devices = results[0] as ConnectedDevices;
    final macAps = results[1] as MacFilterAccessPoints;

    final active = activeDevices(devices);
    final nodeMacs = meshNodeMacs(devices);

    // Build a MAC → hostname lookup from all known hosts (active + inactive)
    final hostnameByMac = {
      for (final d in devices.items)
        if (d.macAddress.isNotEmpty)
          normalizeMac(d.macAddress):
              d.hostName.isNotEmpty ? d.hostName : normalizeMac(d.macAddress),
    };

    // Allowed list shows all whitelisted MACs with hostname if known, else MAC.
    // Mesh nodes are always on the wire (REQ-10a) but stay out of both
    // customer-facing lists, so they are hidden here too — matching 1.x
    // (`instantPrivacyDeviceListProvider` on `main`).
    final allowed =
        allowedDevices(macAps).where((d) => !nodeMacs.contains(d.mac)).map((d) {
      final name = hostnameByMac[d.mac] ?? d.mac;
      return InstantPrivacyDeviceUIModel(
        mac: d.mac,
        displayName: name,
        isPrivateMac: OuiLookup.isRandomizedMac(d.mac),
      );
    }).toList();

    return InstantPrivacyFetchResult(
      isEnabled: isEnabled(macAps),
      connectedDevices: active,
      allowedDevices: allowed,
      macFilterContext: MacFilterContext._(macAps, nodeMacs),
    );
  }

  /// Enable MAC filtering on all APs with the given MAC whitelist.
  Future<void> enable(List<String> macs, MacFilterContext ctx) async {
    try {
      final updates = buildEnableUpdates(
        macs,
        ctx._data,
        alwaysAllowedMacs: ctx._alwaysAllowedMacs,
      );
      if (updates.isNotEmpty) {
        final result = await MacFilterAccessPoints.update(_usp, updates);
        final parsed = UspResultParser.parseSetResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(
              :final errorSummary,
              :final successes,
              :final failures
            ):
            throw UspPartialFailureError(
              summary: 'MAC filter enable partial failure: $errorSummary',
              successPaths: successes.map((s) => s.requestedPath).toList(),
              failures: failures,
            );
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'MAC filter enable failed: $errorSummary',
              failures: errors,
            );
        }
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Disable MAC filtering on all APs.
  Future<void> disable(MacFilterContext ctx) async {
    try {
      final updates = buildDisableUpdates(ctx._data);
      if (updates.isNotEmpty) {
        final result = await MacFilterAccessPoints.update(_usp, updates);
        final parsed = UspResultParser.parseSetResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(
              :final errorSummary,
              :final successes,
              :final failures
            ):
            throw UspPartialFailureError(
              summary: 'MAC filter disable partial failure: $errorSummary',
              successPaths: successes.map((s) => s.requestedPath).toList(),
              failures: failures,
            );
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'MAC filter disable failed: $errorSummary',
              failures: errors,
            );
        }
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Add a MAC address to the allowed list across all APs.
  /// Returns true if the MAC was added, false if already present.
  Future<bool> addMac(String mac, MacFilterContext ctx) async {
    try {
      final updates = buildAddMacUpdates(
        mac,
        ctx._data,
        alwaysAllowedMacs: ctx._alwaysAllowedMacs,
      );
      if (updates.isEmpty) return false;
      final result = await MacFilterAccessPoints.update(_usp, updates);
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          return true;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'MAC filter add partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'MAC filter add failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // MAC address utilities
  // ---------------------------------------------------------------------------

  /// Returns true if [mac] matches colon-separated or hyphen-separated hex format.
  static bool validateMac(String mac) => _macRegExp.hasMatch(mac.trim());

  /// Converts [mac] to uppercase colon-separated canonical form.
  /// Precondition: [mac] passes [validateMac].
  static String normalizeMac(String mac) =>
      mac.trim().toUpperCase().replaceAll('-', ':');
}
