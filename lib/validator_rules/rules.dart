import 'dart:convert';

import 'package:privacy_gui/utils.dart';

abstract class ValidationRule {
  String get name => runtimeType.toString();

  bool validate(String input);
}

abstract class RegExValidationRule extends ValidationRule {
  RegExp get _rule;

  bool get notCheck => false;

  RegExp get rule => _rule;

  @override
  bool validate(String input) =>
      notCheck ? !_rule.hasMatch(input) : _rule.hasMatch(input);
}

class EmailRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(
      r"^[a-zA-Z0-9.!#$%&‘*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
}

class DigitalCheckRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(r".*\d+.*");
}

class SpecialCharCheckRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(r".*[^a-zA-Z0-9 ]+.*");
// From current linksys app
// RegExp regEx = RegExp(
//     r"(?=.*?[\x20-\x29\x2A-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7D-\x7E])\w+");
}

class WiFiPasswordRule extends RegExValidationRule {
  final bool ignoreLength;
  final bool ignoreWhiteSpaceSurround;
  WiFiPasswordRule({
    this.ignoreLength = false,
    this.ignoreWhiteSpaceSurround = false,
  });
  @override
  RegExp get _rule => RegExp(ignoreLength
      ? r"^(?! )[\x20-\x7e]+(?<! )$"
      : r"^(?! )[\x20-\x7e]{8,64}(?<! )$");
}

class WiFiSsidRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(r"^(?! ).{1,32}(?<! )$");
}

class IpAddressRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(
      r"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$");
}

class NoSurroundWhitespaceRule extends RegExValidationRule {
  @override
  bool notCheck = true;

  @override
  RegExp get _rule => RegExp(r'^\s+|\s+$');
}

class AndroidNameRule extends RegExValidationRule {
  @override
  RegExp get _rule =>
      RegExp(r"^Android$|^android-[a-fA-F0-9]{16}.*|^Android-[0-9]+");
}

class AsciiRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(r'^[\x20-\x7E]+$');
}

class WhiteSpaceRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(r'.*[\s]+.*');
}

class HostNameRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(r'[^a-zA-Z0-9-]+|^-|-$');
}

class ConsecutiveCharRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(r'(.)\1{1}');
}

class MACAddressRule extends RegExValidationRule {
  @override
  RegExp get _rule => RegExp(r"^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$");
}

class LengthRule extends ValidationRule {
  final int min;
  final int max;

  LengthRule({this.min = 10, this.max = 0});

  @override
  bool validate(String input) {
    final encoded = utf8.encode(input);
    return max > 0
        ? encoded.length >= min && encoded.length <= max
        : encoded.length >= min;
  }
}

class HybridCaseRule extends ValidationRule {
  @override
  bool validate(String input) {
    return input != input.toUpperCase() && input != input.toLowerCase();
  }
}

class IpAddressHasFourOctetsRule extends ValidationRule {
  @override
  bool validate(String input) => input.split('.').length == 4;
}

class SubnetMaskRule extends ValidationRule {
  final int minNetworkPrefixLength;
  final int maxNetworkPrefixLength;

  SubnetMaskRule({
    this.minNetworkPrefixLength = 8,
    this.maxNetworkPrefixLength = 30,
  });

  @override
  bool validate(String input) {
    try {
      return NetworkUtils.isValidSubnetMask(
        input,
        minNetworkPrefixLength: minNetworkPrefixLength,
        maxNetworkPrefixLength: maxNetworkPrefixLength,
      );
    } catch (e) {
      return false;
    }
  }
}

class RequiredRule extends ValidationRule {
  @override
  bool validate(String input) {
    return input.isNotEmpty;
  }
}

class IpAddressNoReservedRule extends ValidationRule {
  @override
  bool validate(String input) {
    return input != '0.0.0.0' &&
        input != '127.0.0.1' &&
        input != '255.255.255.255';
  }
}

class HostValidForGivenRouterIPAddressAndSubnetMaskRule extends ValidationRule {
  final String routerIPAddress;
  final String subnetMask;

  HostValidForGivenRouterIPAddressAndSubnetMaskRule(
      this.routerIPAddress, this.subnetMask);

  @override
  bool validate(String input) {
    final hostIPAddressNum = NetworkUtils.ipToNum(input);
    final routerIPAddressNum = NetworkUtils.ipToNum(routerIPAddress);
    final subnetMaskNum = NetworkUtils.ipToNum(subnetMask);
    final hostSubnet = (hostIPAddressNum & subnetMaskNum) >>> 0;
    final routerSubnet = (routerIPAddressNum & subnetMaskNum) >>> 0;

    return (hostSubnet == routerSubnet) &&
        _isIPValidForSubnet(hostIPAddressNum, subnetMaskNum);
  }

  bool _isIPValidForSubnet(int ipAddressNum, int subnetMaskNum) {
    final networkIdNum = (ipAddressNum & subnetMaskNum) >>> 0;
    final broadcastIdNum = (~subnetMaskNum | networkIdNum) >>> 0;
    return ipAddressNum != networkIdNum && ipAddressNum != broadcastIdNum;
  }
}

class NotRouterIpAddressRule extends ValidationRule {
  final String routerIpAddress;

  bool get notCheck => true;

  NotRouterIpAddressRule(this.routerIpAddress);

  @override
  bool validate(String input) {
    final ipAddressOctets = input.split('.');
    final routerIPAddressOctets = routerIpAddress.split('.');
    if (ipAddressOctets.length < 4) {
      return true;
    }
    if (routerIPAddressOctets.length < 4) {
      return true;
    }
    for (var i = 0; i < 4; i++) {
      if (routerIPAddressOctets[i] != ipAddressOctets[i]) {
        return true;
      }
    }
    return false;
  }
}

class IntegerRule extends ValidationRule {
  final int min;
  final int max;

  IntegerRule({this.min = -1, this.max = -1});

  @override
  bool validate(String input) {
    final num = int.tryParse(input);
    if (num != null) {
      return (min == -1 ? true : num >= min) && (max == -1 ? true : num <= max);
    }
    return false;
  }
}
