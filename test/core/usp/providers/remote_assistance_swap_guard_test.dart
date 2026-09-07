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
// way to swap a GetIt singleton, and it is what this code did for its whole life
// before #1322. Nothing else objects: it compiles, the first activation of any
// session behaves identically, and the failure only appears on a second
// activation in one page lifetime, as `null pointer passed to rust` somewhere far
// from here.
//
// #1323 PHASE 5 WIDENED THIS SCAN, AND THE WIDENING IS THE POINT. It used to
// slice the region between `activate(` and `deactivate(`, because `deactivate()`
// legitimately unregistered and disposed — it was tearing the session down rather
// than replacing it — so a whole-file scan would have been permanently red. The
// original header warned that the two adjacent methods looked inconsistent and
// that a reviewer would be tempted to "fix" the one that was right; what actually
// happened is the reverse, and better: acceptance 10 of #1323 measured
// `deactivate()` to have **zero production callers** and deleted it. With the one
// legitimate exception gone, the exception in this scan goes too, and the claim
// gets stronger — *no code in this file* frees or replaces the façade, not merely
// `activate()`.
//
// This test's end anchor was the only thing that noticed the deletion. It failed
// with the reason string it had been given for exactly this case, which is the
// argument for writing anchor assertions at all: a slice whose end silently
// becomes `-1` reads the whole file, and a `isNot(contains(...))` over a region
// that grew is still green.
//
// Overlaps `remote_assistance_provider_test.dart`'s "no production path frees the
// registered UspClient façade" on purpose, and neither subsumes the other: that
// one sweeps all of `lib/` for `unregister<UspClient>`, this one is narrow enough
// to also demand the positive — `rebindFromBuilder` is present, and no `dispose()`
// of any kind appears.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Everything from `//` to end of line, dropped.
///
/// The reason this exists: the source it scans *documents* the pattern it forbids
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

  late String providerFile;

  setUpAll(() {
    expect(file.existsSync(), isTrue,
        reason: '${file.path} moved — re-point this scan');
    final source = file.readAsStringSync();

    // Whole file since #1323 phase 5 removed `deactivate()`, which was the one
    // member allowed to unregister and dispose. Nothing here is scoped any more,
    // so nothing has to stay in step with a second method's name.
    expect(source, contains('Future<void> activate('),
        reason:
            'activate() was renamed or removed. If it was renamed, re-point '
            'the assertions below; if it was removed, the register-vs-rebind '
            'decision moved somewhere else and this whole file has to follow it '
            'there — do not just delete it.');

    providerFile = _stripComments(source);
  });

  group('activate() rebinds rather than replacing the UspClient', () {
    test('the stripped source is still recognisable code', () {
      // Guards the guard: an over-eager strip (a `://` in a URL literal, say)
      // would empty the source and make every assertion below vacuous.
      expect(providerFile, contains('getIt.isRegistered<UspClient>()'));
      expect(providerFile, contains('uspMutationLockProvider'));
      expect(providerFile, isNot(contains('#1322')),
          reason: 'comment stripping is not working, so the assertions below '
              'can be satisfied by the prose that explains them');
    });

    test('it re-points the existing instance', () {
      expect(providerFile, contains('rebindFromBuilder'),
          reason: 'the registered UspClient must be re-pointed at the new '
              'Guardian session. 41 services hold this instance by value and '
              'never re-read it.');
    });

    test('it never unregisters the singleton', () {
      expect(providerFile, isNot(contains('unregister')),
          reason:
              'unregister + registerSingleton changes the instance, and the '
              '41 ref.read holders keep the old one. Use rebindFromBuilder.');
    });

    test('it never disposes a UspClient', () {
      expect(providerFile, isNot(contains('dispose()')),
          reason: 'disposing the façade calls free() on the WASM client and '
              'zeroes __wbg_ptr for everyone still holding it. '
              'rebindTransport() disposes the old *transport* instead, so the '
              'WASM object is still freed exactly once per swap.');
    });
  });
}
