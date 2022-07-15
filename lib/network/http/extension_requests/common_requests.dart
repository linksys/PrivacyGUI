import 'dart:convert';

import 'package:http/http.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import '../constant.dart';
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
    return this.post(Uri.parse(url), headers: header, body: jsonEncode(deviceInfo.toJson()));
  }

  Future<Response> getMaskedCommunicationMethods(String username) async {
    final url = combineUrl(endpointGetMaskedCommunicationMethods, args: {varUsername: username});
    final header = defaultHeader;
    return this.get(Uri.parse(url), headers: header);
  }
}
