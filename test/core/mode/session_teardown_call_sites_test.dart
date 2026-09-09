// #1323 phase 5: the two shape rules that acceptances 1, 2 and 3 rest on, and
// that no behavioural test in this repo can see.
//
// Both are *call-site censuses*, and they exist because the bug #1323 describes
// was never a wrong line of code — it was a right line of code that only some
// call sites had.
//
//   - RA teardown (release the Guardian session, then drop the local session
//     state) lived in `remote_session_chip.dart`'s Disconnect handler, and the
//     other ten paths into `logout()` had none of it. Phase 5 moved it behind
//     `SessionStrategy.end`; nothing stops the next feature from copying the old
//     two lines back into its own handler, and if it does, everything still
//     passes: the copy works.
//
//   - ending the session at all lived wherever the code that noticed happened to
//     be. `app_connection_state_provider.dart` — a provider under `lib/core/` —
//     finished three of its exits with a bare `logout()`, which is the decision to
//     sign a person out, the RA teardown-by-cause `SessionStrategy.end` owns, and
//     the navigation that follows, all made from the layer that is only supposed to
//     know the connection is gone. Phase 5 gave it a report to make instead; the
//     third census below is what stops the next such file from making the call.
//
//   - "Return to login page" is correct in a local build and dishonest in RA,
//     where the credential was a one-shot Guardian token. Phase 5 gated the two
//     dialogs that offer it and gave each an `else` arm offering "End session". A
//     third recovery dialog is a plausible thing to add — the second one already
//     exists (firmware) — and it will be written by copying one of these two,
//     which is exactly how the copy loses the gate, or keeps the gate and loses
//     the `else`, which is worse: that renders a modal with no way out of it.
//
// AMENDED BY #1497 (phase 7), which changed what the second rule can be. Phase 5
// left each dialog holding its own `if/else` over cause 3; phase 7 replaced both
// with `SurfaceStrategy.sessionExitAction()`, a member returning the widget. The
// rule is therefore no longer "gate it, and provide the else" — it is "take the
// widget, author none of it", and the else arm has stopped being something a test
// has to require: a non-nullable `Widget` return makes the modal-with-no-way-out
// case unwritable rather than merely tested-for.
//
// That is the direction this file's assertions should always move in. A census
// asserting a *shape* is the weaker instrument; when a refactor can make the
// defect inexpressible, the census's job shrinks to policing re-authoring, which
// is what the group below now does. The phase-5 form is left in the comments
// because the failure it caught is the reason cause 5 exists.
//
// WHY A SOURCE SCAN AND NOT A WIDGET TEST. The composition is a `ref.watch` in an
// `actions:` list, so a widget test *could* pump each dialog under a remote
// profile and assert which button appears — and one does, in
// surface_consumers_test.dart's `recovery dialog` group. What it cannot do is
// assert about the dialog that does not exist yet, and that is where the risk is:
// the third recovery dialog, written by copying one of these two. No test that
// names its subject can be written before its subject exists. A census can.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one file allowed to end a Remote Assistance session.
const _sessionStrategy = 'lib/core/mode/impl/remote_session_strategy.dart';

/// The one file allowed to author a session-exit affordance.
///
/// #1497 replaced phase 5's per-dialog gate with `SurfaceStrategy
/// .sessionExitAction()`, and the two buttons moved into named widgets here. The
/// directory is not incidental: `lib/components/` rather than beside the dialogs
/// is what puts `loc(context).returnToLoginPage` outside `lib/page/` entirely,
/// which is acceptance 5c of #1497 stated as a grep. Authoring the labels inline
/// in `LocalSurface`/`RemoteSurface` would have satisfied the contract and failed
/// it, since Rule 17.1.3 puts those under `lib/page/_shared/mode/`.
const _exitActions = 'lib/components/session/session_exit_actions.dart';

/// The one file under `lib/core/` still allowed to sign the user out, and the one
/// outside it that acts on the core's report.
///
/// `sse_providers.dart` is an exception with a reason, not an oversight. Its two
/// calls are `bridge.onAuthFailed` and a shared `forceLogout` handed to the auth
/// coordinator and the client — **callbacks assigned onto transport objects inside
/// provider build bodies**, so there is no notifier state for a page to listen to,
/// and the 401 they answer can arrive during boot, before any page is mounted.
/// Turning them into a report would therefore fail *open*: the app would keep a
/// session the router has already rejected, which is strictly worse than the layer
/// violation. Closing it needs a state-carrying owner for transport auth failure;
/// that is recorded on #1323 rather than attempted here.
const _transportAuthFailure = 'lib/core/usp/providers/sse_providers.dart';
const _sessionSink = 'lib/page/shell/usp_dashboard_shell.dart';

