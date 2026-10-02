/// Provider overrides for `instant_privacy_view` (save-based).
///
/// A `uspInstantPrivacyProvider` pinned to one state, with `build()` returning
/// it directly (no fetch microtask). Used by the golden suite, the layout gate
/// and the view tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

import '../test_data/scenes/instant_privacy_scene_data.dart';

class FixedInstantPrivacyNotifier extends UspInstantPrivacyNotifier {
  FixedInstantPrivacyNotifier(this._fixedState);

  final UspInstantPrivacyState _fixedState;

  @override
  UspInstantPrivacyState build() => _fixedState;
}

/// Overrides for `instant_privacy_view`, defaulting to [gateInstantPrivacyState].
List<Override> instantPrivacyOverrides([UspInstantPrivacyState? state]) => [
      uspInstantPrivacyProvider.overrideWith(
        () => FixedInstantPrivacyNotifier(state ?? gateInstantPrivacyState),
      ),
    ];
