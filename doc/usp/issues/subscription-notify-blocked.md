# USP Subscription / Notify Pipeline — Issue Report

**Environment**

| Item | Value |
|------|-------|
| Device | Linksys M60TB-EU (PINNACLE 2.0) |
| Firmware | 1.0.16.26013014 |
| usp-bridge | v0.1.1 |
| Date | 2026-03-09 |
| Method | Flutter WASM client + SSH + OBUSPA prototrace |

---

## Summary

After creating a Subscription and triggering an async Operate via the WASM client, the client **receives no notifications whatsoever**. There are two breakpoints in the notification pipeline; both must be fixed for end-to-end delivery.

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
    │                               bridge ──✗──→ SSE                  (Issue 2)
    │
    └── SSE stream ──→ only heartbeat, no notification events
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

## Issue 2: usp-bridge does not forward OBUSPA USP Notify to SSE

### Symptom

After manually creating an OBUSPA Subscription via USP Add and triggering Operate (IPPing), OBUSPA correctly generates a USP Notify and delivers it to the bridge, but the bridge **does not parse or forward** the message to the SSE stream.

### Reproduction Steps

1. Create a Subscription via the test page using USP Add:
   - Path: `Device.LocalAgent.Subscription.`
   - Parameters: `Enable=true`, `NotifType=OperationComplete`, `ReferenceList=Device.IP.Diagnostics.IPPing()`
2. Verify Recipient is automatically set to `Device.LocalAgent.Controller.2` (controller::localui / usp-bridge)
3. Send Operate IPPing via WASM client → receive empty OperateResp (expected for async commands)
4. Enable OBUSPA prototrace (`ubus call obuspa set '{"path":"Device.LocalAgent.Controller.2.SendOnBoardRequest","value":"1"}'`) and confirm:
   - `CMD_OPERATE_ASYNC` delivered to bbfdm ✅
   - `NOTIFY_OPR_COMPLETE` returned from bbfdm ✅
   - OBUSPA matches Subscription and generates Notify ✅
   - **USP Notify delivered to bridge via UDS** ✅
5. SSE stream: only heartbeat, **no notification event** ❌

> This test bypasses Issue 1 (OBUSPA Subscription created directly via USP Add), isolating Issue 2 independently.

### OBUSPA Log Evidence

```
Sending NotifyRequest (OperationComplete for path=Device.IP.Diagnostics.IPPing())
NOTIFY sent to controller::localui via UDS
```

### Notify Protobuf Content (captured via prototrace)

```protobuf
body {
  request {
    notify {
      subscription_id: "cpe-1"
      send_resp: false
      oper_complete {
        obj_path: "Device.IP.Diagnostics."
        command_name: "IPPing()"
        command_key: "d268a5ef-23ab-4a88-abc2-2201bed32fa6"
        req_output_args {
          output_args { key: "Status"              value: "Complete" }
          output_args { key: "IPAddressUsed"       value: "192.168.15.2" }
          output_args { key: "SuccessCount"        value: "3" }
          output_args { key: "FailureCount"        value: "0" }
          output_args { key: "AverageResponseTime" value: "5" }
          output_args { key: "MinimumResponseTime" value: "3" }
          output_args { key: "MaximumResponseTime" value: "6" }
          output_args { key: "AverageResponseTimeDetailed" value: "4677" }
          output_args { key: "MinimumResponseTimeDetailed" value: "3722" }
          output_args { key: "MaximumResponseTimeDetailed" value: "6533" }
        }
      }
    }
  }
}
```

### Scope of Impact

All USP Notification types are blocked:

| NotifType | Description | OBUSPA Generates | Bridge Forwards |
|-----------|-------------|------------------|-----------------|
| ValueChange | Parameter value changed | ✅ | ❌ |
| ObjectCreation | Object instance created | ✅ | ❌ |
| ObjectDeletion | Object instance deleted | ✅ | ❌ |
| OperationComplete | Async Operate completed | ✅ verified | ❌ verified |
| Event | Custom event | ✅ | ❌ |

### Expected Behavior

When the bridge receives a USP Notify protobuf from OBUSPA via UDS, it should:
1. Parse the Notify message content
2. Push the event to the corresponding SSE session

---

## Fix Dependencies

```
Issue 1 (subscribe does not create OBUSPA Subscription)
   │
   │  After fix → OBUSPA starts generating Notify messages
   │
   ▼
Issue 2 (bridge does not forward Notify to SSE)
   │
   │  After fix → Client receives notifications via SSE
   │
   ▼
End-to-end notifications working ✅
```

**Both issues must be fixed** for end-to-end notifications to work.

Suggested fix order:
1. **Issue 2 first** — bridge forwards Notify to SSE. Once fixed, can be verified end-to-end by manually creating an OBUSPA Subscription via USP Add.
2. **Issue 1 follows** — WASM subscribe routes through USP Add (or bridge proxies to OBUSPA), so the subscribe API automatically creates a proper OBUSPA Subscription.

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
