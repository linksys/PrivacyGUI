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
  RegExp get _rule => RegExp(r"^(?!\s).{0,31}\S$");
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

class IPv6WithReservedRule extends ValidationRule {
  @override
  String get name => 'IPv6WithReservedRule';

  @override
  bool validate(String input) {
    try {
      final List<int> rawAddress = _parseIpv6ToBytes(input);

      // If parsing failed, _parseIpv6ToBytes returns an empty list.
      if (rawAddress.isEmpty) {
        return false;
      }

      // An IPv6 address must be 16 bytes long.
      if (rawAddress.length != 16) {
        return false;
      }

      // --- Rule Checks: Exclude Reserved/Special Ranges ---

      // 1. Loopback Address (::1) - All bytes are 0 except the last one which is 1.
      if (rawAddress[0] == 0 &&
          rawAddress[1] == 0 &&
          rawAddress[2] == 0 &&
          rawAddress[3] == 0 &&
          rawAddress[4] == 0 &&
          rawAddress[5] == 0 &&
          rawAddress[6] == 0 &&
          rawAddress[7] == 0 &&
          rawAddress[8] == 0 &&
          rawAddress[9] == 0 &&
          rawAddress[10] == 0 &&
          rawAddress[11] == 0 &&
          rawAddress[12] == 0 &&
          rawAddress[13] == 0 &&
          rawAddress[14] == 0 &&
          rawAddress[15] == 1) {
        return false;
      }

      // 2. Link-local Address (fe80::/10) - First byte is 0xFE, and the top two bits of the second byte are 10 (0x80 to 0xBF).
      if (rawAddress[0] == 0xFE && (rawAddress[1] & 0xC0) == 0x80) {
        return false;
      }

      // 3. Multicast Address (ff00::/8) - First byte is 0xFF.
      if (rawAddress[0] == 0xFF) {
        return false;
      }

      // 4. ULA (Unique Local Address) fc00::/7 - First byte is 0xFC or 0xFD.
      if (rawAddress[0] == 0xFC || rawAddress[0] == 0xFD) {
        return false;
      }

      // 5. Unspecified Address (::) - All 16 bytes are 0.
      if (rawAddress.every((byte) => byte == 0)) {
        return false;
      }

      // 6. Unallocated or Deprecated Address Space

      // 6a. Check for ffff::/16 (unallocated).
      if (rawAddress[0] == 0xFF && rawAddress[1] == 0xFF) {
        return false;
      }

      // 6b. Check for 3ffe::/16 (6bone - deprecated IPv6 testing network).
      if (rawAddress[0] == 0x3F && rawAddress[1] == 0xFE) {
        return false;
      }

      // 6c. Check for other reserved ranges within 2000::/3 (e.g., 5F00::/12, 6000::/3 to 7FFF::/3).
      if (rawAddress[0] >= 0x5F && rawAddress[0] <= 0x7F) {
        return false;
      }

      // --- Rule: Must be a Global Unicast Address ---
      // Global Unicast addresses fall within the 2000::/3 range,
      // meaning the first byte starts with binary '001'.
      // So, the first byte's value should be between 0x20 (00100000) and 0x3F (00111111), inclusive.
      if (rawAddress[0] < 0x20 || rawAddress[0] > 0x3F) {
        return false;
      }

      // If all checks pass, the address is considered a valid global unicast.
      return true;
    } catch (e) {
      // Catch any other unexpected errors during the process.
      return false;
    }
  }

