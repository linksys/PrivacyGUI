import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';

/// The build-phase partition every mode strategy is selected by.
///
/// One value per way the app can be *built and entered*, which is why this is
/// not simply `ForceCommand` renamed:
///
/// - [local] / [remote] are the two `--dart-define=force=` flavours.
/// - [cloud] is `ForceCommand.none` — the cloud-login build. It behaves exactly
///   like [local] once a session exists, and #1474 keeps the distinction only so
///   that `AppModeProfile.mode` stays truthful; the profile is
///   `LocalModeProfile.aliasedAs(AppMode.cloud)`, i.e. one implementation, two
///   labels. Collapsing the two arms would make a future divergence a silent
///   behaviour change instead of a compile error.
/// - [demo] is not a build flag at all. `lib/demo/` is a separate entry point
///   that installs provider overrides, so [resolve] can never return it; it is
///   reachable only through `appModeProvider`'s override in
///   `demo_overrides.dart`. Without that arm the enum's exhaustive `switch` in
///   `appModeProfileProvider` would be a switch over three reachable values with
///   a fourth that nothing could ever produce — and the epic's central guard
///   would be guarding a fiction.
enum AppMode {
  local,
  remote,
  cloud,
  demo;

  /// The mode this *build* is in.
  ///
  /// Reads the build flag exactly once per provider read and nowhere else in the
  /// mode subsystem — this is the single translation from `ForceCommand` into the
  /// strategy world. Everything downstream switches on [AppMode].
  ///
  /// Deliberately total rather than defensive: `ForceCommand` has three values
  /// and each maps to one mode, so there is no fallback branch to get wrong.
  static AppMode resolve() => switch (BuildConfig.forceCommandType) {
        ForceCommand.local => AppMode.local,
        ForceCommand.remote => AppMode.remote,
        ForceCommand.none => AppMode.cloud,
      };
}

/// The one seam a test overrides to put the whole stack in another mode.
///
/// This provider exists so that `BuildConfig.forceCommandType` — a mutable
/// static — never has to be assigned in a test. #1474's falsification criterion
/// 2 (the no-global criterion) is exactly that: `test/di_test.dart` is the one
/// place in the repo that pays that price, for a pure function, and every remote
/// test written after this phase overrides a provider and needs no `tearDown`.
///
/// Note that overriding *this* provider is the coarse lever (it re-derives the
/// whole profile through `appModeProfileProvider`); overriding
/// `appModeProfileProvider` directly with a hand-built profile is the fine one,
/// used when a test wants one strategy swapped and the rest real.
final appModeProvider = Provider<AppMode>((ref) => AppMode.resolve());
