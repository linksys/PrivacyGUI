# waitingForRecovery Connection State Machine

**Issue:** #822  
**Date:** 2026-04-30  
**Status:** Draft

## Summary

When the router becomes unreachable (natural network loss or operational triggers like WiFi SSID change), the app currently has no unified recovery mechanism. Background activities continue sending invalid requests and users receive no guidance.

This design adds an application-layer connection state machine that:
1. Detects router unreachability
2. Stops all background activities
3. Probes for recovery
4. Auto-reconnects when the router returns

## Scope

**In scope:**
- `AppConnectionState` enum + Riverpod provider
- Natural trigger: SSE `suspended` + polling consecutive 3 network errors
- Operational trigger mechanism with configurable cooldown
- WiFi SSID save as first operational trigger integration point
- Recovery probe loop (health → login → serial verify)
- Router fingerprint storage (serial number in FlutterSecureStorage)
- Full-screen overlay UI (minimal style, using ui_kit_library)
- Background activity pause/resume via provider watch pattern

**Out of scope (future issues):**
- Reboot operational trigger integration (hook ready, not wired)
- Firmware upgrade operational trigger (hook ready, not wired)

## State Machine

```
              +---------------+
    +---------| authenticated |---------+
    |         +-------+-------+         |
    |                 |                 |
    |  Natural:       |  401 + reauth  |
    |  SSE suspended  |  all fail      |
    |  + polling 3x   |                 |
    |  network errors |                 |
    |                 |                 |
    |  Operational:   |                 |
    |  explicit call  |                 |
    v                 |                 v
+------------------+  |       +----------+
|waitingForRecovery|  +------>| loggedOut |
|                  |          +----------+
| health OK        |               ^
| + login OK       |  serial       |
| + serial match   |  mismatch     |
|       |          |---------------+
|       v          |
|  -> authenticated|
+------------------+
```

## Architecture

### Components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `AppConnectionState` | `lib/core/connection/models/app_connection_state.dart` | Enum: `authenticated`, `waitingForRecovery`, `loggedOut` |
| `AppConnectionStateNotifier` | `lib/core/connection/providers/app_connection_state_provider.dart` | State transitions, starts/stops probe loop, reconnects SSE on recovery |
| `RecoveryProbeService` | `lib/core/connection/services/recovery_probe_service.dart` | Probe loop: health → login → serial verify |
| `RouterFingerprintService` | `lib/core/connection/services/router_fingerprint_service.dart` | Serial number CRUD in FlutterSecureStorage |
| `RecoveryOverlay` | `lib/core/connection/views/recovery_overlay.dart` | Full-screen overlay widget |

### Entry Conditions

#### Natural Trigger

Two independent signals must both be true:

1. **SSE enters `suspended`** — `SseConnectionManager` exhausts max retries (default 5), transitions to `SseConnectionState.suspended`
2. **Any polling provider reports 3 consecutive network errors** — each polling notifier (TrafficAnalysis, SystemMonitor) maintains a local error counter; on 3 consecutive `ConnectivityError`s, it notifies `AppConnectionStateNotifier`

Both conditions must be met. Order doesn't matter — whichever happens second triggers the transition.

**Signal aggregation:** `AppConnectionStateNotifier` watches `sseConnectionStateProvider` for the SSE signal. Polling providers call a `reportConnectivityFailure()` method on the notifier when they hit 3 consecutive errors. The notifier internally tracks both flags and transitions only when both are true.

#### Operational Trigger

Caller explicitly invokes:
```dart
ref.read(appConnectionStateProvider.notifier).enterWaiting(
  cooldown: Duration(seconds: 3), // per-operation configurable
);
```

Integration point for this issue: WiFi SSID save (cooldown: 3s).

### Behavior on Entry

1. **SSE disconnect** — `AppConnectionStateNotifier` calls `sseManager.disconnect()` directly
2. **Polling auto-pause** — each polling provider watches `appConnectionStateProvider`; when state != `authenticated`, it cancels its timer
3. **Start recovery probe** — after cooldown expires, begin probe loop

### Recovery Probe Loop

Interval: 5 seconds (configurable). Runs until recovery or manual exit.

