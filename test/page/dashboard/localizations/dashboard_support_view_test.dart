import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/page/support/faq_list_view.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/connectivity_notifier_mocks.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../test_data/_index.dart';

void main() async {
  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  Widget testableWidget(Locale locale) => testableRouteShellWidget(
        child: const FaqListView(),
        locale: locale,
        overrides: [],
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testLocalizations('Dashboard Support View - default', (tester, locale) async {
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
  }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

  testLocalizations('Dashboard Support View - expended',
      (tester, locale) async {
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
    final expansionCardFinder =
        find.byType(AppExpansionCard, skipOffstage: false);
    await tester.tap(expansionCardFinder.first);
    await tester.pumpAndSettle();
    await tester.tap(expansionCardFinder.at(1));
    await tester.pumpAndSettle();
    await tester.tap(expansionCardFinder.at(2));
    await tester.pumpAndSettle();
    await tester.tap(expansionCardFinder.at(3));
    await tester.pumpAndSettle();
    await tester.tap(expansionCardFinder.at(4));
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1600)).toList(),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1440)).toList()
  ]);
}
