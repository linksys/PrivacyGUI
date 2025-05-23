import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';

class VPNService {
  final RouterRepository routerRepository;
  VPNService(this.routerRepository);

  Future<String?> getTunneledUser() {
    return routerRepository
        .send(JNAPAction.getTunneledUser, auth: true)
        .then((result) => result.output['ipAddress']);
  }

  Future<VPNGatewaySettings> getVPNGateway() {
    return routerRepository.send(JNAPAction.getVPNGateway, auth: true).then(
        (result) => VPNGatewaySettings.fromMap(result.output['settings']));
  }

  Future<VPNServiceSettings> getVPNService() {
    return routerRepository.send(JNAPAction.getVPNService, auth: true).then(
        (result) => VPNServiceSettings.fromMap(result.output['settings']));
  }

  Future<VPNUserCredentials> getVPNUser() {
    return routerRepository.send(JNAPAction.getVPNUser, auth: true).then(
        (result) => VPNUserCredentials.fromMap(result.output['credentials']));
  }

  Future<void> setTunneledUser(String ipAddress) {
    return routerRepository.send(JNAPAction.setTunneledUser,
        auth: true, data: {'ipAddress': ipAddress});
  }

  Future<void> setVPNGateway(VPNGatewaySettings settings) {
    return routerRepository.send(JNAPAction.setVPNGateway,
        auth: true, data: settings.toMap());
  }

  Future<void> setVPNService(VPNServiceSetSettings settings) {
    return routerRepository.send(JNAPAction.setVPNService,
        auth: true, data: settings.toMap());
  }

  Future<void> setVPNUser(VPNUserCredentials credentials) {
    return routerRepository.send(JNAPAction.setVPNUser,
        auth: true, data: credentials.toMap());
  }

  Future<VPNTestResult> testVPNConnection() {
    return routerRepository
        .send(JNAPAction.testVPNConnection, auth: true)
        .then((result) => VPNTestResult.fromMap(result.output));
  }

  Future<void> applyVPNSettings() {
    return routerRepository.send(JNAPAction.setVPNApply,
        auth: true, fetchRemote: true);
  }

  Future<void> fetch([bool force = false]) async {
    final commands = JNAPTransactionBuilder(auth: true, commands: [
      const MapEntry(JNAPAction.getVPNUser, {}),
      const MapEntry(JNAPAction.getVPNGateway, {}),
      const MapEntry(JNAPAction.getVPNService, {}),
      // const MapEntry(JNAPAction.getTunneledUser, {}),
    ]);
    await routerRepository.transaction(commands, fetchRemote: force);
  }

  Future<void> save(VPNSettings settings) async {
    final commands = JNAPTransactionBuilder(auth: true, commands: [
      if (settings.isEditingCredentials)
        MapEntry(
            JNAPAction.setVPNUser, settings.userCredentials?.toMap() ?? {}),
      if (settings.gatewaySettings?.gatewayAddress != null)
        MapEntry(
            JNAPAction.setVPNGateway, settings.gatewaySettings?.toMap() ?? {}),
      MapEntry(
          JNAPAction.setVPNService, settings.serviceSettings?.toMap() ?? {}),
      if (settings.tunneledUserIP != null)
        MapEntry(
            JNAPAction.setTunneledUser, {'ipAddress': settings.tunneledUserIP}),
    ]);
    await routerRepository.transaction(commands);
  }
}
