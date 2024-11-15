import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_rule_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/static_routing_state.dart';
import '../../../../../mocks/static_routing_notifier_mocks.dart';

void main() {
  late MockStaticRoutingNotifier mockStaticRoutingNotifier;

  setUp(() {
    mockStaticRoutingNotifier = MockStaticRoutingNotifier();
  });

  testLocalizations('Static routing detail view test - Add new item',
      (tester, locale) async {
    when(mockStaticRoutingNotifier.build())
        .thenReturn(StaticRoutingState.empty());
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      overrides: [
        staticRoutingProvider.overrideWith(() => mockStaticRoutingNotifier),
      ],
      locale: locale,
      child: const StaticRoutingRuleView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('Static routing detail view test - Edit LAN interface item',
      (tester, locale) async {
    when(mockStaticRoutingNotifier.build())
        .thenReturn(StaticRoutingState.empty());
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      overrides: [
        staticRoutingProvider.overrideWith(() => mockStaticRoutingNotifier),
      ],
      locale: locale,
      child: StaticRoutingRuleView(
        args: {
          'currentSetting': NamedStaticRouteEntry.fromMap(staticRoutingItem1),
        },
      ),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations(
      'Static routing detail view test - Edit Internet interface item',
      (tester, locale) async {
    when(mockStaticRoutingNotifier.build())
        .thenReturn(StaticRoutingState.empty());
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      overrides: [
        staticRoutingProvider.overrideWith(() => mockStaticRoutingNotifier),
      ],
      locale: locale,
      child: StaticRoutingRuleView(
        args: {
          'currentSetting': NamedStaticRouteEntry.fromMap(staticRoutingItem1),
        },
      ),
    );
    await tester.pumpWidget(widget);
  });
}
