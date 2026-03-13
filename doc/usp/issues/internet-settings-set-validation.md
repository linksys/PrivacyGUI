# Internet Settings Page — USP Set Path Validation Report

**Environment**

| Item | Value |
|------|-------|
| Device | Community00080 (OpenWrt 23.05-SNAPSHOT, r0-225ad95) |
| Firmware build | 2026-02-27 |
| Data model agent | bbfdm (via ubus) |
| WAN mode at test time | DHCP (`network.wan.proto='dhcp'`) |
| Date | 2026-03-10 |

---

## Summary

The USP Internet Settings page (`UspInternetSettingsView`) uses `WanSettings.save()`, `Ipv6Settings.save()`, and `WanOperations` to perform Set operations against the router. SSH-based validation of every TR-181 path revealed **multiple paths that are non-writable, missing instances, or behave incorrectly** on the current firmware. The page cannot successfully save PPPoE, Static IP (DNS/Gateway), MAC clone, or VLAN settings in its current form.

---

## Test Method

All tests performed via direct `ubus call bbfdm {get|set|add|del|schema|instances}` on the router over SSH, bypassing the WASM USP client to isolate data-model-layer behavior.

---

## WanSettings — Per-Path Results

### IPv4 Core

| # | TR-181 Path | Field | Get | Set | modified_uci | Verdict |
|---|---|---|---|---|---|---|
| 1 | `Device.IP.Interface.2.IPv4Address.1.AddressingType` | addressingType | `"DHCP"` | Returns `data:1` | **`[]` (empty)** | **BROKEN** — set accepted but value unchanged |
| 2 | `Device.IP.Interface.2.MaxMTUSize` | mtu | `1500` | `data:1` | `/etc/config/network` | OK |
| 3 | `Device.IP.Interface.2.IPv4Address.1.IPAddress` | staticIpAddress | `"192.168.200.156"` | `data:1` | `/etc/config/network` | OK |
| 4 | `Device.IP.Interface.2.IPv4Address.1.SubnetMask` | subnetMask | `"255.255.255.0"` | `data:1` | `/etc/config/network` | OK |

### Gateway & DNS

| # | TR-181 Path | Field | Get | Set | Fault | Verdict |
|---|---|---|---|---|---|---|
| 5 | `Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress` | defaultGateway | `"0.0.0.0"` | **FAIL** | 9008: "dynamic route, not permitted" | **NON-WRITABLE** |
| 6 | `Device.DNS.Client.Server.1.DNSServer` | dnsServer1 | `"192.168.200.1"` | **FAIL** | 9008: non-writable | **NON-WRITABLE** |
| 7 | `Device.DNS.Client.Server.2.DNSServer` | dnsServer2 | **Instance missing** | N/A | 9005: invalid parameter name | **NO INSTANCE** |
| 8 | `Device.DNS.Client.Server.3.DNSServer` | dnsServer3 | **Instance missing** | N/A | 9005: invalid parameter name | **NO INSTANCE** |

**Replacement paths discovered:**

| Vendor Extension Path | Writable | modified_uci | Notes |
|---|---|---|---|
| `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway` | YES | `/etc/config/network` | Use instead of Routing.Router path |
| `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers` | YES | `/etc/config/network` | Comma-separated list; replaces all 3 DNS Server paths |

### PPPoE / PPP

| # | TR-181 Path | Field | Set (no instance) | Set (after add) | Verdict |
|---|---|---|---|---|---|
| 9 | `Device.PPP.Interface.1.Username` | pppUsername | fault 9005 | `data:1` ✓ | **NEEDS ADD** |
| 10 | `Device.PPP.Interface.1.Password` | pppPassword | fault 9005 | `data:1` ✓ | **NEEDS ADD** |
| 11 | `Device.PPP.Interface.1.PPPoE.ServiceName` | pppoeServiceName | fault 9005 | **fault 9001: Request denied** | **NON-WRITABLE** (even after add) |
| 12 | `Device.PPP.Interface.1.ConnectionTrigger` | connectionTrigger | fault 9005 | `data:1` (but `modified_uci:[]`) | **SUSPECT** — no uci change |
| 13 | `Device.PPP.Interface.1.IdleDisconnectTime` | idleDisconnectTime | fault 9005 | `data:1` ✓ | **NEEDS ADD** |
| 14 | `Device.PPP.Interface.1.LCPEcho` | lcpEchoInterval | fault 9005 | **fault 9008: non-writable** | **READ-ONLY** (schema `data:"0"`) |

**PPP Instance lifecycle:**
- `bbfdm add '{"path":"Device.PPP.Interface."}'` → creates instance `.1`, modifies `/etc/bbfdm/dmmap/PPP`
- `bbfdm del '{"path":"Device.PPP.Interface.1."}'` → removes instance, modifies `/etc/bbfdm/dmmap/PPP`
- In DHCP mode, **zero PPP instances exist** — any direct Set to `Device.PPP.Interface.1.*` will fail with fault 9005 or error 7016

### VLAN

