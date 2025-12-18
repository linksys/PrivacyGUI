import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/personal_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/mock_pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';

import '../../../../common/_index.dart';

// A wrapper widget to correctly handle the lifecycle of the onInit call.
class InitOnceWrapper extends ConsumerStatefulWidget {
  final PersonalWiFiStep step;
  const InitOnceWrapper({Key? key, required this.step}) : super(key: key);

  @override
  ConsumerState<InitOnceWrapper> createState() => _InitOnceWrapperState();
}

class _InitOnceWrapperState extends ConsumerState<InitOnceWrapper> {
  @override
  void initState() {
    super.initState();
    // Call onInit here. It runs once and has access to a valid ref.
    widget.step.onInit(ref);
  }

  @override
  Widget build(BuildContext context) {
    // The content widget will be rebuilt on state changes, but initState will not be called again.
    return widget.step.content(context: context, ref: ref);
  }
}

void main() {
  group('PersonalWiFiStep Tests', () {
    late BaseMockPnpNotifier testPnpNotifier;
    late ProviderContainer container;
    late PersonalWiFiStep personalWiFiStep;
    WidgetRef? capturedRef;

    setUp(() {
      // Instantiate a new step object for each test to ensure isolation.
      personalWiFiStep = PersonalWiFiStep();
      testPnpNotifier = BaseMockPnpNotifier();
      container = ProviderContainer(
        overrides: [
          pnpProvider.overrideWith(() => testPnpNotifier),
        ],
      );
      capturedRef = null; // Reset for each test
    });

    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: mockLightThemeData,
            home: Scaffold(
              body: Consumer(builder: (context, ref, child) {
                capturedRef = ref; // Capture the ref
                return InitOnceWrapper(step: personalWiFiStep);
              }),
            ),
          ),
        ),
      );
    }

    // Helper to get the current PnpStepState for the personalWiFiStep
    PnpStepState getPersonalWifiStepState() {
      final pnpState = container.read(pnpProvider);
      final stepState = pnpState.stepStateList[personalWiFiStep.stepId];
      expect(stepState, isNotNull,
          reason: 'PnpStepState for personalWifiStep should not be null');
      return stepState!;
    }

    testWidgets('onInit should load default wifi data and trigger validation',
        (tester) async {
      // Arrange: The BaseMockPnpNotifier provides default wifi names.
      // Act
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Assert: Check if the text fields are populated with mock data.
      expect(find.text('Mock-WiFi'), findsOneWidget);
      expect(find.text('mock-password'), findsOneWidget);

      // Assert: Check if the initial state is valid because the default data is valid.
      final stepState = getPersonalWifiStepState();
      expect(stepState.status, StepViewStatus.data);
      // Safely check the error map.
      final errorMap = stepState.error as Map<String, String?>?;
      expect(errorMap?.values.every((e) => e == null) ?? true, isTrue);
    });

    testWidgets('should set step status to error for invalid password',
        (tester) async {
      // Arrange
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Act: Enter an invalid password (too short)
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.pumpAndSettle();

      // Assert: The step state should now be error
      final stepState = getPersonalWifiStepState();
      expect(stepState.status, StepViewStatus.error);
      expect(
          (stepState.error as Map<String, String?>?)?['password'], isNotNull);
    });

    testWidgets(
        'should set step status to data when correcting an invalid password',
        (tester) async {
      // Arrange: Start with an invalid password
      await pumpWidget(tester);
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.pumpAndSettle();

      // Verify it's in an error state first
      var stepState = getPersonalWifiStepState();
      expect(stepState.status, StepViewStatus.error);

      // Act: Enter a valid password
      await tester.enterText(find.byType(TextField).last, 'valid-password-123');
      await tester.pumpAndSettle();

      // Assert: The step state should recover to data
      stepState = getPersonalWifiStepState();
      expect(stepState.status, StepViewStatus.data);
      expect((stepState.error as Map<String, String?>?)?['password'], isNull);
    });

    testWidgets('onNext should return the current data from controllers',
        (tester) async {
      // Arrange
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Act: Enter custom data
      await tester.enterText(find.byType(TextField).first, 'MyNewSSID');
      await tester.enterText(find.byType(TextField).last, 'MyNewPassword123');
      await tester.pumpAndSettle();

      // Assert: Call onNext and check the returned value
      expect(capturedRef, isNotNull);
      final result = await personalWiFiStep.onNext(capturedRef!);
      expect(result['ssid'], 'MyNewSSID');
      expect(result['password'], 'MyNewPassword123');
    });
  });
}
