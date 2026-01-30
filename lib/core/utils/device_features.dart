import 'package:flutter/foundation.dart'; // for debugPrint, visibleForTesting

enum DeviceFeature {
  pwa,
}

const Map<DeviceFeature, List<Map<String, dynamic>>> _featureRules = {
  DeviceFeature.pwa: [
    {'provider': 'DU'},
  ],
};

// List of known Service Provider suffixes
const List<String> _knownProviders = [
  'DU',
  'TB',
];

bool isFeatureSupported(
  DeviceFeature feature,
  String modelNumber, {
  String? region,
  String? provider,
  @visibleForTesting
  Map<DeviceFeature, List<Map<String, dynamic>>>? rulesOverride,
}) {
  if (modelNumber.isEmpty) return false;

  final rules = (rulesOverride ?? _featureRules)[feature];
  if (rules == null) return false;

  // Auto-parse region/provider if not supplied
  final effectiveRegion = region ?? _parseRegion(modelNumber);
  final effectiveProvider = provider ?? _parseProvider(modelNumber);

  // ...

  // OR Logic: Return true if ANY rule matches
  for (final rule in rules) {
    if (_isRuleMatch(rule, modelNumber,
        region: effectiveRegion, provider: effectiveProvider)) {
      debugPrint('DeviceFeature: $feature supported by rule $rule');
      return true;
    }
  }

  return false;
}

/// Parses region from "{Model}{SP suffix}-{Region suffix}"
String? _parseRegion(String modelNumber) {
  if (modelNumber.contains('-')) {
    final parts = modelNumber.split('-');
    if (parts.length > 1) {
      return parts.last;
    }
  }
  return null;
}

/// Parses provider from "{Model}{SP suffix}-{Region suffix}"
/// Since there is no delimiter between Model and SP suffix,
/// we check against a list of known provider suffixes.
String? _parseProvider(String modelNumber) {
  // 1. Get the identity part (before dash)
  // Example: 'M60DU-EU' -> 'M60DU'
  String identityPart = modelNumber;
  if (modelNumber.contains('-')) {
    identityPart = modelNumber.split('-').first;
  }

  // 2. Check suffix
  for (final knownProvider in _knownProviders) {
    if (identityPart.toUpperCase().endsWith(knownProvider.toUpperCase())) {
      return knownProvider;
    }
  }
  return null;
}

bool _isRuleMatch(
  Map<String, dynamic> rule,
  String modelNumber, {
  String? region,
  String? provider,
}) {
  // AND Logic: All defined keys in the rule must match
  for (final key in rule.keys) {
    switch (key) {
      case 'pattern':
        // Case-insensitive containment or regex match could be used.
        // For simplicity and alignment with nodes.dart style, we use basic containment/regex.
        // But here we stick to simple 'contains' or regex if needed.
        // Given 'DU-', simple contains is enough, but to be robust like nodes.dart pattern:
        final pattern = rule['pattern'] as String;
        if (!RegExp(pattern, caseSensitive: false).hasMatch(modelNumber)) {
          return false;
        }
        break;
      case 'region':
        if (region == null ||
            !region
                .toUpperCase()
                .contains((rule['region'] as String).toUpperCase())) {
          return false;
        }
        break;
      case 'provider':
        if (provider == null ||
            !provider
                .toUpperCase()
                .contains((rule['provider'] as String).toUpperCase())) {
          return false;
        }
        break;
      // Add more criteria as needed (e.g., 'model' for exact match)
      case 'model':
        if (modelNumber.toUpperCase() !=
            (rule['model'] as String).toUpperCase()) {
          return false;
        }
        break;
    }
  }
  return true;
}
