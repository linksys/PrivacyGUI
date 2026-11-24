// Checks the app's JNAP action table against the spec that 1.x firmware
// builds (#1923): test/test_data/jnap_spec.json, written by
// test_scripts/jnap_spec_snapshot.dart from linksys/JNAP at the commit
// feed_linksys pins.
//
// Two service sets matter. A router reports every service its JNAP defines,
// whether the app's JNAPService lists it or not.
// - The baseline: the services of the JNAP release in the oldest firmware 1.x
//   still supports. They need no gate. Provisional: tag 1.0.0 (#1923).
// - The pin: the services of the JNAP that firmware builds today.
//
// "Defined" is exact: a URL an upgrade gives must be in the list of the
// service that upgrades to it. Only a URL from the seed, which no service
// gives, counts as defined by any service of the set.
//
// Each map below lists the known exceptions to one rule, with the reason. A
// map only shrinks: "every listed exception still applies" fails on an entry
// that no longer does, so a fix deletes its entry.
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';

import 'better_action_resolution.dart';

const _jnap = 'http://linksys.com/jnap/';

/// Actions the baseline sends, through the seed, that only a service newer
/// than the baseline defines: a router at the baseline answers
/// `_ErrorUnknownAction`. Their call sites need a gate. Each entry is the
/// service that defines the action at the pin.
const _definedOnlyAfterBaseline = <JNAPAction, String>{
  JNAPAction.reboot2: '${_jnap}core/Core8',
  JNAPAction.factoryReset2: '${_jnap}core/Core9',
  JNAPAction.execSysCommand: '${_jnap}diagnostics/Diagnostics9',
  JNAPAction.getCloseHealthCheckServers:
      '${_jnap}healthcheck/HealthCheckManager2',
  JNAPAction.getSTABSSIDs: '${_jnap}macfilter/MACFilter2',
  JNAPAction.getAutoIPoECapabilities: '${_jnap}autoipoe/AutoIPoE',
  JNAPAction.getAutoIPoESettings: '${_jnap}autoipoe/AutoIPoE',
  JNAPAction.setAutoIPoESettings: '${_jnap}autoipoe/AutoIPoE',
  JNAPAction.applyAutoIPoE: '${_jnap}autoipoe/AutoIPoE',
  JNAPAction.getAutoIPoEStatus: '${_jnap}autoipoe/AutoIPoE',
  JNAPAction.getAutoIPoELog: '${_jnap}autoipoe/AutoIPoE',
  JNAPAction.resetAutoIPoE: '${_jnap}autoipoe/AutoIPoE',
  // JNAPService has no Setup12, so the app cannot gate this on its service.
  JNAPAction.getAutoMasterStatus: '${_jnap}nodes/setup/Setup12',
};

/// Actions whose URL no service of the pinned linksys/JNAP defines.
const _notInSpec = <JNAPAction, String>{
  JNAPAction.transaction: 'the JNAP transaction endpoint; no service lists it',
  // linksys/JNAP has no vpn namespace at all. The VPN module comes from
  // another feed; which one is not checked (#1923).
  JNAPAction.setVPNUser: 'VPN is not in linksys/JNAP',
  JNAPAction.getVPNUser: 'VPN is not in linksys/JNAP',
  JNAPAction.setVPNGateway: 'VPN is not in linksys/JNAP',
  JNAPAction.getVPNGateway: 'VPN is not in linksys/JNAP',
  JNAPAction.setVPNService: 'VPN is not in linksys/JNAP',
  JNAPAction.getVPNService: 'VPN is not in linksys/JNAP',
  JNAPAction.testVPNConnection: 'VPN is not in linksys/JNAP',
  JNAPAction.getTunneledUser: 'VPN is not in linksys/JNAP',
  JNAPAction.setTunneledUser: 'VPN is not in linksys/JNAP',
  JNAPAction.setVPNApply: 'VPN is not in linksys/JNAP',
};

