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
//   - "Return to login page" is correct in a local build and dishonest in RA,
//     where the credential was a one-shot Guardian token. Phase 5 gated the two
//     dialogs that offer it and gave each an `else` arm offering "End session". A
//     third recovery dialog is a plausible thing to add — the second one already
//     exists (firmware) — and it will be written by copying one of these two,
//     which is exactly how the copy loses the gate, or keeps the gate and loses
//     the `else`, which is worse: that renders a modal with no way out of it.
//
// WHY A SOURCE SCAN AND NOT A WIDGET TEST. The gate is a `ref.read` in an
// `actions:` list, so a widget test *could* pump each dialog under a remote
// profile and assert the button's absence. Two things rule it out. It would have
// to be tagged `ui`, which #1323 forbids for new tests; and — the reason that
// matters — it would assert about the two dialogs that already have the gate,
// which is not where the risk is. The risk is the third dialog, and no test that
// names its subject can be written before its subject exists. A census can.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one file allowed to end a Remote Assistance session.
const _sessionStrategy = 'lib/core/mode/impl/remote_session_strategy.dart';

/// The recovery dialogs that may offer a bail-out to the login page, each gated
/// on cause 3's answer for the running mode.
///
/// Pinned as a list rather than discovered, because adding one has to be a
/// decision. The two assertions below only run against the paths named here, so
/// this list is the mechanism by which a new recovery dialog gets asked whether
/// its bail-out is reachable in Remote Assistance — a discovered set would answer
/// that question by not asking it.
const _loginBailoutDialogs = <String>[
  'lib/page/_shared/helpers/recovery_dialog_helper.dart',
  'lib/page/firmware_update/views/dialogs/firmware_update_recovery_dialog.dart',
];

/// The gate, asserted as *adjacency* rather than as presence anywhere in the file.
///
/// The first version of this test asked whether the file contained the string
/// `SessionOutcome.loginPage` at all, and that version was vacuous — measured, not
/// suspected: moving the collection-`if` onto an unrelated `AppGap.sm()` while
/// leaving the button unconditional kept the file green, because any surviving
/// mention of the enum satisfied it. Which is the worse-than-useless case: a
/// review would read the green suite as covering the thing it had just broken.
///
/// So the pattern spans from the gate to the guarded label with nothing but
/// whitespace between, which is what the collection-`if` form guarantees and what
/// a mis-attached gate cannot fake.
final _gatedLoginButton = RegExp(
  r'SessionOutcome\.loginPage\)\s*'
  r'AppButton\.\w+\(\s*label:\s*loc\(context\)\.returnToLoginPage',
);

/// The `else` arm, for the same reason and one more.
///
/// Both dialogs are their whole `actions:` list or nearly so, both are shown
/// `barrierDismissible: false`, and the only `pop` fires on a transition *into*
/// `authenticated`. A gate with no `else` is therefore not a missing button — it
/// is a modal an RA operator cannot leave, on three triggers RA still recovers
/// for. Asserted positively so that deleting the arm is red, and by adjacency to
/// `else` so that an `endSession` button parked *outside* the gate — visible in
/// both modes, next to "Return to login page" — is red too.
final _elseEndSessionButton = RegExp(
  r'\)\s*else\b\s*'
  r'AppButton\.\w+\(\s*label:\s*loc\(context\)\.endSession',
);

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
    for (final path in _loginBailoutDialogs) {
      expect(sources[path], contains('AppButton'),
          reason: '$path stripped down to something with no widgets in it');
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

  group(
      'the login bail-out is offered only where it leads somewhere '
      '(acceptance 1)', () {
    test('exactly the two known recovery dialogs offer it', () {
      // Two discovery keys, because the affordance has two halves and a new
      // dialog can be found by either. `returnToLoginPage` is the copy; the
      // leading-dot `exitToLogout(` is the *behaviour* — the notifier call that
      // clears the credential and lets the route redirect take the app to the
      // login page. A third dialog that relabels the button ("Cancel", "Leave")
      // and still calls it is the same defect wearing different copy, and the
      // label key alone would not see it. The declaration in
      // `app_connection_state_provider.dart` has no leading dot, so it is not a
      // caller.
      final offerers =
          filesMatching(RegExp(r'\.returnToLoginPage\b|\.exitToLogout\('));

      expect(
        offerers,
        [..._loginBailoutDialogs]..sort(),
        reason: 'expected the login bail-out affordance in exactly the two '
            'recovery dialogs, found $offerers. A third one is fine, but it has '
            'to be added to _loginBailoutDialogs here so the gate assertions '
            'below cover it — which is the point: this list is how a new '
            'recovery dialog gets asked whether its bail-out is reachable in '
            'Remote Assistance.',
      );
    });

    for (final path in _loginBailoutDialogs) {
      test('$path gates it on the mode', () {
        expect(
          sources[path],
          isNotNull,
          reason: '$path is in _loginBailoutDialogs but does not exist. If the '
              'dialog moved, move the entry.',
        );
        expect(
          sources[path]!,
          matches(_gatedLoginButton),
          reason: '$path offers "Return to login page" without a gate directly '
              'in front of it asking cause 3 where an ending session lands in '
              'this mode. Locally that is the login form; in RA the credential '
              'was a one-shot Guardian token, so there is no password to type '
              'and no way back in — and the button reads as the escape hatch '
              'from a recovery wait, so a support engineer presses it and is '
              'left on a dead login form with the Guardian session still '
              'billing. The gate has to guard *this* button: '
              'if (ref.read(appModeProfileProvider).session.destination == '
              'SessionOutcome.loginPage) AppButton.text(label: '
              'loc(context).returnToLoginPage, ...).',
        );
      });

      test('$path offers End session instead, in RA', () {
        expect(
          sources[path]!,
          matches(_elseEndSessionButton),
          reason: '$path gates the login bail-out but has no else arm, so in '
              'Remote Assistance it renders a modal with no way out: this is '
              'the whole actions list or nearly so, barrierDismissible is '
              'false, and the dialog only pops on a transition into '
              'authenticated — which is the case that is not happening. Add '
              'else AppButton.text(label: loc(context).endSession, onTap: () => '
              'ref.read(authProvider.notifier).logout(cause: '
              'EndCause.userRequested)). The string already exists in all 26 '
              'locales and is what the session chip calls the same action.',
        );
      });
    }
  });
}
