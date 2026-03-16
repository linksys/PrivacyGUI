import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/mac_filter_access_points.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:privacy_gui/usp_page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/usp_page/instant_privacy/services/instant_privacy_service.dart';

final uspInstantPrivacyProvider =
    AsyncNotifierProvider<UspInstantPrivacyNotifier, UspInstantPrivacyState>(
  UspInstantPrivacyNotifier.new,
);

class UspInstantPrivacyNotifier extends AsyncNotifier<UspInstantPrivacyState> {
  UspInstantPrivacyService get _svc =>
      ref.read(uspInstantPrivacyServiceProvider);

  @override
  Future<UspInstantPrivacyState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      ConnectedDevices.fetch(usp),
      MacFilterAccessPoints.fetch(usp),
    ]);

    final devices = results[0] as ConnectedDevices;
    final macAps = results[1] as MacFilterAccessPoints;
    final svc = _svc;

    logger.d('[USP] Instant Privacy fetched — '
        'activeDevices: ${svc.activeDevices(devices).length}, '
        'isEnabled: ${svc.isEnabled(macAps)}');

    final active = svc.activeDevices(devices);

    // Build a MAC → hostname lookup from all known hosts (active + inactive)
    // so that allowed devices shown in the ON state can display friendly names.
    final hostnameByMac = {
      for (final d in devices.items)
        if (d.macAddress.isNotEmpty)
          svc.normalizeMac(d.macAddress):
              d.hostName.isNotEmpty ? d.hostName : svc.normalizeMac(d.macAddress),
    };

    final allowed = svc.allowedDevices(macAps).map((d) {
      final name = hostnameByMac[d.mac] ?? 'Unknown Device';
      return name == d.displayName
          ? d
          : InstantPrivacyDeviceUIModel(mac: d.mac, displayName: name);
    }).toList();

    logger.d('[USP] Instant Privacy fetched — '
        'activeDevices: ${active.length}, '
        'isEnabled: ${svc.isEnabled(macAps)}');

    return UspInstantPrivacyState(
      isEnabled: svc.isEnabled(macAps),
      connectedDevices: active,
      allowedDevices: allowed,
      rawMacFilterAps: macAps,
    );
  }

  /// Enables Instant Privacy by snapshotting currently connected devices
  /// as the MAC whitelist across all APs (atomic, allowPartial: false).
  Future<void> enable() async {
    final s = state.valueOrNull;
    if (s == null || s.isEnabled) return;

    state = AsyncData(s.copyWith(isToggleLocked: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      final macs = s.connectedDevices.map((d) => d.mac).toList();
      final updates = _svc.buildEnableUpdates(macs, s.rawMacFilterAps);
      await MacFilterAccessPoints.updateMany(usp, updates);
      logger.d('[USP] Instant Privacy enabled — ${macs.length} MACs');
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(s.copyWith(isToggleLocked: false));
      rethrow;
    }
  }

  /// Disables Instant Privacy by clearing MAC filtering on all APs (atomic).
  Future<void> disable() async {
    final s = state.valueOrNull;
    if (s == null || !s.isEnabled) return;

    state = AsyncData(s.copyWith(isToggleLocked: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      final updates = _svc.buildDisableUpdates(s.rawMacFilterAps);
      await MacFilterAccessPoints.updateMany(usp, updates);
      logger.d('[USP] Instant Privacy disabled');
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(s.copyWith(isToggleLocked: false));
      rethrow;
    }
  }

  /// Adds [mac] to the allowed list across all APs.
  /// Precondition: [mac] is validated and normalized by the caller.
  Future<void> addMac(String mac) async {
    final s = state.valueOrNull;
    if (s == null || !s.isEnabled) return;

    state = AsyncData(s.copyWith(isToggleLocked: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      final updates = _svc.buildAddMacUpdates(mac, s.rawMacFilterAps);
      if (updates.isEmpty) {
        state = AsyncData(s.copyWith(isToggleLocked: false));
        return;
      }
      await MacFilterAccessPoints.updateMany(usp, updates);
      logger.d('[USP] Instant Privacy addMac — $mac');
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(s.copyWith(isToggleLocked: false));
      rethrow;
    }
  }
}