/// Actions whose URL is malformed. Nothing calls them today.
const _malformedUrl = <JNAPAction, String>{
  JNAPAction.getGamingPrioritizationSettings:
      'ends in ":" (jnap_action_value.dart:108); the spec action is '
          'GetGamingPrioritizationSettings (#1923)',
};

/// Actions the app sends at the pin under a service that does not define them.
const _wrongService = <JNAPAction, String>{
  JNAPAction.getWANExternal:
      'upgraded under Router13, which does not define it (#1906)',
};

/// The gate of an action that has no URL at the baseline: the ServiceHelper
/// check its call sites use, and the service it checks.
typedef _Gate = ({bool Function(List<String>) isOpen, String service});

final _gates = <JNAPAction, _Gate>{
  JNAPAction.getWANExternal: (
    isOpen: (services) => ServiceHelper().isSupportWANExternal(services),
    service: '${_jnap}router/Router13',
  ),
  JNAPAction.clientDeauth: (
    isOpen: (services) => ServiceHelper().isSupportClientDeauth(services),
    service: '${_jnap}wirelessap/WirelessAP5',
  ),
};

/// Gates known to answer wrong, with the issue that fixes them.
const _brokenGates = <JNAPAction, String>{
  JNAPAction.getWANExternal:
      'isSupportWANExternal ignores its services argument; #1906 deletes it',
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

  final spec = JnapSpec.load();

  // Each resolves from a fresh start; see resolveActions.
  late final Map<String, String?> seed;
  late final Map<String, String?> atBaseline;
  late final Map<String, String?> atPin;
  late final Map<String, String?> atAllAppServices;
  late final Map<String, Map<String, String?>> byServiceAlone;

  setUpAll(() async {
    [seed, atBaseline, atPin, atAllAppServices] = await Future.wait([
      resolveActions(const []),
      resolveActions(spec.appServicesAtBaseline),
      resolveActions(spec.appServicesAtPin),
      resolveActions(appServices),
    ]);
    final alone =
        await Future.wait(appServices.map((s) => resolveActions([s])));
    byServiceAlone = Map.fromIterables(appServices, alone);
  });

  /// Whether the spec defines [url], which [action] resolves to for a router
  /// that reports [specServices] (of which the app knows [appServicesIn]).
  bool isDefined(JNAPAction action, String url, Iterable<String> specServices,
      Iterable<String> appServicesIn) {
    if (url == seed[action.name]) {
      return spec.definersOf(url, specServices).isNotEmpty;
    }
    // The services that, on their own, upgrade the action to this URL.
    final upgraders = appServicesIn
        .where((service) => byServiceAlone[service]![action.name] == url);
    return upgraders.any((service) => spec.defines(service, url));
  }

  bool undefinedAtBaseline(JNAPAction action) {
    final url = atBaseline[action.name];
    return url != null &&
        !isDefined(action, url, spec.atBaseline, spec.appServicesAtBaseline);
  }

  bool undefinedAtPin(JNAPAction action) {
    final url = atPin[action.name];
    return url != null &&
        !isDefined(action, url, spec.atPin, spec.appServicesAtPin);
  }

  Iterable<String> urlsOf(JNAPAction action) => {
        seed[action.name],
        for (final resolved in byServiceAlone.values) resolved[action.name],
      }.whereType<String>();

  bool hasMalformedUrl(JNAPAction action) =>
      urlsOf(action).any((url) => !_wellFormedUrl.hasMatch(url));

  test(
      'an action with no URL at the baseline is one no baseline service '
      'defines', () {
    final wrong = [
      for (final action in JNAPAction.values)
        if (atBaseline[action.name] == null &&
            atAllAppServices[action.name] != null)
          for (final definer in spec.definersOf(
              atAllAppServices[action.name]!, spec.atBaseline))
            '${action.name}: ${atAllAppServices[action.name]} is defined by '
                '$definer',
    ];
    expect(wrong, isEmpty);
  });

  test('what the app sends at the baseline, the baseline defines', () {
    final undefined = [
      for (final action in JNAPAction.values)
        if (undefinedAtBaseline(action) &&
            !_definedOnlyAfterBaseline.containsKey(action) &&
            !_notInSpec.containsKey(action) &&
            !_malformedUrl.containsKey(action))
          '${action.name}: ${atBaseline[action.name]}',
    ];
    expect(undefined, isEmpty);
  });

  test('what the app sends at the pin, the pin defines', () {
    final undefined = [
      for (final action in JNAPAction.values)
        if (undefinedAtPin(action) &&
            !_notInSpec.containsKey(action) &&
            !_malformedUrl.containsKey(action) &&
            !_wrongService.containsKey(action))
          '${action.name}: ${atPin[action.name]}',
    ];
    expect(undefined, isEmpty);
  });

  test('every URL the app can resolve is well formed', () {
    final malformed = [
      for (final action in JNAPAction.values)
        if (hasMalformedUrl(action) && !_malformedUrl.containsKey(action))
          '${action.name}: ${urlsOf(action).join(', ')}',
    ];
    expect(malformed, isEmpty);
  });

  test('every action with no URL at the baseline has a gate', () {
    final unresolved = [
      for (final action in JNAPAction.values)
        if (atBaseline[action.name] == null) action,
    ];
    expect(unresolved.toSet(), _gates.keys.toSet());
  });

  for (final MapEntry(key: action, value: gate) in _gates.entries) {
    final name = gate.service.split('/').last;

    test("${action.name}'s upgrade comes with $name, outside the baseline",
        () async {
      expect(spec.baselineServices.contains(gate.service), isFalse,
          reason: 'a baseline service needs no gate');
      final withService =
          await resolveActions([...spec.appServicesAtBaseline, gate.service]);
      expect(withService[action.name], isNotNull);
    });

    test(
      "${action.name}'s gate opens on $name and stays shut at the baseline",
      () {
        expect(gate.isOpen([gate.service]), isTrue);
        expect(gate.isOpen(spec.appServicesAtBaseline), isFalse);
      },
      skip: _brokenGates[action],
    );
  }

  test(
    "one router's services leave no URL behind for the next router",
    () async {
      // The app calls buildBetterActions again after each login and network
      // switch, in the same isolate.
      final pin = spec.appServicesAtPin;
      final baseline = spec.appServicesAtBaseline;
      final afterPin = await Isolate.run(() {
        resolveActionsHere(pin);
        return resolveActionsHere(baseline);
      });
      expect(afterPin, atBaseline);
    },
    skip: 'initBetterActions does not clear what an earlier call mapped, so '
        'getWANExternal and clientDeauth keep the last router\'s URL (#1923)',
  );

  test('every listed exception still applies', () {
    final stale = [
      for (final MapEntry(key: action, value: service)
          in _definedOnlyAfterBaseline.entries)
        if (!undefinedAtBaseline(action) ||
            spec.baselineServices.contains(service) ||
            !spec.defines(service, atPin[action.name]!))
          '_definedOnlyAfterBaseline: ${action.name}',
      for (final action in _notInSpec.keys)
        if (atAllAppServices[action.name] == null ||
            spec
                .definersOf(atAllAppServices[action.name]!, spec.atPin)
                .isNotEmpty)
          '_notInSpec: ${action.name}',
      for (final action in _malformedUrl.keys)
        if (!hasMalformedUrl(action)) '_malformedUrl: ${action.name}',
      for (final action in _wrongService.keys)
        if (!undefinedAtPin(action)) '_wrongService: ${action.name}',
      for (final action in _brokenGates.keys)
        if (!_gates.containsKey(action)) '_brokenGates: ${action.name}',
    ];
    expect(stale, isEmpty);
  });
}
