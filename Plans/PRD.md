# WiFi Troubleshooter — Product Requirements Document

**Version:** 2.0
**Date:** 2026-03-30
**Status:** Draft — Under Review

---

## 1. Overview

WiFi Troubleshooter is a Flutter Web app embedded directly in the Linksys router, accessible at `http://192.168.1.1/troubleshoot`. It has two modes: an unauthenticated customer mode for self-service diagnostics, and an authenticated support agent mode that unlocks richer diagnostics by calling the router's existing JNAP API. No app installation is required. No backend or cloud infrastructure is needed.

---

## 2. Problem

### Customer Pain

Home network problems are common, frustrating, and hard for non-technical users to diagnose. When something goes wrong, customers have no structured way to determine whether the problem is their ISP, their router, or a specific device. They call support, give up, or blame the router unfairly.

The six most common issues customers contact support about:

1. Internet feels slow
2. One device is slow while others are fine
3. Connection drops intermittently
4. A new device won't connect
5. Weak or no signal in part of the home
6. Router appears offline or keeps rebooting

### Business Impact

- **Support cost:** Tier 1 agents walk customers through basic diagnostics that a tool could handle automatically. Each deflected call reduces cost.
- **Misattribution:** Customers blame the router for ISP problems and vice versa — incorrect RMAs, unnecessary truck rolls, customer frustration.
- **Churn:** Customers who can't self-resolve leave or return hardware. A fast, accurate diagnostic reduces that risk.
- **Agent efficiency:** Support agents currently have no direct visibility into the customer's router state during a call. The support agent mode gives them real data — connected devices, signal per client, WAN state — without asking the customer to read back technical output.

---

## 3. Goals

### Primary Goals

- Give customers a fast, plain-language answer to "what is wrong with my network" without a support call.
- Give support agents direct visibility into the customer's network state during a call — not customer-described symptoms.
- Correctly attribute the source of a problem: ISP upstream, home network/router, or a specific device.

### Success Metrics — MVP

| Metric | Target |
|--------|--------|
| Time to first result (customer mode) | Under 60 seconds from tool open |
| User completion rate | >60% of sessions reach a verdict screen |
| Blame attribution accuracy | >70% match vs. human agent assessment |
| Tier 1 call deflection | Measurable reduction after launch (baseline established 30 days pre-launch) |
| Agent time-to-triage | Reduction in time from call start to root cause identification |

---

## 4. Non-Goals

The following are explicitly out of scope. These are not deferred — they are not part of this product.

| Out of Scope | Reason |
|---|---|
| Packet capture or deep traffic inspection | OS-level privileges required; privacy risk; not needed for top 6 complaints |
| SSH or serial console access | Engineering tool boundary; production firmware does not expose SSH |
| TR-069 / TR-369 standards integration | Handled by a separate internal tool; not customer-facing |
| ISP internal system access | Outside Linksys control |
| Backend data storage or report servers | No cloud infrastructure in this product |
| Native mobile or desktop app | Not needed — router embed serves all devices via browser |
| App store distribution | No native app; nothing to distribute via stores |
| Report sharing (Phase 1) | Deferred to Phase 2 |

---

## 5. Users

### End Customer

- **Who:** A home network user experiencing a connectivity problem.
- **Context:** At home, on a device connected (or trying to connect) to the network. Not technical. May be frustrated.
- **Entry point:** Support agent directs them to `http://192.168.1.1/troubleshoot` during a call, or they find it via a support article.
- **What they need:** A clear verdict and one plain-language next step. No technical output, no raw metrics.

### Support Agent

- **Who:** A Tier 1 support agent handling an inbound call or chat.
- **Context:** On a call, needs to triage quickly. Currently relies on the customer reading back symptoms.
- **Entry point:** Directs the customer to navigate to the URL, then asks the customer to tap "Support Login" and enter the router admin password.
- **What they need:** Real network data — connected devices, per-client signal strength, DHCP table, WAN status — not customer-interpreted symptoms.

---

## 6. Delivery & Access

### The URL

```
http://192.168.1.1/troubleshoot
```

This is a Flutter Web app served by the router's existing lighttpd web server from `/www/troubleshoot/`. It is not linked from the main router admin UI — it is a direct URL, following the same pattern as existing hidden pages (`/debug.html`, `/cpehelp.html`) already shipping on this device.

No installation required. Works on any device with a browser connected to the home network.

