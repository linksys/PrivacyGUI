# SSE (Server-Sent Events) Implementation Guide

**Date:** 2026-03-13 | **Branch:** `feat/usp-protocol-integration`
**Firmware:** 1.0.16.26013014 | **usp-bridge:** v0.1.1

---

## 1. Architecture Overview

SSE provides real-time push notifications from the router to the Flutter web app. The pipeline involves three independent systems:

```
Flutter App (WASM)
    │
    ├── UspService ──→ OBUSPA (via usp-bridge proxy)
    │     │                │
    │     │    USP Add/Delete Device.LocalAgent.Subscription.{i}
    │     │                │
    │     │                ▼
    │     │         OBUSPA monitors TR-181 data model
    │     │                │
    │     │         Change detected → USP Notify (protobuf)
    │     │                │
    │     │                ▼
    │     │         UDS socket → usp-bridge
    │     │
    ├── UspBridgeClient ──→ usp-bridge HTTP API
    │     │                      │
    │     │    POST /api/v1/subscription (register SSE session)
    │     │                      │
    │     │    GET /api/v1/notifications (SSE stream)
    │     │                      │
    │     │                      ▼
    │     │              Bridge routes Notify → SSE event
    │     │
    └── SseManager (facade)
          ├── SseConnectionManager   — SSE stream lifecycle
          ├── SseSubscriptionRegistry — OBUSPA + bridge subscription tracking
          └── SseEventRouter          — event demux by subscription_id + wildcard
```

### Two-Layer Subscription Architecture

Two independent subscription systems exist:

| Layer | Purpose | Persistence | Creation |
|-------|---------|-------------|----------|
| **OBUSPA** | Tells router to generate USP Notify messages | Survives SSE disconnect, browser refresh | `UspService.createNotifySubscription()` (5-step workaround) |
| **Bridge** | Routes notifications to the correct SSE session | Destroyed on SSE disconnect | `UspBridgeClient.subscribe()` HTTP POST |

Key insight: OBUSPA subscriptions persist on the router even after the browser disconnects. Bridge subscriptions are ephemeral — they only exist while the SSE connection is active.

On SSE reconnect, only bridge subscriptions need re-registration (`SseSubscriptionRegistry.resubscribeAll()`).

---

## 2. Service Layer Files

### Core Services (`lib/usp/services/`)

| File | Class | Responsibility |
|------|-------|----------------|
| `sse_connection_manager.dart` | `SseConnectionManager` | SSE stream lifecycle, exponential backoff (1s → 60s), heartbeat watchdog (45s = 30s heartbeat + 15s grace) |
| `sse_subscription_registry.dart` | `SseSubscriptionRegistry` | Two-layer subscription tracking, `register()` / `unregister()` / `resubscribeAll()` |
| `sse_event_router.dart` | `SseEventRouter` | JSON parse → route by `subscription_id`, wildcard handlers for cross-cutting concerns |
| `sse_manager.dart` | `SseManager` | Facade composing the above three. Primary API for Riverpod providers |
| `sse_operation_awaiter.dart` | `SseOperationAwaiter` | Async Operate commands (Ping/Traceroute) via OperationComplete, polling fallback |

### Providers (`lib/usp/providers/`)

| File | Provider | Purpose |
|------|----------|---------|
| `sse_providers.dart` | `sseManagerProvider` | Singleton `SseManager` for authenticated session |
| | `sseConnectionStateProvider` | Reactive `SseConnectionState` stream for UI badges |
| | `sseOperationAwaiterProvider` | `SseOperationAwaiter` for Operate commands |
| | `sseBootstrapProvider` | App startup: purge → connect → register core subscriptions |
| `sse_invalidation_provider.dart` | `sseInvalidationProvider` | Maps notifications to `InvalidationDomain` for selective re-fetch |

### Generated (`lib/generated/`)

| File | Content | Source |
|------|---------|--------|
| `subscriptions.g.dart` | `coreSubscriptions` — Record tuple list of all bootstrap subscriptions | Auto-generated from YAML `subscribe:` blocks by `usp-codegen` v0.10.5+ |

---

## 3. Two SSE Data Delivery Patterns

### Pattern A: Invalidation Signal (ValueChange / ObjectCreation / ObjectDeletion)

Used for data model changes where the UI needs to re-fetch fresh data.

```
SSE notification arrives
    │
    ▼
SseEventRouter.routeEvent()
    │
    ▼
Wildcard handler in sseInvalidationProvider
    │
    ▼
_mapToDomain() — path-based matching
    │
    ▼
StreamController<InvalidationDomain>.add(domain)
    │
    ▼
Dashboard/page providers: ref.listen(sseInvalidationProvider)
    │
    ▼
ref.invalidateSelf() → re-fetch from router
```

