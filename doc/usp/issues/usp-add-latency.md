# USP Add/Set Latency — `bbf.config commit` Service Reload Bottleneck

**Environment**

| Item | Value |
|------|-------|
| Device | Linksys M60TB-EU (PINNACLE 2.0) |
| Firmware | 1.0.16.26013014 |
| usp-bridge | v0.1.1 |
| Date | 2026-03-09 |

---

## Summary

All USP Add/Set operations via the WASM client (USP protobuf path) take **~7–8 seconds** to complete. The delay is not in the bridge or protobuf processing — it is caused by `bbf.config commit`, which reloads the affected OpenWrt service (dnsmasq, firewall, netifd) after each OBUSPA transaction.

```
WASM client → bridge → OBUSPA → bbfdm
                                  │
                          CMD_ADD (< 1s)
                          CMD_GROUP_SET (< 1s)
                          CMD_TRAN_COMMIT
                                  │
                          bbf.config commit ← 7s (service reload)
                                  │
                          response returned
```

---

## Measurements

### Add Operation — ubus Direct vs OBUSPA

| Operation | ubus direct (bbfdm) | OBUSPA (USP protobuf path) | Delta |
|-----------|--------------------|-----------------------------|-------|
| DHCP Reservation | < 1s | **8s** | ~7s |
| Port Forwarding (NAT.PortMapping) | < 1s | **7s** | ~7s |
| Port Triggering (NAT.PortTrigger) | < 1s | **1s** | ~0s |
| Firewall Chain Rule | < 1s | **7s** | ~7s |
| LocalAgent Subscription | — | **< 1s** | n/a |

- **ubus direct** calls `bbfdm add` without committing — config file is modified but the service is not reloaded
- **OBUSPA** wraps each operation in a transaction (`CMD_TRAN_START` → `CMD_ADD` → `CMD_TRAN_COMMIT`), and the commit triggers `bbf.config commit` which reloads the service
- **Port Triggering** was an outlier at 1s — likely no config change was detected (empty commit)
- **LocalAgent Subscription** is managed internally by OBUSPA (no bbfdm/ubus involvement), so it completes instantly

### Isolated `bbf.config commit` Timing Per Service

| UCI Config | Service Reloaded | Commit Time |
|------------|-----------------|-------------|
| `/etc/config/dhcp` | dnsmasq | **7s** |
| `/etc/config/firewall` | firewall (iptables/nftables) | **7s** |
| `/etc/config/network` | netifd | **7s** |
| `/etc/config/wireless` | hostapd | **< 1s** |

### OBUSPA Detailed Timing (DHCP Reservation Add)

Captured via OBUSPA CLI verbose output with per-line timestamps:

```
[+0s] CMD (CMD_INSTANCES) path(Device.DHCPv4.Server.Pool.) Done
[+0s] CMD (CMD_TRAN_START) Done
[+0s] CMD (CMD_ADD) path(Device.DHCPv4.Server.Pool.1.StaticAddress.) Done
[+0s] CMD (CMD_GROUP_GET) path(Device.DHCPv4.Server.Pool.) Done
[+0s] CMD (CMD_GROUP_SET) Alias = "cpe-3" Done
[+0s] CMD (CMD_GROUP_SET) Chaddr = "" Done
[+0s] CMD (CMD_TRAN_COMMIT) num_services 2
[+7s] # ubus -t 30000ms call bbf.config@commit => {"services":["/etc/config/dhcp","/etc/bbfdm/dmmap/dmmap_dhcp"]}
[+7s] CMD (CMD_TRAN_COMMIT) Done
[+7s] Added Device.DHCPv4.Server.Pool.1.StaticAddress.3
```

All data model operations (instances, add, get, set) complete at `+0s`. The entire 7-second delay occurs at the `bbf.config commit` step.

---

## Root Cause

OBUSPA's USP transaction model requires a `bbf.config commit` at the end of each transaction. This commit call:

1. Writes the modified UCI config files (instantaneous)
2. Triggers service reload via init scripts (e.g., `/etc/init.d/dnsmasq reload`) — **this is the 7s bottleneck**

The `bbf.config` daemon uses a `ubus -t 30000ms` timeout (30s), indicating this is expected to be a slow operation.

This behavior is by design — USP requires that configuration changes take effect immediately after the transaction commits. The ubus direct path is fast because it **skips the commit**, leaving the config in a "written but not applied" state.

---

## Impact on UI

| Scenario | Perceived Latency |
|----------|------------------|
| Add single Port Forwarding rule | ~7s |
| Add single DHCP Reservation | ~8s |
| Add single Firewall Rule | ~7s |
| Add + Set multiple params (same transaction) | ~7s (single commit) |
| Add WiFi settings | < 1s |
| Read operations (GET) | < 1s |

---

## Appendix: SSH Verification Log

### B.1 ubus Direct vs OBUSPA CLI — Side by Side

```
$ ubus call bbfdm.dhcpmngr add '{"path":"Device.DHCPv4.Server.Pool.1.StaticAddress."}'
Elapsed: 0s

$ obuspa -s /tmp/usp_cli -c 'add' 'Device.DHCPv4.Server.Pool.1.StaticAddress.'
Added Device.DHCPv4.Server.Pool.1.StaticAddress.3
Elapsed: 8s
```

```
$ ubus call bbfdm.firewallmngr add '{"path":"Device.NAT.PortMapping."}'
Elapsed: 0s

$ obuspa -s /tmp/usp_cli -c 'add' 'Device.NAT.PortMapping.'
Added Device.NAT.PortMapping.5
Elapsed: 7s
```

```
$ ubus call bbfdm.firewallmngr add '{"path":"Device.Firewall.Chain.1.Rule."}'
Elapsed: 0s

$ obuspa -s /tmp/usp_cli -c 'add' 'Device.Firewall.Chain.1.Rule.'
Added Device.Firewall.Chain.1.Rule.26
Elapsed: 7s
```

### B.2 Isolated bbf.config Commit

```
$ ubus call bbf.config commit \
  '{"services":["/etc/config/dhcp","/etc/bbfdm/dmmap/dmmap_dhcp"],"proto":"usp"}'
Elapsed: 7s

$ ubus call bbf.config commit \
  '{"services":["/etc/config/firewall","/etc/bbfdm/dmmap/dmmap_firewall"],"proto":"usp"}'
Elapsed: 7s

$ ubus call bbf.config commit \
  '{"services":["/etc/config/network"],"proto":"usp"}'
Elapsed: 7s

$ ubus call bbf.config commit \
  '{"services":["/etc/config/wireless"],"proto":"usp"}'
Elapsed: 0s
```

### B.3 OBUSPA Subscription (No bbfdm, No Commit)

```
$ obuspa -s /tmp/usp_cli -c 'add' 'Device.LocalAgent.Subscription.'
Added Device.LocalAgent.Subscription.1
Elapsed: 0s
```
