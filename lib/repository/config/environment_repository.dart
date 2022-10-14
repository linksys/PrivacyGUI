import 'dart:convert';

import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/network/http/extension_requests/extension_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_app.dart';
import 'package:linksys_moab/network/http/model/cloud_config.dart';
import 'package:linksys_moab/network/http/model/cloud_smart_device.dart';

abstract class EnvironmentRepository {
  EnvironmentRepository(MoabHttpClient client) : _client = client;

  final MoabHttpClient _client;

  Future<CloudConfig> fetchCloudConfig();

  Future<List<CloudConfig>> fetchAllCloudConfig();

  Future<CloudApp> createApps(DeviceInfo deviceInfo);

  Future<CloudApp> getApps();

  Future<void> registerSmartDevice(CloudSmartDevice smartDevice);

  Future<void> acceptSmartDevice(String token);

  Future<bool> downloadResources(Uri url, Uri savedPathUri);
}

class MoabEnvironmentRepository extends EnvironmentRepository {
  MoabEnvironmentRepository(super.client);

  @override
  Future<List<CloudConfig>> fetchAllCloudConfig() async {
    return await _client.fetchAllCloudConfig().then((response) {
      final jsonArray = json.decode(response.body) as List<dynamic>;
      return List.from(jsonArray.map((e) => CloudConfig.fromJson(e)));
    });
  }

  @override
  Future<CloudConfig> fetchCloudConfig() async {
    return await _client.fetchCloudConfig().then((response) {
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

  @override
  Future<CloudApp> getApps() async {
    return await CloudEnvironmentManager()
        .loadCloudApp()
        .then((cloudApp) => _client.getApp(cloudApp.id, cloudApp.appSecret!))
        .then((response) {
      final jsonObj = json.decode(response.body);
      try {
        return CloudSmartDeviceApp.fromJson(jsonObj);
      } catch (e) {
        // Not a smart device app
        return CloudApp.fromJson(jsonObj);
      }
    });
  }

  @override
  Future<void> registerSmartDevice(CloudSmartDevice smartDevice) async {
    return await CloudEnvironmentManager()
        .loadCloudApp()
        .then(
            (cloudApp) => _client.registerSmartDevice(cloudApp.id, cloudApp.appSecret!, smartDevice));
  }

  @override
  Future<void> acceptSmartDevice(String token) async {
    return await CloudEnvironmentManager()
        .loadCloudApp()
        .then(
            (cloudApp) => _client.acceptSmartDevice(cloudApp.id, cloudApp.appSecret!, token));
  }

  @override
  Future<bool> downloadResources(Uri url, Uri savedPathUri) async {
    return await _client.download(url, savedPathUri);
  }
}
