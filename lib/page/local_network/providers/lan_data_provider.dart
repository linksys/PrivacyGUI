import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';

// ── Data Model ──

class LanData extends Equatable {
  final LanInfoUIModel model;

  const LanData({required this.model});

  const LanData.empty()
      : model = const LanInfoUIModel(
          ipAddress: '',
          subnetMask: '',
          dhcpEnabled: false,
          minAddress: '',
          maxAddress: '',
        );

  @override
  List<Object?> get props => [model];
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
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }

    // LanNetworkInfo.fetch includes IPv6Enable (merged in YAML v1.2.0).
    // IPv6 addresses still need a separate multi-instance query.
    final List<Object> results;
    try {
      results = await Future.wait([
        LanNetworkInfo.fetch(usp),
        _fetchLanIpv6Addresses(usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final lanInfo = results[0] as LanNetworkInfo;
    final ipv6Addresses = results[1] as List<String>;

    final model = LanInfoUIModel(
      hostName: lanInfo.hostName,
      ipAddress: lanInfo.ipAddress,
      subnetMask: lanInfo.subnetMask,
      dhcpEnabled: lanInfo.dhcpEnabled,
      minAddress: lanInfo.minAddress,
      maxAddress: lanInfo.maxAddress,
      leaseTimeMinutes: (lanInfo.leaseTime / 60).round(),
      dnsServers: lanInfo.dnsServers,
      ipv6Enabled: lanInfo.ipv6Enabled,
      ipv6Addresses: ipv6Addresses,
    );

    logger.d('[USP][LanData] Fetched — ip=${lanInfo.ipAddress}, '
        'dhcp=${lanInfo.dhcpEnabled}, ipv6=${lanInfo.ipv6Enabled}');
    return LanData(model: model);
  }

  /// Fetches IPv6 addresses for LAN (Interface.1) via multi-instance query.
  Future<List<String>> _fetchLanIpv6Addresses(UspService usp) async {
    try {
      final resp = await usp.get([
        'Device.IP.Interface.1.IPv6Address.',
      ]).timeout(const Duration(seconds: 20));

      final instances = resp.getInstances('Device.IP.Interface.1.IPv6Address.');
      return instances
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty)
          .toList();
    } catch (e) {
      logger.w('[USP][LanData] IPv6 addresses fetch failed: $e');
      return const <String>[];
    }
  }
}
