// Checks the app's JNAP action table against the spec that 1.x firmware
// builds (#1923): test/test_data/jnap_spec.json, written by
// test_scripts/jnap_spec_snapshot.dart from linksys/JNAP at the commit
// feed_linksys pins.
//
// Two service sets matter. A router reports every service its JNAP defines,
// so "defined" below means defined by any service of that set, whether the
// app's JNAPService lists it or not.
// - The baseline: the services of the JNAP release in the oldest firmware 1.x
//   still supports. They need no gate. Provisional: tag 1.0.0 (#1923).
// - The pin: the services of the JNAP that firmware builds today.
// The JSON holds each service's actions at the pin only. The generator stops
// if a baseline service lists different actions at the baseline, so the pin's
// lists stand for both.
//
// Each map below lists the known exceptions to one rule, with the reason. A
// map only shrinks: "every listed exception still applies" fails on an entry
// that no longer does, so a fix deletes its entry.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';

import '../../../../test_scripts/better_action_snapshot.dart';

const _jnap = 'http://linksys.com/jnap/';

/// Actions the baseline sends, through the seed, that only a service newer
/// than the baseline defines: a router at the baseline answers
/// `_ErrorUnknownAction`. Their call sites need a gate. Each entry is the
/// service that defines the action at the pin.
const _definedOnlyAfterBaseline = {
  'reboot2': '${_jnap}core/Core8',
  'factoryReset2': '${_jnap}core/Core9',
  'execSysCommand': '${_jnap}diagnostics/Diagnostics9',
  'getCloseHealthCheckServers': '${_jnap}healthcheck/HealthCheckManager2',
  'getSTABSSIDs': '${_jnap}macfilter/MACFilter2',
  'getAutoIPoECapabilities': '${_jnap}autoipoe/AutoIPoE',
  'getAutoIPoESettings': '${_jnap}autoipoe/AutoIPoE',
  'setAutoIPoESettings': '${_jnap}autoipoe/AutoIPoE',
  'applyAutoIPoE': '${_jnap}autoipoe/AutoIPoE',
  'getAutoIPoEStatus': '${_jnap}autoipoe/AutoIPoE',
  'getAutoIPoELog': '${_jnap}autoipoe/AutoIPoE',
  'resetAutoIPoE': '${_jnap}autoipoe/AutoIPoE',
  // JNAPService has no Setup12, so the app cannot gate this on its service.
  'getAutoMasterStatus': '${_jnap}nodes/setup/Setup12',
};

/// Actions whose URL no service of the pinned linksys/JNAP defines.
const _notInSpec = {
  'transaction': 'the JNAP transaction endpoint; no service lists it',
  // linksys/JNAP has no vpn namespace at all. The VPN module comes from
  // another feed; which one is not checked (#1923).
  'setVPNUser': 'VPN is not in linksys/JNAP',
  'getVPNUser': 'VPN is not in linksys/JNAP',
  'setVPNGateway': 'VPN is not in linksys/JNAP',
  'getVPNGateway': 'VPN is not in linksys/JNAP',
  'setVPNService': 'VPN is not in linksys/JNAP',
  'getVPNService': 'VPN is not in linksys/JNAP',
  'testVPNConnection': 'VPN is not in linksys/JNAP',
  'getTunneledUser': 'VPN is not in linksys/JNAP',
  'setTunneledUser': 'VPN is not in linksys/JNAP',
  'setVPNApply': 'VPN is not in linksys/JNAP',
};

/// Actions whose URL is malformed. Nothing calls them today.
const _malformedUrl = {
  'getGamingPrioritizationSettings':
      'ends in ":" (jnap_action_value.dart:108); the spec action is '
          'GetGamingPrioritizationSettings (#1923)',
};

/// Actions the app sends at the pin under a service that does not define them.
const _wrongService = {
  'getWANExternal': 'upgraded under Router13, which does not define it (#1906)',
};

/// The gate for each action that has no URL at the baseline: the
/// ServiceHelper check its call sites use, and the service it checks.
final _gates = <String, (bool Function(List<String>), String)>{
  'getWANExternal': (
    (services) => ServiceHelper().isSupportWANExternal(services),
    '${_jnap}router/Router13',
  ),
  'clientDeauth': (
    (services) => ServiceHelper().isSupportClientDeauth(services),
    '${_jnap}wirelessap/WirelessAP5',
  ),
};

/// Gates known to answer wrong, with the issue that fixes them.
const _brokenGates = {
  'getWANExternal': 'isSupportWANExternal ignores its services argument; '
      '#1906 deletes it',
};

final _wellFormedUrl =
    RegExp(r'^http://linksys\.com/jnap/([a-z0-9]+/)+[A-Z][A-Za-z0-9]*$');

