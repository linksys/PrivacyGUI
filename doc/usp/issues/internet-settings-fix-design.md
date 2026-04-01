# Internet Settings — USP Set Fix Design Document

**Date:** 2026-03-10
**Branch:** peter/usp-internet-setting
**Related:**
- [internet-settings-set-validation.md](internet-settings-set-validation.md) — SSH test results
- [internet-settings-jnap-vs-usp-comparison.md](internet-settings-jnap-vs-usp-comparison.md) — Feature comparison
- [usp-add-latency.md](usp-add-latency.md) — Add/Set latency analysis

---

## 1. Goal

Make the USP Internet Settings page capable of **reading and writing all WAN configuration** that the old JNAP-based page supports, using the USP TR-181 data model.

The page was built in the `peter/usp-internet-setting` branch and currently has a working UI with full read support. However, SSH validation revealed that **most write operations fail** due to non-writable paths, missing multi-instance objects, and a non-functional connection type switch mechanism.

**Success criteria:**
- User can switch between DHCP, Static IP, PPPoE, and Bridge modes and save successfully
- All editable fields (DNS, Gateway, PPP credentials, MTU, VLAN, MAC clone) persist to the router
- Save completes without error on the target firmware

---

## 2. Problem Summary

SSH validation (2026-03-10) on Community00080 (OpenWrt 23.05-SNAPSHOT) found 10 issues across 3 categories:

### 2.1 Wrong paths — standard TR-181 paths are non-writable on this firmware

| Field | Current Path | Fault | Replacement Path |
|---|---|---|---|
| Default gateway | `Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress` | 9008 | `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway` |
| DNS servers (3 paths) | `Device.DNS.Client.Server.[1-3].DNSServer` | 9008 / 9005 | `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers` (comma-separated) |
| MAC clone | `Device.Ethernet.Link.1.MACAddress` | 9008 | Unknown — needs FW investigation |
| LCP echo interval | `Device.PPP.Interface.1.LCPEcho` | 9008 | Read-only on device; remove writable flag |

### 2.2 Missing instances — multi-instance objects require Add before Set

| Object | basePath | Default State (FW 2026-02-27) | Default State (FW 2026-03-18) | Needed When |
|---|---|---|---|---|
| PPP Interface | `Device.PPP.Interface.` | 0 instances in non-PPPoE mode | **1 instance** in DHCP mode | Switching to PPPoE (if 0 instances) |
| VLAN Termination | `Device.Ethernet.VLANTermination.` | 0 instances | **1 instance** in default state | Enabling VLAN tagging (if 0 instances) |

> **Note (2026-03-19):** Newer firmware (build 2026-03-18) ships with 1 default instance for both PPP and VLAN even in DHCP mode. The Add/Delete lifecycle code should check `NumberOfEntries` before Add to handle both firmware behaviors gracefully.

### 2.3 Firmware-level blockers — require FW team involvement

| Issue | Description |
|---|---|
| ISS-1: AddressingType set is no-op | `bbfdm set` returns success but `modified_uci: []` and value unchanged |
| ISS-7: PPPoE.ServiceName denied | fault 9001 even after PPP instance exists |
| ISS-5: MAC clone path | No known writable path yet |

---

## 3. Proposed Solution

### 3.1 Architecture: Split YAML + codegen Add/Delete

The codegen already supports multi-instance Add/Delete generation (used by port_forwarding, dhcp_reservations, static_routing, etc.). The fix is to **split `wan_settings.yaml` so that PPP and VLAN become independent multi-instance definitions**, then let codegen generate the Add/Delete methods.

**Current structure (single monolithic definition):**

```
wan_settings.yaml
├── Device.IP.Interface.2.IPv4Address.1.*      (singleton, exists)
├── Device.PPP.Interface.1.*                    (multi-instance, may not exist)
├── Device.Ethernet.VLANTermination.1.*         (multi-instance, may not exist)
├── Device.DNS.Client.Server.[1-3].*            (wrong paths)
├── Device.Routing.Router.1.*                   (wrong path)
├── Device.Bridging.Bridge.1.*                  (singleton, exists)
├── Device.Ethernet.Link.1.*                    (wrong path)
└── Device.Ethernet.Interface.1.*               (singleton, read-only)
```

**Proposed structure (split by lifecycle):**

