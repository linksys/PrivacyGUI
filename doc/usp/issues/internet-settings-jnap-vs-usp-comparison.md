# Internet Settings — JNAP vs USP Feature Comparison

**Date:** 2026-03-10
**Related:** [internet-settings-set-validation.md](internet-settings-set-validation.md)

---

## Overview

The USP Internet Settings page (`lib/usp_page/internet_settings/`) is a rewrite of the JNAP-based page (`lib/page/advanced_settings/internet_settings/`). This document compares the two implementations and tracks the current functional status of every feature.

---

## Architecture Differences

| Aspect | Old Page (JNAP) | New Page (USP) |
|---|---|---|
| Protocol | JNAP — proprietary Linksys API | USP TR-181 — standards-based data model |
| Save mechanism | Single transaction: `setWANSettings` + `setIPv6Settings` + `setMACAddressCloneSettings` sends all fields atomically | Diff-based: only changed fields sent in one USP Set message |
| Connection type switch | JNAP `wanType` field — one field controls everything | `AddressingType` field — **currently non-functional** (see ISS-1) |
| Instance management | Not needed — JNAP handles internally | **Manual Add/Delete required** for multi-instance objects (PPP, VLAN) |
| Field granularity | Coarse — one action covers many fields | Fine — each field is an independent TR-181 path |
| Error atomicity | Transaction-level: all-or-nothing | Per-parameter: partial failures possible |

---

## Connection Type Support

| Type | Old (JNAP) | New (USP) | USP Status |
|---|---|---|---|
| DHCP | ✅ Fully working | ✅ UI implemented | Read works; **cannot switch to/from** (ISS-1) |
| Static IP | ✅ Fully working | ✅ UI implemented | **Broken** — Gateway/DNS paths non-writable (ISS-3/4) |
| PPPoE | ✅ Fully working | ✅ UI implemented | **Broken** — PPP instance missing (ISS-2), ServiceName denied (ISS-7) |
| Bridge | ✅ Fully working + redirect handling | ✅ UI implemented | **Unverified** — Bridge.Enable suspect (ISS-10), no redirect handling |
| PPTP | ✅ Fully working | ❌ Not implemented | No standard TR-181 mapping for PPTP |
| L2TP | ✅ Fully working | ❌ Not implemented | No standard TR-181 mapping for L2TP |
| Telstra | Listed in enum, not implemented | ❌ | — |
| DSLite | Listed in enum, not implemented | ❌ | — |

---

## IPv4 Field-by-Field Comparison

### Core Connection Fields

| Field | Old (JNAP) | New (USP) | USP Path | Writable? | Issue |
|---|---|---|---|---|---|
| Connection type selector | ✅ `wanType` in `setWANSettings` | ✅ `connectionType` | `...IPv4Address.1.AddressingType` | **NO** — set is no-op | ISS-1 |
| Static IP address | ✅ `staticSettings.ipAddress` | ✅ `staticIpAddress` | `...IPv4Address.1.IPAddress` | ✅ YES | — |
| Subnet mask | ✅ `staticSettings.networkPrefixLength` (prefix) | ✅ `subnetMask` (dotted) | `...IPv4Address.1.SubnetMask` | ✅ YES | Format differs: old=prefix length, new=dotted mask |
| Default gateway | ✅ `staticSettings.gateway` | ✅ `defaultGateway` | `...Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress` | **NO** — fault 9008 | ISS-3 |
| DNS server 1 | ✅ `staticSettings.dns1` | ✅ `dnsServer1` | `...DNS.Client.Server.1.DNSServer` | **NO** — fault 9008 | ISS-4 |
| DNS server 2 | ✅ `staticSettings.dns2` | ✅ `dnsServer2` | `...DNS.Client.Server.2.DNSServer` | **NO** — instance missing | ISS-4 |
| DNS server 3 | ✅ `staticSettings.dns3` | ✅ `dnsServer3` | `...DNS.Client.Server.3.DNSServer` | **NO** — instance missing | ISS-4 |
| Domain name | ✅ `staticSettings.domainName` | ❌ Not mapped | — | — | No standard TR-181 path |
| Network prefix length | ✅ `staticSettings.networkPrefixLength` | ❌ Not mapped | — | — | USP uses SubnetMask instead |

