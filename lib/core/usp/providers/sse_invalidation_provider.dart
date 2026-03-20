import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/models/invalidation_domain.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_event_router.dart';

export 'package:privacy_gui/core/usp/models/invalidation_domain.dart';

/// Emits [InvalidationDomain] values when SSE notifications arrive.
///
/// Providers can `ref.listen` to this and selectively re-fetch or
/// `ref.invalidateSelf()` when their domain is signaled.
///
/// Uses a wildcard handler on [SseEventRouter] to capture ALL notifications
/// and map them to domains based on the TR-181 `param_path` / `obj_path`
/// in the notification payload.
///
/// NOTE: We cannot rely on `subscription_id` for matching because the CPE
/// uses its own internal IDs (e.g., "cpe-15") rather than the client-assigned
/// IDs (e.g., "wifi-ssid-valuechange"). This is the same issue documented in
/// [SseOperationAwaiter] for OperationComplete events.
final sseInvalidationProvider = StreamProvider<InvalidationDomain>((ref) {
  final manager = ref.watch(sseManagerProvider);
  if (manager == null) return const Stream.empty();

  final controller = StreamController<InvalidationDomain>.broadcast();

  final removeHandler = manager.addWildcardHandler((notification) {
    final domain = _mapToDomain(notification);
    if (domain != null && !controller.isClosed) {
      controller.add(domain);
    }
  });

  ref.onDispose(() {
    removeHandler();
    controller.close();
  });

  return controller.stream;
});

/// Maps a notification to an [InvalidationDomain] based on the TR-181 path
/// in the payload.
///
/// Filters out high-frequency `.Stats.` counter changes (e.g.,
/// `Device.WiFi.SSID.2.Stats.UnicastPacketsReceived`) that fire constantly
/// but carry no configuration-relevant information.
InvalidationDomain? _mapToDomain(SseNotification notification) {
  final path = _extractPath(notification);
  if (path == null || path.isEmpty) return null;

  // Skip high-frequency stats counter changes
  if (path.contains('.Stats.')) return null;

  // Map by TR-181 path prefix
  if (path.startsWith('Device.Hosts.Host.')) {
    return InvalidationDomain.connectedDevices;
  }
  if (path.startsWith('Device.WiFi.SSID.')) {
    return InvalidationDomain.wifiSsids;
  }
  if (path.startsWith('Device.WiFi.Radio.')) {
    return InvalidationDomain.wifiRadios;
  }
  // WiFi AssociatedDevice (more specific) before general AccessPoint
  if (path.startsWith('Device.WiFi.AccessPoint.') &&
      path.contains('AssociatedDevice.')) {
    return InvalidationDomain.wifiClients;
  }
  if (path.startsWith('Device.WiFi.AccessPoint.')) {
    return InvalidationDomain.wifiAccessPoints;
  }
  if (path.startsWith('Device.NAT.PortMapping.')) {
    return InvalidationDomain.portForwarding;
  }
  if (path.startsWith('Device.Firewall.DMZ.')) {
    return InvalidationDomain.dmz;
  }
  if (path.startsWith('Device.Firewall.Chain.')) {
    return InvalidationDomain.firewallRules;
  }
  // DHCP Client leases (exclude StaticAddress — that's dhcpReservations)
  if (path.startsWith('Device.DHCPv4.Server.Pool.') &&
      path.contains('Client.') &&
      !path.contains('StaticAddress')) {
    return InvalidationDomain.dhcpClients;
  }
  if (path.startsWith('Device.DHCPv4.Server.Pool.') &&
      path.contains('StaticAddress')) {
    return InvalidationDomain.dhcpReservations;
  }
  if (path.startsWith('Device.Routing.Router.') &&
      path.contains('IPv4Forwarding')) {
    return InvalidationDomain.staticRouting;
  }

  // OperationComplete and unrecognized paths don't map to invalidation
  // domains — they use the Direct Data Delivery pattern.
  return null;
}

/// Extracts the TR-181 path from a notification payload.
///
/// Each notification type stores its path under a different key:
/// - ValueChange → `value_change.param_path`
/// - ObjectCreation → `obj_creation.obj_path`
/// - ObjectDeletion → `obj_deletion.obj_path`
String? _extractPath(SseNotification notification) {
  final payload = notification.payload;
  switch (notification.type) {
    case 'ValueChange':
      final vc = payload['value_change'] as Map<String, dynamic>?;
      return vc?['param_path'] as String?;
    case 'ObjectCreation':
      final oc = payload['obj_creation'] as Map<String, dynamic>?;
      return oc?['obj_path'] as String?;
    case 'ObjectDeletion':
      final od = payload['obj_deletion'] as Map<String, dynamic>?;
      return od?['obj_path'] as String?;
    default:
      return null;
  }
}
