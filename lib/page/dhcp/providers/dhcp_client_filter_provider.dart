import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter options for DHCP client list display.
enum DhcpClientFilter { all, onlineOnly }

/// Persists the selected DHCP client filter across page navigation.
final dhcpClientFilterProvider = StateProvider<DhcpClientFilter>(
  (ref) => DhcpClientFilter.all,
);
