import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

import '../mixin/common_actions_mixin.dart';
import '_actions.dart';

abstract class BaseActions {
  final WidgetTester tester;
  const BaseActions(this.tester);
}

abstract class CommonBaseActions extends BaseActions with CommonActionsMixin {
  CommonBaseActions(super.tester);

  String get title {
    final context = getContext();
    return switch (runtimeType) {
      TestLocalLoginActions => loc(context).login,
      TestMenuActions => loc(context).menu,
      TestLocalRecoveryActions => loc(context).forgotPassword,
      TestLocalResetPasswordActions => loc(context).localResetRouterPasswordTitle,
      TestIncredibleWifiActions => loc(context).incredibleWiFi,
      TestInstantAdminActions => loc(context).instantAdmin,
      TestInstantTopologyActions => loc(context).instantTopology,
      TestInstantSafetyActions => loc(context).instantSafety,
      TestInstantPrivacyActions => loc(context).instantPrivacy,
      TestInstantDevicesActions => loc(context).instantDevices,
      TestAdvancedSettingsActions => loc(context).advancedSettings,
      TestInstantVerifyActions => loc(context).instantVerify,
      TestExternalSpeedTestActions => loc(context).externalSpeedText,
      TestAddNodesActions => loc(context).addNodes,

      _ => 'Unknown', // Or throw an error if you want to be strict
    };
  }
}

