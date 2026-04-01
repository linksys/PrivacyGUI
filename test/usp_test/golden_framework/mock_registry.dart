import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';

/// Fixed-state notifier for firewall golden tests.
///
/// Returns a pre-configured state from build() and no-ops all mutation methods.
class _FixedFirewallNotifier extends UspFirewallNotifier {
  final FirewallFeatureState _fixedState;

  _FixedFirewallNotifier(this._fixedState);

  @override
  FirewallFeatureState build() {
    // Return fixed state directly — no data provider listening, no fetch.
    return _fixedState;
  }

  @override
  Future<(FirewallSettings?, FirewallStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    // No-op: return (null, null) to indicate no changes.
    return (null, null);
  }

  @override
  Future<void> performSave() async {
    // No-op: golden tests don't save.
  }

  @override
  void updateSetting(FirewallUIModel Function(FirewallUIModel) updater) {
    // No-op: golden tests capture static states.
  }
}

/// Centralized provider mocks for golden tests.
///
/// Usage:
/// ```dart
/// final mockSetup = (MockRegistry mock) {
///   mock.common();
///   mock.firewall(FirewallFeatureState(...));
/// };
/// ```
class MockRegistry {
  final List<Override> _overrides = [];

  /// Common provider overrides shared across all views.
  ///
  /// TODO: Add shared overrides incrementally as more views are tested.
  void common() {
    // Reserved for future use.
  }

  /// Override firewall provider with a fixed state.
  void firewall(FirewallFeatureState state) {
    _overrides.add(
      uspFirewallProvider.overrideWith(() => _FixedFirewallNotifier(state)),
    );
  }

  /// Build the list of provider overrides for ProviderScope.
  List<Override> build() => List.unmodifiable(_overrides);
}
