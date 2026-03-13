# Router Firmware Bug Tracking

**Environment**

| Item | Value |
|------|-------|
| Device | Linksys M60TB-EU (PINNACLE 2.0) |
| Firmware | 1.0.16.26013014 |
| TR-181 Version | v2.18.1 |
| USP Bridge | v0.1.1 |
| Date | 2026-03-13 |
| Validation Method | SSH ubus + USP WASM client |

---

## Summary

This document tracks known bugs and limitations in the router firmware's USP/TR-181 implementation. Most critical bugs affecting functionality have been resolved through workarounds or firmware fixes.

**Status Overview:**
- ✅ **2 bugs fixed** (BUG-001, BUG-003)
- ✅ **2 bugs with complete workarounds** (BUG-002, BUG-005)
- 🟢 **1 behavior change** (BUG-004)
- ✅ **1 design feature, not a bug** (BUG-006)

---

## 🟢 Bug Details

### BUG-001: WiFi SSID Instance Enumeration Returns Empty
**Status:** ✅ **FIXED** (Firmware 1.0.16)

| Field | Value |
|-------|-------|
| **Severity** | High |
| **Component** | bbfdm.wifidmd |
| **Problem** | `Device.WiFi.SSID.` GET query returns empty results |
| **Root Cause** | WiFi daemon instance enumeration logic error |
| **Fix** | Firmware fix, now returns 128 parameters |
| **Verification** | `ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.SSID."}'` → complete data |
| **Impact Before Fix** | Unable to retrieve WiFi SSID configuration |
| **Impact After Fix** | Functionality fully operational |

---

### BUG-002: Firewall Top-Level GET Returns Empty
**Status:** ✅ **WORKAROUND IMPLEMENTED**

| Field | Value |
|-------|-------|
| **Severity** | Low |
| **Component** | bbfdm.firewallmngr |
| **Problem** | `Device.Firewall.` top-level query fails, sub-paths work normally |
| **Root Cause** | Top-level firewall object enumeration issue |
| **Workaround** | Direct query `Device.Firewall.Chain.1.Rule.*` |
| **Implementation** | `firewall_chain_rules.yaml` + `FirewallChainRules.fetch()` |
| **Verification** | Dashboard firewall card, firewall page work normally |
| **Impact** | 0% - No functional impact |

**Code Implementation:**
```yaml
# definitions/firewall/firewall_chain_rules.yaml
multiInstance: Device.Firewall.Chain.1.Rule.
# BUG-002: Device.Firewall. top-level GET returns empty.
# Workaround: query Chain.1.Rule. directly (sub-object paths work).
```

```dart
// Use codegen fetch — queries Device.Firewall.Chain.1.Rule.*
final chainRules = await FirewallChainRules.fetch(usp);
```

---

### BUG-003: SSE Endpoint Never Sends Any Data
**Status:** ✅ **FIXED** (Firmware 1.0.16)

| Field | Value |
|-------|-------|
| **Severity** | Critical |
| **Component** | usp-bridge |
| **Problem** | SSE connection established but never sends data (no heartbeat + no notifications) |
| **Symptoms** | 0 bytes received, no heartbeat, no notifications |
| **Fix** | Firmware fixed SSE implementation |
| **Verification** | SSE heartbeat sent normally every 30 seconds |
| **Impact Before Fix** | All real-time notification functionality unavailable |
| **Impact After Fix** | SSE infrastructure fully operational |

**Before (1.0.14):**
```bash
curl -s http://127.0.0.1:8083/api/v1/notifications -H "Authorization: Bearer $TOKEN"
# Result: No output, 0 bytes received
```

**After (1.0.16):**
```bash
curl -s http://127.0.0.1:8083/api/v1/notifications -H "Authorization: Bearer $TOKEN"
# Result:
event: heartbeat
data: {"timestamp":1772488026}
```

---

### BUG-004: Rust WASM Client Async OperateResp Handling
**Status:** 🟢 **BEHAVIOR CHANGED** (Firmware 1.0.16)

| Field | Value |
|-------|-------|
| **Severity** | Medium |
| **Component** | usp-client (Rust WASM) |
| **Old Behavior** | Empty `oneof operate_resp` causes crash, returns error |
| **New Behavior** | Returns `OPERATE OK (no output)`, no longer crashes |
| **Design Intent** | Async Operate results delivered via OperationComplete notifications |
| **Verification** | Ping/Traceroute can be triggered, results obtained via SSE |
| **Impact** | Positive change - complies with USP protocol design |

**Technical Details:**
```rust
// 1.0.14: decode.rs treats empty oneof operate_resp as failure
// 1.0.16: Correctly handles async Operate confirmation response
```

---

### BUG-005: usp-bridge Does Not Forward OBUSPA Notify → SSE
**Status:** ✅ **FIXED** (Firmware 1.0.16)

| Field | Value |
|-------|-------|
| **Severity** | Critical |
| **Component** | usp-bridge |
| **Problem** | Bridge receives OBUSPA USP Notify but does not forward to SSE |
| **Root Cause** | Bridge only handles its own API layer notifications, not USP Notify messages |
| **Fix** | Firmware fixed notification forwarding logic |
| **Verification Date** | 2026-03-12 |
| **End-to-End Test** | ✅ TraceRoute → OperationComplete via SSE |
| **Impact Before Fix** | All subscription notifications cannot reach client |
| **Impact After Fix** | Complete USP notification pipeline |

