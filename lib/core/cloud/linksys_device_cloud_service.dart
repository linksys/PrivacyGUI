import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/cloud2_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/guidans_remote_assistance_service.dart';
import 'package:privacy_gui/core/cloud/model/guidan_remote_assistance.dart';
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
    final cacheData = checkFromCache(kGeoLocation, 36000000);
    if (cacheData != null) {
      logger.d('Get $kGeoLocation from cache: $cacheData');
      return cacheData;
    }
    final linksysToken = await fetchDeviceToken(
        serialNumber: master.unit.serialNumber ?? '',
        macAddress: master.getMacAddress(),
        deviceUUID: master.deviceID);
    return _httpClient
        .geolocation(
            linksysToken: linksysToken,
            serialNumber: master.unit.serialNumber ?? '')
        .then((response) {
      final result = jsonDecode(utf8.decode(response.bodyBytes));
      handleDataCache(kGeoLocation, result, master.unit.serialNumber);
      return result;
    });
  }

  // Remote assistance
  Future<String> createPin({
    required LinksysDevice master,
    required String sessionId,
  }) async {
    final linksysToken = await fetchDeviceToken(
        serialNumber: master.unit.serialNumber ?? '',
        macAddress: master.getMacAddress(),
        deviceUUID: master.deviceID);
    return _httpClient
        .createPin(
            token: linksysToken, serialNumber: master.unit.serialNumber ?? '')
        .then((response) => jsonDecode(response.body)['pin']);
  }

  // Get SessionInfo
  Future<GRASessionInfo> getSessionInfo({
    required LinksysDevice master,
    required String sessionId,
    String? serialNumber,
  }) async {
    final linksysToken = await fetchDeviceToken(
        serialNumber: master.unit.serialNumber ?? '',
        macAddress: master.getMacAddress(),
        deviceUUID: master.deviceID);
    return _httpClient
        .getSessionInfo(
            token: linksysToken,
            sessionId: sessionId,
            serialNumber: master.unit.serialNumber ?? '')
        .then((response) => GRASessionInfo.fromMap(jsonDecode(response.body)));
  }

  // Get Sessions
  Future<List<GRASessionInfo>> getSessions({
    required LinksysDevice master,
  }) async {
    final linksysToken = await fetchDeviceToken(
        serialNumber: master.unit.serialNumber ?? '',
        macAddress: master.getMacAddress(),
        deviceUUID: master.deviceID);
    return _httpClient
        .getSessions(
            token: linksysToken, serialNumber: master.unit.serialNumber ?? '')
        .then((response) => List.from((jsonDecode(response.body)['content']))
            .map((e) => GRASessionInfo.fromMap(e))
            .toList());
  }

  // Fetch device token from cloud via UUID
  Future<String> fetchDeviceToken({
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    String linksysToken = await _loadToken() ??
        await _fetchToken(
          serialNumber: serialNumber,
          deviceUUID: deviceUUID,
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
    required String macAddress,
    required String deviceUUID,
  }) async {
    final linksysToken = await _httpClient
        .getDeviceToken(
          serialNumber: serialNumber,
          macAddress: macAddress,
          deviceUUID: deviceUUID,
        )
        .then(
          (response) => jsonDecode(response.body)['linksysToken'],
        )
        .onError((error, stackTrace) {
      throw error!;
    });
    return linksysToken;
  }

  Map<String, dynamic>? checkFromCache(String action,
      [int? expirationOverride]) {
    final cache = ProviderContainer().read(linksysCacheManagerProvider);
    final isValidData = cache.checkCacheDataValid(action, expirationOverride);
    return isValidData ? cache.data[action]["data"] : null;
  }

  handleDataCache(
    String action,
    Map<String, dynamic> data,
    String? serialNumber,
  ) {
    final cache = ProviderContainer().read(linksysCacheManagerProvider);
    cache.handleJNAPCached(data, action, serialNumber);
  }
}
