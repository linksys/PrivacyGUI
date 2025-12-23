import 'package:flutter/material.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/dhcp_form.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/pppoe_form.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/static_ip_form.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/pptp_form.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/l2tp_form.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/bridge_form.dart';

class WanFormFactory {
  static Widget create({
    required WanType type,
    required bool isEditing,
  }) {
    switch (type) {
      case WanType.pppoe:
        return PppoeForm(
          isEditing: isEditing,
        );
      case WanType.static:
        return StaticIpForm(
          isEditing: isEditing,
        );
      case WanType.pptp:
        return PptpForm(
          isEditing: isEditing,
        );
      case WanType.l2tp:
        return L2tpForm(
          isEditing: isEditing,
        );
      case WanType.bridge:
        return BridgeForm(
          isEditing: isEditing,
        );
      case WanType.dhcp:
      default:
        return DHCPForm(
          isEditing: isEditing,
        );
    }
  }
}
