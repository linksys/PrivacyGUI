# Linksys Vendor Parameters (X_LINKSYS_)

> **Router**: Linksys M60-EU (PINNACLE 2.0)
> **Firmware**: 1.0.14.26013014 (initial), OpenWrt 23.05-SNAPSHOT r0-9033d84 (re-validated)
> **Platform**: OpenWrt 23.05-SNAPSHOT (BusyBox 1.36.1)
> **Date**: 2026-03-10 (initial), 2026-03-19 (re-validated on FW build 2026-03-18)
> **BBF Vendor Prefix**: `X_LINKSYS_`

This document catalogs all `X_LINKSYS_` vendor-extended TR-181 parameters discovered on the router via `obuspa` runtime queries and `bbfdm` microservice binary inspection.

---

## 1. Device.DeviceInfo

### Scalar Parameters

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.DeviceInfo.X_LINKSYS_BaseMACAddress` | string | `74:12:13:21:55:56` | R | Base MAC address of the device |

### Device.DeviceInfo.ProcessStatus

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.DeviceInfo.ProcessStatus.X_LINKSYS_ProcessSupportedSortingMethods` | string | `PID,Memory,CPU_Time` | R | Supported process sorting methods |
| `Device.DeviceInfo.ProcessStatus.X_LINKSYS_ProcessCurrentSortingMethod` | string | `Memory` | R/W | Current process sorting method |
| `Device.DeviceInfo.ProcessStatus.X_LINKSYS_MaxProcessEntries` | unsignedInt | `50` | R/W | Maximum number of process entries returned |

### Device.DeviceInfo.NetworkProperties

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.DeviceInfo.NetworkProperties.X_LINKSYS_MaxConnections` | unsignedInt | `65535` | R | Maximum NAT/conntrack connections |
| `Device.DeviceInfo.NetworkProperties.X_LINKSYS_ActiveConnections` | unsignedInt | `280` | R | Current active NAT/conntrack connections |

### Device.DeviceInfo.X_LINKSYS_FileDescriptors (vendor object)

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.DeviceInfo.X_LINKSYS_FileDescriptors.Used` | unsignedInt | `1088` | R | Currently used file descriptors |
| `Device.DeviceInfo.X_LINKSYS_FileDescriptors.MaxAllowed` | unsignedInt | `42117` | R | Maximum allowed file descriptors |

---

## 2. Device.IP.Interface.{i}.IPv4Address.{i}

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.IP.Interface.{i}.IPv4Address.{i}.X_LINKSYS_DefaultGateway` | string | _(empty)_ | **R/W** | Default gateway for this interface |
| `Device.IP.Interface.{i}.IPv4Address.{i}.X_LINKSYS_DNSServers` | string | _(empty)_ | **R/W** | DNS servers for this interface (comma-separated) |

**Observed instances**: Interface.1.IPv4Address.1, Interface.2.IPv4Address.1

> **Re-validation (2026-03-19, FW build 2026-03-18):** Both paths confirmed **writable** via SSH `ubus call bbfdm set`. Set returns `data: "1"` and modifies `/etc/config/network`. The original 2026-03-10 catalog incorrectly marked these as R (read-only); corrected to R/W based on live testing. DNS accepts comma-separated format (e.g., `"8.8.8.8,8.8.4.4"`).

---

## 3. Device.WiFi.AccessPoint.{i}

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.WiFi.AccessPoint.{i}.X_LINKSYS_MultiAPMode` | unsignedInt | `0` | R/W | Multi-AP/EasyMesh mode for this access point |

**Observed instances**: AccessPoint.1 through AccessPoint.4

---

## 4. Device.Bridging.Bridge.{i}

### Bridge-level

| Path | Type | Sample Value | R/W | Source |
|------|------|-------------|-----|--------|
| `Device.Bridging.Bridge.{i}.X_LINKSYS_VLANFiltering` | boolean | `0` | R/W | JSON plugin: `11VLAN_Filtering_Extension.json` |

### Bridge Port-level

| Path | Type | Sample Value | R/W | Source |
|------|------|-------------|-----|--------|
| `Device.Bridging.Bridge.{i}.Port.{i}.X_LINKSYS_EgressPriorityRegeneration` | string | _(empty)_ | R/W | Binary: `10libbridgeext.so` |

**Observed Bridge instances**: Bridge.1, Bridge.2, Bridge.3 (each with Port.1, Port.2)

---

## 5. Device.Ethernet

### Device.Ethernet.X_LINKSYS_MACVLAN (vendor object)

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.Ethernet.X_LINKSYS_MACVLANNumberOfEntries` | unsignedInt | `0` | R | Number of MAC VLAN entries |

Multi-instance table `Device.Ethernet.X_LINKSYS_MACVLAN.{i}.` — no instances were present at query time.

---

## 6. Device.Time

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.Time.X_LINKSYS_LocalTimeZoneName` | string | _(empty)_ | R/W | Human-readable local timezone name |

### Device.Time.X_LINKSYS_SupportedZones (vendor multi-instance object)

