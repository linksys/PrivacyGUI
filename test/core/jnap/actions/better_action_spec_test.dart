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

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import 'better_action_resolution.dart';
import 'service_helper_gates.dart';

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

/// The gate of each action that needs one (no URL at the baseline, or a URL
/// only a newer service defines): the ServiceHelper check its call sites use,
/// an isServiceSupport gate. Every action that needs a gate is here, in
/// [_missingGates] or in [_noCaller]; service_helper_gates.dart says which
/// services each gate checks, and jnap_service_supported_test.dart that it
/// opens on them.
const _gateOf = <JNAPAction, String>{
  JNAPAction.getWANExternal: 'isSupportWANExternal',
  JNAPAction.clientDeauth: 'isSupportClientDeauth',
  JNAPAction.reboot2: 'isSupportChildReboot',
  JNAPAction.factoryReset2: 'isSupportChildFactoryReset',
  JNAPAction.getCloseHealthCheckServers: 'isSupportHealthCheckManager2',
  JNAPAction.getSTABSSIDs: 'isSupportGetSTABSSID',
  JNAPAction.getAutoIPoECapabilities: 'isSupportAutoIPoE',
  JNAPAction.getAutoIPoESettings: 'isSupportAutoIPoE',
  JNAPAction.setAutoIPoESettings: 'isSupportAutoIPoE',
  JNAPAction.applyAutoIPoE: 'isSupportAutoIPoE',
  JNAPAction.getAutoIPoEStatus: 'isSupportAutoIPoE',
  JNAPAction.getAutoIPoELog: 'isSupportAutoIPoE',
  JNAPAction.resetAutoIPoE: 'isSupportAutoIPoE',
};

/// Actions that need a gate and have none yet.
const _missingGates = <JNAPAction, String>{
  JNAPAction.getAutoMasterStatus: 'JNAPService has no Setup12, so there is '
      'no isServiceSupport gate for it; a #1923 PR adds both',
};

/// Actions that would need a gate, but that nothing in lib/ sends.
const _noCaller = <JNAPAction, String>{
  JNAPAction.execSysCommand:
      'a caller adds an isServiceSupport gate on Diagnostics9',
};

final _wellFormedUrl =
    RegExp(r'^http://linksys\.com/jnap/([a-z0-9]+/)+[A-Z][A-Za-z0-9]*$');

/// Whether a file of lib/ outside the action table sends [action].
bool _hasCaller(JNAPAction action) {
  final reference = RegExp('JNAPAction\\.${action.name}\\b');
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) =>
          file.path.endsWith('.dart') &&
          !file.path.contains('lib/core/jnap/actions/'))
      .any((file) => reference.hasMatch(file.readAsStringSync()));
}

void main() {
  stubTempDirectory();

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

  test('every action has a URL at the pin', () {
    // A router at the pin reports every service, so no action is left
    // without one.
    expect(
      [
        for (final action in JNAPAction.values)
          if (atPin[action.name] == null) action.name,
      ],
      isEmpty,
    );
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

  test('every action that needs a gate has one', () {
    // No URL at the baseline, or a URL only a newer service defines.
    final needsGate = {
      for (final action in JNAPAction.values)
        if (atBaseline[action.name] == null) action,
      ..._definedOnlyAfterBaseline.keys,
    };
    expect(
        needsGate, {..._gateOf.keys, ..._missingGates.keys, ..._noCaller.keys});
  });

  for (final MapEntry(key: action, value: gateName) in _gateOf.entries) {
    test(
      "${action.name}'s gate, $gateName, checks a service outside the "
      'baseline that defines it',
      () async {
        final services = serviceHelperGates[gateName]!
            .services
            .map((service) => service.value)
            .toList();
        expect(services.where(spec.baselineServices.contains), isEmpty,
            reason: 'a baseline service needs no gate');
        // With the gated services, the action has a URL one of them defines.
        final withGate =
            await resolveActions([...spec.appServicesAtBaseline, ...services]);
        final url = withGate[action.name];
        expect(url, isNotNull);
        expect(spec.definersOf(url!, services), isNotEmpty);
      },
      skip: _wrongService[action],
    );
  }

  for (final MapEntry(key: action, value: reason) in _missingGates.entries) {
    test(
      '${action.name} has an isServiceSupport gate on the service that '
      'defines it',
      () {
        final service = _definedOnlyAfterBaseline[action];
        expect(
          serviceHelperGates.values.where((gate) =>
              gate.services.any((candidate) => candidate.value == service)),
          isNotEmpty,
        );
      },
      skip: reason,
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
  );

  test('every listed exception still applies', () {
    final stale = [
      for (final MapEntry(key: action, value: service)
          in _definedOnlyAfterBaseline.entries)
        if (!undefinedAtBaseline(action) ||
            spec.baselineServices.contains(service) ||
            atPin[action.name] == null ||
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
      for (final action in _noCaller.keys)
        if (_hasCaller(action)) '_noCaller: ${action.name}',
    ];
    expect(stale, isEmpty);
  });
}
