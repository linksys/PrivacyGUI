class HealthCheckServer {
  final String serverID;
  final String serverName;
  final String serverLocation;
  final String serverCountry;
  final String serverHostname;
  final int serverPort;

  HealthCheckServer({
    required this.serverID,
    required this.serverName,
    required this.serverLocation,
    required this.serverCountry,
    required this.serverHostname,
    required this.serverPort,
  });

  factory HealthCheckServer.fromJson(Map<String, dynamic> json) {
    return HealthCheckServer(
      serverID: json['serverID'] as String? ?? '',
      serverName: json['serverName'] as String? ?? '',
      serverLocation: json['serverLocation'] as String? ?? '',
      serverCountry: json['serverCountry'] as String? ?? '',
      serverHostname: json['serverHostname'] as String? ?? '',
      serverPort: json['serverPort'] as int? ?? 0,
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
}
