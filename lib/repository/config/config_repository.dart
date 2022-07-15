
import 'dart:convert';

import 'package:moab_poc/network/http/extension_requests/extension_requests.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/network/http/model/cloud_app.dart';
import 'package:moab_poc/network/http/model/cloud_config.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:moab_poc/util/logger.dart';

import '../../network/http/constant.dart';

abstract class ConfigRepository {

  ConfigRepository(MoabHttpClient client): _client = client;

  final MoabHttpClient _client;

  Future<CloudConfig> fetchCloudConfig();
  Future<List<CloudConfig>> fetchAllCloudConfig();
  Future<CloudApp> createApps(DeviceInfo deviceInfo);
}

class MoabConfigRepository extends ConfigRepository {

  MoabConfigRepository(super.client);


  @override
  Future<List<CloudConfig>> fetchAllCloudConfig() async {
    return await _client.fetchCloudConfig().then((response) {
      final statusCode = response.statusCode;
      final body = response.body;
      if (statusCode != 200) {
        throw CloudException('UNABLE_FETCH_ALL_CLOUD_CONFIG', "Not able to fetch ALL ${cloudEnvTarget.name} cloud configs");
      }
      try {
        final jsonArray = json.decode(body) as List<dynamic>;
        return List.from(jsonArray.map((e) => CloudConfig.fromJson(e)));
      } catch (e) {
        logger.e('fetchCloudConfig error', e);
        throw CloudException('JSON_ERROR', "Parsing cloud config error, $body");
      }
    });
  }

  @override
  Future<CloudConfig> fetchCloudConfig() async {
    return await _client.fetchAllCloudConfig().then((response) {
      final statusCode = response.statusCode;
      final body = response.body;
      if (statusCode != 200) {
        throw CloudException('UNABLE_FETCH_CLOUD_CONFIG', "Not able to fetch ${cloudEnvTarget.name} cloud config");
      }
      try {
        final jsonArray = json.decode(body) as List<dynamic>;
        return CloudConfig.fromJson(jsonArray.first);
      } catch (e) {
        logger.e('fetchCloudConfig error', e);
        throw CloudException('JSON_ERROR', "Parsing cloud config error, $body");
      }
    });

  }

  @override
  Future<CloudApp> createApps(DeviceInfo deviceInfo) async {
    // TODO: implement createApps
    throw UnimplementedError();
  }
}