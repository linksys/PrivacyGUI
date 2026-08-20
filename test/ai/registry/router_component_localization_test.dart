import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:privacy_gui/ai/registry/router_component_registry.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Localization coverage for the A2UI component surface (#1253).
///
/// Every router component now resolves its chrome through `loc(context)`, so a
/// missing `AppLocalizations` ancestor turns into a null-check crash at render
/// time rather than an English string. These tests render each registered
/// router component through the registry — the same path
/// `RouterAssistantView` uses — and assert the localized label actually
/// reaches the tree.
///
/// Both fixture shapes matter: populated props exercise the row labels, empty
/// props exercise the empty-state prose and the `?? loc(context).x` fallbacks.
/// Values (SSIDs, IPs, status tokens) stay model-supplied and are deliberately
/// not localized.
void main() {
  late ComponentRegistry registry;

  setUp(() {
    registry = RouterComponentRegistry.create();
  });

  /// Renders [name] with [props] and returns the built subtree, wrapped in the
  /// localized MaterialApp shell the assistant view provides in production.
  Widget wrap(
    String name,
    Map<String, dynamic> props, {
    Locale locale = const Locale('en'),
  }) {
    final builder = registry.lookup(name);
    expect(builder, isNotNull, reason: '$name must be registered');
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Builder(builder: (context) => builder!(context, props)),
        ),
      ),
    );
  }

  /// (component, props, expected localized strings) — the label side of each
  /// component, which #1253 moved out of Dart literals and into ARB keys.
  final populated =
      <({String name, Map<String, dynamic> props, List<String> expect})>[
    (
      name: 'WanSection',
      props: {
        'wanStatus': 'Connected',
        'connectedDevices': 4,
        'wanIp': '203.0.113.7',
        'connectionType': 'DHCP',
      },
      expect: ['WAN Status', 'Connected Devices', 'WAN IP', 'Connection Type'],
    ),
    (
      name: 'LanSection',
      props: {
        'ipAddress': '192.168.1.1',
        'subnetMask': '255.255.255.0',
        'dhcpEnabled': true,
        'dhcpRange': '192.168.1.100-149',
        'dnsServers': '8.8.8.8',
      },
      expect: ['LAN IP Address', 'Subnet mask', 'DHCP Server', 'Enabled'],
    ),
    (
      name: 'WifiSection',
      props: {
        'ssid': 'Linksys-Test',
        'password': 'secret',
        'securityMode': 'WPA3',
        'band': '5GHz',
      },
      expect: ['SSID', 'Password', 'Security', 'Band'],
    ),
    (
      name: 'SystemSection',
      props: {'cpuPercent': 42, 'memoryPercent': 63, 'uptime': '3d 4h'},
      expect: ['CPU', 'Memory', 'Uptime'],
    ),
    (
      name: 'FirewallSection',
      props: {
        'enabled': true,
        'ipv4Enabled': true,
        'ipv6Enabled': false,
        'ruleCount': 3,
        'dmzEnabled': false,
      },
      expect: ['Firewall', 'IPv4 Firewall', 'IPv6 Firewall', 'Active Rules'],
    ),
    (
      name: 'DhcpSection',
      props: {
        'reservations': [
          {'hostname': 'nas', 'mac': 'AA:BB', 'ip': '192.168.1.5'},
        ],
        'clients': [
          {'hostname': 'phone', 'mac': 'CC:DD', 'ip': '192.168.1.20'},
        ],
      },
      expect: ['Reservations', 'Active Clients'],
    ),
    (
      name: 'PortForwardingSection',
      props: {
        'rules': [
          {'description': 'web', 'externalPort': 80, 'internalIp': '10.0.0.2'},
        ],
      },
      expect: ['web'],
    ),
    (
      name: 'NetworkStatusCard',
      props: {
        'wanStatus': 'Connected',
        'connectedDevices': 2,
        'uploadSpeed': '10 Mbps',
        'downloadSpeed': '100 Mbps',
      },
      expect: [
        'Network Status',
        'WAN Status',
        'Connected Devices',
        'Upload Speed',
        'Download Speed',
      ],
    ),
    (
      name: 'WifiSettingsCard',
      props: {
        'ssid': 'Linksys-Test',
        'password': 'secret',
        'securityMode': 'WPA3',
        'band': '5GHz',
      },
      expect: [
        'WiFi Settings',
        'Network Name (SSID)',
        'Password',
        'Security mode',
        'Band',
      ],
    ),
    (
      name: 'LanInfoCard',
      props: {
        'ipAddress': '192.168.1.1',
        'subnetMask': '255.255.255.0',
        'dhcpEnabled': true,
        'dhcpRange': '192.168.1.100-149',
        'dnsServers': '8.8.8.8',
        'ipv6Enabled': true,
        'ipv6Addresses': ['fe80::1'],
      },
      expect: [
        'LAN Settings',
        'IP address',
        'Subnet mask',
        'DHCP Server',
        'DHCP Range',
        'DNS Servers',
        'IPv6 Address',
      ],
    ),
    (
      name: 'DhcpCard',
      props: {
        'reservations': [
          {'hostname': 'nas', 'mac': 'AA:BB', 'ip': '192.168.1.5'},
        ],
        'clients': [
          {'hostname': 'phone', 'mac': 'CC:DD', 'ip': '192.168.1.20'},
        ],
      },
      expect: ['DHCP', 'Reservations (1)', 'Active Clients (1)'],
    ),
    (
      name: 'FirewallCard',
      props: {
        'ipv4Enabled': true,
        'ipv6Enabled': false,
        'ruleCount': 3,
        'dmzEnabled': false,
        'portForwardingCount': 2,
      },
      expect: [
        'Firewall',
        'IPv4 Firewall',
        'IPv6 Firewall',
        'Active Rules',
        'DMZ',
        'Port Forwarding Rules',
      ],
    ),
    (
      name: 'PortForwardingCard',
      props: {
        'rules': [
          {
            'description': 'web',
            'port': 80,
            'protocol': 'TCP',
            'internalIp': '10.0.0.2',
          },
        ],
      },
      // The rule subtitle is a `MapsToRow`, so the arrow is a WidgetSpan and
      // only the source half is a localized string.
      expect: ['Port Forwarding', '1 rules', 'Port 80 (TCP)'],
    ),
    (
      name: 'SystemResourceCard',
      props: {'cpuPercent': 42, 'memoryPercent': 63, 'uptime': '3d 4h'},
      expect: ['System Resources', 'CPU', 'Memory', 'Uptime'],
    ),
    (
      name: 'DeviceListView',
      props: {
        'devices': [
          {'name': 'iPhone', 'ip': '192.168.1.20', 'connectionType': 'WiFi'},
        ],
      },
      expect: ['iPhone'],
    ),
    (
      name: 'EthernetPortsCard',
      props: {
        'ports': [
          {'label': 'WAN', 'status': 'connected', 'speed': '1 Gbps'},
        ],
      },
      expect: ['Ethernet Ports', 'WAN'],
    ),
    (
      name: 'ConfirmationSheet',
      props: {'message': 'Reboot the router?'},
      // Title and both button labels come from the ARB fallbacks.
      expect: ['Confirmation', 'Confirm', 'Cancel'],
    ),
  ];

  for (final c in populated) {
    testWidgets('${c.name} renders localized labels', (tester) async {
      await tester.pumpWidget(wrap(c.name, c.props));
      await tester.pump();

      for (final label in c.expect) {
        expect(find.textContaining(label, findRichText: true), findsWidgets,
            reason: '${c.name} must render the localized "$label"');
      }
    });
  }

  /// Empty props exercise the empty-state prose, which #1253 also moved into
  /// the ARB.
  final emptyStates =
      <({String name, Map<String, dynamic> props, String expect})>[
    (
      name: 'DevicesSection',
      props: {'devices': []},
      expect: 'No connected devices found'
    ),
    (
      name: 'DeviceListView',
      props: {'devices': []},
      expect: 'No connected devices found'
    ),
    (
      name: 'EthernetSection',
      props: {'ports': []},
      expect: 'No ethernet ports found'
    ),
    (
      name: 'EthernetPortsCard',
      props: {'ports': []},
      expect: 'No port information available'
    ),
    (name: 'DhcpSection', props: {}, expect: 'No DHCP data available'),
    (name: 'DhcpCard', props: {}, expect: 'No DHCP data available'),
    (
      name: 'PortForwardingSection',
      props: {'rules': []},
      expect: 'No port forwarding rules configured'
    ),
    (
      name: 'PortForwardingCard',
      props: {'rules': []},
      expect: 'No port forwarding rules configured'
    ),
    (
      name: 'DiagnosticsSection',
      props: {},
      expect: 'No diagnostic results available'
    ),
    (
      name: 'LineChartSection',
      props: {'series': []},
      expect: 'No data available'
    ),
    (
      name: 'BarChartSection',
      props: {'series': []},
      expect: 'No data available'
    ),
    (
      name: 'PieChartSection',
      props: {'sections': []},
      expect: 'No data available'
    ),
  ];

  for (final c in emptyStates) {
    testWidgets('${c.name} renders its localized empty state', (tester) async {
      await tester.pumpWidget(wrap(c.name, c.props));
      await tester.pump();

      expect(find.textContaining(c.expect, findRichText: true), findsWidgets);
    });
  }

  testWidgets('fallback name for an unnamed device comes from the ARB',
      (tester) async {
    await tester.pumpWidget(wrap('DeviceListView', {
      'devices': [
        {'ip': '192.168.1.20'},
      ],
    }));
    await tester.pump();

    expect(find.textContaining('Unknown Device'), findsWidgets);
  });

  testWidgets('fallback name for an unnamed forwarding rule comes from the ARB',
      (tester) async {
    await tester.pumpWidget(wrap('PortForwardingCard', {
      'rules': [
        {'port': 80, 'internalIp': '10.0.0.2'},
      ],
    }));
    await tester.pump();

    expect(find.textContaining('Unnamed rule'), findsWidgets);
  });

  // The section's port column is a fixed 80px, so it cannot carry the labelled
  // `portProtocol` form the card's subtitle uses ("Port 80 (TCP)" does not fit).
  // It has its own key rather than a bare '$port/$protocol' literal, which is
  // what #1253 AC-2 asks for — and the two rule keys are both accepted, because
  // reading only `port` printed "null" for every `externalPort` payload.
  for (final portKey in ['port', 'externalPort']) {
    testWidgets('the port column composes through the ARB, keyed on $portKey',
        (tester) async {
      await tester.pumpWidget(wrap('PortForwardingSection', {
        'rules': [
          {'description': 'web', portKey: 8080, 'protocol': 'UDP'},
        ],
      }));
      await tester.pump();

      expect(find.text('8080/UDP'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
    });
  }

  group('non-English locale', () {
    // The 52 reused keys are already translated in all 26 locales; the 42 keys
    // added by #1253 are English-only by decision, so Flutter's ARB fallback
    // serves the template value. Both halves are asserted here so a future
    // translation drop is visible rather than silent.
    testWidgets('reused keys are translated, new keys fall back to English',
        (tester) async {
      await tester.pumpWidget(wrap(
        'WifiSettingsCard',
        {'ssid': 'Linksys-Test', 'band': '5GHz'},
        locale: const Locale('de'),
      ));
      await tester.pump();

      // Reused key, translated in app_de.arb.
      expect(find.textContaining('WiFi-Einstellungen'), findsWidgets);
      // New key, English-only by decision.
      expect(find.textContaining('Network Name (SSID)'), findsWidgets);
    });

    testWidgets('a section built for a non-English locale still renders',
        (tester) async {
      await tester.pumpWidget(wrap(
        'SystemResourceCard',
        {'cpuPercent': 42, 'memoryPercent': 63, 'uptime': '3d 4h'},
        locale: const Locale('zh', 'TW'),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      // cpu/memory/uptime are reused keys with zh_TW translations.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
