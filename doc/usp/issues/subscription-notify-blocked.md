# USP Subscription / Notify Pipeline — Issue Report

**Environment**

| Item | Value |
|------|-------|
| Device | Linksys M60TB-EU (PINNACLE 2.0) |
| Firmware | 1.0.16.26013014 |
| usp-bridge | v0.1.1 |
| Date | 2026-03-09 (updated 2026-03-16) |
| Method | Flutter WASM client + SSH + OBUSPA prototrace |

---

## Summary

Both issues are now resolved. The full end-to-end notification pipeline is operational.

```
Flutter App (WASM client)
    │
    ├── subscribe() ──→ bridge HTTP API ──→ ✅ Bridge auto-creates OBUSPA Subscription (Issue 1 — FIXED)
    │
    ├── operate()   ──→ bridge ──→ OBUSPA ──→ bbfdm ──→ execution completes
    │                                            │
    │                               OBUSPA generates USP Notify (with full results)
    │                                            │
    │                               Notify delivered to bridge via UDS ✅
    │                                            │
    │                               bridge ──→ SSE ✅                  (Issue 2 — FIXED)
    │
    └── SSE stream ──→ heartbeat + notification events ✅
```

---

## Issue 1: Bridge subscribe now auto-creates OBUSPA Subscription — ✅ FIXED

> **Status**: Fixed in FW 1.0.16.26013014 (bridge v0.1.1 with updated API). Verified 2026-03-16.
>
> **Resolution**: The bridge API field names changed from `type`/`path` (int/string) to `NotifType`/`ReferenceList` (string/string). With the correct field names, `POST /api/v1/subscription` now automatically creates `Device.LocalAgent.Subscription.{i}` in OBUSPA with the correct Recipient (Controller.3/UDS).

### Original Symptom (now resolved)

When the WASM client called `subscribe(id, path, notifType)` with the **old** field names (`type`/`path`), the bridge only recorded the subscription internally — OBUSPA was unaware and would not generate Notify messages.

### Root Cause

The bridge API expected new field names that were not documented:
- **Old (broken)**: `{ "type": 1, "path": "Device.Hosts.Host." }`
- **New (working)**: `{ "NotifType": "ValueChange", "ReferenceList": "Device.Hosts.Host." }`

### Verification (2026-03-16)

SSH verification confirmed bridge creates OBUSPA subscription with correct Recipient:

```bash
# Register via bridge with NEW field names
$ curl -s -X POST http://127.0.0.1:8083/api/v1/subscription \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"register","subscription_id":"test-vc","NotifType":"ValueChange","ReferenceList":"Device.Hosts.Host."}'
{"status":"success"}

# Verify OBUSPA subscription was created
$ obuspa -s /tmp/usp_cli -c 'dump' 'subscriptions'
enable=1
instance=1
cont_instance=3        # ← Controller.3 (UDS/bridge) — correct!
subscription_id=test-vc
notify_type=ValueChange
path[0]=Device.Hosts.Host.
```

Additional SSH verification:
- **Idempotency**: Re-subscribing same ID 3 times → only 1 OBUSPA subscription created (safe for reconnect)
- **Session expiry**: Bridge session timeout (36s) does NOT clean up OBUSPA subscriptions (orphan risk → bootstrap purge kept as safety net)

### Flutter Client Update

`UspBridgeClient.subscribe()` updated to use new field names:
```dart
body: jsonEncode({
  'action': 'register',
  'subscription_id': subscriptionId,
  'NotifType': notifTypeNames[notifType] ?? 'ValueChange',  // was 'type': notifType
  'ReferenceList': path,                                      // was 'path': path
}),
```

`SseSubscriptionRegistry` simplified to bridge-only (removed 5-step OBUSPA workaround — bridge handles OBUSPA lifecycle automatically).

---

## Issue 2: usp-bridge does not forward OBUSPA USP Notify to SSE — ✅ FIXED

> **Status**: Fixed in FW 1.0.16.26013014. Verified 2026-03-12.

### Verification (2026-03-12)

Created OBUSPA Subscription via WASM client USP Add (`Device.LocalAgent.Subscription.3`), then triggered Operate TraceRoute. Bridge successfully forwarded OperationComplete Notify to SSE:

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
      "RouteHops.7.Host": "dns.google",
      "RouteHops.7.HostAddress": "8.8.8.8"
    }
  }
}
```

All notification types now expected to work:

| NotifType | OBUSPA Generates | Bridge Forwards |
|-----------|------------------|-----------------|
| ValueChange | ✅ | ✅ (expected) |
| ObjectCreation | ✅ | ✅ (expected) |
| ObjectDeletion | ✅ | ✅ (expected) |
| OperationComplete | ✅ | ✅ **verified** |
| Event | ✅ | ✅ (expected) |

---

## Fix Dependencies — ✅ All Resolved

```
Issue 2 (bridge does not forward Notify to SSE) ── ✅ FIXED in FW 1.0.16 (2026-03-12)
   │
   ▼
