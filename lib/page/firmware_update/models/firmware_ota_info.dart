import 'package:equatable/equatable.dart';

/// Response model from the Linksys firmware update cloud API.
///
/// When an update is available, all fields are populated.
/// When no update is available, the API returns an empty response body.
class FirmwareOtaInfo extends Equatable {
  final String version;
  final DateTime releaseDate;
  final String downloadUrl;
  final String checksum;
  final String checkInterval;
  final String checkTime;

  const FirmwareOtaInfo({
    required this.version,
    required this.releaseDate,
    required this.downloadUrl,
    required this.checksum,
    required this.checkInterval,
    required this.checkTime,
  });

  factory FirmwareOtaInfo.fromJson(Map<String, dynamic> json) {
    return FirmwareOtaInfo(
      version: json['version'] as String? ?? '',
      releaseDate: DateTime.tryParse(json['release_date'] as String? ?? '') ??
          DateTime.now(),
      downloadUrl: json['download_url'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
      checkInterval: json['check_interval'] as String? ?? '',
      checkTime: json['check_time'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        version,
        releaseDate,
        downloadUrl,
        checksum,
        checkInterval,
        checkTime,
      ];
}

/// Query parameters required for the firmware OTA check API.
class FirmwareOtaCheckParams extends Equatable {
  final String macAddress;
  final String installedVersion;
  final String modelNumber;
  final String hardwareVersion;
  final String ipAddress;

  const FirmwareOtaCheckParams({
    required this.macAddress,
    required this.installedVersion,
    required this.modelNumber,
    required this.hardwareVersion,
    required this.ipAddress,
  });

  Map<String, String> toQueryParams() => {
        'mac_address': macAddress,
        'installed_version': installedVersion,
        'model_number': modelNumber,
        'hardware_version': hardwareVersion,
        'ip_address': ipAddress,
      };

  @override
  List<Object?> get props => [
        macAddress,
        installedVersion,
        modelNumber,
        hardwareVersion,
        ipAddress,
      ];
}
