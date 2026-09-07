import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/app_mode.dart';
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
/// dependency. Splitting the root is the smaller price — both roots switch on the
/// same [AppMode], read via the same `appModeProvider`, so a test that overrides
/// the mode moves both.
///
/// Same rule as the core root: no `default:`, no `_` arm. A new [AppMode] must be
/// a compile error in **both** places, and
/// `test/core/mode/composition_root_test.dart` checks both files for the escape
/// hatch — the switch guards against a new mode, not against someone silencing
/// it.
final surfaceStrategyProvider = Provider<SurfaceStrategy>((ref) {
  final mode = ref.watch(appModeProvider);
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
