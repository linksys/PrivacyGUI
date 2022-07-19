import 'dart:convert';
import 'dart:io';

import 'package:moab_poc/network/http/model/cloud_config.dart';
import 'package:moab_poc/network/http/constant.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/repository/config/environment_repository.dart';
import 'package:test/test.dart';

void main() {
  group('test get dev cloud env config', () {
    test('get dev config', () async {
      MoabHttpClient _client = MoabHttpClient();
      print('Url: $cloudConfigUrl');
      final result = await _client.get(Uri.parse(cloudConfigUrl));
      print('Status code: ${result.statusCode}, body: ${result.body}');
      expect(result.statusCode, 200);
    });

    test('parse dev config, all field are required', () async {
      MoabHttpClient _client = MoabHttpClient();
      print('Url: $cloudConfigUrl');
      final result = await _client.get(Uri.parse(cloudConfigUrl));
      print('Status code: ${result.statusCode}, body: ${result.body}');
      final jsonResp = json.decode(result.body) as List<dynamic>;
      jsonResp.map((e) {
        final config = CloudConfig.fromJson(e);
        expect(config.region.isNotEmpty, true);
        expect(config.env.isNotEmpty, true);
        expect(config.cloudConfigBaseUrl.isNotEmpty, true);
        expect(config.apiBase.isNotEmpty, true);
        expect(config.transport.protocol.isNotEmpty, true);
        expect(config.transport.mqttBroker.isNotEmpty, true);
      });
    });
    test('get dev all env configs', () async {
      MoabHttpClient _client = MoabHttpClient();
      print('Url: $allCloudConfigUrl');
      final result = await _client.get(Uri.parse(allCloudConfigUrl));
      print('Status code: ${result.statusCode}, body: ${result.body}');
      expect(result.statusCode, 200);
    });

    test('parse dev config, all field are required', () async {
      MoabHttpClient _client = MoabHttpClient();
      print('Url: $allCloudConfigUrl');
      final result = await _client.get(Uri.parse(allCloudConfigUrl));
      print('Status code: ${result.statusCode}, body: ${result.body}');
      final jsonResp = json.decode(result.body) as List<dynamic>;
      jsonResp.map((e) {
        final config = CloudConfig.fromJson(e);
        expect(config.region.isNotEmpty, true);
        expect(config.env.isNotEmpty, true);
        expect(config.cloudConfigBaseUrl.isNotEmpty, true);
        expect(config.apiBase.isNotEmpty, true);
        expect(config.transport.protocol.isNotEmpty, true);
        expect(config.transport.mqttBroker.isNotEmpty, true);
      });
    });
  });

  group('test get cloud env config via repository', () {
    test('get env config', () async {
      EnvironmentRepository _repository = MoabEnvironmentRepository(MoabHttpClient());
      final config = await _repository.fetchCloudConfig();
      expect(config.region.isNotEmpty, true);
      expect(config.env.isNotEmpty, true);
      expect(config.cloudConfigBaseUrl.isNotEmpty, true);
      expect(config.apiBase.isNotEmpty, true);
      expect(config.transport.protocol.isNotEmpty, true);
      expect(config.transport.mqttBroker.isNotEmpty, true);
    });
    test('get all env configs', () async {
      EnvironmentRepository _repository = MoabEnvironmentRepository(MoabHttpClient());
      final configList = await _repository.fetchAllCloudConfig();
      configList.map((config) {
        expect(config.region.isNotEmpty, true);
        expect(config.env.isNotEmpty, true);
        expect(config.cloudConfigBaseUrl.isNotEmpty, true);
        expect(config.apiBase.isNotEmpty, true);
        expect(config.transport.protocol.isNotEmpty, true);
        expect(config.transport.mqttBroker.isNotEmpty, true);
      });
    });
  });
}
