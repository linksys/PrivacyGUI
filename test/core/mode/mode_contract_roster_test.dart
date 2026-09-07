// Phase 3 of epic #1474 / acceptance 3b and 3c of #1493: the contract roster
// stays six contracts, one definition each, two implementations each.
//
// THE DECISION GUARDED. Three things at once, all of them shape rather than
// behaviour.
//
//   1. **One definition per contract.** Article IV Rule 4 of the constitution
//      exists because `PreservableContract` was once duplicated, and the
//      duplicate silently broke `LinksysRoute`'s dirty check at runtime — every
//      `is PreservableContract` test returned false for the other copy. The mode
//      contracts are consumed the same way (`AppModeProfile` composes them by
//      type), so a second definition of `TransportStrategy` would give the app
//      two incompatible transports that both compile.
//
//   2. **None of them `sealed`.** `sealed` looks like the right modifier for a
//      closed two-implementation hierarchy, and it would break the test suite:
//      `test/core/usp/mocks.dart` declares `MockSseOperationStrategy extends Mock
//      implements SseOperationStrategy` and `FakeSseOperationStrategy implements
//      SseOperationStrategy` from another library, which `sealed` forbids. Every
//      mode strategy is going to need the same treatment as phases 4-9 fill them
//      in, so the modifier is refused up front rather than discovered later.
//
//   3. **Exactly two implementations each — a Local and a Remote.** This is the
//      claim that the epic replaced 15 scattered mode reads (11
//      `GlobalConfig.remote.isActive` + 4 `BuildConfig.isRemote()`) with a fixed
//      number of classes. A third implementation is not
//      automatically wrong, but it cannot be added without a `switch` arm to
//      select it, so it means a new `AppMode` — and then
//      `composition_root_test.dart` is the file that should be failing too.
//
// The roster also states the negative half of acceptance 3c: a *service* does not
// get a Local/Remote pair. Recovery (phase 4) and the operation guard (phase 6)
// take a strategy as a parameter instead. Without that half, "10 classes" quietly
// becomes 20 as later phases each add their own pair.
//
// HOW IT COULD SILENTLY REVERT. All three are edits a reviewer reads as tidying.
// `sealed` is a *suggestion the IDE makes* for a class with a known set of
// subtypes; the resulting failure is in a different package's mock file, so the
// natural fix looks like "delete that stale mock". A duplicated contract arrives
// via a copied file during a phase-4 rebase. A third implementation arrives as
// "just a variant for tests" — which is what `overrideWithValue` is for.
//
// WHY THIS TEST TYPE. A source scan is the only thing that can see any of it. A
// duplicate definition compiles, `sealed` fails only in *other* files, and an
// implementation count is not observable at runtime at all — nothing enumerates
// the subtypes of an abstract class in Dart. `dart:mirrors` is unavailable under
// Flutter test, and even a behavioural test that pinned every mode would go green
// against a duplicated contract because it would only ever touch one copy.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The six contracts, each mapped to the file that must hold its one definition.
///
/// **This is #1474's own population, and getting it wrong is easy in a way that
/// still reads as 12.** The six are the five new causes plus
/// `SseOperationStrategy` — the one mode contract that already shipped before the
/// epic ("for all six (the five above plus `SseOperationStrategy`)"). It is *not*
/// five causes plus `AppModeProfile`: substituting the profile keeps the census
/// at 12, because the profile also has two implementations, while leaving the
/// pre-existing contract unguarded. Verified by adding a third `implements
/// SseOperationStrategy` under `lib/` with the profile in this map: the whole
/// suite stayed green.
///
/// `SurfaceStrategy` is the odd one among the causes: its implementations live
/// under `lib/page/` (they talk to page state, and `lib/core/` may not depend on
/// `lib/page/`), which is why it is not a member of `AppModeProfile` and has its
/// own composition root.
const _contracts = <String, String>{
  'TransportStrategy': 'lib/framework/mode/transport_strategy.dart',
  'CredentialStrategy': 'lib/framework/mode/credential_strategy.dart',
  'SessionStrategy': 'lib/framework/mode/session_strategy.dart',
  'ProximityStrategy': 'lib/framework/mode/proximity_strategy.dart',
  'SurfaceStrategy': 'lib/framework/mode/surface_strategy.dart',
  'SseOperationStrategy': 'lib/core/usp/services/sse_operation_strategy.dart',
};

/// The profile that composes causes 1-4. Checked for the same two shape rules as
/// a contract, but deliberately **not** for an implementation count.
///
/// It has two today (`LocalModeProfile`, `RemoteModeProfile`, with cloud and demo
/// aliasing local through a labelled constructor), and #1474 §9.1 anticipates a
/// third: *"`CloudModeProfile` becomes a real impl only when something actually
/// differs"*. Pinning 2 here would turn red for doing exactly what the design
/// prescribes — the failure mode of a census that counts the wrong thing.
const _profile = 'AppModeProfile';
const _profilePath = 'lib/core/mode/app_mode_profile.dart';

