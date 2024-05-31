import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/pnp_admin_view.dart';

import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() {
  testLocalizations('pnp admin view ', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => TestMockPnpNotifier())],
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
  });
}

class TestMockPnpNotifier extends BasePnpNotifier {
  @override
  Future checkAdminPassword(String? password) async {}

  @override
  Future checkInternetConnection() async {
  }

  @override
  Future fetchDeviceInfo() async {
  }

  @override
  Future<bool> pnpCheck() async {
    return true;
  }

  @override
  Future<bool> isRouterPasswordSet() async {
    return true;
  }

  @override
  Future fetchData() async {}

  @override
  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase() {
    return (
      name: 'Linksys1234567',
      password: 'Linksys123456@',
      security: 'WPA2/WPA3-Mixed-Personal'
    );
  }

  @override
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase() {
    return (
      name: 'Guest-Linksys1234567',
      password: 'GuestLinksys123456@',
    );
  }

  @override
  Future save() async {}

  @override
  Future checkRouterConfigured() async {
    state = state.copyWith(isUnconfigured: true);
  }

  @override
  Future testConnectionReconnected() async {
    return true;
  }

  @override
  Future fetchDevices() async {}

  @override
  void setAttachedPassword(String? password) {
    state = state.copyWith(attachedPassword: password);
  }
}
