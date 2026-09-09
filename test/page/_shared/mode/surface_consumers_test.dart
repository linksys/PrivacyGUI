// #1497 (phase 7 of epic #1474): the call sites, pumped under both profiles.
//
// `surface_strategies_test.dart` pins what each member *answers*; this file pins
// that the page in front of the user is the answer. The two halves are separable
// and both are needed: a strategy that returns the right widget to a page that
// dropped the call still ships the old screen, and its unit test stays green
// forever.
//
// EVERY CASE SELECTS ITS MODE THE SAME WAY: one
// `appModeProfileProvider.overrideWithValue(...)`. That is falsification
// criterion 2 of #1474 — no test may set `BuildConfig.forceCommandType` — but it
// is also the claim being made. Before this epic, "is this Remote Assistance?"
// was answered independently at 15 sites, so a test that flipped one global was
// really testing 15 unrelated `if`s that merely happened to agree. Overriding the
// profile and finding the whole screen changed is what "one lever" means.
//
// NOT COVERED HERE, AND WHY. `UspDashboardShell` consumes four members
// (`ambientCoordinators`, `sessionGuard`, `assistanceBanner`, `sessionIndicator`)
// and is not pumped below. It is the app's root shell: it needs the router, the
// SSE stack, the dashboard's domain-ready gate, the mascot controller and the
// theme-studio config before it renders a frame, and standing all of that up here
// would produce a test whose failures are almost never about the mode. What holds
// it instead:
//   - the four members' answers, in `surface_strategies_test.dart`;
//   - that each is called from `usp_dashboard_shell.dart` at all, in that file's
//     criterion-4 group;
//   - the shell under the local profile, in the layout-gate page-surface family.
// The gap is the shell pumped under the *remote* profile, and it is a real one —
// recorded here rather than papered over.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/account_actions_section.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/theme_mode_tile.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';
import 'package:privacy_gui/page/support/views/usp_support_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../util/dashboard_page_harness.dart';
import '../../../util/settle.dart';

/// The two profiles, named so a failure message says which screen was wrong.
const _profiles = <String, AppModeProfile>{
  'local': LocalModeProfile(),
  'remote assistance': RemoteModeProfile(),
};

/// A settled auth state, so the account block's own `isLoggedIn` check is a
/// controlled input rather than whatever `commonOverrides()` happens to seed.
///
/// `LoginType.local` for both values of [loggedIn] that matter here: the point of
/// the remote case is that login *kind* is not what hides the block, so seeding
/// `LoginType.remote` there would confound the two questions this group separates.
class _FixedAuth extends AuthNotifier {
  _FixedAuth({required this.loggedIn});
  final bool loggedIn;

  @override
  Future<AuthState> build() => Future.value(loggedIn
      ? const AuthState(loginType: LoginType.local)
      : AuthState.empty());
}

