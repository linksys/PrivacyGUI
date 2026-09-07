import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/navigation_extra.dart';

extension NavigationExtension on BuildContext {
  /// The app's single back-arrow behaviour, in priority order.
  ///
  /// 1. `canPop()` — pop to whoever pushed this page. This is the in-session
  ///    answer, and it is why a detail page must be entered with `pushNamed`:
  ///    `goNamed` replaces the location, so the entry point is dropped from the
  ///    stack and back falls through to the branches below (#1420, #1421).
  /// 2. [NavigationExtra.backDestination] from `extra` — an explicit override
  ///    for a caller that knows better than the stack.
  /// 3. [fallback] — the `backFallback` a page declares. For a route that is
  ///    registered as a nested child this is **unreachable**: the URL's parent
  ///    is always in the rebuilt stack, so `canPop()` is true and branch 1 wins
  ///    every time. Treat it as a no-parent safety net only, not as a statement
  ///    of where back goes.
  ///
  /// ## Cold-URL entry unwinds up the URL, deliberately
  ///
  /// On a reload, a bookmark or a shared link there is no in-memory stack:
  /// go_router builds the match list from the path alone, so the page the user
  /// came from in a previous session does not exist to pop to. `extra` cannot
  /// carry the intent across either — it is not part of the URL and this app
  /// configures no `extraCodec`. So back on a cold entry walks *up the URL*, and
  /// a nested page lands on its URL parent rather than on the Dashboard.
  ///
  /// That asymmetry — Dashboard in-session, URL parent after F5 — was reviewed
  /// and **accepted** as the intended behaviour (#1436, decided on that issue —
  /// see the thread there, which is the artefact this comment records): for a
  /// cold entry the URL *is* the history, and this app ships web only — CI builds
  /// `flutter build web --release` and nothing else, and `build_web.sh` is the
  /// only build script — so synthesizing a Dashboard-rooted stack would make this
  /// arrow disagree with the browser's own Back button on every page. No call
  /// site can change it and none should try. Both landings are asserted in
  /// `test/page/local_network/views/usp_local_network_back_navigation_test.dart`.
  /// Pushes [name] unless it is already the page on top.
  ///
  /// The entry verb for **global chrome** — a control that is present on every
  /// page, *including the page it navigates to*. Such a control still has to
  /// push: it is an entry point, and `goNamed` would throw away the page the user
  /// was on, which is the whole of #1420/#1421/#1434. But nothing in go_router
  /// de-duplicates a push onto the location already on top, and the screen does
  /// not change either, so every extra tap silently adds one more back the user
  /// has to press to leave. Measured: three `pushNamed` calls onto the same shell
  /// child need three pops to get back, the location unchanged throughout.
  ///
  /// `goNamed` used to hide this by being idempotent — replacing a location with
  /// itself is the same location — so it only became visible once the verb was
  /// corrected. A hub chip that replaces itself (the Menu) is idempotent for that
  /// same reason and does not need this.
  ///
  /// Both halves are pinned in `test/route/usp_navigation_invariants_test.dart`.
  void pushNamedIfNotCurrent(String name) {
    if (GoRouter.of(this).state.topRoute?.name == name) return;
    pushNamed(name);
  }

  void navigateBack({String? fallback}) {
    if (canPop()) {
      pop();
      return;
    }
    final extra = GoRouterState.of(this).extra;
    if (extra is NavigationExtra && extra.backDestination != null) {
      goNamed(extra.backDestination!);
      return;
    }
    if (fallback != null) {
      goNamed(fallback);
    }
  }
}
