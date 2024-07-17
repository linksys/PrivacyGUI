import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/single_port_forwarding_test_state.dart';
import '../../single_port_forwarding_list_view_test_mocks.dart';

@GenerateNiceMocks([
  MockSpec<SinglePortForwardingListNotifier>(),
])
void main() {
  late SinglePortForwardingListNotifier mockSinglePortForwardingListNotifier;

  setUp(() {
    mockSinglePortForwardingListNotifier =
        MockSinglePortForwardingListNotifier();
    when(mockSinglePortForwardingListNotifier.build()).thenReturn(
        SinglePortForwardingListState.fromMap(
            singlePortForwardingListTestState));
    when(mockSinglePortForwardingListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
    });
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
