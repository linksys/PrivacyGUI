import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/app_mode.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';
import 'package:privacy_gui/framework/mode/session_strategy.dart';
import 'package:privacy_gui/framework/mode/transport_strategy.dart';

/// One mode's answer to all four core causes, in one object.
///
/// A profile is *composition*, not behaviour: it holds no `if` and decides
/// nothing, it only says which strategy each cause is answered by. That is what
/// makes acceptance 3 of #1493 possible —
/// `appModeProfileProvider.overrideWithValue(RemoteModeProfile())` puts the
/// entire stack in Remote Assistance in one line, with no static mutated and no
/// `tearDown` to forget.
///
/// **Cause 5 is deliberately absent.** `SurfaceStrategy`'s implementations must
/// live under `lib/page/`, and CLAUDE.md forbids `lib/core/` → `lib/page/`, so a
/// `surface` member here would be an illegal dependency. It has its own root at
/// `lib/page/_shared/mode/surface_strategy_provider.dart`. Two composition roots
/// over the same [AppMode] is the intended shape; constitution Article XVII
/// Rule 2 names both, and `test/core/mode/composition_root_test.dart` guards
/// both.
abstract class AppModeProfile {
  /// Which mode this profile *is*, as opposed to which one it behaves like.
  ///
  /// The distinction is real: `AppMode.cloud` and `AppMode.demo` both compose the
  /// local strategies, but a profile that reported `AppMode.local` for them would
  /// make a diagnostic log lie about the build it came from. See
  /// `LocalModeProfile.aliasedAs`.
  AppMode get mode;

  /// Cause 1 — how bytes reach the router.
  TransportStrategy get transport;

  /// Cause 2 — who holds the credential, and what expiry means.
  CredentialStrategy get credential;

  /// Cause 3 — what "the session ended" means.
  SessionStrategy get session;

  /// Cause 4 — whether the operator is standing next to the router.
  ProximityStrategy get proximity;
}

/// The core composition root: the **one** place in `lib/core/` that switches on
/// [AppMode].
///
/// The `switch` below has no `default:` and no `_` arm, and that is the single
/// most load-bearing line in epic #1474. A new [AppMode] is a *compile error*
/// here, which is the whole mechanism replacing the 15 scattered mode reads
/// measured before this phase — 11 `GlobalConfig.remote.isActive` plus 4 direct
/// `BuildConfig.isRemote()`. Each one answered "is this remote?" independently,
/// so a third mode would have been silently mis-answered by however many of them
/// nobody remembered to visit.
///
/// Guarded by `test/core/mode/composition_root_test.dart`, because the exhaustive
/// switch protects against a new *mode* but not against someone adding
/// `default:` to silence the error a new mode produces. That is the realistic
/// regression: the compiler tells you exactly where to look and offers exactly
/// the wrong fix.
final appModeProfileProvider = Provider<AppModeProfile>((ref) {
  final mode = ref.watch(appModeProvider);
  return switch (mode) {
    AppMode.local => const LocalModeProfile(),
    AppMode.remote => const RemoteModeProfile(),
    AppMode.cloud => const LocalModeProfile.aliasedAs(AppMode.cloud),
    AppMode.demo => const LocalModeProfile.aliasedAs(AppMode.demo),
  };
});
