// A port-range triggering rules read the router refuses (#1974).
//
// The read throws, as the port-range forwarding read does, so that Apps &
// Gaming can tell a list it could not read from a router with no rules.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_list_provider.dart';

import '../../../../../common/router_boundary.dart';

const _game = <String, dynamic>{
  'isEnabled': true,
  'firstTriggerPort': 12000,
  'lastTriggerPort': 12050,
  'firstForwardedPort': 12000,
  'lastForwardedPort': 12050,
  'description': 'game',
};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late PortRangeTriggeringListNotifier notifier;

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getPortRangeTriggeringRules, {
        'rules': [_game],
        'maxRules': 50,
        'maxDescriptionLength': 32,
      });
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(portRangeTriggeringListProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('reports a refused rules read, and keeps the rules it showed', () async {
    await notifier.fetch();
    router.refuses(JNAPAction.getPortRangeTriggeringRules);

    await expectLater(
      notifier.fetch(),
      throwsA(isA<JNAPError>()
          .having((error) => error.result, 'result', 'ErrorUnknown')),
    );

    expect(container.read(portRangeTriggeringListProvider).rules,
        [PortRangeTriggeringRule.fromMap(_game)]);
  });
}
