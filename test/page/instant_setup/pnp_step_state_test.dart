import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';

void main() {
  group('PnpNotifier Step State Management Tests', () {
    late ProviderContainer container;
    late PnpNotifier pnpNotifier;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          pnpProvider.overrideWith(() => PnpNotifier()),
        ],
      );
      pnpNotifier = container.read(pnpProvider.notifier) as PnpNotifier;
    });

    tearDown(() {
      container.dispose();
    });

    test('setStepData updates PnpStepState data correctly', () {
      const stepId = PnpStepId.personalWifi;
      final testData = {'ssid': 'MyWiFi', 'password': 'password123'};

      pnpNotifier.setStepData(stepId, data: testData);

      final stepState = pnpNotifier.getStepState(stepId);
      expect(stepState.data, testData);
      // setStepData merges data but doesn't change status; default is loading
      expect(stepState.status, StepViewStatus.loading);
    });

    test('setStepStatus updates PnpStepState status correctly', () {
      const stepId = PnpStepId.guestWifi;

      pnpNotifier.setStepStatus(stepId, status: StepViewStatus.loading);
      expect(pnpNotifier.getStepState(stepId).status, StepViewStatus.loading);

      pnpNotifier.setStepStatus(stepId, status: StepViewStatus.error);
      expect(pnpNotifier.getStepState(stepId).status, StepViewStatus.error);

      pnpNotifier.setStepStatus(stepId, status: StepViewStatus.data);
      expect(pnpNotifier.getStepState(stepId).status, StepViewStatus.data);
    });

    test('setStepError updates PnpStepState error correctly', () {
      const stepId = PnpStepId.nightMode;
      final testError = Exception('Validation failed');

      pnpNotifier.setStepError(stepId, error: testError);

      final stepState = pnpNotifier.getStepState(stepId);
      expect(stepState.error, testError);
      // setStepError only sets error, doesn't change status; default is loading
      expect(stepState.status, StepViewStatus.loading);
    });

    test(
        'setStepError and setStepStatus can be used together for validation failure',
        () {
      const stepId = PnpStepId.personalWifi;
      final testError = Exception('Invalid SSID');

      pnpNotifier.setStepError(stepId, error: testError);
      pnpNotifier.setStepStatus(stepId, status: StepViewStatus.error);

      final stepState = pnpNotifier.getStepState(stepId);
      expect(stepState.error, testError);
      expect(stepState.status, StepViewStatus.error);
    });

    // Test that initial step state is data and empty map
    test('getStepState returns default PnpStepState for uninitialized step',
        () {
      const stepId = PnpStepId.yourNetwork;
      final stepState = pnpNotifier.getStepState(stepId);

      expect(stepState.status, StepViewStatus.data);
      expect(stepState.data, isEmpty);
      expect(stepState.error, isNull);
    });

    // Test that setStepState replaces the entire step state
    test('setStepState replaces the entire PnpStepState for a step', () {
      const stepId = PnpStepId.personalWifi;
      final initialData = {'ssid': 'OldWiFi'};
      pnpNotifier.setStepData(stepId, data: initialData);

      final newStepState = PnpStepState(
        status: StepViewStatus.error,
        data: {'ssid': 'NewWiFi', 'password': 'newpassword'},
        error: Exception('New error'),
      );
      pnpNotifier.setStepState(stepId, newStepState);

      final stepState = pnpNotifier.getStepState(stepId);
      expect(stepState, newStepState);
      expect(stepState.data, {'ssid': 'NewWiFi', 'password': 'newpassword'});
      expect(stepState.status, StepViewStatus.error);
      expect(stepState.error, isA<Exception>());
    });
  });
}
