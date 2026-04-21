# Plan: Proactive Token Refresh + Unified Connection State Management

## Context

The USP WASM client's JWT token TTL is **15 minutes** (confirmed by decoding the actual router JWT: `exp - iat = 900s`). Currently, token refresh is only triggered reactively upon receiving a 401 (`_withAuthRetry` -> `reauth()`). The `UspAuthCoordinator.ensureAuth()` method exists but is **never called**.

Users report "Linksys Now does not re-refresh the token" — operations fail after prolonged idle.

Additionally, when the router is unreachable (reboot, network switch), the app lacks a unified "waiting for recovery" state, causing background activities to send invalid requests with no UI guidance.

## Router Configuration (confirmed 2026-04-20)

```
JWT payload: { iat: T, exp: T+900 }  -> TTL = 15 minutes
usp-bridge.main.session_grace_period = 30s
usp-bridge.main.heartbeat_interval = 30s
Bridge health endpoint: GET /api/v1/health (no auth required)
Router identity: Device.DeviceInfo.SerialNumber (auth required)
```

---

## Part 1: Application-Layer Connection State Machine

### State Definition

```dart
enum AppConnectionState {
  /// Normal operation — all background activities running
  authenticated,

  /// Router unreachable — all background activities stopped, recovery probing in progress
  /// UI: full-screen prompt "Please reconnect to your router network" (future implementation)
  waitingForRecovery,

  /// Auth unrecoverable — navigate to login page
  loggedOut,
}
```

### State Transitions

```
                    +---------------+
          +---------| authenticated |---------+
          |         +-------+-------+         |
          |                 |                 |
          |  Consecutive    |  401 + reauth   |
          |  network        |  failure        |
          |  failures       |                 |
          |  exceed         |                 |
          |  threshold      |                 |
          |  or known op    |                 |
          |  (reboot etc)   |                 |
          v                 |                 v
+------------------+        |        +----------+
|waitingForRecovery|        +------->| loggedOut |
|                  |                 |          |
| Stop all bg      |                 +----------+
| Start recovery   |                      ^
| probe            |                      |
|                  |  serial mismatch     |
| health OK        |---------------------+
| + login OK       |
| + serial match   |
|       |          |
|       v          |
|  -> authenticated|
+------------------+
```

### Conditions to Enter `waitingForRecovery`

| Trigger Type | Condition | Delay |
|-------------|-----------|-------|
| **Natural** | SSE `suspended` + polling consecutive N network errors | Immediate (SSE suspended already went through backoff) |
| **Operational** | User initiates reboot / firmware upgrade | Configurable (e.g., ~5s after reboot) |

### Behavior on Entry

1. **Stop all background activities:**
   - Polling timers (Traffic Analysis 5s, System Monitor 30s, Apps 5s, etc.)
   - SSE reconnect (`SseConnectionManager` stops backoff retry)
   - Heartbeat `ensureAuth()` (SSE disconnected, naturally not triggered)
   - Throttler queue cleared (cancel queued requests)

2. **Start recovery probe loop** (see below)

### Recovery Probe Flow

```
Every N seconds (configurable, default 5s):

  Step 1: Is the bridge reachable?
    GET /api/v1/health (no auth, lightweight)
    -> Fail -> Continue waiting, retry next interval

  Step 2: Can we log in?
    restoreSession() (login with locally stored password)
    * After reboot, session is cleared — refreshToken will fail, so login directly
    -> Fail -> Continue waiting (possibly a different router with different password, or router not fully booted)

  Step 3: Is it the same router?
    GET Device.DeviceInfo.SerialNumber
    Compare with serial number stored in local storage
    -> Match    -> Restore: reconnect SSE, restart polling -> authenticated
    -> Mismatch -> Different router -> force logout -> loggedOut
```

### Router Fingerprint Storage

