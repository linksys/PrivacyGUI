# Implementation Plan: Instant-Test USP 2.4.0 Port

## Phase 1 — Scaffold (COMPLETE)

**Branch**: `feature/instant-test-usp`, base commit `f0db1915` (dev-2.4.0)

**Delivered:**
- `lib/page/instant_test/` — 12 files, zero analyzer errors
- `VerdictEngine` migrated to `DeviceUIModel` + `NodeUIModel` (no JNAP)
- `DeviceScore` migrated to `DeviceUIModel` (downlinkRate in bits/sec)
- `InstantTestState` fully typed — no raw `Map<String, dynamic>`
- Provider watches `devicesDataProvider`, `wanDataProvider`, `ethernetDataProvider`, `dashboardOrchestratorProvider`
- Route `RouteNamed.uspInstantTest` → `/uspInstantTest`
- Menu card in `UspMenuView`
- 4-tab scaffold renders without crash

## Phase 2 — Tests + Production Quality (COMPLETE)

**Delivered:**
- 88 passing tests across models/providers/views
- Connection Recovery wrap on reboot (D-R1): `restartRouter()` + `showRecoveryDialog`
- Three-leg speed test wired (D-R7): client→internet + router→internet + WiFi bottleneck check
- Flow 3 whitelist copy (D-R3): `help_me_fix_it_tab.dart` uses `disable()` not blocklist wording
- Spec docs: `specs/020-instant-test/` (spec.md, plan.md, tasks.md)

## Phase 3 — Planned (not started)

- Full tab implementation (My Devices with "Troubleshoot this device" affordance, My Network with topology widget embed)
- iOS native when USP native transport lands (D-R5)
- Guest network toggle V1.1 when USP write path matures (D-R2)
- Integration test on M60CF-EU hardware
- Localization strings in ARB files

## Architecture Notes

### Provider pre-population (deep-link risk)
`dashboardOrchestratorProvider` is watched (not just read) from `build()` so that deep-linking to `/uspInstantTest` without visiting the dashboard first still triggers the orchestrator's init sequence, which pre-populates `devicesDataProvider`/`wanDataProvider`/`ethernetDataProvider`.

### Three-leg speed test flow
1. Client→Router: `browserDiagnosticService.runRouterSpeedTest()` (Phase 3 — connects to main.dart.js)
2. Client→Internet: `browserDiagnosticService.runInternetSpeedTest()` (Cloudflare, runs in Phase 2)
3. Router→Internet: `speedTestProvider.runSpeedTest()` (USP Operate to Linode, wired in Phase 2)

VerdictEngine compares legs 2 vs 3: if router→internet > 2× client→internet at <50 Mbps, surfaces WiFi bottleneck finding.

### Connection Recovery pattern
```dart
await ref.read(instantTestProvider.notifier).restartRouter(); // service call
await showRecoveryDialog(context, ref,
  trigger: RecoveryTrigger.operationalReboot,
  cooldown: const Duration(seconds: 60));
```
`restartRouter()` stores restart timestamp to localStorage for recurrence detection. After recovery, `fetch(forceSpeedTest: true)` re-runs the full diagnostic.
