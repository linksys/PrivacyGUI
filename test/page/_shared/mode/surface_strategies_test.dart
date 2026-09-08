// #1497 (phase 7 of epic #1474): cause 5's fourteen members, both modes side by
// side.
//
// One file for both, same reason as `test/core/mode/impl/session_strategies_test
// .dart`: every claim below is a *difference* between the two answers to one
// question, and split across two files each half reads as an arbitrary table.
// Article XVII's "a member needs a measured difference" is only checkable side by
// side.
//
// WHAT THIS FILE IS AND IS NOT. It pins the answers, not the wiring. Each member's
// consumer has its own test — the SSE banner in
// `sse_connection_banner_test.dart`, the route table in
// `test/route/remote_assistance_entry_gate_test.dart`, the seven page surfaces in
// `surface_consumers_test.dart` — because a strategy that returns the right thing
// to nobody is exactly the failure mode falsification criterion 4 names, and a
// unit test over the strategy alone cannot see it. The last group here is the
// cheap half of that: every member has at least one caller under `lib/`.
//
// WHY NOT `expect(local.assistanceBanner(), isNotNull)` AND STOP. Because "hidden
// in RA" is the wrong summary of this contract and a nullability-only assertion
// would encode it. Three of the fourteen return a widget in *both* modes with
// different content (`sessionGuard`, `sessionExitAction`,
// `connectionBannerLevel`), and those are the members that make the contract a
// composition and not a capability table. They get the most detailed assertions
// below, on purpose.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/session/session_exit_actions.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/account_actions_section.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/framework/mode/sse_banner_level.dart';
import 'package:privacy_gui/framework/mode/surface_strategy.dart';
import 'package:privacy_gui/page/_shared/components/remote_session_chip.dart';
import 'package:privacy_gui/page/_shared/mode/local_surface.dart';
import 'package:privacy_gui/page/_shared/mode/remote_surface.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_providers.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/first_run_preset_flow.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_banner.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_session_guard.dart';
import 'package:privacy_gui/page/support/views/components/remote_assistance_card.dart';

/// The fourteen members, spelled as they appear in a call site.
///
/// A roster rather than a count: the count is in the guide doc and drifts, while
/// this list is what the "every member has a caller" group iterates. Adding a
/// member to the contract without adding it here leaves it unscanned, which is why
/// the group also checks the contract file declares exactly these.
const _members = <String>[
  'ambientCoordinators',
  'sessionGuard',
  'assistanceBanner',
  'sessionIndicator',
  'connectionBannerLevel',
  'assistanceEntryCard',
  'accountActions',
  'fixedDashboardLayout',
  'layoutEditor',
  'firstRunPresetFlow',
  'firmwareManualEntry',
  'sessionExitAction',
  'recoveryMessages',
  'routes',
];

