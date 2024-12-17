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
  String get name => 'EmailRule';

  @override
  RegExp get _rule => RegExp(
      r"^[a-zA-Z0-9.!#$%&‘*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
}

class DigitalCheckRule extends RegExValidationRule {
  @override
  String get name => 'DigitalCheckRule';

  @override
  RegExp get _rule => RegExp(r".*\d+.*");
}

class SpecialCharCheckRule extends RegExValidationRule {
  @override
  String get name => 'SpecialCharCheckRule';

  @override
  RegExp get _rule => RegExp(r".*[^a-zA-Z0-9 ]+.*");
// From current linksys app
// RegExp regEx = RegExp(
//     r"(?=.*?[\x20-\x29\x2A-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7D-\x7E])\w+");
}

class WiFiPasswordRule extends RegExValidationRule {
  @override
  String get name => 'WiFiPasswordRule';

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
  String get name => 'WiFiSsidRule';

  @override
  RegExp get _rule => RegExp(r"^(?! ).{1,32}(?<! )$");
}

class IpAddressRule extends RegExValidationRule {
  @override
  String get name => 'IpAddressRule';

  @override
  RegExp get _rule => RegExp(
      r"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$");
}

class NoSurroundWhitespaceRule extends RegExValidationRule {
  @override
  String get name => 'NoSurroundWhitespaceRule';

  @override
  bool notCheck = true;

  @override
  RegExp get _rule => RegExp(r'^\s+|\s+$');
}

class AndroidNameRule extends RegExValidationRule {
  @override
  String get name => 'AndroidNameRule';

  @override
  RegExp get _rule =>
      RegExp(r"^Android$|^android-[a-fA-F0-9]{16}.*|^Android-[0-9]+");
}

class AsciiRule extends RegExValidationRule {
  @override
  String get name => 'AsciiRule';

  @override
  RegExp get _rule => RegExp(r'^[\x20-\x7E]+$');
}

class WhiteSpaceRule extends RegExValidationRule {
  @override
  String get name => 'WhiteSpaceRule';

  @override
  RegExp get _rule => RegExp(r'.*[\s]+.*');
}

class HostNameRule extends RegExValidationRule {
  @override
  String get name => 'HostNameRule';

  @override
  RegExp get _rule => RegExp(r'[^a-zA-Z0-9-]+|^-|-$');
}

class ConsecutiveCharRule extends RegExValidationRule {
  @override
  String get name => 'ConsecutiveCharRule';

  @override
  RegExp get _rule => RegExp(r'(.)\1{1}');
}

class MACAddressRule extends RegExValidationRule {
  @override
  String get name => 'MACAddressRule';

  @override
  RegExp get _rule => RegExp(r"^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$");
}

class MACAddressWithReservedRule extends ValidationRule {
  @override
  String get name => 'MACAddressWithReservedRule';

  @override
  bool validate(String input) {
    // 1. check if mac address is in a valid format
    if (!MACAddressRule().validate(input)) {
      return false;
    }
    // 2. check if it's all zeros
    if (input == '00:00:00:00:00:00') {
      return false;
    }
    // 3. check if it's a multicast (the least significant bit of the most significant address octet is set to 1)
    var firstOctet = input.split(':')[0],
        firstOctetInBinary =
            int.parse(firstOctet, radix: 16).toString().padRight(2),
        leastSignificantBit =
            firstOctetInBinary.substring(firstOctetInBinary.length - 1);
    if (leastSignificantBit == '1') {
      return false;
    }
    // 4. check if second character is 0, 2, 4, 6, 8, A, C, E
    var secondCharacter =
        firstOctet.substring(firstOctet.length - 1).toUpperCase();
    if (secondCharacter != '0' &&
        secondCharacter != '2' &&
        secondCharacter != '4' &&
        secondCharacter != '6' &&
        secondCharacter != '8' &&
        secondCharacter != 'A' &&
        secondCharacter != 'C' &&
        secondCharacter != 'E') {
      return false;
    }
    return true;
  }
}

class LengthRule extends ValidationRule {
  final int min;
  final int max;

  LengthRule({this.min = 10, this.max = 0});
  @override
  String get name => 'LengthRule';

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
  String get name => 'HybridCaseRule';

  @override
  bool validate(String input) {
    return input != input.toUpperCase() && input != input.toLowerCase();
  }
}

class IpAddressHasFourOctetsRule extends ValidationRule {
  @override
  String get name => 'IpAddressHasFourOctetsRule';

  @override
  bool validate(String input) => input.split('.').length == 4;
}

class SubnetMaskRule extends ValidationRule {
  @override
  String get name => 'SubnetMaskRule';

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
  String get name => 'RequiredRule';
  @override
  bool validate(String input) {
    return input.isNotEmpty;
  }
}

class IpAddressNoReservedRule extends ValidationRule {
  @override
  String get name => 'IpAddressNoReservedRule';
  @override
  bool validate(String input) {
    return input != '0.0.0.0' &&
        input != '127.0.0.1' &&
        input != '255.255.255.255';
  }
}

class HostValidForGivenRouterIPAddressAndSubnetMaskRule extends ValidationRule {
  @override
  String get name => 'HostValidForGivenRouterIPAddressAndSubnetMaskRule';
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
  @override
  String get name => 'NotRouterIpAddressRule';

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
  String get name => 'IntegerRule';
  @override
  bool validate(String input) {
    final num = int.tryParse(input);
    if (num != null) {
      return (min == -1 ? true : num >= min) && (max == -1 ? true : num <= max);
    }
    return false;
  }
}