**Invalidation Domains:**

| Domain | TR-181 Path | Notification Types |
|--------|-------------|-------------------|
| `connectedDevices` | `Device.Hosts.Host.` | ObjectCreation, ObjectDeletion, ValueChange |
| `wifiSsids` | `Device.WiFi.SSID.` | ValueChange |
| `wifiRadios` | `Device.WiFi.Radio.` | ValueChange |
| `wifiClients` | `Device.WiFi.AccessPoint.*.AssociatedDevice.` | ObjectCreation |
| `wifiAccessPoints` | `Device.WiFi.AccessPoint.` | ValueChange |
| `portForwarding` | `Device.NAT.PortMapping.` | ValueChange, ObjectCreation, ObjectDeletion |
| `dmz` | `Device.Firewall.DMZ.` | ValueChange, ObjectCreation, ObjectDeletion |
| `firewallRules` | `Device.Firewall.Chain.` | ValueChange |
| `dhcpReservations` | `Device.DHCPv4.Server.Pool.*.StaticAddress.` | ValueChange, ObjectCreation, ObjectDeletion |
| `dhcpClients` | `Device.DHCPv4.Server.Pool.*.Client.` | ObjectCreation |
| `staticRouting` | `Device.Routing.Router.*.IPv4Forwarding.` | ValueChange, ObjectCreation, ObjectDeletion |

### Pattern B: Direct Data Delivery (OperationComplete)

Used for async Operate commands where the SSE notification IS the result.

```
SseOperationAwaiter.execute()
    │
    ├── Create OBUSPA subscription (OperationComplete)
    ├── Add wildcard handler (match by command_name)
    ├── Fire operate command
    │
    ▼
SSE OperationComplete arrives
    │
    ▼
Wildcard handler matches command_name (e.g., "IPPing()")
    │
    ▼
Completer.complete(OperateResult)
    │
    ▼
Cleanup: remove handler + unregister subscription
```

This pattern exists because **BUG-006**: Operate results are NOT written back to the TR-181 data model. `GET Device.IP.Diagnostics.IPPing.` returns empty after Operate completes. The SSE OperationComplete notification is the only source of result data.

---

## 4. Critical Design Decisions

### 4.1 CPE Subscription ID Mismatch

**Problem:** When we register a subscription with `subscriptionId: "connected-devices-objectcreation"`, the CPE delivers the event with its own internal ID (`cpe-3`, `cpe-15`, etc.). Subscription-specific handlers registered under our client ID never fire.

**Solution:** Use wildcard handlers for all cross-cutting matching:

- **Invalidation signals**: Wildcard handler in `sseInvalidationProvider` matches by `param_path` / `obj_path` from the notification payload
- **OperationComplete**: Wildcard handler in `SseOperationAwaiter` matches by `command_name`

The per-subscription handlers in `SseEventRouter._handlers` are technically unused for routing — but the OBUSPA subscription itself must still be created to tell the router to generate notifications.

### 4.2 WiFi Stats Noise Elimination

**Problem:** `Device.WiFi.SSID.*.Stats.*` (BytesSent, PacketsReceived, etc.) and `Device.WiFi.Radio.*.Stats.*` (LastChange, etc.) fire ValueChange notifications every second, flooding the SSE stream with 50+ events/s.

**Root fix:** WiFi ValueChange subscriptions removed from bootstrap entirely. `Device.Hosts.Host.` registers ObjectCreation, ObjectDeletion, and ValueChange (safe — no `.Stats.*` counters). Other subscriptions target specific subtrees (DHCP Clients, WiFi AccessPoint).

**Defense-in-depth:** `_mapToDomain()` in `sse_invalidation_provider.dart` filters out any path containing `.Stats.` as a safety net.

### 4.3 Bootstrap Purge Mechanism

**Problem:** Browser refresh doesn't trigger `dispose()` on Riverpod providers. OBUSPA subscriptions from the previous session accumulate on the router, causing duplicate notifications.

**Solution:** `sseBootstrapProvider` executes `purgeAllSubscriptions()` as Step 1 before connecting SSE:

```
Step 1: GET Device.LocalAgent.Subscription.    → enumerate all instances
Step 2: Extract instance IDs via regex (Device.LocalAgent.Subscription.\d+\.)
Step 3: DELETE each instance
Step 4: Connect SSE
Step 5: Register core subscriptions
```

The purge uses GET-based enumeration (not WASM `listSubscriptions`, which returns bridge-level subscriptions, not OBUSPA).

### 4.4 Polling Fallback

When SSE is disconnected, `SseOperationAwaiter` falls back to polling:

