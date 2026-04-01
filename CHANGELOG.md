# Changelog

All notable changes to PrivacyGUI after version 2.0.0 are documented in this file.

## [2.1.0] - 2026-03-13

#### WiFi Settings Page (USP)
- Add WiFi Settings page: `UspWifiSettingsService` + `UspWifiSettingsProvider`, route and menu entry
- Add `WifiNetworkUIModel` — cross-reference enrichment joining SSID + AccessPoint + Radio data
- UI: WifiListTile-style cards with responsive grid, modal-based editing for SSID, password, security, channel, bandwidth, and WiFi Mode (OperatingStandards)
- Add Advanced tab with DFS/IEEE-802.11h toggle; remove MAC Filtering tab (vendor extension, not standard TR-181)
- Fix `SSIDAdvertisementEnabled` TR-181 path: `Device.WiFi.SSID` → `Device.WiFi.AccessPoint`
- Integrate Dirty Guard: staged mutations buffered until Save, tab change guard, Dirty Guard route interception
- Add Quick Setup mode: apply uniform settings across all bands with automatic 6 GHz WPA3 override
- Add JNAP-to-TR181 field mapping reference doc (134 actions mapped)

## [2.1.0] - 2026-03-12

### USP Protocol Integration

#### USP Subscription & Notification Pipeline
- Add `UspService.createNotifySubscription()` — client-side OBUSPA subscription creation via USP Add + Set with GET-diff instance discovery (workaround for WASM `add` returning empty on `Device.LocalAgent.Subscription.`)
- Add `UspService.deleteNotifySubscription()` — USP Delete for subscription cleanup
- Add OperationComplete and Event notification types to test console subscription dropdown
- Add "Create USP Subscription" button to test console — creates OBUSPA `Device.LocalAgent.Subscription.{i}` with proper Recipient (UDS controller) for SSE delivery
- Verified end-to-end async Operate flow: IPPing + TraceRoute → OperationComplete via SSE ✅
- Update `subscription-notify-blocked.md` — Issue 2 (Notify→SSE) verified fixed, add bridge enhancement request for auto-register

#### Comprehensive PDF Report (F-025)
- Rewrite `UspPdfService` — expand from basic dashboard export to comprehensive multi-page report
- Add `PdfReportData` model — aggregates dashboard state, polling providers, and feature data
- Report sections: System Overview, Network Status, Connected Devices, WiFi Performance, Traffic Analysis, Network Health, Firewall, Port Forwarding, DMZ, Static Routing
- Include charts and statistics from dashboard card data

#### Dashboard Layout Presets & Responsive Scaling
- Add `UspDashboardPreset` — predefined layout configurations (default, compact, monitoring, etc.)
- Add `PresetSelectionDialog` — visual preset picker for quick layout switching
- Add `UspWidgetSpecs.scaleLayout()` — proportional 12→8 (tablet) / 12→4 (mobile) column scaling
- Add `UspBarsVisibleProvider` — scroll-direction-aware top/bottom bar visibility

#### Shell & Navigation Improvements
- Add scroll-aware bar hiding to `UspDashboardShell` — `NotificationListener<UserScrollNotification>` hides top/bottom bars on scroll-down, restores on scroll-up
- Add `UiKitPageView` back button visibility control
- Add session token refresh retry to `AuthProvider`

#### Statistics Page Improvements
- Add `StatsSectionCard` reusable component for consistent section styling
- Refactor `stats_traffic_trends_section` — simplify chart configuration
- Refactor `stats_activity_heatmap_section` and `stats_signal_quality_section` layout improvements
- Add statistics view section registration updates

#### Port Forwarding Detail View Refactor
- Refactor `UspPortForwardingDetailView` tab layout and styling

#### USP Page App Bar Migration
- Migrate 15 USP pages from custom `_buildHeader()` to `UiKitPageView` built-in app bar (`title` + `onBackTap`)
- Wire `onBackTap` through UI Kit chain: `UiKitPageView` → `PageAppBarConfig` → `AppPageView` → `AppUnifiedBar`
- `onBackTap` callback always shows back button with custom fallback navigation (`context.canPop()` → `context.goNamed()`)
- Remove app bar `actions` — move refresh, spinner, and device count into page content:
  - 5 refresh-only pages (Topology, Firewall, Local Network, DMZ, System Log): rely on `onRefresh` pull-to-refresh
  - Static Routing / IPv6 Port Service: spinner/refresh moved to section title Row alongside add button
  - Device List: count text (`N / total`) moved below search bar
