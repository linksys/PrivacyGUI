import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_routing_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_routing_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/utils.dart';

/// Service layer for static routing feature
///
/// Handles all JNAP protocol communication and data transformation between
/// JNAP models (Data layer) and UI models (Presentation layer).
///
/// This service is responsible for:
/// - Fetching routing settings from device via JNAP
/// - Transforming JNAP models to UI models
/// - Saving routing settings back to device
/// - Handling errors gracefully
///
/// The service accepts a RouterRepository instance for dependency injection,
/// making it easily testable by mocking the repository.
class StaticRoutingService {
  /// RouterRepository instance for JNAP communication
  final RouterRepository _routerRepository;

  /// Create a new StaticRoutingService instance
  ///
  /// Parameters:
  /// - [routerRepository]: RouterRepository for JNAP communication
  StaticRoutingService(this._routerRepository);

  /// Fetch routing settings from device
  ///
  /// Retrieves both routing configuration and network context from the device.
  /// Combines GetRoutingSettings (routing config) with RouterLANSettings
  /// (network context like router IP and subnet mask).
  ///
  /// Returns a tuple of (StaticRoutingUISettings, StaticRoutingStatus) on success.
  /// Returns (null, null) if the fetch fails due to JNAP error or malformed response.
  ///
  /// Parameters:
  /// - [forceRemote]: If true, fetches from cloud; otherwise uses local cache
  ///
  /// Throws: May throw on network errors, but handles JNAP protocol errors gracefully
  Future<(StaticRoutingUISettings?, StaticRoutingStatus?)>
      fetchRoutingSettings({
    bool forceRemote = false,
  }) async {
    try {
      // Fetch LAN settings for network context (router IP, subnet mask)
      final lanSettingsResponse = await _routerRepository.send(
        JNAPAction.getLANSettings,
        auth: true,
        fetchRemote: forceRemote,
      );
      final lanSettings = RouterLANSettings.fromMap(lanSettingsResponse.output);
      final routerIP = lanSettings.ipAddress;
      final subnetMask = NetworkUtils.prefixLengthToSubnetMask(
        lanSettings.networkPrefixLength,
      );

      // Fetch routing settings from device
      final routingSettingsResponse = await _routerRepository.send(
        JNAPAction.getRoutingSettings,
        auth: true,
        fetchRemote: forceRemote,
      );
      final jnapRoutingSettings =
          GetRoutingSettings.fromMap(routingSettingsResponse.output);

      // Transform JNAP models to UI models
      final uiSettings = _transformFromJNAP(jnapRoutingSettings);
      final status = StaticRoutingStatus(
        maxStaticRouteEntries: jnapRoutingSettings.maxStaticRouteEntries,
        routerIp: routerIP,
        subnetMask: subnetMask,
      );

      return (uiSettings, status);
    } catch (e) {
      // Graceful error handling - return null on failure
      return (null, null);
    }
  }

  /// Validate a single route entry
  ///
  /// Performs comprehensive validation on route configuration:
  /// - Route name: non-empty, max 32 characters
  /// - Destination IP: valid IPv4 format
  /// - Subnet mask: valid IPv4 or CIDR prefix length (0-32)
  /// - Gateway: valid IPv4 format or empty
  ///
  /// Returns: Map of validation errors. Empty map means validation passed.
  /// Keys are field names (name, destinationIP, subnetMask, gateway)
  /// Values are user-friendly error messages.
  Map<String, String> validateRouteEntry(StaticRouteEntryUIModel entry) {
    final errors = <String, String>{};

    // Validate route name
    if (entry.name.isEmpty) {
      errors['name'] = 'Route name cannot be empty';
    } else if (entry.name.length > 32) {
      errors['name'] = 'Route name must be 32 characters or less';
    }

    // Validate destination IP
    if (!_isValidIPv4(entry.destinationIP)) {
      errors['destinationIP'] = 'Invalid destination IP address format';
    }

    // Validate subnet mask (can be dotted decimal or CIDR prefix)
    if (!_isValidSubnetMask(entry.subnetMask)) {
      errors['subnetMask'] = 'Invalid subnet mask format';
    }

    // Validate gateway (if provided)
    if (entry.gateway.isNotEmpty && !_isValidIPv4(entry.gateway)) {
      errors['gateway'] = 'Invalid gateway IP address format';
    }

    return errors;
  }

  /// Check if string is a valid IPv4 address
  ///
  /// Valid formats:
  /// - 192.168.1.1
  /// - 10.0.0.0
  /// - etc.
  bool _isValidIPv4(String ip) {
    if (ip.isEmpty) return false;

    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }

