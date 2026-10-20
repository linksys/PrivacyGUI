import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

/// What `UspIpv6PortServiceService.fetchPage` hands the notifier: the rules
/// the page lists, and the descriptions of every other firewall rule.
class Ipv6PortServicePageData {
  final List<Ipv6PortServiceRuleUIModel> rules;

  /// Descriptions of the `Device.Firewall.Chain.1.Rule` entries the page does
  /// not list (system rules, IPv4 rules, non-Accept rules). FW refuses a
  /// description any firewall rule already has (ErrorDescriptionInUse,
  /// FWDEV#204), because FLWRT finds a rule by its description.
  final Set<String> hiddenRuleDescriptions;

  const Ipv6PortServicePageData({
    required this.rules,
    required this.hiddenRuleDescriptions,
  });
}
