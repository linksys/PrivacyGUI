// #1496 phase 6, acceptance 6 — the half Dart cannot enforce.
//
// The acceptance asks that "adding a destructive operation without a
// `DisruptionClass` does not compile". Half of that is real and is already the
// compiler's job: `ProximityStrategy.canRecoverFrom` switches over
// `DisruptionClass` with no `default:`, so a new *class* cannot be added without
// every mode stating an opinion about it.
//
// The other half is not expressible. Nothing in the type system knows what an
// "operation" is; an author who adds a new `Future<void> wipeVpnConfig()` and
// simply does not call `OperationGuard.enforce` breaks no signature and gets no
// error. The usual escape — make the destructive call require a token only the
// guard can mint — does not close it either: the new method just would not ask
// for the token. So the property is bought here instead, with two censuses, and
// the shortfall is stated in the PR rather than papered over.
//
//   1. **The seam roster.** Five methods, each pinned to the class it declares,
//      asserted by *adjacency* — the guard must be the first statement of the
//      method. Presence anywhere in the file is not enough: a guard below the
//      `await` it is meant to prevent passes a substring check and leaves a
//      resetting router. This is the lesson `session_teardown_call_sites_test.dart`
//      records from phase 5, where `contains(gate)` was measured to be vacuous.
//
//   2. **The command inventory.** Every call in `lib/` to *any* of the five
//      codegen classes that can issue a TR-181 Operate, pinned per file **with
//      repeats**. This is the census that can see a *new* operation, because a
//      new one has to reach the router through one of these calls. It found
//      something the ticket's own five-row table had missed on its first run —
//      see `_unguardedByDesign`.
//
//      It covered two of the five until review of PR #1513 asked why acceptance
//      6's compile-time clause was unmet. The clause is unmeetable, but the
//      answer exposed something that was not: the census stood in for it over
//      40% of the operate surface, so a destructive command was caught only if
//      it happened to live in the right class. The three former exclusions are
//      now waivers pinned per call site — see `_notDestructive`.
//
// FALSIFIED IN TWELVE DIRECTIONS. All eleven tests passed on their first run, which
// is the state a source-scanning census is least trustworthy in — a regex that
// matches nothing looks exactly like a codebase that is correct. So each
// assertion was made to fail on purpose, and each failed where it should:
//
//   move `factoryReset`'s guard below its `try {`  → factoryReset's seam test
//   give `runUpload` the wrong class               → runUpload's seam test
//   delete `reboot`'s guard outright               → the count test
//   short-circuit a class inside OperationGuard    → "holds no part of the policy"
//   add an unrostered destructive call site        → inventory + reachability
//   ...and then roster it, still with no caller    → reachability alone
//
// and four more after review found the first six were bought with censuses that
// were each weaker than they read:
//
//   make the import/export strip greedy           → the corpus test, FIRST of 9
//   drop one duplicate `download` from the roster  → inventory alone
//   give the waived `pnp_service` a 2nd command    → inventory + reachability
//   delete the relogin after a password change     → the password test alone
//
// The last pair is why the reachability test exists at all: the inventory map
// notices a *new* call site, but it stops noticing the moment someone appeases it
// by adding a line, and a rostered command with nothing guarding it is the
// original bug wearing the census's own paperwork.
//
// The greedy-strip mutant is worth a second look, because it is the one that
// shows what the corpus test is for. Emptying the corpus fails nine of eleven
// tests — but the two survivors are "the guard holds no part of the policy" and
// reachability, i.e. the two assertions phrased negatively, which an empty file
// satisfies perfectly. A negative assertion over a scanned corpus is only as good
// as the proof that the corpus is real, and that is a separate test on purpose.
//
// And two more from PR #1513's review, both aimed at this census rather than at
// the code it watches:
//
//   rename `enforce` to `requireAllowed` everywhere → 5 seam tests + the count
//   a speed test calling `downloadDiagnostic`       → inventory + reachability
//
// The rename mutant is here because the review reply that first went out claimed
// this census could not survive one. It can: the count test asserts *exactly*
// five `.enforce(DisruptionClass.` sites, so a rename reads as zero and takes the
// five adjacency tests down with it. Six red tests, and the claim was wrong.
//
// The speed-test mutant is the one that changed the code. Added to `pingTest()`,
// which already holds a waived `NetworkDiagnostics.ping`, it fires the inventory
// (the file's pinned list is short one command) and reachability (the new command
// is unwaived, so the file it lives in loses the waiver its neighbours earned —
// which is what keying waivers on `(file, command)` buys). Against the two-class
// census it was **green in all eleven**, and that measurement is why
// `_operationClasses` now names five.
//
// WHY NOT A WIDGET TEST. The affordances are hidden by phase 7 (#1497) through
// `SurfaceStrategy`, so a widget test would assert about the layer that is about
// to change, and would go green for the wrong reason the moment a button moves.
// The enforcement floor is at the notifier, and it has behavioural tests there
// (`usp_admin_notifier_test.dart`, `firmware_update_notifier_test.dart`); what
// those cannot see is the seam that nobody wrote.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The guarded seams: which method declares which [DisruptionClass].
///
/// Pinned rather than discovered, because adding a destructive operation has to
/// be a decision. This list is the mechanism by which a new one gets asked what
/// it costs — a discovered set would answer the question by not asking it.
///
/// Three of the five are allowed in every mode, and they are the more important
/// half. With only the two refusals wired, `reboot` and `factoryReset` would
/// differ by the *presence* of a check and a reader could not tell whether reboot
/// is permitted or whether somebody forgot — which is the exact confusion that
/// put the two operations in the same mental bucket to begin with.
const _seams = <({String file, String method, String disruption})>[
  (
    file: 'lib/page/admin/providers/usp_admin_notifier.dart',
    method: 'reboot',
    disruption: 'transientRestart',
  ),
  (
    file: 'lib/page/admin/providers/usp_admin_notifier.dart',
    method: 'factoryReset',
    disruption: 'credentialLoss',
  ),
  (
    file: 'lib/page/firmware_update/providers/firmware_update_notifier.dart',
    method: 'runUpload',
    disruption: 'transportLoss',
  ),
  (
    file: 'lib/page/firmware_update/providers/firmware_update_notifier.dart',
    method: 'triggerInstall',
    disruption: 'transientRestart',
  ),
  (
    file: 'lib/page/firmware_update/providers/firmware_update_notifier.dart',
    method: 'triggerOtaInstall',
    disruption: 'transientRestart',
  ),
];

