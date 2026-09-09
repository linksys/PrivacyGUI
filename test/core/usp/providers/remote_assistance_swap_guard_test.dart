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
// #1474 PHASE 9 NARROWED THE DISPOSAL ASSERTION, WHICH IS THE OPPOSITE MOVE FROM
// PHASE 5's AND FOR THE SAME REASON. Phase 5 could widen because the one legitimate
// exception went away; phase 9 has to narrow because a new legitimate case arrived —
// releasing a wasm handle that no façade ever took ownership of, which is the other
// half of #1322's ownership question. A blanket `isNot(contains('dispose()'))` would
// have forbidden the fix rather than the bug, so it became an exact census of the
// disposal sites. See that test for why the census is stronger on the axis that
// matters.
//
// Overlaps `remote_assistance_provider_test.dart`'s "no production path frees the
// registered UspClient façade" on purpose, and neither subsumes the other: that
// one sweeps all of `lib/` for `unregister<UspClient>`, this one is narrow enough
// to also demand the positive — `rebindFromBuilder` is present, and the only
// `dispose()` calls are the two that name a façade GetIt never received.

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

    test('the release is conditional on nobody having taken the handle', () {
      // The one arm of the ownership rule no VM test can reach, and the reason it
      // gets a structural pin: `handleOwned` only becomes true after a façade has
      // successfully wrapped the handle, and wrapping is precisely what fails off
      // the web platform — so the behavioural tests in
      // `remote_assistance_provider_test.dart` always run the *other* branch. A
      // mutation that released unconditionally passed all of them.
      //
      // Releasing when a façade did take ownership is a double free, and it frees
      // the handle the registered façade is using: #1322's field symptom exactly,
      // `null pointer passed to rust` across 41 services that never asked for a new
      // session.
      expect(providerFile, contains('if (!handleOwned) {'),
          reason:
              'the orphan release is no longer guarded by ownership. Freeing a '
              'handle a façade already took is a double free of the live '
              'connection — see #1322. If the flag was renamed, re-point this; if '
              'ownership is tracked some other way, the new spelling has to make '
              'the same distinction and this assertion has to follow it.');
    });

    test('the only façades it disposes are ones GetIt never saw', () {
      // Was `isNot(contains('dispose()'))` until #1474 phase 9, and the narrowing
      // is the interesting part — the claim did not weaken, it got said properly.
      //
      // The claim was never "no `dispose()` appears in this file". It is "the
      // *registered* façade is never freed", and a blanket ban was an adequate proxy
      // only while the file had no other façade to talk about. Phase 9 gave it one:
      // `activate()` builds the wasm handle outside the mutation lock, so a critical
      // section that throws leaves a live wasm-bindgen object with no reference to
      // `free()` — a leak per failed attempt, on the path a user retries. Fixing it
      // means disposing something, and a ban would have forced the fix to be spelled
      // in a way this test could not read.
      //
      // So: an exact census of the disposal sites, which is strictly stronger than
      // the ban on the axis that matters. Both allowed receivers are provably
      // unreachable from GetIt — one is a local that is nulled the instant
      // `registerSingleton` returns, the other a throwaway wrapper built inside the
      // release path — and any third spelling, including the `getIt<UspClient>()`
      // receiver the old ban was really aimed at, fails here.
      const allowed = {
        // A façade constructed but not yet handed to GetIt. Nulled immediately
        // after `registerSingleton`, so this can only be non-null if registration
        // itself threw.
        'pendingFacade?.dispose();',
        // A wasm handle no façade ever took. Wrapped only to reach `free()` —
        // `UspClientWeb` is private to `lib/core/usp/services/`, so `dispose()` on a
        // throwaway is the one public route to it.
        'UspClient.fromBuilder(jsClient, baseUrl: baseUrl).dispose();',
      };

      final sites = providerFile
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.contains('dispose()'))
          .toSet();

      expect(
        sites.difference(allowed),
        isEmpty,
        reason: 'a new dispose() site appeared in this file: '
            '${sites.difference(allowed)}. Disposing the *registered* façade calls '
            'free() on the WASM client and zeroes __wbg_ptr for all 41 services '
            'holding it by value — that is #1322, and it reproduces only in a '
            'browser as unrelated features failing with "null pointer passed to '
            'rust". A swap disposes the old *transport* via rebindTransport(), '
            'which frees the WASM object exactly once without touching the '
            'instance. If this really is a handle GetIt never received, add it to '
            '`allowed` above with the argument for why it is unreachable.',
      );

      expect(
        allowed.difference(sites),
        isEmpty,
        reason: 'a release site listed above is gone: '
            '${allowed.difference(sites)}. Both exist to stop a wasm handle leaking '
            'when installation fails, so deleting one silently restores the leak — '
            'and a leak is invisible to every other test in this repo. If the '
            'ownership rule was restructured, re-point this list at the new '
            'spelling rather than shortening it.',
      );
    });
  });
}
