import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';

// State -> screen goldens for the Auto Master waiting view. This is the only
// user-visible surface the WAN-up Auto Master detection adds; the flow/branch
// logic lives in PnpAutoMasterFlowMixin and is not exercised here.
void main() async {
  testLocalizations('Instant Setup - PnP Auto Master waiting: spinner',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpAutoMasterWaitingView(showConnectionError: false),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
      ),
    );
    // The spinner animates indefinitely, so a single settling pump (not
    // pumpAndSettle) is enough to lay out the stable content.
    await tester.pump();
  });

  testLocalizations('Instant Setup - PnP Auto Master waiting: connection error',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: PnpAutoMasterWaitingView(
          showConnectionError: true,
          onRetry: () {},
        ),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  });
}