| # | TR-181 Path | Field | Current State | Verdict |
|---|---|---|---|---|
| 15 | `Device.Ethernet.VLANTermination.1.Enable` | vlanEnabled | **No instances exist** | **NEEDS ADD** |
| 16 | `Device.Ethernet.VLANTermination.1.VLANID` | vlanId | **No instances exist** | **NEEDS ADD** |

**VLAN Instance lifecycle:**
- `bbfdm add '{"path":"Device.Ethernet.VLANTermination."}'` → creates instance, modifies `/etc/config/network`
- `bbfdm del '{"path":"Device.Ethernet.VLANTermination.1."}'` → removes instance

### Bridge & MAC

| # | TR-181 Path | Field | Get | Set | Verdict |
|---|---|---|---|---|---|
| 17 | `Device.Bridging.Bridge.1.Enable` | bridgeEnabled | `true` | `data:1` (but `modified_uci:[]`) | **SUSPECT** |
| 18 | `Device.Ethernet.Link.1.MACAddress` | wanMacAddress | `"74:12:13:21:55:56"` | **fault 9008: non-writable** | **NON-WRITABLE** |
| 19 | `Device.Ethernet.Interface.1.MACAddress` | currentMacAddress | `"74:12:13:21:55:56"` | (read-only by design) | OK |

---

## Ipv6Settings — Per-Path Results

| # | TR-181 Path | Field | Get | Set | Verdict |
|---|---|---|---|---|---|
| 1 | `Device.IP.Interface.2.IPv6Enable` | ipv6Enabled | `true` | `data:1` ✓ | OK |
| 2 | `Device.DHCPv6.Client.1.Enable` | dhcpv6Enabled | `true` | `data:1` ✓ | OK |
| 3 | `Device.IPv6rd.InterfaceSetting.1.Enable` | ipv6rdEnabled | `false` | `data:1` ✓ | OK |
| 4 | `Device.IPv6rd.InterfaceSetting.1.SPIPv6Prefix` | ipv6rdPrefix | `""` | **fault 9007: pattern mismatch** (`"2001:db8::"`) | **FORMAT ISSUE** |
| 5 | `Device.IPv6rd.InterfaceSetting.1.IPv4MaskLength` | ipv6rdIpv4MaskLength | `0` | `data:1` ✓ | OK |
| 6 | `Device.IPv6rd.InterfaceSetting.1.BorderRelayIPv4Addresses` | ipv6rdBorderRelay | `""` | `data:1` ✓ | OK |

---

## WanOperations

| # | Operation Path | Method | Notes |
|---|---|---|---|
| 1 | `Device.DHCPv4.Client.1.Renew()` | renewDhcpLease | Not tested; should work in DHCP mode |
| 2 | `Device.DHCPv6.Client.1.Renew()` | renewDhcpv6Lease | Not tested; should work when DHCPv6 enabled |

---

## Issue Summary

### Critical — Blocks Core Functionality

#### ISS-1: AddressingType set is a no-op

`Device.IP.Interface.2.IPv4Address.1.AddressingType` accepts Set without error (`data:1`) but `modified_uci` is empty and the value does not change. This means the app **cannot switch WAN connection types** (DHCP ↔ PPPoE ↔ Static ↔ Bridge) via USP Set.

**Impact:** All connection type changes are broken.
**Action:** Clarify with FW team how to switch WAN protocol. Likely requires a vendor-specific Operate command or direct `uci set network.wan.proto=pppoe && uci commit network` equivalent in the data model.

#### ISS-2: PPP.Interface instances do not exist in non-PPPoE mode

When WAN is in DHCP mode, `Device.PPP.Interface.` has zero instances. Any Set to `Device.PPP.Interface.1.*` fails with fault 9005 (via bbfdm) or error 7016 (via USP protocol). This is the **direct cause of the error shown in the screenshot**.

**Impact:** PPPoE configuration cannot be saved.
**Action:** Implement USP Add (`Device.PPP.Interface.`) before setting PPP parameters when switching to PPPoE. Implement USP Delete when switching away from PPPoE. The generated code and YAML definition need to support Add/Delete operations.

#### ISS-3: Gateway path is non-writable

`Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress` returns fault 9008 ("This is a dynamic route, therefore it's not permitted to set").

**Impact:** Static IP mode cannot set default gateway.
**Action:** Use `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway` instead.

#### ISS-4: DNS Server paths are non-writable / missing instances

- `Device.DNS.Client.Server.1.DNSServer` → fault 9008 (non-writable)
- `Device.DNS.Client.Server.2.DNSServer` → fault 9005 (instance does not exist)
- `Device.DNS.Client.Server.3.DNSServer` → fault 9005 (instance does not exist)

**Impact:** Static IP mode cannot set DNS servers.
**Action:** Use `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers` (comma-separated string, e.g. `"8.8.8.8,8.8.4.4"`) instead.

#### ISS-5: MAC Clone path is non-writable

`Device.Ethernet.Link.1.MACAddress` → fault 9008.

