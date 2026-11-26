// The Your Network step, through the PnP setup page that lays it out, with
// the real PnpNotifier over a RouterBoundary: once the save has landed, it
// lists what the router reports of the mesh.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
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
    // An auto-parented router with neither guest WiFi nor night mode: the WiFi
    // step saves, and Your Network follows.
    when(services.isSupportGuestNetwork(any)).thenReturn(false);
    when(services.isSupportLedMode(any)).thenReturn(false);
    router = RouterBoundary()
      ..refuses(JNAPAction.getAutoMasterStatus)
      ..holds(JNAPAction.getDevices, {
        'revision': 1,
        'devices': [
          pnpDevice('router', nodeType: 'Master', location: 'Living room'),
          pnpDevice('laptop', location: 'Study desk'),
          pnpDevice('node', nodeType: 'Slave', location: 'Office'),
        ],
      });
    holdPnpReads(router,
        autoConfiguration: pnpAutoConfiguration(method: 'AutoParent'));
  });

  testWidgets(
      'after the save, lists the router and its nodes by location, and '
      'leaves the clients out', (tester) async {
    await openPnpSetup(tester, router: router, pnp: ArrivedPnp());

    await tapAndSave(tester, 'Next');

    expect(router.actions, contains(JNAPAction.getDevices));
    expect(find.text('Living room'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    expect(find.text('Study desk'), findsNothing);
    expect(nextButton('Done'), findsOneWidget);
  });
}
