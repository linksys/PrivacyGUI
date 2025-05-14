import 'dart:async';
import 'package:privacy_gui/vpn/providers/vpn_state.dart';

import '../models/vpn_models.dart';
import '../data/mock_vpn_data.dart';

class VPNService {
  // Mock data
  VPNUserCredentials? _userCredentials;
  VPNGatewaySettings? _gatewaySettings;
  VPNServiceSettings? _serviceSettings;
  String? _tunneledUserIP;

  // Mock initial data
  VPNService() {
    fetch();
  }

  // Fetch
  Future<void> fetch([bool force = false]) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _userCredentials = VPNUserCredentials.fromMap(
        mockVPNData['userCredentials'] as Map<String, dynamic>);
    _gatewaySettings = VPNGatewaySettings.fromMap(
        mockVPNData['gatewaySettings'] as Map<String, dynamic>);
    _serviceSettings = VPNServiceSettings.fromMap(
        mockVPNData['serviceSettings'] as Map<String, dynamic>);
    _tunneledUserIP = mockVPNData['tunneledUserIP'] as String;
  }

  // Save
  Future<void> save(VPNSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    mockVPNData['userCredentials'] = _userCredentials?.toMap();
    mockVPNData['gatewaySettings'] = _gatewaySettings?.toMap();
    mockVPNData['serviceSettings'] = _serviceSettings?.toMap();
    mockVPNData['tunneledUserIP'] = _tunneledUserIP;
  }

  // User Management
  Future<void> setVPNUser(VPNUserCredentials credentials) async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    _userCredentials = credentials;
  }

  Future<VPNUserCredentials> getVPNUser() async {
    if (_userCredentials == null) {
      throw Exception('No VPN user credentials found');
    }
    return VPNUserCredentials(
      username: _userCredentials!.username,
      authMode: _userCredentials!.authMode,
    );
  }

  // Gateway Settings
  Future<void> setVPNGateway(VPNGatewaySettings settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _gatewaySettings = settings;
  }

  Future<VPNGatewaySettings> getVPNGateway() async {
    if (_gatewaySettings == null) {
      throw Exception('No VPN gateway settings found');
    }
    return _gatewaySettings!;
  }

  // Service Settings
  Future<void> setVPNService(VPNServiceSetSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _serviceSettings = _serviceSettings?.copyWith(
      enabled: settings.enabled,
      autoConnect: settings.autoConnect,
    );
  }

  Future<VPNServiceSettings> getVPNService() async {
    if (_serviceSettings == null) {
      throw Exception('No VPN service settings found');
    }
    return _serviceSettings!;
  }

  // Connection Testing
  Future<VPNTestResult> testVPNConnection() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return VPNTestResult(
      success: true,
      statusMessage: 'IPsec SA established',
      latency: 42,
    );
  }

  // Tunneled User Management
  Future<String?> getTunneledUser() async {
    return _tunneledUserIP;
  }

  Future<void> setTunneledUser(String ipAddress) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tunneledUserIP = ipAddress;
  }
}