```
1. Fire operate command
2. Poll GET <path>. every 1s
3. Check DiagnosticsState == 'Complete' or 'Error'
4. Parse response into OperateResult
```

This fallback relies on GET returning results — which only works for some diagnostics where the firmware writes results back. For commands affected by BUG-006, polling returns empty.

---

## 5. SSE Event Format

### Heartbeat

```
event: heartbeat
data: {"timestamp":1773027837}
```

Sent every 30s by the bridge. Watchdog timeout: 45s.

### Notification — ValueChange

```json
{
  "subscription_id": "cpe-15",
  "type": "ValueChange",
  "value_change": {
    "param_path": "Device.Hosts.Host.3.Active",
    "param_value": "true"
  }
}
```

### Notification — ObjectCreation

```json
{
  "subscription_id": "cpe-3",
  "type": "ObjectCreation",
  "obj_creation": {
    "obj_path": "Device.Hosts.Host.5.",
    "unique_keys": {}
  }
}
```

### Notification — ObjectDeletion

```json
{
  "subscription_id": "cpe-3",
  "type": "ObjectDeletion",
  "obj_deletion": {
    "obj_path": "Device.Hosts.Host.5."
  }
}
```

### Notification — OperationComplete

```json
{
  "subscription_id": "cpe-3",
  "type": "OperationComplete",
  "oper_complete": {
    "obj_path": "Device.IP.Diagnostics.",
    "command_name": "TraceRoute()",
    "command_key": "f7a93db5-1321-49ec-b2ca-413781a9a2b7",
    "output_args": {
      "Status": "Complete",
      "RouteHops.1.Host": "10.92.12.1",
      "RouteHops.1.HostAddress": "10.92.12.1",
      "RouteHops.1.RTTimes": "1",
      "RouteHops.7.Host": "dns.google",
      "RouteHops.7.HostAddress": "8.8.8.8",
      "RouteHops.7.RTTimes": "5,6,5"
    }
  }
}
```

---

## 6. OBUSPA Subscription Creation (5-Step Workaround)

`UspService.createNotifySubscription()` performs the full OBUSPA subscription lifecycle:

```dart
// Step 1: GET Device.LocalAgent.Subscription. — snapshot existing IDs
final before = await get(['Device.LocalAgent.Subscription.']);
final idsBefore = _extractInstanceIds(before);

// Step 2: USP Add Device.LocalAgent.Subscription. — create instance
await add('Device.LocalAgent.Subscription.', {});

// Step 3: GET again — diff to find new instance ID
final after = await get(['Device.LocalAgent.Subscription.']);
final idsAfter = _extractInstanceIds(after);
final newId = idsAfter.difference(idsBefore).first;

// Step 4: USP SetMultiple — configure the subscription
await setMultiple({
  'Device.LocalAgent.Subscription.$newId.Enable': 'true',
  'Device.LocalAgent.Subscription.$newId.NotifType': notifType,
  'Device.LocalAgent.Subscription.$newId.ReferenceList': referenceList,
});

// Step 5: Verify Recipient points to UDS controller
final recipient = await get([
  'Device.LocalAgent.Subscription.$newId.Recipient'
]);
```

