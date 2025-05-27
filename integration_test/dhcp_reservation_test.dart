import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'actions/base_actions.dart';
import 'config/integration_test_config.dart';

void main() {
  integrationDriver();
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dependencySetup();
    initBetterActions();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    BuildConfig.load();
  });

  Future<TestDHCPReservationActions> enterDHCPReservationPage(WidgetTester tester) async {
    await tester.pumpFrames(app(), const Duration(seconds: 3));
    final topbarActions = TestTopbarActions(tester);
    await topbarActions.tapMenuButton();
    final menuActions = TestMenuActions(tester);
    await menuActions.enterAdvancedSettingsPage();
    final advancedSettingsActions = TestAdvancedSettingsActions(tester);
    await advancedSettingsActions.enterLocalNetworkSettingsPage();
    final localNetworkSettingsActions = TestLocalNetworkSettingsActions(tester);
    await localNetworkSettingsActions.tapDHCPServerTab();
    final dhcpReservationActions = TestDHCPReservationActions(tester);
    await dhcpReservationActions.tapDHCPReservationEnterance();
    return dhcpReservationActions;
  }

  group('DHCP Reservation - Log in', () {
    testWidgets('DHCP Reservation - Log in', (tester) async {
      await tester.pumpFrames(app(), const Duration(seconds: 3));
      final login = TestLocalLoginActions(tester);
      await login.inputPassword(IntegrationTestConfig.password);
      await login.tapLoginButton();
    });
  });

  group('DHCP Reservation - CRUD', () {
    testWidgets('Add, edit, and save DHCP reservation', (tester) async {
      final actions = await enterDHCPReservationPage(tester);

      // Add new reservation
      await actions.tapAddReservationButton();
      await actions.inputMacAddress('AA:BB:CC:DD:EE:01');
      await actions.inputIPAddress('192.168.1.21');
      await actions.inputDeviceName('TestDevice1');
      await actions.tapAlertSaveButton();
      await actions.verifyReservationInList('TestDevice1', '192.168.1.21', 'AA:BB:CC:DD:EE:01');

      // Edit reservation
      await actions.tapEditReservation('TestDevice1');
      await actions.inputDeviceName('TestDevice1Edit');
      await actions.tapAlertUpdateButton();
      await actions.verifyReservationInList('TestDevice1Edit', '192.168.1.21', 'AA:BB:CC:DD:EE:01');

      // Save and check again
      await actions.tapSaveButton();
      await actions.tapBackButton();
      await actions.tapDHCPReservationEnterance();
      await actions.verifyReservationInList('TestDevice1Edit', '192.168.1.21', 'AA:BB:CC:DD:EE:01');
      await actions.verifyHasOneReservation();
      await actions.tapReservation('TestDevice1Edit');
      await actions.verifyNoReservation();
    });
  });

  group('DHCP Reservation - Validation', () {
    testWidgets('Invalid MAC and IP address', (tester) async {
      final actions = await enterDHCPReservationPage(tester);

      await actions.tapAddReservationButton();
      await actions.verifyMacAddressError();
      await actions.verifyIPAddressError();
    });
  });
} 