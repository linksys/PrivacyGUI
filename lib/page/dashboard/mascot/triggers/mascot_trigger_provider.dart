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

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cooldownState.clearAll();
    });

    return _seedBaseline();
  }

  /// Captures the current router state as the baseline for change detection.
  ///
  /// Must be **returned** from [build] rather than assigned to `state`:
  /// riverpod applies `build()`'s return value *after* the body has run
  /// (`setState(provider.runNotifierBuild(notifier))`,
  /// riverpod-2.6.1/lib/src/notifier/base.dart:212; 3.4.3 does the same at
  /// providers/notifier.dart:94), so an in-build `state = …` is silently
  /// discarded — it compiles clean and analyze says nothing. That is the #1509
  /// defect: every `previousXxx` stayed null, so each `_evaluateXxx` hit its
  /// `previous == null` early return and the first SSE event per domain could
  /// only seed, never fire.
  MascotTriggerState _seedBaseline() {
    final isDashboardReady = ref.read(dashboardDomainReadyProvider).hasValue;
    if (!isDashboardReady) return const MascotTriggerState();

    final wan = ref.read(wanDataProvider).valueOrNull;
    final devices = ref.read(devicesDataProvider).valueOrNull;
    final firewall = ref.read(firewallDataProvider).valueOrNull;
    final wifi = ref.read(wifiDataProvider).valueOrNull;

    final disabledRadios =
        wifi?.radioModels.where((r) => !r.enable).map((r) => r.band).toSet();

    return MascotTriggerState(
      previousWanUp: wan?.model.isUp,
      previousDeviceCount: devices?.clientDevices.length,
      previousFirewallEnabled: firewall?.firewallModel.isIPv4FirewallEnabled,
      previousDisabledRadios: disabledRadios,
    );
  }

  void _listenToSseEvents() {
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull?.domain;
      if (domain != null &&
          TriggerDomainMapping.canTriggerNotification(domain)) {
        _fillMissingBaseline();
        _debouncedEvaluate(domain);
      }
    });
  }

  /// True once every domain has something to compare against.
  bool get _hasCompleteBaseline =>
      state.previousWanUp != null &&
      state.previousDeviceCount != null &&
      state.previousFirewallEnabled != null &&
      state.previousDisabledRadios != null;

  /// Captures the pre-event value for any domain [build] could not seed.
  ///
  /// Necessary because `build()` can only capture what is already loaded, and
  /// `dashboardDomainReadyProvider` awaits systemInfo/devices/ethernet only:
  /// `devicesDataProvider` is covered directly and `wifiDataProvider`
  /// transitively (`devices_data_provider.dart:164` awaits it), but
  /// `wanDataProvider` and `firewallDataProvider` are card-driven, so nothing
  /// orders them before the mascot mounts. `firewall_overview` in particular
  /// sits below the fold in every preset. Without this, the first
  /// firewall-disable of a session could go unannounced even with the seed in
  /// place.
  ///
  /// Running it synchronously inside the SSE listener is what makes it a
  /// *pre-event* value: the L1 provider for the domain cannot have refreshed
  /// yet — its own listener merely marks it dirty and the refetch is a USP
  /// round-trip — while `_debouncedEvaluate` reads the new value 500 ms later.
  /// Even against an already-invalidated provider the refreshing frame is
  /// `AsyncData(previous, isLoading: true)`, so `valueOrNull` still yields the
  /// old value. (`build()`'s reads are also what *start* those card-driven
  /// fetches, so by the time any SSE event arrives the data is normally there.)
  void _fillMissingBaseline() {
    if (_hasCompleteBaseline) return;

    final baseline = _seedBaseline();
    state = MascotTriggerState(
      lastTrigger: state.lastTrigger,
      lastTriggerTime: state.lastTriggerTime,
      previousWanUp: state.previousWanUp ?? baseline.previousWanUp,
      previousDeviceCount:
          state.previousDeviceCount ?? baseline.previousDeviceCount,
      previousFirewallEnabled:
          state.previousFirewallEnabled ?? baseline.previousFirewallEnabled,
      previousDisabledRadios:
          state.previousDisabledRadios ?? baseline.previousDisabledRadios,
    );
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

    final currentCount = devices.clientDevices.length;
    final previousCount = state.previousDeviceCount;

    // Update state for next comparison
    state = state.copyWith(previousDeviceCount: currentCount);

    // Only trigger when new device joins (count increases)
    if (previousCount == null) return null;
    if (currentCount <= previousCount) return null;

    // Find the newest device (last in list by convention)
    final newDevice = devices.clientDevices.isNotEmpty
        ? (devices.clientDevices.last.hostName.isNotEmpty
            ? devices.clientDevices.last.hostName
            : devices.clientDevices.last.mac)
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
