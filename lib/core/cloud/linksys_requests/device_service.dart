import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:linksys_moab/core/http/linksys_http_client.dart';

import '../../../constants/_constants.dart';

extension DeviceService on LinksysHttpClient {
  Future<Response> getNetworks({required String token}) {
    final endpoint = combineUrl(kAccountNetworksEndpoint);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.get(Uri.parse(endpoint), headers: header);
  }

  Future<Response> deleteNetwork(
      {required String token, required String networkId}) {
    final endpoint =
        combineUrl(kDeviceNetworksEndpoint, args: {kVarNetworkId: networkId});
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    return this.delete(Uri.parse(endpoint), headers: header);
  }

  Future<Response> updateNetwork(
      {required String token,
      required String networkId,
      required String friendlyName}) {
    final endpoint =
        combineUrl(kDeviceNetworksEndpoint, args: {kVarNetworkId: networkId});
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);

    final body = {
      'network': {'friendlyName': friendlyName}
    };
    return this
        .put(Uri.parse(endpoint), headers: header, body: jsonEncode(body));
  }
}
