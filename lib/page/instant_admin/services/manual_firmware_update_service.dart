// lib/page/instant_admin/services/manual_firmware_update_service.dart

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/utils.dart';

final manualFirmwareUpdateServiceProvider =
    Provider((ref) => ManualFirmwareUpdateService(ref));

final linksysHttpClientProvider = Provider((ref) => LinksysHttpClient());

class ManualFirmwareUpdateService {
  final Ref _ref;

  ManualFirmwareUpdateService(this._ref);

  Future<bool> manualFirmwareUpdate(String filename, List<int> bytes,
      String? localPassword, String localIp) async {
    final client = _ref.read(linksysHttpClientProvider)
      ..timeoutMs = 300000
      ..retries = 0;
    final localPwd = localPassword ?? '';
    final multiPart = MultipartFile.fromBytes(
      'upload',
      bytes,
      filename: filename,
      contentType: MediaType('application', 'octet-stream'),
    );
    final log = BenchMarkLogger(name: 'Manual FW update');
    log.start();
    return client.upload(Uri.parse('https://$localIp/jcgi/'), [
      multiPart,
    ], fields: {
      kJNAPAction: 'updatefirmware',
      kJNAPAuthorization: 'Basic ${Utils.stringBase64Encode('admin:$localPwd')}'
    }).then((response) {
      final result = jsonDecode(response.body)['result'];
      log.end();
      if (result == 'OK') {
        return true;
      }
      // error
      final error = response.headers['X-Jcgi-Result'];
      throw ManualFirmwareUpdateException(error);
    }).onError((error, stackTrace) {
      log.end();
      if (error is ErrorResponse && error.code == '500') {
        return true;
      }
      logger.e('[FIRMWARE]: Manual firmware update: Error: $error');
      throw ManualFirmwareUpdateException('UnknownError');
    });
  }
}

class ManualFirmwareUpdateException implements Exception {
  final String? result;
  ManualFirmwareUpdateException(this.result);
}