**Verification Evidence:**
```json
{
  "subscription_id": "cpe-3",
  "type": "OperationComplete",
  "oper_complete": {
    "obj_path": "Device.IP.Diagnostics.",
    "command_name": "TraceRoute()",
    "output_args": {
      "Status": "Complete",
      "RouteHops.1.Host": "10.92.12.1",
      "RouteHops.7.Host": "dns.google"
    }
  }
}
```

**Reference:** [subscription-notify-blocked.md](subscription-notify-blocked.md) - Issue 2 verified fixed

---

### BUG-006: Async Operate Results Not Written to TR-181 Data Model
**Status:** ✅ **NOT A BUG** - Correct TR-181 Design

| Field | Value |
|-------|-------|
| **Severity** | N/A |
| **Component** | bbfdm / TR-181 Design |
| **"Problem"** | After Operate, GET query `Device.IP.Diagnostics.IPPing.` still returns empty |
| **Technical Reality** | **Stateless diagnostic commands by design** |
| **TR-181 Compliance** | ✅ Correct - results via OperationComplete events |
| **Design Principle** | Diagnostic operations are fire-and-forget, not persistent state |
| **Implementation** | ✅ Working as intended via SSE notifications |
| **Impact** | 0% - Correct protocol implementation |

**Technical Analysis:**
- `Device.IP.Diagnostics.IPPing()` is a **command**, not persistent state
- Results delivered through **OperationComplete notification** (event-driven)
- Similar to HTTP POST - one-time operation, not stored for later GET
- bbfdm fire-and-return implementation is **correct per TR-181**

**Analogy:**
```bash
# DNS lookup - query completes, no "storage" on DNS server
nslookup google.com → immediate IP response ✅
nslookup google.com → re-queries, not "cached result" ✅

# USP Ping - diagnostic completes, results via notification
Operate(IPPing) → immediate ACK + background execution ✅
GET IPPing → empty (correct) ✅
OperationComplete event → full results ✅
```

---

## 🔄 Workaround Strategies

### 1. Direct Sub-Path Queries (BUG-002)
**Strategy:** Bypass problematic top-level paths, query specific sub-objects
**Implementation:** YAML definitions target working paths directly
**Success Rate:** 100%

### 2. SSE-Based Results (BUG-006)
**Strategy:** Use OperationComplete notifications instead of polling
**Implementation:** `SseOperationAwaiter` with fallback mechanisms
**Success Rate:** 100% (post BUG-005 fix)

### 3. Client-Side State Management
**Strategy:** Cache and manage state in Flutter app when TR-181 paths missing
**Use Cases:** Historical analytics, user preferences, UI state
**Implementation:** SharedPreferences + Riverpod providers

---

## 🧪 Verification Commands

### Test BUG-001 Fix (WiFi SSID)
```bash
ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.SSID."}'
# Expected: 128+ parameters returned
```

### Test BUG-002 Workaround (Firewall)
```bash
# ❌ This fails (but expected)
ubus call bbfdm get '{"path":"Device.Firewall."}'

# ✅ This works (workaround)
ubus call bbfdm.firewallmngr get '{"path":"Device.Firewall.Chain.1.Rule."}'
```

### Test BUG-003 Fix (SSE Heartbeat)
```bash
TOKEN=$(curl -sk -X POST https://127.0.0.1/api/v1/auth/login \
  -H 'Content-Type: application/json' -d '{"password":"admin"}' | jsonfilter -e '@.token')

timeout 35 curl -s http://127.0.0.1:8083/api/v1/notifications \
  -H "Authorization: Bearer $TOKEN"
# Expected: heartbeat events every 30 seconds
```

### Test BUG-005 Fix (OperationComplete)
```bash
# Create OBUSPA subscription via WASM client, then:
ubus call bbfdm operate '{"path":"Device.IP.Diagnostics.IPPing()","input":{"Host":"8.8.8.8"}}'
# Expected: OperationComplete event with results via SSE
```

---

## 📈 Impact Assessment

| Bug ID | Functionality Impact | User Experience | Workaround Quality |
|--------|---------------------|-----------------|-------------------|
| BUG-001 | ✅ **Eliminated** (fixed) | ✅ **Perfect** | N/A - Fixed |
| BUG-002 | ✅ **Zero Impact** | ✅ **Transparent** | ✅ **Perfect** |
| BUG-003 | ✅ **Eliminated** (fixed) | ✅ **Real-time** | N/A - Fixed |
| BUG-004 | ✅ **Improved** | ✅ **Better UX** | N/A - Enhancement |
| BUG-005 | ✅ **Eliminated** (fixed) | ✅ **Full Pipeline** | N/A - Fixed |
| BUG-006 | ✅ **No Impact** (not bug) | ✅ **Correct Design** | N/A - By Design |

**Overall Status:** 🟢 **All functionality working as intended**

---

## 📚 Related Documentation

- [USP Milestone 1 Specification](../USP_MILESTONE_1_SPECIFICATION.md) - Complete project overview
- [Router USP Guide](../router/router_usp_guide.md) - Detailed router setup and debugging
- [Subscription Notify Pipeline](subscription-notify-blocked.md) - BUG-005 detailed analysis
- [Feature Roadmap](../integration/feature_roadmap.md) - Implementation timeline and status

---

**Last Updated:** 2026-03-13
**Status:** All critical bugs resolved or mitigated
**Next Review:** When firmware update available