/// The guard's own file, which must contain no per-class branching.
const _guard = 'lib/core/mode/operation_guard.dart';

/// Every codegen class in `lib/generated/` that can issue a TR-181 **Operate**.
///
/// All five, not the two that hold today's destructive commands. Review of the
/// epic asked why acceptance 6's compile-time clause was unmet; it cannot be met
/// (see the header), but the census standing in for it was answering a narrower
/// question than the acceptance asked — it saw a new destructive command only if
/// that command happened to live in `DeviceOperations` or `FirmwareOperations`.
/// A speed test calling `NetworkDiagnostics.downloadDiagnostic` saturates the
/// very WAN uplink an RA session rides and would have been invisible here.
///
/// Widening the list moves the three former exclusions from **prose to
/// waivers**: their live call sites are pinned in [_commandCallSites] and each is
/// named in [_notDestructive] with the reason it needs no seam. The difference is
/// what happens on the next edit — the prose version described a codebase and a
/// reader had to notice it had changed, this version fails.
///
/// It is deliberately the *operate* surface and not "everything destructive". A
/// TR-181 **Set** can be as destructive as an Operate —
/// [_reauthAfterPasswordChange] is exactly that case — and no census here can see
/// it, because a Set is how every ordinary settings write goes out too. That
/// residual is stated on #1496 rather than papered over with a pattern that would
/// match the whole app.
const _operationClasses = <String>[
  'DeviceOperations',
  'FirmwareOperations',
  'NetworkDiagnostics',
  'SetupOperations',
  'WanOperations',
];

