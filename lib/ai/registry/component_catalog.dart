/// Component catalog for Router AI Assistant.
///
/// This file defines metadata for all UI components available to the AI,
/// providing a single source of truth for:
/// 1. Which components are registered in RouterComponentRegistry
/// 2. Component categories (high-level vs basic)
/// 3. Component props for validation
///
/// The sync test ensures this catalog matches the actual registry.
library;

/// Represents a UI component available to the AI.
class ComponentMetadata {
  final String name;
  final ComponentCategory category;
  final String description;
  final List<String> requiredProps;
  final List<String> optionalProps;

  const ComponentMetadata({
    required this.name,
    required this.category,
    required this.description,
    this.requiredProps = const [],
    this.optionalProps = const [],
  });
}

/// Component categories for organization and prompt generation.
enum ComponentCategory {
  /// Composable data sections - the smallest domain-specific units.
  /// AI combines these inside AppCard to build custom displays.
  dataSection,

  /// Pre-composed cards for common single-domain displays.
  /// Kept for backward compatibility but AI should prefer sections.
  legacyCard,

  /// Basic display components for custom layouts.
  basicDisplay,

  /// Container components for grouping content.
  container,

  /// Layout components for arranging children.
  layout,

  /// Interactive components (buttons, inputs, dialogs).
  interactive,
}

/// The complete catalog of components available to the Router AI Assistant.
///
/// This is the source of truth for:
/// - Component names that must be registered in RouterComponentRegistry
/// - Props that each component accepts
/// - Categories used in the system prompt
class ComponentCatalog {
  ComponentCatalog._();