**Impact:** MAC address clone feature is broken.
**Action:** Investigate vendor extension path. The JNAP reference mentions `X_LINKSYS_COM_MACClone.Enable` — check if bbfdm exposes a writable MAC clone path.

### High — Incorrect YAML definitions

#### ISS-6: LCPEcho is read-only on device

`Device.PPP.Interface.{i}.LCPEcho` has schema `data:"0"` (read-only). The YAML definition incorrectly marks it as `writable: true`. Set returns fault 9008.

**Impact:** LCP echo interval cannot be configured.
**Action:** Remove `writable: true` from `wan_settings.yaml` line 95 and regenerate code. Investigate if `LCPEchoRetry` or another parameter serves the intended purpose.

#### ISS-7: PPPoE.ServiceName set denied

`Device.PPP.Interface.1.PPPoE.ServiceName` has schema `data:"1"` (should be writable) but returns fault 9001 ("Request denied") when attempting to set, even after the PPP instance is successfully created. The neighboring `PPPoE.ACName` also returns fault 9001.

**Impact:** PPPoE service name cannot be configured.
**Action:** Investigate with FW team whether PPPoE sub-object requires specific instance state (e.g., `Enable=true` or `LowerLayers` configured) before parameters become writable.

### Medium — Missing Instance Management

#### ISS-8: VLANTermination has no instances by default

`Device.Ethernet.VLANTermination.` has zero instances. Enabling VLAN tagging requires a USP Add operation first.

**Impact:** VLAN tagging configuration will fail.
**Action:** Same pattern as PPP — implement Add before Set, Delete when disabling.

#### ISS-9: IPv6rd SPIPv6Prefix format validation

Setting `Device.IPv6rd.InterfaceSetting.1.SPIPv6Prefix` to `"2001:db8::"` returns fault 9007 ("List patterns did not match"). The router expects a specific format.

**Impact:** 6rd tunnel manual configuration may fail on prefix field.
**Action:** Investigate expected format — may need prefix length suffix (e.g., `"2001:db8::/32"`) or full expanded notation.

### Low — Suspect Behavior (Needs Monitoring)

#### ISS-10: ConnectionTrigger and Bridge.Enable set with empty modified_uci

Both paths return `data:1` but `modified_uci:[]`. They may be working at a dmmap level without touching uci, or may be silently failing like AddressingType. Needs verification after FW team resolves ISS-1.

---

## Vendor Extension Discovery

The router exposes Linksys-specific writable parameters under `Device.IP.Interface.{i}.IPv4Address.{i}.`:

```
Device.IP.Interface.{i}.IPv4Address.{i}.X_LINKSYS_DefaultGateway  (writable, string)
Device.IP.Interface.{i}.IPv4Address.{i}.X_LINKSYS_DNSServers      (writable, string, comma-separated)
```

These were confirmed writable via SSH testing (both modify `/etc/config/network`). They should replace the non-writable standard paths for Gateway and DNS.

The full schema for this object:

```
IPv4Address.{i}.Enable            (writable, boolean)
IPv4Address.{i}.Status            (read-only, string)
IPv4Address.{i}.Alias             (writable, string)
IPv4Address.{i}.IPAddress         (writable, string)
IPv4Address.{i}.SubnetMask        (writable, string)
IPv4Address.{i}.AddressingType    (writable per schema, but set is no-op)
IPv4Address.{i}.X_LINKSYS_DefaultGateway  (writable, string)
IPv4Address.{i}.X_LINKSYS_DNSServers      (writable, string)
```

---

## Recommended Fix Priority

1. **ISS-1** — Resolve AddressingType switching mechanism with FW team (blocks everything)
2. **ISS-2** — Implement PPP.Interface Add/Delete lifecycle in codegen or service layer
3. **ISS-3 + ISS-4** — Switch to X_LINKSYS vendor extension paths for Gateway and DNS
4. **ISS-5** — Find MAC clone vendor extension path
5. **ISS-6** — Fix YAML: remove LCPEcho writable flag
6. **ISS-7** — Investigate PPPoE.ServiceName denial with FW team
7. **ISS-8** — Implement VLANTermination Add/Delete lifecycle
8. **ISS-9** — Clarify IPv6rd prefix format
9. **ISS-10** — Re-test after ISS-1 is resolved

---

## Appendix: bbfdm CLI Reference

```bash
# Get parameter value
ubus call bbfdm get '{"path":"Device.PPP.Interface.1.Username"}'

# Set parameter value
ubus call bbfdm set '{"path":"Device.PPP.Interface.1.Username","value":"myuser"}'

# List instances of a multi-instance object
ubus call bbfdm instances '{"path":"Device.PPP.Interface."}'

# Get schema (use {i} template, not concrete instance numbers)
ubus call bbfdm schema '{"path":"Device.PPP.Interface.{i}."}'

# Add a new instance
ubus call bbfdm add '{"path":"Device.PPP.Interface."}'

# Delete an instance
ubus call bbfdm del '{"path":"Device.PPP.Interface.1."}'
```

**Schema data field meaning:**
- `"data": "1"` → writable parameter
- `"data": "0"` → read-only parameter
