import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/wifi_settings/view/_view.dart';
import '_model.dart';


class WifiSettingsPath extends DashboardPath {
  @override
  Widget buildPage() {
    switch (runtimeType) {
      case WifiSettingsOverviewPath:
        return const WifiSettingsView();
      case WifiSettingsReviewPath:
        return WifiSettingsReviewView(
          args: args,
        );
      case EditWifiNamePasswordPath:
        return EditWifiNamePasswordView(
          args: args,
        );
      case EditWifiSecurityPath:
        return EditWifiSecurityView(
          args: args,
        );
      case EditWifiModePath:
        return EditWifiModeView(
          args: args,
        );
      case WifiListPath:
        return const WifiListView();
      case ShareWifiPath:
        return ShareWifiView(
          args: args,
        );
      default:
        return const Center();
    }
  }
}

class WifiSettingsOverviewPath extends WifiSettingsPath {}

class WifiSettingsReviewPath extends WifiSettingsPath {}

class EditWifiNamePasswordPath extends WifiSettingsPath {}

class EditWifiSecurityPath extends WifiSettingsPath {}

class EditWifiModePath extends WifiSettingsPath {}

class WifiListPath extends WifiSettingsPath {}

class ShareWifiPath extends WifiSettingsPath {}