- Add `onRefresh` to Topology page (previously missing)
- Skipped: Sliver Dashboard (custom layout), Test Console (special purpose)

#### Internet Settings Page (baeb9b2c, a0aec135)
- Add USP YAML definitions: `wan_settings` (19 fields incl. connection type, DHCP/Static/PPPoE/PPTP/L2TP/Bridge), `ipv6_settings` (automatic/6rd/pass-through), `wan_operations` (Renew/Release)
- Add `UspInternetSettingsView` — sectioned form layout (IPv4, IPv6, Optional Settings, Renew/Release)
- Add `UspInternetSettingsFormModel` with `UspWanConnectionType` enum and per-type field validation
- Add `UspInternetSettingsFormValidator` — connection-type-aware required field validation
- Add `UspInternetSettingsNotifier` / `UspInternetSettingsState` — form state management with dirty tracking
- Add `UspInternetSettingsService` — fetch + save via codegen `WanSettings` / `Ipv6Settings`
- Add `UspConnectionStatusBanner`, `UspSectionCard`, `UspRenewActionCard` view components
- Add SSH-validated set-path analysis docs — JNAP vs USP field mapping comparison, fix design, Linksys vendor extension parameters (`X_LINKSYS_DefaultGateway`, `X_LINKSYS_DNSServers`)
- Update codegen output for all generated files (improved fetch/save signatures)
- Refine USP Dashboard components (WiFi card, time settings, topology, device list)
- Improve auth provider token refresh retry and protocol error handling
- Add unit tests for form validator and service layer

#### USP Feature Pages (947a3dba, 8eecf073)
- Add DMZ settings page — View/Provider/Service with enable toggle, host IP configuration
- Add IPv6 Port Service page — full CRUD for IPv6 inbound port rules (add/edit/delete/toggle)
- Add Local Network page — LAN IP, subnet mask, DHCP range display and configuration
- Add Static Routing page — route table with add/edit/delete dialogs
- Add Port Forwarding Detail page — tabbed view with Single Port, Port Range, Port Triggering
- Add Admin page — password change, timezone configuration, reboot
- Add DHCP Detail page — active client leases + reservation management
- Add codegen definitions: `firmware_images`, `dmz`, `ipv6_port_service`, `static_routing`

#### Device Search Field & IPv6 Data Extension (947a3dba)
- Extend `connected_devices.yaml` with IPv6 children (`Device.Hosts.Host.{i}.IPv6Address.{i}.IPAddress`)
- Add `DeviceSearchField` reusable widget with `DeviceSearchMode` (ipv4/ipv6/mac) — `RawAutocomplete` with device name, address, and MAC fuzzy search
- Integrate into IPv6 Port Service Add/Edit Rule dialog — select from known devices with IPv6 addresses
- Add `ipv6Addresses: List<String>` to `DeviceUIModel`

#### USP Console & Menu Improvements (947a3dba)
- Add TR-181 path autocomplete to USP Console (8K+ paths from `tr-181-2-20-0-usp-full.xml`)
- Migrate USP Console to UI Kit components (`AppButton.*`, `AppTextField`)
- Add Advanced Settings submenu (Local Network, Firewall, DMZ, Port Forwarding, Static Routing)
- Nest sub-routes under Advanced Settings for proper back navigation
- Remove IPv6 Firewall standalone menu item (merged into Firewall)
- Increase dashboard topology card client-node spacing (`nodeSpacing * 1.4`, `orbitRadius * 1.4`)
- Wrap TR-181 autocomplete and generated path data in `kDebugMode` for production size protection

#### Real-Time Traffic Monitor (F-018)
- Add `WanTrafficStats` codegen definition — `Device.IP.Interface.2.Stats.{BytesSent,BytesReceived,PacketsSent,PacketsReceived}`
- Add `UspTrafficMonitorCard` with dual-line chart (upload primary / download secondary), auto-scaled Y-axis, gradient fill
- Add `UspTrafficMonitorNotifier` — 2s default polling interval, delta-based rate calculation, 60-point ring buffer
- Add `TrafficMonitorState` / `TrafficSnapshot` state model following SystemMonitor pattern
- Speed display with auto-scaled units (B/s → KB/s → MB/s → GB/s), cumulative totals via `Transforms.formatBytes`
- Interval selector (Off / 2s / 5s / 10s) matching SystemStatus card pattern
- Register in `UspWidgetSpecs` (6×4), `UspWidgetFactory`, default layout next to System Status

