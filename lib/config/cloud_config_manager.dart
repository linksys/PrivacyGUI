
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:moab_poc/network/http/model/cloud_config.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/repository/config/config_repository.dart';
import 'package:moab_poc/util/logger.dart';


class CloudConfigManager {
  CloudConfig? _config;
  final List<CloudConfig> _allConfigs = [];
  final _configStreamController = StreamController<CloudConfig>();
  Stream<CloudConfig> get stream => _configStreamController.stream;
  CloudConfig? get currentConfig => _config;
  List<CloudConfig> get allConfigs => _allConfigs;
  final ConfigRepository _repository = MoabConfigRepository(MoabHttpClient());

  factory CloudConfigManager() {
    _singleton ??= CloudConfigManager._();
    return _singleton!;
  }

  CloudConfigManager._();

  static CloudConfigManager? _singleton;

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
    _configStreamController.add(config);
  }

  Future<List<CloudConfig>> fetchAllCloudConfigs() async {
    final configs = await _repository.fetchAllCloudConfig();
    _allConfigs..clear()..addAll(configs);
    return configs;
  }
}