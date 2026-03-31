# Dashboard Orchestration & Loading Architecture

**Date:** 2026-03-27 | **Branch:** `feature/apps-page`
**Related:** [SSE Implementation](sse_implementation.md) | [Feature Roadmap](feature_roadmap.md)

---

## 1. Overview

The dashboard loading pipeline coordinates authentication, parallel data fetching, SSE subscription registration, and retry/recovery. The design accounts for the router's single-threaded OBUSPA backend — only 1 USP message is processed at a time, with lighttpd reverse-proxying all API endpoints to the same `127.0.0.1:8083` bridge process.

**Key constraint:** Concurrent requests exceeding the bridge's listen backlog cause `Connection refused` → lighttpd 503 → cascade failures. All mechanisms below are designed to prevent this.

---

## 2. Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│  UI Layer — Dashboard Cards                                  │
│  Each card watches its domain provider, shows skeleton       │
│  until AsyncValue.data arrives                               │
├─────────────────────────────────────────────────────────────┤
│  Layer 1 — Domain Data Providers (AsyncNotifierProvider)     │
│  systemInfo, devices, ethernet, wifi, wan, lan, dhcp,        │
│  firewall, portForwarding, portTriggering, time              │
├─────────────────────────────────────────────────────────────┤
│  Layer 1b — Polling/Analytics (NotifierProvider)             │
│  systemMonitor, trafficAnalysis, deviceAnalytics             │
│  (gated by dashboardDomainReadyProvider)                     │
├─────────────────────────────────────────────────────────────┤
│  Orchestrator — DashboardOrchestrator (AsyncNotifier)        │
│  Auth → trigger core providers → SSE deferred → retry        │
├─────────────────────────────────────────────────────────────┤
│  Infrastructure                                              │
│  BridgeRequestThrottler │ SSE Manager │ Auth Coordinator     │
└─────────────────────────────────────────────────────────────┘
```

### File Locations

| Component | Path |
|-----------|------|
| Orchestrator | `lib/page/dashboard/orchestrator/dashboard_orchestrator.dart` |
| Domain Ready | `lib/page/dashboard/providers/dashboard_domain_ready_provider.dart` |
| Throttler | `lib/core/usp/services/bridge_request_throttler.dart` |
| Throttler Provider | `lib/core/usp/providers/bridge_request_throttler_provider.dart` |
| SSE Providers | `lib/core/usp/providers/sse_providers.dart` |
| Dashboard Shell | `lib/page/shell/usp_dashboard_shell.dart` |

---

## 3. Loading Sequence

```
App Start
  │
  ├─ routerProvider redirect → authCheck()
  │    └─ authProvider.init() → restoreSession() → USP login
  │
  ├─ Navigate to /usp/dashboard
  │    └─ UspDashboardShell watches:
  │         ├─ sseBootstrapProvider  → SSE connect (NO subscriptions yet)
  │         └─ dashboardOrchestratorProvider → triggers build
  │
  └─ DashboardOrchestrator._buildImpl()
       │
       ├─ 1. Auth check + session restore (if needed)
       │
       ├─ 2. Fire-and-forget triggers (core providers)
       │    ├─ ref.read(systemInfoDataProvider)
       │    ├─ ref.read(devicesDataProvider)
       │    └─ ref.read(ethernetDataProvider)
       │    (Cards trigger remaining providers lazily on render:
       │     wan, lan, dhcp, firewall, portForwarding, portTriggering, time)
       │
       ├─ 3. Fire-and-forget: packageWidgetLoaderProvider
       │
       ├─ 4. unawaited(_registerSSEAfterDomainReady())
       │    ├─ await dashboardDomainReadyProvider (systemInfo+devices+ethernet)
       │    ├─ await throttler.whenIdle() (ALL queued requests drained)
       │    ├─ Ensure SSE connected
       │    ├─ setCoreSubscriptions(coreSubscriptions)
       │    └─ registerDeferredSubscriptions(force: true)
       │
       ├─ 5. unawaited: push initial SystemSnapshot to monitor
       │
       └─ 6. _scheduleProviderRetry() (exponential backoff)
            └─ 5s → 10s → 20s, checks ALL 11 domain providers
