import 'package:flutter/material.dart';
import 'package:linksys_moab/page/dashboard/view/administration/_administration.dart';
import 'package:linksys_moab/page/dashboard/view/administration/internet_settings/connection_type_selection_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/internet_settings/internet_settings_mac_clone_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/internet_settings/internet_settings_mtu_picker.dart';
import 'package:linksys_moab/page/dashboard/view/administration/internet_settings/internet_settings_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/lan/dhcp_reservations/dhcp_reservations_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/lan/lan_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/mac_filtering/mac_filtering_enter_mac_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/mac_filtering/mac_filtering_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_forwarding/port_range_forwarding_list_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_forwarding/port_range_forwarding_rule_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_triggering/port_range_triggering_list_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_triggering/port_range_triggering_rule_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/single_port_forwarding_rule_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_forwarding_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/select_online_device_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/select_protocol_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/single_port_forwarding_list_view.dart';
import 'package:linksys_moab/route/model/_model.dart';

class AdministrationPath extends DashboardPath {
  @override
  Widget buildPage() {
    switch (runtimeType) {
      case AdministrationViewPath:
        return const AdministrationView();
      case RouterPasswordViewPath:
        return const RouterPasswordView();
      case FirmwareUpdateViewPath:
        return const FirmwareUpdateView();
      case TimeZoneViewPath:
        return const TimezoneView();
      case IpDetailsViewPath:
        return const IpDetailsView();
      case WebUiAccessViewPath:
        return const WebUiAccessView();
      case InternetSettingsPath:
        return const InternetSettingsView();
      case ConnectionTypeSelectionPath:
        return ConnectionTypeSelectionView(
          next: next,
          args: args,
        );
      case LANSettingsPath:
        return LANView(
          next: next,
          args: args,
        );
      case PortForwardingPath:
        return PortForwardingView(
          next: next,
          args: args,
        );
      case SinglePortForwardingListPath:
        return SinglePortForwardingListView(
          next: next,
          args: args,
        );
      case PortRangeForwardingListPath:
        return PortRangeForwardingListView(
          next: next,
          args: args,
        );
      case PortRangeTriggeringListPath:
        return PortRangeTriggeringListView(
          next: next,
          args: args,
        );
      case SinglePortForwardingRulePath:
        return SinglePortForwardingRuleView(
          next: next,
          args: args,
        );
      case PortRangeForwardingRulePath:
        return PortRangeForwardingRuleView(
          next: next,
          args: args,
        );
      case PortRangeTriggeringRulePath:
        return PortRangeTriggeringRuleView(
          next: next,
          args: args,
        );
      case SelectProtocolPath:
        return SelectProtocolView(
          next: next,
          args: args,
        );
      case SelectDevicePtah:
        return SelectOnlineDeviceView(
          next: next,
          args: args,
        );
      case MacFilteringPath:
        return MacFilteringView(
          next: next,
          args: args,
        );
      case MacFilteringInputPath:
        return MacFilteringEnterDeviceView(
          next: next,
          args: args,
        );
      case MTUPickerPath:
        return MTUPickerView(
          next: next,
          args: args,
        );
      case MACClonePath:
        return MACCloneView(
          next: next,
          args: args,
        );
      case DHCPReservationsPath:
        return DHCPReservationsView(
          next: next,
          args: args,
        );
      default:
        return const Center();
    }
  }
}

class AdministrationViewPath extends AdministrationPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class RouterPasswordViewPath extends AdministrationPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class FirmwareUpdateViewPath extends AdministrationPath {}

class TimeZoneViewPath extends AdministrationPath {}

class IpDetailsViewPath extends AdministrationPath {}

class WebUiAccessViewPath extends AdministrationPath {}

class InternetSettingsPath extends AdministrationPath {}

class ConnectionTypeSelectionPath extends AdministrationPath
    with ReturnablePath {}

class LANSettingsPath extends AdministrationPath {}

class PortForwardingPath extends AdministrationPath {}

class SinglePortForwardingListPath extends AdministrationPath {}

class PortRangeForwardingListPath extends AdministrationPath {}

class PortRangeTriggeringListPath extends AdministrationPath {}

class SinglePortForwardingRulePath extends AdministrationPath
    with ReturnablePath {}

class PortRangeForwardingRulePath extends AdministrationPath
    with ReturnablePath {}

class PortRangeTriggeringRulePath extends AdministrationPath
    with ReturnablePath {}

class SelectDevicePtah extends AdministrationPath with ReturnablePath {}

class SelectProtocolPath extends AdministrationPath with ReturnablePath {}

class MacFilteringPath extends AdministrationPath {}

class MacFilteringInputPath extends AdministrationPath with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class MTUPickerPath extends AdministrationPath with ReturnablePath {}

class MACClonePath extends AdministrationPath with ReturnablePath {}

class DHCPReservationsPath extends AdministrationPath {}
