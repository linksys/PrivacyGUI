// Design assertion D5 of #1494 (phase 8 of epic #1474): the two Remote
// Assistance sides stay unlinked.
//
// THE DECISION GUARDED. "Remote Assistance" is two subsystems that share a
// protocol, not one subsystem with two screens:
//
//   - The DEVICE side runs in a LOCAL build, on the router being helped. It
//     mints a PIN, shows the consent dialog, and renders the "someone is
//     watching" banner. Its state lives in `remoteClientProvider`.
//   - The AGENT side runs in a REMOTE build, in the supporter's browser. It
//     redeems a session token, confirms the connection, and renders the session
//     chip. Its state lives in `remoteAccessProvider`.
//
// Nothing about the code says which side a file is on. The two providers are
// near-synonyms — `remoteClientProvider` / `remoteAccessProvider` — and they are
// filed in inverted directories: `core/cloud/providers/remote_assistance/` holds
// the *device* side while `providers/remote_access/` holds the *agent* side, so
// the directory named "remote_assistance" is the one that is not the remote end.
// #1494's third part is "name the two RA sides apart"; until a rename lands, the
// classification below is the only place the split is written down, and this file
// is what makes it load-bearing rather than a comment.
//
// HOW IT COULD SILENTLY REVERT. By a helpful refactor, in one of two shapes.
//
//   1. A shared widget pulled into the wrong side. The banner and the chip are
//      both "a strip that says a remote session is live"; deduplicating them
//      into one widget that reads both providers compiles, analyzes clean, and
//      renders correctly in whichever build the author happened to test. The
//      other build then holds a reference to a provider its transport never
//      populates.
//   2. A convenience import for one field. `remote_client_state.dart` and
//      `remote_access_state.dart` both carry a session id and an expiry; either
//      side reaching across for the other's type is a one-line import that no
//      test currently notices.
//
// Both are silent because each side's own tests keep passing: a device-side test
// overrides `remoteClientProvider` and never learns that the widget also watches
// `remoteAccessProvider`, which in a test resolves to its harmless default.
//
// WHY THIS TEST TYPE. The invariant is about the import graph, and the import
// graph is exactly what a behavioural test abstracts over. To catch shape 1 by
// pumping, a test would have to assert that a widget does *not* read a provider —
// which means either enumerating reads (no API for that) or overriding the
// forbidden provider with a throwing stub in every device-side widget test and
// every agent-side one, forever, including the ones not written yet. The scan
// costs one file and covers the ones not written yet by construction.
//
// This test was green the day it was written — there are no crossings today. That
// is the point: it is cheap now precisely because there is nothing to fix, and
// its whole job is to stay green through phases 5, 7 and 9, which move RA code.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The device side: code that only ever runs in a **local** build, on the router
/// being helped.
const _deviceSide = <String>{
  'lib/page/remote_assistance/views/remote_assistance_dialog.dart',
  'lib/page/remote_assistance/views/remote_assistance_banner.dart',
  'lib/page/remote_assistance/views/remote_assistance_session_guard.dart',
  'lib/core/cloud/providers/remote_assistance/remote_client_provider.dart',
  'lib/core/cloud/providers/remote_assistance/remote_client_state.dart',
  'lib/core/cloud/providers/remote_assistance/device_credentials_provider.dart',
};

/// The agent side: code that only ever runs in a **remote** build, in the
/// supporter's browser.
///
/// `route_remote_assistance.dart` is a `part of 'router_provider.dart'`, so it
/// declares no imports of its own and passes the crossing scan trivially. The
/// scan below is text-based and does not follow `part` directives, so a
/// device-side import added to the enclosing library would not show up here — it
/// shows up in the both-sides scan instead, where `router_provider.dart` is not a
/// declared host. The two tests cover each other's blind spot.
const _agentSide = <String>{
  'lib/page/remote_assistance/views/remote_assistance_confirm_view.dart',
  'lib/page/_shared/components/remote_session_chip.dart',
  'lib/providers/remote_access/remote_access_provider.dart',
  'lib/providers/remote_access/remote_access_state.dart',
  'lib/providers/remote_access/stub_html.dart',
  'lib/route/route_remote_assistance.dart',
};

/// Transport and models both sides use. Listed so the inventory check can tell
/// "shared" apart from "unclassified", and deliberately not constrained: shared
/// code importing either side *would* be a violation, but it would be a violation
/// of a different rule than D5 and there is nothing to guard yet.
const _sharedTransport = <String>{
  'lib/core/cloud/guardian_api_client.dart',
  'lib/core/cloud/services/remote_assistance_service.dart',
  'lib/core/cloud/model/guardians_remote_assistance.dart',
  'lib/core/usp/providers/remote_assistance_provider.dart',
  'lib/core/usp/services/sse_remote_strategy.dart',
};

/// The files that legitimately reach into **both** sides.
///
/// One entry, and it is not the one #1494 predicted. The ticket said "with
/// `router_provider.dart` exempt"; measured, the router imports only agent-side
/// files (`remote_access_provider.dart`, `remote_assistance_confirm_view.dart`),
/// so it needs no exemption. The shell is the real crossing: it composes the
/// agent-side chip and the device-side banner and session guard into one app bar,
/// because it is the one widget both builds render.
///
/// A host is not a side. It may reference both because it is deciding *which*
/// build it is in — which is #1474's whole subject, and what phase 7's
/// `SurfaceStrategy` takes over, at which point this set should shrink to empty.
const _bothSidesHosts = <String>{
  'lib/page/shell/usp_dashboard_shell.dart',
};

