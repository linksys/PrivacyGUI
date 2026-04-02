# Instant-Help (cs_diagnostic) Test Suite

## Running Tests

```bash
# Run all cs_diagnostic tests (135 tests)
fvm flutter test test/page/cs_diagnostic/

# Run specific test file
fvm flutter test test/page/cs_diagnostic/providers/jnap_parsing_test.dart
fvm flutter test test/page/cs_diagnostic/providers/cs_diagnostic_state_test.dart
fvm flutter test test/page/cs_diagnostic/models/diagnostic_client_test.dart
fvm flutter test test/page/cs_diagnostic/services/mock_diagnostic_data_test.dart

# Run with verbose output
fvm flutter test test/page/cs_diagnostic/ --reporter expanded
```

## Test Files

### 1. JNAP Parsing Tests (33 tests)
**File:** `providers/jnap_parsing_test.dart`

Tests that real JNAP response data from the M60CF router is correctly interpreted. Uses actual response fixtures captured 2026-04-02.

| Group | Tests | What It Validates |
|-------|-------|-------------------|
| GetDeviceInfo parsing | 3 | modelNumber, serialNumber, firmwareVersion extracted correctly |
| GetSystemStats parsing | 2 | uptimeSeconds extracted; CPU/memory gracefully absent when firmware omits them |
| Radio config parsing | 4 | channel 0 = Auto; both radios present with correct bands; band steering flag; channelWidth Auto display |
| buildDeviceMap from GetDevices3 | 6 | Device count; friendlyName as hostname; IP addresses; deviceType extraction; empty deviceType filtered; MAC uppercased |
| parseClients from NodesWireless | 8 | Client count; all wireless; all on 5GHz; negotiatedMbps fallback for TX/RX; hostnames merged; IPs merged; deviceType merged; signal strength classification |
| Speed test state | 7 | kbps→Mbps conversion; null handling; isSpeedTestRunning steps; copyWith clear flags; copyWith preservation |
| Full state construction | 1 | End-to-end: real JNAP data → CsDiagnosticState with all fields verified |

**Key fixture data:**
- Router: M60CF-EU, firmware 1.0.18.26040118
- 4 wireless clients on 5GHz with negotiatedMbps (no txRate/rxRate in wireless object)
- GetSystemStats: only uptimeSeconds (no CPULoad/MemoryLoad)
- GetRadioInfo3: channel 0 (Auto), channelWidth Auto, 802.11mixed

### 2. State Tests (49 tests)
**File:** `providers/cs_diagnostic_state_test.dart`

Tests all computed properties and state management of `CsDiagnosticState`.

| Group | Tests | What It Validates |
|-------|-------|-------------------|
| wanConnected | 5 | Connected/connected/Disconnected/null/missing key handling |
| dhcpUtilization | 4 | Correct ratio; division-by-zero guard; defaults; near-full pool |
| routerUptimeSeconds | 3 | Value from map; null map; missing key |
| flaggedClients | 4 | Empty list; weak signal flagging; wired exclusion; null signal with good rates |
| complexityScore | 5 | Minimal state; many clients; high DHCP; WAN down; recent reboot; max clamp |
| bandSteeringEnabled | 3 | Supported; not supported; null radioInfo |
| guestNetworkEnabled | 3 | Enabled; disabled; null |
| firmwareUpdateAvailable | 3 | Available; not available; null |
| macFilterMode | 5 | Allow; Deny; Disabled; isEnabled false; absent key |
| parentalControlsEnabled | 3 | Enabled; disabled; null |
| wirelessScheduleEnabled | 3 | Enabled; disabled; null |
| securityMode | 3 | Top-level; wpaPersonalSettings fallback; null |
| copyWith | 3 | Changed loadState; cleared errorMessage; preserved fields |

### 3. DiagnosticClient Model Tests (28 tests)
**File:** `models/diagnostic_client_test.dart`

Tests the client model's signal classification, flagging logic, OUI manufacturer lookup, and display name formatting.

| Group | Tests | What It Validates |
|-------|-------|-------------------|
| signalStrength | 6 | excellent/fair/weak/veryWeak boundaries; wired returns unknown; null signal returns unknown |
| isFlagged | 6 | Weak signal (<-75); boundary (-75 not flagged); low txRate; low rxRate; healthy not flagged; wired never flagged |
| manufacturer/OUI lookup | 5 | Apple; Samsung; Linksys prefixes; unknown OUI returns null; short MAC returns null; lowercase handled |
| displayName/displayNameWithOui | 4 | Hostname present; hostname absent (MAC); OUI + MAC format; bare MAC when no OUI |
| Equatable | 2 | Same props equal; different signal not equal |

### 4. Mock Data Tests (25 tests)
**File:** `services/mock_diagnostic_data_test.dart`

Tests that mock data scenarios are internally consistent and correctly structured.

| Group | Tests | What It Validates |
|-------|-------|-------------------|
| healthy() scenario | 11 | Loaded state; WAN connected; uptime > 1 day; has clients; wired + wireless; low DHCP; no firmware update; band steering; guest network; low complexity; device info; all wireless have signal |
| degraded() scenario | 10 | Loaded state; WAN disconnected; recent reboot; high DHCP; firmware update; flagged clients; higher complexity; backhaul info; has clients; varying signal quality |
| Data consistency | 4 | Client count matches DHCP; valid band values; wired has no signal; all have MAC addresses |

## Test Coverage Summary

| Area | Test Count | Coverage |
|------|-----------|----------|
| JNAP response parsing | 33 | Real M60CF fixture data |
| State computed properties | 49 | All getters, copyWith, edge cases |
| Client model logic | 28 | Signal, flags, OUI, display names |
| Mock data integrity | 25 | Both scenarios, consistency checks |
| **Total** | **135** | |

## Adding New Tests

When adding a new JNAP call or data source:
1. Capture real response data from the router (use browser DevTools → Network tab)
2. Add the fixture as a `const` map in `jnap_parsing_test.dart`
3. Add test cases that validate the parsing logic matches your expectations
4. Run `fvm flutter test test/page/cs_diagnostic/` to verify

When adding new state properties:
1. Add tests to `cs_diagnostic_state_test.dart` for the getter/computed property
2. Test edge cases: null input, missing keys, boundary values
3. Test copyWith behavior if the property is mutable
