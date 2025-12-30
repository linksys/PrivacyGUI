import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/internet_settings_form_validator.dart';

import 'package:privacy_gui/utils.dart';

class InternetSettingsIPv4FormValidityNotifier
    extends AutoDisposeNotifier<bool> {
  @override
  bool build() {
    final ipv4Setting = ref.watch(
        internetSettingsProvider.select((s) => s.settings.current.ipv4Setting));
    final validator = InternetSettingsFormValidator();
    return isWanFormValid(
        ipv4Setting.ipv4ConnectionType, ipv4Setting, validator);
  }

  bool isWanFormValid(String wanType, Ipv4Setting ipv4Setting,
      InternetSettingsFormValidator validator) {
    switch (WanType.resolve(wanType)) {
      case WanType.static:
        return _isStaticFormValid(ipv4Setting, validator);
      case WanType.pppoe:
        return (ipv4Setting.username?.isNotEmpty ?? false) &&
            (ipv4Setting.password?.isNotEmpty ?? false);
      case WanType.pptp:
        bool isStaticPartValid = true;
        if (ipv4Setting.useStaticSettings == true) {
          isStaticPartValid = _isStaticFormValid(ipv4Setting, validator);
        }
        final isPptpPartValid =
            validator.validateIpAddress(ipv4Setting.serverIp ?? '') == null &&
                (ipv4Setting.username?.isNotEmpty ?? false) &&
                (ipv4Setting.password?.isNotEmpty ?? false);
        return isStaticPartValid && isPptpPartValid;
      case WanType.l2tp:
        return (ipv4Setting.username?.isNotEmpty ?? false) &&
            (ipv4Setting.password?.isNotEmpty ?? false) &&
            validator.validateIpAddress(ipv4Setting.serverIp ?? '') == null;
      case WanType.bridge:
      case WanType.dhcp:
      default:
        return true;
    }
  }

  bool _isStaticFormValid(
      Ipv4Setting ipv4Setting, InternetSettingsFormValidator validator) {
    return validator.validateIpAddress(ipv4Setting.staticIpAddress ?? '') ==
            null &&
        validator.validateSubnetMask(ipv4Setting.networkPrefixLength != null
                ? NetworkUtils.prefixLengthToSubnetMask(
                    ipv4Setting.networkPrefixLength!)
                : '') ==
            null &&
        validator.validateIpAddress(ipv4Setting.staticGateway ?? '') == null &&
        validator.validateIpAddress(ipv4Setting.staticDns1 ?? '') == null &&
        (ipv4Setting.staticDns2 == null ||
            ipv4Setting.staticDns2!.isEmpty ||
            validator.validateIpAddress(ipv4Setting.staticDns2!) == null) &&
        (ipv4Setting.staticDns3 == null ||
            ipv4Setting.staticDns3!.isEmpty ||
            validator.validateIpAddress(ipv4Setting.staticDns3!) == null);
  }
}

final internetSettingsIPv4FormValidityProvider =
    AutoDisposeNotifierProvider<InternetSettingsIPv4FormValidityNotifier, bool>(
        InternetSettingsIPv4FormValidityNotifier.new);

class InternetSettingsIPv6FormValidityNotifier
    extends AutoDisposeNotifier<bool> {
  @override
  bool build() {
    final ipv6Setting = ref.watch(
        internetSettingsProvider.select((s) => s.settings.current.ipv6Setting));
    final validator = InternetSettingsFormValidator();

    if (ipv6Setting.ipv6rdTunnelMode == IPv6rdTunnelMode.manual) {
      final prefixError =
          validator.validateIpv6Prefix(ipv6Setting.ipv6Prefix ?? '');
      final borderRelayError =
          validator.validateBorderRelay(ipv6Setting.ipv6BorderRelay ?? '');
      return prefixError == null && borderRelayError == null;
    }

    return true;
  }
}

final internetSettingsIPv6FormValidityProvider =
    AutoDisposeNotifierProvider<InternetSettingsIPv6FormValidityNotifier, bool>(
        InternetSettingsIPv6FormValidityNotifier.new);

class OptionalSettingsFormValidityNotifier extends AutoDisposeNotifier<bool> {
  @override
  bool build() {
    final settings =
        ref.watch(internetSettingsProvider.select((s) => s.settings.current));
    final validator = InternetSettingsFormValidator();

    bool isMacCloneValid = true;
    if (settings.macClone) {
      isMacCloneValid =
          validator.validateMacAddress(settings.macCloneAddress) == null;
    }

    bool isMtuValid = true;
    if (settings.ipv4Setting.mtu != 0) {
      final mtu = settings.ipv4Setting.mtu;
      isMtuValid = mtu >= 576 &&
          mtu <=
              NetworkUtils.getMaxMtu(settings.ipv4Setting.ipv4ConnectionType);
    }

    return isMacCloneValid && isMtuValid;
  }
}

final optionalSettingsFormValidityProvider =
    AutoDisposeNotifierProvider<OptionalSettingsFormValidityNotifier, bool>(
        OptionalSettingsFormValidityNotifier.new);
