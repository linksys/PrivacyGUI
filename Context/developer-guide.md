# Instant-Help Developer Guide

Onboarding guide for developing the Instant-Help (CS Diagnostic) feature inside PrivacyGUI.

---

## What You're Working On

Instant-Help is a WiFi diagnostic tool embedded at `http://192.168.1.1/#/troubleshoot` on Linksys Pinnacle routers. It has two modes:

- **Customer mode** — no authentication, browser-based tests (gateway ping, DNS check, speed test), plain-language verdicts
- **Agent mode** — authenticated with router admin password, pulls live JNAP data, shows signal tables, flow analysis, radio config, device details

The feature lives inside the existing **PrivacyGUI** Flutter Web app (not a separate project). The router already serves Flutter Web on lighttpd.

---

## Repository & Branch

| Item | Value |
|------|-------|
| Repo | `linksys/PrivacyGUI` |
| Feature branch | `feature/wifi-troubleshooter` |
| Base branch | `dev-1.2.9` |
| Route | `/#/troubleshoot` |

Clone and set up:
```bash
git clone git@github.com:linksys/PrivacyGUI.git
cd PrivacyGUI
git checkout feature/wifi-troubleshooter
```

---

## Local Development

### Prerequisites

- **FVM** (Flutter Version Manager): `dart pub global activate fvm`
- **Flutter SDK** (managed by FVM): `fvm install` in repo root
- **Fortinet VPN** for Jenkins access and router SSH

### Run Locally

```bash
# Start Flutter dev server
~/.pub-cache/bin/fvm flutter run -d web-server --web-port 8080

# In another terminal — CORS-disabled Chrome (quit Chrome first!)
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --disable-web-security --user-data-dir=/tmp/chrome-cors-dev \
  http://localhost:8080/#/troubleshoot
```

CORS-disabled Chrome is required because the app makes cross-origin requests to `192.168.1.1` (JNAP) and external URLs (DNS checks). The router's self-signed cert also causes issues in normal browsers.

### Run Tests

```bash
cd ~/Projects/PrivacyGUI
~/.pub-cache/bin/fvm flutter test test/page/cs_diagnostic/
```

Test files:
- `test/page/cs_diagnostic/models/diagnostic_client_test.dart` — 22 tests
- `test/page/cs_diagnostic/providers/cs_diagnostic_state_test.dart` — 41 tests
- `test/page/cs_diagnostic/services/mock_diagnostic_data_test.dart` — 19 tests

---

## Code Structure

All Instant-Help code lives under `lib/page/cs_diagnostic/`:

```
lib/page/cs_diagnostic/
├── _cs_diagnostic.dart                    # Barrel file (exports)
├── models/
│   └── diagnostic_client.dart             # DiagnosticClient model, OUI lookup, signal strength
├── providers/
│   ├── cs_diagnostic_auth_provider.dart   # Auth state for agent login
│   ├── cs_diagnostic_provider.dart        # Main provider — parses JNAP into diagnostic state
│   └── cs_diagnostic_state.dart           # CsDiagnosticState — all computed getters
├── services/
│   ├── browser_diagnostic_service.dart    # Browser-based tests (gateway ping, DNS, speed)
│   └── mock_diagnostic_data.dart          # Factory data for testing without a router
└── views/
    ├── diagnostic_entry_view.dart         # Entry point — routes to customer or agent
    ├── customer/
    │   ├── customer_home_view.dart         # Unauthenticated landing page
    │   ├── flow_slow_internet_view.dart    # "Slow internet" troubleshooting flow
    │   ├── flow_slow_device_view.dart      # "One device is slow" flow
    │   └── flow_cant_connect_view.dart     # "Can't connect" flow
    └── agent/
        ├── agent_login_view.dart           # Admin password entry
        ├── agent_dashboard_view.dart       # Main agent dashboard (radio, WAN, alerts)
        ├── flow_analysis_view.dart         # 6-tab flow analysis with findings
        ├── signal_table_view.dart          # Connected devices table (signal, TX/RX)
        ├── router_info_card.dart           # Router model/firmware info card
        ├── health_bar_widget.dart          # Visual health indicator
        ├── callback_risk_widget.dart       # Callback risk assessment
        └── report_summary_view.dart        # Exportable diagnostic report
```

