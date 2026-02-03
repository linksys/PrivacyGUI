import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/di.dart';

final serviceHelper = getIt<ServiceHelper>();

class ServiceHelper {
  bool isSupportVPN([List<String>? services]) =>
      isServiceSupport(JNAPService.vpn, services);

  bool isSupportSetup([List<String>? services]) =>
      isServiceSupport(JNAPService.setup, services);

  bool isSupportGuestNetwork([List<String>? services]) =>
      isServiceSupport(JNAPService.guestNetwork, services);

  bool isSupportLedMode([List<String>? services]) =>
      isServiceSupport(JNAPService.routerLEDs4, services);

  bool isSupportNodeFirmwareUpdate([List<String>? services]) =>
      isServiceSupport(JNAPService.nodesFirmwareUpdate, services);

  bool isSupportHealthCheck([List<String>? services]) =>
      isServiceSupport(JNAPService.healthCheckManager, services);

  bool isSupportHealthCheckManager2([List<String>? services]) =>
      isServiceSupport(JNAPService.healthCheckManager2, services);

  bool isSupportProduct([List<String>? services]) =>
      isServiceSupport(JNAPService.product, services);

  bool isSupportLedBlinking([List<String>? services]) =>
      isServiceSupport(JNAPService.setup9, services);

  bool isSupportAutoOnboarding([List<String>? services]) =>
      isServiceSupport(JNAPService.autoOnboarding, services);

  bool isSupportPnP([List<String>? services]) =>
      isServiceSupport(JNAPService.setup11, services);

  bool isSupportTopologyOptimization([List<String>? services]) =>
      isServiceSupport(JNAPService.nodesTopologyOptimization2, services);

  bool isSupportMLO([List<String>? services]) =>
      isServiceSupport(JNAPService.mlo, services);

  bool isSupportIPTv([List<String>? services]) =>
      isServiceSupport(JNAPService.iptv, services);

  bool isSupportDFS([List<String>? services]) =>
      isServiceSupport(JNAPService.dfs, services);

  bool isSupportAirtimeFairness([List<String>? services]) =>
      isServiceSupport(JNAPService.airtimeFairness, services);

  bool isSupportAdminPasswordAuthStatus([List<String>? services]) =>
      isServiceSupport(JNAPService.core7, services);

  bool isSupportChildReboot([List<String>? services]) =>
      isServiceSupport(JNAPService.core8, services);

  bool isSupportChildFactoryReset([List<String>? services]) =>
      isServiceSupport(JNAPService.core9, services);

  bool isSupportWANExternal([List<String>? services]) =>
      isServiceSupport(JNAPService.router13);

  bool isSupportClientDeauth([List<String>? services]) =>
      isServiceSupport(JNAPService.wirelessAP5, services);

  bool isSupportGetSTABSSID([List<String>? services]) =>
      isServiceSupport(JNAPService.macFilter2, services);
  bool isSupportDualWAN([List<String>? services]) =>
      isServiceSupport(JNAPService.router15);
}
