import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:linksys_app/core/http/linksys_http_client.dart';

import '../../../constants/_constants.dart';

extension SmartDeviceService on LinksysHttpClient {
  Future<Response> registerSmartDevice(
    String deviceToken, {
    String? appType,
  }) async {
    final endpoint = combineUrl(kSmartDeviceRegisterEndpoint);
    final header = defaultHeader;
    final body = {
      'smartDevice': {
        'deviceToken': deviceToken,
        'tokenType': Platform.isIOS ? 'APNS' : 'GCM',
        'appName': 'FLUTTER',
        'appType': appType,
        'buildType': kReleaseMode ? 'RELEASE' : 'DEBUG'
      }..removeWhere((key, value) => value == null)
    };
    return this
        .post(Uri.parse(endpoint), headers: header, body: jsonEncode(body));
  }

  Future<Response> verifySmartDevice(String verificationToken) {
    final endpoint = combineUrl(
      kSmartDeviceVerificationEndpoint,
      args: {
        kVarToken: verificationToken,
      },
    );
    final header = defaultHeader;
    final body = {
      'verification': {'status': 'ACCEPTED'}
    };
    return this
        .put(Uri.parse(endpoint), headers: header, body: jsonEncode(body));
  }
}