### Key Files to Understand

1. **`cs_diagnostic_provider.dart`** — The brain. Parses raw JNAP responses into `CsDiagnosticState`. Merges data from multiple JNAP calls (GetDevices, GetNodesWirelessNetworkConnections, GetNetworkConnections) to build the full client picture.

2. **`cs_diagnostic_state.dart`** — Immutable state class with computed getters for everything the UI needs: `wanConnected`, `flaggedClients`, `complexityScore`, `bandSteeringEnabled`, etc.

3. **`diagnostic_client.dart`** — Per-device model. Includes OUI manufacturer lookup (first 3 octets of MAC), signal strength classification, and flagging logic (weak signal + slow TX = flagged).

4. **`browser_diagnostic_service.dart`** — Runs in the customer's browser without authentication. Gateway ping uses HTTPS to detect TLS rejection (fast error = reachable). DNS check uses Cloudflare `1.1.1.1/cdn-cgi/trace` with Google `generate_204` fallback.

5. **`agent_dashboard_view.dart`** — The agent's main view. Shows radio config (with actual channel when auto-select), WAN status, alert banners, and navigation to signal table and flow analysis.

### Route Registration

The `/troubleshoot` route is registered in `lib/route/router_provider.dart` with a redirect bypass so unauthenticated users aren't bounced to the login page.

---

## JNAP API

JNAP (JSON Network Access Protocol) is the router's internal API at `POST http://192.168.1.1/JNAP/`.

### Calls Used by Instant-Help

| Action | Auth Required | What It Returns |
|--------|--------------|-----------------|
| `core/GetDeviceInfo` | No | Model, firmware version, serial number |
| `router/GetWANStatus` | No | WAN connection status, IP |
| `nodes/networkconnections/GetNodesWirelessNetworkConnections` | Yes | Wireless clients with signal strength (mesh) |
| `networkconnections/GetNetworkConnections` | Yes | All connected clients (fallback, includes wired) |
| `devicelist/GetDevices3` | Yes | Device names, `wirelessConnectionInfo` (TX/RX in Kbps) |
| `wirelessap/GetRadioInfo3` | Yes | Radio bands, channels, band steering |
| `wirelessap/GetSelectedChannels` | Yes | Actual operating channels (vs configured) |
| `diagnostics/GetSystemStats` | Yes | Uptime, CPU, memory |
| `router/GetDHCPClientLeases` | Yes | DHCP pool usage |
| `guestnetwork/GetGuestNetworkSettings` | Yes | Guest network status |
| `firmwareupdate/GetFirmwareUpdateStatus` | Yes | Firmware update availability |
| `nodes/diagnostics/GetBackhaulInfo` | Yes | Mesh backhaul info (Master mode only) |

### Auth Pattern

Agent mode uses `X-JNAP-Authorization: Basic admin:PASSWORD` (same as `debug.html`). The password is held in memory for the session only, never persisted.

### Data Merging Gotcha

No single JNAP call returns all device data. The provider merges:
- **NodesWirelessNetworkConnections** → signal strength, band, BSSID (wireless clients only)
- **GetDevices3** → TX/RX rates (in Kbps, convert to Mbps), device names
- **GetNetworkConnections** → wired clients, IP addresses, MAC addresses

If a field is missing from one source, fallback to another. See `_buildDeviceMap()` and `_parseClients()` in `cs_diagnostic_provider.dart`.

---

## Build & Deploy

Full details: `Context/build-and-deploy.md`

### Quick Reference: End-to-End Build Pipeline

```
Code change → Push branch → GUI build (jenkins-cloud) → Firmware build (jenkins-fw) → Flash router
```

