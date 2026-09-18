// Characterization tests for the Auto-IPoE coordination in Internet Settings.
//
// These exist to hold the behaviour still while that coordination moves out of
// the widget. They are written against what a user can observe -- how many times
// Apply is dispatched, which dialog appears, whether the page reports the save
// as done -- so they keep working after the logic moves, which is the whole
// point of writing them before it does.
//
// The re-entrancy guard is the one worth being explicit about: Apply restarts
// WAN and WiFi, so a second dispatch from a double tap has real consequences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_notifier.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/di.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/internet_settings_notifier_mocks.dart';
import '../../../../test_data/auto_ipoe_state_data.dart';
import '../../../../test_data/internet_settings_state_data.dart';

/// Keeps the page off the network: the real notifier fetches on entry and the
/// log pane polls the runtime for as long as IPoE is the WAN type.
class _SeededAutoIPoENotifier extends AutoIPoENotifier {
  _SeededAutoIPoENotifier(this._seed);

  final AutoIPoEState _seed;

  @override
  AutoIPoEState build() => _seed;

  @override
  Future<AutoIPoEState> fetchAll() async => state;

  @override
  Future<AutoIPoEState> refreshRuntime() async => state;

  @override
  Future<AutoIPoEState> refreshStatus() async => state;
}

/// Counts dispatches and lets each test decide how reconciliation ends.
class _ScriptedBridge extends Fake implements AutoIPoEInternetSettingsBridge {
  _ScriptedBridge({this.waitOutcome});

  /// Thrown from the reconciliation wait; null completes it normally.
  final Object? waitOutcome;

  int applyCalls = 0;
  int waitCalls = 0;

  @override
  Future<void> saveIPoEInternetSettings({
    required AutoIPoESettings settings,
    required WanType? originalWanType,
    AutoIPoEStatus? originalStatus,
  }) async {
    applyCalls++;
  }

  @override
  Future<AutoIPoELog> waitForPnpIPoESetupCompletion({
    int maxRetry = 80,
    Duration retryDelay = const Duration(seconds: 3),
    AutoIPoEMode? expectedMode,
    bool useStructuredProgress = false,
    AutoIPoEProgressCallback? onProgress,
    AutoIPoEReconciliationProgressCallback? onReconciliationProgress,
  }) async {
    waitCalls++;
    if (waitOutcome != null) {
      throw waitOutcome!;
    }
    return const AutoIPoELog.init();
  }
}

/// The bottom bar's Save button, found by the identifier the shared page view
/// stamps on it rather than by its label, which is localized.
final saveButton = find.byWidgetPredicate((widget) =>
    widget is AppFilledButton &&
    widget.identifier == 'now-page-bottom-button-positive');

const terminalDialog = ValueKey('autoIpoeTerminalFailureDialog');

void main() {
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;
  late _ScriptedBridge bridge;

  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  final seed = AutoIPoEState.fromMap(autoIPoEStateAuto);

  setUp(() {
    bridge = _ScriptedBridge();
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
    final state = InternetSettingsState.fromMap(internetSettingsStateIpoe);
    when(mockInternetSettingsNotifier.build()).thenReturn(state);
    when(mockInternetSettingsNotifier.fetch(
            fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer((_) async => state);
    when(mockServiceHelper.isSupportAutoIPoE()).thenReturn(true);
  });

  tearDown(() {
    reset(mockServiceHelper);
  });

  /// Mounts the page, enters edit mode and makes an edit, which is what the
  /// bottom bar requires before it enables Save. The edit is written through the
  /// provider, exactly as the section's own onChanged does.
  Future<void> pumpAndEdit(WidgetTester tester) async {
    await tester.pumpWidget(testableSingleRoute(
      child: const InternetSettingsView(),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
        autoIPoEProvider.overrideWith(() => _SeededAutoIPoENotifier(seed)),
        autoIPoEInternetSettingsBridgeProvider.overrideWithValue(bridge),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LinksysIcons.edit).first);
    await tester.pumpAndSettle();

    ProviderScope.containerOf(tester.element(find.byType(InternetSettingsView)))
        .read(autoIPoEProvider.notifier)
        .updateSettings(
          seed.settings.copyWith(selectedMode: AutoIPoEMode.v6PlusStaticIp),
        );
    await tester.pumpAndSettle();
  }

  testWidgets('saving an IPoE change dispatches Apply once and reconciles it',
      (tester) async {
    await pumpAndEdit(tester);
    expect(saveButton, findsOneWidget);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(bridge.applyCalls, 1);
    expect(bridge.waitCalls, 1);
  });

  testWidgets(
      'a second tap while the first save is in flight does not re-dispatch '
      'Apply', (tester) async {
    await pumpAndEdit(tester);

    await tester.tap(saveButton);
    await tester.pump();
    if (tester.any(saveButton)) {
      await tester.tap(saveButton, warnIfMissed: false);
    }
    await tester.pumpAndSettle();

    expect(bridge.applyCalls, 1);
  });

  testWidgets('a terminal reconciliation failure is reported in a dialog',
      (tester) async {
    bridge = _ScriptedBridge(
      waitOutcome: const AutoIPoETerminalFailure(AutoIPoEIssue(
        category: AutoIPoEIssueCategory.provider,
        code: 'ErrorAutoIPoEProvisioningFailed',
        retryable: false,
        recoveryAction: AutoIPoERecoveryAction.retrySetup,
      )),
    );

    await pumpAndEdit(tester);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.byKey(terminalDialog), findsOneWidget);
  });

  testWidgets('a completed reconciliation leaves editing and shows no failure',
      (tester) async {
    await pumpAndEdit(tester);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Leaving edit mode takes the bottom bar with it, which is the observable
    // half of the finalizing path.
    expect(saveButton, findsNothing);
    expect(find.byKey(terminalDialog), findsNothing);
  });
}