/// Every call site of [_operationClasses] in `lib/`, pinned per file.
///
/// Sorted, and **repeats kept**. The first draft de-duplicated per file with a
/// `.toSet()`, which is a hole big enough to drive the original bug through: a
/// second method in an already-listed file calling an already-listed command
/// changed nothing in the census, so `usp_firmware_update_service.dart` could
/// grow a third unguarded `FirmwareOperations.download` and stay green. Counting
/// makes that a red diff. The cost is that splitting or merging a call needs an
/// edit here, which is the intended price — the two `download` calls below are
/// `triggerLocalDownload` and `triggerOtaDownload`, and they are two entries
/// because they are two seams with two different reasons to exist.
const _commandCallSites = <String, List<String>>{
  'lib/page/admin/services/usp_admin_service.dart': [
    'DeviceOperations.factoryReset',
    'DeviceOperations.reboot',
  ],
  'lib/page/firmware_update/services/firmware_http_upload_strategy.dart': [
    'FirmwareOperations.chunkedPush',
  ],
  'lib/page/firmware_update/services/usp_firmware_update_service.dart': [
    // triggerLocalDownload (file:// URL) and triggerOtaDownload (cloud URL).
    'FirmwareOperations.download',
    'FirmwareOperations.download',
  ],
  'lib/page/instant_setup/services/pnp_service.dart': [
    'DeviceOperations.reboot',
    'NetworkDiagnostics.ping',
    'WanOperations.renewDhcpLease',
  ],
  'lib/page/instant_setup/services/pnp_status_service.dart': [
    'SetupOperations.setUserAcknowledgedAutoConfig',
  ],
  'lib/page/internet_settings/services/usp_internet_settings_service.dart': [
    'WanOperations.renewDhcpLease',
    'WanOperations.renewDhcpv6Lease',
  ],
};

/// The one call site in [_commandCallSites] with no seam above it, and why.
///
/// `PnpService.reboot()` wraps `DeviceOperations.reboot` and **has no caller** —
/// measured: the only occurrence of `.reboot()` under `lib/page/instant_setup/`
/// is the declaration itself. A guard on a method nothing calls is a guard that
/// can never be wrong and never be right, so it was left alone rather than
/// decorated for the sake of a green census.
///
/// It is named here instead of quietly omitted because the day it acquires a
/// caller is the day it needs a seam, and its class is not obvious: PnP runs
/// against a factory-fresh router over the local link, so `transientRestart` is
/// right for the flow that exists today and wrong the moment anything reaches it
/// from Remote Assistance.
///
/// Keyed on `(file, command)` and not on the file. A per-file exemption is an
/// exemption for everything that file ever comes to do: `pnp_service.dart` also
/// holds the PnP `WanOperations` and `NetworkDiagnostics` calls and is where a
/// factory reset would most plausibly be added next, and a file-shaped waiver
/// would have covered it silently. This shape makes an added command in an
/// exempt file fall out of the exemption and into the reachability test.
const _unguardedByDesign = <({String file, String command})>{
  (
    file: 'lib/page/instant_setup/services/pnp_service.dart',
    command: 'DeviceOperations.reboot',
  ),
};

/// Operate call sites that are live and need no seam, because the command itself
/// costs the session nothing. Measured 2026-09-09.
///
/// A separate set from [_unguardedByDesign] rather than five more entries in it,
/// because the two waivers expire on opposite events. Those are waived for having
/// **no caller** and need a seam the day they acquire one; these are waived for
/// **what they do** and would need one only if that changed. Collapsing them
/// would leave a reader unable to tell which question a waiver had answered.
///
/// * `NetworkDiagnostics.ping` — an ICMP echo to `8.8.8.8`. The four members of
///   that class that *would* matter — `downloadDiagnostic`, `uploadDiagnostic`,
///   `udpEchoDiagnostic`, `serverSelectionDiagnostic` — are declared by codegen
///   and called from nowhere, which is why the class is censused and its one live
///   member waived rather than the class excluded.
/// * `WanOperations.renewDhcpLease` / `.renewDhcpv6Lease` — the likeliest waiver
///   here to go wrong, because a renew *does* drop the WAN address and the WAN is
///   the RA path. Waived because it costs at most `transientRestart`: the router
///   re-acquires the address itself, and Guardian's tunnel is dialled outward by
///   the agent, so nothing on the browser's side needs to learn the new one. Both
///   proximity strategies answer `transientRestart` alike, so a seam would refuse
///   nothing in any mode that exists. A member that ever *holds* the WAN down — a
///   release with no renew — is `transportLoss` and belongs in `_seams`.
/// * `SetupOperations.setUserAcknowledgedAutoConfig` — records an
///   acknowledgement. (`setConfigured` is uncalled and deliberately out of PnP's
///   TR-181 scope.)
const _notDestructive = <({String file, String command})>{
  (
    file: 'lib/page/instant_setup/services/pnp_service.dart',
    command: 'NetworkDiagnostics.ping',
  ),
  (
    file: 'lib/page/instant_setup/services/pnp_service.dart',
    command: 'WanOperations.renewDhcpLease',
  ),
  (
    file: 'lib/page/instant_setup/services/pnp_status_service.dart',
    command: 'SetupOperations.setUserAcknowledgedAutoConfig',
  ),
  (
    file:
        'lib/page/internet_settings/services/usp_internet_settings_service.dart',
    command: 'WanOperations.renewDhcpLease',
  ),
  (
    file:
        'lib/page/internet_settings/services/usp_internet_settings_service.dart',
    command: 'WanOperations.renewDhcpv6Lease',
  ),
};

