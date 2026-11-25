// The ServiceHelper gates and the services each one checks, for the #1923
// tests. Every isServiceSupport gate stays (#1923): jnap_service_supported_test.dart
// fails to compile when one goes, and fails when one is added and not listed.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';

typedef Gate = ({
  bool Function(List<String> services) isOpen,
  Set<JNAPService> services,
});

ServiceHelper get _helper => ServiceHelper();

/// Every gate of ServiceHelper, keyed by its name, with the services it
/// opens on.
final serviceHelperGates = <String, Gate>{
  'isSupportAutoIPoE': (
    isOpen: (s) => _helper.isSupportAutoIPoE(s),
    services: {JNAPService.autoIPoE},
  ),
  'isSupportVPN': (
    isOpen: (s) => _helper.isSupportVPN(s),
    services: {JNAPService.vpn},
  ),
  'isSupportSetup': (
    isOpen: (s) => _helper.isSupportSetup(s),
    services: {JNAPService.setup},
  ),
  'isSupportGuestNetwork': (
    isOpen: (s) => _helper.isSupportGuestNetwork(s),
    services: {JNAPService.guestNetwork},
  ),
  'isSupportLedMode': (
    isOpen: (s) => _helper.isSupportLedMode(s),
    services: {JNAPService.routerLEDs4},
  ),
  'isSupportNodeFirmwareUpdate': (
    isOpen: (s) => _helper.isSupportNodeFirmwareUpdate(s),
    services: {JNAPService.nodesFirmwareUpdate},
  ),
  'isSupportHealthCheck': (
    isOpen: (s) => _helper.isSupportHealthCheck(s),
    services: {JNAPService.healthCheckManager},
  ),
  'isSupportHealthCheckManager2': (
    isOpen: (s) => _helper.isSupportHealthCheckManager2(s),
    services: {JNAPService.healthCheckManager2},
  ),
  'isSupportProduct': (
    isOpen: (s) => _helper.isSupportProduct(s),
    services: {JNAPService.product},
  ),
  'isSupportLedBlinking': (
    isOpen: (s) => _helper.isSupportLedBlinking(s),
    services: {JNAPService.setup9},
  ),
  'isSupportAutoOnboarding': (
    isOpen: (s) => _helper.isSupportAutoOnboarding(s),
    services: {JNAPService.autoOnboarding},
  ),
  'isSupportPnP': (
    isOpen: (s) => _helper.isSupportPnP(s),
    services: {JNAPService.setup11},
  ),
  'isSupportTopologyOptimization': (
    isOpen: (s) => _helper.isSupportTopologyOptimization(s),
    services: {JNAPService.nodesTopologyOptimization2},
  ),
  'isSupportMLO': (
    isOpen: (s) => _helper.isSupportMLO(s),
    services: {JNAPService.mlo},
  ),
  'isSupportIPTv': (
    isOpen: (s) => _helper.isSupportIPTv(s),
    services: {JNAPService.iptv},
  ),
  'isSupportDFS': (
    isOpen: (s) => _helper.isSupportDFS(s),
    services: {JNAPService.dfs},
  ),
  'isSupportAirtimeFairness': (
    isOpen: (s) => _helper.isSupportAirtimeFairness(s),
    services: {JNAPService.airtimeFairness},
  ),
  'isSupportAdminPasswordAuthStatus': (
    isOpen: (s) => _helper.isSupportAdminPasswordAuthStatus(s),
    services: {JNAPService.core7},
  ),
  'isSupportChildReboot': (
    isOpen: (s) => _helper.isSupportChildReboot(s),
    services: {JNAPService.core8},
  ),
  'isSupportChildFactoryReset': (
    isOpen: (s) => _helper.isSupportChildFactoryReset(s),
    services: {JNAPService.core9},
  ),
  'isSupportWANExternal': (
    isOpen: (s) => _helper.isSupportWANExternal(s),
    services: {JNAPService.router13},
  ),
  'isSupportClientDeauth': (
    isOpen: (s) => _helper.isSupportClientDeauth(s),
    services: {JNAPService.wirelessAP5},
  ),
  'isSupportGetSTABSSID': (
    isOpen: (s) => _helper.isSupportGetSTABSSID(s),
    services: {JNAPService.macFilter2},
  ),
  'isSupportNodesNetworkConnections': (
    isOpen: (s) => _helper.isSupportNodesNetworkConnections(s),
    services: {
      JNAPService.nodesNetworkConnections,
      JNAPService.nodesNetworkConnections2,
    },
  ),
};

/// Gives the test file a temp directory of its own.
///
/// isServiceSupport reads the cache manager before it looks at the services
/// it is given, and the cache manager reaches for the temp directory. Other
/// suites write their cache file into the shared system temp directory, so
/// this one gets its own. #1923's P2 (one holder of the router's services)
/// makes this unnecessary.
void stubTempDirectory() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('service_helper_');
  tearDownAll(() => dir.deleteSync(recursive: true));
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => dir.path,
  );
}