```
wan_settings.yaml        — Singleton fields that always exist
├── Device.IP.Interface.2.IPv4Address.1.AddressingType
├── Device.IP.Interface.2.IPv4Address.1.IPAddress
├── Device.IP.Interface.2.IPv4Address.1.SubnetMask
├── Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway  (NEW)
├── Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers      (NEW)
├── Device.IP.Interface.2.MaxMTUSize
├── Device.Bridging.Bridge.1.Enable
└── Device.Ethernet.Interface.1.MACAddress (read-only)

ppp_interface.yaml (NEW) — Multi-instance with type: add
├── basePath: Device.PPP.Interface.
├── Device.PPP.Interface.{i}.Username
├── Device.PPP.Interface.{i}.Password
├── Device.PPP.Interface.{i}.ConnectionTrigger
├── Device.PPP.Interface.{i}.IdleDisconnectTime
├── Device.PPP.Interface.{i}.ConnectionStatus (read-only)
└── Device.PPP.Interface.{i}.LCPEcho (read-only)

vlan_termination.yaml (NEW) — Multi-instance with type: add
├── basePath: Device.Ethernet.VLANTermination.
├── Device.Ethernet.VLANTermination.{i}.Enable
└── Device.Ethernet.VLANTermination.{i}.VLANID
```

**Removed from wan_settings.yaml:**
- `Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress` → replaced by `X_LINKSYS_DefaultGateway`
- `Device.DNS.Client.Server.[1-3].DNSServer` → replaced by `X_LINKSYS_DNSServers`
- `Device.Ethernet.Link.1.MACAddress` → removed until writable path found (ISS-5)
- `Device.PPP.Interface.1.*` → moved to `ppp_interface.yaml`
- `Device.Ethernet.VLANTermination.1.*` → moved to `vlan_termination.yaml`

### 3.2 Generated code outcome

After codegen:

```dart
// wan_settings.g.dart — slimmed down
class WanSettings {
  final String addressingType;
  final String staticIpAddress;
  final String subnetMask;
  final String defaultGateway;      // X_LINKSYS_DefaultGateway
  final String dnsServers;          // X_LINKSYS_DNSServers (comma-separated)
  final int mtu;
  final bool bridgeEnabled;
  final String currentMacAddress;   // read-only

  static Future<WanSettings> fetch(UspService client) async { ... }
  static Future<void> save(UspService client, { ... }) async { ... }
}

// ppp_interface.g.dart — NEW, multi-instance with add/delete
class PppInterfaceInstance {
  final String instancePath;
  final String username;
  final String password;
  final String connectionTrigger;
  final int idleDisconnectTime;
  final String connectionStatus;   // read-only
  final int lcpEcho;               // read-only

  // ...
}
class PppInterface {
  static Future<List<PppInterfaceInstance>> fetch(UspService client) async { ... }
  static Future<String> add(UspService client, { ... }) async { ... }
  static Future<void> delete(UspService client, String instancePath) async { ... }
}

// vlan_termination.g.dart — NEW, multi-instance with add/delete
class VlanTerminationInstance {
  final String instancePath;
  final bool enabled;
  final int vlanId;

  // ...
}
class VlanTermination {
  static Future<List<VlanTerminationInstance>> fetch(UspService client) async { ... }
  static Future<String> add(UspService client, { ... }) async { ... }
  static Future<void> delete(UspService client, String instancePath) async { ... }
}
```

### 3.3 Service layer changes

`UspInternetSettingsService` becomes the orchestrator for multi-step save:

```dart
Future<void> saveAll(original, edited) async {
  // Step 1: Handle PPP instance lifecycle
  await _handlePppLifecycle(original, edited);

  // Step 2: Handle VLAN instance lifecycle
  await _handleVlanLifecycle(original, edited);

  // Step 3: Save singleton WAN fields (AddressingType, MTU, static IP, DNS, gateway, bridge)
  await _saveWanSettings(original, edited);

  // Step 4: Save IPv6 fields
  await _saveIpv6Settings(original, edited);
}
```

### 3.4 Form model changes

`UspInternetSettingsForm.fromGenerated()` signature changes:

```dart
factory UspInternetSettingsForm.fromGenerated(
  WanSettings wan,
  Ipv6Settings ipv6,
  PppInterfaceInstance? ppp,     // nullable — may not exist
  VlanTerminationInstance? vlan, // nullable — may not exist
) { ... }
```

DNS conversion logic lives in the form factory:

```dart
// fetch: comma-separated → 3 fields
final dnsParts = wan.dnsServers.split(',');
dnsServer1: dnsParts.isNotEmpty ? dnsParts[0].trim() : '',
dnsServer2: dnsParts.length > 1 ? dnsParts[1].trim() : '',
dnsServer3: dnsParts.length > 2 ? dnsParts[2].trim() : '',

// save: 3 fields → comma-separated
final dnsValue = [edited.dnsServer1, edited.dnsServer2, edited.dnsServer3]
    .where((s) => s.isNotEmpty).join(',');
```