/// RA files whose *name* carries neither "remote" nor "guardian", and which
/// `find -iname` therefore misses.
///
/// This is why #1494's published inventory reads 15 files / 4,102 lines: that is
/// what the glob returns, not what the subsystem is.
/// `device_credentials_provider.dart` is a 32-line device-side provider that
/// consumes `remoteClientProvider`, and `stub_html.dart` is the agent side's
/// conditional-import shim. Pinned here so the next person to measure the
/// subsystem starts from 17 files rather than re-deriving 15.
const _globBlindSpot = <String>{
  'lib/core/cloud/providers/remote_assistance/device_credentials_provider.dart',
  'lib/providers/remote_access/stub_html.dart',
};

void main() {
  const classified = <String>{
    ..._deviceSide,
    ..._agentSide,
    ..._sharedTransport
  };

  /// Every `package:privacy_gui/…` file [path] mentions, as a `lib/`-relative
  /// path.
  ///
  /// Scans the whole file rather than lines beginning with `import`, on purpose:
  /// the agent side's `stub_html.dart` arrives through a conditional import whose
  /// second URI sits on a continuation line, and `export` re-exposes a dependency
  /// just as effectively as `import` does. Over-matching a URI inside a comment
  /// would fail loudly and be trivially fixable; under-matching a real one is the
  /// failure this file exists to prevent.
  Set<String> privacyGuiRefs(String path) => RegExp(
        r'package:privacy_gui/([A-Za-z0-9_/]+\.dart)',
      )
          .allMatches(File(path).readAsStringSync())
          .map((m) => 'lib/${m.group(1)}')
          .toSet();

  List<String> libDartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path)
      .where((p) => p.endsWith('.dart'))
      .toList()
    ..sort();

  group('the two Remote Assistance sides stay unlinked', () {
    test('every classified path still exists', () {
      final missing = classified.where((p) => !File(p).existsSync()).toList()
        ..sort();

      expect(
        missing,
        isEmpty,
        reason:
            'These files moved or were renamed. Update the classification — '
            'a stale path silently narrows every scan below, which is the one '
            'way this file can rot into a no-op. If the move is #1494\'s '
            '"name the two RA sides apart" rename, this is the diff that '
            'records which side each new name is on.',
      );
    });

    test('every RA file in lib/ is classified', () {
      final globFound = libDartFiles().where((p) {
        final name = p.split('/').last.toLowerCase();
        return name.contains('remote') || name.contains('guardian');
      }).toSet();

      expect(
        globFound.difference(classified),
        isEmpty,
        reason: 'New Remote Assistance files that no side owns. Add each to '
            '_deviceSide, _agentSide or _sharedTransport — the choice is the '
            'design decision, and leaving it unmade means the scans below do not '
            'cover the file.',
      );

      expect(
        classified.difference(globFound),
        _globBlindSpot,
        reason: 'The set of RA files that a name-based glob cannot find has '
            'changed. Update _globBlindSpot, and re-measure any published file '
            'or line count that was taken from such a glob.',
      );
    });

    test('no file on one side imports the other', () {
      final crossings = <String>[];
      // Explicit (side, other) pairs. Deriving `other` from `side == _deviceSide`
      // would be reference equality on a `Set` — and if the two const sets ever
      // held identical contents, Dart would canonicalise them into one instance,
      // making `other` always `_agentSide` and reducing this scan to comparing a
      // set against itself. Green, and blind in both directions.
      for (final (side, other) in [
        (_deviceSide, _agentSide),
        (_agentSide, _deviceSide),
      ]) {
        for (final file in side.toList()..sort()) {
          final hits = (privacyGuiRefs(file).intersection(other).toList()
                ..sort())
              .join(', ');
          if (hits.isNotEmpty) crossings.add('$file -> $hits');
        }
      }

      expect(
        crossings,
        isEmpty,
        reason: 'A device-side file imports the agent side or vice versa. The '
            'importing side now holds a reference to a provider its own '
            'transport never populates — in a local build `remoteAccessProvider` '
            'is never activated, and in a remote build `remoteClientProvider` is '
            'never activated, so the reference reads a default state that looks '
            'like "no session" rather than failing. If the two really do need '
            'the same thing, lift it into _sharedTransport.',
      );
    });

    test('only the declared hosts reference both sides', () {
      final hosts = <String>[];
      for (final file in libDartFiles()) {
        // Skips everything already classified, shared transport included. Shared
        // code touching both sides is plausible — `remote_client_state.dart` and
        // `remote_access_state.dart` both carry a session id and an expiry — but
        // it is not the failure this test diagnoses, and reporting it with this
        // test's message would name the wrong cause. It has no assertion of its
        // own yet because there is no decision to guard: nothing shared imports
        // either side today.
        if (classified.contains(file)) continue;
        final refs = privacyGuiRefs(file);
        if (refs.intersection(_deviceSide).isNotEmpty &&
            refs.intersection(_agentSide).isNotEmpty) {
          hosts.add(file);
        }
      }

      expect(
        hosts.toSet(),
        _bothSidesHosts,
        reason:
            'A file outside the declared hosts pulls in both RA sides. That '
            'is the shape D5 is aimed at: one widget serving both builds, which '
            'compiles and renders correctly in whichever build its author '
            'tested. If it genuinely hosts both — a shell, a router — add it to '
            '_bothSidesHosts and say why in the doc comment. If it is one side\'s '
            'widget that reached across, it belongs on that side.',
      );
    });
  });
}
