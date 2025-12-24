import 'package:flutter/material.dart'
    hide ControlsWidgetBuilder, ControlsDetails;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/mock_pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_stepper.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:ui_kit_library/ui_kit.dart'
    hide ControlsWidgetBuilder, ControlsDetails;

import '../../../common/theme_data.dart';

// A simple mock PnpStep for testing the stepper's logic.
class MockPnpStep extends PnpStep {
  bool onInitCalled = false;

  // Use a unique but predictable ID for finding widgets.
  MockPnpStep(String id)
      : super(stepId: PnpStepId.values.firstWhere((e) => e.name == id));

  @override
  Future<void> onInit(WidgetRef ref) async {
    onInitCalled = true;
    super.onInit(ref);
  }

  @override
  Widget content(
      {required BuildContext context, required WidgetRef ref, Widget? child}) {
    return Text('Content for ${stepId.name}');
  }

  @override
  ControlsWidgetBuilder controlBuilder(int currentStep, int stepIndex) {
    return (context, details) {
      return Row(
        children: [
          AppButton(
            label: 'Cancel',
            onTap: details.onStepCancel,
          ),
          AppButton(
            label: 'Continue',
            onTap: details.onStepContinue,
          ),
        ],
      );
    };
  }

  @override
  String title(BuildContext context) => stepId.name;

  @override
  Map<String, dynamic> getValidationData() => {};

  @override
  Map<String, List<ValidationRule>> getValidationRules() => {};

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async => {};

  @override
  void onDispose() {}
}

void main() {
  group('PnpStepper Widget Tests', () {
    late ProviderContainer container;
    late MockPnpStep step1;
    late MockPnpStep step2;

    setUp(() {
      // Use predictable names for stable finders
      step1 = MockPnpStep('personalWifi');
      step2 = MockPnpStep('guestWifi');

      container = ProviderContainer(
        overrides: [
          pnpProvider.overrideWith(() => BaseMockPnpNotifier()),
        ],
      );
    });

    tearDown(() => container.dispose());

    Future<void> pumpStepper(WidgetTester tester, List<PnpStep> steps,
        {VoidCallback? onLastStep}) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: mockLightThemeData,
            home: Scaffold(
              body: AppResponsiveLayout(
                mobile: (ctx) => PnpStepper(
                  steps: steps,
                  onLastStep: onLastStep,
                ),
                desktop: (ctx) => PnpStepper(
                  steps: steps,
                  onLastStep: onLastStep,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'does not initialize first step if status is not wizardConfiguring',
        (tester) async {
      // Arrange
      final mockNotifier =
          container.read(pnpProvider.notifier) as BaseMockPnpNotifier;
      mockNotifier.setStatus(PnpFlowStatus.adminInitializing);
      await pumpStepper(tester, [step1, step2]);

      // Act
      await tester
          .pump(); // Use pump instead of pumpAndSettle to avoid timeout from potential infinite animations

      // Assert
      expect(step1.onInitCalled, isFalse);
    });

    testWidgets('initializes first step when flow status is wizardConfiguring',
        (tester) async {
      // Arrange
      final mockNotifier =
          container.read(pnpProvider.notifier) as BaseMockPnpNotifier;
      mockNotifier.setStatus(PnpFlowStatus.wizardConfiguring);
      await pumpStepper(tester, [step1, step2]);

      // Act
      await tester.pumpAndSettle(); // Wait for post-frame callback

      // Assert
      expect(step1.onInitCalled, isTrue);
      expect(step2.onInitCalled, isFalse);
      expect(find.text('Content for personalWifi'), findsOneWidget);
    });

    testWidgets('onStepContinue moves to the next step and calls onInit',
        (tester) async {
      // Arrange
      final mockNotifier =
          container.read(pnpProvider.notifier) as BaseMockPnpNotifier;
      mockNotifier.setStatus(PnpFlowStatus.wizardConfiguring);
      await pumpStepper(tester, [step1, step2]);
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();

      // Assert
      expect(step2.onInitCalled, isTrue);
      expect(find.text('Content for guestWifi'), findsOneWidget);
      expect(find.text('Content for personalWifi'), findsNothing);
    });

    testWidgets('onStepCancel moves to the previous step', (tester) async {
      // Arrange
      final mockNotifier =
          container.read(pnpProvider.notifier) as BaseMockPnpNotifier;
      mockNotifier.setStatus(PnpFlowStatus.wizardConfiguring);
      await pumpStepper(tester, [step1, step2]);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();

      // Pre-condition check
      expect(find.text('Content for guestWifi'), findsOneWidget);

      // Act
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Content for personalWifi'), findsOneWidget);
      expect(find.text('Content for guestWifi'), findsNothing);
    });

    testWidgets('onLastStep is called when continuing from the final step',
        (tester) async {
      // Arrange
      bool onLastStepCalled = false;
      final mockNotifier =
          container.read(pnpProvider.notifier) as BaseMockPnpNotifier;
      mockNotifier.setStatus(PnpFlowStatus.wizardConfiguring);
      await pumpStepper(tester, [step1], onLastStep: () {
        onLastStepCalled = true;
      });
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();

      // Assert
      expect(onLastStepCalled, isTrue);
    });
  });
}
