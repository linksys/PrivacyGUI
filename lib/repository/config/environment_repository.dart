
import 'dart:convert';

import 'package:linksys_moab/network/http/extension_requests/extension_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_app.dart';
import 'package:linksys_moab/network/http/model/cloud_config.dart';


abstract class EnvironmentRepository {

  EnvironmentRepository(MoabHttpClient client): _client = client;

  final MoabHttpClient _client;

  Future<CloudConfig> fetchCloudConfig();
  Future<List<CloudConfig>> fetchAllCloudConfig();
  Future<CloudApp> createApps(DeviceInfo deviceInfo);
}

class MoabEnvironmentRepository extends EnvironmentRepository {

  MoabEnvironmentRepository(super.client);


  @override
  Future<List<CloudConfig>> fetchAllCloudConfig() async {
    return await _client.fetchCloudConfig().then((response) {
      final jsonArray = json.decode(response.body) as List<dynamic>;
      return List.from(jsonArray.map((e) => CloudConfig.fromJson(e)));
    });
  }

  @override
  Future<CloudConfig> fetchCloudConfig() async {
    return await _client.fetchAllCloudConfig().then((response) {
      final jsonArray = json.decode(response.body) as List<dynamic>;
      return CloudConfig.fromJson(jsonArray.first);
    });

  }

  @override
  Future<CloudApp> createApps(DeviceInfo deviceInfo) async {
    return await _client.createApp(deviceInfo).then((response) {
      return CloudApp.fromJson(json.decode(response.body));
    });
  }
}