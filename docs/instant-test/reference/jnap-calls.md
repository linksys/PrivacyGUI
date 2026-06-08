# Reference: JNAP Calls Used

> The JNAP actions the Instant-Test feature relies on (JNAP line).

| Action | Auth | Used for |
|--------|------|----------|
| `core/GetDeviceInfo` | no | model, firmware, serial (router-info header) |
| `router/GetWANStatus` | no | WAN connection, IP, type |
| `diagnostics/GetSystemStats` | yes | uptime, CPU, memory |
| `nodes/networkconnections/GetNodesWirelessNetworkConnections` | yes | client list (mesh) — first call in poll; if it fails the poll aborts |
| `networkconnections/GetNetworkConnections` | yes | client list (fallback) |
| `router/GetDHCPClientLeases` | yes | DHCP usage |
| `devicelist/GetDevices3` | yes | device names (optional, may fail) |
| `wirelessap/GetRadioInfo3` | yes | radio config, band steering, channel IDs |
| `guestnetwork/GetGuestNetworkSettings` | yes | guest network status |
| `firmwareupdate/GetFirmwareUpdateStatus` | yes | firmware update availability |
| `nodes/diagnostics/GetBackhaulInfo` | yes | mesh backhaul |

## Notes
- Channel recommendation reads `GetRadioInfo3` for accurate radio IDs but the
  suggested channel (6 / 36) is hardcoded best-practice, NOT a scan. See [[roadmap]] B-18.
- Full catalog (184 actions) in PRODUCT_MANAGEMENT `Context/jnap-reference.md`.
- USP line uses TR-181 data-model paths instead — see [[concepts/two-line-strategy]].

## Related
- [[code-map]]
- [[concepts/verdict-engine]]

## Last Verified
2026-06-08
