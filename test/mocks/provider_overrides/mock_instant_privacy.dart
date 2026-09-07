/// Provider overrides for `instant_privacy_view`.
///
/// Moved out of `test/golden_test/golden_framework/mocks/` by #1380 (wave 4) so the
/// layout gate can reach it — `instant_privacy_scene_data.dart` says why a move and
/// not a copy. The class below is unchanged from what the golden suite has been
/// using; the argument to [instantPrivacyOverrides] became optional so the gate can
/// take the default scene without naming it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

import '../test_data/scenes/instant_privacy_scene_data.dart';

/// A `uspInstantPrivacyProvider` pinned to one state, with every mutating path
/// stubbed.
class FixedInstantPrivacyNotifier extends UspInstantPrivacyNotifier {
  final UspInstantPrivacyState _fixedState;

  FixedInstantPrivacyNotifier(this._fixedState);

  @override
  Future<UspInstantPrivacyState> build() async => _fixedState;

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> addMac(String mac) async {}
}

/// Overrides for `instant_privacy_view`, defaulting to [gateInstantPrivacyState].
List<Override> instantPrivacyOverrides([UspInstantPrivacyState? state]) => [
      uspInstantPrivacyProvider.overrideWith(
        () => FixedInstantPrivacyNotifier(state ?? gateInstantPrivacyState),
      ),
    ];
