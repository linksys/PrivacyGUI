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
  /// and **accepted** as the intended behaviour (#1436, decided 2026-09-02): for
  /// a cold entry the URL *is* the history, and this app ships web only, so
  /// synthesizing a Dashboard-rooted stack would make this arrow disagree with
  /// the browser's own Back button on every page. No call site can change it and
  /// none should try. Both landings are asserted in
  /// `test/page/local_network/views/usp_local_network_back_navigation_test.dart`.
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
