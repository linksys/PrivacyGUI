import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/services/usp_device_service.dart';

// ── Data Model ──

class WanData extends Equatable {
  final WanStatus raw;
  final WanStatusUIModel model;

  const WanData({required this.raw, required this.model});

  @override
  List<Object?> get props => [raw, model];
}

// ── Provider ──

/// Layer 1 data provider for WAN status.
///
/// No SSE invalidation domain for WAN — manual refresh only.
final wanDataProvider =
    AsyncNotifierProvider<WanDataNotifier, WanData>(WanDataNotifier.new);

// ── Notifier (NOT autoDispose) ──

class WanDataNotifier extends AsyncNotifier<WanData> {
  @override
  Future<WanData> build() async {
    // No SSE invalidation domain for WAN status.
    return _fetch();
  }

  Future<WanData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      WanStatus.fetch(usp),
      _fetchDefaultGateway(usp),
      _fetchWanIpv6(usp),
    ]);

    final wanStatus = results[0] as WanStatus;
    final gateway = results[1] as String;
    final ipv6 = results[2] as ({bool enabled, List<String> addresses});

    final svc = UspDeviceService();
    final model = svc.buildWanStatusUIModel(
      wanStatus: wanStatus,
      gateway: gateway,
      ipv6Enabled: ipv6.enabled,
      ipv6Addresses: ipv6.addresses,
    );

    logger.d('[USP][WanData] Fetched — ip=${wanStatus.ipAddress}, '
        'status=${wanStatus.status}, gateway=$gateway, '
        'ipv6=${ipv6.enabled}');
    return WanData(raw: wanStatus, model: model);
  }

  // ── Mutation ──

  /// Renews the WAN DHCP lease.
  ///
  /// Fire-and-forget operate — firmware does NOT send OperationComplete.
  /// Waits 2 seconds then re-fetches WAN status.
  Future<void> renewLease() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    await ref.read(uspMutationLockProvider).withLock(() async {
      await WanOperations.renewDhcpLease(usp);
      await Future.delayed(const Duration(seconds: 2));
      final wan = await WanStatus.fetch(usp);
      final prev = state.valueOrNull;
      final svc = UspDeviceService();
      state = AsyncData(WanData(
        raw: wan,
        model: svc.buildWanStatusUIModel(
          wanStatus: wan,
          gateway: prev?.model.gateway ?? '',
        ),
      ));
    });
  }

  // ── Helpers ──

  /// Fetches the default gateway IP from the IPv4 routing table.
  Future<String> _fetchDefaultGateway(UspService usp) async {
    try {
      final resp = await usp.get([
        'Device.Routing.Router.1.IPv4Forwarding.*.DestIPAddress',
        'Device.Routing.Router.1.IPv4Forwarding.*.GatewayIPAddress',
        'Device.Routing.Router.1.IPv4Forwarding.*.Interface',
      ]).timeout(const Duration(seconds: 10));

      const basePath = 'Device.Routing.Router.1.IPv4Forwarding.';
      final ids = <String>{};
      for (final key in resp.keys) {
        if (key.startsWith(basePath)) {
          final rest = key.substring(basePath.length);
          final dot = rest.indexOf('.');
          if (dot > 0) ids.add(rest.substring(0, dot));
        }
      }

      for (final id in ids) {
        final prefix = '$basePath$id.';
        final dest = resp['${prefix}DestIPAddress']?.toString() ?? '';
        final gw = resp['${prefix}GatewayIPAddress']?.toString() ?? '';
        final iface = resp['${prefix}Interface']?.toString() ?? '';
        if (dest == '0.0.0.0' && iface.contains('Interface.2')) {
          return gw;
        }
      }
      return '';
    } catch (e) {
      logger.w('[USP][WanData] Failed to fetch default gateway: $e');
      return '';
    }
  }

  /// Fetches IPv6 enable flag and addresses for WAN (Interface.2).
  Future<({bool enabled, List<String> addresses})> _fetchWanIpv6(
      UspService usp) async {
    try {
      final resp = await usp.get([
        'Device.IP.Interface.2.IPv6Enable',
        'Device.IP.Interface.2.IPv6Address.',
      ]).timeout(const Duration(seconds: 10));

      final enabled = resp['Device.IP.Interface.2.IPv6Enable'] == true;
      final instances = resp.getInstances('Device.IP.Interface.2.IPv6Address.');
      final List<String> addresses = instances
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty)
          .toList();

      return (enabled: enabled, addresses: addresses);
    } catch (e) {
      logger.w('[USP][WanData] IPv6 fetch failed (may not be supported): $e');
      return (enabled: false, addresses: const <String>[]);
    }
  }
}