/// Whether [site] has a stated reason to carry no seam.
///
/// The union is taken here, at the one place that asks, so that neither set can
/// quietly become the other's dumping ground.
bool _waived(({String file, String command}) site) =>
    _unguardedByDesign.contains(site) || _notDestructive.contains(site);

/// The operation that looks like `credentialLoss` and is not, plus the line that
/// makes it not.
///
/// `UspAdminNotifier.setAdminPassword` changes the admin password the RA session
/// is authenticating with, which is the same *thing* a factory reset destroys —
/// and it is invisible to both censuses above, because it goes out as a TR-181
/// **Set** through `_svc.updatePassword` rather than as an Operate on one of
/// [_operationClasses]. Left unguarded on a measurement, not an oversight: the
/// notifier immediately calls [reauthCall] with the password the operator has
/// just typed, and falls back to `logout()` if that fails. Nothing becomes
/// unknown. A factory reset is refused precisely because its replacement
/// credential is printed on the router's label, where a remote agent cannot read
/// it; here the replacement is on the operator's screen.
///
/// Asserted rather than only explained, because the exclusion is exactly as good
/// as that one call: delete the re-authentication and a password change *does*
/// end an RA session with no way back, at which point it needs a seam and a
/// `credentialLoss`.
const _reauthAfterPasswordChange = (
  file: 'lib/page/admin/providers/usp_admin_notifier.dart',
  method: 'setAdminPassword',
  reauthCall: 'reloginWithNewPassword',
);

