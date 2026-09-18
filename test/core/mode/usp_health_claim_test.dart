// #1576 — the claim that Guardian does not serve `/usp/health` must not come back.
//
// THE DECISION GUARDED. Not "the new call exists" — that is what the behaviour tests
// in `recovery_strategies_test.dart` are for. This file guards the *absence* of a
// sentence, because #1576's acceptance says so explicitly and the reason is measured:
// a scan for the new call passes green with the wrong comment sitting next to it, and
// the wrong comment is what propagated.
//
// It propagated to **four** places from one docstring — `sse_providers.dart`,
// `remote_transport_strategy.dart`, `bridge_endpoints_test.dart` and the waiver list
// in `composition_root_test.dart` — plus #1474's issue body, over a release cycle,
// while Guardian served the path all along. Each copy read as independent
// corroboration of the others.
//
// HOW IT COULD SILENTLY REVERT. Someone reads `BridgeEndpoints.remote()`'s `health`
// line, remembers "wasn't that a fabrication?", and writes the note back. Nothing in
// the type system or in any behavioural test objects, because the note is a comment;
// the code keeps working and the next reader inherits the false premise again.
//
// WHY THIS TEST TYPE. A source scan, which is the only honest oracle for "no file
// says X". It reads `lib/` and the four files above as text.
//
// WHAT IT DOES NOT CLAIM. That the endpoint is deployed on QA. That is #1575's
// verification item 3, still open on 2026-09-18, and it is why
// `RemoteTransportStrategy` keeps a 404 fallback. A test cannot check someone else's
// deployment; it can check that we stopped asserting the opposite of the contract.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phrases that only occur in a sentence denying the endpoint exists.
///
/// Deliberately narrow. The scan has to pass over files that legitimately discuss
/// the history — this file, and the two comments in `lib/` that explain what
/// #1576 replaced — so the needles match the *claim* rather than the topic. Each
/// one is a phrase from a real copy of the note, lowercased.
const _denials = <String>[
  'guardian has no health',
  'guardian has no such endpoint',
  'guardian does not serve',
  'health` path is a fabrication',
  'health path is a fabrication',
  'no health or turbo',
];

/// Files outside `lib/` that carried the claim and had to be corrected.
///
/// Named rather than globbed over `test/`: these three are the copies #1576 found,
/// and naming them means a future reader of a failure knows the set is a decision.
/// A new copy in some other test file would be missed — which is the honest limit of
/// this scan, and the reason `lib/` is swept whole.
const _correctedTestFiles = <String>[
  'test/core/usp/services/bridge_endpoints_test.dart',
  'test/core/mode/composition_root_test.dart',
  'test/core/mode/impl/recovery_strategies_test.dart',
];

Iterable<File> _dartFilesUnder(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  test('no file claims Guardian does not serve /usp/health', () {
    final offenders = <String>[];

    for (final file in [
      ..._dartFilesUnder('lib'),
      ..._correctedTestFiles.map(File.new),
    ]) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].toLowerCase();
        for (final denial in _denials) {
          if (line.contains(denial)) {
            offenders.add('${file.path}:${i + 1}  ${lines[i].trim()}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Guardian\'s own OpenAPI spec serves '
          '`/v1/guardians/remote-assistances/sessions/{id}/usp/health`, at exactly '
          'the path `BridgeEndpoints.remote()` has always declared. #1576 deleted '
          'the remote-mode skip in `sseBootstrapProvider` and pointed '
          '`RemoteTransportStrategy.isRouterReachable` at it.\n\n'
          'If you are re-adding one of these sentences because a call to it '
          'failed: a 404 means that deployment has not shipped the endpoint yet '
          '(#1575 verification item 3), which the probe already handles by falling '
          'back. It does not mean the path is wrong.\n\n'
          'Found:\n${offenders.join('\n')}',
    );
  });

  test(
      'the probe reads health, and the fallback is dated rather than permanent',
      () {
    // The positive half, and it is deliberately weaker than the scan above: it
    // pins that the 404 arm still says when it goes away. A hedge with no end
    // date is the thing that becomes permanent, and this one is a *deployment*
    // hedge — `dev-phase-no-fw-back-compat` would rule out a firmware one
    // outright, so the distinction has to survive in the comment.
    final source = File('lib/core/mode/impl/remote_transport_strategy.dart')
        .readAsStringSync();

    expect(source, contains('bridge.health()'));
    expect(source, contains('_reachableViaSerialNumber'),
        reason: 'the pre-#1576 read is kept only for a deployment with no '
            '/usp/health');
    expect(source, contains('#1575'),
        reason: 'the fallback must name the verification item that retires it, '
            'or nobody will know it is removable');
  });
}