- **When to store:** During Dashboard initialization (after `systemInfoProvider` fetch succeeds)
- **Where to store:** `FlutterSecureStorage` (same secure storage as password)
- **What to store:** `Device.DeviceInfo.SerialNumber`
- **When to clear:** On `logout()`

### Maximum Wait Time

**Unlimited — stay on the waiting screen and let the user decide when to give up.**

The user can manually return to the login page via a UI button (to be added in future UI implementation).

---

## Part 2: Unified Fault Handling Rules

### Fault Classification & Behavior

| Fault Type | Meaning | Behavior |
|-----------|---------|----------|
| **401** -> reauth success | Token expired but recoverable | Resume normally, no logout |
| **401** -> reauth failure | Session unrecoverable | **Force logout** |
| **Network error** | Cannot reach server | SSE banner -> accumulate -> **waitingForRecovery** |
| **Server error** (503/504) | Bridge busy | Retry, no logout, no waiting |
| **WASM/JS exception** | Client internal error | Error state, no logout |

### Behavior Matrix by Trigger Source

| Trigger Source | Error Type | Behavior |
|---------------|------------|----------|
| Heartbeat refresh | Success | Update timestamp |
| Heartbeat refresh | 401 | **Force logout** |
| Heartbeat refresh | Network error | Skip, retry next heartbeat |
| Polling / user action | 401 -> reauth success | Resume normally |
| Polling / user action | 401 -> reauth failure | **Force logout** |
| Polling / user action | Network error | Provider error state -> accumulate -> **waitingForRecovery** |
| SSE reconnect | 401 -> reauth failure | **Force logout** |
| SSE reconnect | Network error | Banner + backoff -> suspended -> **waitingForRecovery** |
| Connected to different router | 401 -> reauth failure | **Force logout** |
| Recovery probe serial mismatch | — | **Force logout** |
| User-triggered reboot | — | **waitingForRecovery** (configurable delay) |

### Banner vs waitingForRecovery vs Force Logout

```
Network error occurs
  -> SSE: connecting -> reconnecting -> suspended (backoff exhausted)
  -> Polling: consecutive failures accumulate
  -> Brief disconnect: Banner shows -> reconnect succeeds -> Banner disappears (no waiting)
  -> Sustained disconnect: SSE suspended -> enter waitingForRecovery -> full-screen prompt

401 occurs
  -> reauth success: Resume normally (no UI impact)
  -> reauth failure: Force logout -> login page (skip waiting, logout immediately)
```

---

## Part 3: Proactive Token Refresh Implementation (5 files)

### 1. `lib/core/usp/services/usp_client.dart`

**Added:**
- `bool get isReauthInProgress => _reauthInProgress != null;`
- `VoidCallback? onForceLogout;`
- `VoidCallback? onRefreshTokenSuccess;`

**Modified `reauth()` catch block (~line 160):**

```dart
} catch (e) {
  if (!_reauthInProgress!.isCompleted) {
    _reauthInProgress!.completeError(e);
  }
  logger.w('[USP][Service]All reauth stages failed — forcing logout');
  onForceLogout?.call();
  rethrow;
}
```

**Modified `reauth()` after Stage 1 success (~line 146):**

```dart
await refreshToken();
logger.d('[USP][Service]Token refreshed successfully');
onRefreshTokenSuccess?.call();
_reauthInProgress!.complete();
return;
```

### 2. `lib/core/usp/providers/usp_auth_coordinator.dart`

**Added fields:**
```dart
DateTime? _lastTokenRefresh;
Completer<void>? _refreshInProgress;
VoidCallback? onForceLogout;
static const Duration _refreshThreshold = Duration(minutes: 12);
```

**Modified constructor:**
```dart
UspAuthCoordinator(this._usp, this._storage) {
  _usp?.onReauthRequired = () => _forceRestoreSession();
  _usp?.onRefreshTokenSuccess = () {
    _lastTokenRefresh = DateTime.now();
  };
}
```