**Why 5 steps?** WASM `add('Device.LocalAgent.Subscription.')` returns empty (Rust bug — `wasm/mod.rs:435-441` doesn't parse `AddResp.updated_inst_results`). The GET-diff workaround finds the new instance ID.

---

## 7. Bootstrap Flow

`sseBootstrapProvider` executes on app startup (watched from the app shell):

```
1. Check: uspServiceProvider != null && isAuthenticated
2. Purge stale OBUSPA subscriptions (purgeAllSubscriptions)
3. Connect SSE (manager.connect)
4. Register core subscriptions (from subscriptions.g.dart, auto-generated by usp-codegen):
   - connected-devices-objectcreation (ObjectCreation, Device.Hosts.Host.)
   - connected-devices-objectdeletion (ObjectDeletion, Device.Hosts.Host.)
   - connected-devices-valuechange (ValueChange, Device.Hosts.Host.)
   - dhcp-clients-01 (ObjectCreation, Device.DHCPv4.Server.Pool.1.Client.)
   - wifi-clients-01 (ObjectCreation, Device.WiFi.AccessPoint.)
5. Log completion
```

Core subscriptions are auto-generated from YAML `subscribe:` blocks by `usp-codegen`. WiFi SSID/Radio ValueChange is intentionally excluded to avoid `.Stats.*` noise flooding.

---

## 8. Reconnection Behavior

| Event | Connection Manager | Registry | Router |
|-------|-------------------|----------|--------|
| SSE stream error | Auto-reconnect (exp backoff) | `resubscribeAll()` on reconnect | OBUSPA subscriptions survive |
| Heartbeat timeout (45s) | Close stream → reconnect | Same as above | Same as above |
| Browser refresh | New session starts | Bootstrap purges old OBUSPA subs, creates new | Old subscriptions purged |
| Intentional disconnect | No reconnect | Subscriptions retained in memory | OBUSPA subscriptions survive |
| Logout / dispose | Stop and clean | `unregisterAll()` deletes OBUSPA + bridge | Subscriptions deleted |

---

## 9. Known Issues & Workarounds

| Issue | Impact | Workaround | Status |
|-------|--------|------------|--------|
| **CPE subscription_id mismatch** | Per-subscription handlers never fire | Wildcard handlers + path/command_name matching | Permanent workaround |
| **WASM `add` returns empty for LocalAgent** | Can't get new subscription instance path | GET-diff in `createNotifySubscription()` | Permanent workaround (Rust bug) |
| **Bridge subscribe doesn't create OBUSPA** | Client must manage OBUSPA subscriptions | 5-step workaround in `UspService` | Enhancement request filed (`subscription-notify-blocked.md`) |
| **WiFi Stats noise** | 50+ events/s from `.Stats.*` counters | Removed WiFi ValueChange from bootstrap + `.Stats.` filter | Fixed |
| **Stale subscriptions on refresh** | Duplicate notifications | Bootstrap purge via `purgeAllSubscriptions()` | Fixed |
| **BUG-006: Operate results not in data model** | Polling fallback returns empty | SSE OperationComplete is primary delivery (Direct Data Delivery pattern) | By design |

---

## 10. Adding New SSE Subscriptions

### For Invalidation Signals (re-fetch on change)

1. Add `subscribe:` block to the YAML definition (`definitions/`):
   ```yaml
   # Single subscription:
   subscribe:
     enabled: true
     notifType: ValueChange
     id: my-feature-valuechange

   # Multiple subscriptions (array format, codegen v0.10.5+):
   subscribe:
     - notifType: ObjectCreation
       id: my-feature-objectcreation
     - notifType: ValueChange
       id: my-feature-valuechange
   ```

2. Run codegen — `subscriptions.g.dart` is auto-generated with the new entries:
   ```bash
   ./tools/usp-codegen --definitions-dir definitions/ \
     --output-dir lib/generated/ --language dart \
     --client-import 'package:privacy_gui/usp/services/usp_service.dart'
   ```

3. Add domain to `InvalidationDomain` enum in `invalidation_domain.dart`

4. Add path mapping in `_mapToDomain()` (`sse_invalidation_provider.dart`):
   ```dart
   if (path.startsWith('Device.My.Path.')) {
     return InvalidationDomain.myFeature;
   }
   ```

5. Listen in your provider:
   ```dart
   ref.listen(sseInvalidationProvider, (prev, next) {
     next.whenData((domain) {
       if (domain == InvalidationDomain.myFeature) {
         ref.invalidateSelf();
       }
     });
   });
   ```

**Warning:** Avoid subscribing to subtrees with high-frequency `.Stats.*` counters (WiFi SSID/Radio Stats).

### For Operate Commands (Direct Data Delivery)

Use `SseOperationAwaiter.execute()`:

```dart
final awaiter = ref.read(sseOperationAwaiterProvider);
final result = await awaiter!.execute(
  operateCommand: 'Device.IP.Diagnostics.IPPing()',
  referencePath: 'Device.IP.Diagnostics.IPPing()',
  args: {'Host': '8.8.8.8', 'NumberOfRepetitions': '3'},
  timeout: Duration(seconds: 30),
);

final ping = PingResult.fromOperateResult(result, '8.8.8.8');
```

The awaiter handles subscription creation, wildcard matching, cleanup, and polling fallback automatically.

---

## 11. Debug Tools

### Test Console

The USP Test Console (`lib/usp_page/test_console/views/usp_test_console_view.dart`) provides:

- **List All**: Lists bridge-level subscriptions via WASM `listSubscriptions()`
- **Purge All**: Deletes all OBUSPA subscriptions via GET-based enumeration + DELETE
- **Subscribe / Unsubscribe**: Manual subscription management for testing

### Logging

All SSE components use structured logging with `[SSE]` prefix:

```
[SSE] Connecting...
[SSE] Connected (event: heartbeat)
[SSE Router] Routing: SseNotification(sub=cpe-3, type=OperationComplete)
[SSE Operate] Matched OperationComplete for IPPing() (from sub=cpe-3)
[SSE Registry] Registered connected-devices-objectcreation → Device.LocalAgent.Subscription.5.
[SSE Bootstrap] Purged 2 stale OBUSPA subscriptions
[SSE Bootstrap] Complete — 5 core subscriptions registered
```