Multi-instance table `Device.Time.X_LINKSYS_SupportedZones.{i}.` — defined in `00libtimeext.so`, no instances populated at query time.

---

## 7. Device.LocalAgent

### Device.LocalAgent.X_LINKSYS_Session (vendor object)

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.LocalAgent.X_LINKSYS_Session.State` | unsignedInt | `0` | R | Current USP session state |
| `Device.LocalAgent.X_LINKSYS_Session.RemainingTime` | unsignedInt | `0` | R | Remaining session time (seconds) |
| `Device.LocalAgent.X_LINKSYS_Session.Controller` | string | _(empty)_ | R | Active session controller endpoint ID |

---

## 8. Device.X_LINKSYS_TRUSTDOMAIN (top-level vendor object)

Manages trusted IP addresses for management access.

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.X_LINKSYS_TRUSTDOMAIN.IPv4AddressNumberOfEntries` | unsignedInt | `5` | R | Number of trusted IPv4 addresses |

### Device.X_LINKSYS_TRUSTDOMAIN.IPv4Address.{i}

| Path | Type | Sample Value | R/W | Description |
|------|------|-------------|-----|-------------|
| `Device.X_LINKSYS_TRUSTDOMAIN.IPv4Address.{i}.Alias` | string | `cpe-1` | R/W | Alias |
| `Device.X_LINKSYS_TRUSTDOMAIN.IPv4Address.{i}.Enable` | boolean | `1` | R/W | Enable/disable this entry |
| `Device.X_LINKSYS_TRUSTDOMAIN.IPv4Address.{i}.IPAddress` | string | `188.215.74.72` | R/W | Trusted IPv4 address |
| `Device.X_LINKSYS_TRUSTDOMAIN.IPv4Address.{i}.SubnetMask` | string | `255.255.255.255` | R/W | Subnet mask |

**Observed instances**: 5 entries

---

## 9. Device.ManagementServer (CWMP/TR-069)

| Path | Type | Sample Value | R/W | Source |
|------|------|-------------|-----|--------|
| `Device.ManagementServer.X_LINKSYS_AllowedConnectionRequestIP` | string | — | R/W | Binary: `icwmp.so` |

**Note**: Not returned at runtime query (may require CWMP protocol context).

---

## Summary Table — All X_LINKSYS Parameters by Source Module

| bbfdm Module | Parameters |
|-------------|-----------|
| **core.so** | `BBF_VENDOR_PREFIX = "X_LINKSYS_"` (global vendor prefix definition) |
| **netmngr.so** | `Device.IP.Interface.{i}.IPv4Address.{i}.X_LINKSYS_DefaultGateway`, `...X_LINKSYS_DNSServers`, `Device.Ethernet.X_LINKSYS_MACVLAN.{i}.` |
| **hostmngr.so** | `Device.Hosts.X_LINKSYS_Host.{i}.` (internal host table extension — function symbols only) |
| **icwmp.so** | `Device.ManagementServer.X_LINKSYS_AllowedConnectionRequestIP` |
| **bridgemngr** | `Device.Bridging.Bridge.{i}.X_LINKSYS_VLANFiltering`, `...Port.{i}.X_LINKSYS_EgressPriorityRegeneration` |
| **timemngr** | `Device.Time.X_LINKSYS_LocalTimeZoneName`, `Device.Time.X_LINKSYS_SupportedZones.{i}.` |
| **trustdomainmngr.so** | `Device.X_LINKSYS_TRUSTDOMAIN.IPv4Address.{i}.` |
| **obuspa.so** (runtime) | `Device.LocalAgent.X_LINKSYS_Session.*` |
| _(built-in)_ | `Device.DeviceInfo.X_LINKSYS_BaseMACAddress`, `...ProcessStatus.X_LINKSYS_*`, `...NetworkProperties.X_LINKSYS_*`, `...X_LINKSYS_FileDescriptors.*` |
| _(built-in)_ | `Device.WiFi.AccessPoint.{i}.X_LINKSYS_MultiAPMode` |

---

## Notes

1. Parameters marked as _(empty)_ had no value at query time — they may be populated under different network configurations (e.g., WAN with static IP or PPPoE).
2. `hostmngr.so` contains function symbols referencing `X_LINKSYS_Hosts_Host` but these did not appear as runtime-queryable parameters via `obuspa`. They may be internal-only or require a different protocol context.
3. Several guessed top-level vendor paths (`X_LINKSYS_MCS`, `X_LINKSYS_SSIDSTEERING`, `X_LINKSYS_OPENVPN`, `X_LINKSYS_PORTTRIGGER`, `X_LINKSYS_GATEWAY`, `X_LINKSYS_DBON`, `X_LINKSYS_CBT`, `X_LINKSYS_MACSEC`, `X_LINKSYS_LIFEMOTE`, `X_LINKSYS_MWAN`) returned `Path is invalid` — these features either don't exist on this firmware version or are accessible through different naming conventions.
4. Total unique vendor parameter paths found: **~25 leaf parameters** across **8 distinct object groups**.
