# Feature Specification: Instant-Test USP 2.4.0 Port

**Feature Branch**: `feature/instant-test-usp`
**Created**: 2026-06-01
**Status**: In Progress (Phase 2 complete, Phase 3 pending)
**Based on PRD**: `~/Projects/Instant_Help/Plans/PRD.md` (v0.8)

## Overview

Instant-Test is a customer-facing automatic network health diagnostic and guided
repair tool. It performs a 19-point check suite (router reachability, WAN status,
DNS resolution, speed, WiFi signal quality, mesh backhaul health, firmware, etc.)
and presents findings in plain language with one-tap fixes.

This spec covers the rebase from dev-1.2.9 (JNAP) to dev-2.4.0 (USP/TR-181),
delivered in two phases with a third phase planned.

## Architecture

```
lib/page/instant_test/
├── models/
│   ├── verdict.dart           VerdictEngine — 19 checks → ranked findings
│   ├── device_score.dart      WiFi quality score from DeviceUIModel
│   └── customer_journey.dart  Session action tracking
├── providers/
│   ├── instant_test_state.dart  Typed USP state (no raw Maps)
│   ├── instant_test_provider.dart  Watches devicesDataProvider + wanDataProvider +
│   │                                 ethernetDataProvider + dashboardOrchestratorProvider
│   ├── local_storage_web.dart   Recurrence detection (localStorage)
│   └── local_storage_stub.dart  Non-web stub
├── services/
│   └── browser_diagnostic_service.dart  Client→Router + Client→Internet speed tests
└── views/
    ├── instant_test_page.dart   4-tab scaffold
    ├── overview_tab.dart        Verdict findings + Restart Router (Connection Recovery)
    ├── my_devices_tab.dart      DeviceUIModel list with scoring badges
    ├── my_network_tab.dart      WAN + mesh topology + Ethernet ports
    └── help_me_fix_it_tab.dart  5 guided flows (Flow 3: whitelist semantics)
```

**Route**: `/uspInstantTest` (`RouteNamed.uspInstantTest`)
**Menu**: `AppSectionItemData` card in `UspMenuView`

## Data Sources

| Data | Provider | Location |
|------|----------|----------|
| Client devices | `devicesDataProvider` | `lib/page/devices/providers/` |
| WAN status | `wanDataProvider` | `lib/page/internet_settings/providers/` |
| Ethernet ports | `ethernetDataProvider` | `lib/page/local_network/providers/` |
| Mesh nodes | `devicesDataProvider.nodeModels` | `lib/page/devices/providers/` |
| System info / uptime | `systemInfoDataProvider` | `lib/page/admin/providers/` |
| Firmware update | `firmwareBanksDataProvider` | `lib/page/firmware_update/providers/` |
| Router→internet speed | `speedTestProvider` | `lib/page/unified_diagnostics/providers/` |
| Instant Privacy state | `uspInstantPrivacyProvider` | `lib/page/instant_privacy/providers/` |

## Decisions

- D-R1: Reboot via `showRecoveryDialog(trigger: RecoveryTrigger.operationalReboot)` — inherits SSE pause + 5s probe + re-auth
- D-R2: Guest network toggle deferred to V1.1 (USP write path too heavy)
- D-R3: Flow 3 uses whitelist semantics (`disable()` / `addMac()`) — not blocklist
- D-R4: Spec lives at `specs/020-instant-test/` alongside `Plans/PRD.md`
- D-R5: iOS native deferred (USP native transport not implemented on dev-2.4.0)
- D-R6: 4 tabs — embed their data inside our tabs (not link-out)
- D-R7: Three-leg speed test in Phase 2: client→router (browserDiagnosticService) + client→internet (Cloudflare) + router→internet (speedTestProvider)
- D-R8: Two-phase delivery — Phase 1 = scaffold, Phase 2 = tests + recovery + speed + flow copy + spec

## User Scenarios

### Scenario 1: Customer runs Instant Test (all-clear)
Customer opens Menu → Instant Test. Page loads, auto-fetches USP data, runs browser tests over 20-30s. Verdict shows "All checks passed" with check count. Customer sees their devices and network topology.

### Scenario 2: WAN disconnected
Verdict shows critical "No internet connection detected" finding. Customer is guided to check modem cable.

### Scenario 3: Speed slow due to WiFi bottleneck (three-leg)
All three legs run. Router→internet shows 200 Mbps; client→internet shows 30 Mbps. Verdict surfaces "Your WiFi is slowing down your connection" finding with advice to move closer to router.

### Scenario 4: Restart needed
Customer taps "Restart Router." Router reboots. `showRecoveryDialog` shows spinner while probing. Page auto-re-runs test after recovery.

### Scenario 5: Instant Privacy blocking device (Flow 3)
Customer navigates to Help Me Fix It tab. Flow 3 section shows Instant Privacy is on. Customer taps "Allow All Devices" → calls `uspInstantPrivacyProvider.notifier.disable()`.
