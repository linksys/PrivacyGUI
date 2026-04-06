# Instant-Help (formerly WiFi Troubleshooter)

## What This Is

Customer-facing WiFi diagnostic tool branded **Instant-Help**. Two modes:
1. **Customer self-help** — unauthenticated, runs browser-based speed/gateway/DNS tests
2. **Support agent dashboard** — authenticated via router admin, pulls JNAP data for deep diagnostics

Built as a new route (`/troubleshoot`) inside the existing `linksys/PrivacyGUI` Flutter Web app at `http://192.168.1.1`.

**Not** an engineering tool. No SSH. No serial. No TR standards.

## What This Is Not

See `Firmware_Inspector/` for the internal engineering QA tool (SSH/serial device access, TR-181 assessment, firmware diffing). That tool and this one share nothing except the same product line.

## Target Audiences

1. **End customers** — frustrated at home, internet is slow or broken
2. **Linksys support agents** — using customer-generated diagnostic reports to triage calls

## Architecture

Full architecture plan: `Plans/architecture.md`

### Tiered Delivery (most important concept)

| Tier | Delivery | Install Required | Works When WiFi Down? |
|------|----------|-----------------|----------------------|
| **0** | SMS link → cellular web | None | Yes |
| **1** | `http://192.168.1.1/troubleshoot` (router embed) | None | LAN only |
| **2** | Progressive Web App | Browser prompt | No |
| **3** | Native app (Flutter) | App Store/Play Store | No |

**Phase 1: Tiers 0 + 1. Phase 2: Tier 3 (native).**

### Tech Stack

- **All tiers:** Flutter (Web for Tiers 0-2, native for Tier 3)
- The router already ships Flutter Web (`privacy_gui` on lighttpd at `http://192.168.1.1`)
- Same diagnostic Dart package compiles to web and native

### Project Layout

```
WiFi_Troubleshooter/
├── CLAUDE.md              # This file
├── Plans/
│   └── architecture.md    # Full architecture decision document
├── Context/               # Decisions, backlog, open questions
├── lib/
│   ├── diagnostics/       # Platform-agnostic diagnostic logic (Dart)
│   └── ui/                # Flutter UI widgets
├── web/                   # Flutter Web build output
├── android/               # Flutter Android target
├── ios/                   # Flutter iOS target
├── macos/                 # Flutter macOS target
└── windows/               # Flutter Windows target
```

## Core Customer Pain Points (scope boundary)

1. Slow internet
2. Slow device (others fine)
3. Connectivity drops
4. Can't add / connect new device
5. WiFi dead spots / weak signal
6. Router appears offline / rebooting

**Out of scope permanently:** packet capture, SSH/router admin access, TR standards, ISP internal systems.

## Platform API Reality

iOS cannot deliver channel scan or BSSID data (Apple entitlement denied). iOS is a reduced-scope product by design — never show empty "advanced" panels for features the platform won't permit.

See `Plans/architecture.md` → "Per-Platform Diagnostic Capability Reality" for the full matrix.

## Privacy

Every field collected is enumerated in `Plans/architecture.md` → "Data & Privacy Model". MAC addresses, IPs, and SSIDs are GDPR PII. Session-only unless user explicitly shares a report.

## Implementation Status

Code lives in `~/Projects/PrivacyGUI/lib/page/cs_diagnostic/`. Key paths:

| Component | Path |
|-----------|------|
| JNAP service | `services/jnap_diagnostic_service.dart` |
| Browser diagnostics | `services/browser_diagnostic_service.dart` |
| Mock data | `services/mock_diagnostic_data.dart` |
| State + provider | `providers/cs_diagnostic_state.dart`, `cs_diagnostic_provider.dart` |
| Agent dashboard | `views/agent/agent_dashboard_view.dart` |
| Flow analysis (6 tabs) | `views/agent/flow_analysis_view.dart` |
| Customer home | `views/customer/customer_home_view.dart` |
| Client model + OUI | `models/diagnostic_client.dart` |
| Route registration | `lib/route/router_provider.dart` (bypass redirect for `/troubleshoot`) |

### JNAP Calls Used
- `core/GetDeviceInfo` (no auth) — model, firmware, serial
- `router/GetWANStatus` (no auth) — WAN connection, IP
- `diagnostics/GetSystemStats` — uptime, CPU, memory
- `networkconnections/GetNetworkConnections` — client list (fallback)
- `nodes/networkconnections/GetNodesWirelessNetworkConnections` — client list (mesh, primary)
- `router/GetDHCPClientLeases` — DHCP usage
- `devicelist/GetDevices3` — device names (may fail, optional)
- `wirelessap/GetRadioInfo3` — radio config, band steering
- `guestnetwork/GetGuestNetworkSettings` — guest network status
- `firmwareupdate/GetFirmwareUpdateStatus` — firmware update availability
- `nodes/diagnostics/GetBackhaulInfo` — mesh backhaul info

### Dev Testing
```bash
# From PrivacyGUI repo:
~/.pub-cache/bin/fvm flutter run -d web-server --web-port 8080

# CORS-disabled Chrome (must quit Chrome first):
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --disable-web-security --user-data-dir=/tmp/chrome-cors-dev \
  http://localhost:8080/#/troubleshoot
```

## Open Questions

See bottom of `Plans/architecture.md`.
