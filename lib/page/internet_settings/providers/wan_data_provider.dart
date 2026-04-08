import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';

// ── Data Model ──

class WanData extends Equatable {
  final WanStatusUIModel model;

  const WanData({required this.model});

  @override
  List<Object?> get props => [model];
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
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }

    try {
      // WanStatus.fetch includes IPv6Enable (merged in YAML v1.1.0).
      // Gateway + IPv6 addresses are combined into one manual request
      // to reduce throttler pressure (was 3 → now 2 USP requests).
      final results = await Future.wait([
        WanStatus.fetch(usp),
        _fetchGatewayAndIpv6Addresses(usp),
      ]);

      final wanStatus = results[0] as WanStatus;
      final extra =
          results[1] as ({String gateway, List<String> ipv6Addresses});

      final svc = UspDeviceService();
      final model = svc.buildWanStatusUIModel(
        wanStatus: wanStatus,
        gateway: extra.gateway,
        ipv6Addresses: extra.ipv6Addresses,
      );

      logger.d('[USP][WanData] Fetched — ip=${wanStatus.ipAddress}, '
          'status=${wanStatus.status}, gateway=${extra.gateway}, '
          'ipv6=${wanStatus.ipv6Enabled}');
      return WanData(model: model);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ── Mutation ──

  /// Renews the WAN DHCP lease.
  ///
  /// Fire-and-forget operate — firmware does NOT send OperationComplete.
  /// Waits 2 seconds then re-fetches WAN status.
  Future<void> renewLease() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }

    await ref.read(uspMutationLockProvider).withLock(() async {
      try {
        await WanOperations.renewDhcpLease(usp);
        await Future.delayed(const Duration(seconds: 2));
        final wan = await WanStatus.fetch(usp);
        final prev = state.valueOrNull;
        final svc = UspDeviceService();
        state = AsyncData(WanData(
          model: svc.buildWanStatusUIModel(
            wanStatus: wan,
            gateway: prev?.model.gateway ?? '',
          ),
        ));
      } catch (e) {
        throw mapUspErrorToServiceError(e);
      }
    });
  }

  // ── Helpers ──

  /// Fetches default gateway IP and IPv6 addresses in a single USP request.
  ///
  /// Combines the routing table scan (for gateway) and IPv6Address
  /// multi-instance query to minimize throttler slot usage.
  Future<({String gateway, List<String> ipv6Addresses})>
      _fetchGatewayAndIpv6Addresses(UspService usp) async {
    try {
      final resp = await usp.get([
        // Gateway: scan routing table for default route on WAN interface
        'Device.Routing.Router.1.IPv4Forwarding.*.DestIPAddress',
        'Device.Routing.Router.1.IPv4Forwarding.*.GatewayIPAddress',
        'Device.Routing.Router.1.IPv4Forwarding.*.Interface',
        // IPv6 addresses (multi-instance)
        'Device.IP.Interface.2.IPv6Address.',
      ]).timeout(const Duration(seconds: 20));

      // Parse gateway from routing table
      String gateway = '';
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
          gateway = gw;
          break;
        }
      }

      // Parse IPv6 addresses
      final instances = resp.getInstances('Device.IP.Interface.2.IPv6Address.');
      final List<String> ipv6Addresses = instances
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty)
          .toList();

      return (gateway: gateway, ipv6Addresses: ipv6Addresses);
    } catch (e) {
      logger.w('[USP][WanData] Gateway/IPv6 fetch failed: $e');
      return (gateway: '', ipv6Addresses: const <String>[]);
    }
  }
}
