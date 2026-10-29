import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;
import 'package:privacy_gui/util/network_utils.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

/// FWDEV#213's static route limit, which is 1.0's: FW refuses a new route past
/// it (feed_usp#56). There is no TR-181 leaf for it.
const kMaxStaticRoutes = 20;

/// The error names FW gives a refused static route write (FWDEV#213; they are
/// 1.0's), at the start of the refused leaf's message. The service reads them
/// off a refusal and the page shows each with its own message.
class StaticRouteRefusalNames {
  static const tooManyEntries = 'ErrorTooManyEntries';
  static const invalidIpAddress = 'ErrorInvalidIPAddress';
  static const invalidNetworkPrefixLength = 'ErrorInvalidNetworkPrefixLength';
  static const invalidGateway = 'ErrorInvalidGateway';
  static const duplicateEntryName = 'ErrorDuplicateEntryName';

  static const all = [
    tooManyEntries,
    invalidIpAddress,
    invalidNetworkPrefixLength,
    invalidGateway,
    duplicateEntryName,
  ];
}

/// Error keys returned by [StaticRouteUIModel.validateRoute] and
/// [StaticRouteUIModel.validateList].
/// Use these to map to l10n strings in the View layer.
class StaticRoutingErrorKeys {
  static const nameRequired = 'nameRequired';
  static const nameTooLong = 'nameTooLong';
  static const destIpRequired = 'destIpRequired';
  static const invalidIpAddress = 'invalidIpAddress';
  static const subnetMaskRequired = 'subnetMaskRequired';
  static const invalidSubnetMask = 'invalidSubnetMask';
  static const gatewayRequired = 'gatewayRequired';
  static const gatewayIsRouter = 'gatewayIsRouter';
  static const reservedAddress = 'reservedAddress';
  static const destIpInLanSubnet = 'destIpInLanSubnet';
  static const duplicateName = 'duplicateName';
  static const tooManyRoutes = 'tooManyRoutes';
  static const gatewayMustBeWithinLanSubnet = 'gatewayMustBeWithinLanSubnet';
  static const gatewayMustBeOutsideLanSubnet = 'gatewayMustBeOutsideLanSubnet';
}

/// UI model for a single static route entry.
///
/// [instancePath] is `null` for newly created (local-only) routes
/// that have not yet been saved to the device.
class StaticRouteUIModel extends Equatable {
  final String? instancePath;
  final bool enabled;
  final String name;
  final String destIpAddress;
  final String destSubnetMask;
  final String gatewayIpAddress;
  final String interfaceName;

  const StaticRouteUIModel({
    this.instancePath,
    required this.enabled,
    required this.name,
    required this.destIpAddress,
    required this.destSubnetMask,
    required this.gatewayIpAddress,
    required this.interfaceName,
  });

  /// Stable, kebab-case key for E2E `identifier` hooks (e.g.
  /// `static-route-edit-<key>`). Derived from the route name ("Web Server" →
  /// "web-server"); falls back to the saved instance number, then "unnamed",
  /// so it is always non-empty and never collides across rows.
  String get identifierKey => ruleIdentifierKey(name, instancePath);

  /// The interface choices the route dialog offers, as display names.
  static const interfaceOptions = ['LAN', 'Internet'];

  /// A contiguous /8 to /30, as 1.0's dialog (FWDEV#213; FW also takes /31).
  /// [NetworkUtils.isValidSubnetMask] throws, rather than returns false, for a
  /// prefix outside the range it is given.
  static bool _isValidRouteMask(String mask) {
    try {
      return NetworkUtils.isValidSubnetMask(mask);
    } on FormatException {
      return false;
    }
  }

  /// 1.0's util.isReservedAddress, which FW checks on the destination and an
  /// Internet gateway (FWDEV#213): 0/8, 127/8, 169.254/16, 224/4 and 240/4.
  /// [ip] must be a valid IPv4 address.
  static bool _isReservedAddress(String ip) {
    final n = NetworkUtils.ipToNum(ip);
    return (n >> 24) == 0 ||
        (n >> 24) == 127 ||
        (n >> 16) == 0xA9FE ||
        (n >> 28) >= 0xE;
  }

