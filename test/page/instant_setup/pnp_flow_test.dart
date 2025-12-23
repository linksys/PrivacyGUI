import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/providers/mock_pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';

void main() {
  group('Pnp Flow Tests with Mock Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // --- Unconfigured Router (Factory Reset) ---
    test('Unconfigured Flow: startPnpFlow transitions to adminUnconfigured', () async {
      final pnpNotifier = container.read(unconfiguredPnpProvider.notifier);

      await pnpNotifier.startPnpFlow(null);

      expect(pnpNotifier.state.status, PnpFlowStatus.adminUnconfigured);
      expect(pnpNotifier.state.isRouterUnConfigured, isTrue);
      expect(pnpNotifier.state.attachedPassword, isNotNull);
    });

    test('Unconfigured Flow: continueFromUnconfigured transitions to wizardInitializing', () async {
      final pnpNotifier = container.read(unconfiguredPnpProvider.notifier);

      // Simulate initial state
      await pnpNotifier.startPnpFlow(null);
      expect(pnpNotifier.state.status, PnpFlowStatus.adminUnconfigured);

      await pnpNotifier.continueFromUnconfigured();

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardInitializing);
    });

    test('Unconfigured Flow: savePnpSettings transitions to wizardNeedsReconnect', () async {
      final pnpNotifier = container.read(unconfiguredPnpProvider.notifier);

      // Simulate initial state and wizard initialization
      await pnpNotifier.startPnpFlow(null);
      await pnpNotifier.continueFromUnconfigured();
      await pnpNotifier.initializeWizard();
      expect(pnpNotifier.state.status, PnpFlowStatus.wizardConfiguring);

      await pnpNotifier.savePnpSettings();

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardNeedsReconnect);
    });

    // --- Configured Router (Standard Flow) ---
    test('Configured Flow: startPnpFlow transitions to adminAwaitingPassword', () async {
      final pnpNotifier = container.read(configuredPnpProvider.notifier);

      await pnpNotifier.startPnpFlow(null);

      expect(pnpNotifier.state.status, PnpFlowStatus.adminAwaitingPassword);
      expect(pnpNotifier.state.isRouterUnConfigured, isFalse);
    });

    test('Configured Flow: submitPassword with correct password transitions to wizardInitializing', () async {
      final pnpNotifier = container.read(configuredPnpProvider.notifier);

      // Simulate initial state
      await pnpNotifier.startPnpFlow(null);
      expect(pnpNotifier.state.status, PnpFlowStatus.adminAwaitingPassword);

      await pnpNotifier.submitPassword('password');

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardInitializing);
    });

    test('Configured Flow: submitPassword with incorrect password transitions to adminLoginFailed', () async {
      final pnpNotifier = container.read(configuredPnpProvider.notifier);

      // Simulate initial state
      await pnpNotifier.startPnpFlow(null);
      expect(pnpNotifier.state.status, PnpFlowStatus.adminAwaitingPassword);

      await pnpNotifier.submitPassword('wrong_password');

      expect(pnpNotifier.state.status, PnpFlowStatus.adminLoginFailed);
      expect(pnpNotifier.state.error, isA<ExceptionInvalidAdminPassword>());
    });

    test('Configured Flow: savePnpSettings transitions to wizardWifiReady', () async {
      final pnpNotifier = container.read(configuredPnpProvider.notifier);

      // Simulate initial state and wizard initialization
      await pnpNotifier.startPnpFlow(null);
      await pnpNotifier.submitPassword('password');
      await pnpNotifier.initializeWizard();
      expect(pnpNotifier.state.status, PnpFlowStatus.wizardConfiguring);

      await pnpNotifier.savePnpSettings();

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardWifiReady);
    });

    // --- Mandatory Firmware Update ---
    test('FW Update Flow: savePnpSettings simulates firmware update and transitions to wizardWifiReady', () async {
      final pnpNotifier = container.read(fwUpdatePnpProvider.notifier);

      // Simulate initial state and wizard initialization
      await pnpNotifier.startPnpFlow(null);
      await pnpNotifier.submitPassword('password');
      await pnpNotifier.initializeWizard();
      expect(pnpNotifier.state.status, PnpFlowStatus.wizardConfiguring);

      await pnpNotifier.savePnpSettings();

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardWifiReady);
    });

    // --- Unconfigured Router with Mandatory Firmware Update ---
    test('Unconfigured FW Update Flow: savePnpSettings simulates firmware update and transitions to wizardNeedsReconnect', () async {
      final pnpNotifier = container.read(unconfiguredFwUpdatePnpProvider.notifier);

      // Simulate initial state and wizard initialization
      await pnpNotifier.startPnpFlow(null);
      await pnpNotifier.continueFromUnconfigured();
      await pnpNotifier.initializeWizard();
      expect(pnpNotifier.state.status, PnpFlowStatus.wizardConfiguring);

      await pnpNotifier.savePnpSettings();

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardNeedsReconnect);
    });

    // --- No Internet Connection ---
    test('No Internet Flow: continueFromUnconfigured transitions to adminNeedsInternetTroubleshooting', () async {
      final pnpNotifier = container.read(noInternetPnpProvider.notifier);

      // Simulate initial state
      await pnpNotifier.startPnpFlow(null);
      expect(pnpNotifier.state.status, PnpFlowStatus.adminUnconfigured);

      await pnpNotifier.continueFromUnconfigured();

      expect(pnpNotifier.state.status, PnpFlowStatus.adminNeedsInternetTroubleshooting);
      expect(pnpNotifier.state.error, isA<ExceptionNoInternetConnection>());
    });

    // --- Admin Error Flow ---
    test('Admin Error Flow: fetchDeviceInfo failure transitions to adminError', () async {
      final pnpNotifier = container.read(adminErrorPnpProvider.notifier);

      await pnpNotifier.startPnpFlow(null);

      expect(pnpNotifier.state.status, PnpFlowStatus.adminError);
      expect(pnpNotifier.state.error, isA<ExceptionFetchDeviceInfo>());
    });

    // --- Wizard Init Failed Flow ---
    test('Wizard Init Failed Flow: initializeWizard failure transitions to wizardInitFailed', () async {
      final pnpNotifier = container.read(wizardInitFailedPnpProvider.notifier);

      // Simulate initial state
      await pnpNotifier.startPnpFlow(null);
      expect(pnpNotifier.state.status, PnpFlowStatus.adminInternetConnected);

      await pnpNotifier.initializeWizard();

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardInitFailed);
      expect(pnpNotifier.state.error, isA<Exception>());
    });

    // --- Wizard Save Failed Flow ---
    test('Wizard Save Failed Flow: savePnpSettings failure transitions to wizardSaveFailed', () async {
      final pnpNotifier = container.read(wizardSaveFailedPnpProvider.notifier);

      // Simulate initial state and wizard initialization
      await pnpNotifier.startPnpFlow(null);
      await pnpNotifier.initializeWizard();
      expect(pnpNotifier.state.status, PnpFlowStatus.wizardConfiguring);

      await pnpNotifier.savePnpSettings();

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardSaveFailed);
      expect(pnpNotifier.state.error, isA<ExceptionSavingChanges>());
    });

    // --- Reconnect Failed Flow ---
    test('Reconnect Failed Flow: testPnpReconnect failure transitions to wizardNeedsReconnect', () async {
      final pnpNotifier = container.read(reconnectFailedPnpProvider.notifier);

      // Simulate initial state and wizard initialization
      await pnpNotifier.startPnpFlow(null);
      await pnpNotifier.initializeWizard();
      // Simulate being in wizardNeedsReconnect state
      pnpNotifier.state = pnpNotifier.state.copyWith(status: PnpFlowStatus.wizardNeedsReconnect);

      await pnpNotifier.testPnpReconnect();

      expect(pnpNotifier.state.status, PnpFlowStatus.wizardNeedsReconnect);
      expect(pnpNotifier.state.error, isA<ExceptionNeedToReconnect>());
    });

    // --- Internet Connected Flow (Direct to Wizard) ---
    test('Internet Connected Flow: startPnpFlow directly transitions to adminInternetConnected', () async {
      final pnpNotifier = container.read(internetConnectedPnpProvider.notifier);

      await pnpNotifier.startPnpFlow(null);

      expect(pnpNotifier.state.status, PnpFlowStatus.adminInternetConnected);
    });
  });
}