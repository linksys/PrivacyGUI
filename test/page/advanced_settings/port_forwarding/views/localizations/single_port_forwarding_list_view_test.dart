import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/single_port_forwarding_test_state.dart';
import '../../../../../mocks/single_port_forwarding_list_notifier_mocks.dart';

void main() {
  late SinglePortForwardingListNotifier mockSinglePortForwardingListNotifier;

  setUp(() {
    mockSinglePortForwardingListNotifier =
        MockSinglePortForwardingListNotifier();
    when(mockSinglePortForwardingListNotifier.build()).thenReturn(
        SinglePortForwardingListState.fromMap(
            singlePortForwardingListTestState));
  });

  testLocalizations('Single port forwarding list view - empty rule', (tester, locale) async {
    when(mockSinglePortForwardingListNotifier.build()).thenReturn(
        SinglePortForwardingListState.fromMap(
            singlePortForwardingEmptyListTestState));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SinglePortForwardingListView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Single port forwarding list view - with rules', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SinglePortForwardingListView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