  /// Validate a route entry. Returns a map of field → [StaticRoutingErrorKeys]
  /// key.
  ///
  /// When [lanIp] and [lanSubnetMask] are provided, validates gateway subnet:
  /// - LAN interface: gateway must be within LAN subnet
  /// - Internet interface: gateway must be outside LAN subnet
  ///
  /// [otherNames] is the name of every other route on the page, unsaved ones
  /// included; leave out the route being edited.
  static Map<String, String> validateRoute({
    required String name,
    required String destIp,
    required String subnetMask,
    required String gateway,
    String? interfaceName,
    String? lanIp,
    String? lanSubnetMask,
    Set<String> otherNames = const {},
  }) {
    final errors = <String, String>{};
    // The LAN, or null when it is not known: LanData.empty() gives '' for
    // both, and ipToNum('') is 0, which would put every address in the LAN.
    final lanKnown = lanIp != null &&
        lanIp.isNotEmpty &&
        lanSubnetMask != null &&
        lanSubnetMask.isNotEmpty &&
        NetworkUtils.isValidIpAddress(lanIp) &&
        NetworkUtils.isValidSubnetMask(lanSubnetMask);
    // A host of the LAN: inside it, and not its network or broadcast address.
    final isLanHost = lanKnown
        ? HostValidForGivenRouterIPAddressAndSubnetMaskRule(
            lanIp,
            lanSubnetMask,
          ).validate
        : null;
    // Inside the LAN subnet, its network and broadcast addresses included, as
    // FW's `in_lan` (feed_usp#56).
    bool inLanSubnet(String ip) {
      final mask = NetworkUtils.ipToNum(lanSubnetMask!);
      return NetworkUtils.ipToNum(ip) & mask ==
          NetworkUtils.ipToNum(lanIp!) & mask;
    }

    if (name.isEmpty) {
      errors['name'] = StaticRoutingErrorKeys.nameRequired;
    } else if (name.length > 32) {
      errors['name'] = StaticRoutingErrorKeys.nameTooLong;
    } else if (otherNames.contains(name)) {
      errors['name'] = StaticRoutingErrorKeys.duplicateName;
    }
    if (destIp.isEmpty) {
      errors['destIp'] = StaticRoutingErrorKeys.destIpRequired;
    } else if (!NetworkUtils.isValidIpAddress(destIp)) {
      errors['destIp'] = StaticRoutingErrorKeys.invalidIpAddress;
    } else if (_isReservedAddress(destIp)) {
      errors['destIp'] = StaticRoutingErrorKeys.reservedAddress;
    } else if (isLanHost != null && destIp != lanIp && isLanHost(destIp)) {
      // 1.x IpAddressAsLocalIpValidator. FW does not check this one.
      errors['destIp'] = StaticRoutingErrorKeys.destIpInLanSubnet;
    }
    if (subnetMask.isEmpty) {
      errors['subnetMask'] = StaticRoutingErrorKeys.subnetMaskRequired;
    } else if (!_isValidRouteMask(subnetMask)) {
      errors['subnetMask'] = StaticRoutingErrorKeys.invalidSubnetMask;
    }
    if (gateway.isEmpty) {
      errors['gateway'] = StaticRoutingErrorKeys.gatewayRequired;
    } else if (!NetworkUtils.isValidIpAddress(gateway)) {
      errors['gateway'] = StaticRoutingErrorKeys.invalidIpAddress;
    } else if (_isReservedAddress(gateway)) {
      errors['gateway'] = StaticRoutingErrorKeys.reservedAddress;
    } else if (interfaceName != null && isLanHost != null) {
      // Validate gateway subnet based on interface selection.
      if (interfaceName == 'LAN' && !isLanHost(gateway)) {
        errors['gateway'] = StaticRoutingErrorKeys.gatewayMustBeWithinLanSubnet;
      } else if (interfaceName == 'LAN' && gateway == lanIp) {
        errors['gateway'] = StaticRoutingErrorKeys.gatewayIsRouter;
      } else if (interfaceName == 'Internet' && inLanSubnet(gateway)) {
        errors['gateway'] =
            StaticRoutingErrorKeys.gatewayMustBeOutsideLanSubnet;
      }
    }
    return errors;
  }