```
Every 5s (after cooldown):
  Step 1: GET /api/v1/health
    → fail → continue waiting (next probe in 5s)

  Step 2: UspAuthCoordinator.restoreSession()
    → fail → continue waiting (next probe in 5s)

  Step 3: GET Device.DeviceInfo.SerialNumber
    → match stored fingerprint → RECOVER
    → mismatch → FORCE LOGOUT (different router)
```

**Recovery (serial match):**
1. Transition state to `authenticated`
2. Reconnect SSE with new token (token was refreshed in Step 2)
3. Polling providers observe state change, restart timers automatically

**Force logout (serial mismatch):**
1. Transition state to `loggedOut`
2. Trigger existing `authProvider.logout()` flow

### Router Fingerprint

| When | Action |
|------|--------|
| Dashboard init (after `systemInfoProvider` resolves) | Store serial to FlutterSecureStorage |
| Recovery probe Step 3 | Read and compare |
| `logout()` | Clear stored serial |

Storage key: `router_fingerprint_serial`

### Background Activity Pause (Provider Watch Pattern)

Each polling provider adds a watch on `appConnectionStateProvider`:

```dart
// In each polling notifier's build():
final connectionState = ref.watch(appConnectionStateProvider);
if (connectionState != AppConnectionState.authenticated) {
  _cancelTimer();
  return;
}
// ... normal polling logic
```

No central registry. Each provider manages its own lifecycle.

### UI: Recovery Overlay

**Placement:** Wrapped around `MaterialApp`'s navigator (or as a top-level `Overlay` entry) so it blocks all route-level interaction.

**Content (minimal style):**
- Router/connectivity icon (from ui_kit_library)
- Title: "Waiting for router..."
- Subtitle: "The router is restarting. The app will reconnect automatically."
- Loading spinner (from ui_kit_library)
- "Return to login page" text button at bottom

**Behavior:**
- Watches `appConnectionStateProvider`
- Shows when state == `waitingForRecovery`
- Hides when state transitions to `authenticated` or `loggedOut`
- "Return to login page" calls `authProvider.logout()`

**Implementation constraint:** All UI components must come from `ui_kit_library` first. Only use custom widgets if ui_kit_library lacks the needed component.

### Operational Trigger: WiFi SSID Save Integration

In `UspWifiSettingsProvider.save()`, after the USP write succeeds:

```dart
await performSave(); // existing save logic
ref.read(appConnectionStateProvider.notifier).enterWaiting(
  cooldown: Duration(seconds: 3),
);
```

This immediately shows the overlay and starts the cooldown before probing.

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Health check timeout | Treat as fail, continue probing |
| Login returns 401 | Continue probing (router may still be initializing) |
| Login throws non-network error | Continue probing |
| Serial read fails (network) | Continue probing |
| Serial read fails (USP error) | Log warning, continue probing |
| User taps "Return to login" | Immediate logout, stop probe loop |
| App goes to background (web tab hidden) | Pause probe loop, resume on foreground |

## Max Wait Time

Unlimited. The probe loop runs indefinitely until:
- Recovery succeeds (serial match)
- Serial mismatch triggers logout
- User manually returns to login page

No timeout-based force logout. The user is always in control.

## Testing Strategy

**Unit tests:**
- `AppConnectionStateNotifier` state transitions (natural trigger, operational trigger, recovery, serial mismatch)
- `RecoveryProbeService` probe sequence (mock health/login/serial outcomes)
- `RouterFingerprintService` CRUD operations
- Polling providers pause/resume when connection state changes

**Integration tests:**
- Full flow: SSE suspended + polling errors → waiting → health OK → login OK → serial match → authenticated
- Full flow: operational trigger → cooldown → probe → recovery
- Serial mismatch → force logout

**Widget tests:**
- Overlay shows/hides based on connection state
- "Return to login" button triggers logout

## Dependencies

- #821 (proactive token refresh) — already implemented; provides `ensureAuth()`, `onForceLogout`, `restoreSession()` infrastructure
- `UspBridgeClient.health()` — already exists
- `SessionNotifier.checkRouterIsBack()` — existing serial verification logic
- `FlutterSecureStorage` — already used for password storage
