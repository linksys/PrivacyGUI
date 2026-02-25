import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/services/local_network_settings_service.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

final localNetworkSettingProvider =
    NotifierProvider<LocalNetworkSettingsNotifier, LocalNetworkSettingsState>(
        () => LocalNetworkSettingsNotifier());
// The provider now needs to be generic to match the contract.
final preservableLocalNetworkSettingsProvider =
    Provider<PreservableContract<LocalNetworkSettings, LocalNetworkStatus>>(
        (ref) {
  return ref.watch(localNetworkSettingProvider.notifier);
});

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
    _updateValidators(LocalNetworkSettingsState.init());
    return LocalNetworkSettingsState.init();
  }

  @override
  bool updateShouldNotify(
      LocalNetworkSettingsState previous, LocalNetworkSettingsState next) {
    return previous != next;
  }

  @override
  set state(LocalNetworkSettingsState newState) {
    super.state = newState;
  }

  @override
  Future<(LocalNetworkSettings?, LocalNetworkStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(localNetworkSettingsServiceProvider);
    final (newSettings, newStatus) = await service.fetchLANSettingsWithUIModels(
      forceRemote: forceRemote,
      currentStatus: state.status,
    );

    _updateValidators(state.copyWith(
        status: newStatus,
        settings: state.settings.copyWith(current: newSettings)));
    logger.d('[State]:[LocalNetworkSettings]:${state.toJson()}');
    return (newSettings, newStatus);
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(localNetworkSettingsServiceProvider);
    final settings = state.settings.current;

    // Clear reservations if router IP changed
    final reservations =
        (state.settings.original.ipAddress != settings.ipAddress)
            ? <DHCPReservationUIModel>[]
            : state.status.dhcpReservationList;

    await service.saveReservations(
      routerIp: settings.ipAddress,
      networkPrefixLength:
          NetworkUtils.subnetMaskToPrefixLength(settings.subnetMask),
      hostName: settings.hostName,
      isDHCPEnabled: settings.isDHCPEnabled,
      firstClientIP: settings.firstIPAddress,
      lastClientIP: settings.lastIPAddress,
      leaseMinutes: settings.clientLeaseTime,
      dns1: settings.dns1,
      dns2: settings.dns2,
      dns3: settings.dns3,
      wins: settings.wins,
      reservations: reservations,
    );
    await ref.read(instantSafetyProvider.notifier).fetch();
  }

  Future<void> saveReservations(List<DHCPReservationUIModel> list) async {
    final service = ref.read(localNetworkSettingsServiceProvider);
    final currentSettings = state.settings.current;

    await service.saveReservations(
      routerIp: currentSettings.ipAddress,
      networkPrefixLength:
          NetworkUtils.subnetMaskToPrefixLength(currentSettings.subnetMask),
      hostName: currentSettings.hostName,
      isDHCPEnabled: currentSettings.isDHCPEnabled,
      firstClientIP: currentSettings.firstIPAddress,
      lastClientIP: currentSettings.lastIPAddress,
      leaseMinutes: currentSettings.clientLeaseTime,
      dns1: currentSettings.dns1,
      dns2: currentSettings.dns2,
      dns3: currentSettings.dns3,
      wins: currentSettings.wins,
      reservations: list,
    );
    // After saving, we need to refetch the local network settings to get the updated state.
    await fetch(forceRemote: true);
  }

  void updateSettings(LocalNetworkSettings newSettings) {
    state = state.copyWith(
      settings: state.settings.copyWith(current: newSettings),
    );
  }

  void updateHostName(String hostName) {
    String? invalidChars;
    String? error;

    final invalidMatches = RegExp(r'[^a-zA-Z0-9-]').allMatches(hostName);
    if (invalidMatches.isNotEmpty) {
      error = LocalNetworkErrorPrompt.hostNameInvalidCharacters.name;
      final uniqueChars =
          invalidMatches.map((m) => m.group(0)).toSet().toList();
      uniqueChars.sort();
      invalidChars = uniqueChars.join(', ');
    } else if (hostName.isEmpty) {
      error = LocalNetworkErrorPrompt.hostName.name;
    } else if (hostName.length > 15) {
      error = LocalNetworkErrorPrompt.hostNameLengthError.name;
    } else if (hostName.startsWith('-')) {
      error = LocalNetworkErrorPrompt.hostNameStartWithHyphen.name;
    } else if (hostName.endsWith('-')) {
      error = LocalNetworkErrorPrompt.hostNameEndWithHyphen.name;
    }

    updateSettings(state.settings.current.copyWith(hostName: hostName));
    state = state.copyWith(
      status: state.status.copyWith(
        hostNameInvalidChars: () => invalidChars,
      ),
    );

    updateErrorPrompts(
      LocalNetworkErrorPrompt.hostName.name,
      error,
    );
  }

  void updateErrorPrompts(String key, String? value) {
    Map<String, String> errorTextMap = Map.from(state.status.errorTextMap);
    if (value != null) {
      errorTextMap[key] = value;
    } else {
      errorTextMap.remove(key);
    }
    state = state.copyWith(
        status: state.status.copyWith(errorTextMap: errorTextMap));
    updateHasErrorOnTabs();
  }

  void updateHasErrorOnTabs() {
    bool hasErrorOnHostNameTab = false;
    bool hasErrorOnIPAddressTab = false;
    bool hasErrorOnDhcpServerTab = false;
    for (String errorKey in state.status.errorTextMap.keys) {
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
        status: state.status.copyWith(
      hasErrorOnHostNameTab: hasErrorOnHostNameTab,
      hasErrorOnIPAddressTab: hasErrorOnIPAddressTab,
      hasErrorOnDhcpServerTab: hasErrorOnDhcpServerTab,
    ));
  }

  void updateDHCPReservationList(
      List<DHCPReservationUIModel> addedDHCPReservationList) {
    final filteredList = addedDHCPReservationList
        .where((element) => !isReservationOverlap(item: element));
    final List<DHCPReservationUIModel> newList = [
      ...state.status.dhcpReservationList,
      ...filteredList
    ];
    state = state.copyWith(
        status: state.status.copyWith(dhcpReservationList: newList));
  }

  bool updateDHCPReservationOfIndex(DHCPReservationUIModel item, int index) {
    List<DHCPReservationUIModel> newList =
        List.from(state.status.dhcpReservationList);
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
          status: state.status.copyWith(dhcpReservationList: newList));
    }
    return succeed;
  }

  bool isReservationOverlap(
      {required DHCPReservationUIModel item, int? index}) {
    final overlap = state.status.dhcpReservationList.where((element) {
      // Not compare with self if on editing
      if (index != null &&
          state.status.dhcpReservationList.indexOf(element) == index) {
        return false;
      }
      return element.ipAddress == item.ipAddress ||
          element.macAddress == item.macAddress;
    }).toList();
    return overlap.isNotEmpty;
  }

  void _updateValidators(LocalNetworkSettingsState currentSettings) {
    _routerIpAddressValidator = IpAddressRequiredValidator();
    _subnetMaskValidator = SubnetMaskValidator(
      min: currentSettings.status.minNetworkPrefixLength,
      max: currentSettings.status.maxNetworkPrefixLength,
    );
    _startIpAddressValidator = IpAddressAsLocalIpValidator(
      currentSettings.settings.current.ipAddress,
      currentSettings.settings.current.subnetMask,
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
  ) {
    // Verify router ip
    final routerIpAddressResult =
        routerIpAddressFinished(newRouterIpAddress, state.settings.current);
    updateSettings(routerIpAddressResult.$2);
    // Verify start ip
    final startIpResult = startIpFinished(
        routerIpAddressResult.$2.firstIPAddress, routerIpAddressResult.$2);
    updateSettings(startIpResult.$2);
    // Verify max user allowed
    final maxUserAllowedResult = maxUserAllowedFinished(
        '${startIpResult.$2.maxUserAllowed}', startIpResult.$2);
    updateSettings(maxUserAllowedResult.$2);
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
  ) {
    // Verify subnet mask
    final subnetMaskResult =
        subnetMaskFinished(subnetMask, state.settings.current);
    updateSettings(subnetMaskResult.$2);
    if (subnetMaskResult.$1 == true) {
      // Verify start ip
      final startIpResult = startIpFinished(
          subnetMaskResult.$2.firstIPAddress, subnetMaskResult.$2);
      updateSettings(startIpResult.$2);
      // Verify max user allowed
      final maxUserAllowedResult = maxUserAllowedFinished(
          '${startIpResult.$2.maxUserAllowed}', startIpResult.$2);
      updateSettings(maxUserAllowedResult.$2);
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
  ) {
    // Verify start ip
    final startIpResult =
        startIpFinished(startIpAddress, state.settings.current);
    updateSettings(startIpResult.$2);
    // Verify max user allowed
    final maxUserAllowedResult = maxUserAllowedFinished(
        '${startIpResult.$2.maxUserAllowed}', startIpResult.$2);
    updateSettings(maxUserAllowedResult.$2);
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
  ) {
    // Verify max user allowed
    final maxUserAllowedResult =
        maxUserAllowedFinished(maxUserAllowed, state.settings.current);
    updateSettings(maxUserAllowedResult.$2);
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
      _updateValidators(
          state.copyWith(settings: state.settings.copyWith(current: settings)));
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
      state = state.copyWith(
          status: state.status.copyWith(maxUserLimit: maxUserLimit));

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
      settings = settings.copyWith(
        subnetMask: subnetMask,
      );
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
      state = state.copyWith(
          status: state.status.copyWith(maxUserLimit: maxUserLimit));
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