  List<int> _parseIpv6ToBytes(String ipv6String) {
    List<int> resultBytes = []; // Use List<int> for dynamic byte appending

    // Check for multiple '::' (double colons).
    // An IPv6 address can only have one '::' for zero compression.
    if (ipv6String.indexOf('::') != ipv6String.lastIndexOf('::')) {
      return []; // Invalid format: multiple double colons.
    }

    // Check for invalid characters (must be hexadecimal digits or colons).
    if (!RegExp(r'^[0-9a-fA-F:]+$').hasMatch(ipv6String)) {
      return []; // Contains non-hexadecimal or non-colon characters.
    }

    if (ipv6String.contains('::')) {
      // Handle zero compression (double colon abbreviation).
      List<String> parts = ipv6String.split('::');
      if (parts.length != 2) {
        // Should only result in a left and right part.
        return [];
      }

      // Split the left and right parts into hexadecimal groups.
      // Handle cases like "::1" (left part is empty) or "1::" (right part is empty).
      List<String> leftGroups = parts[0].isEmpty ? [] : parts[0].split(':');
      List<String> rightGroups = parts[1].isEmpty ? [] : parts[1].split(':');

      // Edge case: "::" should have both left and right parts empty.
      if (leftGroups.isEmpty && rightGroups.isEmpty && ipv6String != "::") {
        return []; // e.g., ":::" which is invalid.
      }

      // Parse the left-hand side groups.
      for (String group in leftGroups) {
        // Each group must not be empty and must have 1 to 4 hexadecimal characters.
        if (group.isEmpty || group.length > 4) return [];
        try {
          int value = int.parse(group, radix: 16);
          resultBytes.add((value >> 8) & 0xFF); // Add high byte.
          resultBytes.add(value & 0xFF); // Add low byte.
        } catch (e) {
          return []; // Parsing error (e.g., non-hex characters in a group).
        }
      }

      // Calculate how many zero-compressed groups '::' represents.
      // An IPv6 address has 8 groups in total.
      int numGroups = leftGroups.length + rightGroups.length;
      if (numGroups > 8) {
        return []; // Too many groups in total.
      }
      int zeroCompressedGroups = 8 - numGroups;

      // Fill the middle with zeros (each group is 2 bytes).
      for (int i = 0; i < zeroCompressedGroups * 2; i++) {
        resultBytes.add(0);
      }

      // Parse the right-hand side groups.
      for (String group in rightGroups) {
        // Each group must not be empty and must have 1 to 4 hexadecimal characters.
        if (group.isEmpty || group.length > 4) return [];
        try {
          int value = int.parse(group, radix: 16);
          resultBytes.add((value >> 8) & 0xFF); // Add high byte.
          resultBytes.add(value & 0xFF); // Add low byte.
        } catch (e) {
          return []; // Parsing error.
        }
      }
    } else {
      // Handle standard (non-abbreviated) IPv6 format.
      List<String> parts = ipv6String.split(':');
      if (parts.length != 8) {
        return []; // Not the standard 8 groups.
      }

      for (String group in parts) {
        // Each group must not be empty and must have 1 to 4 hexadecimal characters.
        if (group.isEmpty || group.length > 4) return [];
        try {
          int value = int.parse(group, radix: 16);
          resultBytes.add((value >> 8) & 0xFF); // Add high byte.
          resultBytes.add(value & 0xFF); // Add low byte.
        } catch (e) {
          return []; // Parsing error.
        }
      }
    }

    // Final check: The total number of bytes must be 16.
    if (resultBytes.length != 16) {
      return []; // Not fully parsed to 16 bytes, format error.
    }

    return resultBytes; // Return the list of bytes.
  }
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

/// Validates an IPv4 address string against specified rules:
/// 1. Must be a correct IPv4 format.
/// 2. Cannot be from reserved or special-use ranges:
///    - 0.0.0.0/8 (Current Network / Unspecified)
///    - 127.0.0.0/8 (Loopback)
///    - 224.0.0.0/4 (Multicast)
///    - 255.255.255.255 (Broadcast)
class IpAddressNoReservedRule extends ValidationRule {
  @override
  String get name => 'IpAddressNoReservedRule';

