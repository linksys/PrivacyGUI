// A single-port rules read the router refuses (#1974).
//
// The read throws, as the port-range forwarding read does, so that Apps &
// Gaming can tell a list it could not read from a router with no rules.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_provider.dart';

import '../../../../../common/router_boundary.dart';
import '../../_router_lan_settings.dart';

const _xbox = <String, dynamic>{
  'isEnabled': true,
  'externalPort': 3074,
  'protocol': 'TCP',
  'internalServerIPAddress': '192.168.1.150',
  'internalPort': 3074,
  'description': 'XBox Live (TM)',
};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late SinglePortForwardingListNotifier notifier;

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getLANSettings, routerLanSettings)
      ..holds(JNAPAction.getSinglePortForwardingRules, {
        'rules': [_xbox],
        'maxRules': 50,
        'maxDescriptionLength': 32,
      });
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(singlePortForwardingListProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('reports a refused rules read, and keeps the rules it showed', () async {
    await notifier.fetch();
    router.refuses(JNAPAction.getSinglePortForwardingRules);

    await expectLater(
      notifier.fetch(),
      throwsA(isA<JNAPError>()
          .having((error) => error.result, 'result', 'ErrorUnknown')),
    );

    expect(container.read(singlePortForwardingListProvider).rules,
        [SinglePortForwardingRule.fromMap(_xbox)]);
  });
}
