
import 'dart:async';
import 'dart:convert';

import 'package:moab_poc/constants/constants.dart';
import 'package:moab_poc/network/http/model/cloud_app.dart';
import 'package:moab_poc/network/http/model/cloud_config.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/repository/config/environment_repository.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CloudEnvironmentManager {
  CloudConfig? _config;
  CloudApp? _app;
  final List<CloudConfig> _allConfigs = [];
  final _configStreamController = StreamController<CloudConfig>();
  Stream<CloudConfig> get stream => _configStreamController.stream;
  CloudConfig? get currentConfig => _config;
  List<CloudConfig> get allConfigs => _allConfigs;
  final EnvironmentRepository _repository = MoabEnvironmentRepository(MoabHttpClient());

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
    _allConfigs..clear()..addAll(configs);
    return configs;
  }

  Future<void> createCloudApp() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.containsKey(_getAppKey())) {
      return;
    }
    final app = await _repository.createApps(await Utils.fetchDeviceInfo());
    await pref.setString(_getAppKey(), jsonEncode(app.toJson()));
  }

  Future<CloudApp> loadCloudApp() async {
    logger.d('load cloud app');
    if (_app == null) {
      await createCloudApp();
    }
    SharedPreferences pref = await SharedPreferences.getInstance();
    final jsonStr = pref.getString(_getAppKey())!;
    _app = CloudApp.fromJson(json.decode(jsonStr));
    logger.d('Cloud App: $_app');
    return _app!;
  }

  CloudApp getCloudApp() {
    if (_app == null) {
      // TODO throw a specific exception if there has no App object
      throw Exception();
    }
    return _app!;
  }

  String _getAppKey() => '${moabPrefAppKey}_${cloudEnvTarget.name}';
}