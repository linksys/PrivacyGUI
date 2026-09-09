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
/// violation. Closing it needs a state-carrying owner for transport auth failure,
/// which is #1529's first scope item — filed because round 2 of #1513's review
/// pointed out that the waiver previously named #1323, which carries the reasoning
/// but no acceptance line for these two sites, so a green census here read as
/// "done". Both sites now carry a `TODO(#1529)`.
const _transportAuthFailure = 'lib/core/usp/providers/sse_providers.dart';
const _sessionSink = 'lib/components/session/session_exit_sink.dart';

/// The one file that subscribes the sink to the connection state.
///
/// Separate from [_sessionSink] because the two censuses below fail for different
/// reasons, and the split is what round 2 of the review made necessary: the verb
/// and its wiring lived in the same file, so the only mutation that mattered —
/// deleting the `listenManual` — was invisible to a census naming the file that
/// still held the verb. Measured: removing those three lines left all fourteen
/// tests in the sink's own suite and in this file green.
const _sessionSinkWiring = 'lib/page/shell/usp_dashboard_shell.dart';

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

/// Drop `//` comments, trailing ones included.
///
/// A named function rather than an expression inlined into the corpus builder,
/// because [_endsAppSession] below is only correct *composed with this*, and the
/// fixture test that pins the pair has to be able to call both. See the corpus's
/// own doc comment for why stripping is load-bearing at all.
String _stripComments(String source) => source
    .split('\n')
    .map((l) => l.replaceFirst(RegExp(r'(?<!:)//.*$'), ''))
    .join('\n');

/// How many times [needle] appears in [source].
///
/// The file lists every other assertion here produces cannot count, and for the
/// sink's wiring that is the difference between the property and its shadow: one
/// file holding the declaration and one file holding a call reads identically to
/// one file holding the declaration and one holding three. Three would be three
/// subscriptions racing for a value `takePendingSessionExit` clears on read.
int _countOccurrences(String source, String needle) =>
    needle.allMatches(source).length;

