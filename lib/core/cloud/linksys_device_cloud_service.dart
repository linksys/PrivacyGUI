import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/cloud2_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/device_service.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/ip_getter/web_get_local_ip.dart';

final deviceCloudServiceProvider = Provider((ref) => DeviceCloudService(
      httpClient: LinksysHttpClient(getHost: () {
        if (BuildConfig.forceCommandType == ForceCommand.local) {
          var localIP = getLocalIp(ref);
          localIP = localIP.startsWith('http') ? localIP : 'https://$localIP';
          return localIP;
        }
        final routerType =
            ref.read(connectivityProvider).connectivityInfo.routerType;
        if (routerType == RouterType.others) {
          return null;
        } else {
          var localIP = getLocalIp(ref);
          localIP = localIP.startsWith('http') ? localIP : 'https://$localIP';
          return localIP;
        }
      }),
    ));

class DeviceCloudService {
  final LinksysHttpClient _httpClient;

  DeviceCloudService({required LinksysHttpClient httpClient})
      : _httpClient = httpClient;

  // geolocation
  Future<Map<String, dynamic>> getGeolocation(LinksysDevice master) async {
    final linksysToken = await registerDevice(
        serialNumber: master.unit.serialNumber ?? '',
        modelNumber: master.modelNumber ?? '',
        macAddress: master.getMacAddress());
    return _httpClient
        .geolocation(
            linksysToken: linksysToken,
            serialNumber: master.unit.serialNumber ?? '')
        .then((response) => jsonDecode(response.body));
  }

  // device registation

  Future<String> registerDevice({
    required String serialNumber,
    required String modelNumber,
    required String macAddress,
  }) async {
    String linksysToken = await _loadToken() ??
        await _fetchToken(
          serialNumber: serialNumber,
          modelNumber: modelNumber,
          macAddress: macAddress,
        ).then((value) async {
          const storage = FlutterSecureStorage();
          await storage.write(key: pLinksysToken, value: value);
          await storage.write(
              key: pLinksysTokenTs,
              value: '${DateTime.now().millisecondsSinceEpoch}');
          return value;
        });

    return linksysToken;
  }

  Future<bool> _isLinksysTokenExpired() async {
    const storage = FlutterSecureStorage();
    final tokenTs =
        int.tryParse(await storage.read(key: pLinksysTokenTs) ?? '');
    if (tokenTs == null) {
      return true;
    }
    const tokenExpiration = 60 * 60 * 24 * 1000;
    return DateTime.now().millisecondsSinceEpoch - tokenTs > tokenExpiration;
  }

  Future<String?> _loadToken() async {
    final isExpired = await _isLinksysTokenExpired();
    const storage = FlutterSecureStorage();

    return isExpired ? null : await storage.read(key: pLinksysToken);
  }

  Future<String> _fetchToken({
    required String serialNumber,
    required String modelNumber,
    required String macAddress,
  }) async {
    final linksysToken = await _httpClient
        .registrations(
          serialNumber: serialNumber,
          modelNumber: modelNumber,
          macAddress: macAddress,
        )
        .then(
          (response) =>
              jsonDecode(response.body)['clientDevice']['linksysToken'],
        )
        .onError((error, stackTrace) {
      throw error!;
    });
    return linksysToken;
  }
}