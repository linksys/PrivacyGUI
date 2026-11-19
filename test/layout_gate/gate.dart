/// #1802 P3's layout gate: what it runs, and what fails it.
library;

import 'dart:ui';

import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import '../common/config.dart';
import '../common/screen.dart';
import 'incident.dart';
import 'layout_cases.dart';

/// The sizes the gate runs a case at (#1802, Decision 7): the narrowest
/// mobile size the harness renders, the narrowest two desktop content boxes
/// (905 and 1241, both 841px), and a short desktop window.
const List<RequestedScreen> gateScreens = [
  (width: 480, height: null),
  (width: 905, height: null),
  (width: 1241, height: null),
  shortViewport,
];

/// The widths the gate has to run at, derived from [ResponsiveLayout]'s
/// breakpoints (#1802, Method 4): where the desktop content box is narrowest.
/// That is [ResponsiveLayout.medium], the first desktop width, where the
/// margin is still 24px, and the first width past [ResponsiveLayout.large],
/// where the margin jumps to 200px. Both boxes are 841px today.
Set<double> requiredGateWidths() =>
    {ResponsiveLayout.medium, ResponsiveLayout.large + 1};

/// The short desktop window the gate runs at.
const RequestedScreen shortViewport = (width: 1280, height: 420);

/// The locales the gate runs a case in when no locale is asked for
/// (#1802, Decision 7). Together they find every incident the 26 locales do.
const List<String> gateLocales = ['ja', 'ru', 'el', 'nl', 'de'];

/// Cases the gate keeps off [shortViewport] (#1802, Decision 9): at 420px they
/// tap a widget that is off screen, so they fail before any layout is checked.
/// They still run at the other gate sizes. An entry can go once its case
/// scrolls to what it taps; an entry whose case no longer exists fails
/// `gate_test.dart`.
const Set<String> shortViewportSkips = {
  // advanced_settings/apps_and_gaming/views/localizations/apps_and_gaming_view_test.dart
  'Port range forwarding - edit error',
  'Port range forwarding - edit filled up',
  'Port range forwarding - edit overlap error',
  'Port range forwarding - protocol',
  'Port range triggerring - edit error',
  'Port range triggerring - edit filled up',
  'Port range triggerring - edit overlap error',
  'Single port forwarding - edit filled up',
  'Single port forwarding - edit overlap error',
  // advanced_settings/firewall/views/localizations/firewall_view_test.dart
  'Firewall settings view - IPv6 port service - add rule - invalid ports',
  'Firewall settings view - IPv6 port service - add rule - protocol dropdown',
  // advanced_settings/static_routing/views/localizations/static_routing_view_test.dart
  'Static routing view test - NAT enabled add rule - interface dropdown',
  'Static routing view test - NAT enabled add rule - invalid gateway IP',
  // dashboard/localizations/dashboard_support_view_test.dart
  'Dashboard Support View - expended',
  // instant_setup/troubleshooter/views/isp_settings/localizations/pnp_static_ip_view_test.dart
  'Troubleshooter - PnP static IP: wrong input formats',
  // instant_topology/localizations/add_wired_node_view_test.dart
  'Instant-Topology view - add wired node failed',
  'Instant-Topology view - add wired node processing',
  'Instant-Topology view - add wired node success',
  // instant_topology/localizations/instant_topology_view_test.dart
  'Instant-Topology view - factory reset child alert ',
  'Instant-Topology view - factory reset parent alert ',
  'Instant-Topology view - reboot child alert ',
  'Instant-Topology view - reboot parent alert ',
  // wifi_settings/views/localizations/wifi_main_view_test.dart
  'Incredible-WiFi - Wifi list view - edit SSID - empty error',
  'Incredible-WiFi - Wifi list view - edit SSID - length error',
  'Incredible-WiFi - Wifi list view - edit SSID - surround space error',
  'Incredible-WiFi - Wifi list view - edit password - error state',
};

/// The sizes the gate runs a case at: each of [gateScreens] in a layout the
/// case renders ([measuringScreensFor]), except [shortViewport] for a case on
/// [shortViewportSkips].
List<ScreenSize> gateScreensFor(String caseName, List<ScreenSize> caseScreens) {
  final skipShort = shortViewportSkips.contains(caseName);
  return measuringScreensFor(caseScreens, [
    for (final s in gateScreens)
      if (!skipShort || s != shortViewport) s,
  ]);
}

/// The locales the gate runs a case in, out of [caseLocales], those the case
/// renders: all of them when the `locales` define picked them ([configured]),
/// as each CI job does, or else the ones among [gateLocales].
List<Locale> gateLocalesFor(List<Locale> caseLocales,
    {required bool configured}) {
  if (configured) return caseLocales;
  final byTag = {for (final l in caseLocales) l.toLanguageTag(): l};
  return [
    for (final tag in gateLocales)
      if (byTag[tag] case final locale?) locale,
  ];
}

/// The overflows that fail the gate: those over [kOverflowTolerancePx], and
/// those whose amount could not be read.
List<OverflowIncident> gateFailures(List<OverflowIncident> incidents) =>
    [for (final i in incidents) if (i.pixels > kOverflowTolerancePx) i];

/// The failure message for [failures] in one case at one size and locale: one
/// line per overflow, with its site, so it can be found without a screenshot.
String describeGateFailures(
  List<OverflowIncident> failures, {
  required String caseName,
  required String size,
  required String locale,
}) {
  final lines = [
    for (final f in failures)
      '  - ${f.site ?? '(outside the repository)'}: '
          '${f.widget ?? 'a widget'} overflowed by '
          '${f.pixels.toStringAsFixed(1)}px on the ${f.side}',
  ];
  return '"$caseName" at $size in $locale overflows by more than '
      '${kOverflowTolerancePx}px (constitution 3.3, #1802):\n'
      '${lines.join('\n')}';
}
