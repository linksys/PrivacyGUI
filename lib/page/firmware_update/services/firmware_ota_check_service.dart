import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/http/linksys_http_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_info.dart';

final firmwareOtaCheckServiceProvider = Provider<FirmwareOtaCheckService>(
  (ref) => FirmwareOtaCheckService(),
);

class FirmwareOtaCheckException implements Exception {
  final String message;
  FirmwareOtaCheckException(this.message);

  @override
  String toString() => message;
}

/// Service for checking firmware updates from the Linksys cloud.
class FirmwareOtaCheckService {
  final LinksysHttpClient _client;

  FirmwareOtaCheckService({LinksysHttpClient? client})
      : _client = client ?? LinksysHttpClient();

  /// Check for firmware updates.
  ///
  /// Returns [FirmwareOtaInfo] if an update is available, or `null` if
  /// the device is already on the latest version (API returns empty body).
  Future<FirmwareOtaInfo?> checkForUpdate(FirmwareOtaCheckParams params) async {
    final baseUrl = cloudEnvironmentConfig[kFirmwareOtaBase] as String;
    final uri = Uri.parse('$baseUrl$kFirmwareOtaEndpoint')
        .replace(queryParameters: params.toQueryParams());

    logger.d('[FirmwareOta] Checking for update at $uri');

    try {
      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        logger.w('[FirmwareOta] API returned status ${response.statusCode}');
        throw FirmwareOtaCheckException(
          'Failed to check for updates: HTTP ${response.statusCode}',
        );
      }

      if (response.body.isEmpty) {
        logger.d('[FirmwareOta] No update available (empty response)');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = FirmwareOtaInfo.fromJson(json);
      logger.d('[FirmwareOta] Update available: ${info.version}');
      return info;
    } on FirmwareOtaCheckException {
      rethrow;
    } catch (e) {
      logger.e('[FirmwareOta] Error checking for update', error: e);
      throw FirmwareOtaCheckException('Failed to check for updates: $e');
    }
  }
}