1. **Push** your branch to `linksys/PrivacyGUI`
2. **GUI build** — trigger `private-gui-olympus` on jenkins-cloud with your branch
3. **Firmware build** — trigger `fw.linksyswrt.build.ui.dev` on jenkins-fw with `UI_BUILD_NU` = your GUI build number
4. **Flash** — download firmware image, flash to router via TFTP or web UI

### Quick Deploy (Dev Only)

For rapid iteration, skip Jenkins and SCP directly:

```bash
cd ~/Projects/PrivacyGUI
~/.pub-cache/bin/fvm flutter build web
scp -r build/web/* root@192.168.1.1:/www/
```

---

## Polling Provider & Login Loop

The main app's `polling_provider.dart` polls JNAP periodically via a batched Transaction call. **Any single JNAP call failure aborts ALL subsequent calls in the transaction.** If the poll fails, the app immediately force-logs out (production behavior — do not change this).

### Clean Flash Login Loop (Critical Dev Gotcha)

After `sysupgrade -n` (clean flash), the device has no config and `devicedb` is not running. `GetNodesWirelessNetworkConnections` is the **first** call in the polling transaction and depends on `devicedb`. When it fails, every other call in the transaction aborts, the poll returns zero data, and the app logs out — creating a login loop.

**Fix:** Complete the setup wizard after any clean flash. The wizard initializes `devicedb` and other services. Alternatively, reboot the device.

**Do NOT** modify `polling_provider.dart` to work around this. The production logout-on-first-failure behavior is intentional. The issue only occurs during dev after a clean flash without completing setup — customers always go through the wizard.

### Diagnosing JNAP Transaction Failures

```bash
# Test the full polling transaction from CLI:
AUTH=$(echo -n "admin:PASSWORD" | base64)
curl -sk -X POST "https://192.168.1.1/JNAP/" \
  -H "X-JNAP-Action: http://linksys.com/jnap/core/Transaction" \
  -H "X-JNAP-Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '[{"action":"http://linksys.com/jnap/core/GetDeviceInfo","request":{}}]' | python3 -m json.tool

# Check if devicedb is running:
ssh root@192.168.1.1 "ps | grep devicedb"
```

---

## Known Limitations

1. **Speed test is a placeholder** — returns mock data. Real integration requires either LibreSpeed server or firmware `/localtest_blob` endpoint. Ookla and SamKnows are options but require licensing/provisioning.

2. **iOS cannot provide channel scan or BSSID** — Apple denies the required entitlement. iOS is reduced-scope by design. Never show empty advanced panels for features the platform won't permit.

3. **CORS in browser** — The app runs on `192.168.1.1` with a self-signed cert. Cross-origin requests to external URLs (DNS checks, speed tests) require careful handling. The browser diagnostic service treats fast TLS rejections as "reachable" (TCP connected, TLS rejected = gateway is up).

4. **Flash space** — `/www/` ROM partition on M60CF is at 100% capacity. The feature must fit within the existing PrivacyGUI bundle size. No room for a separate app.

---

## Contacts

| Role | Person | Context |
|------|--------|---------|
| Project lead | Deven Ducommun | Architecture, requirements, priorities |
| Firmware build | Jianrong | Jenkins firmware build process, manual build steps |
| Jenkins admin | Reza Rahimi | Created firmware Jenkins jobs, can grant permissions |
| PrivacyGUI dev | Austin | PrivacyGUI branching, development patterns, code review |
| Firmware team | (various) | JNAP API questions, flash space, new JNAP actions |

---

## Roadmap

- **MAC Address Device Lookup** — Agent inputs a MAC, system searches logs for connection events
- **Real Speed Test** — LibreSpeed or Ookla integration for actual throughput measurement
- **Diagnostic PIN Auth** — Replace admin password with temporary read-only PIN (firmware change required)
- **Report Export** — Generate shareable diagnostic report (PDF or link)
- **Trend Data** — Historical signal/speed data over time (requires firmware storage)