```

---

## 4. Bridge Request Throttler

**Purpose:** Limits concurrent outbound requests to prevent bridge overload.

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `maxConcurrent` | 2 | OBUSPA single-threaded; 2 provides pipelining without wasting connections |
| `staggerDelay` | 80ms | Brief pause between dispatches to avoid burst-hammering |
| `requestTimeout` | 15s | Free slot if action hangs; underlying HTTP may still complete |
| `defaultCacheTtl` | 5s | Dedup identical requests within short window |

### Dedup Order
1. **Cache** (completed, within TTL) → return cached Future
2. **In-flight** (dispatched, executing) → share pending Future
3. **Queue** (waiting) → share queued Future
4. **New** → enqueue with priority + FIFO ordering

### Priority Levels
- `RequestPriority.high` — dispatched first
- `RequestPriority.normal` — default
- `RequestPriority.low` — dispatched last

### `whenIdle()` API
Returns a `Future<void>` that resolves when `activeCount == 0 && queueLength == 0`. Used by the orchestrator to defer SSE subscription registration until ALL data requests (not just core 3) have completed.

---

## 5. SSE Deferred Registration

### Problem
SSE subscription POST requests (`POST /api/v1/subscription`) go through the same bridge as data GET requests (`GET /api/v1/usp`). If they fire concurrently during the initial data load burst, the bridge's listen backlog fills up → `Connection refused` → lighttpd 503 → cascade failures.

### Solution: Two-Phase Boot

**Phase 1 — `sseBootstrapProvider`:**
- SSE stream connects (`GET /api/v1/notifications`)
- NO subscriptions registered at this point
- SSE connection is ready to receive events once subscriptions are added

**Phase 2 — `_registerSSEAfterDomainReady()` (in orchestrator):**
1. `await dashboardDomainReadyProvider.future` — waits for core 3 providers (systemInfo, devices, ethernet)
2. `await throttler.whenIdle()` — waits for ALL remaining dashboard requests to drain (wan, lan, dhcp, firewall, etc.)
3. `manager.setCoreSubscriptions(coreSubscriptions)` — sets the subscription list
4. `manager.registerDeferredSubscriptions(force: true)` — POSTs subscriptions to bridge

This ensures zero overlap between data GETs and subscription POSTs.

---

## 6. Provider Retry Mechanism

### Coverage: All 11 Domain Providers
```dart
static final _allDomainProviders = [
  ('systemInfo', systemInfoDataProvider),
  ('devices', devicesDataProvider),
  ('ethernet', ethernetDataProvider),
  ('wifi', wifiDataProvider),
  ('wan', wanDataProvider),
  ('lan', lanDataProvider),
  ('dhcp', dhcpDataProvider),
  ('firewall', firewallDataProvider),
  ('portForwarding', portForwardingDataProvider),
  ('portTriggering', portTriggeringDataProvider),
  ('time', timeDataProvider),
];
```

### Strategy: Exponential Backoff
- **Schedule:** 5s → 10s → 20s (3 attempts max)
- **Behavior:** Timer fires → check each provider's `AsyncValue.hasError` → `ref.invalidate()` any that failed
- **Always schedules next:** Providers may still be loading at check time (throttler queue) and could fail after

### Why All 11?
Previously only 4 providers (systemInfo, devices, ethernet, wifi) were retried. The remaining 7 (wan, lan, dhcp, firewall, portForwarding, portTriggering, time) are triggered lazily by card rendering. If they fail during bridge startup burst, there was no recovery — cards showed permanent blank state.

### Polling/Analytics Providers (NOT retried)
- `uspSystemMonitorProvider`, `uspTrafficAnalysisProvider`, `uspDeviceAnalyticsProvider`
- These are `NotifierProvider` (not `AsyncNotifierProvider`), poll on internal timers
- Gated by `dashboardDomainReadyProvider` — they don't start until core data loads
- Gracefully show empty state if data is unavailable

---

## 7. Pull-to-Refresh

`refreshAll()` invalidates all 11 domain providers via `_allDomainProviders`, then `ref.invalidateSelf()` to re-run the orchestrator build. This re-triggers:
- All fire-and-forget provider reads
- SSE deferred registration sequence
- Provider retry schedule

---

## 8. Dashboard Domain Ready Provider

```dart
// lib/page/dashboard/providers/dashboard_domain_ready_provider.dart
final dashboardDomainReadyProvider = FutureProvider<void>((ref) async {
  await Future.wait<void>([
    ref.read(systemInfoDataProvider.future).then((_) {}).catchError((_) {}),
    ref.read(devicesDataProvider.future).then((_) {}).catchError((_) {}),
    ref.read(ethernetDataProvider.future).then((_) {}).catchError((_) {}),
  ]);
});
```

- Resolves when core 3 providers **settle** (success OR error)
- Individual `.catchError((_) {})` ensures one failure doesn't block others
- Gates: SSE registration, polling providers

---

## 9. Router Provider Ref Lifecycle

### Problem
`RouterNotifier` holds a `Ref` from `routerProvider`. When `authProvider.init()` changes auth state, `routerProvider`'s `ref.watch(authProvider)` dependency marks the ref as outdated. Any `_ref.read()` after this point throws:
```
"Cannot use ref functions after the dependency of a provider changed
 but before the provider rebuilt"
