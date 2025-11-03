import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/your_network_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/mock_pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart'; // Restored
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart'; // Corrected for StepViewStatus
import 'package:privacygui_widgets/theme/custom_responsive.dart';

void main() {
  group('YourNetworkStep Corrected Widget Tests', () {
    late ProviderContainer container;
    late YourNetworkStep yourNetworkStep;
    WidgetRef? capturedRef;

    setUp(() {
      yourNetworkStep = YourNetworkStep();
      container = ProviderContainer(
        overrides: [
          // Use the UnconfiguredMockPnpNotifier as it has a mock for fetchDevices
          pnpProvider.overrideWith(() => UnconfiguredMockPnpNotifier()),
        ],
      );
      capturedRef = null; // Reset for each test
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CustomResponsive(
              child: Scaffold(
                body: Consumer(builder: (context, ref, child) {
                  capturedRef = ref; // Capture the ref
                  return yourNetworkStep.content(context: context, ref: ref);
                }),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('onInit calls fetchDevices and updates UI with nodes', (tester) async {
      // Arrange
      final pnpNotifier = container.read(pnpProvider.notifier) as UnconfiguredMockPnpNotifier;
      // The mock implementation of fetchDevices in UnconfiguredMockPnpNotifier already returns a list of nodes.

      // Act
      await pumpWidget(tester);
      expect(capturedRef, isNotNull);
      await yourNetworkStep.onInit(capturedRef!);
      await tester.pumpAndSettle(); // Re-render with the new state

      // Assert
      final stepState = pnpNotifier.getStepState(yourNetworkStep.stepId);
      expect(stepState.status, StepViewStatus.data);

      // Assert that the child nodes from the mock are displayed in the UI
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('Bedroom'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
    });

    testWidgets('onInit sets status to error when fetchDevices fails', (tester) async {
      // Arrange
      final pnpNotifier = container.read(pnpProvider.notifier) as UnconfiguredMockPnpNotifier;
      pnpNotifier.shouldThrowFetchDevicesError = true;

      // Act
      await pumpWidget(tester);
      expect(capturedRef, isNotNull);
      await yourNetworkStep.onInit(capturedRef!);

      // Assert
      final stepState = pnpNotifier.getStepState(yourNetworkStep.stepId);
      expect(stepState.status, StepViewStatus.error);
    });

    testWidgets('onNext returns an empty map', (tester) async {
      // Arrange
      await pumpWidget(tester);
      expect(capturedRef, isNotNull);

      // Act
      final result = await yourNetworkStep.onNext(capturedRef!);

      // Assert
      expect(result, isEmpty);
    });

    testWidgets('getValidationData returns an empty map', (tester) async {
      // No arrangement needed

      // Act
      final result = yourNetworkStep.getValidationData();

      // Assert
      expect(result, isEmpty);
    });

    testWidgets('getValidationRules returns an empty map', (tester) async {
      // No arrangement needed

      // Act
      final result = yourNetworkStep.getValidationRules();

      // Assert
      expect(result, isEmpty);
    });
  });
}
