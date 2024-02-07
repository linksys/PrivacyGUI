import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/core/jnap/models/set_lan_settings.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/local_network_settings/local_network_settings_state.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_app/validator_rules/validators.dart';

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

  Future<LocalNetworkSettingsState> fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          auth: true,
        )
        .then((value) => RouterLANSettings.fromJson(value.output));

    final subnetMaskString = Utils.prefixLengthToSubnetMask(
      lanSettings.networkPrefixLength,
    );
    final maxUserAllowed = Utils.getMaxUserAllowedInDHCPRange(
      lanSettings.ipAddress,
      lanSettings.dhcpSettings.firstClientIPAddress,
      lanSettings.dhcpSettings.lastClientIPAddress,
    );
    final maxUserLimit = Utils.getMaxUserLimit(
      lanSettings.ipAddress,
      lanSettings.dhcpSettings.firstClientIPAddress,
      subnetMaskString,
      maxUserAllowed,
    );

    state = state.copyWith(
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
    return state;
  }

  Future<void> saveSettings(LocalNetworkSettingsState settings) {
    final newSettings = SetRouterLANSettings(
      ipAddress: settings.ipAddress,
      networkPrefixLength: Utils.subnetMaskToPrefixLength(settings.subnetMask),
      hostName: settings.hostName,
      isDHCPEnabled: settings.isDHCPEnabled,
      dhcpSettings: DHCPSettings(
        firstClientIPAddress: settings.firstIPAddress,
        lastClientIPAddress: settings.lastIPAddress,
        leaseMinutes: settings.clientLeaseTime,
        dnsServer1: settings.dns1,
        dnsServer2: settings.dns2,
        dnsServer3: settings.dns3,
        winsServer: settings.wins,
        reservations: settings.dhcpReservationList,
      ),
    );
    final routerRepository = ref.read(routerRepositoryProvider);
    return routerRepository
        .send(
      JNAPAction.setLANSettings,
      auth: true,
      data: newSettings.toMap()..removeWhere((key, value) => value == null),
    )
        .then((result) {
      // Update the state
      state = state.copyWith(
        hostName: settings.hostName,
        ipAddress: settings.ipAddress,
        subnetMask: settings.subnetMask,
        isDHCPEnabled: settings.isDHCPEnabled,
        firstIPAddress: settings.firstIPAddress,
        lastIPAddress: settings.lastIPAddress,
        maxUserLimit: settings.maxUserLimit,
        maxUserAllowed: settings.maxUserAllowed,
        clientLeaseTime: settings.clientLeaseTime,
        minAllowDHCPLeaseMinutes: settings.minAllowDHCPLeaseMinutes,
        maxAllowDHCPLeaseMinutes: settings.maxAllowDHCPLeaseMinutes,
        minNetworkPrefixLength: settings.minNetworkPrefixLength,
        maxNetworkPrefixLength: settings.maxNetworkPrefixLength,
        dns1: settings.dns1,
        dns2: settings.dns2,
        dns3: settings.dns3,
        wins: settings.wins,
        dhcpReservationList: settings.dhcpReservationList,
      );
    });
  }

  void _updateValidators(LocalNetworkSettingsState currentSettings) {
    _routerIpAddressValidator = IpAddressLocalTestSubnetMaskValidator(
      currentSettings.ipAddress,
      currentSettings.subnetMask,
    );
    _subnetMaskValidator = SubnetValidator(
      min: currentSettings.minNetworkPrefixLength,
      max: currentSettings.maxNetworkPrefixLength,
    );
    _startIpAddressValidator = IpAddressLocalValidator(
      currentSettings.ipAddress,
      currentSettings.subnetMask,
    );
    _maxUserAllowedValidator = MaxUsersValidator(currentSettings.maxUserLimit);
    _clientLeaseTimeValidator = LeaseTimeValidator(
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
      final newLastIp = Utils.getEndingIpAddress(
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
      final maxUserLimit = Utils.getMaxUserLimit(
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
        final newLastIpAddress = Utils.getEndingIpAddress(
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
      final lastIpAddress = Utils.getEndingIpAddress(
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
      final maxUserLimit = Utils.getMaxUserLimit(
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
      final lastIpAddress = Utils.getEndingIpAddress(
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
    if (isValid) {
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
    if (isValid) {
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
    if (isValid) {
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
    _routerIPAddressValidator = IpAddressLocalTestSubnetMaskValidator(
        state.ipAddress, state.subnetMask);
    _ipAddressLocalValidator =
        IpAddressLocalValidator(state.ipAddress, state.subnetMask);
    _subnetValidator = SubnetValidator(
        min: state.minNetworkPrefixLength, max: state.maxNetworkPrefixLength);
    _maxUsersValidator = MaxUsersValidator(state.maxNumUsers);
    _leaseTimeValidator = LeaseTimeValidator(
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
    final valid = _ipAddressLocalValidator.validate(newFirstIPAddress);
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
