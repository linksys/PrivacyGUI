import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/vpn/models/vpn_models.dart';
import 'package:privacy_gui/vpn/providers/vpn_state.dart';
import 'package:privacy_gui/vpn/service/vpn_service.dart';

class VPNServiceJNAP implements VPNService {
  final RouterRepository routerRepository;
  VPNServiceJNAP(this.routerRepository);

  @override
  Future<String?> getTunneledUser() {
    return routerRepository
        .send(JNAPAction.getTunneledUser, auth: true)
        .then((result) => result.output['ipAddress']);
  }

  @override
  Future<VPNGatewaySettings> getVPNGateway() {
    return routerRepository
        .send(JNAPAction.getVPNGateway, auth: true)
        .then((result) => VPNGatewaySettings.fromMap(result.output));
  }

  @override
  Future<VPNServiceSettings> getVPNService() {
    return routerRepository
        .send(JNAPAction.getVPNService, auth: true)
        .then((result) => VPNServiceSettings.fromMap(result.output));
  }

  @override
  Future<VPNUserCredentials> getVPNUser() {
    return routerRepository
        .send(JNAPAction.getVPNUser, auth: true)
        .then((result) => VPNUserCredentials.fromMap(result.output));
  }

  @override
  Future<void> setTunneledUser(String ipAddress) {
    return routerRepository.send(JNAPAction.setTunneledUser,
        auth: true, data: {'ipAddress': ipAddress});
  }

  @override
  Future<void> setVPNGateway(VPNGatewaySettings settings) {
    return routerRepository.send(JNAPAction.setVPNGateway,
        auth: true, data: settings.toMap());
  }

  @override
  Future<void> setVPNService(VPNServiceSetSettings settings) {
    return routerRepository.send(JNAPAction.setVPNService,
        auth: true, data: settings.toMap());
  }

  @override
  Future<void> setVPNUser(VPNUserCredentials credentials) {
    return routerRepository.send(JNAPAction.setVPNUser,
        auth: true, data: credentials.toMap());
  }

  @override
  Future<VPNTestResult> testVPNConnection() {
    return routerRepository
        .send(JNAPAction.testVPNConnection, auth: true)
        .then((result) => VPNTestResult.fromMap(result.output));
  }

  @override
  Future<void> fetch([bool force = false]) async {
    final commands = JNAPTransactionBuilder(auth: true, commands: [
      const MapEntry(JNAPAction.getVPNUser, {}),
      const MapEntry(JNAPAction.getVPNGateway, {}),
      const MapEntry(JNAPAction.getVPNService, {}),
      const MapEntry(JNAPAction.getTunneledUser, {}),
    ]);
    await routerRepository.transaction(commands, fetchRemote: force);
  }

  @override
  Future<void> save(VPNSettings settings) async {
    final commands = JNAPTransactionBuilder(auth: true, commands: [
      MapEntry(JNAPAction.setVPNUser, settings.userCredentials?.toMap() ?? {}),
      MapEntry(
          JNAPAction.setVPNGateway, settings.gatewaySettings?.toMap() ?? {}),
      MapEntry(
          JNAPAction.setVPNService, settings.serviceSettings?.toMap() ?? {}),
      MapEntry(JNAPAction.setTunneledUser,
          {'ipAddress': settings.tunneledUserIP ?? ''}),
    ]);
    await routerRepository.transaction(commands);
  }
}
