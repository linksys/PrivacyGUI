import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'mascot_trigger.dart';
import 'trigger_definitions.dart';

/// Provider for the mascot trigger system.
///
/// Listens to SSE events and fires mascot notifications based on
/// predefined trigger conditions. Features:
/// - Cooldown management (prevents spam)
/// - Priority ordering (critical events interrupt)
/// - State change detection (only triggers on actual changes)
final mascotTriggerProvider =
    NotifierProvider.autoDispose<MascotTriggerNotifier, MascotTriggerState>(
  MascotTriggerNotifier.new,
);

/// State for the trigger system.
class MascotTriggerState {
  /// The most recently triggered event (for external consumption).
  final MascotTrigger? lastTrigger;

  /// Timestamp of the last trigger.
  final DateTime? lastTriggerTime;

  /// Previous WAN status for change detection.
  final bool? previousWanUp;

  /// Previous device count for change detection.
  final int? previousDeviceCount;

  /// Previous firewall status for change detection.
  final bool? previousFirewallEnabled;

  /// Previous disabled WiFi radios for change detection.
  final Set<String>? previousDisabledRadios;

  const MascotTriggerState({
    this.lastTrigger,
    this.lastTriggerTime,
    this.previousWanUp,
    this.previousDeviceCount,
    this.previousFirewallEnabled,
    this.previousDisabledRadios,
  });

  MascotTriggerState copyWith({
    MascotTrigger? lastTrigger,
    DateTime? lastTriggerTime,
    bool? previousWanUp,
    int? previousDeviceCount,
    bool? previousFirewallEnabled,
    Set<String>? previousDisabledRadios,
  }) {
    return MascotTriggerState(
      lastTrigger: lastTrigger ?? this.lastTrigger,
      lastTriggerTime: lastTriggerTime ?? this.lastTriggerTime,
      previousWanUp: previousWanUp ?? this.previousWanUp,
      previousDeviceCount: previousDeviceCount ?? this.previousDeviceCount,
      previousFirewallEnabled:
          previousFirewallEnabled ?? this.previousFirewallEnabled,
      previousDisabledRadios:
          previousDisabledRadios ?? this.previousDisabledRadios,
    );
  }
}

class MascotTriggerNotifier extends AutoDisposeNotifier<MascotTriggerState> {
  final _cooldownState = TriggerCooldownState();
  Timer? _debounceTimer;

  /// External callback for firing triggers.
  ///
  /// Set by [MascotCoordinatorNotifier] to wire into the mascot controller.
  void Function(MascotTrigger)? onTrigger;