**Update `_lastTokenRefresh = DateTime.now()` at all login success points:**
- `syncAfterLocalLogin()` — after `_usp.login()` succeeds
- `_loginWithStoredPassword()` — after `_usp.login()` succeeds
- `tryUspLogin()` — after `authenticated == true`

**Reset in `syncAfterLogout()`:** `_lastTokenRefresh = null;`

**Added `_forceRestoreSession()`** — bypasses `isAuthenticated` guard (WASM may still report authenticated after 401 since it checks token existence, not validity).

**Rewritten `ensureAuth()` — distinguishes 401 from network error:**
```dart
static bool _isAuthError(Object error) {
  return error.toString().contains('HTTP 401');
}

Future<void> ensureAuth() async {
  if (_usp == null || !_usp.isAuthenticated) return;
  if (_usp.isReauthInProgress) return;
  if (_refreshInProgress != null) return;

  final last = _lastTokenRefresh;
  if (last != null && DateTime.now().difference(last) < _refreshThreshold) {
    return;
  }

  _refreshInProgress = Completer<void>();
  try {
    await _usp.refreshToken();
    _lastTokenRefresh = DateTime.now();
    logger.d('[USP][Auth]Proactive token refresh succeeded');
  } catch (e) {
    if (_isAuthError(e)) {
      logger.w('[USP][Auth]Proactive refresh got 401 — forcing logout: $e');
      onForceLogout?.call();
    } else {
      logger.w('[USP][Auth]Proactive refresh failed (non-auth, will retry): $e');
    }
  } finally {
    _refreshInProgress = null;
  }
}
```

### 3. `lib/core/usp/services/sse_event_router.dart`

**Added:** `VoidCallback? onHeartbeat;`

**Modified `routeEvent()`:**
```dart
case 'heartbeat':
  onHeartbeat?.call();
  break;
case 'connected':
  break;
```

**`dispose()` includes:** `onHeartbeat = null;`

### 4. `lib/core/usp/services/sse_manager.dart`

**Added:** `Future<void> Function()? onHeartbeatAuth;`

**Constructor wiring:**
```dart
router.onHeartbeat = () {
  final authCheck = onHeartbeatAuth;
  if (authCheck != null) {
    authCheck().catchError((e) {
      logger.w('[USP][SSE]Heartbeat auth check error: $e');
    });
  }
};
```

**`dispose()` includes:** `router.onHeartbeat = null; onHeartbeatAuth = null;`

### 5. `lib/core/usp/providers/sse_providers.dart`

**Modified `sseManagerProvider`:**

```dart
final sseManagerProvider = Provider<SseManager?>((ref) {
  final usp = ref.watch(uspClientProvider);
  final bridge = ref.watch(uspBridgeClientProvider);
  if (usp == null || bridge == null) return null;

  final manager = SseManager(usp: usp, bridge: bridge);

  final authCoordinator = ref.read(uspAuthCoordinatorProvider);
  manager.onHeartbeatAuth = () => authCoordinator.ensureAuth();

  bool logoutTriggered = false;
  void forceLogout() {
    if (logoutTriggered) return;
    logoutTriggered = true;
    logger.w('[USP]Force logout triggered');
    ref.read(authProvider.notifier).logout();
  }
  authCoordinator.onForceLogout = forceLogout;
  usp.onForceLogout = forceLogout;

  ref.onDispose(() {
    authCoordinator.onForceLogout = null;
    usp.onForceLogout = null;
    manager.dispose();
  });

  return manager;
});
```

**Added imports:**
```dart
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
```

---

## Part 4: Callback Chains

### Proactive Path (Heartbeat)

```
Bridge SSE stream (heartbeat every 30s)
  -> SseConnectionManager._onEvent()
    -> onEvent (= router.routeEvent)
      -> SseEventRouter case 'heartbeat' -> onHeartbeat()
        -> SseManager: onHeartbeatAuth()
          -> UspAuthCoordinator.ensureAuth()
            -> elapsed < 12 min? return
            -> elapsed >= 12 min? refreshToken()
              -> Success: update _lastTokenRefresh
              -> Fail 401: onForceLogout -> loggedOut
              -> Fail network: skip, retry next heartbeat
```