---

## 4. Design Decisions

These need to be decided before implementation:

### DD-1: PPP instance lifecycle — when to Add and Delete?

| Option | Add | Delete | Pros | Cons |
|---|---|---|---|---|
| **A: Strict** | When switching TO PPPoE | When switching AWAY from PPPoE | Clean state; no stale instances | Must handle Add failure gracefully |
| B: Lazy create, never delete | When switching TO PPPoE (if not exists) | Never | Simpler; instance reused next time | Stale instance persists; may confuse router |
| C: Always check | Before save, check `instances` and Add if needed | When switching away | Most robust | Extra fetch on every save; slower |

**Recommended: A** — matches the router's natural state (DHCP = no PPP instance).

### DD-2: VLAN instance lifecycle — when to Add and Delete?

| Option | Add | Delete | Pros | Cons |
|---|---|---|---|---|
| **A: Match toggle** | When enabling VLAN | When disabling VLAN | Clean state | Extra step on every toggle |
| B: Lazy create, Set Enable=false | When enabling (if not exists) | Never; set Enable=false | Simpler | Instance persists when disabled |

**Recommended: A** — consistent with PPP approach.

### DD-3: Save failure rollback

| Option | Behavior | Pros | Cons |
|---|---|---|---|
| A: No rollback | On failure, re-fetch and update UI to reflect actual device state | Simple; reliable | User may see partial changes |
| **B: Best-effort rollback** | On failure, attempt to Delete any just-created instances, then re-fetch | Cleaner UX | Rollback itself may fail; complex |

**Recommended: A** — rollback adds complexity and may itself fail. Re-fetch is already implemented in the current save flow.

### DD-4: DNS field conversion location

| Option | Where | Pros | Cons |
|---|---|---|---|
| **A: Form factory + service** | `fromGenerated()` splits; service merges | Keeps form UI-friendly (3 fields); conversion logic explicit | Manual code outside codegen |
| B: Codegen transform | YAML transform definition | Fully declarative | Codegen may not support split/merge transforms |

**Recommended: A** — the codegen transform system is designed for value conversions (e.g., enum mapping), not split/merge of fields.

### DD-5: How many YAML files to split into?

| Option | Files | Pros | Cons |
|---|---|---|---|
| A: 2 new files | ppp_interface.yaml + vlan_termination.yaml | Minimal change | wan_settings.yaml still large |
| **B: 2 new files + slim wan_settings** | Same + remove wrong paths from wan_settings | Clean; only valid paths remain | More changes to existing code |

**Recommended: B** — removing non-writable paths prevents future confusion.

---

## 5. Risks and Mitigations

### Risk 1: AddressingType remains non-functional (ISS-1)

**Severity:** Critical — blocks connection type switching entirely.

**Mitigation:** Implement the Add/Delete and path fixes first (they are independently useful). AddressingType switching can be added later once FW team provides the correct mechanism. In the interim, the page can still:
- Edit settings for the **current** connection type (e.g., change PPP password if already in PPPoE mode)
- Save MTU, IPv6, and other singleton fields

**Open question for FW team:** Does adding a `Device.PPP.Interface.` instance + setting its fields + calling some Operate command automatically switch the WAN proto? Or is there a vendor-specific path like `X_LINKSYS_WanType`?

### Risk 2: Add latency compounds save time

**Severity:** High — each Add/Set triggers ~7-8s `bbf.config commit`.

**Worst case (DHCP → PPPoE + VLAN enable):**
```
Add PPP.Interface          ~8s
Set PPP params             ~8s
Add VLANTermination        ~8s
Set VLAN params            ~8s
Set WAN singleton params   ~8s
Set IPv6 params            ~8s
                    Total: ~48s
```

**Mitigation:**
- Combine Set params into as few USP Set messages as possible (already diff-based)
- Investigate whether `allowPartial: true` can batch Add + Set into fewer transactions
- Display progress feedback in UI (e.g., "Creating PPP interface..." → "Saving settings...")
- Long-term: work with FW team on the commit latency issue (see [usp-add-latency.md](usp-add-latency.md))

### Risk 3: Instance number is not always 1

**Severity:** Medium — `add()` may return `.2.` instead of `.1.`.

**Mitigation:** The codegen multi-instance pattern uses wildcard fetch (`Device.PPP.Interface.*.Username`) and returns a list with `instancePath` on each item. Save/delete operations use the `instancePath` from fetch result, never hardcoded numbers. This is already the standard pattern in port_forwarding, etc.

