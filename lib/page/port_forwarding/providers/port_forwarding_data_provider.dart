import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_data_service.dart';

/// Shared data provider for Port Forwarding rules.
///
/// NOT autoDispose — persists across tab switches.
/// SSE: listens for [InvalidationDomain.portForwarding].
final portForwardingDataProvider =
    AsyncNotifierProvider<PortForwardingDataNotifier, PortForwardingData>(
  PortForwardingDataNotifier.new,
);

class PortForwardingData extends Equatable with DiagnosticLoggable {
  final List<PortForwardingRuleUIModel> ruleModels;

  const PortForwardingData({
    required this.ruleModels,
  });

  @override
  String get diagnosticName => 'PortForwardingData';

  @override
  Map<String, Object?> get namedProps => {'ruleModels': ruleModels};
}

class PortForwardingDataNotifier extends AsyncNotifier<PortForwardingData> {
  Timer? _debounce;

  @override
  Future<PortForwardingData> build() async {
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull?.domain;
      if (domain == InvalidationDomain.portForwarding) {
        _debounce?.cancel();
        _debounce =
            Timer(const Duration(milliseconds: 500), () => _refreshFromPush());
      }
    });
    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  /// Re-read the device and publish the result, WITHOUT depending on anyone reading this
  /// provider afterwards.
  ///
  /// WHY NOT `invalidateSelf()` — linksys/PrivacyGUI#1615. That call discards the state
  /// and marks the provider for rebuild; riverpod runs `build()` again **when something
  /// reads the provider**. When the debounce timer fires with no reader:
  ///
  ///   - `build()` does not run, so no re-fetch happens, and
  ///   - the `ref.listen` above — which lives INSIDE `build()` — is not re-registered,
  ///     so the NEXT notification does not even reach a listener.
  ///
  /// So the first matching notification disables the mechanism. Measured: a held
  /// subscriber gave 1 fetch → 2 after a `portForwarding` event; no subscriber, 1 → 1.
  ///
  /// WAS THIS REACHABLE? **No, and for a more basic reason than the subscriber question.**
  /// `portForwarding` is produced only from `Device.NAT.PortMapping.`
  /// (`sse_invalidation_provider.dart`), which is NOT among the five paths the app
  /// subscribes to (`lib/generated/subscriptions.g.dart`) — so the notification never
  /// arrives, and whether anything was watching is moot.
  ///
  /// (`stats_panel` does read this provider on every preset, so a subscriber generally
  /// existed too. That is a second reason rather than the reason.)
  ///
  /// Fixed anyway, because the defect is in the pattern: a subscription added later would
  /// otherwise make a dormant bug live with nothing to catch it.
  ///
  /// Assigning `state` directly removes the dependency. `ref.onDispose` still cancels
  /// the timer, which matters for efficiency (a disposed notifier would otherwise issue
  /// one more USP fetch); it is not needed for correctness, because riverpod 2.6.1
  /// accepts a post-dispose `state` assignment silently rather than throwing (measured).
  ///
  /// ON FAILURE IT KEEPS THE PREVIOUS VALUE. Consumers read through `valueOrNull`, so an
  /// error state renders as "unknown" — a transient hiccup would empty the rule list.
  Future<void> _refreshFromPush() async {
    try {
      state = AsyncData(await _fetch());
    } catch (e, st) {
      logger.w(
          '[PortForwarding] push-triggered refetch failed, keeping previous value',
          error: e,
          stackTrace: st);
    }
  }

  Future<PortForwardingData> _fetch() async {
    final svc = ref.read(uspPortForwardingDataServiceProvider);
    final ruleModels = await svc.fetch();
    return PortForwardingData(ruleModels: ruleModels);
  }
}