    return true;
  }

  /// Check if string is a valid subnet mask (dotted decimal or prefix length)
  ///
  /// Valid formats:
  /// - Dotted decimal: 255.255.255.0, 255.255.0.0, etc.
  /// - Prefix length as string: "24", "16", etc. (0-32)
  bool _isValidSubnetMask(String mask) {
    if (mask.isEmpty) return false;

    // Try as prefix length (0-32)
    final prefixLength = int.tryParse(mask);
    if (prefixLength != null && prefixLength >= 0 && prefixLength <= 32) {
      return true;
    }

    // Try as dotted decimal IPv4
    return _isValidIPv4(mask);
  }

  /// Save routing settings to device
  ///
  /// Validates all route entries before transmission.
  /// Transforms UI models back to JNAP SetRoutingSettings model
  /// and sends to device via RouterRepository.
  ///
  /// Parameters:
  /// - [settings]: UI model with current routing configuration
  ///
  /// Throws: Exception if validation fails or on network errors
  Future<void> saveRoutingSettings(
    StaticRoutingUISettings settings,
  ) async {
    // Validate all route entries before saving
    for (final entry in settings.entries) {
      final errors = validateRouteEntry(entry);
      if (errors.isNotEmpty) {
        throw Exception('Route validation failed: ${errors.values.join(", ")}');
      }
    }

    // Transform UI models to JNAP SetRoutingSettings
    final jnapSettings = _transformToJNAP(settings);

    // Send to device
    await _routerRepository.send(
      JNAPAction.setRoutingSettings,
      auth: true,
      fetchRemote: true,
      data: jnapSettings.toMap(),
    );
  }

  /// Transform JNAP GetRoutingSettings to UI StaticRoutingUISettings
  ///
  /// Converts JNAP data model to presentation layer UI model.
  /// Transform JNAP NamedStaticRouteEntry to UI StaticRoutingRuleUI
  ///
  /// Converts JNAP protocol model to UI presentation model for the rule editor.
  /// This is used by the StaticRoutingRuleNotifier to display rule details.
  ///
  /// Parameters:
  /// - [jnapEntry]: NamedStaticRouteEntry from JNAP protocol
  ///
  /// Returns: StaticRoutingRuleUI for UI layer
  StaticRoutingRuleUIModel transformJNAPRuleToUIModel(
    NamedStaticRouteEntry jnapEntry,
  ) {
    return StaticRoutingRuleUIModel(
      name: jnapEntry.name,
      destinationIP: jnapEntry.settings.destinationLAN,
      networkPrefixLength: jnapEntry.settings.networkPrefixLength,
      gateway: jnapEntry.settings.gateway,
      interface: jnapEntry.settings.interface,
    );
  }

  /// Transform UI StaticRoutingRuleUI to JNAP NamedStaticRouteEntry
  ///
  /// Converts UI presentation model to JNAP protocol model for saving.
  /// This is used by the StaticRoutingNotifier to convert user input.
  ///
  /// Parameters:
  /// - [uiModel]: StaticRoutingRuleUI from UI layer
  ///
  /// Returns: NamedStaticRouteEntry for JNAP protocol transmission
  NamedStaticRouteEntry transformUIModelToJNAPRule(
    StaticRoutingRuleUIModel uiModel,
  ) {
    return NamedStaticRouteEntry(
      name: uiModel.name,
      settings: StaticRouteEntry(
        destinationLAN: uiModel.destinationIP,
        gateway: uiModel.gateway?.isNotEmpty ?? false ? uiModel.gateway : null,
        interface: uiModel.interface,
        networkPrefixLength: uiModel.networkPrefixLength,
      ),
    );
  }

  /// This transformation isolates the UI from JNAP implementation details.
  ///
  /// Parameters:
  /// - [jnapSettings]: GetRoutingSettings from device (JNAP model)
  ///
  /// Returns: StaticRoutingUISettings for presentation layer
  StaticRoutingUISettings _transformFromJNAP(
    GetRoutingSettings jnapSettings,
  ) {
    final entries = jnapSettings.entries
        .map(
          (entry) => StaticRouteEntryUIModel(
            name: entry.name,
            // JNAP uses 'destinationLAN' with network prefix length
            destinationIP: entry.settings.destinationLAN,
            subnetMask: NetworkUtils.prefixLengthToSubnetMask(
              entry.settings.networkPrefixLength,
            ),
            gateway: entry.settings.gateway ?? '',
            interface: entry.settings.interface,
          ),
        )
        .toList();

    return StaticRoutingUISettings(
      isNATEnabled: jnapSettings.isNATEnabled,
      isDynamicRoutingEnabled: jnapSettings.isDynamicRoutingEnabled,
      entries: entries,
    );
  }

  /// Transform UI StaticRoutingUISettings to JNAP SetRoutingSettings
  ///
  /// Converts presentation layer UI model to JNAP data model for device.
  /// This transformation prepares UI data for JNAP protocol transmission.
  ///
  /// Parameters:
  /// - [uiSettings]: StaticRoutingUISettings from presentation layer
  ///
  /// Returns: SetRoutingSettings ready for JNAP transmission
  SetRoutingSettings _transformToJNAP(
    StaticRoutingUISettings uiSettings,
  ) {
    final entries = uiSettings.entries
        .map(
          (entry) => NamedStaticRouteEntry(
            name: entry.name,
            settings: StaticRouteEntry(
              destinationLAN: entry.destinationIP,
              gateway: entry.gateway.isNotEmpty ? entry.gateway : null,
              interface: entry.interface,
              networkPrefixLength:
                  NetworkUtils.subnetMaskToPrefixLength(entry.subnetMask),
            ),
          ),
        )
        .toList();

    return SetRoutingSettings(
      isNATEnabled: uiSettings.isNATEnabled,
      isDynamicRoutingEnabled: uiSettings.isDynamicRoutingEnabled,
      entries: entries,
    );
  }
}

/// Provider for StaticRoutingService
final staticRoutingServiceProvider = Provider<StaticRoutingService>(
  (ref) => StaticRoutingService(ref.watch(routerRepositoryProvider)),
);
