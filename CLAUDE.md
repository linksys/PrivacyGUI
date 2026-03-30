# WiFi Troubleshooter

## What This Is

Customer-facing WiFi diagnostic tool. Targets end customers and Linksys support agents.

**Not** an engineering tool. No SSH. No serial. No router admin credentials. No TR standards.

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

## Open Questions

See bottom of `Plans/architecture.md`.