### PPPoE Fields

| Field | Old (JNAP) | New (USP) | USP Path | Writable? | Issue |
|---|---|---|---|---|---|
| Username | ✅ `pppoeSettings.username` | ✅ `pppUsername` | `...PPP.Interface.1.Username` | ✅ after Add | ISS-2 (needs Add) |
| Password | ✅ `pppoeSettings.password` | ✅ `pppPassword` | `...PPP.Interface.1.Password` | ✅ after Add | ISS-2 (needs Add) |
| Service name | ✅ `pppoeSettings.serviceName` | ✅ `pppoeServiceName` | `...PPP.Interface.1.PPPoE.ServiceName` | **NO** — fault 9001 | ISS-7 |
| Connection mode | ✅ `behavior` (KeepAlive/ConnectOnDemand) | ✅ `connectionTrigger` (AlwaysOn/OnDemand) | `...PPP.Interface.1.ConnectionTrigger` | ⚠️ suspect | ISS-10 |
| Max idle time | ✅ `maxIdleMinutes` (minutes) | ✅ `idleDisconnectTime` (seconds) | `...PPP.Interface.1.IdleDisconnectTime` | ✅ after Add | Unit differs: old=minutes, new=seconds |
| LCP echo / reconnect | ✅ `reconnectAfterSeconds` | ✅ `lcpEchoInterval` | `...PPP.Interface.1.LCPEcho` | **NO** — read-only | ISS-6 |

### VLAN Tagging

| Field | Old (JNAP) | New (USP) | USP Path | Writable? | Issue |
|---|---|---|---|---|---|
| VLAN enable | ✅ `wanTaggingSettings.enable` (PPPoE only) | ✅ `vlanEnabled` (all modes) | `...Ethernet.VLANTermination.1.Enable` | ❌ instance missing | ISS-8 |
| VLAN ID | ✅ `wanTaggingSettings.vlanId` | ✅ `vlanId` | `...Ethernet.VLANTermination.1.VLANID` | ❌ instance missing | ISS-8 |

### MAC Address Clone

| Field | Old (JNAP) | New (USP) | USP Path | Writable? | Issue |
|---|---|---|---|---|---|
| Clone enable toggle | ✅ `setMACAddressCloneSettings.enable` | ❌ Not implemented | — | — | Missing feature |
| Clone MAC address | ✅ `setMACAddressCloneSettings.macAddress` | ✅ `wanMacAddress` | `...Ethernet.Link.1.MACAddress` | **NO** — fault 9008 | ISS-5 |
| Current MAC (read-only) | ✅ via device lookup | ✅ `currentMacAddress` | `...Ethernet.Interface.1.MACAddress` | read-only (OK) | — |

### MTU

| Field | Old (JNAP) | New (USP) | USP Path | Writable? | Issue |
|---|---|---|---|---|---|
| MTU size | ✅ `mtu` in `setWANSettings` | ✅ `mtu` (0=auto) | `...IP.Interface.2.MaxMTUSize` | ✅ YES | — |

### Bridge Mode Extras

| Field | Old (JNAP) | New (USP) | USP Path | Writable? | Issue |
|---|---|---|---|---|---|
| Bridge enable | ✅ implicit in `wanType='Bridge'` | ✅ `bridgeEnabled` | `...Bridging.Bridge.1.Enable` | ⚠️ suspect | ISS-10 |
| Disable remote setting | ✅ `setRemoteSetting.isEnabled=false` | ❌ Not implemented | — | — | Missing feature |
| Save redirect URL | ✅ stored in SharedPreferences | ❌ Not implemented | — | — | Missing feature |

---

## IPv6 Field-by-Field Comparison

### Connection Type

| Field | Old (JNAP) | New (USP) | Notes |
|---|---|---|---|
| IPv6 WAN type selector | ✅ 8 types: Automatic, Static, Bridge, 6rd, SLAAC, DHCPv6, PPPoE, Pass-through | ❌ Only enable/disable toggle | Different design: old page has explicit type dropdown, new page derives state from individual flags |