### Reactive Path (401 Reauth)

```
CRUD / Polling -> HTTP 401
  -> _withAuthRetry -> reauth()
    -> Stage 1: refreshToken()
      -> Success: onRefreshTokenSuccess -> update _lastTokenRefresh
    -> Stage 2: onReauthRequired -> _forceRestoreSession()
      -> Success: _lastTokenRefresh updated
    -> Both fail: onForceLogout() -> loggedOut
```

### Recovery Path (waitingForRecovery)

```
Enter waitingForRecovery state
  -> Stop all polling / SSE reconnect
  -> Start recovery probe (configurable interval, default 5s)
    -> health OK -> restoreSession OK -> GET serial
      -> match: restore -> authenticated
      -> mismatch: force logout -> loggedOut
    -> health fail: continue waiting
```

---

## Part 5: Race Condition Guards

| Scenario | Guard |
|----------|-------|
| Heartbeat and 401 reauth simultaneous | `ensureAuth()` checks `_usp.isReauthInProgress` -> skip |
| Consecutive heartbeats stacking | `_refreshInProgress` Completer guard -> skip |
| 401 triggers onForceLogout during logout | `logoutTriggered` bool guard -> skip |
| Both paths call refreshToken simultaneously | Acceptable — refreshToken is idempotent |
| User action during waitingForRecovery | UI blocks (full-screen modal), background stopped |

---

## Part 6: `_lastTokenRefresh` Update Points

| Event | Update Location |
|-------|----------------|
| Initial login (tryUspLogin) | `UspAuthCoordinator.tryUspLogin()` |
| Sync login (syncAfterLocalLogin) | `UspAuthCoordinator.syncAfterLocalLogin()` |
| Session restore (restoreSession) | `UspAuthCoordinator._loginWithStoredPassword()` |
| Proactive refresh (heartbeat) | `UspAuthCoordinator.ensureAuth()` |
| Reactive refresh (401 Stage 1) | `UspClient.reauth()` -> `onRefreshTokenSuccess` callback |
| Logout | `UspAuthCoordinator.syncAfterLogout()` -> reset to `null` |

---

## Part 7: Implementation Phases

### Phase 1 (this implementation): Proactive Token Refresh + Force Logout

- Modify 5 files (Part 3)
- Fault rules: unrecoverable 401 = force logout, network error = no logout
- Router fingerprint storage (store serial number to secure storage on login)

### Phase 2 (future): waitingForRecovery State

- Add `AppConnectionState` state machine + provider
- Recovery probe loop (health -> login -> serial comparison)
- Operational triggers (reboot and other known operations enter waiting directly)
- Mechanism to stop all background activities
- UI: full-screen modal "Please reconnect to your router network"

---

## Part 8: Verification

### Phase 1 Verification

1. `flutter analyze lib/core/usp/` — zero errors
2. Manual testing:
   - Wait >12 minutes after login -> log shows `Proactive token refresh succeeded`
   - Continuous operation -> no extra refresh triggered within 12 minutes
   - SSH kill session -> next poll or heartbeat triggers 401 -> auto logout
   - Unplug network cable -> SSE banner shows, force logout NOT triggered
   - Network restored + token not expired -> SSE reconnects -> banner disappears
   - Network restored + token expired -> SSE reconnect 401 -> reauth success/failure
3. Edge case: Connect to different router (same IP) -> 401 -> reauth failure -> force logout

### Phase 2 Verification (future)

1. User-triggered reboot -> enter waiting state -> router finishes restarting -> auto recovery
2. Switch WiFi to different network -> enter waiting -> switch back to correct WiFi -> serial match -> recovery
3. Switch back to different router (same IP + same password) -> serial mismatch -> force logout
4. User manually returns to login page while in waiting state
