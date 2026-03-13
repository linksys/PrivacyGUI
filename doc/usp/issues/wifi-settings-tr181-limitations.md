# WiFi Settings — TR-181 Limitations and Known Issues

**Date:** 2026-03-13
**Branch:** feat/usp-protocol-integration
**Related:**
- [internet-settings-fix-design.md](internet-settings-fix-design.md) — pattern for vendor extension workarounds

---

## Summary

Four limitations discovered during WiFi Settings page implementation that cannot be fully resolved with standard TR-181 paths. Items 1 and 2 require a vendor extension from the firmware team; items 3 and 4 are descoped pending further investigation.

---

## ISS-1: `PossibleChannels` is not grouped by channel width

**Path:** `Device.WiFi.Radio.{i}.PossibleChannels`

TR-181 provides a flat, comma-separated list of all channels available on the radio — it does not group channels by channel width. As a result, the UI cannot automatically derive which channels are valid for a given bandwidth selection (e.g., which channels support 80 MHz vs. 160 MHz).

Additional factors that affect channel availability at runtime:

- **Regulatory domain** — legal channels differ by country (e.g., Japan, Taiwan, and the EU each permit different channel sets).
- **DFS channels (52–144)** — require active radar detection before use in most regions. The router may dynamically exclude them depending on detected radar activity or regional restrictions.

**Impact:** The current implementation cannot build an accurate "channels available for this width" dropdown from TR-181 data alone.

**Workaround needed:** A firmware vendor extension that exposes a pre-filtered `AvailableChannels` map keyed by channel width, taking regulatory domain and DFS state into account, so the router provides the correct list directly.

---

## ISS-2: Channel width options are hardcoded

**Path:** `Device.WiFi.Radio.{i}.OperatingChannelBandwidth` / `PossibleChannelBandwidths` (non-standard)

TR-181 does not define a `PossibleChannelBandwidths` equivalent to `PossibleChannels`. The current UI hardcodes the available options:

| Band | Options |
|------|---------|
| 2.4 GHz | Auto / 20 MHz / 40 MHz |
| 5 GHz / 6 GHz | Auto / 20 MHz / 40 MHz / 80 MHz / 160 MHz |

These options may not reflect what the actual hardware supports (e.g., a radio that does not support 160 MHz would still show it in the list).

**Workaround needed:** A vendor extension path that returns the supported bandwidths per radio, or a firmware-side filtering mechanism that rejects unsupported values with a clear fault code.

---

## ISS-3: MAC Filtering supports whitelist only — blacklist not available in TR-181

**Paths:**
- `Device.WiFi.AccessPoint.{i}.MACAddressControlEnabled`
- `Device.WiFi.AccessPoint.{i}.AllowedMACAddress`

The original JNAP MAC Filtering feature is a **deny-list** (block specific devices). TR-181 only supports an **allow-list** (`AllowedMACAddress`) — there is no standard path for a deny-list equivalent.

Enabling `MACAddressControlEnabled` with an `AllowedMACAddress` list would block all devices not on the list, which is the inverse of the expected behavior and unsafe to expose as a simple toggle.

**Current status:** MAC Filtering tab removed from the WiFi Settings page. The feature requires a vendor extension (e.g., `X_LINKSYS_DeniedMACAddress`) before it can be re-added.

---

## ISS-4: Guest network detection relies on SSID name heuristic

TR-181 does not provide a property on `Device.WiFi.Radio.{i}` or `Device.WiFi.AccessPoint.{i}` to distinguish a guest network from a primary network. The `WiFiRadio`, `WiFiAccessPoint`, and `WiFiSsid` objects have no `IsGuest` or `NetworkRole` field in the standard data model.

**Current workaround:** Guest networks are identified by checking whether the SSID string contains `"guest"` (case-insensitive). This heuristic fails for:
- Guest networks with custom names (e.g., `"Linksys-Visitors"`)
- Primary networks that happen to include `"guest"` in the name

**Workaround needed:** A vendor extension property on `Device.WiFi.AccessPoint.{i}` (e.g., `X_LINKSYS_NetworkType`) that explicitly marks the network role (primary / guest / iot).
