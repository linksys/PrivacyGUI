import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';

// ── Data Model ──

class LanData extends Equatable {
  final LanNetworkInfo raw;
  final LanInfoUIModel model;

  const LanData({required this.raw, required this.model});

  const LanData.empty()
      : raw = const LanNetworkInfo(
          ipAddress: '',
          subnetMask: '',
          dhcpEnabled: false,
          minAddress: '',
          maxAddress: '',
          leaseTime: 0,
          dnsServers: '',
          hostName: '',
        ),
        model = const LanInfoUIModel(
          ipAddress: '',
          subnetMask: '',
          dhcpEnabled: false,
          minAddress: '',
          maxAddress: '',
        );

  @override
  List<Object?> get props => [raw, model];
}

// ── Provider ──

final lanDataProvider =
    AsyncNotifierProvider<LanDataNotifier, LanData>(LanDataNotifier.new);

// ── Notifier (NOT autoDispose) ──

class LanDataNotifier extends AsyncNotifier<LanData> {
  @override
  Future<LanData> build() async {
    // No SSE invalidation domain for LAN info.
    return _fetch();
  }

  Future<LanData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      LanNetworkInfo.fetch(usp),
      _fetchLanIpv6(usp),
    ]);

    final lanInfo = results[0] as LanNetworkInfo;
    final ipv6 = results[1] as ({bool enabled, List<String> addresses});

    final model = LanInfoUIModel(
      ipAddress: lanInfo.ipAddress,
      subnetMask: lanInfo.subnetMask,
      dhcpEnabled: lanInfo.dhcpEnabled,
      minAddress: lanInfo.minAddress,
      maxAddress: lanInfo.maxAddress,
      dnsServers: lanInfo.dnsServers,
      ipv6Enabled: ipv6.enabled,
      ipv6Addresses: ipv6.addresses,
    );

    logger.d('[USP][LanData] Fetched — ip=${lanInfo.ipAddress}, '
        'dhcp=${lanInfo.dhcpEnabled}, ipv6=${ipv6.enabled}');
    return LanData(raw: lanInfo, model: model);
  }

  /// Fetches IPv6 enable flag and addresses for LAN (Interface.1).
  Future<({bool enabled, List<String> addresses})> _fetchLanIpv6(
      UspService usp) async {
    try {
      final resp = await usp.get([
        'Device.IP.Interface.1.IPv6Enable',
        'Device.IP.Interface.1.IPv6Address.',
      ]).timeout(const Duration(seconds: 10));

      final enabled = resp['Device.IP.Interface.1.IPv6Enable'] == true;
      final instances = resp.getInstances('Device.IP.Interface.1.IPv6Address.');
      final List<String> addresses = instances
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty)
          .toList();

      return (enabled: enabled, addresses: addresses);
    } catch (e) {
      logger.w('[USP][LanData] IPv6 fetch failed (may not be supported): $e');
      return (enabled: false, addresses: const <String>[]);
    }
  }
}
