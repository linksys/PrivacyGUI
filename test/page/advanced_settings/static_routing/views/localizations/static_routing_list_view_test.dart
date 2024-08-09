import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_list_view.dart';
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

  testLocalizations('Static routing list view test - 2 items',
      (tester, locale) async {
    when(mockStaticRoutingNotifier.build())
        .thenReturn(StaticRoutingState.fromMap(staticRoutingState3));
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      overrides: [
        staticRoutingProvider.overrideWith(() => mockStaticRoutingNotifier),
      ],
      locale: locale,
      child: const StaticRoutingListView(),
    );
    await tester.pumpWidget(widget);
  });
}
