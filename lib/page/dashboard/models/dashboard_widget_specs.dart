import 'display_mode.dart';
import 'height_strategy.dart';
import 'widget_grid_constraints.dart';
import 'widget_spec.dart';

/// Specifications for all Dashboard components.
///
/// Defines grid constraints for each component across different [DisplayMode]s.
/// All column values are based on a 12-column layout.
abstract class DashboardWidgetSpecs {
  DashboardWidgetSpecs._();

  // ---------------------------------------------------------------------------
  // Internet Status
  // ---------------------------------------------------------------------------
  static const internetStatus = WidgetSpec(
    id: 'internet_status',
    displayName: 'Internet Status (Combined)',
    description:
        'Combined status including internet connectivity and master router info.',
    canHide: false,
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(1.0),
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 8,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
        minHeightRows: 2,
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 12,
        heightStrategy: HeightStrategy.strict(4.0),
        minHeightRows: 2,
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Networks (Node Status)
  // ---------------------------------------------------------------------------
  static const networks = WidgetSpec(
    id: 'networks',
    displayName: 'Networks',
    description: 'Combined view of network topology and device counts.',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(6.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(8.0),
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // WiFi Grid
  // ---------------------------------------------------------------------------
  static const wifiGrid = WidgetSpec(
    id: 'wifi_grid',
    displayName: 'Wi-Fi Networks',
    description: 'Overview of Wi-Fi networks and guest access.',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 8,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(1.0),
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy:
            HeightStrategy.strict(5.0), // 2 rows of cards (176px * 2 + spacing)
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 12,
        maxColumns: 12,
        preferredColumns: 12,
        heightStrategy: HeightStrategy.strict(6.0),
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Quick Panel
  // ---------------------------------------------------------------------------
  static const quickPanel = WidgetSpec(
    id: 'quick_panel',
    displayName: 'Quick Panel',
    description: 'Quick access to common settings and actions.',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0),
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(4.0),
        minHeightRows: 2,
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4.0),
        minHeightRows: 2,
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Port and Speed
  // ---------------------------------------------------------------------------
  static const portAndSpeed = WidgetSpec(
    id: 'port_and_speed',
    displayName: 'Ports & Speed',
    description: 'Combined view of ethernet ports and speed test results.',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Standard Widgets (used in Standard Layout)
  // ---------------------------------------------------------------------------
  static const List<WidgetSpec> standardWidgets = [
    internetStatus,
    networks,
    wifiGrid,
    quickPanel,
    portAndSpeed,
    vpn,
  ];

  // ---------------------------------------------------------------------------
  // Atomic Widgets (used in Custom/Bento Layout)
  // ---------------------------------------------------------------------------

  /// Internet status only (online/offline, geolocation, uptime)
  static const internetStatusOnly = WidgetSpec(
    id: 'internet_status_only',
    displayName: 'Internet Status',
    description: 'Shows internet connectivity status only.',
    canHide: false,
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0),
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
    },
  );

  /// Master node info (router image, model, serial, firmware)
  static const masterNodeInfo = WidgetSpec(
    id: 'master_node_info',
    displayName: 'Master Router',
    description: 'Information about the master node (model, serial, firmware).',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0),
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  /// Ports status (LAN + WAN)
  static const ports = WidgetSpec(
    id: 'ports',
    displayName: 'Ports',
    description: 'Status of LAN and WAN ethernet ports.',
    constraints: _portsVerticalConstraints,
  );

  // ---------------------------------------------------------------------------
  // Ports Constraints Variations
  // ---------------------------------------------------------------------------

  /// Constraints for "No LAN" (WAN only) - Minimal height
  static const _portsNoLanConstraints = {
    DisplayMode.compact: WidgetGridConstraints(
      minColumns: 3,
      maxColumns: 4,
      preferredColumns: 4,
      heightStrategy: HeightStrategy.strict(1.0),
      minHeightRows: 1,
    ),
    DisplayMode.normal: WidgetGridConstraints(
      minColumns: 4,
      maxColumns: 6,
      preferredColumns: 4,
      heightStrategy: HeightStrategy.strict(2.0),
    ),
    DisplayMode.expanded: WidgetGridConstraints(
      minColumns: 4,
      maxColumns: 8,
      preferredColumns: 6,
      heightStrategy: HeightStrategy.strict(2.0),
    ),
  };

  /// Constraints for Horizontal Layout (Row) - Wider, less height
  static const _portsHorizontalConstraints = {
    DisplayMode.compact: WidgetGridConstraints(
      minColumns: 6,
      maxColumns: 12,
      preferredColumns: 8,
      heightStrategy: HeightStrategy.strict(1.0),
      minHeightRows: 1,
    ),
    DisplayMode.normal: WidgetGridConstraints(
      minColumns: 8,
      maxColumns: 12,
      preferredColumns: 12,
      heightStrategy: HeightStrategy.strict(2.0),
    ),
    DisplayMode.expanded: WidgetGridConstraints(
      minColumns: 8,
      maxColumns: 12,
      preferredColumns: 12,
      heightStrategy: HeightStrategy.strict(2.0),
    ),
  };

  /// Constraints for Vertical Layout (Column) - Narrower, more height
  static const _portsVerticalConstraints = {
    DisplayMode.compact: WidgetGridConstraints(
      minColumns: 3,
      maxColumns: 6,
      preferredColumns: 4,
      heightStrategy: HeightStrategy.strict(1.0), // Changed from 2.0 to 1.0
      minHeightRows: 1,
    ),
    DisplayMode.normal: WidgetGridConstraints(
      minColumns: 4,
      maxColumns: 8,
      preferredColumns: 6,
      heightStrategy: HeightStrategy.strict(3.0),
    ),
    DisplayMode.expanded: WidgetGridConstraints(
      minColumns: 6,
      maxColumns: 12,
      preferredColumns: 8,
      heightStrategy: HeightStrategy.strict(4.0),
    ),
  };

  /// Get ports spec with dynamic constraints based on state
  static WidgetSpec getPortsSpec({
    required bool hasLanPort,
    required bool isHorizontal,
  }) {
    Map<DisplayMode, WidgetGridConstraints> selectedConstraints;

    if (!hasLanPort) {
      selectedConstraints = _portsNoLanConstraints;
    } else if (isHorizontal) {
      selectedConstraints = _portsHorizontalConstraints;
    } else {
      selectedConstraints = _portsVerticalConstraints;
    }

    return WidgetSpec(
      id: ports.id,
      displayName: ports.displayName,
      description: ports.description,
      canHide: ports.canHide,
      requirements: ports.requirements,
      constraints: selectedConstraints,
    );
  }

  /// Speed test results
  static const speedTest = WidgetSpec(
    id: 'speed_test',
    displayName: 'Speed Test',
    description: 'Internet speed test results and history.',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0), // Changed from 2.0
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  /// Network stats (nodes/devices count)
  static const networkStats = WidgetSpec(
    id: 'network_stats',
    displayName: 'Network Stats',
    description: 'Counts of connected nodes and devices.',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0),
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
    },
  );

