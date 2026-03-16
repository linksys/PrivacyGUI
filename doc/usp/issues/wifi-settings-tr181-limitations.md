# WiFi Settings — TR-181 Limitations and Known Issues

**Date:** 2026-03-13
**Branch:** feat/usp-protocol-integration
**Related:**
- [internet-settings-fix-design.md](internet-settings-fix-design.md) — pattern for vendor extension workarounds

---

## Summary

Four limitations discovered during WiFi Settings page implementation. **ISS-2 resolved** (2026-03-16): `SupportedOperatingChannelBandwidths` standard path exists. Items 1, 3, and 4 require vendor extensions from the firmware team.

---

## ISS-1: `PossibleChannels` is not grouped by channel width

**Path:** `Device.WiFi.Radio.{i}.PossibleChannels`

TR-181 provides a flat, comma-separated list of all channels available on the radio — it does not group channels by channel width. As a result, the UI cannot automatically derive which channels are valid for a given bandwidth selection (e.g., which channels support 80 MHz vs. 160 MHz).

**SSH Verification (2026-03-16):**

| Radio | PossibleChannels | SupportedBandwidths | CurrentBandwidth |
|-------|-----------------|---------------------|------------------|
| Radio.1 (2.4 GHz) | `1-13` | `Auto,20MHz` | `20MHz` |
| Radio.2 (5 GHz) | `36,40,44,48,52,56,60,64,100-140` | `Auto,20MHz,40MHz,80MHz` | `160MHz` ⚠️ |

> **Data inconsistency:** Radio.2 reports `CurrentOperatingChannelBandwidth` = `160MHz`, but `SupportedOperatingChannelBandwidths` only lists up to `80MHz`. This firmware data contradiction needs clarification from the FW team.

Additional factors that affect channel availability at runtime:

- **Regulatory domain** — legal channels differ by country (e.g., Japan, Taiwan, and the EU each permit different channel sets).
- **DFS channels (52–144)** — require active radar detection before use in most regions. The router may dynamically exclude them depending on detected radar activity or regional restrictions.

**Impact:** The current implementation cannot build an accurate "channels available for this width" dropdown from TR-181 data alone. The flat `PossibleChannels` list (e.g., `36,40,44,48,52-64,100-140`) does not indicate which channels are valid for 40 MHz vs. 80 MHz vs. 160 MHz bonding.

**Workaround needed:** A firmware vendor extension that exposes a pre-filtered `AvailableChannels` map keyed by channel width, taking regulatory domain and DFS state into account, so the router provides the correct list directly.

---

## ISS-2: Channel width options are hardcoded — ✅ RESOLVED (2026-03-16)

**Path:** `Device.WiFi.Radio.{i}.OperatingChannelBandwidth` / `SupportedOperatingChannelBandwidths`

~~TR-181 does not define a `PossibleChannelBandwidths` equivalent to `PossibleChannels`.~~ **Update (2026-03-16):** The standard path `Device.WiFi.Radio.{i}.SupportedOperatingChannelBandwidths` exists and returns correct data:

```
Radio.1 (2.4 GHz): "Auto,20MHz"
Radio.2 (5 GHz):   "Auto,20MHz,40MHz,80MHz"   ← hardware does not support 160MHz
```

The current UI hardcodes the available options (incorrect):

| Band | Hardcoded Options | Actual Support |
|------|-------------------|----------------|
| 2.4 GHz | Auto / 20 MHz / 40 MHz | Auto / 20 MHz |
| 5 GHz / 6 GHz | Auto / 20 MHz / 40 MHz / 80 MHz / 160 MHz | Auto / 20 MHz / 40 MHz / 80 MHz |

**Fix:** Remove hardcoded options. Read `SupportedOperatingChannelBandwidths` per radio and dynamically build the dropdown. No vendor extension needed.

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

**SSH Verification (2026-03-16) — All 4 AccessPoint profiles compared:**

| Field | AP.1 (Primary 2.4G) | AP.2 (Primary 5G) | AP.3 (Guest 2.4G) | AP.4 (Guest 5G) |
|-------|---------------------|--------------------|--------------------|------------------|
| `Enable` | `true` | `true` | **`false`** | **`false`** |
| `SSIDReference` | `""` | `""` | `""` | `""` |
| `SSIDAdvertisementEnabled` | `true` | `true` | `true` | `true` |
| `IsolationEnable` | `false` | `false` | `false` | `false` |
| `MaxAllowedAssociations` | `32` | `32` | `32` | `32` |
| `X_LINKSYS_MultiAPMode` | `0` | `0` | `0` | `0` |
| `Security.ModeEnabled` | `WPA2-Personal` | `WPA2-Personal` | **`None`** | **`None`** |

**Findings:**
- **No field distinguishes guest from primary.** All structural/policy fields (`SSIDReference`, `IsolationEnable`, `MaxAllowedAssociations`, `X_LINKSYS_MultiAPMode`) are identical across all 4 APs.
- AP.3/4 can only be inferred as "guest" by convention: disabled by default + `Security.ModeEnabled = "None"`. This is unreliable — user could enable a guest AP and set security, making it indistinguishable from a primary AP.
- `SSIDReference` is empty for all APs (no cross-reference to `Device.WiFi.SSID.{i}`), so SSID-based lookup is also unavailable via this field.

**Current workaround:** Guest networks are identified by checking whether the SSID string contains `"guest"` (case-insensitive). This heuristic fails for:
- Guest networks with custom names (e.g., `"Linksys-Visitors"`)
- Primary networks that happen to include `"guest"` in the name

**Alternative heuristic considered:** AP index-based (AP.3/4 = guest). This is fragile and hardware-dependent.

**Workaround needed:** A vendor extension property on `Device.WiFi.AccessPoint.{i}` (e.g., `X_LINKSYS_NetworkType`) that explicitly marks the network role (primary / guest / iot).
