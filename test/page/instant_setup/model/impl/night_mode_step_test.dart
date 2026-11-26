// The night mode step, through the PnP setup page that lays it out, with the
// real PnpNotifier over a RouterBoundary: what PnP saves from the user's
// choice (#1921: what PnP saves from a step, not the keys of its map).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/di.dart';
import '../../../../common/router_boundary.dart';
import '../../data/pnp_router_data.dart';
import 'pnp_setup_harness.dart';

void main() {
  mockDependencyRegister();
  final services = getIt.get<ServiceHelper>();

  late RouterBoundary router;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    // A router with night mode and no guest WiFi, auto-parented: setup asks
    // for the WiFi, then night mode, which saves, then lists the nodes.
    when(services.isSupportGuestNetwork(any)).thenReturn(false);
    when(services.isSupportLedMode(any)).thenReturn(true);
    router = RouterBoundary()
      ..refuses(JNAPAction.getAutoMasterStatus)
      ..holds(JNAPAction.getDevices, {
        'revision': 1,
        'devices': [pnpDevice('router', nodeType: 'Master')],
      });
    holdPnpReads(router,
        autoConfiguration: pnpAutoConfiguration(method: 'AutoParent'));
  });

  /// Opens setup and moves past the WiFi step to the night mode step.
  Future<void> openNightModeStep(WidgetTester tester) async {
    await openPnpSetup(tester, router: router, pnp: ArrivedPnp());
    await tester.tap(nextButton('Next'));
    await tester.pumpAndSettle();
    expect(find.byType(AppSwitch), findsOneWidget);
  }

  testWidgets('turned on, saves night mode from 8 pm to 8 am', (tester) async {
    await openNightModeStep(tester);

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    await tapAndSave(tester, 'Next');

    expect(router.payloadsOf(JNAPAction.setLedNightModeSetting).single,
        {'Enable': true, 'StartingTime': 20, 'EndingTime': 8});
  });

  testWidgets('left off, saves no night mode', (tester) async {
    await openNightModeStep(tester);

    await tapAndSave(tester, 'Next');

    expect(router.transactions.last.map((command) => command.key),
        contains(JNAPAction.setFirmwareUpdateSettings));
    expect(router.actions, isNot(contains(JNAPAction.setLedNightModeSetting)));
  });
}