#### Dashboard Custom Layout (SliverDashboard)
- Add drag-drop / resize dashboard with `sliver_dashboard` — `UspSliverDashboardView`, `DashboardOverlay`, edit mode with jiggle animation
- Fixed slot height (120px per row) via dynamic `slotAspectRatio` calculation using `LayoutBuilder`
- Default 2-column grid layout (12-column, w=6 per card)
- Add `UspWidgetSpecs` — per-card `WidgetGridConstraints` (min/max columns, height rows, `HeightStrategy`)
- Add `UspWidgetFactory` — ID → Widget mapping for grid item builder
- Add `UspLayoutController` — SharedPreferences persistence for layout & edit mode state
- Add `UspLayoutPreferences` — widget visibility, layout reset; `useCustomLayout = true` default
- Add `UspLayoutSettingsPanel` — available widgets re-add (categorized: built-in & app widgets), reset layout to defaults
- Convert `UspStatsPanel` to `ConsumerWidget` (self-contained provider read) + add to widget specs registry
- Remove firmware images section from `UspDeviceInfoCard` (reduce height for grid fit)
- Increase `SystemStatus` card height (h=3→4) to accommodate gauges + chart
- Header buttons switch between normal (print/refresh/edit) and edit mode (optimize/tune/cancel/save)
- Add `UspDashboardSkeleton` with paired-row layout matching grid structure
- Remove `UspConnectionStatusCard` (redundant with Stats Panel)

#### Dashboard Layout & Topology Improvements
- Ethernet Ports: Show one LAN port entry per active wired device instead of single aggregate (switch chip limitation — TR-181 only exposes 1 LAN `Ethernet.Interface` for 3 physical ports)
- Use bridge membership (`Device.Bridging.Bridge.*.Port.*.LowerLayers`) for WAN/LAN classification instead of inverted `Upstream` flag
- Stats Panel: Add Router count tile, Port Rules tile; simplify Devices tile to online count only
- Topology: Auto-switch `ClientVisibility` — expanded (`always`) when <8 clients, indicator ring (`onHover`) when >=8
- Desktop layout: Place Device Info and Network Status cards side by side
- Remove `UspProtocolInfoCard` (no longer needed)
- Clean up verbose debug logging in dashboard notifier
- Replace `DeviceSearchField` with `SelectAutoComplete` reusable widget
- Port Forwarding dialog: Integrate device search for IP address selection

#### Network Health Monitoring (F-022)
- Add `UspNetworkHealthCard` — 3-tab card (Health, Errors, Loss) sharing `uspTrafficAnalysisProvider` timer
- Health tab: `AppGauge` composite score (0-100) from packet loss + error/discard rates, WAN/LAN traffic light indicators
- Errors tab: Error/discard rate `AppLineChart` area chart over time with avg/peak legend
- Loss tab: Packet loss % `AppLineChart` over time with avg/peak legend
- Add `NetworkHealthHelpers` — `HealthTier` enum, score computation, tier color mapping, fault rate formatting
- Register in `UspWidgetSpecs` (6×4), `UspWidgetFactory`, default layout at y=4

#### Firewall Configuration Overview (F-023)
- Add `UspFirewallOverviewCard` — 2-tab card (Rules, Ports)
- Rules tab: Target distribution `AppPieChart` donut (Accept/Drop/Reject/Other) + active/total rule count + port forward/DMZ stats
- Ports tab: Top-5 port forwarding rules with protocol badge + enable dot, DMZ section, protocol `AppBarChart` distribution
- Extend `UspDashboardState` with `FirewallChainRules` + `Dmz` raw data fields
- Extend `UspDashboardNotifier._fetchAll()` with `FirewallChainRules.fetch()` + `Dmz.fetch()` (17 parallel fetches)
- Descoped from "Activity Visualization" — TR-181 `FirewallChainRule` lacks hit count/timestamp/event log
- Register in `UspWidgetSpecs` (6×4), `UspWidgetFactory`, default layout at y=29

