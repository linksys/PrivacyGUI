// #1474 phase 9 (#1498): Remote Assistance session *entry* funnels through
// `SessionStrategy.start()`, and nothing else in `lib/` may open one.
//
// The mirror of `session_teardown_call_sites_test.dart`, and it exists for the same
// reason that file gives: the defect a call-site census catches is never a wrong
// line of code, it is a right line of code that only one call site has. Phase 9
// moved the three steps of RA entry out of `remote_assistance_confirm_view.dart`'s
// `_doConnect` and into `RemoteSessionStrategy.start`. Nothing stops the next
// feature — a second entry surface, a deep link handler, a "reconnect" button —
// from building a `RemoteAssistanceConfig` and calling `activate()` itself, and if
// it does, every test in this repo still passes: the copy works.
//
// WHAT THE COPY LOSES. Not the activation — `activate()` is idempotent since #1322
// and sets `loginType` and rebinds credentials on its own. Three other things, none
// of which fail at the call site:
//
//   - **the Guardian the session points at.** `start` reads `kCloudBase` and
//     `kClientTypeId` itself rather than taking them, so no caller can aim a session
//     at the wrong environment. A hand-built config is exactly the freedom
//     [SupportSessionRequest] was sealed to remove, and getting it wrong produces a
//     live-looking session against a QA Guardian.
//   - **the order.** `updateSessionInfo` starts the expiry countdown and the status
//     poll; running it before the transport exists gives a ticking clock over a dead
//     connection, and a copy that reads top-to-bottom from the old view is as likely
//     to get this backwards as right.
//   - **the pairing with cause 3's `end`.** `endSessionForCA` + `clearSession()` are
//     already funnelled (see the teardown census). An entry that does not go through
//     `start` still gets torn down by `end`, so the asymmetry is silent: state that
//     `start` would have set is simply missing when `end` clears it.
//
// NOT SYMMETRIC WITH THE LOCAL ARM, deliberately. `LocalSessionStrategy.start`'s two
// steps — `tryUspLogin` and `fetchDeviceInfoAndInitializeServices` — have other
// legitimate callers (`login_local_view.dart`, and the router's own prepare step),
// because locally `start` is *sequencing* calls that the app makes elsewhere for
// other reasons. The remote arm is the opposite: its three calls have no correct use
// outside session entry. Censusing the local names would forbid the PnP and prepare
// paths, which is why only one mode appears below.
//
// WHY A SOURCE SCAN. Same answer as the teardown census: the risk is the call site
// that does not exist yet, and no test that names its subject can be written before
// its subject exists.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one file allowed to open a Remote Assistance session.
const _sessionStrategy = 'lib/core/mode/impl/remote_session_strategy.dart';

/// Where the notifier and its config type are declared.
///
/// Allowed to name `RemoteAssistanceConfig` because it *is* the declaration — the
/// constructor and the `toString` interpolation both match the census key below.
/// Excluding the file instead of listing it would make the scan blind to a real
/// construction added here later, and this file is where a "convenience" factory
/// would most plausibly be written.
const _provider = 'lib/core/usp/providers/remote_assistance_provider.dart';

void main() {
  /// Every `lib/` Dart file's source with `//` comments removed, l10n excluded.
  ///
  /// Comment-stripping is load-bearing: all three census keys are named in prose by
  /// files that must not be callers. `remote_assistance_confirm_view.dart` documents
  /// what phase 9 took out of `_doConnect`, `remote_transport_strategy.dart` and
  /// `session_entry.dart` name `remoteAssistanceProvider` in their own docs, and
  /// `di.dart` explains that `activate()` is the only thing that can create the
  /// session client. A scan that read comments would report every one of those
  /// explanations as a violation and be un-greenable without deleting the
  /// documentation that makes this seam legible.
  ///
  /// Trailing comments too, not just whole comment lines, and `(?<!:)` so a `https://`
  /// inside a string literal is not read as the start of one. Same expression as
  /// `session_teardown_call_sites_test.dart` and
  /// `remote_assistance_swap_guard_test.dart`, deliberately: three guards over the
  /// same corpus disagreeing about what counts as a comment is a way for one of them
  /// to be quietly weaker than it reads.
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
    // Guards the guard. Every assertion below is a match against `sources`, and an
    // over-eager strip that emptied the corpus would turn all three censuses green
    // — nothing matches, so nothing is a caller — while reporting nothing at all.
    expect(sources[_sessionStrategy], contains('class RemoteSessionStrategy'));
    expect(sources[_provider], contains('class RemoteAssistanceNotifier'),
        reason: '$_provider stripped down to something with no notifier in it');
  });

  group(
      'RA session entry funnels through SessionStrategy.start (acceptance 10)',
      () {
    test('only the session strategy reaches the activation notifier', () {
      // The narrowest true key. `activate` is a plausible method name for anything,
      // so a bare `\.activate\(` would red the suite the day an unrelated notifier
      // grows one; `remoteAssistanceProvider.notifier` cannot be reached by
      // accident and is the only route to `activate()` there is. A caller that
      // resolves the notifier into a local variable first still matches, because
      // the read is what this finds.
      final callers =
          filesMatching(RegExp(r'remoteAssistanceProvider\.notifier'));

      expect(
        callers,
        [_sessionStrategy],
        reason:
            'RemoteAssistanceNotifier must be driven from $_sessionStrategy '
            'alone, found $callers. Everything a second caller needs to get right '
            'is invisible at its own call site: which Guardian the session points '
            'at (start reads kCloudBase itself, so that it cannot be passed '
            'wrongly), and that updateSessionInfo runs after the transport exists '
            'rather than before it. If a new surface needs to open a session, give '
            'it a SupportSessionRequest and call start().',
      );
    });

    test('only the session strategy builds a session configuration', () {
      // The second discovery key, and it catches a caller the first would miss: one
      // that constructs the config and hands it to something else to activate. Both
      // halves are needed because either alone is a complete entry path.
      final builders = filesMatching(RegExp(r'RemoteAssistanceConfig\('));

      expect(
        builders,
        [_sessionStrategy, _provider]..sort(),
        reason:
            'a session configuration is built outside $_sessionStrategy, in '
            '$builders. The type is deliberately not something a view should '
            'assemble: guardianBaseUrl and clientTypeId come from build '
            'configuration, and a hand-assembled one is the freedom '
            'SupportSessionRequest was sealed to remove — see #1357 item 1. '
            '($_provider is expected here: it declares the class.)',
      );
    });

    test('only the session strategy records the engagement', () {
      // A leading dot, so this finds invocations and not the declaration in
      // `remote_access_provider.dart`. This is the *ordering* half of `start`, and
      // the one with no crash to announce it: a countdown and a status poll running
      // against a connection that does not exist yet look like a Guardian outage.
      final callers = filesMatching(RegExp(r'\.updateSessionInfo\('));

      expect(
        callers,
        [_sessionStrategy],
        reason:
            'updateSessionInfo must be called from $_sessionStrategy alone, '
            'found $callers. It has to run after activate() — it starts the expiry '
            'countdown, the status poll and the UI restrictions, all of which read '
            'as a broken session if the transport is not up. Note the pairing this '
            'protects: clearSession() is already funnelled to the same file by '
            'session_teardown_call_sites_test.dart, so an entry path that skips '
            'this call leaves cause 3 clearing state nobody set.',
      );
    });
  });
}
