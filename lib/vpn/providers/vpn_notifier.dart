import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/vpn/service/vpn_service_jnap.dart';
import '../models/vpn_models.dart';
import '../service/vpn_service.dart';
import 'vpn_state.dart';

class VPNNotifier extends Notifier<VPNState> {
  @override
  VPNState build() {
    return const VPNState.init();
  }

  Future<VPNState> fetch([bool force = false]) async {
    final service = ref.read(vpnServiceProvider);
    try {
      await service.fetch(force);
      // Load all VPN data
      final userCredentials = await service.getVPNUser();
      final gatewaySettings = await service.getVPNGateway();
      final serviceSettings = await service.getVPNService();
      final tunneledUserIP = await service.getTunneledUser();

      state = state.copyWith(
        settings: state.settings.copyWith(
          userCredentials: userCredentials,
          gatewaySettings: gatewaySettings,
          serviceSettings: VPNServiceSetSettings(
              enabled: serviceSettings.enabled,
              autoConnect: serviceSettings.autoConnect),
          tunneledUserIP: tunneledUserIP,
        ),
        status: state.status.copyWith(
          statistics: serviceSettings.statistics,
          tunnelStatus: serviceSettings.tunnelStatus,
        ),
      );
    } catch (e) {
      rethrow;
    }
    return state;
  }

  Future<VPNState> save() async {
    final service = ref.read(vpnServiceProvider);
    await service.save(state.settings);
    return fetch(true);
  }

  // State updates
  // User Management
  Future<void> setVPNUser(VPNUserCredentials credentials) async {
    state = state.copyWith(
      settings: state.settings.copyWith(
        userCredentials: credentials,
      ),
    );
  }

  // Gateway Settings
  Future<void> setVPNGateway(VPNGatewaySettings settings) async {
    state = state.copyWith(
      settings: state.settings.copyWith(
        gatewaySettings: settings,
      ),
    );
  }

  // Service Settings
  Future<void> setVPNService(VPNServiceSetSettings settings) async {
    state = state.copyWith(
      settings: state.settings.copyWith(
        serviceSettings: settings,
      ),
    );
  }

  // Tunneled User Management
  Future<void> setTunneledUser(String ipAddress) async {
    state = state.copyWith(
      settings: state.settings.copyWith(
        tunneledUserIP: ipAddress,
      ),
    );
  }

  // Connection Testing
  Future<VPNState> testVPNConnection() async {
    final repository = ref.read(vpnServiceProvider);

    try {
      final result = await repository.testVPNConnection();
      state = state.copyWith(
        status: state.status.copyWith(
          testResult: result,
        ),
      );
      return state;
    } catch (e) {
      rethrow;
    }
  }
}

final vpnServiceProvider = Provider<VPNService>((ref) {
  return getIt.get<ServiceHelper>().isSupportVPN() ? VPNServiceJNAP(ref.read(routerRepositoryProvider)) : VPNService();
});

final vpnProvider = NotifierProvider<VPNNotifier, VPNState>(VPNNotifier.new);