  @override
  MascotTriggerState build() {
    _listenToSseEvents();
    _initializeState();

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cooldownState.clearAll();
    });

    return const MascotTriggerState();
  }

  void _initializeState() {
    final isDashboardReady = ref.read(dashboardDomainReadyProvider).hasValue;
    if (!isDashboardReady) return;

    // Capture initial state for change detection
    final wan = ref.read(wanDataProvider).valueOrNull;
    final devices = ref.read(devicesDataProvider).valueOrNull;
    final firewall = ref.read(firewallDataProvider).valueOrNull;
    final wifi = ref.read(wifiDataProvider).valueOrNull;

    final disabledRadios =
        wifi?.radioModels.where((r) => !r.enable).map((r) => r.band).toSet();

    state = MascotTriggerState(
      previousWanUp: wan?.model.isUp,
      previousDeviceCount: devices?.deviceModels.length,
      previousFirewallEnabled: firewall?.firewallModel.isIPv4FirewallEnabled,
      previousDisabledRadios: disabledRadios,
    );
  }

  void _listenToSseEvents() {
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain != null &&
          TriggerDomainMapping.canTriggerNotification(domain)) {
        _debouncedEvaluate(domain);
      }
    });
  }

  void _debouncedEvaluate(InvalidationDomain domain) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _evaluateTriggers(domain);
    });
  }

  void _evaluateTriggers(InvalidationDomain domain) {
    final triggers = <MascotTrigger>[];

    switch (domain) {
      case InvalidationDomain.wanStatus:
        final wanTrigger = _evaluateWanStatus();
        if (wanTrigger != null) triggers.add(wanTrigger);
        break;

      case InvalidationDomain.connectedDevices:
        final deviceTrigger = _evaluateDeviceChanges();
        if (deviceTrigger != null) triggers.add(deviceTrigger);
        break;

      case InvalidationDomain.firewallRules:
      case InvalidationDomain.dmz:
        final firewallTrigger = _evaluateFirewallChanges();
        if (firewallTrigger != null) triggers.add(firewallTrigger);
        break;

      case InvalidationDomain.wifiRadios:
        final wifiTrigger = _evaluateWifiChanges();
        if (wifiTrigger != null) triggers.add(wifiTrigger);
        break;

      default:
        break;
    }

    // Sort by priority (lower = higher priority)
    triggers.sort((a, b) => a.priority.compareTo(b.priority));

    // Fire highest priority trigger that isn't in cooldown
    for (final trigger in triggers) {
      if (!_cooldownState.isInCooldown(trigger)) {
        _fireTrigger(trigger);
        break;
      }
    }
  }

  MascotTrigger? _evaluateWanStatus() {
    final wan = ref.read(wanDataProvider).valueOrNull;
    if (wan == null) return null;

    final currentUp = wan.model.isUp;
    final previousUp = state.previousWanUp;

    // Update state for next comparison
    state = state.copyWith(previousWanUp: currentUp);

    // Only trigger on actual state change
    if (previousUp == null) return null;
    if (currentUp == previousUp) return null;

    if (!currentUp) {
      debugPrint('[Mascot][Trigger]: WAN went down');
      return TriggerDefinitions.wanDown();
    } else {
      debugPrint('[Mascot][Trigger]: WAN restored');
      return TriggerDefinitions.wanRestored();
    }
  }

  MascotTrigger? _evaluateDeviceChanges() {
    final devices = ref.read(devicesDataProvider).valueOrNull;
    if (devices == null) return null;

    final currentCount = devices.deviceModels.length;
    final previousCount = state.previousDeviceCount;

    // Update state for next comparison
    state = state.copyWith(previousDeviceCount: currentCount);

    // Only trigger when new device joins (count increases)
    if (previousCount == null) return null;
    if (currentCount <= previousCount) return null;

    // Find the newest device (last in list by convention)
    final newDevice = devices.deviceModels.isNotEmpty
        ? (devices.deviceModels.last.hostName.isNotEmpty
            ? devices.deviceModels.last.hostName
            : devices.deviceModels.last.mac)
        : 'Unknown device';

    debugPrint('[Mascot][Trigger]: New device joined — $newDevice');
    return TriggerDefinitions.newDeviceJoined(newDevice);
  }

  MascotTrigger? _evaluateFirewallChanges() {
    final firewall = ref.read(firewallDataProvider).valueOrNull;
    if (firewall == null) return null;

    final currentEnabled = firewall.firewallModel.isIPv4FirewallEnabled;
    final previousEnabled = state.previousFirewallEnabled;

    // Update state for next comparison
    state = state.copyWith(previousFirewallEnabled: currentEnabled);

    // Only trigger when firewall becomes disabled
    if (previousEnabled == null) return null;
    if (currentEnabled || !previousEnabled) return null;

    debugPrint('[Mascot][Trigger]: Firewall disabled');
    return TriggerDefinitions.firewallDisabled();
  }

  MascotTrigger? _evaluateWifiChanges() {
    final wifi = ref.read(wifiDataProvider).valueOrNull;
    if (wifi == null) return null;

    final currentDisabled =
        wifi.radioModels.where((r) => !r.enable).map((r) => r.band).toSet();
    final previousDisabled = state.previousDisabledRadios;

    // Update state for next comparison
    state = state.copyWith(previousDisabledRadios: currentDisabled);

    // Only trigger on actual state change (newly disabled radios)
    if (previousDisabled == null) return null;

    final newlyDisabled = currentDisabled.difference(previousDisabled);
    if (newlyDisabled.isEmpty) return null;

    final band = newlyDisabled.first;
    debugPrint('[Mascot][Trigger]: WiFi radio disabled — $band');
    return TriggerDefinitions.wifiRadioDisabled(band);
  }

  void _fireTrigger(MascotTrigger trigger) {
    _cooldownState.recordTrigger(trigger);

    state = state.copyWith(
      lastTrigger: trigger,
      lastTriggerTime: DateTime.now(),
    );

    debugPrint('[Mascot][Trigger]: Firing trigger — ${trigger.id}');

    onTrigger?.call(trigger);
  }

  /// Manually fire a trigger (for testing or external use).
  void manualTrigger(MascotTrigger trigger) {
    if (!_cooldownState.isInCooldown(trigger)) {
      _fireTrigger(trigger);
    }
  }

  /// Clear all cooldowns (for testing).
  void clearCooldowns() {
    _cooldownState.clearAll();
  }
}

/// Extension to convert [MascotTrigger] to [MascotDialogNode].
extension TriggerToDialogNode on MascotTrigger {
  MascotDialogNode toDialogNode() {
    return MascotDialogNode(
      id: 'trigger_$id',
      text: message,
      autoHide: true,
      autoHideDuration: autoHideDuration,
      showDismissButton: priority <= TriggerPriority.high,
      suggestedAnimation: animation,
    );
  }
}
