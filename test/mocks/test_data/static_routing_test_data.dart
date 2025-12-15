import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';

/// Test data builder for StaticRoutingService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
///
/// Usage:
/// ```dart
/// when(() => mockRepo.send(any()))
///     .thenAnswer((_) async => StaticRoutingTestData.createSuccessfulResponse());
/// ```
class StaticRoutingTestData {
  /// Create default GetRoutingSettings success response
  static GetRoutingSettings createSuccessfulResponse({
    bool isNATEnabled = false,
    bool isDynamicRoutingEnabled = false,
    int maxStaticRouteEntries = 10,
    List<NamedStaticRouteEntry>? entries,
  }) =>
      GetRoutingSettings(
        isNATEnabled: isNATEnabled,
        isDynamicRoutingEnabled: isDynamicRoutingEnabled,
        maxStaticRouteEntries: maxStaticRouteEntries,
        entries: entries ?? _createDefaultEntries(),
      );

  /// Create LAN settings response for network context
  static RouterLANSettings createLANSettingsResponse({
    String ipAddress = '192.168.1.1',
    int networkPrefixLength = 24,
  }) =>
      RouterLANSettings(
        ipAddress: ipAddress,
        networkPrefixLength: networkPrefixLength,
        isDHCPEnabled: true,
        hostName: 'Linksys',
        minNetworkPrefixLength: 1,
        maxNetworkPrefixLength: 30,
        minAllowedDHCPLeaseMinutes: 1,
        maxDHCPReservationDescriptionLength: 64,
        dhcpSettings: const DHCPSettings(
          firstClientIPAddress: '192.168.1.100',
          lastClientIPAddress: '192.168.1.200',
          leaseMinutes: 1440,
          reservations: [],
        ),
      );

  /// Create a single route entry for testing
  static NamedStaticRouteEntry createRouteEntry({
    String name = 'Test Route',
    String destinationLAN = '10.0.0.0',
    String? gateway = '192.168.1.254',
    String interface = 'LAN',
    int networkPrefixLength = 24,
  }) =>
      NamedStaticRouteEntry(
        name: name,
        settings: StaticRouteEntry(
          destinationLAN: destinationLAN,
          gateway: gateway,
          interface: interface,
          networkPrefixLength: networkPrefixLength,
        ),
      );

  /// Create default empty route list
  static List<NamedStaticRouteEntry> _createDefaultEntries() => [];

  /// Create a complete successful JNAP response with default values
  static GetRoutingSettings createDefaultRoutingSettings() =>
      createSuccessfulResponse();

  /// Create routing settings with specific number of routes
  static GetRoutingSettings createWithRoutes(int count) {
    final entries = List.generate(
      count,
      (index) => createRouteEntry(
        name: 'Route $index',
        destinationLAN: '10.${index + 1}.0.0',
      ),
    );
    return createSuccessfulResponse(entries: entries);
  }

  /// Create routing settings at max capacity
  static GetRoutingSettings createAtMaxCapacity(int maxEntries) {
    final entries = List.generate(
      maxEntries,
      (index) => createRouteEntry(
        name: 'Route $index',
        destinationLAN: '10.${index + 1}.0.0',
      ),
    );
    return GetRoutingSettings(
      isNATEnabled: false,
      isDynamicRoutingEnabled: false,
      maxStaticRouteEntries: maxEntries,
      entries: entries,
    );
  }

  /// Create with NAT enabled
  static GetRoutingSettings createWithNATEnabled() =>
      createSuccessfulResponse(isNATEnabled: true);

  /// Create with dynamic routing enabled
  static GetRoutingSettings createWithDynamicRoutingEnabled() =>
      createSuccessfulResponse(isDynamicRoutingEnabled: true);

  /// Create with both NAT and dynamic routing enabled
  static GetRoutingSettings createWithBothEnabled() =>
      createSuccessfulResponse(
        isNATEnabled: true,
        isDynamicRoutingEnabled: true,
      );

  /// Create a UI model for a single rule (for Provider layer testing)
  static StaticRoutingRuleUIModel createUIRuleModel({
    String name = 'Test Route',
    String destinationIP = '10.0.0.0',
    int networkPrefixLength = 24,
    String? gateway = '192.168.1.254',
    String interface = 'LAN',
  }) =>
      StaticRoutingRuleUIModel(
        name: name,
        destinationIP: destinationIP,
        networkPrefixLength: networkPrefixLength,
        gateway: gateway,
        interface: interface,
      );

  /// Create a UI rule state
  static StaticRoutingRuleState createUIRuleState({
    List<StaticRoutingRuleUIModel>? rules,
    StaticRoutingRuleUIModel? rule,
    int? editIndex,
    String routerIp = '192.168.1.1',
    String subnetMask = '255.255.255.0',
  }) =>
      StaticRoutingRuleState(
        rules: rules ?? [],
        rule: rule,
        editIndex: editIndex,
        routerIp: routerIp,
        subnetMask: subnetMask,
      );
}
