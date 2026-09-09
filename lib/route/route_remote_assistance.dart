part of 'router_provider.dart';

final remoteAssistanceRoute = LinksysRoute(
  name: RouteNamed.remoteAssistanceConfirm,
  path: RoutePath.remoteAssistanceConfirm,
  config: LinksysRouteConfig(column: ColumnGrid(column: 12), noNaviRail: true),
  builder: (context, state) {
    // Query params: session, token, ended, expired
    final sessionId = state.uri.queryParameters['session'] ?? '';
    final token = state.uri.queryParameters['token'] ?? '';
    final ended = state.uri.queryParameters['ended'] == 'true';

    // `expired` was written by `remote_session_chip._handleForceDisconnect` from
    // the day it was added and read by nothing, here or anywhere else in `lib/`.
    // The consequence was invisible in code review and loud in use: a
    // Guardian-invalidated session navigated to `?expired=true`, `sessionEnded`
    // stayed false, `_hasRequiredParams` was false too because there is no
    // `session`/`token` on that URL, and the support engineer got
    // `_buildMissingParamsView()` — a red "Missing Parameters" developer page —
    // as the last thing they saw.
    //
    // Mapped onto the same terminal surface rather than a new one. The two causes
    // *are* distinguishable and #1323's `EndCause` is what distinguishes them, but
    // telling them apart in the copy needs a new string in 26 ARB files and a
    // decision about what it says; landing on the right surface does not. So the
    // parameter stays separate in the URL, which is where a later copy split would
    // read it from, and both values render "session ended" today.
    final expired = state.uri.queryParameters['expired'] == 'true';
    return RemoteAssistanceConfirmView(
      sessionId: sessionId,
      token: token,
      sessionEnded: ended || expired,
    );
  },
);
