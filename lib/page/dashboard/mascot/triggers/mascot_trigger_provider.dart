import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// Listens to the four L1 domain providers and fires mascot notifications based
/// on predefined trigger conditions. Features:
/// - Cooldown management (prevents spam)
/// - State change detection (only triggers on actual changes)
///
/// Value-driven rather than SSE-driven on purpose — see [_listenToDomainData].
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

  /// External callback for firing triggers.
  ///
  /// Set by [MascotCoordinatorNotifier] to wire into the mascot controller.
  void Function(MascotTrigger)? onTrigger;

  @override
  MascotTriggerState build() {
    _listenToDomainData();

    ref.onDispose(_cooldownState.clearAll);

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
  /// `previous == null` early return and the first change per domain could only
  /// seed, never fire.
  ///
  /// Only captures what is already loaded, which is enough:
  /// `dashboardDomainReadyProvider` awaits systemInfo/devices/ethernet only, so
  /// `wanDataProvider` and `firewallDataProvider` (both card-driven, and
  /// `firewall_overview` sits below the fold in every preset) can still be in
  /// flight here. The `ref.read`s below *start* those fetches, and
  /// [_listenToDomainData] seeds each of them from its first settled value.
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

  /// Evaluates each domain when *its own* L1 provider publishes a settled value.
  ///
  /// Deliberately **not** driven by `sseInvalidationProvider`. Every L1 provider
  /// the mascot reads debounces its own SSE-triggered refetch by 500 ms
  /// (`firewall_data_provider.dart:137-141`, `wifi_data_provider.dart:109-112`,
  /// `devices_data_provider.dart:246-249`), so a mascot-side timer can only ever
  /// read the *pre-change* value: at T+500 the refetch has merely been *started*
  /// and the USP round-trip is still in flight. Measured with a 500 ms
  /// mascot-side debounce — `firewallRules`, `wifiRadios` and `connectedDevices`
  /// all compared the baseline against the unchanged value, fired nothing, and
  /// committed the stale value back as the baseline; only `wanStatus` worked,
  /// because `wan_data_provider.dart:49-51` invalidates with no debounce.
  /// Reacting to the value instead of to the clock takes 500 ms out of the
  /// correctness argument altogether, and drops the shared debounce timer that
  /// used to let one domain's event cancel another's pending evaluation.
  void _listenToDomainData() {
    ref.listen(
        wanDataProvider, (_, next) => _onDomainData(next, _evaluateWanStatus));
    ref.listen(devicesDataProvider,
        (_, next) => _onDomainData(next, _evaluateDeviceChanges));
    ref.listen(firewallDataProvider,
        (_, next) => _onDomainData(next, _evaluateFirewallChanges));
    ref.listen(wifiDataProvider,
        (_, next) => _onDomainData(next, _evaluateWifiChanges));
  }

  /// Runs [evaluate] once per settled frame, and announces what it returns.
  ///
  /// The `isLoading` guard skips the re-run frame: `invalidateSelf()`
  /// republishes the *previous* value with `isLoading` set, so evaluating on it
  /// would compare the baseline against itself and then commit that stale value
  /// as the new baseline — losing the change for good. Same guard and same
  /// reason as `devices_data_provider.dart:128-131`; see
  /// `doc/riverpod/listen_site_audit.md`. Error frames are skipped for the same
  /// reason: `AsyncError` carries the previous value forward.
  ///
  /// Each `_evaluateXxx` compares against the stored baseline *before*
  /// overwriting it, so these four sites are edge-triggered by construction and
  /// unaffected by riverpod 3 collapsing two equal `AsyncData` frames into one
  /// notification (#1512 P2) — the suppressed frame carried no delta anyway.
  void _onDomainData(
    AsyncValue<Object?> next,
    MascotTrigger? Function() evaluate,
  ) {
    if (next.isLoading || next.hasError || !next.hasValue) return;

    final trigger = evaluate();
    if (trigger == null) return;
    if (_cooldownState.isInCooldown(trigger)) return;

    _fireTrigger(trigger);
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
