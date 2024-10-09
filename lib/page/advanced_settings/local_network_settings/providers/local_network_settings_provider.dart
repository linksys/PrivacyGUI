import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

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
      dns1: lanSettings.dhcpSettings.dnsServer1,
      dns2: lanSettings.dhcpSettings.dnsServer2,
      dns3: lanSettings.dhcpSettings.dnsServer3,
      wins: lanSettings.dhcpSettings.winsServer,
      dhcpReservationList: lanSettings.dhcpSettings.reservations,
    );
    // Update all necessary validators by the current settings
    _updateValidators(state);
    logger.d('[State]:[LocalNetworkSettings]:${state.toJson()}');
    return state;
  }

  Future<void> saveSettings(LocalNetworkSettingsState settings) {
    final currentIPAddress = state.ipAddress;
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
    }).catchError(
      (error) {
        if (kIsWeb) {
          ref.read(redirectionProvider.notifier).state =
              'https://${newSettings.ipAddress}';
        }
      },
      test: (error) => error is JNAPSideEffectError,
    );
  }

  void updateHostName(String hostName) {
    state = state.copyWith(hostName: hostName);
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
    _routerIpAddressValidator = IpAddressAsNewRouterIpValidator(
      currentSettings.ipAddress,
      currentSettings.subnetMask,
    );
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
    }
    return (isMaskValid, settings);
  }

  (bool, LocalNetworkSettingsState) maxUserAllowedFinished(
    String maxUserAllowed,
    LocalNetworkSettingsState settings,
  ) {
    // Due to the UI limit, the value input from users should always be valid
    final isValid = _maxUserAllowedValidator.validate(maxUserAllowed);
    if (isValid) {
      final maxUserAllowedInt = int.parse(maxUserAllowed);
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
    }
    return (isValid, settings);
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
    if (isValid || dnsIp.isEmpty) {
      settings = settings.copyWith(
        dns1: dnsIp,
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
    if (isValid || dnsIp.isEmpty) {
      settings = settings.copyWith(
        dns2: dnsIp,
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
    if (isValid || dnsIp.isEmpty) {
      settings = settings.copyWith(
        dns3: dnsIp,
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
        wins: winsIp,
      );
    }
    return (isValid, settings);
  }

/*
  _updateValidator() {
    _routerIPAddressValidator = IpAddressAsNewRouterIpValidator(
        state.ipAddress, state.subnetMask);
    _ipAddressAsLocalIpValidator =
        IpAddressAsLocalIpValidator(state.ipAddress, state.subnetMask);
    _subnetValidator = SubnetValidator(
        min: state.minNetworkPrefixLength, max: state.maxNetworkPrefixLength);
    _maxUsersValidator = MaxUsersValidator(state.maxNumUsers);
    _leaseTimeValidator = DhcpClientLeaseTimeValidator(
        state.minAllowDHCPLeaseMinutes, state.maxAllowDHCPLeaseMinutes);
  }

  updateMaxUser() {
    final maxUsers = Utils.getMaxUserAllowedInDHCPRange(
        state.ipAddress, state.firstIPAddress, state.lastIPAddress);
    state = state.copyWith(maxUserLimit: maxUsers);
  }

  updateMaxUserLimit() {
    var newMaxUsersLimit = Utils.getMaxUserLimit(state.ipAddress,
        state.firstIPAddress, state.subnetMask, state.maxUserLimit);
    if (newMaxUsersLimit != 0) {
      state = state.copyWith(maxUserLimit: newMaxUsersLimit);
    } else {
      // startIPAddress not in valid subnet
    }
  }

  setIPAddress(String newIPAddress) {
    final valid = _routerIPAddressValidator.validate(newIPAddress);
    if (valid) {
      state = state.copyWith(ipAddress: newIPAddress);
      updateIPFields();
      _updateValidator();
    }
    setError('ipAddress', valid ? null : 'invalid_input');
  }

  setSubnetMask(String newSubnetMask) {
    final valid = _subnetValidator.validate(newSubnetMask);
    if (valid) {
      state = state.copyWith(subnetMask: newSubnetMask);
      updateMaxUserLimit();
      updateLastClientIPAddress();
      _updateValidator();
    }
    setError('subnetMask', valid ? null : 'invalid_input');
  }

  setFirstIPAddress(String newFirstIPAddress) {
    final valid = _ipAddressAsLocalIpValidator.validate(newFirstIPAddress);
    if (valid) {
      state = state.copyWith(firstIPAddress: newFirstIPAddress);
      updateLastClientIPAddress();
      updateMaxUserLimit();
      _updateValidator();
    }
    setError('firstIPAddress', valid ? null : 'invalid_input');
  }

  setMaxUsers(String newMaxUsers) {
    final valid = _maxUsersValidator.validate(newMaxUsers);
    if (valid) {
      state = state.copyWith(maxNumUsers: int.parse(newMaxUsers));
      updateMaxUserLimit();
      updateLastClientIPAddress();
      _updateValidator();
    }
    setError('maxUsers', valid ? null : 'invalid_input');
  }

  setAutoDNS(bool isAuto) {
    state = state.copyWith(isAutoDNS: isAuto);
  }

  updateDNSMode() {
    state = state.copyWith(
        isAutoDNS:
            state.dns1 != null || state.dns2 != null || state.dns3 != null);
  }

  updateLastClientIPAddress() {
    final newLastIP = Utils.getEndDHCPRangeForMaxUsers(
        state.firstIPAddress, state.maxNumUsers);
    state = state.copyWith(lastIPAddress: newLastIP);
  }
  
  */
}
