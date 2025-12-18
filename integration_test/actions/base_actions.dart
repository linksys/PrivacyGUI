import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_term_titles.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/info_card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ipv6_form_field.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../mixin/common_actions_mixin.dart';

part 'dashboard_home_actions.dart';
part 'local_login_actions.dart';
part 'menu_actions.dart';
part 'incredible_wifi_actions.dart';
part 'instant_admin_actions.dart';
part 'instant_topology_actions.dart';
part 'instant_safety_actions.dart';
part 'instant_privacy_actions.dart';
part 'instant_devices_actions.dart';
part 'advanced_settings_actions.dart';
part 'instant_verify_actions.dart';
part 'external_speed_test_actions.dart';
part 'speed_test_actions.dart';
part 'add_nodes_actions.dart';
part 'pnp_setup_actions.dart';
part 'prepair_pnp_setup_actions.dart';
part 'recovery_actions.dart';
part 'reset_password_actions.dart';
part 'topbar_actions.dart';
part 'advanced_routing_actions.dart';
part 'firewall_actions.dart';
part 'apps_and_gaming_actions.dart';
part 'administration_actions.dart';
part 'local_network_settings_actions.dart';
part 'dhcp_reservation_actions.dart';
part 'internet_settings_actions.dart';
part 'dmz_actions.dart';

abstract class BaseActions {
  final WidgetTester tester;
  const BaseActions(this.tester);
}

sealed class CommonBaseActions extends BaseActions with CommonActionsMixin {
  CommonBaseActions(super.tester);

  String get title {
    final context = getContext();
    return switch (this) {
      TestDashboardHomeActions() => loc(context).home,
      TestLocalLoginActions() => loc(context).login,
      TestMenuActions() => loc(context).menu,
      TestLocalRecoveryActions() => loc(context).forgotPassword,
      TestLocalResetPasswordActions() =>
        loc(context).localResetRouterPasswordTitle,
      TestIncredibleWifiActions() => loc(context).incredibleWiFi,
      TestInstantAdminActions() => loc(context).instantAdmin,
      TestInstantTopologyActions() => loc(context).instantTopology,
      TestInstantSafetyActions() => loc(context).instantSafety,
      TestInstantPrivacyActions() => loc(context).instantPrivacy,
      TestInstantDevicesActions() => loc(context).instantDevices,
      TestAdvancedSettingsActions() => loc(context).advancedSettings,
      TestInstantVerifyActions() => loc(context).instantVerify,
      TestExternalSpeedTestActions() => loc(context).externalSpeedText,
      TestSpeedTestActions() => loc(context).speedTest,
      TestAddNodesActions() => loc(context).addNodes,
      TestAdvancedRoutingActions() => loc(context).advancedRouting,
      TestFirewallActions() => loc(context).firewall,
      TestAppsAndGamingActions() => loc(context).appsGaming,
      TestLocalNetworkSettingsActions() => loc(context).localNetwork,
      TestAdministrationActions() => loc(context).administration,
      TestDmzActions() => loc(context).dmz,
      TestDHCPReservationActions() =>
        loc(context).dhcpReservations.capitalizeWords(),
      TestInternetSettingsActions() =>
        loc(context).internetSettings.capitalizeWords(),
      // TODO: Handle this case.
      TestPnpSetupActions() => throw UnimplementedError(),
      // TODO: Handle this case.
      TestPrepairPnpSetupActions() => throw UnimplementedError(),
      // TODO: Handle this case.
      TestTopbarActions() => throw UnimplementedError(),
    };
  }
}