/// The recovery dialogs that must take their exit action from cause 5.
///
/// Pinned as a list rather than discovered, because adding one has to be a
/// decision. The assertions below only run against the paths named here, so this
/// list is the mechanism by which a new recovery dialog gets asked where its way
/// out comes from — a discovered set would answer that question by not asking it.
const _recoveryDialogs = <String>[
  'lib/page/_shared/helpers/recovery_dialog_helper.dart',
  'lib/page/firmware_update/views/dialogs/firmware_update_recovery_dialog.dart',
];

/// `sessionExitAction()` inside the dialog's own `actions:` list, asserted as
/// *containment* rather than as presence anywhere in the file.
///
/// The same lesson this file learned once already, in its phase-5 form. That
/// version asked whether the file mentioned `SessionOutcome.loginPage` at all,
/// and it was vacuous — measured, not suspected: moving the collection-`if` onto
/// an unrelated `AppGap.sm()` while leaving the button unconditional kept the file
/// green. A bare `contains('sessionExitAction(')` has the identical weakness one
/// refactor later, since a call whose result is dropped, or one parked in an
/// unrelated builder, reads the same to `contains`.
///
/// `[^\[\]]*` is what does the work: it forbids a `]` between the list opening and
/// the call, so the match cannot straddle the end of `actions:` into whatever
/// comes after it. Both current call sites reach it through a receiver with
/// parentheses (`ref.watch(surfaceStrategyProvider).`), which is why the gap is
/// bracket-restricted rather than word-restricted.
final _composedExitAction =
    RegExp(r'actions:\s*\[[^\[\]]*sessionExitAction\(\)');

/// The four spellings of a dialog deciding its own exit, banned per dialog.
///
/// This is what replaces phase 5's `else`-arm adjacency assertion, and the reason
/// the replacement can be a ban rather than a requirement is a type: `
/// sessionExitAction()` returns a **non-nullable** `Widget`, so "the gate with no
/// `else`" — a modal with no affordance, `barrierDismissible: false`, popping only
/// on a transition *into* `authenticated` — is no longer expressible. What is
/// still expressible is a third dialog copying one of these two and re-authoring
/// the button, which is what these forbid: the label either way, the behaviour
/// (`exitToLogout`), and the cause-3 enum a hand-rolled gate would consult.
const _handRolledExit = <String, String>{
  'returnToLoginPage': 'the local label',
  '.exitToLogout(': 'the local behaviour',
  'loc(context).endSession': 'the remote label',
  'SessionOutcome': 'a hand-rolled gate on cause 3',
};