### IPv6 Core

| Field | Old (JNAP) | New (USP) | USP Path | Writable? | Issue |
|---|---|---|---|---|---|
| IPv6 enable | ✅ implicit in type selection | ✅ `ipv6Enabled` | `...IP.Interface.2.IPv6Enable` | ✅ YES | — |
| DHCPv6 enable | ✅ implicit in Automatic type | ✅ `dhcpv6Enabled` | `...DHCPv6.Client.1.Enable` | ✅ YES | — |
| DHCPv6 DUID (read-only) | ❌ Not shown | ✅ `dhcpv6Duid` | `...DHCPv6.Client.1.DUID` | read-only (OK) | — |

### 6rd Tunnel

| Field | Old (JNAP) | New (USP) | USP Path | Writable? | Issue |
|---|---|---|---|---|---|
| 6rd tunnel mode | ✅ `ipv6rdTunnelMode` (Disabled/Auto/Manual) | ❌ Only enable/disable | — | — | Mode concept not mapped |
| 6rd enable | ✅ implicit in tunnel mode | ✅ `ipv6rdEnabled` | `...IPv6rd.InterfaceSetting.1.Enable` | ✅ YES | — |
| 6rd prefix | ✅ `ipv6Prefix` | ✅ `ipv6rdPrefix` | `...IPv6rd.InterfaceSetting.1.SPIPv6Prefix` | ⚠️ format validation | ISS-9 |
| 6rd prefix length | ✅ `ipv6PrefixLength` | ❌ Not mapped | — | — | No separate TR-181 field |
| 6rd IPv4 mask length | ❌ Not in old UI | ✅ `ipv6rdIpv4MaskLength` | `...IPv6rd.InterfaceSetting.1.IPv4MaskLength` | ✅ YES | — |
| 6rd border relay | ✅ `ipv6BorderRelay` | ✅ `ipv6rdBorderRelay` | `...IPv6rd.InterfaceSetting.1.BorderRelayIPv4Addresses` | ✅ YES | — |
| 6rd border relay prefix length | ✅ `ipv6BorderRelayPrefixLength` | ❌ Not mapped | — | — | No TR-181 equivalent |

---

## Operations Comparison

| Operation | Old (JNAP) | New (USP) | USP Path | Status |
|---|---|---|---|---|
| Renew DHCPv4 lease | ✅ `renewDHCPWANLease` | ✅ `renewDhcpLease()` | `Device.DHCPv4.Client.1.Renew()` | Should work (not SSH-tested) |
| Renew DHCPv6 lease | ✅ `renewDHCPIPv6WANLease` | ✅ `renewDhcpv6Lease()` | `Device.DHCPv6.Client.1.Renew()` | Should work (not SSH-tested) |

---

## Vendor Extension Paths Discovered

Standard TR-181 paths for Gateway and DNS are non-writable on this firmware. The router exposes Linksys-specific alternatives:

| Standard Path (non-writable) | Vendor Extension (writable) | Notes |
|---|---|---|
| `Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress` | `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway` | Direct replacement |
| `Device.DNS.Client.Server.1.DNSServer` | `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers` | Comma-separated string replaces all 3 DNS paths |
| `Device.DNS.Client.Server.2.DNSServer` | (same as above) | |
| `Device.DNS.Client.Server.3.DNSServer` | (same as above) | |

These were confirmed writable via SSH (`modified_uci` includes `/etc/config/network`).

---

## Functional Status Summary

### Working (read + write)

