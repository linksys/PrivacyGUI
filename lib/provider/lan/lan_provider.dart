import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/lan/lan_state.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_app/validator_rules/validators.dart';

final lanProvider =
    NotifierProvider<LANNotifier, LANState>(() => LANNotifier());

class LANNotifier extends Notifier<LANState> {
  late InputValidator _routerIPAddressValidator;
  late InputValidator _ipAddressLocalValidator;
  late InputValidator _subnetValidator;
  late InputValidator _maxUsersValidator;
  late InputValidator _leaseTimeValidator;
  final InputValidator _ipAddressValidator = IpAddressValidator();

  @override
  LANState build() => LANState.init();

  Future<LANState> fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          auth: true,
        )
        .then((value) => RouterLANSettings.fromJson(value.output));
    state = state.copyWith(
      ipAddress: lanSettings.ipAddress,
      subnetMask:
          Utils.prefixLengthToSubnetMask(lanSettings.networkPrefixLength),
      isDHCPEnabled: lanSettings.isDHCPEnabled,
      firstIPAddress: lanSettings.dhcpSettings.firstClientIPAddress,
      lastIPAddress: lanSettings.dhcpSettings.lastClientIPAddress,
      maxAllowDHCPLeaseMinutes: lanSettings.maxAllowedDHCPLeaseMinutes,
      minAllowDHCPLeaseMinutes: lanSettings.minAllowedDHCPLeaseMinutes,
      clientLeaseTime: lanSettings.dhcpSettings.leaseMinutes,
    );

    _updateValidator();

    updateMaxUser();
    updateLastClientIPAddress();
    updateMaxUserLimit();
    updateDNSMode();
    return state;
  }

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

  setLeaseTime(String newLeaseTime) {
    final valid = _leaseTimeValidator.validate(newLeaseTime);
    if (valid) {
      state = state.copyWith(clientLeaseTime: int.parse(newLeaseTime));
    }
    setError('leaseTime', valid ? null : 'invalid_input');
  }

  setStaticDns1(String newDns1) {
    final valid = _ipAddressValidator.validate(newDns1);
    if (valid) {
      state = state.copyWith(dns1: newDns1);
    }
    setError('dns1', valid ? null : 'invalid_input');
  }

  setStaticDns2(String newDns1) {
    final valid = _ipAddressValidator.validate(newDns1);
    if (valid) {
      state = state.copyWith(dns2: newDns1);
    }
    setError('dns2', valid ? null : 'invalid_input');
  }

  setStaticDns3(String newDns3) {
    final valid = _ipAddressValidator.validate(newDns3);
    if (valid) {
      state = state.copyWith(dns3: newDns3);
    }
    setError('dns3', valid ? null : 'invalid_input');
  }

  setAutoDNS(bool isAuto) {
    state = state.copyWith(isAutoDNS: isAuto);
  }

  setError(String key, String? value) {
    if (value != null) {
      state =
          state.copyWith(errors: Map.from(state.errors)..addAll({key: value}));
    } else {
      state = state.copyWith(errors: Map.from(state.errors)..remove(key));
    }
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

  updateMaxUser() {
    final maxUsers = Utils.getMaxUserForDHCPRange(
        state.ipAddress, state.firstIPAddress, state.lastIPAddress);
    state = state.copyWith(maxNumUsers: maxUsers);
  }

  updateMaxUserLimit() {
    var newMaxUsersLimit = Utils.getMaxUserLimit(state.ipAddress,
        state.firstIPAddress, state.subnetMask, state.maxNumUsers);
    if (newMaxUsersLimit != 0) {
      state = state.copyWith(maxNumUsers: newMaxUsersLimit);
    } else {
      // startIPAddress not in valid subnet
    }
  }

  updateIPFields() {
    final ipSplit = state.ipAddress.split('.');
    final firstIPSplit = state.firstIPAddress.split('.');
    final lastIPSplit = state.lastIPAddress.split('.');
    final newFirstClientIP =
        '${ipSplit[0]}.${ipSplit[1]}.${ipSplit[2]}.${firstIPSplit[3]}';
    final newLastClientIP =
        '${ipSplit[0]}.${ipSplit[1]}.${ipSplit[2]}.${lastIPSplit[3]}';
    state = state.copyWith(
        firstIPAddress: newFirstClientIP, lastIPAddress: newLastClientIP);
  }
}