void main() {
  // isServiceSupport reads the cache manager before it looks at the services
  // it is given, and the cache manager reaches for the temp directory. #1923's
  // P2 (one holder of the router's services) makes this unnecessary.
  //
  // The directory is this file's own: other suites write their cache file
  // into the shared system temp directory.
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('better_action_spec_');
  tearDownAll(() => tempDir.deleteSync(recursive: true));
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => tempDir.path,
  );

  final spec =
      jsonDecode(File('test/test_data/jnap_spec.json').readAsStringSync())
          as Map<String, dynamic>;
  final pinServices = (spec['services'] as Map<String, dynamic>)
      .map((service, actions) => MapEntry(service, Set<String>.from(actions)));
  final baselineServices = Set<String>.from(spec['baselineServices']);
  final appServices = JNAPService.values.map((s) => s.value).toList();

  // What the app resolves for a router that reports exactly these services.
  // buildBetterActions ignores the services JNAPService does not list.
  final atBaseline =
      resolveActions(appServices.where(baselineServices.contains).toList());
  final atPin =
      resolveActions(appServices.where(pinServices.containsKey).toList());
  final everywhere = resolveActions(appServices);

  /// The services, among [services], whose spec defines the action at [url].
  List<String> definersOf(String url, Iterable<String> services) {
    final slash = url.lastIndexOf('/');
    final namespace = url.substring(0, slash + 1);
    final name = url.substring(slash + 1);
    return [
      for (final service in services)
        if (service.startsWith(namespace) &&
            !service.substring(namespace.length).contains('/') &&
            (pinServices[service]?.contains(name) ?? false))
          service,
    ];
  }

  final allPin = pinServices.keys;
  final allBaseline = allPin.where(baselineServices.contains);

  test(
      'an action with no URL at the baseline is one no baseline service '
      'defines', () {
    final wrong = [
      for (final MapEntry(key: action, value: url) in atBaseline.entries)
        if (url == null && everywhere[action] != null)
          for (final definer in definersOf(everywhere[action]!, allBaseline))
            '$action: ${everywhere[action]} is defined by $definer',
    ];
    expect(wrong, isEmpty);
  });

  test('what the app sends at the baseline, a baseline service defines', () {
    final undefined = [
      for (final MapEntry(key: action, value: url) in atBaseline.entries)
        if (url != null &&
            definersOf(url, allBaseline).isEmpty &&
            !_definedOnlyAfterBaseline.containsKey(action) &&
            !_notInSpec.containsKey(action) &&
            !_malformedUrl.containsKey(action))
          '$action: $url',
    ];
    expect(undefined, isEmpty);
  });

  test('what the app sends at the pin, a pin service defines', () {
    final undefined = [
      for (final MapEntry(key: action, value: url) in atPin.entries)
        if (url != null &&
            definersOf(url, allPin).isEmpty &&
            !_notInSpec.containsKey(action) &&
            !_malformedUrl.containsKey(action) &&
            !_wrongService.containsKey(action))
          '$action: $url',
    ];
    expect(undefined, isEmpty);
  });

  test('every URL the app can resolve is well formed', () {
    final malformed = <String>{
      for (final services in [
        const <String>[],
        ...appServices.map((service) => [service]),
      ])
        for (final MapEntry(key: action, value: url)
            in resolveActions(services).entries)
          if (url != null &&
              !_wellFormedUrl.hasMatch(url) &&
              !_malformedUrl.containsKey(action))
            '$action: $url',
    };
    expect(malformed, isEmpty);
  });

  test('every action with no URL at the baseline has a gate', () {
    final unresolved = [
      for (final MapEntry(key: action, value: url) in atBaseline.entries)
        if (url == null) action,
    ];
    expect(unresolved.toSet(), _gates.keys.toSet());
  });

  for (final MapEntry(key: action, value: (gate, service)) in _gates.entries) {
    test(
      "$action's gate opens on ${service.split('/').last} and stays shut at "
      'the baseline',
      () {
        expect(baselineServices.contains(service), isFalse,
            reason: 'a baseline service needs no gate');
        expect(gate([service]), isTrue);
        expect(gate(appServices.where(baselineServices.contains).toList()),
            isFalse);
      },
      skip: _brokenGates[action],
    );
  }

  test('every listed exception still applies', () {
    final stale = <String>[
      for (final MapEntry(key: action, value: service)
          in _definedOnlyAfterBaseline.entries)
        if (atBaseline[action] == null ||
            definersOf(atBaseline[action]!, allBaseline).isNotEmpty ||
            !definersOf(atBaseline[action]!, allPin).contains(service) ||
            baselineServices.contains(service))
          '_definedOnlyAfterBaseline: $action',
      for (final action in _notInSpec.keys)
        if (everywhere[action] == null ||
            definersOf(everywhere[action]!, allPin).isNotEmpty)
          '_notInSpec: $action',
      for (final action in _malformedUrl.keys)
        if (everywhere[action] == null ||
            _wellFormedUrl.hasMatch(everywhere[action]!))
          '_malformedUrl: $action',
      for (final action in _wrongService.keys)
        if (atPin[action] == null ||
            definersOf(atPin[action]!, allPin).isNotEmpty)
          '_wrongService: $action',
      for (final action in _brokenGates.keys)
        if (!_gates.containsKey(action)) '_brokenGates: $action',
    ];
    expect(stale, isEmpty);
  });
}