void main() {
  /// `lib/` sources with `//` comments and import/export directives stripped,
  /// and all whitespace collapsed.
  ///
  /// Comments go for the reason every census in `test/core/mode/` strips them:
  /// the doc comment above each seam explains its `DisruptionClass` in prose, so
  /// a scan that read comments could be satisfied by the explanation of a guard
  /// that had been deleted. `(?<!:)` keeps `https://` inside a string literal
  /// from starting a comment — the same expression as
  /// `session_teardown_call_sites_test.dart`, deliberately, because two censuses
  /// over one corpus disagreeing about what a comment is would be a way for one
  /// of them to be quietly weaker.
  ///
  /// Directives go for [_reachableFromSeam]'s sake: it decides "file A uses file
  /// B's class" by looking for B's class names in A, and `import '...' show Foo;`
  /// is a mention of `Foo` by a file that may never call it. Removing them costs
  /// the other assertions nothing — an import names a *path* in snake_case, so it
  /// cannot match a `PascalCase.method` call or a seam signature — and it is done
  /// after the collapse so one pattern covers the multi-line `show` form too.
  ///
  /// Whitespace is collapsed so the adjacency patterns below survive
  /// `dart format`, which wraps the same call two different ways depending on how
  /// long the operation label is. Matching layout instead of structure would make
  /// this file fail on a reformat and pass on a deleted guard.
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
          .join('\n')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r"\b(?:import|export)\s+'[^']*'[^;]*;"), ''),
  };

  test('the stripped corpus is still recognisable code', () {
    // Guards the guard. An over-eager strip would empty the corpus, and an empty
    // corpus makes the inventory census pass (nothing matches, so nothing is a
    // call site) while the seam assertions fail with a message about the seams
    // rather than about the stripper. Fail here, where the cause is named.
    expect(sources[_guard], contains('class OperationGuard'));
    for (final seam in _seams) {
      expect(sources[seam.file], contains('${seam.method}('),
          reason: '${seam.file} stripped down to something without '
              '${seam.method} in it');
    }
    // And the directive strip took only directives. `usp_admin_service.dart`
    // imports the codegen class it calls, so if the pattern had eaten past the
    // `;` the inventory would find nothing here and call that a clean census.
    expect(
      sources['lib/page/admin/services/usp_admin_service.dart'],
      allOf(
        isNot(contains('import ')),
        contains('DeviceOperations.factoryReset'),
      ),
      reason: 'the import/export strip either missed a directive or ran past '
          'one into the code after it',
    );
  });

  group('every destructive seam declares its class, first thing (acceptance 6)',
      () {
    for (final seam in _seams) {
      test('${seam.method} is ${seam.disruption}', () {
        // Signature → `{` → the guard call, with nothing in between. The zero
        // tolerance is the whole point: `_setState`, an `await`, or a read of
        // `_pickedBytes` before the guard means the operation has begun to
        // happen before anyone asked whether it may.
        final pattern = RegExp(
          '\\b${seam.method}'
          r'\(\s*\{?[^)]*\}?\s*\)\s*async\s*\{\s*'
          r'ref\s*\.\s*read\(\s*operationGuardProvider\s*\)\s*'
          r'\.\s*enforce\(\s*DisruptionClass\.'
          '${seam.disruption}\\b',
        );

        expect(
          sources[seam.file],
          matches(pattern),
          reason: '${seam.file}: ${seam.method} must open with '
              'ref.read(operationGuardProvider).enforce('
              'DisruptionClass.${seam.disruption}, operation: ...). Either it is '
              'missing, it names a different class, or something runs before it. '
              'The last case is the dangerous one and is why this is an '
              'adjacency match and not a contains(): a guard that throws after '
              'the USP command has gone out leaves a router that is already '
              'resetting, an error dialog, and — remotely — nobody in the '
              'building who can read the label the password just reverted to.',
        );
      });
    }

    test('and there are exactly ${_seams.length} of them', () {
      final enforceCall = RegExp(r'\.enforce\(\s*DisruptionClass\.');
      final perFile = <String, int>{};
      var total = 0;
      sources.forEach((path, src) {
        final n = enforceCall.allMatches(src).length;
        if (n == 0) return;
        perFile[path] = n;
        total += n;
      });

      expect(
        total,
        _seams.length,
        reason: 'found $total enforce() call sites in '
            '${Map.fromEntries(perFile.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))}, '
            'expected ${_seams.length}. More means a destructive operation was '
            'guarded without being added to _seams, so nothing pins the class it '
            'chose; fewer means one of the five lost its guard. Either way the '
            'roster and the code disagree, and the roster is the thing reviewers '
            'read.',
      );
    });
  });

  test('a password change re-authenticates, which is why it needs no seam', () {
    const r = _reauthAfterPasswordChange;
    // Same method, not merely the same file: the point is that the operator's
    // new password is used before control returns to the caller. 380 collapsed
    // characters apart today; the bound is loose enough to survive an added log
    // line and tight enough that the call cannot drift into a neighbour.
    expect(
      sources[r.file],
      matches(RegExp('\\b${r.method}\\(.{0,900}?\\b${r.reauthCall}\\b',
          dotAll: true)),
      reason: '${r.file}: ${r.method} no longer re-authenticates via '
          '${r.reauthCall} within its own body. That call is the entire reason '
          'this operation is absent from _seams — with it, the replacement '
          'credential is the one the operator just typed; without it, changing '
          'the password is credentialLoss with all of a factory reset\'s '
          'consequences and none of its warning, and it needs a seam declaring '
          'DisruptionClass.credentialLoss.',
    );
  });

  test('the guard holds no part of the policy', () {
    // `OperationGuard.allows` delegates to `ProximityStrategy.canRecoverFrom`,
    // and the moment it mentions a specific class it has started to hold an
    // opinion — at which point "which operations are refused" has two homes and
    // the copy nobody edits is the one a new class gets wrong. Note this is a
    // stronger claim than operation_guard_test.dart's delegation assertion, which
    // a hard-coded table matching today's policy would satisfy.
    expect(
      sources[_guard],
      isNot(contains('DisruptionClass.')),
      reason: '$_guard names a specific DisruptionClass in code. The guard is '
          'allowed to *take* one and pass it on; branching on one makes it the '
          'second place cause 4 lives. If a class genuinely needs different '
          'handling at the seam — a different error, a confirmation — that '
          'belongs to the caller, which knows what operation it is performing.',
    );
  });

  group('the destructive command inventory', () {
    /// Path → sorted `Class.method` calls found in it, repeats included.
    late final Map<String, List<String>> found = () {
      final pattern = RegExp('(${_operationClasses.join('|')})'
          r'\.([a-zA-Z_]\w*)');
      final result = <String, List<String>>{};
      sources.forEach((path, src) {
        // The declarations themselves are not call sites.
        if (path.startsWith('lib/generated/')) return;
        final calls = pattern.allMatches(src).map((m) => m[0]!).toList()
          ..sort();
        if (calls.isNotEmpty) result[path] = calls;
      });
      return result;
    }();

    test('nothing new reaches a destructive TR-181 command', () {
      expect(
        found,
        _commandCallSites,
        reason: 'the set of call sites into '
            '${_operationClasses.join(' / ')} changed. This is the census that '
            'can see a destructive operation nobody classified: a new one has to '
            'get to the router through one of these calls, and it will not have '
            'a DisruptionClass unless somebody chose one. Add the call site here '
            'and give the operation a seam in _seams — or, if it genuinely has '
            'no caller and therefore no seam, add it to _unguardedByDesign with '
            'the reason, which is what PnpService.reboot did.',
      );
    });

    test('every command call site is reachable from a guarded seam', () {
      // Files holding a guard, plus the files that only *wrap* a command and are
      // called by one. Deliberately a reachability claim rather than a
      // per-file-has-a-guard claim: the guards live at the notifier and the
      // commands live two layers down in the services, so requiring a guard in
      // the same file would push five `enforce` calls into the service layer and
      // duplicate them — the services are shared, and a service is not where a
      // mode policy belongs.
      final guardedSeamFiles = _seams.map((s) => s.file).toSet();
      // A file is waived only if *every* command in it is waived by name, so a
      // new command in an exempt file lands back in this test rather than
      // inheriting the waiver its neighbour earned.
      final unaccounted = found.entries
          .where((e) => !e.value
              .every((command) => _waived((file: e.key, command: command))))
          .map((e) => e.key)
          .where((path) => !_reachableFromSeam(path, sources, guardedSeamFiles))
          .toList()
        ..sort();

      expect(
        unaccounted,
        isEmpty,
        reason:
            'these files issue a destructive command and nothing above them '
            'asks the mode first: $unaccounted. Give the operation a seam in a '
            'notifier that calls OperationGuard.enforce, or record it in '
            '_unguardedByDesign with the reason it needs none.',
      );
    });
  });
}