void main() {
  /// Every `lib/` Dart file's source with `//` comments removed, l10n excluded.
  ///
  /// Comment-stripping is load-bearing twice over here. Both production files in
  /// this census document the removed/gated code in prose that names the exact
  /// calls being banned — `remote_session_strategy.dart`'s doc comment says
  /// "skips `endSessionForCA`", and `remote_session_chip.dart` explains that its
  /// handler no longer calls either — so a scan that read comments would report
  /// the explanations as the violations and be un-greenable without deleting the
  /// documentation.
  ///
  /// *Trailing* comments too, not just whole comment lines: `foo(); // no longer
  /// calls clearSession()` is one line of code and one mention, and a scan that
  /// only dropped whole-line comments would still read the second half. The
  /// `(?<!:)` is what keeps `https://` in a URL literal from being treated as the
  /// start of one. Same expression as `remote_assistance_swap_guard_test.dart`,
  /// deliberately — two guards over the same corpus disagreeing about what counts
  /// as a comment is a way for one of them to be quietly weaker.
  ///
  /// `lib/l10n/` is excluded because the ARB files and 25 generated
  /// `app_localizations_*.dart` all carry `returnToLoginPage` as a key or a
  /// string literal. That is the copy, not an affordance; the string has to stay
  /// translated for the local build that still offers the button.
  late final Map<String, String> sources = {
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.startsWith('lib/l10n/')))
      f.path: f
          .readAsStringSync()
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'(?<!:)//.*$'), ''))
          .join('\n'),
  };

  List<String> filesMatching(RegExp pattern) => sources.entries
      .where((e) => pattern.hasMatch(e.value))
      .map((e) => e.key)
      .toList()
    ..sort();

  test('the stripped corpus is still recognisable code', () {
    // Guards the guard. Every assertion below is a match against `sources`, and
    // an over-eager strip that emptied the corpus would turn the two censuses
    // green (nothing matches, so nothing is a caller) while the adjacency
    // assertions would fail with a message about the dialogs rather than about
    // the stripper. Fail here instead, where the cause is named.
    expect(sources[_sessionStrategy], contains('class RemoteSessionStrategy'));
    expect(sources[_exitActions], contains('AppButton'),
        reason:
            '$_exitActions stripped down to something with no widgets in it');
    for (final path in _recoveryDialogs) {
      expect(sources[path], contains('actions:'),
          reason: '$path stripped down to something with no dialog in it');
    }
  });

  group('RA teardown funnels through SessionStrategy.end (acceptances 2, 3)',
      () {
    test('only the session strategy releases the Guardian session', () {
      // A leading dot, so this finds invocations and not the declaration in
      // `remote_assistance_service.dart`.
      final callers = filesMatching(RegExp(r'\.endSessionForCA\('));

      expect(
        callers,
        [_sessionStrategy],
        reason: 'endSessionForCA must be called from $_sessionStrategy alone, '
            'found $callers. It is not a call you can make correctly outside '
            'cause 3: it authenticates with the session token, so it has to run '
            'before the local state is dropped and it has to be skipped when the '
            'cause is a token the router already rejected. A call site that '
            'decides those two things for itself is the bug this phase closed. '
            'If a new path needs to end a session, give it '
            'authProvider.notifier.logout(cause: ...).',
      );
    });

    test('only the session strategy drops the local session state', () {
      final callers = filesMatching(RegExp(r'\.clearSession\('));

      expect(
        callers,
        [_sessionStrategy],
        reason: 'clearSession() must be called from $_sessionStrategy alone, '
            'found $callers. This is the call acceptance 3 turns on: '
            "router_provider's /usp* guard rebuilds the confirm URL from "
            'sessionInfo and sessionToken, so any exit that skips it lands the '
            'app back on the confirm page holding the parameters of the session '
            'it just left — where one tap re-activates it. Scattering the call '
            'back out means the next exit path is one someone forgot.',
      );
    });
  });

  group('lib/core/ reports that a session is over rather than ending it', () {
    test('only the declared exception signs the user out', () {
      // Two keys, and the pairing is what makes this precise enough to assert.
      // `.logout(` alone has four more callers under `lib/core/` that are the USP
      // protocol's own logout on a transport (`_usp.logout()`,
      // `_client.logout()`), which are not this rule's subject; mentioning
      // `authProvider` is what separates "ends the app's session" from "closes a
      // connection". Measured, not assumed: those four files mention
      // `authProvider` zero times.
      //
      // It is a file-level pairing rather than a single expression on purpose. The
      // spelling varies — `ref.read(authProvider.notifier).logout()` here,
      // `authNotifier.logout(cause: ...)` via a local in `remote_session_chip.dart`
      // — and a regex tight enough to match only the first would miss the second,
      // which is the failure mode a census cannot afford. The cost is a false
      // positive if a `lib/core/` file ever reads `authProvider` for some unrelated
      // reason *and* calls a transport `logout()`; erring that way is correct here,
      // because the fix for a false positive is a comment on this list and the
      // fix for a false negative is a field bug.
      final callers = sources.entries
          .where((e) => e.key.startsWith('lib/core/'))
          .where((e) => e.value.contains('authProvider'))
          .where((e) => e.value.contains('.logout('))
          .map((e) => e.key)
          .toList()
        ..sort();

      expect(
        callers,
        [_transportAuthFailure],
        reason: 'expected $_transportAuthFailure to be the only file under '
            'lib/core/ that ends the app session, found $callers. This was '
            'app_connection_state_provider.dart until #1323 phase 5: three exits '
            'there — the manual one, a router back from a factory reset, a router '
            'back with a different serial — each finished with a bare logout(), '
            'and a bare logout() is three decisions, not one. It defaults to '
            'EndCause.sessionLost, which is RemoteSessionStrategy.end deciding '
            'not to release the Guardian session; it drops the credential, which '
            'is what the route redirect reads to pick a destination; and it is '
            'the sign-out itself. A provider that knows the connection is gone is '
            'not the layer that gets to make any of them. Report instead: set the '
            'state and an EndCause, and let the consumer act — see '
            'AppConnectionStateNotifier.takePendingSessionExit.',
      );
    });

    test('exactly one consumer acts on the report', () {
      // The mirror of the ban above, and the half that matters more. A report
      // nobody reads fails *open*: the connection state says the session is over
      // while auth still holds it, and nothing navigates. So "core stopped calling
      // logout()" is only an improvement if this list is non-empty, and only
      // unambiguous if it has one entry — `takePendingSessionExit` clears on read,
      // so a second consumer would race the first for a cause exactly one of them
      // can see. The declaration in `app_connection_state_provider.dart` has no
      // leading dot, so it is not a consumer.
      final consumers = filesMatching(RegExp(r'\.takePendingSessionExit\('));

      expect(
        consumers,
        [_sessionSink],
        reason: 'expected the core session-exit report to be consumed in '
            '$_sessionSink alone, found $consumers. Empty means the three exits '
            'in app_connection_state_provider.dart now do nothing at all — the '
            'dialog closes, the state reads loggedOut and the user stays signed '
            'in on a router that is gone. More than one means two listeners '
            'competing for a one-shot value. If the consumer has to move, it has '
            'to move somewhere mounted whenever any of those three exits can '
            'fire; the reachability argument for this one is written on its '
            'initState.',
      );
    });
  });

  group(
      'the login bail-out is offered only where it leads somewhere '
      '(acceptance 1, as #1497 left it)', () {
    test('exactly one file authors the affordance', () {
      // Two discovery keys, because the affordance has two halves and a new
      // author can be found by either. `returnToLoginPage` is the copy; the
      // leading-dot `exitToLogout(` is the *behaviour* — the notifier call that
      // clears the credential and lets the route redirect take the app to the
      // login page. A dialog that relabels the button ("Cancel", "Leave") and
      // still calls it is the same defect wearing different copy, and the label
      // key alone would not see it. The declaration in
      // `app_connection_state_provider.dart` has no leading dot, so it is not a
      // caller.
      final offerers =
          filesMatching(RegExp(r'\.returnToLoginPage\b|\.exitToLogout\('));

      expect(
        offerers,
        [_exitActions],
        reason: 'expected the login bail-out to be authored in $_exitActions '
            'alone, found $offerers. This was the two recovery dialogs before '
            '#1497, and one file rather than two is the whole point: each dialog '
            'that authors the button also has to know, for itself, that the '
            'remote build wants a different one — and the second dialog got that '
            'right only because the first one had already been fixed. If a new '
            'exit affordance is needed, add it beside ReturnToLoginAction and '
            'return it from SurfaceStrategy.sessionExitAction().',
      );
    });

    for (final path in _recoveryDialogs) {
      test('$path composes its exit action rather than choosing one', () {
        expect(
          sources[path],
          isNotNull,
          reason: '$path is in _recoveryDialogs but does not exist. If the '
              'dialog moved, move the entry.',
        );
        expect(
          sources[path]!,
          matches(_composedExitAction),
          reason: '$path does not have sessionExitAction() inside its own '
              '`actions:` list. Cause 5 is what makes the way out of this modal '
              'mode-correct: locally the exit is the login form, but in RA the '
              'credential was a one-shot Guardian token, so there is no password '
              'to type and no way back in — and the button reads as the escape '
              'hatch from a recovery wait, so a support engineer presses it and '
              'is left on a dead login form with the Guardian session still '
              'billing. Write actions: [ref.watch(surfaceStrategyProvider)'
              '.sessionExitAction(), ...]. A call whose result is dropped, or '
              'one made in some other builder, is what the bracket-restricted '
              'match here is meant to reject.',
        );
      });

      test('$path re-authors none of it', () {
        for (final entry in _handRolledExit.entries) {
          expect(
            sources[path]!,
            isNot(contains(entry.key)),
            reason:
                '$path names `${entry.key}` — ${entry.value} — so it has an '
                'opinion about where an ending session lands. It should not need '
                'one: sessionExitAction() returns a non-nullable Widget and '
                'already differs by mode. The failure this replaces was a dialog '
                'that kept a mode gate and lost its else arm, which renders a '
                'modal with no way out at all: barrierDismissible is false and '
                'the dialog only pops on a transition into authenticated, which '
                'is the case that is not happening. Deleting the local branch '
                'and taking the widget is what makes that unwritable.',
          );
        }
      });
    }
  });
}