#### WiFi Performance Analytics (F-024)
- Add `UspWifiPerformanceCard` — 3-tab card (Signal, Speed, Channels)
- Signal tab: Per-client RSSI `AppBarChart` with tier coloring (Excellent ≥-50, Good ≥-60, Fair ≥-70, Weak <-70 dBm)
- Speed tab: Per-client DL/UL grouped `AppBarChart` with auto-format (kbps → Mbps → Gbps)
- Channels tab: Per-radio info (band + channel + bandwidth + client count) + band distribution `AppPieChart` donut
- Add `WifiPerformanceHelpers` — `SignalTier` enum, SNR computation, speed formatting, tier color mapping
- Uses `connectionDetailMap[mac].band` for accurate AP→Radio band mapping (replaces naive AP index heuristic)
- Register in `UspWidgetSpecs` (6×5), `UspWidgetFactory`, default layout at y=23

#### Bugfix: SliverDashboard crash
- Fix "Unexpected null value" at `sliver_dashboard.dart:621` during paint — removed `optimizeLayout()` calls from `UspLayoutController` that mutated `DashboardController` after widget tree was built
- Add stale layout validation — saved layout from SharedPreferences checked against current `UspWidgetSpecs.all` IDs; discarded if missing new widget IDs

#### Dashboard & Shell Improvements (947a3dba, 3169d7c6, 8eecf073)
- Merge `UspSystemMonitorCard` into `UspSystemStatusCard` — unified CPU/memory/firmware display
- Add `FirmwareImages` codegen definition — display firmware slots with active/boot status in Device Info card
- Add `WanStatus` YAML definition + `UspNetworkStatusCard` with WAN IP, gateway, MTU, IPv6 display
- Redesign `UspStatsPanel` summary row layout
- Add dashboard skeleton loading animation during initial fetch
- Refactor USP navigation to shared `MenuHolder` pattern — `MenuController` with configurable `navigatorKey` + `pathResolver`, `NaviType.resolveUspPath()`, delete `UspNavTab`
- Fix MenuHolder theme: prefer inherited dark theme from parent context, fallback to getIt for JNAP compatibility
- Fix Advanced Settings page styling — add `UspTopBar`, back button header, responsive 2-column layout
- Fix shell/topbar theme design style reactivity (`AppDesignTheme` listener)
- Fix `EthernetInterface.Upstream` boolean coercion for integer 0/1 values
- Add USP Bridge Client turbo HTTP session support (start/heartbeat/status/release)
- Relocate USP dashboard from `lib/page/usp_test/` to `lib/usp_page/`

#### Selective Get Optimization & Codegen v0.10.3 (61b45a4b, bcb843c6)
- Migrate 8 YAML definitions to new `multiInstance` format with selective get search paths (connected_devices, data_elements_network, wi_fi_radios, wi_fi_access_points, wi_fi_ssids, port_forwarding, port_triggering, firewall_chain_rules)
- Upgrade `usp-codegen` to v0.10.3 — phantom instance filter skips all-default empty instances from wildcard search path queries (BUG-003)
- Remove `fetchAll` from port_forwarding — selective get now safe with phantom filter
- Fix `UspService._coerceValue`: empty string returns `''` not `null`
- Fix `UspService.get`: skip wildcard paths in missing-path check
- Fix `_fetchDefaultGateway`: use wildcard search paths instead of index-based loop (non-contiguous routing table instance IDs)

#### Firewall Settings Page (61b45a4b)
- Add `FirewallUIModel` with 8 boolean toggles (SPI IPv4/IPv6, VPN passthrough, internet filters)
- Add `UspFirewallService` — scatter-gather fetch, Description-based rule identification, Target-aware toggle inversion
- Add `UspFirewallNotifier` with `isDirty` / batch `save()` pattern
- Add `UspFirewallView` — 3-section layout (Firewall Protection, VPN Passthrough, Internet Filters)

#### System Log & System Monitor (61b45a4b, c772bcb3)
- Add System Log page — `VendorLogFiles` codegen definition, fetch + display log content
- Add `UspSystemMonitorCard` with real-time CPU/memory polling via `Device.DeviceInfo.ProcessStatus`
- Add `SignalStrengthIndicator` reusable component for WiFi signal display