/// Does this file end the **app's** session, as opposed to closing a connection?
///
/// Two needles, paired at file level, and round 2's review is right that this is a
/// coarse instrument — so here is what it is coarse *towards*, and why the
/// suggested narrowing to a single call-shape regex was declined.
///
/// The spelling varies: `ref.read(authProvider.notifier).logout()` in most places,
/// `authNotifier.logout(cause: ...)` through a local in `remote_session_chip.dart`.
/// A regex tight enough to match only the first misses the second, which is the one
/// failure mode a census cannot afford — a false negative here is a field bug,
/// while a false positive is a comment on the allowlist. `.logout(` alone is too
/// wide in the other direction: four `lib/core/` files call the USP protocol's own
/// `_usp.logout()` / `_client.logout()` on a transport, and those mention
/// `authProvider` zero times, which is measured rather than assumed.
///
/// The under-approximation the review names is real and unfixed by any regex: a
/// core file that ends the session through a helper matches neither needle. The one
/// helper that exists is caught by name below; a second one would not be, and no
/// source scan can see it. That is the standing limit of this instrument.
bool _endsAppSession(String stripped) =>
    stripped.contains('authProvider') && stripped.contains('.logout(');

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
  late final Map<String, String> rawSources = {
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.startsWith('lib/l10n/')))
      f.path: f.readAsStringSync(),
  };

  late final Map<String, String> sources = {
    for (final e in rawSources.entries) e.key: _stripComments(e.value),
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

  test('_endsAppSession separates the app session from a transport', () {
    // Fixture-testing the matcher, which round 2's review asked for and which the
    // corpus cannot provide: every real file is either a match or not, so nothing
    // in `lib/` demonstrates that the *pairing* is what does the separating. These
    // four cases do. Each is a spelling that exists in the tree, reduced to the
    // line that decides it.
    const cases = <String, bool>{
      // The common form, and the one all three removed exits in
      // app_connection_state_provider.dart used.
      'ref.read(authProvider.notifier).logout();': true,
      // remote_session_chip.dart's form: the receiver is a local, so a regex
      // anchored on `authProvider.notifier).logout` would miss it. This is the
      // false negative the pairing exists to avoid.
      'final authNotifier = ref.read(authProvider.notifier);\n'
          'authNotifier.logout(cause: EndCause.userRequested);': true,
      // The USP protocol closing a connection. Four lib/core/ files do this and
      // none of them is this rule's subject; `.logout(` alone would name them all.
      'await _usp.logout();': false,
      // Reading auth without ending anything.
      'final isLoggedIn = ref.read(authProvider).value != null;': false,
    };
    for (final entry in cases.entries) {
      expect(_endsAppSession(_stripComments(entry.key)), entry.value,
          reason: 'expected _endsAppSession to be ${entry.value} for:\n'
              '${entry.key}');
    }
  });

  test('the core exit census depends on the stripper, and says so', () {
    // The precise false positive round 2 found, pinned rather than argued away.
    // `app_connection_state_provider.dart` — the file this whole group exists to
    // keep clean — still contains `.logout(` in its own prose, because the prose
    // documents the three calls that were removed. The census passes only because
    // `_stripComments` takes them out first.
    //
    // Asserting both halves means a stripper that stopped removing trailing
    // comments fails *here*, naming the file and the mechanism, instead of failing
    // the census below with a message about layer violations that would send the
    // next reader looking for a logout() that is not there. And deleting the prose
    // to make some future census green would fail here too, which is the point:
    // the explanation is load-bearing.
    const core =
        'lib/core/connection/providers/app_connection_state_provider.dart';
    expect(rawSources[core], contains('.logout('),
        reason: '$core no longer documents the logout() calls #1323 removed. '
            'If the prose was deleted, restore it; this census reads as "core '
            'never signed anyone out", which is the opposite of the history.');
    expect(_endsAppSession(sources[core]!), isFalse,
        reason:
            '$core reads as a session-ending file after stripping. Either it '
            'has genuinely regained a logout() call — the defect #1323 closed — '
            'or _stripComments has stopped removing the comments that mention '
            'one. Check which before touching the census.');
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
      // The matcher, its coarseness and the reason the coarseness points the way
      // it does are all on `_endsAppSession`; the fixture test above is what keeps
      // that argument honest. Two extra discovery keys here, because the sink has
      // two entry points and both end a session without naming `authProvider`:
      // the verb, and — added after round 3 — the wiring, which reaches the verb
      // twice over (the catch-up read and the subscription). A `lib/core/` file
      // calling either is the same layer violation one indirection further out.
      //
      // The wiring key overlaps with `the consumer is actually subscribed to
      // something` below, which would also red on a third caller. The overlap is
      // the point: that test fails with a message about the subscription being
      // duplicated, this one fails naming the layer rule that was broken, and only
      // one of those sends the next reader to the right argument.
      final callers = sources.entries
          .where((e) => e.key.startsWith('lib/core/'))
          .where((e) =>
              _endsAppSession(e.value) ||
              e.value.contains('endSessionIfCoreReportedOne(') ||
              e.value.contains('listenForCoreSessionExit('))
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
            'to move somewhere that will be mounted again after any of those three '
            'exits can fire; the reachability argument, and why "always mounted" '
            'was the wrong thing to claim, are on listenForCoreSessionExit.',
      );
    });

    test('the consumer is actually subscribed to something', () {
      // The census above pins where the verb *lives*; this one pins that something
      // calls it. They were the same file until round 2 of the review, and that is
      // exactly why neither of them saw the mutation that matters: deleting the
      // three-line `listenManual` out of the shell's initState left the verb, its
      // file, and all fourteen tests over both untouched, and disabled every
      // automatic path out of a dead session.
      //
      // Both entries are expected. `_sessionSink` holds the definition and the
      // catch-up read inside `listenForCoreSessionExit` itself; `_sessionSinkWiring`
      // is the only caller. Deleting either one reds this.
      final wiring = filesMatching(RegExp(r'listenForCoreSessionExit\('));

      expect(
        wiring,
        [_sessionSink, _sessionSinkWiring],
        reason: 'expected listenForCoreSessionExit to be defined in '
            '$_sessionSink and called from $_sessionSinkWiring, found $wiring. '
            'One entry means the subscription was deleted and the verb is now '
            'dead code: three exits in app_connection_state_provider.dart set a '
            'state and an EndCause that nothing will ever read, so the user stays '
            'signed in on a router that is gone, factory-reset, or a different '
            'router entirely. More than two means a second subscriber racing for '
            'a value takePendingSessionExit clears on read.',
      );

      // Round 3: the file list above is not a call graph. It cannot tell the
      // declaration from a call, nor one call from three, and both distinctions are
      // load-bearing — so count, and then say where the one call has to sit.
      expect(
        _countOccurrences(sources[_sessionSink]!, 'listenForCoreSessionExit('),
        1,
        reason: 'expected $_sessionSink to hold the declaration and nothing '
            'else. A second occurrence here is the function calling itself or a '
            'second wiring helper beside it, and either way the list above still '
            'reads as "defined in one file, called from one other".',
      );
      expect(
        _countOccurrences(
            sources[_sessionSinkWiring]!, 'listenForCoreSessionExit('),
        1,
        reason:
            'expected exactly one call in $_sessionSinkWiring, which is the '
            'whole of the wiring. Two would be two subscriptions and two '
            'catch-up reads on one shell, competing for a one-shot cause: '
            'whichever ran second would find null and do nothing, so the bug '
            'this produces is not a double sign-out but a silent dependence on '
            'which one won.',
      );
      expect(
        sources[_sessionSinkWiring],
        matches(RegExp(r'void initState\(\)[^}]*listenForCoreSessionExit\(')),
        reason:
            'expected the call in $_sessionSinkWiring to sit in the State\'s '
            'initState. `ref.listenManual` is scoped to the State, so wiring it '
            'from `build` — or from a `Consumer` builder — subscribes again on '
            'every rebuild, and the shell rebuilds on every route change under '
            '/usp*. That is the same one-shot race as above, arrived at without '
            'anyone writing a second call.\n'
            'This pattern is deliberately stricter than the property: `[^}]*` '
            'forbids any closing brace between `initState() {` and the call, so '
            'it also reds for a call that is still in initState but sits after '
            'another block — which is harmless. A regex cannot balance braces, '
            'and ordering inside initState is not load-bearing, so the strictness '
            'costs a one-line move and buys an assertion that cannot be satisfied '
            'from inside `build`. If this is what failed, move the call up rather '
            'than widening the pattern.',
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

    test('only the local surface produces ReturnToLoginAction', () {
      // The premise `exitToLogout()`'s docstring rests on, pinned as a grep.
      //
      // That method now records EndCause.userRequested where a bare logout()
      // defaulted to sessionLost, and the argument that this is inert spans three
      // files and one empty method body: the only caller is ReturnToLoginAction,
      // only LocalSurface returns it, and LocalSessionStrategy.end ignores its
      // cause. The middle link is the one a future edit breaks silently — a remote
      // build that starts offering "Return to login page" would send
      // userRequested into RemoteSessionStrategy.end, which *does* read it, and
      // release the Guardian session on what the operator meant as a retreat to a
      // login form that a one-shot token cannot use.
      //
      // Both entries are expected: `_exitActions` matches on its own constructor
      // declaration. Left broad rather than narrowed to `ReturnToLoginAction()`
      // with empty parens, which would exclude the declaration and also miss a
      // producer that passed a `key:` — the same false-negative trade the census
      // above declines.
      final producers = filesMatching(RegExp(r'ReturnToLoginAction\('));

      expect(
        producers,
        [_exitActions, 'lib/page/_shared/mode/local_surface.dart'],
        reason: 'expected LocalSurface.sessionExitAction() to be the only '
            'producer of ReturnToLoginAction, found $producers. If a remote or '
            "shared surface now returns it, exitToLogout()'s "
            'EndCause.userRequested stops being inert — re-read that docstring '
            'before adding the entry here.',
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
