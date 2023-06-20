import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:linksys_moab/core/utils/logger.dart';
import 'package:multicast_dns/multicast_dns.dart';

class DiscoverDevice extends Equatable {
  final String domainName;
  final String target;
  final String ip;
  final int port;

  const DiscoverDevice({
    required this.domainName,
    required this.target,
    required this.ip,
    required this.port,
  });

  DiscoverDevice copyWith({
    String? domainName,
    String? target,
    String? ip,
    int? port,
  }) {
    return DiscoverDevice(
      domainName: domainName ?? this.domainName,
      target: target ?? this.target,
      ip: ip ?? this.ip,
      port: port ?? this.port,
    );
  }

  @override
  List<Object> get props => [domainName, target, ip, port];

  Map<String, dynamic> toJson() {
    return {
      'domainName': domainName,
      'target': target,
      'ip': ip,
      'port': port,
    };
  }

  factory DiscoverDevice.fromJson(Map<String, dynamic> json) {
    return DiscoverDevice(
      domainName: json['domainName'],
      target: json['target'],
      ip: json['ip'],
      port: json['port'],
    );
  }
}

class MDnsHelper {
  static Future<List<DiscoverDevice>> discover(String name) async {
    final MDnsClient client = Platform.isIOS ? MDnsClient() : MDnsClient(rawDatagramSocketFactory:
        (dynamic host, int port,
        {bool? reuseAddress, bool? reusePort, int? ttl}) {
      return RawDatagramSocket.bind(host, port,
          reuseAddress: true, reusePort: false, ttl: ttl!);
    });
    List<DiscoverDevice> result = [];
    logger.d('Discover start $name');
    // Start the client with default options.
    await client.start();
    // Get the PTR record for the service.
    await for (final PtrResourceRecord ptr in client
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
      // Use the domainName from the PTR record to get the SRV record,
      // which will have the port and local hostname.
      // Note that duplicate messages may come through, especially if any
      // other mDNS queries are running elsewhere on the machine.
      await for (final SrvResourceRecord srv
      in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName))) {
        // Domain name will be something like "io.flutter.example@some-iphone.local._dartobservatory._tcp.local"
        final String bundleId =
            ptr.domainName; //.substring(0, ptr.domainName.indexOf('@'));
        logger.d('Discover device instance found at '
            '${srv.target}:${srv.port} for "$bundleId".');
        var device = DiscoverDevice(
            domainName: bundleId, target: srv.target, ip: '', port: srv.port);
        await for (final IPAddressResourceRecord ip
        in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target))) {
          logger.d('Service instance found at '
              '${srv.target}:${srv.port} with ${ip.address}.');
          device = device.copyWith(ip: ip.address.address);
        }
        result.add(device);
      }
    }
    client.stop();
    logger.d('Discover finish $name');
    return result;
  }
}
