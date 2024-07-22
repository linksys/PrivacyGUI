import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';


void main() {
  
  testLocalizations('Port settings view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PortForwardingView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });
}
