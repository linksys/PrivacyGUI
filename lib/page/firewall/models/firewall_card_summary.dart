import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_verdict.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

/// Which SPI firewall is off, when one is.
enum SpiOff { ipv4, ipv6, both }

/// What the dashboard's Firewall card shows (#1130).
///
/// Each row of the card is one settings page and its main value. Which rows
/// show and what they count follow #1130's 11-09 and 11-12 comments, and are
/// kept here so they are tested without a widget. How a value is worded, and
/// when a row carries `(i)`, is the card's.
class FirewallCardSummary extends Equatable {
  /// The badge, and the popup form's one value.
  final FirewallVerdict verdict;

  /// Which SPI firewall is off, or null while both are on. On is the default,
  /// so the row only shows when one is off.
  final SpiOff? spiOff;

  /// Whether DMZ is on, as on the DMZ page.
  final bool dmzOn;

  /// The DMZ host as the DMZ page gives it: the MAC in MAC mode, else the IP.
  final String dmzHost;

  /// Port rules that are on, and all port rules, over the Port Forwarding
  /// page's three tabs (single port, port range, port range triggering).
  /// Triggering counts because it also lets connections in. A rule that is off
  /// opens nothing, so it is in [total] only. Null until both forwarding and
  /// triggering are read.
  final ({int on, int total})? portRules;

  /// Whether UPnP is on, as on the Administration page. Null until it is read.
  final bool? upnpOn;

  const FirewallCardSummary({
    required this.verdict,
    required this.spiOff,
    required this.dmzOn,
    required this.dmzHost,
    required this.portRules,
    required this.upnpOn,
  });

  factory FirewallCardSummary.of({
    required FirewallData firewall,
    required List<PortForwardingRuleUIModel>? forwardingRules,
    required List<PortTriggeringRuleUIModel>? triggeringRules,
    required bool? upnpEnabled,
  }) {
    final ipv4On = firewall.firewallModel.isIPv4FirewallEnabled;
    final ipv6On = firewall.firewallModel.isIPv6FirewallEnabled;
    final dmz = firewall.dmzModel;
    return FirewallCardSummary(
      verdict: FirewallVerdict.of(
        ipv4SpiOn: ipv4On,
        ipv6SpiOn: ipv6On,
        dmzOn: dmz.isEnabled,
      ),
      spiOff: switch ((ipv4On, ipv6On)) {
        (true, true) => null,
        (false, true) => SpiOff.ipv4,
        (true, false) => SpiOff.ipv6,
        (false, false) => SpiOff.both,
      },
      dmzOn: dmz.isEnabled,
      dmzHost: dmz.destinationType == DmzDestinationType.mac
          ? dmz.destMac
          : dmz.destIp,
      portRules: forwardingRules == null || triggeringRules == null
          ? null
          : (
              on: forwardingRules.where((r) => r.enabled).length +
                  triggeringRules.where((r) => r.enabled).length,
              total: forwardingRules.length + triggeringRules.length,
            ),
      upnpOn: upnpEnabled,
    );
  }

  /// Whether the card says "You haven't opened any device to the internet":
  /// both SPI firewalls on, DMZ off and no port rule on. UPnP on does not hide
  /// it, which is why the sentence does not claim nothing can be reached.
  /// Never claimed while the port rules are unknown.
  bool get nothingOpen => spiOff == null && !dmzOn && portRules?.on == 0;

  @override
  List<Object?> get props =>
      [verdict, spiOff, dmzOn, dmzHost, portRules, upnpOn];
}