### Customer Mode (Unauthenticated)

- No login
- Available to anyone on the LAN
- Browser-level diagnostics: speed test, DNS, gateway reachability, latency/jitter
- Plain-language verdicts only — no raw data exposed
- Covers Flows 1, 2, and 4 (Slow Internet, Slow Device, Can't Connect)

### Support Agent Mode (Authenticated)

- Login via router admin password — same JNAP authentication (`X-JNAP-Authorization: Basic admin:PASSWORD`) used by existing router pages
- Unlocks JNAP API access: the router's own data is called directly, same-origin, no proxy needed
- All 6 diagnostic flows available
- Shows structured diagnostic data alongside plain-language verdicts
- Per-client WiFi stats, DHCP lease table, WAN state, router uptime visible to agent

**Precedent:** This two-tier pattern already exists on this device. `/cpehelp.html` checks access level before rendering. `/debug.html` uses JNAP auth for privileged operations. This is not new infrastructure — it is the same pattern, applied to a new tool.

### Hosted Web (Customer Mode Only)

A hosted version of the Flutter Web build is deployed to a Linksys CDN support URL for customers who navigate there from a support article before the router embed is available in their firmware version. This version has browser-only capabilities — no JNAP access, since it is not served from the router. Customer mode only.

---

## 7. Diagnostic Flows

Each flow produces a verdict: a plain-language conclusion and one recommended action.

In customer mode, the verdict is the only output. In support agent mode, the structured data behind the verdict is also visible.

---

### Flow 1: Slow Internet

**Customer entry:** "My internet feels slow."

**Customer mode inputs:** LibreSpeed test (download, upload, latency, jitter), DNS resolution test, gateway ping, optional user-entered plan speed.

**Support agent additional inputs (JNAP):** WAN connection status, WAN throughput from router perspective, gateway error counts.

| Condition | Verdict |
|---|---|
| Speed test fails entirely | ISP connectivity issue suspected |
| Speed well below plan; gateway healthy | ISP degradation or plan under-delivery |
| Latency/jitter high; speed normal | Congestion or ISP routing issue |
| DNS failures | DNS misconfiguration or ISP DNS issue |
| All metrics normal | Device-specific — refer to Flow 2 |

---

### Flow 2: Slow Device (Others Fine)

**Customer entry:** "One device is slow, but other devices seem fine."

**Customer mode inputs:** LibreSpeed on affected device, gateway reachability, user confirmation others are normal.

**Support agent additional inputs (JNAP):** Per-client RSSI and band for the affected device vs. others, which band the affected device is associated on, client TX/RX rates.

| Condition | Verdict |
|---|---|
| Affected device speed poor; others fine | Device-specific issue (signal, band, background processes) |
| Affected device on 2.4 GHz; others on 5/6 GHz | Band steering or manual band recommendation |
| Affected device RSSI significantly lower (JNAP) | Device too far from router |
| Gateway unreachable on affected device | IP conflict or adapter issue |

---

### Flow 3: Connectivity Drops

**Customer entry:** "My connection keeps dropping."

**Customer mode:** Gateway ping monitor for 2 minutes. Honest disclosure if no drop observed: "No drops detected in 2 minutes — your agent can see more detail."

**Support agent (JNAP):** DHCP lease table — check lease validity and expiry. Client association history if available. WAN error counts and reconnection events. Band steering config — detect if aggressive steering is causing drops.

| Condition | Verdict |
|---|---|
| DHCP lease near expiry or invalid | DHCP renewal issue |
| WAN reconnection events in log | ISP line instability |
| Client repeatedly re-associating | Band steering or driver issue on device |
| No drops observed, all metrics clean | Intermittent — may require monitoring over time |

---

### Flow 4: Can't Connect a New Device

**Customer entry:** "I can't get a new device to connect."

**Customer mode inputs:** Other devices connect (yes/no), device type, SSID being joined, network reachability from tool device.

**Support agent additional inputs (JNAP):** DHCP pool utilization (leases issued vs. total), security mode per SSID (WPA2/WPA3), band steering config, active SSID list including hidden SSIDs.

| Condition | Verdict |
|---|---|
| DHCP pool full (JNAP) | Too many devices; DHCP limit reached |
| WPA3-only; device is older | WPA3 incompatibility; guided fix |
| 6 GHz-only band steering; older device | Device cannot see 6 GHz; guided fix |
| All healthy; new device issue | Device-specific config steps by type |

---

### Flow 5: Dead Spots / Weak Signal

**Customer entry:** "My WiFi signal is weak in part of my home."

**Customer mode:** Basic — can only report signal at current device location. Guidance on router placement and mesh nodes.

**Support agent (JNAP):** Per-client RSSI table — see every connected device's signal strength. Identify which devices have poor signal. Band breakdown — clients stuck on 2.4 GHz where 5/6 GHz is available.

| Condition | Verdict |
|---|---|
| Multiple devices showing low RSSI (JNAP) | Router placement or coverage gap — recommend mesh |
| One device low; others normal | Device-specific; move device or switch band |
| All devices on 2.4 GHz | Band steering issue or device compatibility |

---

### Flow 6: Router Offline / Rebooting

**Customer entry:** "My router seems offline or keeps restarting."

**Customer mode:** Gateway reachability test. If unreachable: "Check power and lights." If reachable but internet down: ISP issue with evidence.

**Support agent (JNAP):** Router uptime, WAN status, error log summary, firmware version, CPU/memory health if available via JNAP.

| Condition | Verdict |
|---|---|
| Gateway unreachable | Hardware/power issue — physical check required |
| Gateway reachable; WAN down | ISP issue — provide evidence for ISP contact |
| Uptime very short (JNAP) | Router is rebooting — check firmware version |
| WAN error count high (JNAP) | Line instability or ISP provisioning issue |

---

## 8. Tech Stack

### Flutter Web

Single Flutter codebase. The same Dart diagnostic logic package handles both customer mode (browser APIs only) and support agent mode (browser APIs + JNAP calls). The UI renders different views based on auth state.

Build: `flutter build web` → static bundle → copied into router firmware at `/www/troubleshoot/` and deployed to CDN.

The router already ships Flutter Web for `privacy_gui` v1.2.2 — the Flutter runtime, bootstrap, and service worker are already present in `/www/`. The troubleshooter bundle is additive, not a new dependency.

### JNAP API (Support Agent Mode)

The router's existing REST-style API, called via `POST /JNAP/` with `X-JNAP-Action` and `X-JNAP-Authorization` headers. Same-origin from the router embed — no CORS issues, no proxy. Existing pages (`debug.html`, `cpehelp.html`) already use this pattern.

JNAP calls used in support agent mode:
- `GetDeviceList` / `GetNetworkConnections` — connected clients
- WiFi radio and AP state — channels, bands, BSSID per AP
- DHCP service state — lease table, pool utilization
- WAN status — link state, uptime, error counts
- `GetDeviceInfo` — router model, firmware version, uptime

### Speed Test: LibreSpeed (self-hosted)

Open source. Self-hosted on Linksys infrastructure. Measures download (Mbps), upload (Mbps), latency (ms), jitter (ms). No third-party licensing cost. Test data stays within Linksys-controlled infrastructure.

### Backend: None

No cloud database, no report server, no analytics pipeline. All diagnostic data is computed and displayed in the browser session. The only external network calls are LibreSpeed (to Linksys-hosted servers) and standard DNS/HTTP checks to public endpoints for connectivity testing.

---

## 9. Capability by Access Mode

| Capability | Customer Mode | Support Agent Mode |
|---|---|---|
| Speed test (LibreSpeed) | ✅ | ✅ |
| DNS resolution test | ✅ | ✅ |
| Gateway reachability | ✅ | ✅ |
| Latency and jitter | ✅ | ✅ |
| Plain-language verdict | ✅ | ✅ |
| Raw diagnostic data visible | ❌ Hidden from customer | ✅ Shown to agent |
| Per-client RSSI (JNAP) | ❌ | ✅ |
| Connected device list (JNAP) | ❌ | ✅ |
| DHCP lease table (JNAP) | ❌ | ✅ |
| WAN status and error counts (JNAP) | ❌ | ✅ |
| Router uptime and firmware version (JNAP) | ❌ | ✅ |
| WiFi band per client (JNAP) | ❌ | ✅ |
| All 6 diagnostic flows | ❌ Flows 1, 2, 4 only | ✅ All 6 |

**Hosted web (CDN version):** Customer mode only. JNAP is not accessible from an external host. Capabilities are identical to customer mode in the router embed.

---

## 10. Privacy & Data

### What Is Collected

| Field | Purpose | Stored? |
|---|---|---|
| WiFi SSID | Identify network tested | Session only — not transmitted |
| Current device IP | Diagnostic input | Session only |
| Gateway IP | Diagnostic input | Session only |
| DNS test results | Diagnostic input | Session only |
| Speed test results (Mbps, latency, jitter) | Core diagnostic | Session only |
| App version | Crash telemetry | Crash reports only |
| Timestamp | Session reference | Session only |

**Support agent mode additional data (JNAP):** Connected device list, per-client RSSI, DHCP leases, WAN state. This data is read from the router and displayed in the browser session. It is not transmitted to Linksys servers.

### What Is Not Collected

- Network passwords
- Packet content
- Public IP address
- Location or GPS
- Any data not listed above

### Data Residency

All data stays in the browser session. No diagnostic results are transmitted to Linksys servers. LibreSpeed test data is discarded server-side after the test session. Support agent mode reads JNAP data from the router locally — it does not leave the LAN.

### Consent (Customer Mode)

A disclosure screen is shown before any diagnostic runs on first use. It explains what data the tool reads and confirms that no data leaves the device. This is a hard gate — no diagnostic starts before acknowledgment.

### GDPR

GDPR applies (UK and UAE customers). The no-backend, session-only architecture minimizes compliance surface area. Legal review required before launch.

---

## 11. Phase 1 Scope

| Deliverable | Mode | Notes |
|---|---|---|
| Flutter Web app at `/www/troubleshoot/` | Both | Router embed — requires firmware team to include bundle in production image |
| Hosted web version (CDN) | Customer only | Same build; no JNAP access |
| Customer mode — Flows 1, 2, 4 | Customer | Slow Internet, Slow Device, Can't Connect |
| Support agent login | Agent | Router admin password via JNAP auth |
| Support agent mode — all 6 flows | Agent | Flows 3, 5, 6 enabled by JNAP data |
| JNAP integration | Agent | Device list, RSSI, DHCP, WAN state, uptime |
| LibreSpeed integration | Both | Self-hosted on Linksys infrastructure |
| Plain-language results UI | Both | No raw metrics shown in customer mode |
| Consent screen | Customer | First-run gate |
| Basic crash telemetry | Both | No PII |

---

## 12. Phase 2 & Beyond

| Feature | Notes |
|---|---|
| RBAC — multiple support tiers | Multiple roles beyond admin (e.g., read-only agent vs. senior agent). JNAP permission model must be evaluated. |
| Background drop monitoring | Persistent connectivity check; requires keeping browser tab open or a native companion |
| Report export / share with support | User or agent exports session results; format TBD |
| Customer mode Flows 3, 5, 6 | Currently agent-only; customer versions require simpler UI and may need background monitoring |
| Localization beyond English | UAE (Arabic) and UK markets |
| Native app | Not currently planned. Revisit only if router embed has a proven capability gap that browser cannot address. |

---

## 13. Open Decisions

| Decision | Options | Status |
|---|---|---|
| RBAC scope for Phase 2 | (A) Simple two-tier (admin vs. read-only agent); (B) Full role matrix with ISP partner access | **Open.** Not blocking Phase 1. Revisit after MVP. |
| Hosted web support agent mode | Support agents could log in on the CDN-hosted version if JNAP were proxied — but this requires a backend and introduces security complexity | **Decision: No.** Support agent mode is router-embed only. No proxy, no backend. |

---

## Appendix A: Glossary

| Term | Definition |
|---|---|
| Router embed | The Flutter Web app served from the router's lighttpd server at `http://192.168.1.1/troubleshoot` |
| JNAP | The router's internal REST API. Called via `POST /JNAP/` with action and authorization headers. Already used by existing router web pages. |
| Customer mode | Unauthenticated access. Browser-level diagnostics only. Flows 1, 2, 4. |
| Support agent mode | Authenticated via router admin password. JNAP-powered. All 6 flows. Raw data visible. |
| LibreSpeed | Open-source speed test library and server, self-hosted on Linksys infrastructure |
| Verdict | The plain-language conclusion shown at the end of a diagnostic flow |
| Blame attribution | Identifying whether the root cause is the ISP, home network/router, or a specific device |
| GDPR | General Data Protection Regulation; applies to UK and UAE customers |

---

*End of document — WiFi Troubleshooter PRD v2.0*
