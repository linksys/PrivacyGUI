import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_auth_view.dart';

import '../../../../../../common/di.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';

void main() {
  mockDependencyRegister();

  testLocalizations('PnP ISP auth view', (tester, locale) async {
    await tester.pumpWidget(testableSingleRoute(
      locale: locale,
      child: const PnpIspAuthView(),
    ));
  });
}
