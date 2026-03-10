# Changelog

All notable changes to PrivacyGUI after version 2.0.0 are documented in this file.

## [2.1.0] - 2026-03-10

### USP Protocol Integration

#### Device Search Field & IPv6 Data Extension
- Extend `connected_devices.yaml` with IPv6 children (`Device.Hosts.Host.{i}.IPv6Address.{i}.IPAddress`)
- Add `DeviceSearchField` reusable widget with `DeviceSearchMode` (ipv4/ipv6/mac) — `RawAutocomplete` with device name, address, and MAC fuzzy search
- Integrate into IPv6 Port Service Add/Edit Rule dialog — select from known devices with IPv6 addresses
- Add `ipv6Addresses: List<String>` to `DeviceUIModel`

#### USP Console & Menu Improvements
- Add TR-181 path autocomplete to USP Console (8K+ paths from `tr-181-2-20-0-usp-full.xml`)
- Migrate USP Console to UI Kit components (`AppButton.*`, `AppTextField`)
- Add Advanced Settings submenu (Local Network, Firewall, DMZ, Port Forwarding, Static Routing)
- Nest sub-routes under Advanced Settings for proper back navigation
- Remove IPv6 Firewall standalone menu item (merged into Firewall)
- Increase dashboard topology card client-node spacing (`nodeSpacing * 1.4`, `orbitRadius * 1.4`)
- Wrap TR-181 autocomplete and generated path data in `kDebugMode` for production size protection

#### Selective Get Optimization & Codegen v0.10.3
- Migrate 8 YAML definitions to new `multiInstance` format with selective get search paths (connected_devices, data_elements_network, wi_fi_radios, wi_fi_access_points, wi_fi_ssids, port_forwarding, port_triggering, firewall_chain_rules)
- Upgrade `usp-codegen` to v0.10.3 — phantom instance filter skips all-default empty instances from wildcard search path queries (BUG-003)
- Remove `fetchAll` from port_forwarding — selective get now safe with phantom filter
- Fix `UspService._coerceValue`: empty string returns `''` not `null`
- Fix `UspService.get`: skip wildcard paths in missing-path check
- Fix `_fetchDefaultGateway`: use wildcard search paths instead of index-based loop (non-contiguous routing table instance IDs)

#### Firewall Settings Page (F-005)
- Add `FirewallUIModel` with 8 boolean toggles (SPI IPv4/IPv6, VPN passthrough, internet filters)
- Add `UspFirewallService` — scatter-gather fetch, Description-based rule identification, Target-aware toggle inversion
- Add `UspFirewallNotifier` with `isDirty` / batch `save()` pattern
- Add `UspFirewallView` — 3-section layout (Firewall Protection, VPN Passthrough, Internet Filters)

#### System Log & System Monitor
- Add System Log page — `VendorLogFiles` codegen definition, fetch + display log content
- Add `UspSystemMonitorCard` with real-time CPU/memory polling via `Device.DeviceInfo.ProcessStatus`
- Add `SignalStrengthIndicator` reusable component for WiFi signal display

#### Phase 3: UI Model Layer — Presentation/Data Decoupling
- Establish Presentation Layer UI Models per constitution Article V Section 5.3 — views no longer import codegen `generated/*.g.dart` files
- Add 6 UI Models: `SystemInfoUIModel`, `DeviceUIModel`, `WifiRadioUIModel`, `TimeSettingsUIModel`, `DhcpReservationUIModel`, `PortForwardingRuleUIModel`
- Add `UspDeviceService` (Article VI stateless service) — consolidates all Data Model → UI Model transformation
- Refactor all dashboard cards to consume UI Models with computed getters (`formattedUptime`, `signalQuality`, `displayName`, `portSummary`, etc.)
- Refactor all dialogs (`TimeSettingsDialog`, `WifiChannelDialog`, `PortForwardingDialog`) to accept UI Models instead of codegen types
- Change `updatePortForwardingRule` notifier to accept primitive params — eliminates last codegen import from view layer
- Add USP Dashboard shell with tab navigation (Home / Menu / Support)

#### Phase 0: Codegen Toolchain & Validation
- Add USP (TR-369) HTTP/WASM client (`lib/usp/`) with JS interop
- Implement `usp-codegen` CLI (v0.6.1) — YAML definition → Dart data class + CRUD methods
- Add 8 YAML definitions: SystemInfo, ConnectedDevices, WiFiRadios, WiFiSsids, WiFiAccessPoints, TimeSettings, DhcpReservations, PortForwarding
- Add `UspService` with GET/SET/ADD/DELETE/OPERATE APIs
- Add `UspResponseExtension` helpers (`getInstances`, `getString`, `getBool`, `getInt`)
- Validate codegen through 5 iterations (v1→v5), fixing class name collision, reserved word escaping, trailing dot normalization

#### Phase 2A: USP Dashboard — Read-Only
- Add standalone USP Dashboard page with 7 read-only cards: Device Info, System Status, Connected Devices, WiFi Status, Time Settings, DHCP Reservations, Protocol Info
- Implement session restore on page reload (WASM state recovery)
- Cross-reference WiFi AP → SSID via `ssidReference` path
- Parallel `Future.wait` fetch for all 8 data categories (WASM client v0.6.1+)

#### Phase 2D: USP Dashboard — Ethernet Port Status
- Add `EthernetInterfaces` YAML definition + codegen for `Device.Ethernet.Interface.{i}` (multi-instance)
- Add `EthernetPortUIModel` with `WiredDeviceInfo` for wired device detail (hostname, MAC, IP)
- Add `UspEthernetPortsCard` with SVG port icons (green=Up, gray=Down) and speed label (supports 2.5 Gbps)
- Add port detail dialog (`showEthernetPortDetailDialog`) — tap port to view interface info and connected devices
- WAN ports use real `Ethernet.Interface.Status`; LAN ports derive effective status from `ConnectedDevices` cross-reference (switch chip always reports Up)
- Manually patch codegen boolean parsing for integer 0/1 values (`Upstream` field)

#### Phase 2C: USP Dashboard — Data Enrichment & Topology
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

#### Phase 2B: USP Dashboard — Write Operations
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
