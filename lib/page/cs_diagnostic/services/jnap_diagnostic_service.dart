import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_auth_provider.dart';

class JnapDiagnosticService {
  final String _authHeader;
  static const _baseUrl = 'http://192.168.1.1/JNAP/';
  static const _timeout = Duration(seconds: 15);

  JnapDiagnosticService(this._authHeader);

  /// Calls a JNAP action and returns the unwrapped 'output' map.
  /// Throws if result is not 'OK'.
  Future<Map<String, dynamic>> _call(String action, {bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-JNAP-Action': 'http://linksys.com/jnap/$action',
    };
    if (auth) {
      headers['X-JNAP-Authorization'] = _authHeader;
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: '{}',
    ).timeout(_timeout);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['result'] as String?;
    if (result != 'OK') {
      throw Exception('JNAP $action failed: $result');
    }
    return (body['output'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> getDeviceInfo() => _call('core/GetDeviceInfo', auth: false);
  Future<Map<String, dynamic>> getNodesWirelessConnections() =>
      _call('nodes/networkconnections/GetNodesWirelessNetworkConnections');
  Future<Map<String, dynamic>> getNetworkConnections() =>
      _call('networkconnections/GetNetworkConnections');
  Future<Map<String, dynamic>> getWANStatus() => _call('router/GetWANStatus', auth: false);
  Future<Map<String, dynamic>> getDHCPClientLeases() => _call('router/GetDHCPClientLeases');
  Future<Map<String, dynamic>> getDevices() => _call('devicelist/GetDevices3');
  Future<Map<String, dynamic>> getSystemStats() => _call('diagnostics/GetSystemStats');
  Future<Map<String, dynamic>> getRadioInfo() => _call('wirelessap/GetRadioInfo3');
  Future<Map<String, dynamic>> getGuestNetworkSettings() => _call('guestnetwork/GetGuestNetworkSettings');
  Future<Map<String, dynamic>> getFirmwareUpdateStatus() => _call('firmwareupdate/GetFirmwareUpdateStatus');
  Future<Map<String, dynamic>> getBackhaulInfo() => _call('nodes/diagnostics/GetBackhaulInfo');
  Future<Map<String, dynamic>> getMACFilterSettings() => _call('macfilter/GetMACFilterSettings');
  Future<Map<String, dynamic>> getNetworkSecuritySettings() => _call('networksecurity/GetNetworkSecuritySettings');
  Future<Map<String, dynamic>> getParentalControlSettings() => _call('parentalcontrol/GetParentalControlSettings');
  Future<Map<String, dynamic>> getWirelessSchedulerSettings() => _call('wirelessscheduler/GetWirelessSchedulerSettings');
  Future<Map<String, dynamic>> getSelectedChannels() => _call('nodes/setup/GetSelectedChannels');
  Future<Map<String, dynamic>> getEthernetPortConnections() => _call('router/GetEthernetPortConnections');
}

final jnapDiagnosticServiceProvider = Provider<JnapDiagnosticService>((ref) {
  final authState = ref.watch(diagnosticAuthProvider);
  return JnapDiagnosticService(authState.authHeader);
});
