import 'dart:convert';

import 'package:http/http.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

extension Cloud2Service on LinksysHttpClient {
  Future<Response> associateSmartDevice({
    required String linksysToken,
    required String serialNumber,
    required String fcmToken,
  }) {
    final endpoint = combineUrl(kSmartDeviceAssociate);
    Map<String, String> header = defaultHeader;

    header.addAll({
      kHeaderLinksysToken: linksysToken,
      kHeaderSerialNumber: serialNumber,
    });
    return this.post(Uri.parse(endpoint),
        headers: header, body: jsonEncode({'fcmToken': fcmToken}));
  }

  Future<Response> geolocation({
    required String linksysToken,
    required String serialNumber,
  }) {
    final endpoint = combineUrl(kGeoLocation);
    Map<String, String> header = defaultHeader;

    header.addAll({
      kHeaderLinksysToken: linksysToken,
      kHeaderSerialNumber: serialNumber,
      'cache-control': 'max-age=3600',
    });
    return this.get(
      Uri.parse(endpoint),
      headers: header,
    );
  }

  Future<Response> getDeviceToken({
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) {
    final endpoint = combineUrl(kDeviceToken);
    Map<String, String> header = defaultHeader;

    return this.get(
        Uri.parse(endpoint).replace(queryParameters: {
          'serialNumber': serialNumber,
          'macAddress': macAddress,
          'uuid': deviceUUID.toUpperCase(),
        }),
        headers: header);
  }
}
