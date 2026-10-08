import 'package:privacy_gui/constants/build_config.dart';
import 'dart:convert';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

/// Kernel-selected IPv4 egress; route/link readiness is not an Internet test.
class ActiveIpv4Connection {
  ActiveIpv4Connection(this.data);
  final Map<String, dynamic> data;
  static const path = 'Device.X_LINKSYS_AutoIPoE.Connection';
  String text(String key) => data[key] is String ? data[key] as String : '';
  bool get isUp =>
      data['available'] == true &&
      data['state'] == 'Up' &&
      data['activeIPv4Route'] == true;
  bool get isTunnel => text('tunnelType').isNotEmpty;
  bool get pointToPoint => data['pointToPoint'] == true;
  String get address => text('address');
  String get gateway => text('gateway');
  int get mtu => data['mtu'] is int ? data['mtu'] as int : 0;
  String get label => isTunnel
      ? text('tunnelType')
      : switch (text('protocol')) {
          'dhcp' => 'DHCP',
          'pppoe' => 'PPPoE',
          'static' => 'Static',
          _ => text('protocol'),
        };
  List<String> get ipv6 =>
      (data['ipv6Addresses'] is List ? data['ipv6Addresses'] as List : const [])
          .whereType<String>()
          .toList();
  String? get forwardingNotice => switch (text('forwardingPolicy')) {
        'port-set' =>
          'MAP-E: only ports assigned by your ISP can receive inbound IPv4 connections.',
        'provider-nat' =>
          'DS-Lite: inbound IPv4 connections are controlled by your ISP’s NAT. Local port rules alone cannot open them.',
        'provider-dependent' =>
          'IPIP: inbound IPv4 availability depends on the address and service supplied by your ISP.',
        _ => null,
      };
  static Future<ActiveIpv4Connection?> fetch(UspClient client) async {
    if (!BuildConfig.autoIPoEEnabled) return null;
    Map<String, dynamic> reply;
    try {
      reply = await client.get([path]);
    } catch (e) {
      final error = e is ServiceError ? e : mapUspErrorToServiceError(e);
      if (error is ResourceNotFoundError) return null;
      throw error;
    }
    // Older stock firmware has no optional native connection object.
    if (!reply.containsKey(path)) return null;
    final raw = reply[path];
    if (raw is! String || raw.length > 32768) throw const InvalidInputError();
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> || value['apiVersion'] != 1) {
      throw const InvalidInputError();
    }
    return ActiveIpv4Connection(value);
  }
}
