import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:linksys_moab/constants/build_config.dart';
import 'package:linksys_moab/constants/constants.dart';
import 'package:linksys_moab/network/http/model/cloud_app.dart';
import 'package:linksys_moab/network/http/model/cloud_config.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_smart_device.dart';
import 'package:linksys_moab/repository/config/environment_repository.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudEnvironmentManager {
  CloudConfig? _config;
  CloudApp? _app;
  final List<CloudConfig> _allConfigs = [];
  final _configStreamController = StreamController<CloudConfig>();

  Stream<CloudConfig> get stream => _configStreamController.stream;

  CloudConfig? get currentConfig => _config;

  List<CloudConfig> get allConfigs => _allConfigs;
  final EnvironmentRepository _repository =
      MoabEnvironmentRepository(MoabHttpClient());

  factory CloudEnvironmentManager() {
    _singleton ??= CloudEnvironmentManager._();
    return _singleton!;
  }

  CloudEnvironmentManager._();

  static CloudEnvironmentManager? _singleton;

  void update(CloudConfig config) {
    if (_config == config) return;
    _config = config;
    _configStreamController.add(config);
  }

  Future<void> fetchCloudConfig() async {
    final config = await _repository.fetchCloudConfig();
    logger.d('Cloud config fetched: $config');
    if (config == _config) {
      return;
    }
    _config = config;
    _configStreamController.add(config);
  }

  Future<List<CloudConfig>> fetchAllCloudConfigs() async {
    final configs = await _repository.fetchAllCloudConfig();
    _allConfigs
      ..clear()
      ..addAll(configs);
    return configs;
  }

  Future<void> createCloudApp() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final appKey = _getAppKey();
    logger.d('cloud app not exist! start create one');
    final app = await _repository.createApps(await Utils.fetchDeviceInfo());
    await pref.setString(appKey, jsonEncode(app.toJson()));
    // put secret alone with id as the key
    await pref.setString(app.id, app.appSecret!);
    _app = app;
  }

  Future<void> fetchCloudApp() async {
    final app = await _repository.getApps();
    SharedPreferences pref = await SharedPreferences.getInstance();
    final appKey = _getAppKey();
    if (!pref.containsKey(appKey)) {
      throw Exception("Cloud app doesn't exist!");
    }
    // update cloud app
    final appSecret = pref.getString(app.id);

    final appJson = app.toJson()..['appSecret'] = appSecret;
    pref.setString(appKey, jsonEncode(appJson));
    _app = _buildCloudApp(appJson);
  }

  Future<void> registerSmartDevice() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final deviceToken = pref.getString(moabPrefDeviceToken) ?? '';
    final pushPlatform = Platform.isIOS ? 'APNS' : 'GCM';
    CloudSmartDevice smartDevice =
        CloudSmartDevice(platform: pushPlatform, deviceToken: deviceToken);
    if (pushPlatform == 'APNS') {
      final packageInfo = await PackageInfo.fromPlatform();
      final appType = packageInfo.packageName.endsWith('ee')
          ? 'ENTERPRISE'
          : 'DISTRIBUTION';
      const smartDeviceType = kReleaseMode ? 'PRODUCTION' : 'SANDBOX';
      smartDevice = CloudSmartDevice(
          platform: pushPlatform,
          deviceToken: deviceToken,
          appType: appType,
          smartDeviceType: smartDeviceType);
    }
    await _repository.registerSmartDevice(smartDevice);
  }

  Future<void> acceptSmartDevice(String token) async {
    _repository.acceptSmartDevice(token).then((value) => fetchCloudApp());
  }

  Future<void> checkSmartDevice() async {

    final pref = await SharedPreferences.getInstance();
    if (pref.getString(moabPrefDeviceToken) == null) {
      return;
    }
    await fetchCloudApp();
    final app = _app;
    bool isRegister = false;
    if (app is CloudSmartDeviceApp) {
      logger.d('SmartDevice status: ${app.smartDevice.smartDeviceStatus}');
      isRegister = app.smartDevice.smartDeviceStatus == 'ACTIVE';
    }
    if (isRegister) return;

    await registerSmartDevice();
  }

  Future<CloudApp> loadCloudApp() async {
    logger.d('load cloud app');
    if (!await _isCloudAppExist()) {
      logger.d('can not find cloud app, create one');
      await createCloudApp();
    }
    logger.d('Cloud App loaded!');
    return _app!;
  }

  CloudApp getCloudApp() {
    if (_app == null) {
      // TODO throw a specific exception if there has no App object
      throw Exception();
    }
    return _app!;
  }

  void updateDeviceToken(String deviceToken) => SharedPreferences.getInstance()
      .then((pref) => pref.setString(moabPrefDeviceToken, deviceToken));

  String _getAppKey() => '${moabPrefAppKey}_${cloudEnvTarget.name}';

  Future<bool> _isCloudAppExist() async {
    if (_app?.appSecret != null) {
      return true;
    }
    logger.d('app not found in memory!');
    SharedPreferences pref = await SharedPreferences.getInstance();
    String key = _getAppKey();
    if (pref.containsKey(key)) {
      try {
        final appJson = jsonDecode(pref.getString(key)!);
        final appSecret = pref.getString(appJson['id']);
        if (appSecret == null) {
          return false;
        }
        _app = _buildCloudApp(appJson);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  CloudApp _buildCloudApp(Map<String, dynamic> json) {
    return json['smartDeviceStatus'] == null ? CloudApp.fromJson(json) : CloudSmartDeviceApp.fromJson(json);
  }
}
