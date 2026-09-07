import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/app_mode.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/framework/mode/surface_strategy.dart';
import 'package:privacy_gui/page/_shared/mode/local_surface.dart';
import 'package:privacy_gui/page/_shared/mode/remote_surface.dart';

/// The page composition root: the **one** place in `lib/page/` that switches on
/// [AppMode].
///
/// Why cause 5 has its own root instead of a `surface` member on
/// `AppModeProfile`: [SurfaceStrategy]'s implementations talk to page state, so
/// they must live under `lib/page/`, and CLAUDE.md forbids `lib/core/` →
/// `lib/page/`. A `surface` getter on the core profile would be exactly that
/// dependency. Splitting the root is the smaller price.
///
/// **The mode comes from the profile, not from `appModeProvider`.** Reading the
/// raw provider here looks equivalent and is not: acceptance 3 of #1493 is that
/// *one* `appModeProfileProvider.overrideWithValue(const RemoteModeProfile())`
/// puts the whole stack in remote, and a root that reads `appModeProvider`
/// silently opts cause 5 out of that override — the four core causes move, the
/// surfaces stay local, and the test that only asserts transport still passes.
/// Going through the profile keeps **both** levers working, because the profile
/// is itself derived from `appModeProvider`: overriding the coarse mode moves
/// both roots, and overriding the profile now moves both too. This is the
/// direction #1474's design specifies (`ref.watch(appModeProfileProvider).mode`);
/// `composition_root_test.dart` pins it, since nothing observable distinguishes
/// the two readings until someone writes exactly that one-line test.
///
/// Same rule as the core root: no `default:`, no `_` arm. A new [AppMode] must be
/// a compile error in **both** places, and
/// `test/core/mode/composition_root_test.dart` checks both files for the escape
/// hatch — the switch guards against a new mode, not against someone silencing
/// it.
final surfaceStrategyProvider = Provider<SurfaceStrategy>((ref) {
  final mode = ref.watch(appModeProfileProvider).mode;
  return switch (mode) {
    AppMode.local => const LocalSurface(),
    AppMode.remote => const RemoteSurface(),
    // Cloud and demo see the same surfaces as local. Unlike the core root there
    // is no alias constructor to preserve a label, because no `SurfaceStrategy`
    // member reports which mode it came from — if one ever does, give it the same
    // `aliasedAs` treatment as `LocalModeProfile` rather than letting `mode` and
    // the surfaces disagree.
    AppMode.cloud => const LocalSurface(),
    AppMode.demo => const LocalSurface(),
  };
});
