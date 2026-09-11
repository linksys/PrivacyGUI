import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/auto_ipoe_section.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_optional_pane.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_recovery_ui.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';

import '../../../common/testable_widget.dart';
import '../../../common/testable_router.dart';

void main() {
  testWidgets('an in-progress recovery offers read-only checking only',
      (tester) async {
    var checks = 0;
    var retries = 0;
    var edits = 0;
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoERecoveryPanel(
          isChecking: false,
          progress: const AutoIPoEReconciliationProgress.initial(),
          issue: const AutoIPoEIssue(
            category: AutoIPoEIssueCategory.retryable,
            code: 'WAN6NotReady',
            retryable: true,
            recoveryAction: AutoIPoERecoveryAction.continueChecking,
          ),
          onContinueChecking: () => checks++,
          onRetry: () => retries++,
          onEditSettings: () => edits++,
        ),
      ),
    );

    expect(find.text('Continue Checking'), findsOneWidget);
    expect(find.text('Retry Setup'), findsNothing);
    expect(find.text('Edit Settings'), findsOneWidget);
    expect(
      find.textContaining('does not apply the settings again'),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue Checking'));
    await tester.tap(find.text('Edit Settings'));
    expect((checks, retries, edits), (1, 0, 1));
  });

  testWidgets(
      'terminal retry returns to populated form without automatically applying',
      (tester) async {
    var recovering = true;
    var applies = 0;
    var checks = 0;

    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: StatefulBuilder(
          builder: (context, setState) => recovering
              ? AutoIPoERecoveryPanel(
                  isChecking: false,
                  issue: const AutoIPoEIssue(
                    category: AutoIPoEIssueCategory.retryable,
                    code: 'ConnectivityFailed',
                    retryable: true,
                    recoveryAction: AutoIPoERecoveryAction.retrySetup,
                  ),
                  onContinueChecking: () => checks++,
                  onRetry: () => setState(() => recovering = false),
                  onEditSettings: () => setState(() => recovering = false),
                )
              : Column(
                  children: [
                    const Text('kept-value'),
                    TextButton(
                      onPressed: () => applies++,
                      child: const Text('Save once'),
                    ),
                  ],
                ),
        ),
      ),
    );

    expect(find.text('Retry Setup'), findsOneWidget);
    expect(find.text('Continue Checking'), findsNothing);
    await tester.tap(find.text('Retry Setup'));
    await tester.pump();

    expect(find.text('kept-value'), findsOneWidget);
    expect(applies, 0);
    expect(checks, 0);

    await tester.tap(find.text('Save once'));
    expect(applies, 1);
  });

  testWidgets('PnP shows scheduled provider recovery as a recoverable state',
      (tester) async {
    var checks = 0;
    var edits = 0;
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoERecoveryPanel(
          compactProgress: true,
          isChecking: false,
          issue: const AutoIPoEIssue(
            category: AutoIPoEIssueCategory.provider,
            code: 'RetryScheduled',
            retryable: true,
            recoveryAction: AutoIPoERecoveryAction.scheduledRetry,
          ),
          onContinueChecking: () => checks++,
          onRetry: () {},
          onEditSettings: () => edits++,
        ),
      ),
    );

    expect(find.text('Provider recovery is scheduled'), findsOneWidget);
    expect(find.textContaining('scheduled another automatic'), findsOneWidget);
    expect(find.text('Continue Checking'), findsOneWidget);
    expect(find.text('Edit Settings'), findsOneWidget);
    expect(find.text('Retry Setup'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Continue Checking'));
    await tester.tap(find.text('Edit Settings'));
    expect((checks, edits), (1, 1));
  });

  testWidgets('Advanced shows scheduled recovery in a non-failure dialog',
      (tester) async {
    AutoIPoERetryScheduledDialogAction? action;
    await tester.pumpWidget(
      testableSingleRoute(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              action = await showAutoIPoERetryScheduledDialog(
                context,
                const AutoIPoEIssue(
                  category: AutoIPoEIssueCategory.provider,
                  code: 'RetryScheduled',
                  retryable: true,
                  recoveryAction: AutoIPoERecoveryAction.scheduledRetry,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('autoIpoeRetryScheduledDialog')),
      findsOneWidget,
    );
    expect(find.text('Provider recovery is scheduled'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('autoIpoeTerminalFailureDialog')),
      findsNothing,
    );

    await tester.tap(find.text('Continue Checking'));
    await tester.pumpAndSettle();
    expect(
      action,
      AutoIPoERetryScheduledDialogAction.continueChecking,
    );

    action = null;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Settings'));
    await tester.pumpAndSettle();
    expect(action, AutoIPoERetryScheduledDialogAction.editSettings);
  });

  testWidgets('Japanese terminal dialog is actionable', (tester) async {
    await tester.pumpWidget(
      testableSingleRoute(
        locale: const Locale('ja'),
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAutoIPoETerminalFailureDialog(
              context,
              const AutoIPoEIssue(
                category: AutoIPoEIssueCategory.validation,
                code: 'MissingV6PlusStaticIPSettings',
                retryable: false,
                fieldGroup: AutoIPoEFieldGroup.v6PlusStaticIp,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('IPoE設定を確認してください'), findsOneWidget);
    expect(find.text('設定を編集'), findsOneWidget);
    expect(
        find.textContaining('MissingV6PlusStaticIPSettings'), findsOneWidget);
  });

  testWidgets('Edit Settings remains available while a check is in flight',
      (tester) async {
    var edits = 0;
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoERecoveryPanel(
          isChecking: false,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () => edits++,
        ),
      ),
    );

    await tester.tap(find.text('Edit Settings'));
    expect(edits, 1);
  });

  testWidgets('missing settings highlights the selected mode field group',
      (tester) async {
    final settings = const AutoIPoESettings.init().copyWith(
      isEnabled: true,
      selectedMode: AutoIPoEMode.v6PlusStaticIp,
      v6PlusStaticIpSettings: const V6PlusStaticIPSettings(userId: 'kept-id'),
    );
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoESection(
          settings: settings,
          status: const AutoIPoEStatus.init(),
          capabilities: const AutoIPoECapabilities(
            isSupported: true,
            supportedModes: [AutoIPoEMode.v6PlusStaticIp],
            blocksManualIPv6Configuration: true,
            requiresResetOnExit: true,
          ),
          isEditing: true,
          highlightedFieldGroup: AutoIPoEFieldGroup.v6PlusStaticIp,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('autoIpoeV6PlusStaticIPFieldGroup')),
      findsOneWidget,
    );
    expect(find.text('Review the settings in this section.'), findsOneWidget);
    expect(find.text('kept-id'), findsOneWidget);
  });

  testWidgets('modes without editable fields never show a validation warning',
      (tester) async {
    const modesWithoutFields = [
      AutoIPoEMode.auto,
      AutoIPoEMode.ocnVirtualConnectStaticIp,
      AutoIPoEMode.ocxHikariV6ixStaticIp,
    ];

    for (final mode in modesWithoutFields) {
      await tester.pumpWidget(
        testableWidget(
          locale: const Locale('en'),
          child: AutoIPoESection(
            settings: const AutoIPoESettings.init().copyWith(
              isEnabled: true,
              selectedMode: mode,
            ),
            status: const AutoIPoEStatus.init(),
            capabilities: AutoIPoECapabilities(
              isSupported: true,
              supportedModes: [mode],
              blocksManualIPv6Configuration: true,
              requiresResetOnExit: true,
            ),
            isEditing: true,
            highlightedFieldGroup: AutoIPoEFieldGroup.none,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        find.text('Review the settings in this section.'),
        findsNothing,
        reason: '${mode.value} has no fields to review',
      );
    }
  });

  testWidgets('BIGLOBE uses the shared constrained credential editor',
      (tester) async {
    final settings = const AutoIPoESettings.init().copyWith(
      isEnabled: true,
      selectedMode: AutoIPoEMode.biglobeStaticIp,
      biglobeStaticIpSettings: const BiglobeStaticIPSettings(
        userId: AutoIPoESecret(hasStoredValue: true),
        userPassword: AutoIPoESecret(hasStoredValue: true),
      ),
    );
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoESection(
          settings: settings,
          status: const AutoIPoEStatus.init(),
          capabilities: const AutoIPoECapabilities(
            isSupported: true,
            supportedModes: [AutoIPoEMode.biglobeStaticIp],
            blocksManualIPv6Configuration: true,
            requiresResetOnExit: true,
          ),
          isEditing: true,
          highlightedFieldGroup: AutoIPoEFieldGroup.biglobeStaticIp,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('BIGLOBE IPIP (HB46PP)'), findsOneWidget);
    expect(find.text('Review the settings in this section.'), findsOneWidget);

    final userId = tester.widget<AppTextField>(
      find.byKey(const ValueKey('autoIpoeBiglobeUserId')),
    );
    final password = tester.widget<AppTextField>(
      find.byKey(const ValueKey('autoIpoeBiglobePassword')),
    );
    expect(userId.headerText, 'User ID');
    expect(userId.secured, isFalse);
    expect(userId.controller?.text, isEmpty);
    expect(userId.hintText, 'Stored on router');
    expect(password.headerText, 'Password');
    expect(password.secured, isTrue);
    expect(password.controller?.text, isEmpty);
    expect(password.hintText, 'Stored on router');

    var filtered = const TextEditingValue(
      text: 'abc.DEF_123-xyz!456789012345678901234567890',
    );
    for (final formatter in userId.inputFormatters!) {
      filtered = formatter.formatEditUpdate(TextEditingValue.empty, filtered);
    }
    expect(filtered.text, 'abcDEF_123-xyz456789012345678901');
    expect(filtered.text.length, 32);
  });

  testWidgets('BIGLOBE info view never exposes stored credentials',
      (tester) async {
    final settings = const AutoIPoESettings.init().copyWith(
      isEnabled: true,
      selectedMode: AutoIPoEMode.biglobeStaticIp,
      biglobeStaticIpSettings: const BiglobeStaticIPSettings(
        userId: AutoIPoESecret(hasStoredValue: true),
        userPassword: AutoIPoESecret(hasStoredValue: true),
      ),
    );
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoESection(
          settings: settings,
          status: const AutoIPoEStatus.init(),
          capabilities: const AutoIPoECapabilities(
            isSupported: true,
            supportedModes: [AutoIPoEMode.biglobeStaticIp],
            blocksManualIPv6Configuration: true,
            requiresResetOnExit: true,
          ),
          isEditing: false,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('BIGLOBE IPIP (HB46PP)'), findsOneWidget);
    expect(find.text('Configured'), findsNWidgets(2));
    expect(find.text('biglobe_id'), findsNothing);
  });

  testWidgets('PnP progress is compact and hides raw Auto-IPoE diagnostics',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoEOptionalPane(
          compactProgress: true,
          state: const AutoIPoEState.init().copyWith(
            log: const AutoIPoELog(
              content: 'raw mapv6 debug output',
              isComplete: false,
              rebootRecommended: false,
            ),
          ),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          issue: const AutoIPoEIssue(
            category: AutoIPoEIssueCategory.retryable,
            code: 'ApplyAccepted',
            retryable: true,
            recoveryAction: AutoIPoERecoveryAction.continueChecking,
          ),
          isChecking: false,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('autoIpoEProgressIndicator')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Checking your IPv6 connection…'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Completing IPoE setup'), findsNothing);
    expect(find.text('Continue Checking'), findsNothing);
    expect(find.text('Edit Settings'), findsNothing);
    expect(find.text('Show details'), findsOneWidget);
    expect(find.text('IPoE Log'), findsNothing);
    expect(find.textContaining('raw mapv6'), findsNothing);
    expect(find.textContaining('ApplyAccepted'), findsNothing);
  });

  testWidgets('compact PnP log expands and updates during reconciliation',
      (tester) async {
    var state = const AutoIPoEState.init().copyWith(
      status: const AutoIPoEStatus.init().copyWith(isBusy: true),
      log: const AutoIPoELog(
        content: 'Getting provider rules',
        isComplete: false,
        rebootRecommended: false,
      ),
    );
    late StateSetter updateWidget;
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: StatefulBuilder(
          builder: (context, setState) {
            updateWidget = setState;
            return AutoIPoEOptionalPane(
              compactProgress: true,
              progress: const AutoIPoEReconciliationProgress(
                currentStep: 2,
                phase: AutoIPoEProgressPhase.provisioning,
              ),
              state: state,
              shouldTrackRuntime: false,
              awaitingCompletion: true,
              isChecking: true,
              onContinueChecking: () {},
              onRetry: () {},
              onEditSettings: () {},
              onAwaitingCompletionChanged: (_) {},
            );
          },
        ),
      ),
    );

    expect(find.textContaining('Getting provider rules'), findsNothing);
    await tester.tap(find.text('Show details'));
    await tester.pump();

    expect(find.text('Hide details'), findsOneWidget);
    expect(find.text('IPoE Log'), findsOneWidget);
    expect(find.textContaining('Getting provider rules'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('autoIpoEProgressIndicator')),
      findsOneWidget,
    );

    updateWidget(() {
      state = state.copyWith(
        log: const AutoIPoELog(
          content: 'Getting provider rules\nConnectivity attempt 2/5',
          isComplete: false,
          rebootRecommended: false,
        ),
      );
    });
    await tester.pump();

    expect(find.textContaining('Connectivity attempt 2/5'), findsOneWidget);
    expect(find.text('Hide details'), findsOneWidget);
  });

  testWidgets('compact PnP log disclosure has localized Japanese semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('ja'),
        child: AutoIPoEOptionalPane(
          compactProgress: true,
          state: const AutoIPoEState.init(),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          isChecking: true,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('詳細を表示'), findsOneWidget);
    expect(find.bySemanticsLabel('IPoE設定ログを表示'), findsOneWidget);

    await tester.tap(find.text('詳細を表示'));
    await tester.pump();

    expect(find.text('詳細を隠す'), findsOneWidget);
    expect(find.bySemanticsLabel('IPoE設定ログを隠す'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('compact PnP progress shows the connectivity phase at 4 of 5',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoEOptionalPane(
          compactProgress: true,
          progress: const AutoIPoEReconciliationProgress(currentStep: 4),
          state: const AutoIPoEState.init(),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          isChecking: true,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('Testing the new Internet connection…'), findsOneWidget);
  });

  testWidgets('compact PnP progress describes observed IPoE states',
      (tester) async {
    for (final stage in const [
      (
        step: 2,
        message: 'Getting Internet settings from your ISP…',
      ),
      (
        step: 3,
        message:
            'Applying Internet settings… Your network may briefly restart.',
      ),
    ]) {
      await tester.pumpWidget(
        testableWidget(
          locale: const Locale('en'),
          child: AutoIPoEOptionalPane(
            compactProgress: true,
            progress: AutoIPoEReconciliationProgress(currentStep: stage.step),
            state: const AutoIPoEState.init(),
            shouldTrackRuntime: false,
            awaitingCompletion: true,
            isChecking: true,
            onContinueChecking: () {},
            onRetry: () {},
            onEditSettings: () {},
            onAwaitingCompletionChanged: (_) {},
          ),
        ),
      );

      expect(find.text('${stage.step}/5'), findsOneWidget);
      expect(find.text(stage.message), findsOneWidget);
    }
  });

  testWidgets('step 4 explains validation before connectivity attempts',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoEOptionalPane(
          compactProgress: true,
          progress: const AutoIPoEReconciliationProgress.validatingTunnel(),
          state: const AutoIPoEState.init(),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          isChecking: true,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('Testing the new Internet connection…'), findsOneWidget);
    expect(
      find.text('Waiting for the new connection to become ready…'),
      findsOneWidget,
    );
  });

  testWidgets('step 4 shows a structured connectivity attempt', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoEOptionalPane(
          compactProgress: true,
          progress: const AutoIPoEReconciliationProgress.connectivityChecking(
            attempt: 3,
            attemptTotal: 5,
          ),
          state: const AutoIPoEState.init(),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          isChecking: true,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('Testing the new Internet connection…'), findsOneWidget);
    expect(find.text('Attempt 3 of 5'), findsOneWidget);
  });

  testWidgets('compact PnP progress uses friendly Japanese completion copy',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('ja'),
        child: AutoIPoEOptionalPane(
          compactProgress: true,
          progress: const AutoIPoEReconciliationProgress.completed(),
          state: const AutoIPoEState.init(),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          isChecking: true,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('インターネット接続の準備ができました。'), findsOneWidget);
  });

  testWidgets('shared Advanced progress uses the five-stage PnP content',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: const AutoIPoECompactProgressContent(
          progress: AutoIPoEReconciliationProgress.connectivityChecking(
            attempt: 3,
            attemptTotal: 5,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('Testing the new Internet connection…'), findsOneWidget);
    expect(find.text('Attempt 3 of 5'), findsOneWidget);
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byKey(const ValueKey('autoIpoEProgressIndicator')),
    );
    expect(indicator.value, 0.8);
    expect(indicator.semanticsValue, 'Step 4 of 5');
  });

  testWidgets('custom IPoE spinner omits the generic Processing message',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showAppSpinnerDialog<void>(
                context,
                title: 'Saving changes...',
                titleTextAlign: TextAlign.center,
                messages: const [],
                loadingWidget: const AutoIPoECompactProgressContent(
                  progress: AutoIPoEReconciliationProgress.initial(),
                  centered: true,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Checking your IPv6 connection…'), findsOneWidget);
    expect(find.text('Processing...'), findsNothing);
    final progressPanel = tester.widget<Column>(
      find.byKey(const ValueKey('autoIpoECompactProgressPanel')),
    );
    expect(progressPanel.crossAxisAlignment, CrossAxisAlignment.center);
    final title = tester.widget<Text>(find.text('Saving changes...'));
    expect(title.textAlign, TextAlign.center);
    expect(
      tester.getCenter(find.text('Saving changes...')).dx,
      closeTo(
        tester
            .getCenter(
              find.byKey(const ValueKey('autoIpoEProgressIndicator')),
            )
            .dx,
        0.01,
      ),
    );
  });

  testWidgets('compact PnP progress preserves actionable real failures',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoEOptionalPane(
          compactProgress: true,
          state: const AutoIPoEState.init(),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          issue: const AutoIPoEIssue(
            category: AutoIPoEIssueCategory.retryable,
            code: 'ConnectivityFailed',
            retryable: true,
            recoveryAction: AutoIPoERecoveryAction.retrySetup,
          ),
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Retry Setup'), findsOneWidget);
    expect(find.text('Edit Settings'), findsOneWidget);
    expect(find.textContaining('ConnectivityFailed'), findsOneWidget);
    expect(find.text('IPoE Log'), findsNothing);
  });

  testWidgets('Advanced IPoE log is collapsed until details are requested',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoEOptionalPane(
          state: const AutoIPoEState.init().copyWith(
            log: const AutoIPoELog(
              content: 'advanced diagnostic details',
              isComplete: false,
              rebootRecommended: false,
            ),
          ),
          shouldTrackRuntime: false,
          awaitingCompletion: false,
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Show details'), findsOneWidget);
    expect(find.text('IPoE Log'), findsNothing);
    expect(find.textContaining('advanced diagnostic'), findsNothing);

    await tester.tap(find.text('Show details'));
    await tester.pump();

    expect(find.text('Hide details'), findsOneWidget);
    expect(find.text('IPoE Log'), findsOneWidget);
    expect(find.textContaining('advanced diagnostic'), findsOneWidget);
  });

  testWidgets('Advanced modal hides the background recovery panel',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoEOptionalPane(
          state: const AutoIPoEState.init(),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          isChecking: true,
          showRecovery: false,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Completing IPoE setup'), findsNothing);
    expect(
      find.byKey(const ValueKey('autoIpoERecoveryPanel')),
      findsNothing,
    );
    expect(find.text('Continue Checking'), findsNothing);
    expect(find.text('Edit Settings'), findsNothing);
    expect(find.text('Show details'), findsOneWidget);
  });

  testWidgets('Advanced post-modal check keeps the recovery panel visible',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
        locale: const Locale('en'),
        child: AutoIPoEOptionalPane(
          state: const AutoIPoEState.init(),
          shouldTrackRuntime: false,
          awaitingCompletion: true,
          isChecking: true,
          showRecovery: true,
          onContinueChecking: () {},
          onRetry: () {},
          onEditSettings: () {},
          onAwaitingCompletionChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('autoIpoERecoveryPanel')),
      findsOneWidget,
    );
  });
}