#### Phase 3: UI Model Layer — Presentation/Data Decoupling (86e8815a)
- Establish Presentation Layer UI Models per constitution Article V Section 5.3 — views no longer import codegen `generated/*.g.dart` files
- Add 6 UI Models: `SystemInfoUIModel`, `DeviceUIModel`, `WifiRadioUIModel`, `TimeSettingsUIModel`, `DhcpReservationUIModel`, `PortForwardingRuleUIModel`
- Add `UspDeviceService` (Article VI stateless service) — consolidates all Data Model → UI Model transformation
- Refactor all dashboard cards to consume UI Models with computed getters (`formattedUptime`, `signalQuality`, `displayName`, `portSummary`, etc.)
- Refactor all dialogs (`TimeSettingsDialog`, `WifiChannelDialog`, `PortForwardingDialog`) to accept UI Models instead of codegen types
- Change `updatePortForwardingRule` notifier to accept primitive params — eliminates last codegen import from view layer
- Add USP Dashboard shell with tab navigation (Home / Menu / Support)

#### Phase 0: Codegen Toolchain & Validation (e5382392, 5acebdbc)
- Add USP (TR-369) HTTP/WASM client (`lib/usp/`) with JS interop
- Implement `usp-codegen` CLI (v0.6.1) — YAML definition → Dart data class + CRUD methods
- Add 8 YAML definitions: SystemInfo, ConnectedDevices, WiFiRadios, WiFiSsids, WiFiAccessPoints, TimeSettings, DhcpReservations, PortForwarding
- Add `UspService` with GET/SET/ADD/DELETE/OPERATE APIs
- Add `UspResponseExtension` helpers (`getInstances`, `getString`, `getBool`, `getInt`)
- Validate codegen through 5 iterations (v1→v5), fixing class name collision, reserved word escaping, trailing dot normalization

#### Phase 2A: USP Dashboard — Read-Only (7ddd7c08)
- Add standalone USP Dashboard page with 7 read-only cards: Device Info, System Status, Connected Devices, WiFi Status, Time Settings, DHCP Reservations, Protocol Info
- Implement session restore on page reload (WASM state recovery)
- Cross-reference WiFi AP → SSID via `ssidReference` path
- Parallel `Future.wait` fetch for all 8 data categories (WASM client v0.6.1+)

#### Phase 2D: USP Dashboard — Ethernet Ports, Device List & Topology (e2bd260f)
- Add `EthernetInterfaces` YAML definition + codegen for `Device.Ethernet.Interface.{i}` (multi-instance)
- Add `EthernetPortUIModel` with `WiredDeviceInfo` for wired device detail (hostname, MAC, IP)
- Add `UspEthernetPortsCard` with SVG port icons (green=Up, gray=Down) and speed label (supports 2.5 Gbps)
- Add port detail dialog (`showEthernetPortDetailDialog`) — tap port to view interface info and connected devices
- WAN ports use real `Ethernet.Interface.Status`; LAN ports derive effective status from `ConnectedDevices` cross-reference (switch chip always reports Up)
- Manually patch codegen boolean parsing for integer 0/1 values (`Upstream` field)
- Add Device List view with filter panel (by mesh node, SSID, band) and device detail view
- Add Topology view with interactive mesh node visualization and node detail view
- Add `LanNetworkInfo` codegen definition for LAN IP/subnet/DHCP display

#### Phase 2C: USP Dashboard — Data Enrichment & Topology (6ab0b72e, c772bcb3, 1281594e)
- Upgrade `usp-codegen` to v0.10.0 — recursive multi-level `children` nesting support
- Add `DataElementsNetwork` YAML definition (4-level: Device → Radio → BSS → STA) for EasyMesh topology
- Add `WiFiClients` YAML definition with `flatten: true` + `nestedPath` for nested multi-instance
- Rewrite `mesh_node_enricher` — replace 153-line manual parsing with codegen `DataElementsNetwork.fetch()`
- Rewrite `wifi_client_enricher` — replace manual AP.AssociatedDevice parsing with codegen `WifiClients.fetch()`
- Add WiFi client connection detail enrichment: cross-reference AP → SSID → Radio for band + SSID name per client
- Add mesh node topology: `MeshTopologyInfo` with client→node mapping, graceful fallback for non-mesh routers
- Add `UspNetworkTopologyCard` with `AppTopology` visualization (gateway, extenders, clients with signal quality)
- **Connected Devices**: Show band/SSID/Ethernet, signal strength (dBm + color), parent node name ("via MR7500")
- **WiFi Status Card**: Group Access Points under their parent Radio section
- Add `UspStatsPanel` summary row with online devices, WiFi radios, DHCP, port forwarding counts
- Add codegen example YAMLs: `example_nested_multi_instance.yaml`, `example_flatten_multi_instance.yaml`
- Rename `usp_dashboard_provider.dart` → `usp_dashboard_state.dart` (clarify state vs provider)

