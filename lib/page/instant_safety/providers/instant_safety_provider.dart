// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';

final instantSafetyProvider =
    NotifierProvider<InstantSafetyNotifier, InstantSafetyState>(
        () => InstantSafetyNotifier());

final DhcpOption fortinetSetting = DhcpOption(
  type: InstantSafetyType.fortinet,
  dnsServer1: '208.91.114.155',
);
final DhcpOption openDNSSetting = DhcpOption(
  type: InstantSafetyType.openDNS,
  dnsServer1: '208.67.222.123',
  dnsServer2: '208.67.220.123',
);
// Remove all fortinet compatibility map
final compatibilityMap = [
  // const CompatibilityItem(
  //   modelRegExp: '^MX62',
  //   compatibleFW: CompatibilityFW(min: '1.0.5.213402'),
  // ),
  // const CompatibilityItem(
  //   modelRegExp: '^MBE70',
  //   compatibleFW: CompatibilityFW(min: '1.0.4.213257'),
  // ),
  // const CompatibilityItem(modelRegExp: '^MBE71'),
  // const CompatibilityItem(
  //   modelRegExp: '^LN11',
  //   compatibleFW: CompatibilityFW(min: '1.0.2.213420'),
  // ),
  // const CompatibilityItem(modelRegExp: '^LN14'),
  // const CompatibilityItem(modelRegExp: '^LN15'),
  // const CompatibilityItem(modelRegExp: '^LN16'),
  // const CompatibilityItem(modelRegExp: '^MX57'),
];

class InstantSafetyNotifier extends Notifier<InstantSafetyState> {
  @override
  InstantSafetyState build() {
    fetchLANSettings(fetchRemote: true);
    return const InstantSafetyState();
  }

  Future fetchLANSettings({bool fetchRemote = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          fetchRemote: fetchRemote,
          auth: true,
        )
        .then((value) => RouterLANSettings.fromMap(value.output));

    final safeBrowsingType = getSafeBrowsingType(lanSettings);

    state = state.copyWith(
      lanSetting: lanSettings,
      safeBrowsingType: safeBrowsingType,
      hasFortinet: hasFortinet(),
    );
  }

  Future setSafeBrowsing(InstantSafetyType safeBrowsingType) async {
    final lanSetting = state.lanSetting;
    if (lanSetting != null) {
      DHCPSettings dhcpSettings;
      switch (safeBrowsingType) {
        case InstantSafetyType.fortinet:
          dhcpSettings = lanSetting.dhcpSettings.copyWith(
            dnsServer1: fortinetSetting.dnsServer1,
            dnsServer2: fortinetSetting.dnsServer2,
            dnsServer3: fortinetSetting.dnsServer3,
          );
        case InstantSafetyType.openDNS:
          dhcpSettings = lanSetting.dhcpSettings.copyWith(
            dnsServer1: openDNSSetting.dnsServer1,
            dnsServer2: openDNSSetting.dnsServer2,
            dnsServer3: openDNSSetting.dnsServer3,
          );
        case InstantSafetyType.off:
          dhcpSettings = DHCPSettings(
            lastClientIPAddress: lanSetting.dhcpSettings.lastClientIPAddress,
            leaseMinutes: lanSetting.dhcpSettings.leaseMinutes,
            reservations: lanSetting.dhcpSettings.reservations,
            firstClientIPAddress: lanSetting.dhcpSettings.firstClientIPAddress,
          );
      }
      final setLanSetting = SetRouterLANSettings(
        ipAddress: lanSetting.ipAddress,
        networkPrefixLength: lanSetting.networkPrefixLength,
        hostName: lanSetting.hostName,
        isDHCPEnabled: lanSetting.isDHCPEnabled,
        dhcpSettings: dhcpSettings,
      );

      final repo = ref.read(routerRepositoryProvider);
      await repo
          .send(
        JNAPAction.setLANSettings,
        auth: true,
        cacheLevel: CacheLevel.noCache,
        data: setLanSetting.toMap(),
      )
          .then((value) async {
        await fetchLANSettings(fetchRemote: true);
      }).onError((error, stackTrace) {
        if (error is JNAPSideEffectError) {
          throw error;
        }
        throw SafeBrowsingError(message: (error as JNAPError).error);
      });
    } else {
      // ERROR
      throw SafeBrowsingError(message: 'Lan settings NULL');
    }
  }

  InstantSafetyType getSafeBrowsingType(RouterLANSettings lanSettings) {
    final dnsServer1 = lanSettings.dhcpSettings.dnsServer1;
    if (dnsServer1 == fortinetSetting.dnsServer1) {
      return InstantSafetyType.fortinet;
    } else if (dnsServer1 == openDNSSetting.dnsServer1) {
      return InstantSafetyType.openDNS;
    } else {
      return InstantSafetyType.off;
    }
  }

  bool hasFortinet() {
    final coreTransactionData = ref.read(pollingProvider).value;
    final result = coreTransactionData?.data;
    if (result != null) {
      final getDeviceInfoData =
          (result[JNAPAction.getDeviceInfo] as JNAPSuccess?)?.output;
      if (getDeviceInfoData != null) {
        final deviceInfo = NodeDeviceInfo.fromJson(getDeviceInfoData);
        final compatibilityItems = compatibilityMap.where((e) {
          final regex = RegExp(e.modelRegExp, caseSensitive: false);
          bool isMatch = regex.hasMatch(deviceInfo.modelNumber);
          return isMatch;
        }).toList();
        if (compatibilityItems.isEmpty) return false;
        final compatibleFW = compatibilityItems.first.compatibleFW;
        if (compatibleFW != null) {
          if (deviceInfo.firmwareVersion.compareToVersion(compatibleFW.min) >=
              0) {
            final max = compatibleFW.max;
            if (max != null) {
              if (deviceInfo.firmwareVersion.compareToVersion(max) <= 0) {
                return true;
              }
            } else {
              return true;
            }
          }
        } else {
          return true;
        }
      }
    }
    return false;
  }
}

class DhcpOption {
  final InstantSafetyType type;
  final String? dnsServer1;
  final String? dnsServer2;
  final String? dnsServer3;

  DhcpOption({
    required this.type,
    this.dnsServer1,
    this.dnsServer2,
    this.dnsServer3,
  });
}

class CompatibilityItem {
  final String modelRegExp;
  final CompatibilityFW? compatibleFW;

  const CompatibilityItem({
    required this.modelRegExp,
    this.compatibleFW,
  });
}

class CompatibilityFW {
  final String min;
  final String? max;

  const CompatibilityFW({
    required this.min,
    this.max,
  });
}

class SafeBrowsingError extends Error {
  final String? message;

  SafeBrowsingError({
    this.message = 'Unknown error',
  });
}