```

### Solution: Cache Before Async Gap
All `_ref.read()` calls are cached **before** the async `init()` call:
```dart
Future<String?> authCheck(GoRouterState state) {
  // Cache BEFORE init() — init changes authProvider → invalidates our ref
  final session = _ref.read(sessionProvider.notifier);
  final autoParentLogin = _ref.read(autoParentFirstLoginStateProvider);
  final autoParentLoginNotifier = _ref.read(autoParentFirstLoginStateProvider.notifier);
  final cachedDeviceInfo = _ref.read(sessionProvider).deviceInfo;

  return _ref.read(authProvider.notifier).init().then((authState) async {
    // _ref is outdated here — use cached values only
    return _prepare(state, session: session, ...cachedDeviceInfo: cachedDeviceInfo);
  });
}
```

**Rule:** Never call `_ref.read()` / `_ref.watch()` after any async operation that modifies a watched provider's state. Cache everything needed synchronously before the async gap.

---

## 10. Card → Provider Mapping

| Card | Provider(s) | Retried? |
|------|------------|----------|
| Device Info | systemInfoDataProvider | Yes |
| Network Status | wanDataProvider | Yes |
| Topology | devicesDataProvider, systemInfoDataProvider | Yes |
| LAN Info | lanDataProvider | Yes |
| Ethernet Ports | ethernetDataProvider | Yes |
| System Status | systemInfoDataProvider, uspSystemMonitorProvider | Partial (polling not retried) |
| Connected Devices | devicesDataProvider | Yes |
| WiFi Status | wifiDataProvider | Yes |
| Time Settings | timeDataProvider | Yes |
| DHCP Reservations | dhcpDataProvider | Yes |
| Port Forwarding | portForwardingDataProvider, portTriggeringDataProvider | Yes |
| Firewall Overview | firewallDataProvider, portForwardingDataProvider | Yes |
| WiFi Performance | wifiDataProvider, devicesDataProvider | Yes |
| Stats Panel | devicesDataProvider, ethernetDataProvider, wifiDataProvider, portForwardingDataProvider, portTriggeringDataProvider | Yes |
| Traffic Analysis | uspTrafficAnalysisProvider | No (polling) |
| Device Analytics | uspDeviceAnalyticsProvider | No (polling) |
| Network Health | uspTrafficAnalysisProvider | No (polling) |

---

## 11. Package Widget System (Modular Apps)

### Capability Gate
`appsCapabilityProvider` — one-shot `FutureProvider<bool>`, cached for the session:
- GET `/api/apps.json` → 200 = supported, 404/timeout = not supported
- Controls: Apps icon visibility (`usp_top_bar.dart`), `packageWidgetLoaderProvider` activation

### Package Widget Loader (`packageWidgetLoaderProvider`)
- **NOT autoDispose** — persists across tab switches
- **Gated by** `appsCapabilityProvider` — if router doesn't support apps, returns empty immediately, no polling
- **Initial load**: Fetch apps.json → extract widget entries → fetch each template URL
- **Poll (30s)**: Lightweight — only re-fetches apps.json for install/remove detection
  - **Added widgets**: Only fetches template URLs for NEW widgets
  - **Removed widgets**: Auto-removes from dashboard + cleans up data provider
  - **Fetch failure**: Skips removal processing (prevents false widget deletions)

### Apps List Polling (`uspAppsProvider`)
- **autoDispose** — stops when user leaves Apps page
- **5-second poll** for app install/remove, "NEW" badge (60s auto-clear)
- Implicitly gated by capability check (icon hidden → page unreachable → provider never watched)

### Package Widget Renderer Data Sources
| Type | Initial Load | Update Mechanism |
|------|-------------|-----------------|
| USP | `usp.get(paths)` | SSE ValueChange subscription |
| HTTP/CGI | POST/GET to `/cgi-bin/...` | Timer-based polling (`refreshInterval` seconds) |

### File Locations

| Component | Path |
|-----------|------|
| Capability Check | `lib/page/apps/providers/apps_capability_provider.dart` |
| Widget Loader | `lib/page/dashboard/providers/package_widget_loader.dart` |
| Widget Renderer | `lib/page/dashboard/widgets/package_widget_renderer.dart` |
| Widget Data | `lib/page/dashboard/providers/package_widget_data_provider.dart` |
| Apps Notifier | `lib/page/apps/providers/usp_apps_notifier.dart` |
| Apps Service | `lib/page/apps/services/usp_apps_service.dart` |
| Top Bar (icon) | `lib/page/shell/usp_top_bar.dart` |

---

## 12. Known Constraints

| Constraint | Impact | Mitigation |
|------------|--------|------------|
| OBUSPA single-threaded | Only 1 USP msg processed at a time | Throttler maxConcurrent=2 (pipelining) |
| Bridge listen backlog | Burst connections → Connection refused → 503 | Throttler + stagger delay + SSE deferral |
| lighttpd worker limit | All endpoints share same backend proxy | Reserve connections for SSE stream |
| Browser HTTP/1.1 limit | 6 connections per origin | maxConcurrent=2 leaves slots for SSE + auth |
| Page reload loses WASM state | Auth session lost | Auto session restore via stored password |
