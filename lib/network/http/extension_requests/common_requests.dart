import 'dart:convert';

import 'package:http/http.dart';
import 'package:linksys_moab/network/http/model/cloud_smart_device.dart';
import '../../../constants/_constants.dart';
import '../http_client.dart';
import '../model/cloud_app.dart';

extension MoabCommonRequests on MoabHttpClient {
  Future<Response> fetchCloudConfig() async {
    final url = cloudConfigUrl;
    return this.get(Uri.parse(url));
  }

  Future<Response> fetchAllCloudConfig(String configBaseUrl) async {
    final url = '$configBaseUrl/$allConfigFileName';
    return this.get(Uri.parse(url));
  }

  Future<Response> createApp(DeviceInfo deviceInfo) async {
    final url = await combineUrl(endpointCreateApps);
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(deviceInfo.toJson()));
  }

  Future<Response> getApp(String appId, String appSecret) async {
    final url = await combineUrl(endpointGetApps, args: {varAppId: appId});
    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});

    return this.get(Uri.parse(url), headers: header);
  }

  Future<Response> registerSmartDevice(
      String appId, String appSecret, CloudSmartDevice smartDevice) async {
    final url = await combineUrl(endpointPutSmartDevices, args: {varAppId: appId});
    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});
    return this.put(Uri.parse(url),
        headers: header, body: jsonEncode(smartDevice.toJson()));
  }

  Future<Response> acceptSmartDevice(
      String appId, String appSecret, String token) async {
    final url = await combineUrl(endpointPutAcceptSmartDevices, args: {varAppId: appId});
    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});

    return this.put(Uri.parse(url), headers: header, body: jsonEncode({'token': token}));
  }

  Future<Response> getMaskedCommunicationMethods(String username) async {
    final url = await combineUrl(endpointGetMaskedCommunicationMethods,
        args: {varUsername: Uri.encodeQueryComponent(username)});
    final header = defaultHeader;
    return this.get(Uri.parse(url), headers: header);
  }
}
