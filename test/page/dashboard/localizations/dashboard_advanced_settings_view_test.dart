import 'package:privacy_gui/page/advanced_settings/advanced_settings_view.dart';
import 'package:privacy_gui/route/route_model.dart';


import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() {
  testLocalizations('Advanced Settings View', (tester, locale) async {
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [],
      locale: locale,
      child: const AdvancedSettingsView(),
    );
    await tester.pumpWidget(widget);
  });
}