/// Distinguishable stand-ins for the builders and children members are handed —
/// the firmware picker, the `sessionGuard` child. `const` so identity is stable
/// across calls.
///
/// Deliberately *not* a `SizedBox`, even though that is what it builds: the
/// remote firmware arm returns a real `SizedBox.shrink()`, and a sentinel of the
/// same type would make "remote returned nothing" and "remote returned what it was
/// handed" indistinguishable.
class _Sentinel extends StatelessWidget {
  const _Sentinel(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  String toString({DiagnosticLevel? minLevel}) => 'Sentinel($name)';
}

void main() {
  const local = LocalSurface();
  const remote = RemoteSurface();

  group('shell chrome', () {
    test('ambient coordinators: the mascot timer, and nothing in a session',
        () {
      expect(local.ambientCoordinators(), [mascotCoordinatorProvider]);
      expect(remote.ambientCoordinators(), isEmpty,
          reason: 'an empty list is how a mode says it has no ambient state — '
              'the shell then watches nothing and holds no `if`. A '
              '`hasMascot` bool here would have been the capability table '
              'Article XVII rules out.');
    });

    test('session guard: local wraps, remote is the identity', () {
      const child = _Sentinel('content');

      final wrapped = local.sessionGuard(child: child);
      expect(wrapped, isA<RemoteAssistanceSessionGuard>());
      expect((wrapped as RemoteAssistanceSessionGuard).child, same(child),
          reason: 'the guard must wrap the real content, not replace it');

      expect(remote.sessionGuard(child: child), same(child),
          reason:
              'returning the child unwrapped is what the guard\'s own first '
              'line used to do after being wrapped anyway. Two reads had to '
              'agree — the shell\'s `if (!isRemoteMode)` and the guard\'s early '
              'return — and either one alone was silently a no-op.');
    });

    test('assistance banner: about a session being granted', () {
      expect(local.assistanceBanner(), isA<RemoteAssistanceBanner>());
      expect(remote.assistanceBanner(), isNull,
          reason: 'consent is what got this build its token; there is no '
              'pending session for it to announce');
    });

    test('session indicator: about the session being run', () {
      expect(local.sessionIndicator(), isNull);
      expect(remote.sessionIndicator(), isA<RemoteSessionChip>(),
          reason: 'the mirror image of the banner, and the reason both members '
              'exist: neither mode wants both, and no single surface covers '
              'them');
    });
  });

  // The one member whose modes differ in *degree*, so the whole table is asserted
  // rather than a representative row. `SseConnectionState` is exhaustive in both
  // implementations, so a new state is a compile error — but a new state's
  // *classification* is a decision, and this is where the two get compared.
  group('connection banner level', () {
    const expected = <SseConnectionState, (SseBannerLevel, SseBannerLevel)>{
      // state: (local, remote)
      SseConnectionState.connected: (
        SseBannerLevel.hidden,
        SseBannerLevel.hidden
      ),
      SseConnectionState.connecting: (
        SseBannerLevel.warning,
        SseBannerLevel.warning
      ),
      SseConnectionState.reconnecting: (
        SseBannerLevel.warning,
        SseBannerLevel.warning
      ),
      // The one row that differs, and the reason this member is an enum: Guardian
      // force-closes the proxied stream at roughly ten minutes, so a closed stream
      // is the most routine event in a support session and a fault on a LAN.
      SseConnectionState.disconnected: (
        SseBannerLevel.danger,
        SseBannerLevel.warning
      ),
      SseConnectionState.suspended: (
        SseBannerLevel.danger,
        SseBannerLevel.danger
      ),
    };

    test('every state is in the table', () {
      expect(expected.keys, containsAll(SseConnectionState.values),
          reason: 'a new SseConnectionState is a compile error in both '
              'implementations, so this table is not what catches it — but an '
              'unclassified state would silently skip the comparison that is the '
              'point of this group');
    });

    for (final entry in expected.entries) {
      test(
          '${entry.key.name}: local=${entry.value.$1.name}, '
          'remote=${entry.value.$2.name}', () {
        expect(local.connectionBannerLevel(entry.key), entry.value.$1);
        expect(remote.connectionBannerLevel(entry.key), entry.value.$2);
      });
    }

    test('exactly one state is classified differently', () {
      final differing = SseConnectionState.values
          .where((s) =>
              local.connectionBannerLevel(s) != remote.connectionBannerLevel(s))
          .toList();

      expect(differing, [SseConnectionState.disconnected],
          reason: 'this member earns its place in the contract by exactly one '
              'measured difference (Article XVII). If the two implementations '
              'agree on everything, the member should be a plain function; if '
              'they disagree on more, say which new fact about Guardian made '
              'that true.');
    });
  });

  group('page surfaces', () {
    test('assistance entry card: a session does not offer another one', () {
      expect(local.assistanceEntryCard(), isA<RemoteAssistanceCard>());
      expect(remote.assistanceEntryCard(), isNull);
    });

    test('account actions: a one-shot token has no login page to return to',
        () {
      expect(local.accountActions(), isA<AccountActionsSection>());
      expect(remote.accountActions(), isNull,
          reason: 'narrower than "hide it in RA": "log out" has no counterpart '
              '"log in" for a Guardian token, and sessionExitAction() is where '
              'that mode\'s exit lives instead');
    });

    // Stated here as well as in `usp_layout_fixed_surface_test.dart`, and the
    // duplication is the point rather than an oversight. That file asserts what the
    // two *providers* do with the answer; this one asserts that the two modes give
    // different answers at all, which is Article XVII's bar for a member existing.
    // Review found the member had only the first: making `RemoteSurface` return
    // `null` — collapsing the two implementations into one, which §17.2 says demotes
    // a member to a plain function — left this file entirely green, so skipping one
    // test file removed the whole guard.
    test('fixed dashboard layout: the eight cards, or the viewer\'s own', () {
      expect(local.fixedDashboardLayout(), isNull,
          reason:
              'null is how the grid and the preferences provider learn that '
              'the stored layout is authoritative in both directions');

      final remoteLayout = remote.fixedDashboardLayout();
      expect(remoteLayout, isNotNull);
      expect(
        remoteLayout!.map((item) => item.id).toList()..sort(),
        UspDashboardPreset.remote.cardIds.toList()..sort(),
        reason:
            'the fixed layout is the `remote` preset\'s cards. Asserted by id '
            'rather than by length so that a preset edited to hold eight '
            '*different* cards cannot pass.',
      );

      expect(remote.fixedDashboardLayout(), isNot(same(remoteLayout)),
          reason: 'a fresh list per call, deliberately: the grid mutates '
              'LayoutItem geometry in place, so a cached instance would carry '
              'one session\'s drag into the next container. Review proposed '
              'caching it for the allocation — this is why not.');
    });

    test('layout editor: the callback itself, or nothing to run', () {
      void enterEditMode() {}

      expect(local.layoutEditor(enterEditMode), same(enterEditMode),
          reason: 'the callback is returned unchanged — the strategy decides '
              'whether there is an editor, not what editing does');
      expect(remote.layoutEditor(enterEditMode), isNull,
          reason: '`null` is how DashboardHeaderBar learns not to render the '
              'dashboard-edit action at all. It used to take an `isRemoteMode` '
              'bool AND a required `onEdit` — the same condition spelled twice, '
              'with the remote build passing a callback it never used.');
    });

    test('first-run preset flow: the whole flow, or none of it', () {
      expect(local.firstRunPresetFlow(), same(runFirstRunPresetFlow),
          reason:
              'the preference check, the picker and applying the result are '
              'one decision; splitting them left the call site holding a '
              '`showPresetDialog` flag to consult first');
      expect(remote.firstRunPresetFlow(), isNull,
          reason: 'the preset is fixed (UspDashboardPreset.remote), and the '
              'agent is not the user whose preference a picker would store');
    });

    // WHAT A SENTINEL CANNOT TELL YOU. This group used to test a
    // `firmwareUpdateCards` list with three sentinels, and asserted — with a
    // paragraph of justification — that remote returning `[status, ota]` was
    // "hiding the manual-update CARD, not the page". Every word of that was green
    // and the shipped behaviour was a regression: the sentinel named
    // `manualUpdate` stood in for `_buildActionCard`, which is not the
    // manual-update card but the page's entire eleven-phase install machine, and a
    // cloud OTA install — the operation RA keeps — drives those same phases. A
    // stand-in is opaque by construction, so no assertion at this level could have
    // said so. `surface_consumers_test.dart` pumps the real page at
    // `installing` and `failed` for that reason; what is left here is what a
    // sentinel *can* answer honestly.
    group('firmware manual entry', () {
      const picker = _Sentinel('picker');

      test('local offers the picker it was handed', () {
        expect(local.firmwareManualEntry(picker: () => picker), same(picker));
      });

      test('remote offers nothing in its place', () {
        final entry = remote.firmwareManualEntry(picker: () => picker);
        expect(entry, isNot(same(picker)));
        expect(entry, isA<SizedBox>(),
            reason: 'an empty widget rather than `null`, because the call site '
                'is a `switch` arm that must return a Widget — see the contract '
                'doc. It must still be *empty*: returning the picker with its '
                'buttons disabled would be the affordance again.');
      });

      test('the card remote omits is never built', () {
        var built = 0;
        remote.firmwareManualEntry(picker: () {
          built++;
          return picker;
        });

        expect(built, 0,
            reason: 'this is why the member takes a builder rather than a '
                'widget: a discarded _buildIdleCard would still have read '
                'firmwareUpdateProvider and registered a dependency for a card '
                'the page is not showing');
      });
    });
  });

  group('recovery dialogs', () {
    test('exit action: both modes, different destinations', () {
      expect(local.sessionExitAction(), isA<ReturnToLoginAction>());
      expect(remote.sessionExitAction(), isA<EndSessionAction>());
    });

    test('neither exit action is null', () {
      // Stated separately from the types above because it is a different claim
      // with a different consequence: `showRecoveryDialog` passes
      // `barrierDismissible: false` and only pops on a transition into
      // `authenticated`, so this member being the whole `actions:` list means a
      // `null` here renders a modal the operator cannot leave.
      for (final surface in <SurfaceStrategy>[local, remote]) {
        expect(surface.sessionExitAction(), isNotNull);
      }
    });

    test('recovery messages: local advice an agent cannot act on', () {
      expect(local.recoveryMessages(), hasLength(1));
      expect(local.recoveryMessages().single, contains('reconnect'),
          reason: 'the string moved rather than being rewritten — it is what '
              'showRecoveryDialog has always defaulted to');

      expect(remote.recoveryMessages(), isEmpty,
          reason:
              'empty rather than differently worded: the agent\'s browser is '
              'nowhere near the Wi-Fi that is restarting, and an accurate remote '
              'line is new user-visible copy in 26 locales. #1497 is not that '
              'change, and doing it here would hide the debt behind a refactor.');
    });
  });

  // Falsification criterion 4 of #1474: a member with no caller is deleted. This
  // is the cheap half — it proves each member is *named* somewhere outside the
  // contract and its two implementations, not that the call site renders it
  // correctly. `surface_consumers_test.dart` is the other half.
  //
  // Worth having anyway, because the failure it catches is the epic's own stated
  // trap: `GlobalConfig.remote` shipped three per-mode flags that were well
  // named, documented, centralised and read by nothing, and an unread answer
  // cannot be seen to be wrong.
  group('every member has a caller (criterion 4)', () {
    /// `lib/` sources with comment lines removed, keyed by path.
    ///
    /// Stripping `//` and `///` is the correctness of this scan, not tidiness: the
    /// contract's own doc comment cross-references almost every member by name
    /// (`[assistanceBanner]`, `[sessionIndicator]`, …), and so do both
    /// implementations. With comments included, a member deleted from every call
    /// site would still be found — in the prose explaining why it exists.
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

    /// The contract and its two implementations: where a member is *declared* or
    /// *overridden*, which is not a caller.
    const declarers = {
      'lib/framework/mode/surface_strategy.dart',
      'lib/page/_shared/mode/local_surface.dart',
      'lib/page/_shared/mode/remote_surface.dart',
    };

    test('the roster matches the contract', () {
      final contract = sources['lib/framework/mode/surface_strategy.dart'];
      expect(contract, isNotNull,
          reason: 'the contract moved — re-point this scan and Article XVII');

      for (final member in _members) {
        expect(contract, contains(member),
            reason: '$member is in _members but not declared in the contract');
      }

      // The other direction: a member added to the contract but not to _members
      // would be silently unscanned. Matched as "a name followed by `(` at the
      // start of a declaration", which is why `Function` has to be subtracted —
      // `firstRunPresetFlow`'s return type is a function type, so
      // `Future<void> Function(BuildContext …)` matches the same shape as a
      // member. Subtracted by name rather than by a cleverer regex: the regex
      // that excluded it would also be the regex that quietly excluded a real
      // member whose signature grew a callback parameter.
      final declared = RegExp(r'^\s*[\w<>,?\s]+\s(\w+)\(', multiLine: true)
          .allMatches(contract!)
          .map((m) => m.group(1)!)
          .toSet()
        ..remove('Function');
      expect(declared.difference(_members.toSet()), isEmpty,
          reason:
              'the contract declares a member _members does not list, so it '
              'is exempt from the caller check below. Add it here.');
      expect(_members.toSet().difference(declared), isEmpty,
          reason: '_members lists a name the contract does not declare as a '
              'member — a rename that left the roster behind, which would make '
              'the caller check below scan for a spelling nothing uses.');
    });

    for (final member in _members) {
      test(member, () {
        final callers = sources.entries
            .where((e) => !declarers.contains(e.key))
            .where((e) => e.value.contains('$member('))
            .map((e) => e.key)
            .toList()
          ..sort();

        expect(
          callers,
          isNotEmpty,
          reason: 'SurfaceStrategy.$member() is called from nowhere under '
              'lib/. Criterion 4 of #1474 says delete it: a per-mode answer '
              'nobody asks for is the exact shape of the three '
              '`GlobalConfig.remote` flags phase 8 removed — well named, '
              'documented, and never read. If the caller is coming in a later '
              'phase, the member belongs in that phase.',
        );
      });
    }
  });
}
