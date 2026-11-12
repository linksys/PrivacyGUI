import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';

/// The IPv6 Port Service rules, for the dashboard's Firewall card (#1130).
///
/// A rule lets IPv6 connections from the internet reach a device in the home,
/// so while one is on the card does not say "You haven't opened any device to
/// the internet". It reads the page's own `fetch()` — the rules the page lists,
/// built the page's way — as the PDF report does.
///
/// L1: not autoDispose. Read again by the dashboard's refresh and by a save on
/// the IPv6 Port Service page, which invalidates it.
final ipv6PortServiceDataProvider =
    FutureProvider<List<Ipv6PortServiceRuleUIModel>>(
  (ref) => ref.read(uspIpv6PortServiceServiceProvider).fetch(),
);
