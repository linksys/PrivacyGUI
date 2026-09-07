// #1322: `activate()` re-points the USP connection, it never frees the façade.
//
// WHAT THIS GUARDS, AND WHY IT IS A SOURCE SCAN. The behaviour — "a reference
// captured before a swap keeps working and reads the new session" — is tested for
// real in `test/core/usp/services/usp_client_rebind_test.dart`, at the
// `UspClient.rebindTransport` seam. What cannot be tested for real is that
// `activate()` is the thing that calls it.
//
// `activate()` opens with `if (!kIsWeb) throw UnsupportedError(...)` (with a test
// of its own asserting exactly that, in `remote_assistance_provider_test.dart`)
// and everything past it builds a wasm-bindgen object through
// `UspClientBuilderJS`. So #1322's AC 5, "two consecutive `activate()` calls on
// one container", is not reachable from the VM at all. The two ways to make it
// reachable are deleting the platform guard or adding an injectable global — and
// #1474's falsification criterion 2 exists to stop the second one arriving for a
// test's benefit.
//
// So this file asserts the four lines that choose register-vs-rebind, and says so
// rather than dressing a structural check as a behavioural one.
//
// HOW IT WOULD SILENTLY REVERT. `unregister` + `registerSingleton` is the obvious
// way to swap a GetIt singleton, it is what this code did for its whole life
// before #1322, and `deactivate()` twelve lines below still does exactly that —
// correctly, because it is tearing the session down rather than replacing it. A
// reviewer comparing the two methods would see an inconsistency and be tempted to
// "fix" the one that is right. Nothing else objects: it compiles, the first
// activation of any session behaves identically, and the failure only appears on
// a second activation in one page lifetime, as `null pointer passed to rust`
// somewhere far from here.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Everything from `//` to end of line, dropped.
///
/// The reason this exists: the region it scans *documents* the pattern it forbids
/// — "#1322: re-point the registered façade, do NOT free it" sits directly above
/// the rebind call, and the class doc explains what `dispose()` used to do. A scan
/// that keeps comments therefore matches its own explanation and passes no matter
/// what the code does. That is not hypothetical; it is the bug this project's
/// phase-1 census guard shipped with and had to be fixed.
///
/// `://` is excluded because this region is about URLs. Truncating a line at the
/// scheme separator would silently delete real code and turn the `isNot(contains)`
/// assertions below into a pass — a comment stripper that over-strips fails the
/// same way as one that under-strips, just less visibly.
final _comment = RegExp(r'(?<!:)//.*$');

String _stripComments(String source) => source
    .split('\n')
    .map((line) => line.replaceFirst(_comment, ''))
    .join('\n');

void main() {
  final file = File('lib/core/usp/providers/remote_assistance_provider.dart');

  late String activateBody;

  setUpAll(() {
    expect(file.existsSync(), isTrue,
        reason: '${file.path} moved — re-point this scan');
    final source = file.readAsStringSync();

    // Scoped to `activate()`. `deactivate()` legitimately unregisters and
    // disposes, so a whole-file scan would either be permanently red or have to
    // be weakened until it proved nothing.
    final start = source.indexOf('Future<void> activate(');
    final end = source.indexOf('Future<void> deactivate(');
    expect(start, isNot(-1),
        reason: 'activate() was renamed — re-anchor this scan');
    expect(end, greaterThan(start),
        reason: 'deactivate() no longer follows activate() — this scan slices '
            'the region between them and would otherwise read the whole file');

    activateBody = _stripComments(source.substring(start, end));
  });

  group('activate() rebinds rather than replacing the UspClient', () {
    test('the stripped region is still recognisable code', () {
      // Guards the guard: an over-eager strip (a `://` in a URL literal, say)
      // would empty the region and make every assertion below vacuous.
      expect(activateBody, contains('getIt.isRegistered<UspClient>()'));
      expect(activateBody, contains('uspMutationLockProvider'));
      expect(activateBody, isNot(contains('#1322')),
          reason: 'comment stripping is not working, so the assertions below '
              'can be satisfied by the prose that explains them');
    });

    test('it re-points the existing instance', () {
      expect(activateBody, contains('rebindFromBuilder'),
          reason: 'the registered UspClient must be re-pointed at the new '
              'Guardian session. 41 services hold this instance by value and '
              'never re-read it.');
    });

    test('it never unregisters the singleton', () {
      expect(activateBody, isNot(contains('unregister')),
          reason:
              'unregister + registerSingleton changes the instance, and the '
              '41 ref.read holders keep the old one. Use rebindFromBuilder.');
    });

    test('it never disposes a UspClient', () {
      expect(activateBody, isNot(contains('dispose()')),
          reason: 'disposing the façade calls free() on the WASM client and '
              'zeroes __wbg_ptr for everyone still holding it. '
              'rebindTransport() disposes the old *transport* instead, so the '
              'WASM object is still freed exactly once per swap.');
    });
  });
}
