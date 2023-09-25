
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_app/page/dashboard/view/topology/_topology.dart';
import 'package:linksys_app/provider/devices/topology_provider.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/topology/tree_item.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../common/testable_widget.dart';
import '../../../../test_data/topology_data.dart';
import 'topology_view_test.mocks.dart';


/// Please modify auto-generated file - 
/// class MockTopologyNotifier extends _i2.Notifier<_i3.TopologyState> with _i1.Mock implements _i4.TopologyNotifier (O)
/// class MockTopologyNotifier extends _i1.Mock implements _i4.TopologyNotifier (X)
///
@GenerateNiceMocks([MockSpec<TopologyNotifier>()])

void main() {
  late TopologyNotifier mockTopologyNotifier;

  setUp(() {
    mockTopologyNotifier = MockTopologyNotifier();
  });
  group('Topology view test - online nodes', () {
    testWidgets('topology view - 2 online nodes', (tester) async {
      when(mockTopologyNotifier.build())
          .thenReturn(testTopologyState1);

      final widget = testableWidget(overrides: [
        topologyProvider.overrideWith(() => mockTopologyNotifier),
      ], child: const TopologyView());
      await tester.pumpWidget(widget);

      // Find Build Context
      final BuildContext context = tester.element(find.byType(TopologyView));

      // Find by text
      final internetItem = find.text('Internet');
      // Find by icon
      final internetItemIcon =
          find.byIcon(getCharactersIcons(context).nodesDefault);
      // internet node check
      expect(internetItem, findsOneWidget);
      expect(internetItemIcon, findsOneWidget);

      // Find by type
      final treeNodeItems = find.byType(AppTreeNodeItem);
      // nodes check
      expect(treeNodeItems, findsNWidgets(2));

      // AppTreeNodeItem widget
      final node1Finder = find.widgetWithText(AppTreeNodeItem, 'Living room');
      final node1 = tester.firstWidget(node1Finder) as AppTreeNodeItem;

      expect(node1.name, 'Living room');
      expect(node1.count, 30);
      expect(node1.image, AppTheme.of(context).images.devices.routerMx6200);

      final node2Finder = find.widgetWithText(AppTreeNodeItem, 'Kitchen');
      final node2 = tester.firstWidget(node2Finder) as AppTreeNodeItem;
      expect(node2.name, 'Kitchen');
      expect(node2.count, 20);
      expect(node2.image, AppTheme.of(context).images.devices.routerMx6200);
    });

    testWidgets('topology view - 3 online nodes', (tester) async {
      when(mockTopologyNotifier.build())
          .thenReturn(testTopologyState2);

      final widget = testableWidget(overrides: [
        topologyProvider.overrideWith(() => mockTopologyNotifier),
      ], child: const TopologyView());
      await tester.pumpWidget(widget);

      // Find Build Context
      final BuildContext context = tester.element(find.byType(TopologyView));

      // Find by text
      final internetItem = find.text('Internet');
      // Find by icon
      final internetItemIcon =
          find.byIcon(getCharactersIcons(context).nodesDefault);
      // internet node check
      expect(internetItem, findsOneWidget);
      expect(internetItemIcon, findsOneWidget);

      // Find by type
      final treeNodeItems = find.byType(AppTreeNodeItem);
      // nodes check
      expect(treeNodeItems, findsNWidgets(3));

      // AppTreeNodeItem widget
      final node1Finder = find.widgetWithText(AppTreeNodeItem, 'Living room');
      final node1 = tester.firstWidget(node1Finder) as AppTreeNodeItem;

      expect(node1.name, 'Living room');
      expect(node1.count, 30);
      expect(node1.image, AppTheme.of(context).images.devices.routerMx6200);

      final node2Finder = find.widgetWithText(AppTreeNodeItem, 'Kitchen');
      final node2 = tester.firstWidget(node2Finder) as AppTreeNodeItem;
      expect(node2.name, 'Kitchen');
      expect(node2.count, 20);
      expect(node2.image, AppTheme.of(context).images.devices.routerMx6200);
    });
  });
}
