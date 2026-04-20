# Unit Test Coverage Expansion Plan

## Context

Issue #704 identifies critical test coverage gaps: **28 test files / ~223 testable source files = ~12% file coverage**. The project has well-structured, testable architecture (thin services over codegen, uniform notifier mixin, Riverpod DI) but most business logic is untested.

**Already tested**: SSE module (#726, 179 tests), Dashboard Custom Layout (#724, 293 tests), WiFi/Internet settings services, Preservable framework basics, theme/validator utilities.

**Goal**: Systematically cover all untested service, notifier, framework, and provider layers to reach **~60%+ file coverage** with ~446 new tests across ~42 new/modified test files.

---

## Current Coverage Snapshot

| Layer | Total Files | Tested | Gap |
|-------|:-----------:|:------:|:---:|
| Core USP (SSE/Bridge) | 27 | 11 | Stubs/platform-only remaining |
| Page Services | 18 | 2 | **16 untested** |
| Notifiers (Pattern A: Preservable) | 9 | 0 | **9 untested** |
| Notifiers (Pattern B: AsyncNotifier) | 7 | 0 | **7 untested** |
| Shared Data Providers | 6 | 0 | **6 untested** |
| Framework (Preservable mixin) | 5 | 1 (partial) | **4 missing paths** |
| Auth System | 6 | 0 | **6 untested** |
| Generated Transforms | 1 | 0 | **1 untested** |

---

## Architecture Quick Reference

### Service Pattern (Layer 1)
```dart
class UspXxxService {
  final UspService _usp;
  Future<(XxxSettings, XxxStatus)> fetch() async {
    final data = await XxxCodegen.fetch(_usp);  // codegen static call
    return (buildSettings(data), buildStatus(data));
  }
  Future<void> save(...) async { ... }           // codegen CRUD
  XxxUIModel buildUIModel(XxxCodegen data) { ... } // transform
  Map<String, String> validateForm(...) { ... }    // validation
}
```

### Notifier Pattern A: Preservable (Layer 2)
```dart
class UspXxxNotifier extends AutoDisposeNotifier<XxxFeatureState>
    with PreservableAutoDisposeNotifierMixin<...> {
  build() { listen(sseInvalidationProvider); Future.microtask(() => fetch()); }
  performFetch() → calls service.fetch()
  performSave() → calls service.save/add/update/delete
  updateSetting() → synchronous UI mutation + validation
}
```

### Notifier Pattern B: Simple AsyncNotifier (Layer 2)
Direct `state = AsyncValue.data(...)`, no FeatureState/Preservable.

---

## Phases

### Phase 0: Shared Test Infrastructure
**Goal**: Consolidate reusable mocks and fixture factories.

| File | Purpose |
|------|---------|
| `test/shared/mocks.dart` | Re-export `MockUspService` from `test/core/usp/mocks.dart`; add service mocks (`MockUspDmzService`, `MockUspFirewallService`, etc.) for notifier tests |
| `test/shared/fixtures.dart` | Factory functions for codegen data classes with sensible defaults: `makeDmzEntry()`, `makeFirewallChainRule()`, `makeDhcpReservation()`, etc. |

**Tests**: 0 (infrastructure only)

---

### Phase 1: Framework Mixin Gap Coverage
**Goal**: Cover 4 missing `_PreservableDelegate` paths. Highest leverage — benefits all 9 Pattern A notifiers.

**File**: `test/framework/preservable_test.dart` (modify existing)

| # | Test | Target Code |
|---|------|-------------|
| 1-2 | `fetch(updateStatusOnly: true)` updates status only, settings unchanged | delegate:57-61 |
| 3-4 | `onSseInvalidation()` skips fetch when dirty, fetches when clean | delegate:95-102 |
| 5-6 | `performFetch` returns `(null, errorStatus)` — status updates, settings unchanged | delegate:72-74 |
| 7-8 | `save()` re-fetch failure — save still marked clean, error propagated | delegate:84-88 |
| 9-10 | `fetch(forceRemote: true)` with both settings+status returned | delegate:65-69 |

**Tests**: ~10

---

### Phase 2: Simple Services (5 services, quick wins)

| Service | File | Lines | Key Tests | Est. Tests |
|---------|------|:-----:|-----------|:----------:|
| **UspDmzService** | `test/page/dmz/services/usp_dmz_service_test.dart` | 117 | buildUIModel (empty/single/sourceType), validateForm (5 rules), add/update codegen calls | 12 |
| **UspAdminService** | `test/page/admin/services/usp_admin_service_test.dart` | 66 | fetchAdmin (find admin user, fallback), updatePassword, buildTimeSettingsUIModel | 6 |
| **UspSystemLogService** | `test/page/system_log/services/usp_system_log_service_test.dart` | 35 | fetch mapping, empty input, multiple items | 3 |
| **UspInstantSafetyService** | `test/page/instant_safety/services/usp_instant_safety_service_test.dart` | 63 | detectType (openDNS/off), dnsValueForType, save | 6 |
| **UspDhcpService** | `test/page/dhcp/services/usp_dhcp_service_test.dart` | 103 | fetchReservations mapping, saveBatch (delete/add/update/mixed/no-change) | 10 |

**Tests**: ~37

---

### Phase 3: Medium Services (5 services, meaningful logic)

| Service | File | Lines | Key Tests | Est. Tests |
|---------|------|:-----:|-----------|:----------:|
| **UspFirewallService** | `test/page/firewall/services/usp_firewall_service_test.dart` | 220 | parseFirewallRules (desc→key), buildUIModel (Accept inversion, Drop passthrough, missing rules), buildSetPayload (paired rules: SPI×2, IPSec×2; single rules; no-change) | 18 |
| **UspStaticRoutingService** | `test/page/static_routing/services/usp_static_routing_service_test.dart` | 174 | buildRouteUIModels (origin filter, interface→display), validateRoute (7+ rules), saveBatch | 16 |
| **UspIpv6PortServiceService** | `test/page/ipv6_port_service/services/usp_ipv6_port_service_service_test.dart` | 212 | buildRuleUIModels (ipVersion/target filter, IANA→display), validateRule (6+ rules), saveBatch | 18 |
| **UspPortForwardingService** | `test/page/port_forwarding/services/usp_port_forwarding_service_test.dart` | 196 | saveForwardingBatch, saveTriggeringBatch (parent+child add ordering) | 12 |
| **InstantPrivacyService** | `test/page/instant_privacy/services/instant_privacy_service_test.dart` | 230 | activeDevices filter, isEnabled logic, allowedDevices parsing, buildEnable/DisableUpdates, validateMac, normalizeMac | 16 |

**Tests**: ~80

---

### Phase 4: Complex Services (3 large services)

| Service | File | Lines | Key Tests | Est. Tests |
|---------|------|:-----:|-----------|:----------:|
| **UspLocalNetworkService** | `test/page/local_network/services/usp_local_network_service_test.dart` | 276 | DNS parsing, leaseTime conversion, 8+ validation methods, lockedOctetCount, syncPrefix, save diff logic | 30 |
| **UspDeviceService** | `test/page/_shared/services/usp_device_service_test.dart` | 502 | 12+ build methods (systemInfo, firmwareImages, devices, wifiRadios, dhcpClients, dhcpReservations, portForwarding, lanInfo, wanStatus, ethernetPorts, nodes) | 35 |
| **WiFiChannelBonding** | `test/page/wifi_settings/services/wifi_channel_bonding_test.dart` | 288 | computeChannelsPerBandwidth (2.4/5/6 GHz × each width), maxBandwidthForStandards, minStandardForBandwidth | 25 |

**Tests**: ~90

---

### Phase 5: Generated Transforms
**File**: `test/generated/transforms_test.dart`

| Function | Tests |
|----------|:-----:|
| cidrToNetmask (bounds, edge cases) | 4 |
| formatBandwidth (Mbps/Gbps transition) | 3 |
| formatDuration (h+m+s combos) | 3 |
| formatBytes (B→TB transitions) | 3 |
| formatPercent, formatNumber, formatSpeed | 6 |
| hexDecode, durationSeconds/Ms | 6 |

**Tests**: ~25

---

### Phase 6: Auth System

| File | Tests | Key Tests |
|------|:-----:|-----------|
| `test/providers/auth/auth_service_test.dart` | 10 | getStoredLocalPassword, getStoredLoginType, saveLocalPassword, clearAllCredentials (happy + error paths) |
| `test/providers/auth/auth_result_test.dart` | 8 | AuthSuccess/AuthFailure when/map dispatch, isSuccess/isFailure, equality |
| `test/providers/auth/auth_state_test.dart` | 6 | empty(), copyWith, fromJson, Equatable |

**Tests**: ~24

---

### Phase 7: Notifiers — Pattern A (9 Preservable notifiers)

Each notifier test follows a uniform template (~9 tests each):
1. `build()` returns initial loading state
2. `performFetch()` calls service.fetch(), maps result
3. `performFetch()` error → `(null, errorStatus)` path
4. `performSave()` calls correct service methods from current state
5. `updateSetting()` mutations + validation wiring
6. SSE invalidation domain wiring (correct domain triggers `onSseInvalidation`)
7. Feature-specific mutations (add/edit/toggle/delete for list-based features)

| Notifier | File | Differentiator |
|----------|------|---------------|
| UspDmzNotifier | `test/page/dmz/providers/usp_dmz_notifier_test.dart` | isNewEntry → add vs update |
| UspFirewallNotifier | `test/page/firewall/providers/usp_firewall_notifier_test.dart` | reads from firewallDataProvider |
| UspDhcpReservationsNotifier | `test/page/dhcp/providers/usp_dhcp_reservations_notifier_test.dart` | list add/edit/toggle/delete |
| UspStaticRoutingNotifier | `test/page/static_routing/providers/usp_static_routing_notifier_test.dart` | list mutations |
| UspIpv6PortServiceNotifier | `test/page/ipv6_port_service/providers/usp_ipv6_port_service_notifier_test.dart` | list + validation |
| UspLocalNetworkNotifier | `test/page/local_network/providers/usp_local_network_notifier_test.dart` | cascade validation |
| UspPortForwardingNotifier | `test/page/port_forwarding/providers/usp_port_forwarding_notifier_test.dart` | forwarding + triggering tabs |
| UspInternetSettingsNotifier | `test/page/internet_settings/providers/usp_internet_settings_notifier_test.dart` | WAN type switch |
| UspWifiSettingsNotifier | `test/page/wifi_settings/providers/usp_wifi_settings_notifier_test.dart` | multi-AP config |

**Tests**: ~85

---

### Phase 8: Notifiers — Pattern B (7 Simple AsyncNotifiers)

| Notifier | File | Key Tests | Est. Tests |
|----------|------|-----------|:----------:|
| UspAdminNotifier | `test/page/admin/providers/usp_admin_notifier_test.dart` | fetch admin+time, setPassword, reboot | 8 |
| InstantPrivacyNotifier | `test/page/instant_privacy/providers/instant_privacy_notifier_test.dart` | enable/disable/addMac, optimistic UI, error rollback | 10 |
| NetworkDiagnosticsNotifier | `test/page/network_diagnostics/providers/usp_network_diagnostics_notifier_test.dart` | runPing/Traceroute with mock awaiter, timeout | 12 |
| SystemLogNotifier | `test/page/system_log/providers/usp_system_log_notifier_test.dart` | simple fetch | 3 |
| SystemMonitorNotifier | `test/page/_shared/providers/usp_system_monitor_notifier_test.dart` | ring buffer, CPU/memory %, timer lifecycle | 10 |
| TrafficAnalysisNotifier | `test/page/_shared/providers/usp_traffic_analysis_notifier_test.dart` | rate from deltas, counter wraparound, ring buffer | 10 |
| DeviceAnalyticsNotifier | `test/page/_shared/providers/usp_device_analytics_notifier_test.dart` | distribution, hourly aggregate, 24h pruning | 7 |

**Tests**: ~60

---

### Phase 9: Shared Data Providers

| Provider | File | Key Tests | Est. Tests |
|----------|------|-----------|:----------:|
| DhcpDataNotifier | `test/page/local_network/providers/dhcp_data_provider_test.dart` | dual fetch, hostname enrichment, mutations, SSE debounce | 10 |
| LanDataNotifier | `test/page/local_network/providers/lan_data_provider_test.dart` | fetch + IPv6 fallback | 4 |
| EthernetDataNotifier | `test/page/local_network/providers/ethernet_data_provider_test.dart` | bridge port classification | 5 |
| TimeDataNotifier | `test/page/admin/providers/time_data_provider_test.dart` | fetch + updateTimezone | 5 |
| SystemInfoDataNotifier | `test/page/admin/providers/system_info_data_provider_test.dart` | fetch + firmware assembly | 5 |
| DevicesDataNotifier | `test/page/devices/providers/devices_data_provider_test.dart` | complex aggregation | 6 |

**Tests**: ~35

---

## Summary

| Phase | Scope | New Files | Tests | Dependency |
|-------|-------|:---------:|:-----:|:----------:|
| 0 | Shared infrastructure | 2 | 0 | — |
| 1 | Framework mixin gaps | 0 (modify) | 10 | Phase 0 |
| 2 | Simple services (5) | 5 | 37 | Phase 0 |
| 3 | Medium services (5) | 5 | 80 | Phase 0 |
| 4 | Complex services (3) | 3 | 90 | Phase 0 |
| 5 | transforms.g.dart | 1 | 25 | — |
| 6 | Auth system | 3 | 24 | Phase 0 |
| 7 | Notifiers Pattern A (9) | 9 | 85 | Phase 2-4 |
| 8 | Notifiers Pattern B (7) | 7 | 60 | Phase 0 |
| 9 | Shared data providers | 6 | 35 | Phase 2-4 |
| **Total** | | **~41 files** | **~446** | |

### Execution Order (recommended)

```
Phase 0 → Phase 1 → Phase 2 → Phase 5 → Phase 3 → Phase 6 → Phase 4 → Phase 7 → Phase 8 → Phase 9
```

Phases 1-6 have no cross-dependencies (only depend on Phase 0). Phases 7-9 depend on service tests being established.

### Parallelizable Groups
- **Group A** (independent): Phase 1, Phase 5, Phase 6
- **Group B** (sequential): Phase 2 → Phase 3 → Phase 4
- **Group C** (after B): Phase 7 → Phase 9
- **Group D** (after Phase 0): Phase 8

---

## Test Conventions

- **Mocking**: `mocktail` exclusively (established pattern)
- **Codegen data**: Construct directly (`DmzEntry(...)`) — no mocking
- **Service tests**: `MockUspService` injected, no ProviderContainer needed
- **Notifier tests**: `ProviderContainer` with service provider overrides
- **Timer tests**: `fakeAsync` for SystemMonitor/TrafficAnalysis
- **Directory mirroring**: `lib/page/xxx/` → `test/page/xxx/`
- **Static codegen methods**: Mock at `UspService` level (codegen calls `client.get()` internally)

## Verification

```bash
# Per-phase verification
flutter test test/framework/                    # Phase 1
flutter test test/page/dmz/                     # Phase 2 (per feature)
flutter test test/generated/                    # Phase 5

# Full regression
./run_tests.sh
```
