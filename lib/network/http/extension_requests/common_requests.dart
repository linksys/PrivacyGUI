import 'dart:convert';

import 'package:http/http.dart';
import '../../../constants/constants.dart';
import '../http_client.dart';
import '../model/cloud_app.dart';

extension MoabCommonRequests on MoabHttpClient {
  Future<Response> fetchCloudConfig() async {
    final url = cloudConfigUrl;
    return this.get(Uri.parse(url));
  }

  Future<Response> fetchAllCloudConfig() async {
    final url = allCloudConfigUrl;
    return this.get(Uri.parse(url));
  }

  Future<Response> createApp(DeviceInfo deviceInfo) async {
    final url = combineUrl(endpointCreateApps);
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(deviceInfo.toJson()));
  }

  Future<Response> getMaskedCommunicationMethods(String username) async {
    final url = combineUrl(endpointGetMaskedCommunicationMethods,
        args: {varUsername: Uri.encodeQueryComponent(username)});
    final header = defaultHeader;
    return this.get(Uri.parse(url), headers: header);
  }
}