/// Whether any class declared in [path] is named by a seam file, or by a file
/// that is itself named by one.
///
/// Two hops, by class name, and [hops] is a hard bound rather than a tuning
/// knob: without it, two files that mention each other's classes — which is
/// ordinary between a service and its strategy — recurse until the stack ends,
/// and the failure would read as a crash in a mode test rather than as what it
/// is. Two is also all the depth the real graph needs: the notifier names
/// `FirmwareLocalUploadService`, which names `FirmwareHttpUploadStrategy`, which
/// is what actually pushes the chunks.
///
/// Name-matching is not call-graph analysis; a full walk would need a resolved
/// AST for a claim this test does not make. The primary net is the exact map
/// above, which fails on *any* new call site. This one adds the case that map
/// cannot see: a new call site that was dutifully added to `_commandCallSites`
/// and then never given a guarded caller.
///
/// The mention must be a whole word. A bare `contains` let `FirmwareUpdateState`
/// satisfy a search for `FirmwareUpdate`, which is not a hypothetical in a
/// codebase whose classes are `Foo`, `FooState`, `FooNotifier` and `FooService` —
/// every one of them would have vouched for every other. Import directives are
/// already gone from the corpus for the same reason: they are mentions that are
/// not uses.
bool _reachableFromSeam(
  String path,
  Map<String, String> sources,
  Set<String> seamFiles, {
  int hops = 1,
}) {
  // Every class in the file, not just the first: a file whose first declaration
  // is an exception type would otherwise be judged by a name nobody imports.
  final classNames = RegExp(r'class\s+(\w+)')
      .allMatches(sources[path] ?? '')
      .map((m) => m[1]!)
      .toSet();
  if (classNames.isEmpty) return false;

  final asWords = classNames.map((n) => RegExp('\\b$n\\b')).toList();
  bool namedIn(String src) => asWords.any((r) => r.hasMatch(src));

  if (seamFiles.any((seamFile) => namedIn(sources[seamFile]!))) return true;
  if (hops <= 0) return false;
  return sources.entries.any((e) =>
      e.key != path &&
      namedIn(e.value) &&
      _reachableFromSeam(e.key, sources, seamFiles, hops: hops - 1));
}
