import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/port_range_forwarding_test_state.dart';
import '../../../../../mocks/port_range_forwarding_list_notifier_mocks.dart';

void main() {
  late PortRangeForwardingListNotifier mockPortRangeForwardingListNotifier;

  setUp(() {
    mockPortRangeForwardingListNotifier = MockPortRangeForwardingListNotifier();
    when(mockPortRangeForwardingListNotifier.build()).thenReturn(
        PortRangeForwardingListState.fromMap(portRangeForwardingListTestState));
    when(mockPortRangeForwardingListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
    });
  });

  testLocalizations('Port range forwarding list view - empty rule',
      (tester, locale) async {
    when(mockPortRangeForwardingListNotifier.build()).thenReturn(
        PortRangeForwardingListState.fromMap(
            portRangeForwardingEmptyListTestState));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PortRangeForwardingListView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Port range forwarding list view - with rules',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PortRangeForwardingListView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