| Feature | Notes |
|---|---|
| Read all WAN/IPv6 settings | All Get paths return correct data |
| Set MTU | `Device.IP.Interface.2.MaxMTUSize` |
| Set Static IP address | `...IPv4Address.1.IPAddress` |
| Set Subnet mask | `...IPv4Address.1.SubnetMask` |
| Set IPv6 enable/disable | `...IPv6Enable` |
| Set DHCPv6 enable/disable | `...DHCPv6.Client.1.Enable` |
| Set 6rd enable/disable | `...IPv6rd.InterfaceSetting.1.Enable` |
| Set 6rd IPv4 mask length | `...IPv6rd.InterfaceSetting.1.IPv4MaskLength` |
| Set 6rd border relay | `...IPv6rd.InterfaceSetting.1.BorderRelayIPv4Addresses` |
| Renew DHCP leases | Operate commands (not SSH-tested) |

### Broken — Needs Code Fix (path swap or Add/Delete logic)

| Feature | Root Cause | Fix |
|---|---|---|
| Set default gateway | Standard path non-writable | Swap to `X_LINKSYS_DefaultGateway` |
| Set DNS servers | Standard paths non-writable + instances missing | Swap to `X_LINKSYS_DNSServers` (comma-separated) |
| Set PPP username/password/idle | PPP instance does not exist in non-PPPoE mode | Add `Device.PPP.Interface.` before Set, Delete when leaving PPPoE |
| Set VLAN enable/ID | VLANTermination instance does not exist | Add `Device.Ethernet.VLANTermination.` before Set, Delete when disabling |
| Set LCP echo interval | YAML incorrectly marks as writable | Remove `writable: true` from YAML, drop from save |

### Broken — Needs FW Team Investigation

| Feature | Root Cause | Issue |
|---|---|---|
| Switch connection type | `AddressingType` set is a no-op (accepted but no uci change) | ISS-1 |
| Set PPPoE service name | fault 9001 even after PPP instance exists | ISS-7 |
| Set MAC clone address | `Ethernet.Link.1.MACAddress` non-writable | ISS-5 |
| Set 6rd prefix | Format validation rejects test value | ISS-9 |

### Not Implemented in New Page (feature gap vs old page)

| Feature | Old Page Implementation | Notes |
|---|---|---|
| PPTP connection type | Full form: server, username, password, behavior, static settings | No standard TR-181 mapping |
| L2TP connection type | Full form: server, username, password, behavior | No standard TR-181 mapping |
| MAC clone enable toggle | Separate JNAP action `setMACAddressCloneSettings` | Need vendor extension path |
| IPv6 WAN type selector | 8-type dropdown | New page uses individual enable flags instead |
| 6rd tunnel mode (Auto/Manual) | 3-state selector | New page only has enable/disable |
| 6rd prefix length | Separate field | No separate TR-181 parameter |
| 6rd border relay prefix length | Separate field | No TR-181 equivalent |
| Domain name (Static IP) | `staticSettings.domainName` | No standard TR-181 path |
| Bridge mode redirect handling | Save redirect URL to SharedPreferences | Not implemented |
| Bridge mode remote setting | Auto-disable remote management | Not implemented |

---

## Recommended Migration Path

### Phase 1 — Fix writable paths (no FW dependency)

1. Update `wan_settings.yaml`: swap Gateway and DNS paths to `X_LINKSYS_*` vendor extensions
2. Update `wan_settings.yaml`: remove `writable: true` from `LCPEcho`
3. Regenerate code
4. Update `UspInternetSettingsForm.fromGenerated()` to handle new DNS format (single comma-separated → 3 fields)
5. Update `UspInternetSettingsService._saveWanSettings()` to merge 3 DNS fields → comma-separated

### Phase 2 — Implement Add/Delete lifecycle

6. Add USP Add/Delete support to codegen or service layer for PPP.Interface and VLANTermination
7. In save flow: detect connection type change → Add PPP instance before setting PPP fields
8. In save flow: detect VLAN enable → Add VLANTermination instance before setting VLAN fields

### Phase 3 — Resolve with FW team

9. ISS-1: AddressingType switching mechanism
10. ISS-5: MAC clone writable path
11. ISS-7: PPPoE.ServiceName denial reason
12. ISS-9: IPv6rd prefix format specification

### Phase 4 — Feature parity (optional)

13. Bridge mode: redirect handling + remote setting disable
14. MAC clone: enable/disable toggle
15. PPTP/L2TP: evaluate vendor extension feasibility