void main() {
  setUpAll(() {
    // Both pages reach the version line, which reads package_info through a
    // platform channel that does not exist in a test binding.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async => methodCall.method == 'getAll'
          ? <String, dynamic>{
              'appName': 'PrivacyGUI',
              'packageName': 'com.linksys.privacygui',
              'version': '0.0.0',
              'buildNumber': '0',
            }
          : null,
    );
  });

  /// Hosts [page] at `/` under [profile].
  ///
  /// A `LinksysRoute` rather than a bare `home:`, because several of these pages
  /// carry an `onExit` dirty guard and read `GoRouterState` for their title.
  Widget host({
    required AppModeProfile profile,
    required Widget page,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...overrides,
        appModeProfileProvider.overrideWithValue(profile),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            LinksysRoute(
              path: '/',
              name: 'surface_consumer_host',
              builder: (context, state) => page,
            ),
          ],
        ),
      ),
    );
  }

  /// A tall surface, so a card that IS rendered cannot be missed for being off
  /// screen — which would make every "absent in remote" assertion below pass for
  /// the wrong reason.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // ===========================================================================
  // firmwareManualEntry — the one page whose *content* this phase changed
  // ===========================================================================
  //
  // Austin's 2026-09-08 addition to #1497: hide the manual firmware-update
  // affordance in RA. The entry point, not the page and not the install machine —
  // router status, the cloud OTA check and every phase an install passes through
  // stay, because an OTA upgrade is allowed in every mode.
  //
  // Asserted on the page rather than only on the strategy because both failures
  // this group guards are rendering ones, in opposite directions. Too much: a page
  // that kept building the picker directly, alongside the strategy call, would
  // satisfy every strategy assertion while still offering the upload. Too little:
  // dropping a widget one level too high takes the OTA install's progress and
  // failure UI with it, which is what the last two tests exist to catch and what
  // the strategy's own sentinels could not see.
  group('firmware update page', () {
    Widget firmwarePage(AppModeProfile profile, [FirmwareUpdateState? state]) =>
        host(
          profile: profile,
          page: const FirmwareUpdateView(),
          overrides: firmwareUpdateOverrides(
            updateState: state ?? idleNoFileState,
            banksData: testBanksData,
            systemInfoData: testSystemInfoData,
          ),
        );

    testWidgets('local offers the manual upload', (tester) async {
      final handle = tester.ensureSemantics();
      useTallSurface(tester);

      await tester.pumpWidget(firmwarePage(const LocalModeProfile()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('firmware-pick-file'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('remote assistance does not', (tester) async {
      final handle = tester.ensureSemantics();
      useTallSurface(tester);

      await tester.pumpWidget(firmwarePage(const RemoteModeProfile()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('firmware-pick-file'), findsNothing,
          reason: 'pushing an image from the agent\'s browser is a local-only '
              'feature. #1496 refuses the operation underneath; this is the same '
              'decision one layer up, where it is offered — so the agent is not '
              'shown a control that would be rejected.');
      handle.dispose();
    });

    testWidgets('remote assistance keeps the cloud OTA check', (tester) async {
      final handle = tester.ensureSemantics();
      useTallSurface(tester);

      await tester.pumpWidget(firmwarePage(const RemoteModeProfile()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('firmware-check'), findsOneWidget,
          reason: 'the whole point of hiding the CARD rather than the PAGE. '
              'Checking for and applying a cloud OTA image is allowed in every '
              'mode, and it is the affordance an agent on a support call actually '
              'needs; removing the route would have taken it away too.');
      handle.dispose();
    });

    testWidgets('and the page still says what it is', (tester) async {
      // A guard against the cheap way to pass the two tests above: an empty card
      // list, or a page that failed to build at all, satisfies both `findsNothing`
      // assertions.
      final handle = tester.ensureSemantics();
      useTallSurface(tester);

      await tester.pumpWidget(firmwarePage(const RemoteModeProfile()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('firmware-update'), findsOneWidget,
          reason:
              'the page anchor is gone, so this page did not render and the '
              '"remote hides the upload" assertions above are vacuous');
      handle.dispose();
    });

    // The four cases above all pump `idleNoFileState`, and that is what let the
    // first version of this phase ship a real regression: at `idle` the manual
    // affordance and the install phase machine are the *same widget*, so "hide
    // the manual card" and "hide the whole machine" are indistinguishable. They
    // are not the same thing at any later phase. `triggerOtaInstall` walks
    // `triggering → installing`, `enterRecoveryWaiting` sets `rebooting`, and
    // `verify` ends at `done` or `failed` — the cloud OTA install the mode is
    // supposed to keep drives every one of those phases through the machine that
    // was being dropped. So an agent could start an OTA update and then watch the
    // page show nothing at all, with the `failed` copy, its message and its retry
    // button among the casualties.
    //
    // The two tests below pump the phases that only the OTA path can reach in RA.
    testWidgets('remote assistance shows a cloud OTA install in progress',
        (tester) async {
      final handle = tester.ensureSemantics();
      useTallSurface(tester);

      await tester
          .pumpWidget(firmwarePage(const RemoteModeProfile(), installingState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsIdentifier('firmware-phase-installing'),
          findsOneWidget,
          reason: 'an OTA install started from this page must be visible while '
              'it runs. Only the manual *entry point* is local-only; the progress '
              'of an install already under way belongs to whichever path started '
              'it, and in RA that path is the one the mode allows.');
      handle.dispose();
    });

    testWidgets('remote assistance shows an OTA failure and its retry',
        (tester) async {
      final handle = tester.ensureSemantics();
      useTallSurface(tester);

      await tester
          .pumpWidget(firmwarePage(const RemoteModeProfile(), failedState));
      await tester.pumpAndSettle();

      expect(
          find.bySemanticsIdentifier('firmware-phase-failed'), findsOneWidget,
          reason:
              'the whole-flow verdict must stay structurally visible in the '
              'mode that can still reach it');
      expect(find.bySemanticsIdentifier('firmware-retry'), findsOneWidget,
          reason: 'and reachable: `firmware-retry` calls `cancel()`, which is '
              'the only transition out of `failed`. Without it the notifier is '
              'stuck in a phase whose UI is not drawn, so the page stays blank '
              'for the rest of the session with no way back to `idle`.');
      handle.dispose();
    });
  });

  // ===========================================================================
  // assistanceEntryCard
  // ===========================================================================
  group('support page', () {
    for (final entry in _profiles.entries) {
      final expectCard = entry.key == 'local';

      testWidgets(
          '${entry.key}: the Remote Assistance card is '
          '${expectCard ? 'offered' : 'absent'}', (tester) async {
        final handle = tester.ensureSemantics();
        useTallSurface(tester);

        await tester.pumpWidget(
            host(profile: entry.value, page: const UspSupportView()));
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsIdentifier('support-remote-assistance'),
          expectCard ? findsOneWidget : findsNothing,
          reason: expectCard
              ? 'the owner\'s support page is where a session is started, so '
                  'this is the entry point #1357 item 1 is about'
              : 'a support session does not offer to start another one — and the '
                  'agent tapping it would open a consent dialog for a router '
                  'they are already inside',
        );
        handle.dispose();
      });
    }
  });

  // ===========================================================================
  // accountActions
  // ===========================================================================
  //
  // The one member whose old call site was a *compound* condition rather than a
  // plain mode gate: `if (!GlobalConfig.remote.isActive && isLoggedIn)`, with the
  // popup reading `authProvider` for a block it might not render. #1497 split it —
  // which mode has an account block is the strategy's call, whether there is a
  // session to sign out of is `AccountActionsSection`'s own — so both halves are
  // asserted here, because a refactor that dropped either would still satisfy
  // `surface_strategies_test.dart`.
  group('general settings popup', () {
    Widget settingsPopup(AppModeProfile profile, {required bool loggedIn}) =>
        host(
          profile: profile,
          // Last override wins, so this replaces `commonOverrides()`'s
          // unauthenticated stub. That it takes effect is not assumed: the
          // logged-in case asserts the sign-out button, which only exists when
          // the notifier below was the one consulted.
          overrides: [
            authProvider.overrideWith(() => _FixedAuth(loggedIn: loggedIn)),
          ],
          page: const Scaffold(body: GeneralSettingsWidget()),
        );

    /// The popup lives behind the person icon, and everything asserted below is
    /// inside it.
    Future<void> openPopup(WidgetTester tester) async {
      await tester.tap(find.byType(Icon).first);
      await tester.pumpAndSettle();
    }

    testWidgets('local, logged in: the account block is there', (tester) async {
      useTallSurface(tester);

      await tester
          .pumpWidget(settingsPopup(const LocalModeProfile(), loggedIn: true));
      await tester.pumpAndSettle();
      await openPopup(tester);

      expect(find.byType(AccountActionsSection), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget,
          reason: 'the block rendered its content, not just its shell — which '
              'is also what proves the auth override above was consulted');
    });

    testWidgets('remote assistance: no account block at all', (tester) async {
      useTallSurface(tester);

      // Logged IN, deliberately: a Remote Assistance session is `LoginType
      // .remote`, so `isLoggedIn` is true and the widget's own check would let
      // the block through. Only the strategy keeps it out, which is the claim.
      await tester
          .pumpWidget(settingsPopup(const RemoteModeProfile(), loggedIn: true));
      await tester.pumpAndSettle();
      await openPopup(tester);

      expect(find.byType(AccountActionsSection), findsNothing,
          reason: '"Log out" has no counterpart "log in" for a one-shot '
              'Guardian token — the way out of a support session is '
              'sessionExitAction(), not this block');
      expect(find.byType(ThemeModeTile), findsOneWidget,
          reason: 'the popup opened, so the absence above is the block and not '
              'the whole menu');
    });

    testWidgets('local, logged out: the widget declines for itself',
        (tester) async {
      // The other half of the split condition. The block is still *constructed*
      // by the strategy — asserted on the rendered sign-out rather than on the
      // type, because `AccountActionsSection` returns SizedBox.shrink() from its
      // own build when there is no session.
      useTallSurface(tester);

      await tester
          .pumpWidget(settingsPopup(const LocalModeProfile(), loggedIn: false));
      await tester.pumpAndSettle();
      await openPopup(tester);

      expect(find.text('Log out'), findsNothing);
      expect(find.byType(ThemeModeTile), findsOneWidget);
    });
  });

  // ===========================================================================
  // layoutEditor
  // ===========================================================================
  //
  // Two halves, and only the first is here. `DashboardHeaderBar` dropping the
  // action when `onEdit` is null is swept over 234 cells by
  // `page_chrome_overflow_test.dart`, which already knew both modes and now gets
  // its remote cell by passing `onEdit: null`. What no test covered was *who
  // passes null* — the view, whose old form handed the header a mode flag AND a
  // callback for that mode to ignore.
  group('dashboard header', () {
    Future<void> pumpDashboard(
      WidgetTester tester,
      AppModeProfile profile,
    ) async {
      await pumpDashboardPage(
        tester,
        // Wide, so `dashboard-edit` keeps its own button instead of collapsing
        // into the overflow menu — where `findsNothing` would be true of both
        // modes and this test would pass for the wrong reason.
        size: const Size(1280, 2000),
        extraOverrides: [appModeProfileProvider.overrideWithValue(profile)],
      );
    }

    testWidgets('local offers the layout editor', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpDashboard(tester, const LocalModeProfile());

      expect(find.bySemanticsIdentifier('dashboard-edit'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('remote assistance does not', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpDashboard(tester, const RemoteModeProfile());

      expect(find.bySemanticsIdentifier('dashboard-edit'), findsNothing,
          reason: 'the layout is the router owner\'s to arrange; an agent '
              'rearranging it would persist a stranger\'s preference into the '
              'owner\'s dashboard');
      expect(find.bySemanticsIdentifier('dashboard-refresh'), findsOneWidget,
          reason: 'the header rendered, so the absence above is the action and '
              'not the whole bar');
      handle.dispose();
    });
  });

  // ===========================================================================
  // sessionExitAction + recoveryMessages
  // ===========================================================================
  //
  // The only consumer here that is a *function* rather than a page, and the one
  // whose failure mode is a modal nobody can leave: `showAppSpinnerDialog` passes
  // `barrierDismissible: false`, and `showRecoveryDialog`'s only `pop` fires on a
  // transition into `authenticated`. So the exit action is not decoration — it is
  // the whole way out, which is why `sessionExitAction()` returns a non-nullable
  // `Widget` and why this group asserts on the rendered dialog rather than on the
  // strategy alone.
  group('recovery dialog', () {
    /// Opens the dialog under [profile], pinned to `waitingForRecovery` so it
    /// stays open.
    ///
    /// `skipEnterWaiting: true` because the real `enterWaiting` consults cause 4
    /// (`ProximityStrategy.planFor`) and would answer "no recovery needed" for
    /// some trigger/mode pairs — a legitimate answer that is the subject of
    /// #1323's own tests, and here would silently mean "no dialog to assert on".
    Future<void> openRecoveryDialog(
      WidgetTester tester,
      AppModeProfile profile,
    ) async {
      await tester.pumpWidget(host(
        profile: profile,
        overrides: [
          appConnectionStateProvider.overrideWith(
            () => FixedAppConnectionStateNotifier(
              fixedState: AppConnectionState.waitingForRecovery,
            ),
          ),
        ],
        page: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => showRecoveryDialog(
              context,
              ref,
              trigger: RecoveryTrigger.operationalReboot,
              cooldown: Duration.zero,
              skipEnterWaiting: true,
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      // The dialog's spinner never stops, so a plain pumpAndSettle would time
      // out on it rather than on anything this test is about.
      await settleIgnoringAnimations(tester);
    }

    testWidgets('local offers the login page, remote offers to end the session',
        (tester) async {
      final handle = tester.ensureSemantics();
      useTallSurface(tester);

      await openRecoveryDialog(tester, const LocalModeProfile());
      expect(find.bySemanticsIdentifier('firmware-recovery-return-login'),
          findsOneWidget,
          reason: 'the owner has a password and a login form to type it into');
      expect(find.bySemanticsIdentifier('firmware-recovery-end-session'),
          findsNothing);

      handle.dispose();
    });

    testWidgets('remote assistance offers End session instead', (tester) async {
      // Disposed inline rather than via addTearDown: the binding verifies every
      // handle is released at the end of the test *body*, so a deferred dispose
      // fails the test it was meant to clean up.
      final handle = tester.ensureSemantics();
      useTallSurface(tester);

      await openRecoveryDialog(tester, const RemoteModeProfile());

      expect(find.bySemanticsIdentifier('firmware-recovery-end-session'),
          findsOneWidget,
          reason: 'acceptance 1/2 of #1323, now reached by composition: the '
              'credential was a one-shot Guardian token, so "Return to login '
              'page" is an offer to go somewhere unreachable — and it reads as '
              'the escape hatch, so the agent takes it and lands on a dead login '
              'form with the session still running');
      expect(find.bySemanticsIdentifier('firmware-recovery-return-login'),
          findsNothing,
          reason: 'acceptance 5c: no page decides where an ending session '
              'lands, and this is the one that used to');

      handle.dispose();
    });

    testWidgets('local shows the reconnect hint', (tester) async {
      useTallSurface(tester);

      await openRecoveryDialog(tester, const LocalModeProfile());

      expect(
        find.textContaining('reconnect to your router'),
        findsOneWidget,
        reason: 'the string moved out of the call site and into '
            'LocalSurface.recoveryMessages(), so it has to still arrive',
      );
    });

    testWidgets('remote assistance shows no hint at all', (tester) async {
      useTallSurface(tester);

      await openRecoveryDialog(tester, const RemoteModeProfile());

      // Acceptance 5b. Empty rather than reworded: the agent's browser is nowhere
      // near the Wi-Fi that is restarting, and an accurate remote line is new
      // user-visible copy in 26 locales — debt #1497 declines to hide behind a
      // refactor.
      expect(find.textContaining('reconnect to your router'), findsNothing);
      expect(find.textContaining('Wi-Fi network may restart'), findsNothing);
    });

    testWidgets('the message-less dialog stays usable across rotations',
        (tester) async {
      // WHAT THIS DOES AND DOES NOT ASSERT, because the difference cost a
      // falsification run. Writing the empty-message case turned up a real defect
      // in `showAppSpinnerDialog`: `messages[i++ % messages.length]` on a
      // 3-second timer is `% 0` for an empty list, an
      // IntegerDivisionByZeroException thrown inside a `Stream.map` — and
      // `messages: const []` has always been that parameter's default, so the bug
      // predates #1497 and #1497 merely gave it its first caller.
      //
      // It is fixed (the stream is only built for two or more messages), and this
      // test does NOT prove the fix: StreamBuilder folds the throw into an error
      // snapshot, the builder reads `hasData`, and the tree is byte-identical
      // either way. Reverting the fix leaves this file green — measured, not
      // assumed. The fix's justification is the reading, and it is recorded in
      // `dialogs.dart` where the code is.
      //
      // What is left here is still worth having, just narrower than it looks: an
      // empty `messages` list must render no message text and must not take the
      // dialog down over several rotation periods. That is the regression a future
      // `messages.first` or a rotation rewrite would cause, and it is visible.
      useTallSurface(tester);

      await openRecoveryDialog(tester, const RemoteModeProfile());
      await tester.pump(const Duration(seconds: 10));

      expect(tester.takeException(), isNull);
      expect(find.byType(AppDialog), findsOneWidget,
          reason:
              'the dialog is still standing, so the agent still has an exit '
              'action to tap');
      expect(find.bySemanticsIdentifier('firmware-recovery-end-session'),
          findsOneWidget);
    });
  });
}