  /// All registered components.
  static const List<ComponentMetadata> components = [
    // =========================================================================
    // DATA SECTIONS — Composable data blocks (Preferred)
    // =========================================================================

    // Utilities
    ComponentMetadata(
      name: 'SectionHeader',
      category: ComponentCategory.dataSection,
      description: 'Section title with optional badge',
      requiredProps: ['title'],
      optionalProps: ['badge'],
    ),
    ComponentMetadata(
      name: 'AiInfoRow',
      category: ComponentCategory.dataSection,
      description: 'Label-value row for data display',
      requiredProps: ['label', 'value'],
    ),

    // WAN
    ComponentMetadata(
      name: 'WanSection',
      category: ComponentCategory.dataSection,
      description: 'WAN connection status rows',
      requiredProps: ['wanStatus'],
      optionalProps: ['connectedDevices', 'wanIp', 'connectionType'],
    ),

    // LAN
    ComponentMetadata(
      name: 'LanSection',
      category: ComponentCategory.dataSection,
      description: 'LAN configuration rows',
      requiredProps: ['ipAddress', 'subnetMask'],
      optionalProps: [
        'dhcpEnabled',
        'dhcpRange',
        'dnsServers',
        'ipv6Enabled',
        'ipv6Addresses'
      ],
    ),

    // WiFi
    ComponentMetadata(
      name: 'WifiSection',
      category: ComponentCategory.dataSection,
      description: 'WiFi settings rows',
      requiredProps: ['ssid'],
      optionalProps: ['password', 'securityMode', 'band'],
    ),

    // Devices
    ComponentMetadata(
      name: 'DevicesSection',
      category: ComponentCategory.dataSection,
      description: 'Connected devices list',
      requiredProps: ['devices'],
      optionalProps: ['maxCount'],
    ),

    // System
    ComponentMetadata(
      name: 'SystemSection',
      category: ComponentCategory.dataSection,
      description: 'CPU, Memory gauges with uptime',
      requiredProps: ['cpuPercent', 'memoryPercent'],
      optionalProps: ['uptime'],
    ),

    // Firewall
    ComponentMetadata(
      name: 'FirewallSection',
      category: ComponentCategory.dataSection,
      description: 'Firewall status rows',
      requiredProps: ['enabled'],
      optionalProps: ['ipv4Enabled', 'ipv6Enabled', 'ruleCount', 'dmzEnabled'],
    ),

    // Ethernet
    ComponentMetadata(
      name: 'EthernetSection',
      category: ComponentCategory.dataSection,
      description: 'Ethernet port status',
      requiredProps: ['ports'],
    ),

    // DHCP
    ComponentMetadata(
      name: 'DhcpSection',
      category: ComponentCategory.dataSection,
      description: 'DHCP reservations and clients',
      optionalProps: ['reservations', 'clients'],
    ),

    // Port Forwarding
    ComponentMetadata(
      name: 'PortForwardingSection',
      category: ComponentCategory.dataSection,
      description: 'Port forwarding rules list',
      optionalProps: ['rules'],
    ),

    // =========================================================================
    // ADVANCED SECTIONS
    // =========================================================================

    // Topology
    ComponentMetadata(
      name: 'TopologySection',
      category: ComponentCategory.dataSection,
      description: 'Network topology visualization',
      requiredProps: ['gatewayName'],
      optionalProps: ['gatewayModel', 'extenders', 'clients', 'maxClients'],
    ),

    // Diagnostics
    ComponentMetadata(
      name: 'DiagnosticsSection',
      category: ComponentCategory.dataSection,
      description: 'Ping, traceroute, DNS results',
      optionalProps: ['pingResult', 'tracerouteResult', 'dnsResult'],
    ),

    // =========================================================================
    // CHART SECTIONS
    // =========================================================================

    // Line Chart
    ComponentMetadata(
      name: 'LineChartSection',
      category: ComponentCategory.dataSection,
      description: 'Time-series line chart',
      requiredProps: ['series'],
      optionalProps: [
        'height',
        'showGrid',
        'showDots',
        'filled',
        'yMin',
        'yMax',
        'yUnit'
      ],
    ),

    // Bar Chart
    ComponentMetadata(
      name: 'BarChartSection',
      category: ComponentCategory.dataSection,
      description: 'Categorical bar chart',
      requiredProps: ['series'],
      optionalProps: ['xLabels', 'height', 'stacked', 'horizontal'],
    ),

    // Pie Chart
    ComponentMetadata(
      name: 'PieChartSection',
      category: ComponentCategory.dataSection,
      description: 'Proportional pie/donut chart',
      requiredProps: ['sections'],
      optionalProps: ['height', 'donut', 'showLabels'],
    ),

    // =========================================================================
    // LEGACY CARDS — Pre-composed cards (Deprecated, prefer Sections)
    // =========================================================================

    // Network & WAN
    ComponentMetadata(
      name: 'NetworkStatusCard',
      category: ComponentCategory.legacyCard,
      description: 'WAN connection status, device count, speeds',
      optionalProps: [
        'wanStatus',
        'connectedDevices',
        'uploadSpeed',
        'downloadSpeed'
      ],
    ),
    ComponentMetadata(
      name: 'EthernetPortsCard',
      category: ComponentCategory.legacyCard,
      description: 'Physical port status and connections',
      optionalProps: ['ports'],
    ),

    // LAN & DHCP
    ComponentMetadata(
      name: 'LanInfoCard',
      category: ComponentCategory.legacyCard,
      description: 'LAN configuration display',
      optionalProps: [
        'ipAddress',
        'subnetMask',
        'dhcpEnabled',
        'dhcpRange',
        'dnsServers',
        'ipv6Enabled',
        'ipv6Addresses'
      ],
    ),
    ComponentMetadata(
      name: 'DhcpCard',
      category: ComponentCategory.legacyCard,
      description: 'DHCP reservations and active clients',
      optionalProps: ['reservations', 'clients'],
    ),

    // Security
    ComponentMetadata(
      name: 'FirewallCard',
      category: ComponentCategory.legacyCard,
      description: 'Firewall status and rules count',
      optionalProps: [
        'ipv4Enabled',
        'ipv6Enabled',
        'ruleCount',
        'dmzEnabled',
        'portForwardingCount'
      ],
    ),
    ComponentMetadata(
      name: 'PortForwardingCard',
      category: ComponentCategory.legacyCard,
      description: 'Port forwarding rules list',
      optionalProps: ['rules'],
    ),

    // Devices
    ComponentMetadata(
      name: 'DeviceListView',
      category: ComponentCategory.legacyCard,
      description: 'Connected devices list with icons',
      optionalProps: ['devices'],
    ),

    // WiFi
    ComponentMetadata(
      name: 'WifiSettingsCard',
      category: ComponentCategory.legacyCard,
      description: 'WiFi network settings',
      optionalProps: ['ssid', 'password', 'securityMode', 'band'],
    ),

    // System
    ComponentMetadata(
      name: 'SystemResourceCard',
      category: ComponentCategory.legacyCard,
      description: 'CPU, Memory usage and uptime',
      optionalProps: ['cpuPercent', 'memoryPercent', 'uptime'],
    ),

    // =========================================================================
    // BASIC DISPLAY
    // =========================================================================
    ComponentMetadata(
      name: 'AppText',
      category: ComponentCategory.basicDisplay,
      description: 'Text display with variants',
      optionalProps: ['text', 'variant'],
    ),
    ComponentMetadata(
      name: 'AppBadge',
      category: ComponentCategory.basicDisplay,
      description: 'Status badge',
      optionalProps: ['label'],
    ),
    ComponentMetadata(
      name: 'AppIcon',
      category: ComponentCategory.basicDisplay,
      description: 'Icon display',
      optionalProps: ['icon', 'size'],
    ),

    // =========================================================================
    // CONTAINERS
    // =========================================================================
    ComponentMetadata(
      name: 'AppCard',
      category: ComponentCategory.container,
      description: 'Card with padding',
      optionalProps: ['childIds'],
    ),
    ComponentMetadata(
      name: 'AppSurface',
      category: ComponentCategory.container,
      description: 'Elevated surface',
      optionalProps: ['childIds', 'variant'],
    ),
    ComponentMetadata(
      name: 'AppListTile',
      category: ComponentCategory.container,
      description: 'List item with leading, title, subtitle, trailing',
      optionalProps: ['title', 'subtitle', 'leadingId', 'trailingId'],
    ),

    // =========================================================================
    // LAYOUT
    // =========================================================================
    ComponentMetadata(
      name: 'Column',
      category: ComponentCategory.layout,
      description: 'Vertical layout',
      optionalProps: ['childIds', 'justify', 'align'],
    ),
    ComponentMetadata(
      name: 'Row',
      category: ComponentCategory.layout,
      description: 'Horizontal layout',
      optionalProps: ['childIds', 'justify', 'align'],
    ),
    ComponentMetadata(
      name: 'Padding',
      category: ComponentCategory.layout,
      description: 'Add padding around content',
      optionalProps: ['padding', 'childIds'],
    ),
    ComponentMetadata(
      name: 'AppGap',
      category: ComponentCategory.layout,
      description: 'Spacing between components',
      optionalProps: ['size'],
    ),

    // =========================================================================
    // INTERACTIVE
    // =========================================================================
    ComponentMetadata(
      name: 'AppButton',
      category: ComponentCategory.interactive,
      description: 'Action button',
      optionalProps: ['label', 'variant'],
    ),
    ComponentMetadata(
      name: 'ConfirmationSheet',
      category: ComponentCategory.interactive,
      description: 'Dangerous operation confirmation',
      optionalProps: [
        'title',
        'message',
        'confirmLabel',
        'cancelLabel',
        'confirmAction'
      ],
    ),
  ];

  /// Get all component names.
  static List<String> get allComponentNames =>
      components.map((c) => c.name).toList();

  /// Get components by category.
  static List<ComponentMetadata> byCategory(ComponentCategory category) =>
      components.where((c) => c.category == category).toList();

  /// Get all data section names.
  static List<String> get dataSectionNames =>
      byCategory(ComponentCategory.dataSection).map((c) => c.name).toList();

  /// Get all legacy card names (deprecated, prefer sections).
  static List<String> get legacyCardNames =>
      byCategory(ComponentCategory.legacyCard).map((c) => c.name).toList();

  /// Get all high-level card names (alias for legacyCardNames for compatibility).
  static List<String> get highLevelCardNames => legacyCardNames;

  /// Get all basic component names (non-section, non-legacy).
  static List<String> get basicComponentNames => components
      .where((c) =>
          c.category != ComponentCategory.legacyCard &&
          c.category != ComponentCategory.dataSection)
      .map((c) => c.name)
      .toList();

  /// Find a component by name.
  static ComponentMetadata? findByName(String name) {
    try {
      return components.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
}