### Risk 4: Partial save leaves inconsistent state

**Severity:** Medium — Add succeeds but subsequent Set fails.

**Mitigation (per DD-3 decision):**
- Re-fetch after any failure to reflect actual device state in UI
- User sees the real state and can retry
- No rollback attempt (which could itself fail and make things worse)

### Risk 5: PPPoE.ServiceName remains denied (ISS-7)

**Severity:** Low — service name is optional in most ISP configurations.

**Mitigation:** Keep the field in UI but skip it in save if the path is known to be denied. Log a warning. Revisit after FW team investigation.

---

## 6. Implementation Phases

### Phase 1: Path fixes (no FW dependency, no Add/Delete)

**Goal:** Fix all singleton writable paths so that editing existing settings works.

1. Update `wan_settings.yaml`:
   - Replace `Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress` with `...X_LINKSYS_DefaultGateway`
   - Replace 3 DNS paths with single `...X_LINKSYS_DNSServers`
   - Remove `Device.Ethernet.Link.1.MACAddress` (non-writable; park MAC clone feature)
   - Remove `writable: true` from `LCPEcho`
   - Mark `AddressingType` as `writable: true` (schema confirms `data:"1"`)
2. Regenerate `wan_settings.g.dart`
3. Update `UspInternetSettingsForm.fromGenerated()` — DNS split/merge logic
4. Update `UspInternetSettingsService._saveWanSettings()` — DNS merge, remove MAC clone save
5. Update UI: hide MAC clone edit (or show read-only) until ISS-5 resolved
6. Test: save MTU, static IP, subnet mask, gateway, DNS in current mode

### Phase 2: Multi-instance Add/Delete

**Goal:** Enable PPPoE and VLAN configuration.

7. Create `ppp_interface.yaml` with `type: add`, `multiInstance: true`
8. Create `vlan_termination.yaml` with `type: add`, `multiInstance: true`
9. Remove PPP and VLAN fields from `wan_settings.yaml`
10. Regenerate all 3 files
11. Update `UspInternetSettingsForm` — accept nullable PPP/VLAN from fetch
12. Update `UspInternetSettingsService`:
    - `fetchSettings()` — parallel fetch WAN + IPv6 + PPP + VLAN
    - `saveAll()` — orchestrate Add/Delete + Set in correct order
13. Update `UspInternetSettingsState` — track PPP/VLAN instance paths
14. Test: switch to PPPoE (Add + Set), switch back to DHCP (Delete)

### Phase 3: FW team collaboration

**Goal:** Resolve firmware-level blockers.

15. ISS-1: Get correct mechanism for AddressingType / WAN proto switching
16. ISS-5: Get writable MAC clone path
17. ISS-7: Understand PPPoE.ServiceName denial conditions
18. ISS-9: Clarify IPv6rd prefix format
19. Integrate FW team answers into YAML + service layer

### Phase 4: Feature parity with old page

**Goal:** Close remaining gaps vs JNAP page.

20. Bridge mode: redirect URL handling + remote setting disable
21. MAC clone: enable/disable toggle (once ISS-5 resolved)
22. Evaluate PPTP/L2TP feasibility via vendor extensions

---

## 7. Files Affected

| File | Phase | Change |
|---|---|---|
| `doc/usp/definitions/network/wan_settings.yaml` | 1, 2 | Path swaps, remove PPP/VLAN/MAC fields |
| `doc/usp/definitions/network/ppp_interface.yaml` | 2 | **New file** |
| `doc/usp/definitions/network/vlan_termination.yaml` | 2 | **New file** |
| `lib/generated/wan_settings.g.dart` | 1, 2 | Regenerated (slimmer) |
| `lib/generated/ppp_interface.g.dart` | 2 | **New generated file** |
| `lib/generated/vlan_termination.g.dart` | 2 | **New generated file** |
| `lib/usp_page/internet_settings/models/usp_internet_settings_form.dart` | 1, 2 | DNS conversion; nullable PPP/VLAN |
| `lib/usp_page/internet_settings/services/usp_internet_settings_service.dart` | 1, 2 | DNS merge; Add/Delete orchestration |
| `lib/usp_page/internet_settings/providers/usp_internet_settings_state.dart` | 2 | Track instance paths |
| `lib/usp_page/internet_settings/providers/usp_internet_settings_notifier.dart` | 2 | Updated fetch/save flow |
| `lib/usp_page/internet_settings/views/sections/usp_optional_section.dart` | 1 | Hide MAC clone edit if non-writable |
