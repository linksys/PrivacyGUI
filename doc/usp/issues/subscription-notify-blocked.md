# USP Subscription / Notify Pipeline — Issue Report

**Environment**

| Item | Value |
|------|-------|
| Device | Linksys M60TB-EU (PINNACLE 2.0) |
| Firmware | 1.0.16.26013014 |
| usp-bridge | v0.1.1 |
| Date | 2026-03-09 (updated 2026-03-12) |
| Method | Flutter WASM client + SSH + OBUSPA prototrace |

---

## Summary

The notification pipeline has two issues. **Issue 2 is now fixed** in FW 1.0.16. Issue 1 remains open.

```
Flutter App (WASM client)
    │
    ├── subscribe() ──→ bridge HTTP API ──→ ❌ No OBUSPA Subscription created (Issue 1)
    │
    ├── operate()   ──→ bridge ──→ OBUSPA ──→ bbfdm ──→ execution completes
    │                                            │
    │                               OBUSPA generates USP Notify (with full results)
    │                                            │
    │                               Notify delivered to bridge via UDS ✅
    │                                            │
    │                               bridge ──→ SSE ✅                  (Issue 2 — FIXED)
    │
    └── SSE stream ──→ heartbeat + notification events ✅ (when subscription exists)
```

---

## Issue 1: WASM client subscribe does not create an OBUSPA Subscription

### Symptom

When the WASM client calls `subscribe(id, path, notifType)`, it issues an HTTP request to the bridge's `POST /api/v1/subscription` endpoint instead of sending a USP Add to create a `Device.LocalAgent.Subscription.{i}` object in OBUSPA.

### Impact

- The bridge only records the subscription internally — **OBUSPA is completely unaware** that a subscription exists
- OBUSPA will not generate USP Notify messages for any events
- The bridge itself has no polling or listening mechanism to detect data model changes
- The SSE stream only contains heartbeats and will never deliver notification events

### Architecture Analysis

Two independent subscription systems currently exist with no interoperation:

| Layer | Mechanism | Creation Method | Notification Path |
|-------|-----------|-----------------|-------------------|
| **OBUSPA** | `Device.LocalAgent.Subscription.{i}` | USP Add / OBUSPA CLI | OBUSPA detects change → Notify → UDS → bridge |
| **usp-bridge** | `/api/v1/subscription` HTTP API | HTTP POST register | bridge self-managed (no detection mechanism) |

### Expected Behavior

The WASM client's subscribe should create a `Device.LocalAgent.Subscription.{i}` via USP protobuf, or the bridge should translate the request:

```
Option A: WASM subscribe → USP Add(Device.LocalAgent.Subscription.) → OBUSPA manages
Option B: WASM subscribe → bridge API → bridge proxies USP Add → OBUSPA manages
```

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

## Fix Dependencies

```
Issue 2 (bridge does not forward Notify to SSE) ── ✅ FIXED in FW 1.0.16
   │
   ▼
Issue 1 (subscribe does not create OBUSPA Subscription) ── ❌ OPEN
   │
   │  After fix → End-to-end notifications working
   │
   ▼
End-to-end notifications working ✅
```

**Issue 2 is fixed.** Issue 1 remains — the bridge subscribe API must be enhanced to create OBUSPA subscriptions.

### Current Workaround (Dart client-side)

`UspService.createNotifySubscription()` performs the full flow from the Dart client:

```
Step 1: GET Device.LocalAgent.Subscription. (snapshot existing IDs)
Step 2: USP Add Device.LocalAgent.Subscription. (create instance)
Step 3: GET Device.LocalAgent.Subscription. (diff to find new instance ID)*
Step 4: USP SetMultiple Enable=true, NotifType=..., ReferenceList=...
Step 5: GET verify Recipient points to UDS controller
```

> *Step 3 is needed because the WASM client's `add()` returns empty for `Device.LocalAgent.Subscription.` — OBUSPA's AddResp has no `updated_inst_results`. This is a Rust WASM client bug (`wasm/mod.rs:435-441`).

**Problems with the workaround:**
- 5 round-trips instead of 1
- Client must know OBUSPA internals (`Device.LocalAgent.Subscription.` schema)
- GET-diff is fragile under concurrent access
- WASM `add` return value bug requires extra GET

---

## Enhancement Request: Bridge Auto-Register OBUSPA Subscription

### Goal

The bridge `POST /api/v1/subscription` endpoint should create a proper `Device.LocalAgent.Subscription.{i}` instance in OBUSPA, not just register an internal session mapping.

### Proposed API

**Request** (same endpoint, enhanced behavior):

```http
POST /api/v1/subscription
Content-Type: application/json
Authorization: Bearer <token>

{
  "action": "register",
  "subscription_id": "client-sub-1",
  "path": "Device.IP.Diagnostics.TraceRoute()",
  "type": "OperationComplete"
}
```

`type` field should accept string names (preferred) or numeric values:

| type (string) | type (numeric) | Description |
|---------------|----------------|-------------|
| `ValueChange` | 1 | Parameter value changed |
| `ObjectCreation` | 2 | Object instance created |
| `ObjectDeletion` | 3 | Object instance deleted |
| `OperationComplete` | 4 | Async Operate completed |
| `Event` | 5 | Custom event |

**Bridge internal flow:**

```
1. Receive POST /api/v1/subscription
2. USP Add → Device.LocalAgent.Subscription.    (create OBUSPA instance)
3. USP Set → Enable=true, NotifType=<type>, ReferenceList=<path>
4. Verify Recipient → must point to bridge's own UDS controller
5. Register SSE session mapping (existing behavior)
6. Return response with instance details
```

**Response** (enhanced):

```json
{
  "status": "success",
  "instance_path": "Device.LocalAgent.Subscription.3.",
  "recipient": "Device.LocalAgent.Controller.3",
  "notif_type": "OperationComplete",
  "reference_list": "Device.IP.Diagnostics.TraceRoute()"
}
```

**Unregister** should also clean up the OBUSPA instance:

```http
POST /api/v1/subscription
{
  "action": "unregister",
  "subscription_id": "client-sub-1"
}
```

Bridge internal: USP Delete `Device.LocalAgent.Subscription.{i}.` + remove SSE mapping.

### Benefits

- Single round-trip from client
- Client doesn't need to know OBUSPA `Device.LocalAgent.` schema
- Bridge controls the full lifecycle (create + cleanup)
- No dependency on WASM `add` return value bug
- Atomic operation — no race conditions from GET-diff

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