  /// Mesh topology tree view
  static const topology = WidgetSpec(
    id: 'topology',
    displayName: 'Topology',
    description: 'Visual map of your mesh network topology.',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0), // Changed from 3.0
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(6.0),
        minHeightRows: 5,
      ),
    },
  );

  /// Custom layout widgets (atomic components)
  static const List<WidgetSpec> customWidgets = [
    internetStatusOnly,
    masterNodeInfo,
    ports,
    speedTest,
    networkStats,
    topology,
    wifiGrid,
    quickPanel,
    vpn,
  ];

  // ---------------------------------------------------------------------------
  // All Specs List (for UI iteration)
  // ---------------------------------------------------------------------------
  static const List<WidgetSpec> all = [
    internetStatus,
    networks,
    wifiGrid,
    quickPanel,
    portAndSpeed,
    vpn,
    // Atomic widgets
    internetStatusOnly,
    masterNodeInfo,
    ports,
    speedTest,
    networkStats,
    topology,
  ];

  // ---------------------------------------------------------------------------
  // VPN (if supported)
  // ---------------------------------------------------------------------------
  static const vpn = WidgetSpec(
    id: 'vpn',
    displayName: 'VPN',
    description: 'VPN connection status.',
    requirements: const [WidgetRequirement.vpnSupported],
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0), // Changed from 2.0
        minHeightRows: 1,
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  /// Get spec by ID
  static WidgetSpec? getById(String id) {
    for (final spec in all) {
      if (spec.id == id) return spec;
    }
    return null;
  }
}
