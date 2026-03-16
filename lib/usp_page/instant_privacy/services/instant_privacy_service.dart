import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/mac_filter_access_points.g.dart';
import 'package:privacy_gui/usp_page/instant_privacy/models/instant_privacy_device_ui_model.dart';

/// Service provider — stateless, per Constitution Article VI.
final uspInstantPrivacyServiceProvider = Provider<UspInstantPrivacyService>(
  (ref) => UspInstantPrivacyService(),
);

/// Stateless transformation service for Instant Privacy.
///
/// Converts codegen data models to UI models and builds update descriptors
/// for MAC filter operations. Contains zero network calls — all USP I/O
/// is performed by [UspInstantPrivacyNotifier].
class UspInstantPrivacyService {
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
  // MAC address utilities
  // ---------------------------------------------------------------------------

  /// Returns true if [mac] matches colon-separated or hyphen-separated hex format.
  bool validateMac(String mac) => _macRegExp.hasMatch(mac.trim());

  /// Converts [mac] to uppercase colon-separated canonical form.
  /// Precondition: [mac] passes [validateMac].
  String normalizeMac(String mac) =>
      mac.trim().toUpperCase().replaceAll('-', ':');
}
