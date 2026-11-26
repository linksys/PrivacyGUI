// The PnP setup page with the real PnpNotifier over a RouterBoundary, for the
// tests of the steps it lays out. A step is tested through this page, which
// builds it, never in a layout rebuilt for the test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/recording_polling.dart';
import '../../../../common/router_boundary.dart';
import '../../../../common/testable_router.dart';
import '../../data/pnp_router_data.dart';

/// PnP as the admin view hands it to the setup page: it has read the router's
/// device info and its mode. Every method is the real one.
class ArrivedPnp extends PnpNotifier {
  ArrivedPnp({this.unconfigured = false});

  final bool unconfigured;

  @override
  PnpState build() => PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(pnpDeviceInfo),
        isUnconfigured: unconfigured,
      );
}

/// Opens the setup page on [router] and waits for its first step.
Future<void> openPnpSetup(
  WidgetTester tester, {
  required RouterBoundary router,
  required PnpNotifier pnp,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(testableSingleRoute(
    child: const PnpSetupView(),
    locale: const Locale('en'),
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 6, centered: true),
      noNaviRail: true,
    ),
    overrides: [
      pnpProvider.overrideWith(() => pnp),
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => RecordingPolling()),
    ],
  ));
  await tester.pumpAndSettle();
}

/// The step's Next (or Done) button.
Finder nextButton(String label) =>
    find.widgetWithText(AppFilledButton, label).hitTestable();

/// Whether [label]'s button can be tapped.
bool canTap(WidgetTester tester, String label) =>
    tester.widget<AppFilledButton>(nextButton(label)).onTap != null;

/// Taps [label] and lets the save it starts run past its 3 s wait for the
/// router to come back.
Future<void> tapAndSave(WidgetTester tester, String label) async {
  await tester.tap(nextButton(label));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pumpAndSettle();
}