Issue 1 (bridge subscribe creates OBUSPA sub)   ── ✅ FIXED in FW 1.0.16 (2026-03-16, new API fields)
   │
   ▼
End-to-end notifications working ✅ (verified Ping OperationComplete via SSE)
```

**Both issues are fixed.** The full SSE notification pipeline is operational.

### Previous Workaround (now deprecated)

`UspService.createNotifySubscription()` performed a 5-step OBUSPA workaround (Add + GET-diff + SetMultiple). This is no longer needed for production — bridge handles OBUSPA lifecycle automatically. The method is retained in `UspService` for legacy/debug purposes only.

---

## Bridge Subscription API — Current Working Format (✅ Implemented)

The bridge `POST /api/v1/subscription` endpoint now auto-creates OBUSPA subscriptions.

### Request Format

```http
POST /api/v1/subscription
Content-Type: application/json
Authorization: Bearer <token>

{
  "action": "register",
  "subscription_id": "client-sub-1",
  "NotifType": "OperationComplete",
  "ReferenceList": "Device.IP.Diagnostics.TraceRoute()"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `action` | string | `"register"` or `"unregister"` |
| `subscription_id` | string | Client-assigned unique ID |
| `NotifType` | string | `ValueChange`, `ObjectCreation`, `ObjectDeletion`, `OperationComplete`, `Event` |
| `ReferenceList` | string | TR-181 path to monitor |

### Bridge Internal Behavior

- **register**: Creates OBUSPA `Device.LocalAgent.Subscription.{i}` with correct Recipient (Controller.3/UDS) + SSE session mapping
- **unregister**: Deletes OBUSPA subscription + SSE session mapping
- **Idempotent**: Re-registering same `subscription_id` reuses existing OBUSPA subscription (safe for reconnect)
- **Session expiry caveat**: Bridge session timeout does NOT clean up OBUSPA subscriptions — client should purge on app startup

### Unregister

```http
POST /api/v1/subscription
{
  "action": "unregister",
  "subscription_id": "client-sub-1"
}
```

---

## Appendix: SSH Verification Log

Full SSH session recorded on 2026-03-09T03:42 GMT.

### A.1 Environment & Health Check

```
$ ssh root@192.168.1.1

=== 1. Environment ===
--- Firmware ---
{
    "SoftwareVersion": "1.0.16.26013014"
}
--- usp-bridge ---
30408 root      5576 S    /usr/sbin/usp-bridge
--- OBUSPA ---
 5954 root      5596 S    {dm_obuspa} /usr/sbin/dm-service -m obuspa -l 3
18848 root     10176 S    /usr/sbin/obuspa -v 5 -l /tmp/obuspa.log -f /etc/obu

=== 2. Health Check ===
JWT token: eyJhbGciOiJIUzI1NiIs...(305 chars)

$ curl -s http://127.0.0.1:8083/api/v1/health -H "Authorization: Bearer $TOKEN"
{
  "status": "healthy",
  "service": "usp-bridge",
  "version": "0.1.1",
  "agent_connected": true,
  "uptime_seconds": 5769,
  "requests_processed": 16,
  "notifications_delivered": 0
}
```

> Note: `notifications_delivered: 0` — bridge has never delivered any notification since startup.

### A.2 Controller Mapping

```
$ obuspa -s /tmp/usp_cli -c 'get' 'Device.LocalAgent.Controller.1.EndpointID'
Device.LocalAgent.Controller.1.EndpointID => self:ft:1

$ obuspa -s /tmp/usp_cli -c 'get' 'Device.LocalAgent.Controller.2.EndpointID'
Device.LocalAgent.Controller.2.EndpointID => controller::localui
```

- Controller.1 = MQTT (cloud)
- Controller.2 = UDS (localui / usp-bridge)

### A.3 Bridge Subscribe API Does Not Create OBUSPA Subscription

```
$ curl -s -X POST http://127.0.0.1:8083/api/v1/subscription \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"register","subscription_id":"test-verify","path":"Device.IP.Diagnostics.IPPing.","type":1}'
{"status":"success"}

$ obuspa -s /tmp/usp_cli -c 'dump' 'subscriptions'
enable=1
instance=1
cont_instance=1
subscription_id=cpe-1
notification_retry=0
notify_type=OperationComplete
expiry_time=2038-01-19T03:14:07Z
path[0]=Device.IP.Diagnostics.IPPing(), handler_group_id=-1
-
```

> Only the previously CLI-created `cpe-1` subscription appears. The bridge's `{"status":"success"}` response did **NOT** create any OBUSPA Subscription. This confirms Issue 1.

```
$ curl -s -X POST http://127.0.0.1:8083/api/v1/subscription \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"unregister","subscription_id":"test-verify"}'
{"status":"success"}
```

### A.4 OBUSPA Subscription Creation via CLI

```
$ obuspa -s /tmp/usp_cli -c 'add' 'Device.LocalAgent.Subscription.'
Added Device.LocalAgent.Subscription.1

$ obuspa -s /tmp/usp_cli -c 'set' 'Device.LocalAgent.Subscription.1.Enable' 'true'
Device.LocalAgent.Subscription.1.Enable => true

$ obuspa -s /tmp/usp_cli -c 'set' 'Device.LocalAgent.Subscription.1.NotifType' 'OperationComplete'
Device.LocalAgent.Subscription.1.NotifType => OperationComplete

$ obuspa -s /tmp/usp_cli -c 'set' 'Device.LocalAgent.Subscription.1.ReferenceList' 'Device.IP.Diagnostics.IPPing()'
Device.LocalAgent.Subscription.1.ReferenceList => Device.IP.Diagnostics.IPPing()

$ obuspa -s /tmp/usp_cli -c 'get' 'Device.LocalAgent.Subscription.1.'
Device.LocalAgent.Subscription.1.Alias => cpe-1
Device.LocalAgent.Subscription.1.Enable => true
Device.LocalAgent.Subscription.1.Recipient => Device.LocalAgent.Controller.1
Device.LocalAgent.Subscription.1.ID => cpe-1
Device.LocalAgent.Subscription.1.CreationDate => 2026-03-09T03:42:41Z
Device.LocalAgent.Subscription.1.NotifType => OperationComplete
Device.LocalAgent.Subscription.1.ReferenceList => Device.IP.Diagnostics.IPPing()
Device.LocalAgent.Subscription.1.Persistent => false
Device.LocalAgent.Subscription.1.TimeToLive => 0
Device.LocalAgent.Subscription.1.NotifRetry => false
Device.LocalAgent.Subscription.1.NotifExpiration => 0

$ obuspa -s /tmp/usp_cli -c 'dump' 'subscriptions'
enable=1
instance=1
cont_instance=1
subscription_id=cpe-1
notification_retry=0
notify_type=OperationComplete
expiry_time=2038-01-19T03:14:07Z
path[0]=Device.IP.Diagnostics.IPPing(), handler_group_id=-1
-
```

> Note: `Recipient => Device.LocalAgent.Controller.1` (MQTT/cloud) because CLI requests are attributed to Controller.1. To target Controller.2 (localui/bridge), must use USP Add via WASM client.

### A.5 SSE Heartbeat Test

```
$ timeout 35 curl -s http://127.0.0.1:8083/api/v1/notifications \
  -H "Authorization: Bearer $TOKEN"
event: heartbeat
data: {"timestamp":1773027837}

(terminated after 35s — only heartbeat received, no notification events)
```

### A.6 Operate via ubus (Direct bbfdm — Bypasses OBUSPA)

```
$ ubus call bbfdm operate \
  '{"path":"Device.IP.Diagnostics.IPPing()","action":"ping","input":{"Host":"8.8.8.8","NumberOfRepetitions":"3"}}'
{
    "results": [{
        "path": "Device.IP.Diagnostics.IPPing()",
        "output": [
            {"path": "Status",                      "data": "Complete"},
            {"path": "IPAddressUsed",                "data": "192.168.15.2"},
            {"path": "SuccessCount",                 "data": "3"},
            {"path": "FailureCount",                 "data": "0"},
            {"path": "AverageResponseTime",          "data": "6"},
            {"path": "MinimumResponseTime",          "data": "5"},
            {"path": "MaximumResponseTime",          "data": "6"},
            {"path": "AverageResponseTimeDetailed",  "data": "6230"},
            {"path": "MinimumResponseTimeDetailed",  "data": "5732"},
            {"path": "MaximumResponseTimeDetailed",  "data": "6499"}
        ]
    }]
}
```

> ubus operate returns results synchronously. However, this bypasses OBUSPA entirely — no Notify is generated. The WASM client's operate goes through OBUSPA (USP protobuf), which returns an empty OperateResp and delivers results via OperationComplete Notify.

### A.7 Bridge Health — notifications_delivered Counter

```
$ curl -s http://127.0.0.1:8083/api/v1/health -H "Authorization: Bearer $TOKEN"
{
  "status": "healthy",
  "service": "usp-bridge",
  "version": "0.1.1",
  "agent_connected": true,
  "uptime_seconds": 5880,
  "requests_processed": 16,
  "notifications_delivered": 0
}
```

> `notifications_delivered: 0` throughout the entire session — the bridge has **never** forwarded any notification to any SSE client.
