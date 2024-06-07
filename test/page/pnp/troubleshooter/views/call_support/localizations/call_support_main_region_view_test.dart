import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/call_support/call_support_main_region_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/isp_settings/pnp_pppoe_view.dart';

import 'package:privacy_gui/page/pnp/data/pnp_state.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/isp_settings/pnp_static_ip_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

import '../../../../../../common/mock_firebase_messaging.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';
import '../../../../../../test_data/device_info_test_data.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';
import '../../../../pnp_admin_view_test_mocks.dart' as Mock;
import '../../../../pnp_isp_type_selection_view_test_mocks.dart';

void main() async {
  setupFirebaseMessagingMocks();
  await Firebase.initializeApp();

  setUp(() {});

  testLocalizations('call support view - main', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMainRegionView(),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });
  testLocalizations('call support view - America detail', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMainRegionView(),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).first;
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support view - Canada detail', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMainRegionView(),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(1);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });
}
