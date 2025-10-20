import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

final localNetworkSettingProvider =
    NotifierProvider<LocalNetworkSettingsNotifier, LocalNetworkSettingsState>(
        () => LocalNetworkSettingsNotifier());

class LocalNetworkSettingsNotifier extends Notifier<LocalNetworkSettingsState>
    with
        PreservableNotifierMixin<LocalNetworkSettings, LocalNetworkStatus,
            LocalNetworkSettingsState> {
  late InputValidator _routerIpAddressValidator;
  late InputValidator _startIpAddressValidator;
  late InputValidator _subnetMaskValidator;
  late InputValidator _maxUserAllowedValidator;
  late InputValidator _clientLeaseTimeValidator;
  late InputValidator _serverIpAddressValidator;

  @override
  LocalNetworkSettingsState build() {
    return LocalNetworkSettingsState.init();
  }

  @override
  Future<void> performFetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          auth: true,
        )
        .then((value) => RouterLANSettings.fromMap(value.output));

    final subnetMaskString = NetworkUtils.prefixLengthToSubnetMask(
      lanSettings.networkPrefixLength,
    );
    final maxUserAllowed = NetworkUtils.getMaxUserAllowedInDHCPRange(
      lanSettings.ipAddress,
      lanSettings.dhcpSettings.firstClientIPAddress,
      lanSettings.dhcpSettings.lastClientIPAddress,
    );
    final maxUserLimit = NetworkUtils.getMaxUserLimit(
      lanSettings.ipAddress,
      lanSettings.dhcpSettings.firstClientIPAddress,
      subnetMaskString,
      maxUserAllowed,
    );

    state = state.copyWith(
      settings: state.settings.copyWith(
        hostName: lanSettings.hostName,
        ipAddress: lanSettings.ipAddress,
        subnetMask: subnetMaskString,
        isDHCPEnabled: lanSettings.isDHCPEnabled,
        firstIPAddress: lanSettings.dhcpSettings.firstClientIPAddress,
        lastIPAddress: lanSettings.dhcpSettings.lastClientIPAddress,
        maxUserAllowed: maxUserAllowed,
        clientLeaseTime: lanSettings.dhcpSettings.leaseMinutes,
        dns1: () => lanSettings.dhcpSettings.dnsServer1,
        dns2: () => lanSettings.dhcpSettings.dnsServer2,
        dns3: () => lanSettings.dhcpSettings.dnsServer3,
        wins: () => lanSettings.dhcpSettings.winsServer,
        dhcpReservationList: lanSettings.dhcpSettings.reservations,
      ),
      status: LocalNetworkStatus(
        maxUserLimit: maxUserLimit,
        minNetworkPrefixLength: lanSettings.minNetworkPrefixLength,
        maxNetworkPrefixLength: lanSettings.maxNetworkPrefixLength,
        minAllowDHCPLeaseMinutes: lanSettings.minAllowedDHCPLeaseMinutes,
        maxAllowDHCPLeaseMinutes: lanSettings.maxAllowedDHCPLeaseMinutes,
      ),
    );
    _updateValidators(state);
    logger.d('[State]:[LocalNetworkSettings]:${state.toJson()}');
  }

  @override
  Future<void> performSave() async {
    final settings = state.settings;
    final newSettings = SetRouterLANSettings(
      ipAddress: settings.ipAddress,
      networkPrefixLength:
          NetworkUtils.subnetMaskToPrefixLength(settings.subnetMask),
      hostName: settings.hostName,
      isDHCPEnabled: settings.isDHCPEnabled,
      dhcpSettings: DHCPSettings(
        firstClientIPAddress: settings.firstIPAddress,
        lastClientIPAddress: settings.lastIPAddress,
        leaseMinutes: settings.clientLeaseTime,
        dnsServer1: settings.dns1?.isEmpty == true ? null : settings.dns1,
        dnsServer2: settings.dns2?.isEmpty == true ? null : settings.dns2,
        dnsServer3: settings.dns3?.isEmpty == true ? null : settings.dns3,
        winsServer: settings.wins?.isEmpty == true ? null : settings.wins,
        reservations: settings.dhcpReservationList,
      ),
    );
    final routerRepository = ref.read(routerRepositoryProvider);
    await routerRepository
        .send(
      JNAPAction.setLANSettings,
      auth: true,
      data: newSettings.toMap()..removeWhere((key, value) => value == null),
      sideEffectOverrides: const JNAPSideEffectOverrides(maxRetry: 5),
    )
        .then((result) async {
      await ref.read(instantSafetyProvider.notifier).fetch();
    });
  }

  Future<List<DHCPReservation>> saveReservations(
      List<DHCPReservation> list) async {
    await performSave();
    await performFetch();
    return state.settings.dhcpReservationList;
  }

  void updateHostName(String hostName) {
    state = state.copyWith(
        settings: state.settings.copyWith(hostName: hostName));
    String? error;
    if (hostName.isEmpty) {
      error = LocalNetworkErrorPrompt.hostName.name;
    } else if (!LengthRule(min: 1, max: 15).validate(hostName)) {
      error = LocalNetworkErrorPrompt.hostNameInvalid.name;
    } else if (HostNameRule().validate(hostName)) {
      error = LocalNetworkErrorPrompt.hostNameInvalid.name;
    }
    updateErrorPrompts(
      LocalNetworkErrorPrompt.hostName.name,
      error,
    );
  }

  void updateErrorPrompts(String key, String? value) {
    Map<String, String> errorTextMap =
        Map.from(state.settings.errorTextMap);
    if (value != null) {
      errorTextMap[key] = value;
    } else {
      errorTextMap.remove(key);
    }
    state = state.copyWith(
        settings: state.settings.copyWith(errorTextMap: errorTextMap));
    updateHasErrorOnTabs();
  }

  void updateHasErrorOnTabs() {
    bool hasErrorOnHostNameTab = false;
    bool hasErrorOnIPAddressTab = false;
    bool hasErrorOnDhcpServerTab = false;
    for (String errorKey in state.settings.errorTextMap.keys) {
      final key = LocalNetworkErrorPrompt.resolve(errorKey);
      switch (key) {
        case LocalNetworkErrorPrompt.hostName:
          hasErrorOnHostNameTab = true;
          break;
        case LocalNetworkErrorPrompt.ipAddress:
        case LocalNetworkErrorPrompt.subnetMask:
          hasErrorOnIPAddressTab = true;
          break;
        case LocalNetworkErrorPrompt.startIpAddress:
        case LocalNetworkErrorPrompt.maxUserAllowed:
        case LocalNetworkErrorPrompt.leaseTime:
        case LocalNetworkErrorPrompt.dns1:
        case LocalNetworkErrorPrompt.dns2:
        case LocalNetworkErrorPrompt.dns3:
        case LocalNetworkErrorPrompt.wins:
          hasErrorOnDhcpServerTab = true;
          break;
        default:
          break;
      }
    }
    state = state.copyWith(
      settings: state.settings.copyWith(
        hasErrorOnHostNameTab: hasErrorOnHostNameTab,
        hasErrorOnIPAddressTab: hasErrorOnIPAddressTab,
        hasErrorOnDhcpServerTab: hasErrorOnDhcpServerTab,
      ),
    );
  }

  void updateDHCPReservationList(
      List<DHCPReservation> addedDHCPReservationList) {
    final filteredList = addedDHCPReservationList
        .where((element) => !isReservationOverlap(item: element));
    final List<DHCPReservation> newList = [
      ...state.settings.dhcpReservationList,
      ...filteredList
    ];
    state = state.copyWith(
        settings: state.settings.copyWith(dhcpReservationList: newList));
  }

  bool updateDHCPReservationOfIndex(DHCPReservation item, int index) {
    List<DHCPReservation> newList =
        List.from(state.settings.dhcpReservationList);
    bool succeed = false;
    if (item.ipAddress == 'DELETE') {
      newList.removeAt(index);
      succeed = true;
    } else if (!isReservationOverlap(item: item, index: index)) {
      newList[index] = item;
      succeed = true;
    }
    if (succeed) {
      state = state.copyWith(
          settings: state.settings.copyWith(dhcpReservationList: newList));
    }
    return succeed;
  }

  bool isReservationOverlap({required DHCPReservation item, int? index}) {
    final overlap = state.settings.dhcpReservationList.where((element) {
      // Not compare with self if on editing
      if (index != null &&
          state.settings.dhcpReservationList.indexOf(element) == index) {
        return false;
      }
      return element.ipAddress == item.ipAddress ||
          element.macAddress == item.macAddress;
    }).toList();
    return overlap.isNotEmpty;
  }

  void updateState(LocalNetworkSettings newState) {
    state = state.copyWith(settings: newState);
  }

  void _updateValidators(LocalNetworkSettingsState currentSettings) {
    _routerIpAddressValidator = IpAddressRequiredValidator();
    _subnetMaskValidator = SubnetMaskValidator(
      min: currentSettings.status.minNetworkPrefixLength,
      max: currentSettings.status.maxNetworkPrefixLength,
    );
    _startIpAddressValidator = IpAddressAsLocalIpValidator(
      currentSettings.settings.ipAddress,
      currentSettings.settings.subnetMask,
    );
    _maxUserAllowedValidator =
        MaxUsersValidator(currentSettings.status.maxUserLimit);
    _clientLeaseTimeValidator = DhcpClientLeaseTimeValidator(
      currentSettings.status.minAllowDHCPLeaseMinutes,
      currentSettings.status.maxAllowDHCPLeaseMinutes,
    );
    _serverIpAddressValidator = IpAddressValidator();
  }

  void routerIpAddressChanged(
    BuildContext context,
    String newRouterIpAddress,
    LocalNetworkSettings settings,
  ) {
    // Verify router ip
    final routerIpAddressResult =
        routerIpAddressFinished(newRouterIpAddress, settings);
    updateState(routerIpAddressResult.$2);
    // Verify start ip
    final startIpResult = startIpFinished(
        routerIpAddressResult.$2.firstIPAddress, routerIpAddressResult.$2);
    updateState(startIpResult.$2);
    // Verify max user allowed
    final maxUserAllowedResult = maxUserAllowedFinished(
        '${startIpResult.$2.maxUserAllowed}', startIpResult.$2);
    updateState(maxUserAllowedResult.$2);
    // Update error
    updateErrorPrompts(
      LocalNetworkErrorPrompt.startIpAddress.name,
      startIpResult.$1
          ? null
          : newRouterIpAddress == startIpResult.$2.firstIPAddress
              ? LocalNetworkErrorPrompt.startIpAddress.name
              : LocalNetworkErrorPrompt.startIpAddressRange.name,
    );
    updateErrorPrompts(
      LocalNetworkErrorPrompt.ipAddress.name,
      routerIpAddressResult.$1 ? null : LocalNetworkErrorPrompt.ipAddress.name,
    );
    updateErrorPrompts(
      LocalNetworkErrorPrompt.maxUserAllowed.name,
      maxUserAllowedResult.$1
          ? null
          : LocalNetworkErrorPrompt.maxUserAllowed.name,
    );
  }

  void subnetMaskChanged(
    BuildContext context,
    String subnetMask,
    LocalNetworkSettings settings,
  ) {
    // Verify subnet mask
    final subnetMaskResult = subnetMaskFinished(subnetMask, settings);
    updateState(subnetMaskResult.$2);
    if (subnetMaskResult.$1 == true) {
      // Verify start ip
      final startIpResult =
          startIpFinished(subnetMaskResult.$2.firstIPAddress, subnetMaskResult.$2);
      updateState(startIpResult.$2);
      // Verify max user allowed
      final maxUserAllowedResult = maxUserAllowedFinished(
          '${startIpResult.$2.maxUserAllowed}', startIpResult.$2);
      updateState(maxUserAllowedResult.$2);
      // Update error
      updateErrorPrompts(
        LocalNetworkErrorPrompt.startIpAddress.name,
        startIpResult.$1
            ? null
            : startIpResult.$2.ipAddress == startIpResult.$2.firstIPAddress
                ? LocalNetworkErrorPrompt.startIpAddress.name
                : LocalNetworkErrorPrompt.startIpAddressRange.name,
      );
      updateErrorPrompts(
        LocalNetworkErrorPrompt.maxUserAllowed.name,
        maxUserAllowedResult.$1
            ? null
            : LocalNetworkErrorPrompt.maxUserAllowed.name,
      );
    }
    // Update error
    updateErrorPrompts(
      LocalNetworkErrorPrompt.subnetMask.name,
      subnetMaskResult.$1 ? null : LocalNetworkErrorPrompt.subnetMask.name,
    );
  }

  void startIpChanged(
    BuildContext context,
    String startIpAddress,
    LocalNetworkSettings settings,
  ) {
    // Verify start ip
    final startIpResult = startIpFinished(startIpAddress, settings);
    updateState(startIpResult.$2);
    // Verify max user allowed
    final maxUserAllowedResult = maxUserAllowedFinished(
        '${startIpResult.$2.maxUserAllowed}', startIpResult.$2);
    updateState(maxUserAllowedResult.$2);
    // Update error
    updateErrorPrompts(
      LocalNetworkErrorPrompt.startIpAddress.name,
      startIpResult.$1
          ? null
          : startIpResult.$2.ipAddress == startIpResult.$2.firstIPAddress
              ? LocalNetworkErrorPrompt.startIpAddress.name
              : LocalNetworkErrorPrompt.startIpAddressRange.name,
    );
    updateErrorPrompts(
      LocalNetworkErrorPrompt.maxUserAllowed.name,
      maxUserAllowedResult.$1
          ? null
          : LocalNetworkErrorPrompt.maxUserAllowed.name,
    );
  }

  void maxUserAllowedChanged(
    BuildContext context,
    String maxUserAllowed,
    LocalNetworkSettings settings,
  ) {
    // Verify max user allowed
    final maxUserAllowedResult =
        maxUserAllowedFinished(maxUserAllowed, settings);
    updateState(maxUserAllowedResult.$2);
    // Update error
    updateErrorPrompts(
      LocalNetworkErrorPrompt.maxUserAllowed.name,
      maxUserAllowedResult.$1
          ? null
          : LocalNetworkErrorPrompt.maxUserAllowed.name,
    );
  }

  (bool, LocalNetworkSettings) routerIpAddressFinished(
    String newRouterIpAddress,
    LocalNetworkSettings settings,
  ) {
    final isValid = _routerIpAddressValidator.validate(newRouterIpAddress);
    if (isValid) {
      // If the new router IP is valid, replace the first 16 bits of the first Ip
      final routerIpSplit = newRouterIpAddress.split('.');
      final firstIpSplit = settings.firstIPAddress.split('.');
      final newFirstIp =
          '${routerIpSplit[0]}.${routerIpSplit[1]}.${firstIpSplit[2]}.${firstIpSplit[3]}';
      // Calculate the new last Ip
      final newLastIp = NetworkUtils.getEndingIpAddress(
        newRouterIpAddress,
        newFirstIp,
        settings.maxUserAllowed,
      );
      settings = settings.copyWith(
        ipAddress: newRouterIpAddress,
        firstIPAddress: newFirstIp,
        lastIPAddress: newLastIp,
      );
      // Update all necessary validators by the updated settings
      _updateValidators(state);
    } else {
      settings = settings.copyWith(
        ipAddress: newRouterIpAddress,
      );
    }
    return (isValid, settings);
  }

  (bool, LocalNetworkSettings) subnetMaskFinished(
    String subnetMask,
    LocalNetworkSettings settings,
  ) {
    final isMaskValid = _subnetMaskValidator.validate(subnetMask);
    if (isMaskValid) {
      // If the new subnet mask is valid, update the max user limit
      final maxUserLimit = NetworkUtils.getMaxUserLimit(
        settings.ipAddress,
        settings.firstIPAddress,
        subnetMask,
        settings.maxUserAllowed,
      );
      state = state.copyWith(status: LocalNetworkStatus(
        maxUserLimit: maxUserLimit,
        minAllowDHCPLeaseMinutes: state.status.minAllowDHCPLeaseMinutes,
        maxAllowDHCPLeaseMinutes: state.status.maxAllowDHCPLeaseMinutes,
        minNetworkPrefixLength: state.status.minNetworkPrefixLength,
        maxNetworkPrefixLength: state.status.maxNetworkPrefixLength,
      ));
      settings = settings.copyWith(
        subnetMask: subnetMask,
      );
      // Update validators (it is mainly for maxUserAllowedValidator)
      _updateValidators(state);
      // Check if the current max user allowed is still valid
      final isMaxUserAllowedValid =
          _maxUserAllowedValidator.validate('${settings.maxUserAllowed}');
      if (!isMaxUserAllowedValid) {
        // If it's not (TOO BIG), directly reset it with the current max limit
        final newMaxUserAllowed = maxUserLimit;
        // Also, update the ending of Ip range
        final newLastIpAddress = NetworkUtils.getEndingIpAddress(
          settings.ipAddress,
          settings.firstIPAddress,
          newMaxUserAllowed,
        );
        settings = settings.copyWith(
          maxUserAllowed: newMaxUserAllowed,
          lastIPAddress: newLastIpAddress,
        );
      }
    } else {
      settings = settings.copyWith(
        subnetMask: subnetMask,
      );
    }
    return (isMaskValid, settings);
  }

  (bool, LocalNetworkSettings) startIpFinished(
    String startIpAddress,
    LocalNetworkSettings settings,
  ) {
    final isValid = _startIpAddressValidator.validate(startIpAddress);
    if (isValid) {
      // If it is valid, update the max user limit
      final maxUserLimit = NetworkUtils.getMaxUserLimit(
        settings.ipAddress,
        startIpAddress,
        settings.subnetMask,
        settings.maxUserAllowed,
      );
      // Firstly, update the max user limit only
      state = state.copyWith(status: LocalNetworkStatus(
        maxUserLimit: maxUserLimit,
        minAllowDHCPLeaseMinutes: state.status.minAllowDHCPLeaseMinutes,
        maxAllowDHCPLeaseMinutes: state.status.maxAllowDHCPLeaseMinutes,
        minNetworkPrefixLength: state.status.minNetworkPrefixLength,
        maxNetworkPrefixLength: state.status.maxNetworkPrefixLength,
      ));
      // Update validators (it is mainly for maxUserAllowedValidator)
      _updateValidators(state);
      // Check if the current max user allowed is still valid
      final isMaxUserAllowedValid =
          _maxUserAllowedValidator.validate('${settings.maxUserAllowed}');
      if (!isMaxUserAllowedValid) {
        // If it's not (TOO BIG), directly reset it with the current max limit
        settings = settings.copyWith(
          maxUserAllowed: maxUserLimit,
        );
      }
      // Lastly, update the new last Ip
      final lastIpAddress = NetworkUtils.getEndingIpAddress(
        settings.ipAddress,
        startIpAddress,
        settings.maxUserAllowed,
      );
      settings = settings.copyWith(
        firstIPAddress: startIpAddress,
        lastIPAddress: lastIpAddress,
      );
    } else {
      settings = settings.copyWith(
        firstIPAddress: startIpAddress,
      );
    }
    return (isValid, settings);
  }

  (bool, LocalNetworkSettings) maxUserAllowedFinished(
    String maxUserAllowed,
    LocalNetworkSettings settings,
  ) {
    // Due to the UI limit, the value input from users should always be valid
    final isValid = _maxUserAllowedValidator.validate(maxUserAllowed);
    final maxUserAllowedInt = int.parse(maxUserAllowed);
    if (isValid) {
      // If it is valid, update the new last Ip
      final lastIpAddress = NetworkUtils.getEndingIpAddress(
        settings.ipAddress,
        settings.firstIPAddress,
        maxUserAllowedInt,
      );
      settings = settings.copyWith(
        maxUserAllowed: maxUserAllowedInt,
        lastIPAddress: lastIpAddress,
      );
    } else {
      settings = settings.copyWith(
        maxUserAllowed: maxUserAllowedInt,
      );
    }
    return (isValid, settings);
  }

  (bool, LocalNetworkSettings) clientLeaseFinished(
    String leaseTime,
    LocalNetworkSettings settings,
  ) {
    // Due to the UI limit, the value input from users should always be valid
    final isValid = _clientLeaseTimeValidator.validate(leaseTime);
    if (isValid) {
      settings = settings.copyWith(
        clientLeaseTime: int.parse(leaseTime),
      );
    }
    return (isValid, settings);
  }

  (bool, LocalNetworkSettings) staticDns1Finished(
    String dnsIp,
    LocalNetworkSettings settings,
  ) {
    // Due to the UI limit, the value input from users should always be valid
    final isValid = _serverIpAddressValidator.validate(dnsIp);
    if (isValid) {
      settings = settings.copyWith(
        dns1: () => dnsIp,
      );
    } else if (dnsIp.isEmpty) {
      settings = settings.copyWith(
        dns1: () => null,
      );
    }
    return (isValid, settings);
  }

  (bool, LocalNetworkSettings) staticDns2Finished(
    String dnsIp,
    LocalNetworkSettings settings,
  ) {
    // Due to the UI limit, the value input from users should always be valid
    final isValid = _serverIpAddressValidator.validate(dnsIp);
    if (isValid) {
      settings = settings.copyWith(
        dns2: () => dnsIp,
      );
    } else if (dnsIp.isEmpty) {
      settings = settings.copyWith(
        dns2: () => null,
      );
    }

    return (isValid, settings);
  }

  (bool, LocalNetworkSettings) staticDns3Finished(
    String dnsIp,
    LocalNetworkSettings settings,
  ) {
    // Due to the UI limit, the value input from users should always be valid
    final isValid = _serverIpAddressValidator.validate(dnsIp);
    if (isValid) {
      settings = settings.copyWith(
        dns3: () => dnsIp,
      );
    } else if (dnsIp.isEmpty) {
      settings = settings.copyWith(
        dns3: () => null,
      );
    }
    return (isValid, settings);
  }

  (bool, LocalNetworkSettings) winsServerFinished(
    String winsIp,
    LocalNetworkSettings settings,
  ) {
    // Due to the UI limit, the value input from users should always be valid
    final isValid = _serverIpAddressValidator.validate(winsIp);
    if (isValid) {
      settings = settings.copyWith(
        wins: () => winsIp,
      );
    } else if (winsIp.isEmpty) {
      settings = settings.copyWith(
        wins: () => null,
      );
    }
    return (isValid, settings);
  }
}

final preservableLocalNetworkSettingsProvider = Provider.autoDispose<
    PreservableContract<LocalNetworkSettings, LocalNetworkStatus>>((ref) {
  return ref.watch(localNetworkSettingProvider.notifier);
});