/// Types that answer a mode question but must NOT be split per mode: they take a
/// strategy instead. Mapped to the phase that introduces or edits them.
const _notPaired = <String, String>{
  'RecoveryProbeService': '#1494 (phase 4)',
  'OperationGuard': '#1496 (phase 6)',
};

void main() {
  /// Every `lib/` Dart file's source, keyed by path, with comment lines removed.
  ///
  /// Stripping `//` (and therefore `///`) lines is the whole correctness of this
  /// file, not tidiness. The contracts' own doc comments name their
  /// implementations repeatedly — `LocalTransportStrategy`, "implements
  /// SurfaceStrategy" and so on appear in prose — and a scan that counted those
  /// would satisfy the "exactly 2" expectations from documentation alone. The
  /// mutation check for this is in the commit message: deleting a real
  /// `implements` clause must turn this file red, and with comments included it
  /// does not.
  late final Map<String, String> sources = {
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')))
      f.path: f
          .readAsStringSync()
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n'),
  };

  /// Paths of every `lib/` file whose code matches [pattern].
  List<String> filesMatching(RegExp pattern) => (sources.entries
      .where((e) => pattern.hasMatch(e.value))
      .map((e) => e.key)
      .toList()
    ..sort());

  /// Total matches of [pattern] across all of `lib/`.
  int countMatches(RegExp pattern) =>
      sources.values.fold(0, (n, src) => n + pattern.allMatches(src).length);

  group('each contract has exactly one definition', () {
    for (final entry in _contracts.entries) {
      final name = entry.key;
      final expectedPath = entry.value;

      test(name, () {
        final decl =
            RegExp(r'^\s*abstract\s+class\s+' + name + r'\b', multiLine: true);
        final holders = filesMatching(decl);

        expect(
          holders,
          [expectedPath],
          reason: '$name must be declared exactly once, in $expectedPath. '
              'Found in $holders. A second definition compiles and then splits '
              'the app in two: AppModeProfile composes strategies by type, so '
              'the copy nothing wires up is simply never selected — the same '
              'silent failure constitution Article IV Rule 4 records for '
              'PreservableContract. If this contract genuinely moved, update '
              '_contracts here and the guide doc.',
        );
      });
    }
  });

  group('no contract is sealed (acceptance 3b)', () {
    for (final name in _contracts.keys) {
      test(name, () {
        final sealedDecl =
            RegExp(r'^\s*sealed\s+class\s+' + name + r'\b', multiLine: true);

        expect(
          filesMatching(sealedDecl),
          isEmpty,
          reason: '$name must not be sealed. It looks correct — two known '
              'implementations — and it breaks the test suite from outside this '
              'library: mocktail fakes like test/core/usp/mocks.dart\'s '
              'MockSseOperationStrategy cannot implement a sealed type declared '
              'in another library. The failure surfaces in the mock file, so the '
              'obvious fix is to delete the mock, which is the wrong end.',
        );
      });
    }
  });

  group('each contract has exactly two implementations (acceptance 3c)', () {
    for (final name in _contracts.keys) {
      test(name, () {
        final impl =
            RegExp(r'\bimplements\s+' + name + r'\b(?!\w)', multiLine: true);
        final count = countMatches(impl);

        expect(
          count,
          2,
          reason: 'expected one Local and one Remote implementation of $name, '
              'found $count in ${filesMatching(impl)}. Fewer means a mode lost '
              'its answer to this cause and the composition root will not '
              'compile. More means a third mode — in which case '
              'composition_root_test.dart should be red as well, and this count '
              'moves with it. A test-only variant is not a reason to add one: '
              'that is what overrideWithValue is for.',
        );
      });
    }
  });

  group('the profile obeys the shape rules but not the count', () {
    test('one definition, not sealed', () {
      expect(
        filesMatching(RegExp(r'^\s*abstract\s+class\s+' + _profile + r'\b',
            multiLine: true)),
        [_profilePath],
        reason: '$_profile must be declared exactly once, in $_profilePath. '
            'Two definitions and the app composes strategies against a type '
            'nothing wires up — Article IV Rule 4 again.',
      );
      expect(
        filesMatching(RegExp(r'^\s*sealed\s+class\s+' + _profile + r'\b',
            multiLine: true)),
        isEmpty,
        reason:
            'same objection as the contracts: sealing forbids out-of-library '
            'subtypes, so test fakes stop compiling.',
      );
    });

    test('at least two implementations, and no upper bound', () {
      // Concatenated, not interpolated: `r'...$_profile...'` is a raw string, so
      // the name would be matched literally and every count would be zero.
      final impls =
          RegExp(r'\bimplements\s+' + _profile + r'\b(?!\w)', multiLine: true);

      expect(
        countMatches(impls),
        greaterThanOrEqualTo(2),
        reason: 'a mode with no profile cannot be composed. Found in '
            '${filesMatching(impls)}. Deliberately not `equals(2)`: #1474 §9.1 '
            'says CloudModeProfile becomes a real implementation once something '
            'actually differs, so an exact count would make the design\'s own '
            'next step a test failure.',
      );
    });
  });

  test('the roster totals 12 implementations, not 20', () {
    final total = _contracts.keys.fold<int>(
      0,
      (n, name) =>
          n +
          countMatches(
              RegExp(r'\bimplements\s+' + name + r'\b(?!\w)', multiLine: true)),
    );

    expect(
      total,
      12,
      reason:
          'six contracts x two modes — #1474\'s published total, and note it '
          'counts SseOperationStrategy\'s pair and NOT the profile\'s: "20 '
          'members, 6 contracts, 12 implementation classes ... plus the 2 that '
          'SseOperationStrategy already has". The number is here as a census: it '
          'is the concrete form of the claim that the mode logic is a fixed set '
          'of classes rather than a growing set of `if`s, and the per-contract '
          'tests above cannot see a *seventh contract* arriving with its own '
          'pair. If a real CloudModeProfile lands, this total does not move — '
          'profiles are not in it.',
    );
  });

  group('the framework does not import either implementation directory', () {
    // Constitution Article XVII Rule 17.1.3, second half. The rule is not about
    // tidiness: a contract that imports `impl/` is a contract coupled to the
    // classes it exists to be independent of, and it arrives through a *value
    // type* rather than through a strategy, which is why it does not look like a
    // layering violation while you are making it. `BridgeConfig` was filed under
    // `lib/core/mode/impl/` in the first cut of phase 3 for exactly that reason —
    // it is built by the two transport strategies, so it looked like theirs —
    // and `transport_strategy.dart` imported the implementation directory to name
    // its own return type. It now lives in `lib/framework/mode/`.
    //
    // Not caught by anything else: it compiles, it passes every behavioural
    // test, and `dart analyze` has no opinion on import direction. The repo has
    // no import-boundary linter.
    const forbidden = <String, String>{
      'core/mode/impl/': 'the four core causes',
      'page/_shared/mode/': 'cause 5',
    };

    final frameworkFiles = sources.keys
        .where((p) => p.startsWith('lib/framework/mode/'))
        .toList()
      ..sort();

    test('there are framework files to check', () {
      // Guards the scan itself: a moved or renamed directory would otherwise
      // make every expectation below pass over an empty list.
      expect(frameworkFiles, isNotEmpty,
          reason:
              'no files under lib/framework/mode/ — the contracts moved, so '
              'this scan is looking at nothing and silently passing. Re-point '
              'it, and move Article XVII Rule 17.1.3 with them.');
    });

    for (final entry in forbidden.entries) {
      test('no contract imports ${entry.key}', () {
        final offenders = frameworkFiles
            .where((p) => sources[p]!.contains(entry.key))
            .toList();

        expect(
          offenders,
          isEmpty,
          reason: 'files under lib/framework/mode/ must not import '
              '${entry.key} (${entry.value}\' implementations). Found in '
              '$offenders. If a contract needs a type to state its signature, '
              'that type is not an implementation detail and belongs in '
              'lib/framework/mode/ beside the contract — which is where '
              'BridgeConfig ended up.',
        );
      });
    }
  });

  group('mode-aware services are not split per mode (acceptance 3c)', () {
    for (final entry in _notPaired.entries) {
      final name = entry.key;
      final phase = entry.value;

      test('$name has no Local/Remote pair', () {
        // `class Local<name>` does not match `defs` — the name must follow
        // `class ` directly — so the two counts below are independent.
        final defs = RegExp(
            r'^\s*(?:abstract\s+|sealed\s+)?class\s+' + name + r'\b',
            multiLine: true);
        final paired = RegExp(
            r'^\s*(?:abstract\s+|sealed\s+)?class\s+(?:Local|Remote)' +
                name +
                r'\b',
            multiLine: true);

        expect(
          countMatches(defs),
          lessThanOrEqualTo(1),
          reason: '$name must have at most one definition; $phase owns it. '
              'Found in ${filesMatching(defs)}.',
        );
        expect(
          filesMatching(paired),
          isEmpty,
          reason:
              '$name answers a mode question by *taking a strategy*, not by '
              'existing twice ($phase). Splitting it duplicates the logic that '
              'is the same in both modes — probing, guarding, logging — so the '
              'two copies drift on everything except the one line that actually '
              'differs. That line belongs in a strategy, and the strategy '
              'already exists.',
        );
      });
    }
  });
}