  /// Validates an IPv4 address string against specified rules:
  /// 1. Must be a correct IPv4 format.
  /// 2. Cannot be from reserved or special-use ranges:
  ///    - 0.0.0.0/8 (Current Network / Unspecified)
  ///    - 127.0.0.0/8 (Loopback)
  ///    - 224.0.0.0/4 (Multicast)
  ///    - 255.255.255.255 (Broadcast)
  @override
  bool validate(String input) {
    try {
      final List<int> rawAddress = _parseIpv4ToBytes(input);

      // If parsing failed, _parseIpv4ToBytes returns an empty list.
      if (rawAddress.isEmpty) {
        // print('Reject: Invalid IPv4 format during parsing.');
        return false;
      }

      // An IPv4 address must be 4 bytes long.
      if (rawAddress.length != 4) {
        // print('Reject: Parsed address is not 4 bytes long (unexpected).');
        return false;
      }

      // --- Rule Checks based on IPv4 Address Bytes ---

      // 1. Check for 0.0.0.0/8 (Current Network / Unspecified / This Host)
      // This range includes any address where the first octet (byte) is 0.
      if (rawAddress[0] == 0x00) {
        // print('Reject: Falls within 0.0.0.0/8 range (Unspecified/Current Network).');
        return false;
      }

      // 2. Check for 127.0.0.0/8 (Loopback)
      // This range includes any address where the first octet (byte) is 127.
      if (rawAddress[0] == 0x7F) { // 0x7F is 127 in hexadecimal
        // print('Reject: Loopback address (127.0.0.0/8).');
        return false;
      }

      // 3. Check for 224.0.0.0/4 (Multicast)
      // Multicast addresses range from 224.0.0.0 to 239.255.255.255.
      // This means the first octet (byte) is between 224 (0xE0) and 239 (0xEF).
      if (rawAddress[0] >= 0xE0 && rawAddress[0] <= 0xEF) {
        // print('Reject: Multicast address (224.0.0.0/4).');
        return false;
      }

      // 4. Check for 255.255.255.255 (Limited Broadcast)
      // Manually check if all four bytes are 255 (0xFF).
      if (rawAddress[0] == 0xFF &&
          rawAddress[1] == 0xFF &&
          rawAddress[2] == 0xFF &&
          rawAddress[3] == 0xFF) {
        // print('Reject: Limited Broadcast address (255.255.255.255).');
        return false;
      }

      // If all checks pass, the address is considered valid.
      // print('Accept: IPv4 address is valid and not from specified reserved/special ranges.');
      return true;
    } catch (e) {
      // Catch any other unexpected errors during the process.
      // print('An unexpected error occurred during IPv4 validation: $e');
      return false;
    }
  }

  /// Helper function: Parses an IPv4 string into a list of 4 bytes (octets).
  /// Returns a list of 4 integers (0-255), or an empty list if parsing fails.
  static List<int> _parseIpv4ToBytes(String ipv4String) {
    List<String> octets = ipv4String.split('.');

    // An IPv4 address must have exactly 4 octets.
    if (octets.length != 4) {
      return []; // Invalid format: incorrect number of octets.
    }

    List<int> bytes = [];
    for (String octet in octets) {
      // Each octet must not be empty.
      if (octet.isEmpty) {
        return []; // Invalid format: empty octet.
      }
      try {
        int value = int.parse(octet);
        // Each octet must be between 0 and 255.
        if (value < 0 || value > 255) {
          return []; // Invalid format: octet out of range.
        }
        // Leading zeros are generally allowed if the value itself is valid (e.g., "01" is 1).
        // However, "010" might be problematic if interpreted as octal in some contexts.
        // For strict validation, you might check for leading zeros on non-"0" octets.
        // E.g., if octet.length > 1 and octet.startsWith('0') and value != 0, return [].
        // But for simplicity and common use, `int.parse` handles this.
        if (octet.length > 1 && octet.startsWith('0') && octet != '0') {
          // This check rejects "01", "007" etc., which are sometimes considered invalid by strict parsers.
          // Depending on requirements, you might remove this if you want to allow them.
          return [];
        }

        bytes.add(value);
      } on FormatException {
        return []; // Invalid format: octet is not a valid integer.
      }
    }

    return bytes;
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
