// The Add Nodes route (route_add_nodes.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/nodes/views/add_nodes_view.dart';
import 'package:privacy_gui/route/constants.dart';

import 'app_route_builder.dart';

void main() {
  late AppRoutes routes;

  setUp(() => routes = AppRoutes());
  tearDown(() => routes.dispose());

  testWidgets('hands Add Nodes the arguments it was pushed with',
      (tester) async {
    final extra = <String, dynamic>{'mode': 'wired'};

    final built = await routes.build(tester, RouteNamed.addNodes, extra: extra);

    expect(built, isA<AddNodesView>());
    expect(argsOf(built), extra);
  });

  testWidgets('opened by its URL, hands Add Nodes no arguments',
      (tester) async {
    final built = await routes.build(tester, RouteNamed.addNodes);

    expect(argsOf(built), isEmpty);
  });
}
