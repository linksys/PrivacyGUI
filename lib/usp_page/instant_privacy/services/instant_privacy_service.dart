import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/mac_filter_access_points.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/instant_privacy/models/instant_privacy_device_ui_model.dart';

final uspInstantPrivacyServiceProvider = Provider<UspInstantPrivacyService>(
  (ref) => UspInstantPrivacyService(ref.read(uspServiceProvider)!),
);

/// Opaque wrapper around MAC filter AP data.
///
/// Notifiers and state hold this without knowing the inner codegen type.
/// Only [UspInstantPrivacyService] can create and consume it.
class MacFilterContext extends Equatable {
  final MacFilterAccessPoints _data;
  const MacFilterContext._(this._data);

  /// Empty context for initial state.
  static const empty = MacFilterContext._(MacFilterAccessPoints(items: []));

  @override
  List<Object?> get props => [_data.items.length];
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
  final UspService _usp;

  UspInstantPrivacyService(this._usp);
  static final _macRegExp = RegExp(
    r'^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$',
  );

  // ---------------------------------------------------------------------------
  // Read helpers
  // ---------------------------------------------------------------------------

  /// Filters [data] to only currently active devices and maps to UI models.
  List<InstantPrivacyDeviceUIModel> activeDevices(ConnectedDevices data) {
    return data.items
        .where((d) => d.isActive && d.interface_.isNotEmpty)
        .map((d) {
      final mac = normalizeMac(d.macAddress);
      return InstantPrivacyDeviceUIModel(
        mac: mac,
        displayName: d.hostName.isNotEmpty ? d.hostName : mac,
      );
    }).toList();
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

  /// Builds update descriptors to ENABLE MAC filtering on all APs.
  ///
  /// Sets [macAddressControlEnabled] = true and [allowedMACAddress] to the
  /// comma-joined [macs] list on every AP instance in [data].
  List<MacFilterAccessPointUpdate> buildEnableUpdates(
    List<String> macs,
    MacFilterAccessPoints data,
  ) {
    final macList = macs.join(',');
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
  List<MacFilterAccessPointUpdate> buildAddMacUpdates(
    String newMac,
    MacFilterAccessPoints data,
  ) {
    if (data.items.isEmpty) return [];

    final existing = data.items.first.allowedMACAddress
        .split(',')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .map(normalizeMac)
        .toList();

    if (existing.contains(newMac)) return [];

    final updated = [...existing, newMac].join(',');
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
    final results = await Future.wait([
      ConnectedDevices.fetch(_usp),
      MacFilterAccessPoints.fetch(_usp),
    ]);

    final devices = results[0] as ConnectedDevices;
    final macAps = results[1] as MacFilterAccessPoints;

    final active = activeDevices(devices);

    // Build a MAC → hostname lookup from all known hosts (active + inactive)
    final hostnameByMac = {
      for (final d in devices.items)
        if (d.macAddress.isNotEmpty)
          normalizeMac(d.macAddress): d.hostName.isNotEmpty
              ? d.hostName
              : normalizeMac(d.macAddress),
    };

    final allowed = allowedDevices(macAps).map((d) {
      final name = hostnameByMac[d.mac] ?? 'Unknown Device';
      return name == d.displayName
          ? d
          : InstantPrivacyDeviceUIModel(mac: d.mac, displayName: name);
    }).toList();

    return InstantPrivacyFetchResult(
      isEnabled: isEnabled(macAps),
      connectedDevices: active,
      allowedDevices: allowed,
      macFilterContext: MacFilterContext._(macAps),
    );
  }

  /// Enable MAC filtering on all APs with the given MAC whitelist.
  Future<void> enable(List<String> macs, MacFilterContext ctx) async {
    final updates = buildEnableUpdates(macs, ctx._data);
    await MacFilterAccessPoints.updateMany(_usp, updates);
  }

  /// Disable MAC filtering on all APs.
  Future<void> disable(MacFilterContext ctx) async {
    final updates = buildDisableUpdates(ctx._data);
    await MacFilterAccessPoints.updateMany(_usp, updates);
  }

  /// Add a MAC address to the allowed list across all APs.
  /// Returns true if the MAC was added, false if already present.
  Future<bool> addMac(String mac, MacFilterContext ctx) async {
    final updates = buildAddMacUpdates(mac, ctx._data);
    if (updates.isEmpty) return false;
    await MacFilterAccessPoints.updateMany(_usp, updates);
    return true;
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
