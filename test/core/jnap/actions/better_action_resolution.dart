// What the #1923 tests share with test_scripts/better_action_snapshot.dart:
// how an action set is resolved, and the JNAP spec they check it against.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:privacy_gui/core/jnap/actions/better_action.dart';

const snapshotPath = 'test/test_data/better_action_snapshot.json';
const specPath = 'test/test_data/jnap_spec.json';

/// The name of the snapshot input that holds [service] on its own.
String onlyInput(String service) => 'only: $service';

/// The URL each action resolves to for a router that reports [services], or
/// null where it resolves to none. No service at all gives the seed.
///
/// Each call runs in a new isolate, so it starts from the state the app
/// starts with: initBetterActions does not clear what an earlier call
/// mapped, so in one isolate the result would depend on earlier calls (#1923).
Future<Map<String, String?>> resolveActions(List<String> services) =>
    Isolate.run(() => resolveActionsHere(services));

/// [resolveActions] in this isolate, on top of whatever earlier calls mapped.
///
/// It goes through what the app calls: initBetterActions, buildBetterActions
/// and JNAPAction.actionValue.
Map<String, String?> resolveActionsHere(List<String> services) {
  if (services.isEmpty) {
    initBetterActions();
  } else {
    buildBetterActions(services);
  }
  return {for (final action in JNAPAction.values) action.name: _urlOf(action)};
}

String? _urlOf(JNAPAction action) {
  try {
    return action.actionValue;
  } on TypeError {
    // actionValue is `_betterActionMap[this]!`: an action with no URL throws.
    return null;
  }
}

/// The app's services, as GetDeviceInfo reports them, in JNAPService order.
List<String> get appServices => JNAPService.values.map((s) => s.value).toList();

/// test/test_data/jnap_spec.json: the JNAP spec that 1.x firmware builds,
/// written by test_scripts/jnap_spec_snapshot.dart.
class JnapSpec {
  JnapSpec._(this.actionsByService, this.baselineServices, this.pinCommit,
      this.baselineRef);

  factory JnapSpec.load() {
    final json = jsonDecode(File(specPath).readAsStringSync()) as Map;
    return JnapSpec._(
      (json['services'] as Map).map((service, actions) =>
          MapEntry('$service', Set<String>.from(actions as List))),
      Set<String>.from(json['baselineServices'] as List),
      (json['pin'] as Map)['commit'] as String,
      (json['baseline'] as Map)['ref'] as String,
    );
  }

  /// Every service of the pin, keyed by its URL, with the actions it defines.
  /// The generator checks that a baseline service defines the same actions
  /// at the baseline, so these lists stand for both.
  final Map<String, Set<String>> actionsByService;

  /// The services of the baseline release, which need no gate.
  final Set<String> baselineServices;

  final String pinCommit;
  final String baselineRef;

  /// The services a router at the baseline, or at the pin, reports.
  Iterable<String> get atBaseline =>
      actionsByService.keys.where(baselineServices.contains);
  Iterable<String> get atPin => actionsByService.keys;

  /// The app's services among those: what buildBetterActions acts on.
  List<String> get appServicesAtBaseline =>
      appServices.where(baselineServices.contains).toList();
  List<String> get appServicesAtPin =>
      appServices.where(actionsByService.containsKey).toList();

  /// Whether [service] defines the action at [url]: they share a namespace,
  /// and the action is in the service's list.
  bool defines(String service, String url) {
    final namespace = url.substring(0, url.lastIndexOf('/') + 1);
    return service.substring(0, service.lastIndexOf('/') + 1) == namespace &&
        (actionsByService[service]?.contains(url.substring(namespace.length)) ??
            false);
  }

  /// The services among [services] that define the action at [url].
  List<String> definersOf(String url, Iterable<String> services) => [
        for (final service in services)
          if (defines(service, url)) service
      ];
}
