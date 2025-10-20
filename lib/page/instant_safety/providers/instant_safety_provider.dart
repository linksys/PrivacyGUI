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
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final instantSafetyProvider =
    NotifierProvider<InstantSafetyNotifier, InstantSafetyState>(
        () => InstantSafetyNotifier());

// The provider now needs to be generic to match the contract.
final preservableInstantSafetyProvider =
    Provider<PreservableContract<InstantSafetySettings, InstantSafetyStatus>>(
        (ref) {
  return ref.watch(instantSafetyProvider.notifier);
});

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
final compatibilityMap = [];

class InstantSafetyNotifier extends Notifier<InstantSafetyState>
    with
        PreservableNotifierMixin<InstantSafetySettings, InstantSafetyStatus,
            InstantSafetyState> {
  @override
  InstantSafetyState build() {
    // The mixin's fetch method is now available.
    fetch(forceRemote: true);
    return InstantSafetyState.initial();
  }

  @override
  Future<(InstantSafetySettings?, InstantSafetyStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    try {
      final lanSettings = await repo
          .send(
            JNAPAction.getLANSettings,
            fetchRemote: forceRemote,
            auth: true,
          )
          .then((value) => RouterLANSettings.fromMap(value.output));

      final safeBrowsingType = _getSafeBrowsingType(lanSettings);
      final hasFortinetValue = _hasFortinet();

      final settings =
          InstantSafetySettings(safeBrowsingType: safeBrowsingType);
      final status = InstantSafetyStatus(
          lanSetting: lanSettings, hasFortinet: hasFortinetValue);

      // Return the raw data for the mixin to handle.
      return (settings, status);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> performSave() async {
    final currentSettings = state.settings.current;
    final lanSetting = state.status.lanSetting;

    if (lanSetting == null) {
      throw SafeBrowsingError(message: 'Lan settings not available');
    }

    final DHCPSettings dhcpSettings = switch (currentSettings.safeBrowsingType) {
      InstantSafetyType.fortinet => lanSetting.dhcpSettings.copyWith(
          dnsServer1: fortinetSetting.dnsServer1,
          dnsServer2: fortinetSetting.dnsServer2,
          dnsServer3: fortinetSetting.dnsServer3,
        ),
      InstantSafetyType.openDNS => lanSetting.dhcpSettings.copyWith(
          dnsServer1: openDNSSetting.dnsServer1,
          dnsServer2: openDNSSetting.dnsServer2,
          dnsServer3: openDNSSetting.dnsServer3,
        ),
      InstantSafetyType.off => DHCPSettings(
          lastClientIPAddress: lanSetting.dhcpSettings.lastClientIPAddress,
          leaseMinutes: lanSetting.dhcpSettings.leaseMinutes,
          reservations: lanSetting.dhcpSettings.reservations,
          firstClientIPAddress: lanSetting.dhcpSettings.firstClientIPAddress,
        ),
    };
    final setLanSetting = SetRouterLANSettings(
      ipAddress: lanSetting.ipAddress,
      networkPrefixLength: lanSetting.networkPrefixLength,
      hostName: lanSetting.hostName,
      isDHCPEnabled: lanSetting.isDHCPEnabled,
      dhcpSettings: dhcpSettings,
    );

    final repo = ref.read(routerRepositoryProvider);
    try {
      await repo.send(
        JNAPAction.setLANSettings,
        auth: true,
        cacheLevel: CacheLevel.noCache,
        data: setLanSetting.toMap(),
      );
      // The final fetch is removed. The mixin's save() will call markAsSaved().
    } catch (error) {
      if (error is JNAPSideEffectError) {
        rethrow;
      }
      throw SafeBrowsingError(message: (error as JNAPError).error);
    }
  }

  // These methods are for UI interaction to update the 'current' state.
  void setSafeBrowsingEnabled(bool isEnabled) {
    final newType = isEnabled
        ? (state.status.hasFortinet
            ? InstantSafetyType.fortinet
            : InstantSafetyType.openDNS)
        : InstantSafetyType.off;

    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(safeBrowsingType: newType),
      ),
    );
  }

  void setSafeBrowsingProvider(InstantSafetyType provider) {
    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(safeBrowsingType: provider),
      ),
    );
  }

  // --- Private Helpers ---

  InstantSafetyType _getSafeBrowsingType(RouterLANSettings lanSettings) {
    final dnsServer1 = lanSettings.dhcpSettings.dnsServer1;
    if (dnsServer1 == fortinetSetting.dnsServer1) {
      return InstantSafetyType.fortinet;
    } else if (dnsServer1 == openDNSSetting.dnsServer1) {
      return InstantSafetyType.openDNS;
    } else {
      return InstantSafetyType.off;
    }
  }

  bool _hasFortinet() {
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