  /// Check a save of [original] to [current] the way FW will see it, before
  /// anything is written. Returns the [StaticRoutingErrorKeys] key of the first
  /// problem, or null.
  ///
  /// The dialog checks one route against the others; this replays the save
  /// itself (FWDEV#213, feed_usp#56). It goes Delete, then Set, then Add, and
  /// FW checks a name each time a route's Alias is written, against the names
  /// the other routes hold on the router at that moment:
  /// - An edited route's name may not be held by any route the Deletes left,
  ///   under its old name or its new one: how FW orders the routes inside one
  ///   Set is not known, so two routes swapping names is refused either way.
  /// - An added route's name may not be held by any route once the Sets land,
  ///   nor by another added route.
  /// - A route the save does not write is not checked, so two routes an older
  ///   build saved under one name do not block a save that writes neither.
  ///
  /// The limit applies only when the save adds a route, and is counted after
  /// the Deletes: FW counts when a new route gets its destination, so routes
  /// past 20 from an older build stay editable.
  static String? validateList({
    required List<StaticRouteUIModel> original,
    required List<StaticRouteUIModel> current,
  }) {
    final kept = {
      for (final r in current)
        if (r.instancePath != null) r.instancePath!,
    };
    final remaining = [
      for (final r in original)
        if (r.instancePath != null && kept.contains(r.instancePath)) r,
    ];
    final byPath = {for (final r in remaining) r.instancePath!: r};
    final edited = [
      for (final r in current)
        if (r.instancePath != null &&
            byPath[r.instancePath] != null &&
            byPath[r.instancePath] != r)
          r,
    ];
    final added = [
      for (final r in current)
        if (r.instancePath == null) r,
    ];

    for (final e in edited) {
      final taken = {
        for (final r in remaining)
          if (r.instancePath != e.instancePath) r.name,
        for (final o in edited)
          if (o.instancePath != e.instancePath) o.name,
      };
      if (taken.contains(e.name)) return StaticRoutingErrorKeys.duplicateName;
    }
    final afterSets = {
      for (final r in current)
        if (r.instancePath != null) r.name,
    };
    for (final a in added) {
      if (!afterSets.add(a.name)) return StaticRoutingErrorKeys.duplicateName;
    }

    if (added.isNotEmpty &&
        remaining.length + added.length > kMaxStaticRoutes) {
      return StaticRoutingErrorKeys.tooManyRoutes;
    }
    return null;
  }

  StaticRouteUIModel copyWith({
    String? instancePath,
    bool? enabled,
    String? name,
    String? destIpAddress,
    String? destSubnetMask,
    String? gatewayIpAddress,
    String? interfaceName,
  }) {
    return StaticRouteUIModel(
      instancePath: instancePath ?? this.instancePath,
      enabled: enabled ?? this.enabled,
      name: name ?? this.name,
      destIpAddress: destIpAddress ?? this.destIpAddress,
      destSubnetMask: destSubnetMask ?? this.destSubnetMask,
      gatewayIpAddress: gatewayIpAddress ?? this.gatewayIpAddress,
      interfaceName: interfaceName ?? this.interfaceName,
    );
  }

  @override
  List<Object?> get props => [
        instancePath,
        enabled,
        name,
        destIpAddress,
        destSubnetMask,
        gatewayIpAddress,
        interfaceName,
      ];
}
