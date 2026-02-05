import 'package:equatable/equatable.dart';

class HealthCheckServer extends Equatable {
  final String serverID;
  final String serverName;
  final String serverLocation;
  final String serverCountry;
  final String serverHostname;
  final int serverPort;

  const HealthCheckServer({
    required this.serverID,
    required this.serverName,
    required this.serverLocation,
    required this.serverCountry,
    required this.serverHostname,
    required this.serverPort,
  });

  factory HealthCheckServer.fromJson(Map<String, dynamic> json) {
    // Use safe type conversions for external API data
    return HealthCheckServer(
      serverID: json['serverID']?.toString() ?? '',
      serverName: json['serverName']?.toString() ?? '',
      serverLocation: json['serverLocation']?.toString() ?? '',
      serverCountry: json['serverCountry']?.toString() ?? '',
      serverHostname: json['serverHostname']?.toString() ?? '',
      serverPort: (json['serverPort'] as num?)?.toInt() ?? 0,
    );
  }

  factory HealthCheckServer.empty() {
    return const HealthCheckServer(
      serverID: '',
      serverName: '----',
      serverLocation: '',
      serverCountry: '',
      serverHostname: '',
      serverPort: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverID': serverID,
      'serverName': serverName,
      'serverLocation': serverLocation,
      'serverCountry': serverCountry,
      'serverHostname': serverHostname,
      'serverPort': serverPort,
    };
  }

  @override
  String toString() {
    return '$serverName - $serverLocation';
  }

  @override
  List<Object?> get props => [
        serverID,
        serverName,
        serverLocation,
        serverCountry,
        serverHostname,
        serverPort,
      ];
}
