import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/call_support/call_support_main_region_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/call_support/call_support_more_region_view.dart';
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

  testLocalizations('call support more view - Latin America',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.latinAmerica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Mexico detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.latinAmerica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).first;
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Europe', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Belgium detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(0);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Denmark detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(1);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Netherlands detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(2);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Norway detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(3);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Sweden detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(4);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - UK detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.europe},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(5);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Middle Ease And Africa',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.middleEastAndAfrica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Saudi Arabia detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.middleEastAndAfrica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(0);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - United Arab Emirates detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.middleEastAndAfrica},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(1);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Asia Pacific', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Taiwan detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(0);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Hong Kong detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(1);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - China detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(2);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Japan detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(3);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Singapore detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(4);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - Australia detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(5);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('call support more view - New Zealand detail',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const CallSupportMoreRegionView(
          args: {'region': CallSupportRegion.asiaPacific},
        ),
        locale: locale,
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    final regionFinder = find.byType(AppCard).at(6);
    await tester.tap(regionFinder);
    await tester.pumpAndSettle();
  });
}
