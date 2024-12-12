import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

final localNetworkSettingNeedToSaveProvider =
    StateProvider<bool>((ref) => false);

final localNetworkSettingProvider =
    NotifierProvider<LocalNetworkSettingsNotifier, LocalNetworkSettingsState>(
        () => LocalNetworkSettingsNotifier());

class LocalNetworkSettingsNotifier extends Notifier<LocalNetworkSettingsState> {
  late InputValidator _routerIpAddressValidator;
  late InputValidator _startIpAddressValidator;
  late InputValidator _subnetMaskValidator;
  late InputValidator _maxUserAllowedValidator;
  late InputValidator _clientLeaseTimeValidator;
  late InputValidator _serverIpAddressValidator;

  @override
  LocalNetworkSettingsState build() => LocalNetworkSettingsState.init();

  LocalNetworkSettingsState currentSettings() => state.copyWith();

  Future<LocalNetworkSettingsState> fetch({bool fetchRemote = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          fetchRemote: fetchRemote,
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

    state = LocalNetworkSettingsState.init().copyWith(
      hostName: lanSettings.hostName,
      ipAddress: lanSettings.ipAddress,
      subnetMask: subnetMaskString,
      isDHCPEnabled: lanSettings.isDHCPEnabled,
      firstIPAddress: lanSettings.dhcpSettings.firstClientIPAddress,
      lastIPAddress: lanSettings.dhcpSettings.lastClientIPAddress,
      maxUserAllowed: maxUserAllowed,
      maxUserLimit: maxUserLimit,
      minNetworkPrefixLength: lanSettings.minNetworkPrefixLength,
      maxNetworkPrefixLength: lanSettings.maxNetworkPrefixLength,
      clientLeaseTime: lanSettings.dhcpSettings.leaseMinutes,
      minAllowDHCPLeaseMinutes: lanSettings.minAllowedDHCPLeaseMinutes,
      maxAllowDHCPLeaseMinutes: lanSettings.maxAllowedDHCPLeaseMinutes,
      dns1: () => lanSettings.dhcpSettings.dnsServer1,
      dns2: () => lanSettings.dhcpSettings.dnsServer2,
      dns3: () => lanSettings.dhcpSettings.dnsServer3,
      wins: () => lanSettings.dhcpSettings.winsServer,
      dhcpReservationList: lanSettings.dhcpSettings.reservations,
    );
    // Update all necessary validators by the current settings
    _updateValidators(state);
    logger.d('[State]:[LocalNetworkSettings]:${state.toJson()}');
    return state;
  }

  Future<void> saveSettings(LocalNetworkSettingsState settings,
      {String? previousIPAddress}) {
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
        reservations: (previousIPAddress != null &&
                previousIPAddress != settings.ipAddress)
            ? []
            : settings.dhcpReservationList,
      ),
    );
    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository
        .send(
      JNAPAction.setLANSettings,
      auth: true,
      data: newSettings.toMap()..removeWhere((key, value) => value == null),
      sideEffectOverrides: const JNAPSideEffectOverrides(maxRetry: 5),
    )
        .then((result) async {
      // Update the state
      await fetch(fetchRemote: true);
      // Update instant safety
      await ref.read(instantSafetyProvider.notifier).fetchLANSettings();
    });
  }

  Future<List<DHCPReservation>> saveReservations(
      List<DHCPReservation> list) async {
    await saveSettings(state.copyWith(dhcpReservationList: list));
    return fetch(fetchRemote: true).then((state) => state.dhcpReservationList);
  }

  void updateHostName(String hostName) {
    state = state.copyWith(hostName: hostName);
  }

  void updateErrorPrompts(String key, String? value) {
    Map<String, String> errorTextMap = Map.from(state.errorTextMap);
    if (value != null) {
      errorTextMap[key] = value;
    } else {
      errorTextMap.remove(key);
    }
    state = state.copyWith(errorTextMap: errorTextMap);
  }

  void updateDHCPReservationList(
      List<DHCPReservation> addedDHCPReservationList) {
    final filteredList = addedDHCPReservationList
        .where((element) => !isReservationOverlap(item: element));
    final List<DHCPReservation> newList = [
      ...state.dhcpReservationList,
      ...filteredList
    ];
    state = state.copyWith(dhcpReservationList: newList);
  }

  bool updateDHCPReservationOfIndex(DHCPReservation item, int index) {
    List<DHCPReservation> newList = List.from(state.dhcpReservationList);
    bool succeed = false;
    if (item.ipAddress == 'DELETE') {
      newList.removeAt(index);
      succeed = true;
    } else if (!isReservationOverlap(item: item, index: index)) {
      newList[index] = item;
      succeed = true;
    }
    if (succeed) {
      state = state.copyWith(dhcpReservationList: newList);
    }
    return succeed;
  }

  bool isReservationOverlap({required DHCPReservation item, int? index}) {
    final overlap = state.dhcpReservationList.where((element) {
      // Not compare with self if on editing
      if (index != null &&
          state.dhcpReservationList.indexOf(element) == index) {
        return false;
      }
      return element.ipAddress == item.ipAddress ||
          element.macAddress == item.macAddress;
    }).toList();
    return overlap.isNotEmpty;
  }

  void updateState(LocalNetworkSettingsState newState) {
    state = newState.copyWith();
  }

  void _updateValidators(LocalNetworkSettingsState currentSettings) {
    _routerIpAddressValidator = IpAddressRequiredValidator();
    _subnetMaskValidator = SubnetMaskValidator(
      min: currentSettings.minNetworkPrefixLength,
      max: currentSettings.maxNetworkPrefixLength,
    );
    _startIpAddressValidator = IpAddressAsLocalIpValidator(
      currentSettings.ipAddress,
      currentSettings.subnetMask,
    );
    _maxUserAllowedValidator = MaxUsersValidator(currentSettings.maxUserLimit);
    _clientLeaseTimeValidator = DhcpClientLeaseTimeValidator(
      currentSettings.minAllowDHCPLeaseMinutes,
      currentSettings.maxAllowDHCPLeaseMinutes,
    );
    _serverIpAddressValidator = IpAddressValidator();
  }

  void routerIpAddressChanged(
    BuildContext context,
    String newRouterIpAddress,
    LocalNetworkSettingsState settings,
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
      'StartIpAddress',
      startIpResult.$1 ? null : loc(context).invalidIpOrSameAsHostIp,
    );
    updateErrorPrompts(
      'ipAddress',
      routerIpAddressResult.$1 ? null : loc(context).invalidIpAddress,
    );
    updateErrorPrompts(
      'MaxUserAllowed',
      maxUserAllowedResult.$1 ? null : loc(context).invalidNumber,
    );
  }

  void subnetMaskChanged(
    BuildContext context,
    String subnetMask,
    LocalNetworkSettingsState settings,
  ) {
    // Verify subnet mask
    final subnetMaskResult = subnetMaskFinished(subnetMask, settings);
    updateState(subnetMaskResult.$2);
    // Verify start ip
    final startIpResult = startIpFinished(
        subnetMaskResult.$2.firstIPAddress, subnetMaskResult.$2);
    updateState(startIpResult.$2);
    // Verify max user allowed
    final maxUserAllowedResult = maxUserAllowedFinished(
        '${startIpResult.$2.maxUserAllowed}', startIpResult.$2);
    updateState(maxUserAllowedResult.$2);
    // Update error
    updateErrorPrompts(
      'subnetMask',
      subnetMaskResult.$1 ? null : loc(context).invalidSubnetMask,
    );
    updateErrorPrompts(
      'StartIpAddress',
      startIpResult.$1 ? null : loc(context).invalidIpOrSameAsHostIp,
    );
    updateErrorPrompts(
      'MaxUserAllowed',
      maxUserAllowedResult.$1 ? null : loc(context).invalidNumber,
    );
  }

  void startIpChanged(
    BuildContext context,
    String startIpAddress,
    LocalNetworkSettingsState settings,
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
      'StartIpAddress',
      startIpResult.$1 ? null : loc(context).invalidIpOrSameAsHostIp,
    );
    updateErrorPrompts(
      'MaxUserAllowed',
      maxUserAllowedResult.$1 ? null : loc(context).invalidNumber,
    );
  }

  void maxUserAllowedChanged(
    BuildContext context,
    String maxUserAllowed,
    LocalNetworkSettingsState settings,
  ) {
    // Verify max user allowed
    final maxUserAllowedResult =
        maxUserAllowedFinished(maxUserAllowed, settings);
    updateState(maxUserAllowedResult.$2);
    // Update error
    updateErrorPrompts(
      'MaxUserAllowed',
      maxUserAllowedResult.$1 ? null : loc(context).invalidNumber,
    );
  }

  (bool, LocalNetworkSettingsState) routerIpAddressFinished(
    String newRouterIpAddress,
    LocalNetworkSettingsState settings,
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
      _updateValidators(settings);
    } else {
      settings = settings.copyWith(
        ipAddress: newRouterIpAddress,
      );
    }
    return (isValid, settings);
  }

  (bool, LocalNetworkSettingsState) subnetMaskFinished(
    String subnetMask,
    LocalNetworkSettingsState settings,
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
      settings = settings.copyWith(
        subnetMask: subnetMask,
        maxUserLimit: maxUserLimit,
      );

      // Update validators (it is mainly for maxUserAllowedValidator)
      _updateValidators(settings);
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

  (bool, LocalNetworkSettingsState) startIpFinished(
    String startIpAddress,
    LocalNetworkSettingsState settings,
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
      settings = settings.copyWith(
        maxUserLimit: maxUserLimit,
      );
      // Update validators (it is mainly for maxUserAllowedValidator)
      _updateValidators(settings);
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

  (bool, LocalNetworkSettingsState) maxUserAllowedFinished(
    String maxUserAllowed,
    LocalNetworkSettingsState settings,
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

  (bool, LocalNetworkSettingsState) clientLeaseFinished(
    String leaseTime,
    LocalNetworkSettingsState settings,
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

  (bool, LocalNetworkSettingsState) staticDns1Finished(
    String dnsIp,
    LocalNetworkSettingsState settings,
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

  (bool, LocalNetworkSettingsState) staticDns2Finished(
    String dnsIp,
    LocalNetworkSettingsState settings,
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

  (bool, LocalNetworkSettingsState) staticDns3Finished(
    String dnsIp,
    LocalNetworkSettingsState settings,
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

  (bool, LocalNetworkSettingsState) winsServerFinished(
    String winsIp,
    LocalNetworkSettingsState settings,
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
