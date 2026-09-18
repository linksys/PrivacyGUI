// Screenshots for the IPoE page the troubleshooter's ISP type list now offers.
//
// The list entry itself is already covered by pnp_isp_type_selection_view_test,
// but nothing rendered this page, so its description, its determinate progress
// copy and its whole recovery card were untranslated-string blind spots. The
// three states below are the ones that own strings no other golden reaches.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_ipoe_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../../../common/di.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';
import '../../../../../../mocks/internet_settings_notifier_mocks.dart';
import '../../../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import '../../../../../../test_data/auto_ipoe_state_data.dart';
import '../../../../../../test_data/device_info_test_data.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';

/// The page asks the router for its capabilities in initState and sits on a
/// full-screen spinner until that answers, so the fake decides which modes the
/// dropdown offers.
class _Service extends Fake implements AutoIPoEService {
  _Service(this.capabilities);

  final AutoIPoECapabilities capabilities;

  @override
  Future<AutoIPoECapabilities> getCapabilities() async => capabilities;
}

/// Read-only reconciliation that reports one progress step and then never
/// finishes, which is exactly the state the user is looking at while the router
/// applies the tunnel. Nothing here re-sends Apply.
class _StalledBridge extends Fake implements AutoIPoEInternetSettingsBridge {
  _StalledBridge(this.report);

  final AutoIPoEReconciliationProgress report;
  final _never = Completer<AutoIPoELog>();

  @override
  Future<AutoIPoELog> waitForPnpIPoESetupCompletion({
    int maxRetry = 80,
    Duration retryDelay = const Duration(seconds: 3),
    AutoIPoEMode? expectedMode,
    bool useStructuredProgress = false,
    AutoIPoEProgressCallback? onProgress,
    AutoIPoEReconciliationProgressCallback? onReconciliationProgress,
  }) {
    onReconciliationProgress?.call(report);
    return _never.future;
  }
}

/// Stands in for the save page. Popping the issue is the whole contract the
/// real one has with this view, and doing it from a stub keeps these
/// screenshots off the save/Apply path entirely.
GoRoute _saveRoutePopping(AutoIPoEIssue issue) => GoRoute(
      name: RouteNamed.pnpIspSaveSettings,
      path: '/save',
      builder: (context, _) => TextButton(
        onPressed: () => context.pop(issue),
        // Untranslated on purpose: this stub is never in frame when the
        // golden is taken.
        child: const Text('pop'),
      ),
    );

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  final capabilities = AutoIPoEState.fromMap(autoIPoEStateAuto).capabilities;

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();

    when(mockServiceHelper.isSupportAutoIPoE()).thenReturn(true);
    when(mockPnpNotifier.build()).thenReturn(PnpState(
      deviceInfo: NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
      isUnconfigured: true,
    ));

    final mockInternetSettingsState =
        InternetSettingsState.fromJson(internetSettingsStateData);
    when(mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    when(mockInternetSettingsNotifier.fetch()).thenAnswer((_) async {
      return mockInternetSettingsState;
    });
  });

  tearDown(() {
    reset(mockServiceHelper);
  });

  List<Override> overrides(AutoIPoEInternetSettingsBridge bridge) => [
        pnpProvider.overrideWith(() => mockPnpNotifier),
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
        autoIPoEServiceProvider.overrideWithValue(_Service(capabilities)),
        autoIPoEInternetSettingsBridgeProvider.overrideWithValue(bridge),
      ];

  // The editor as the troubleshooter first shows it: the page description, the
  // IPoE mode dropdown defaulted to Auto, and Next.
  testLocalizations('Troubleshooter - PnP IPoE: default',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpIpoeView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: overrides(
          _StalledBridge(const AutoIPoEReconciliationProgress.initial()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  // Apply was accepted but not finished, so the page swaps the editor for the
  // compact determinate panel. Step 4 with a numbered attempt is the only state
  // that renders the connectivity-attempt string, which takes two placeholders.
  testLocalizations('Troubleshooter - PnP IPoE: reconciling after apply',
      (tester, locale) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          builder: (context, state) => const PnpIpoeView(),
        ),
        _saveRoutePopping(const AutoIPoEIssue(
          category: AutoIPoEIssueCategory.retryable,
          code: 'ApplyAccepted',
          retryable: true,
          recoveryAction: AutoIPoERecoveryAction.continueChecking,
        )),
      ],
    );
    await tester.pumpWidget(
      testableRouter(
        router: router,
        locale: locale,
        overrides: overrides(
          _StalledBridge(const AutoIPoEReconciliationProgress
              .connectivityChecking(attempt: 3, attemptTotal: 30)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // By type, not by label: the label is one of the strings under test here.
    await tester.tap(find.byType(AppFilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('pop'));
    await tester.pumpAndSettle();
    // No teardown here: the screenshot is taken after this callback returns, so
    // pumping the tree away would golden an empty frame.
  });

  // The worker ended without connecting and wants a fresh Apply. This is the
  // full recovery card: retry title, the "a new Apply is required" line, the
  // error code row, Retry and Edit settings. Retryable keeps the terminal
  // failure dialog from covering it.
  testLocalizations('Troubleshooter - PnP IPoE: recovery needs fresh apply',
      (tester, locale) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          builder: (context, state) => const PnpIpoeView(),
        ),
        _saveRoutePopping(const AutoIPoEIssue(
          category: AutoIPoEIssueCategory.provider,
          code: 'ErrorAutoIPoEProvisioningFailed',
          retryable: true,
          fieldGroup: AutoIPoEFieldGroup.mode,
          recoveryAction: AutoIPoERecoveryAction.retrySetup,
        )),
      ],
    );
    await tester.pumpWidget(
      testableRouter(
        router: router,
        locale: locale,
        overrides: overrides(
          _StalledBridge(const AutoIPoEReconciliationProgress.initial()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppFilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('pop'));
    await tester.pumpAndSettle();
    // No teardown here: the screenshot is taken after this callback returns, so
    // pumping the tree away would golden an empty frame.
  });
}