#### Phase 2B: USP Dashboard — Write Operations (7ddd7c08, 6c89d808, 98dd0f79, 1e5f8d57)
- Refactor provider architecture: `FutureProvider` → `AsyncNotifierProvider` with `_withLock()` sequential mutation guard
- Add `copyWith()` immutable state updates to `UspDashboardState`
- **WiFi Radio**: Enable/disable toggle (`AppSwitch`) + channel edit dialog (auto/manual)
- **DHCP Reservations**: Enable toggle + add dialog + delete with confirmation
- **Port Forwarding**: Enable toggle + add/edit dialog + delete with confirmation
- **Time Settings**: Enable inline toggle + edit dialog (NTP Server 1/2)
- Add Port Forwarding read-only card (8th card)
- Add `uspMutationLoadingProvider` for per-card loading state during mutations
- Update codegen YAML definitions with `writable: true` and `type: add` flags
- Fix `UspService.add()` to accept `Map<String, dynamic>` (consistent with `set()`)
- Rename YAML definition files to snake_case (Dart naming convention)
- Clean up verbose debug logging in `UspService.get()`

### Features
- Add dynamic upper bound for speed test gauge based on historical data (#628)
- Add server selection dialog for speed test (#623)
- Implement device-specific dynamic theme switching (#620)
- Add automated constitution compliance enforcement (#627)
- Migrate hostname validation & JNAP null guards from dev-1.2.8 (#631)

### Bug Fixes
- Fix SI units for speed test conversion
- Migrate missing fixes from dev-1.2.7 (#619)

### Maintenance
- Migrate PrivacyGUI 1.2.8 features to UI Kit (#616)
- Translate documentation and test data to English (#612)

---

## [2.0.0] - 2026-02-03

### Architecture Overhaul
- **Three-Layer Architecture**: Refactor all feature modules to Notifier → Service → JNAP separation
  - Firewall (IPv6 port service, settings)
  - DMZ settings
  - Administration
  - Static routing
  - WiFi settings
  - Internet settings
  - Local network settings
  - DHCP reservations
  - Port range forwarding / triggering
  - Single port forwarding
  - Instant Setup (PnP, auto-parent, safety, topology, privacy, verify)
  - Node detail, connectivity, node light settings
  - WAN external, polling service
  - Health check
  - Dashboard manager
- **UI Model Separation**: Decouple JNAP models from presentation layer across all modules
- **Unified ServiceError**: Add `ServiceError` pattern replacing ad-hoc error handling
- **Provider Decoupling**: Decouple cross-page provider dependencies (#551, #552)
- **Conditional Exports**: Encapsulate platform-specific exports with entry points (#583)

### UI Kit Migration
- Migrate all UI components to `ui_kit_library` shared component system
- Resolve Phase 2 & 3 UI issues (Topology, Layout, Focus) (#581)
- Reorganize shared widgets (#618)

### Platform Support
- Add iOS platform support with Local/Remote flavors
- Clean up Xcode project configuration

### Features
- Add Remote Assistance implementation & Theme Studio fixes (#608)
- Add custom dashboard layout demo (#589)
- Add Router AI Assistant (#538)
- Add dirty-guard framework integration (#476)

### Testing
- Add comprehensive golden test / screenshot testing framework
  - `testLocalizationsV2` helper, `takeScreenshot` utilities
  - Generate test report script with HTML output
  - Tests for PnP, WiFi, Internet settings, firmware update, speed test, instant setup, device detail, topology, admin, privacy, verify, health check
- Add unit tests for state/model classes (236 tests)
- Add E2E test suite implementation (#471)
- Refactor golden test framework (#470)

### Documentation
- Consolidate architecture audit and renumber specs
- Translate all documentation and audit documents to English
- Add screenshot testing guideline

### Maintenance
- Fix almost all warnings in lib (#479)
- Apply dart format across codebase
- Untrack auto-generated and tool configuration files from version control
