# WiFi Self-Help Diagnostics: Competitive Research

**Date:** 2026-04-01
**Purpose:** Actionable design input for Instant-Help customer self-help tool at `http://192.168.1.1/troubleshoot`

---

## 1. ISP Self-Help Tools

### What Major ISPs Offer

**Xfinity xFi (Comcast)**
- App + web portal at xfinity.com/myxfi
- One-tap "Troubleshoot" button runs automated gateway health check, speed test, and signal assessment
- Shows per-device connection status (connected/offline) with device icons auto-detected by type (phone, laptop, TV, IoT)
- Speed test results displayed as a single large number with "Your speed is normal" or "Your speed is below expected" verdict
- Recommends concrete next steps: "Restart your gateway," "Move closer to your gateway," "Check for service outages in your area"
- Proactive push notifications: "We noticed your internet is slower than usual"
- Color: green checkmark = good, yellow warning triangle = degraded, red X = down

**AT&T Smart Home Manager**
- Device list with signal strength per device (bars, not dBm)
- Speed test integrated (powered by Ookla)
- "WiFi Health" score shown as a single number (e.g., 85/100)
- Troubleshooting flow: automated restart of gateway remotely, check for outages, escalate to support
- Plain language: "Your WiFi is working well" vs "Your WiFi needs attention"

**BT (UK)**
- Web-based "Complete WiFi" checker in My BT portal
- Tests line speed, compares to "guaranteed minimum speed" from contract
- Shows estimated WiFi speed vs wired speed with explanation ("WiFi is always slower than wired")
- If below minimum: auto-generates "Not getting my guaranteed speed" support ticket with diagnostics attached
- Hub firmware auto-updates with "WiFi optimization" that adjusts channels silently

**Sky (UK)**
- Sky Broadband Buddy app shows connected devices + parental controls
- Speed test button in app
- "Broadband Health Check" runs from app, tests line quality
- Plain language verdicts: "Your broadband is healthy" with green bar

**Virgin Media (UK)**
- "Connect" app: speed test, device list, WiFi signal strength per room (with Hub 5)
- Guided troubleshooting: "Are you having problems with... [WiFi / Specific device / All devices]" decision tree
- Traffic light indicator on Hub hardware itself (white = good, orange = booting, red = fault)

**Verizon FiOS / My Fios**
- "Troubleshoot" in app runs automated diagnostics sequence
- Tests router connectivity, internet connectivity, DNS, speed
- Shows "Internet OK" or "Internet has issues" with expandable detail
- Can remotely restart router from app

**Google Fiber**
- Minimalist. Speed test in app shows single number.
- Network health shown as "Good" with a green dot. That's it.
- Mesh point signal quality shown per node.

### ISP Pattern Summary

| Pattern | Adoption | Notes |
|---------|----------|-------|
| Automated multi-step diagnostic sequence | All major ISPs | Customer taps one button, system tests 3-5 things sequentially |
| Traffic-light status (green/yellow/red) | Universal | Sometimes with checkmark/warning/X icons for accessibility |
| Single verdict statement | Universal | "Your internet is working well" — not raw numbers |
| Speed as one big number + context | Universal | "120 Mbps — this is normal for your plan" |
| Device list with connection status | Most | Per-device online/offline, sometimes signal quality |
| Remote gateway restart | Xfinity, AT&T, Verizon | Not applicable to our tool (user is already on the router) |
| Proactive notifications | Xfinity, AT&T | App-only; not relevant to Tier 0/1 |

---

## 2. Router Manufacturer Apps

### What OEM Apps Show vs Hide

**Eero (Amazon)**
- Dashboard: single "Internet" status card (green = online), speed test history graph
- Speed test: one-tap, shows download/upload, saves history
- Device list: grouped by eero node, shows which band (2.4/5/6 GHz) per device
- Network health: mesh node connectivity shown as simple connected/disconnected
- HIDES: channel numbers, RSSI values, TX/RX rates, interference data
- Eero Plus (paid): "Network Insights" — bandwidth usage per device over time

**Google Nest WiFi / Google Home**
- "WiFi" card: shows internet status + mesh point status with signal quality per point
- Speed test: runs to Google servers, shows download/upload
- Device list: shows devices per access point, connection type (wired/wireless)
- "Mesh test": tests connection quality between mesh points, reports "Great connection" / "Weak connection"
- HIDES: all RF details, channel info, per-client RSSI
- Troubleshooting: "Restart network" button, link to Google Support articles

**TP-Link Deco**
- Dashboard: internet status, connected device count, speed test
- Speed test: built-in, runs from app
- Device list: per-node, shows which Deco unit each device connects to
- "Antivirus" and "QoS" features prominent
- "Mesh optimization" runs automatically; no user-facing diagnostics for it
- HIDES: channel, RSSI, RF environment

**Netgear Orbi**
- Orbi app: internet status, device list, speed test, firmware update check
- Dashboard shows "Internet Speed" as last-tested value prominently
- Device list: shows connection quality per device as bars (1-3 bars)
- "Armor" security suite (paid) adds device vulnerability scanning
- HIDES: detailed RF, channel overlap, interference
- Shows backhaul quality between Orbi units as "Good/Fair/Poor"

**ASUS (AiMesh)**
- Router web UI at 192.168.1.1 shows more detail than competitors
- "AiMesh" tab: node topology, backhaul type (wired/wireless), signal quality
- Device list: shows band, RSSI, TX/RX rate per client
- "System Log" available for advanced users (hidden under Administration)
- Network Map: visual topology showing router + nodes + devices
- ASUS shows MORE than any consumer competitor — closest to "prosumer"

**Ubiquiti UniFi**
- Full RF environment dashboard (channel utilization, interference, neighboring APs)
- Per-client: RSSI, SNR, TX/RX rate, channel width, retry rate, satisfaction score
- Speedtest integration (Ookla-powered)
- Topology map with wired/wireless backhaul visualization
- NOT consumer-facing — this is prosumer/SMB; included for comparison only

### OEM Pattern Summary

| Feature | Eero | Google | TP-Link | Netgear | ASUS |
|---------|------|--------|---------|---------|------|
| Speed test | Yes | Yes | Yes | Yes | Via app |
| Device list | Yes | Yes | Yes | Yes | Yes |
| Per-device signal quality | No | No | No | Bars | RSSI/dBm |
| Mesh node health | Yes | Yes | Yes | Yes | Yes |
| Channel/RF details | No | No | No | No | Yes |
| Troubleshooting wizard | No | Minimal | No | No | No |
| Firmware update check | Auto | Auto | Auto | Yes | Yes |

**Key insight: No consumer OEM offers a guided, step-by-step diagnostic flow. They all show status dashboards. The troubleshooting is passive ("here's your data") not active ("let's figure out what's wrong").**

---

## 3. Speed Test Options for Embedded Use

### The Constraint

The tool runs as Flutter Web at `http://192.168.1.1/troubleshoot`. There is no app-server backend on the router that can process speed test traffic. The router's lighttpd serves static files only. Any speed test must:

1. Run entirely as client-side JavaScript/WASM in the browser
2. Test against an external server (the router itself is not an endpoint)
3. Work from an HTTP (not HTTPS) origin on a private IP
4. Be licensable for commercial embedded use

### Option A: Cloudflare `@cloudflare/speedtest` -- RECOMMENDED

| Attribute | Detail |
|-----------|--------|
| Package | `@cloudflare/speedtest` on npm (v1.7.0, MIT license) |
| Architecture | Pure client-side JavaScript. Uses `PerformanceResourceTiming` API. No backend required. |
| Measures | Download, upload, latency (unloaded + loaded), jitter, packet loss |
| Server flexibility | Defaults to Cloudflare edge. **Supports custom `downloadApiUrl` and `uploadApiUrl`** for testing against Linksys-hosted endpoints |
| Embedding | `npm install @cloudflare/speedtest`, then `new SpeedTest({ onFinish: ... })` |
| License | MIT — fully permissive, commercial use allowed |
| Size | ~120 KB unpacked |
| Maturity | Powers speed.cloudflare.com, maintained by Cloudflare Radar team |
| AIM scores | Built-in quality categorization for streaming, gaming, video calls |

**Why it's the best option:**
- MIT license = no licensing cost or negotiation
- Works purely client-side = no router backend needed
- Custom server URLs = can point to Linksys-hosted download/upload endpoints
- AIM scores = can translate raw speed into "Is this good enough for Netflix?" verdicts
- Active maintenance by Cloudflare

**Integration with Flutter Web:**
```dart
// In browser_service.dart, use dart:js_interop to call the JS library
// Bundle speedtest.js with the Flutter Web build
// OR load from Cloudflare CDN (requires internet)
```

**Custom server setup:** Linksys would host simple HTTP endpoints that serve/receive data blobs. The download endpoint returns a large file; the upload endpoint accepts POST data. No speed-test-specific server logic — just data transfer endpoints.

### Option B: LibreSpeed (open source, LGPL-3.0)

| Attribute | Detail |
|-----------|--------|
| Repo | github.com/librespeed/speedtest |
| Architecture | Client: JavaScript + Web Workers. **Server: required** (PHP, Go, Rust, or Node.js) |
| Measures | Download, upload, ping, jitter |
| Server flexibility | Self-hosted only — that's the point |
| License | LGPL-3.0 |

**Problem for our use case:** Requires a backend server. The router's lighttpd cannot run PHP/Go/Node. Would need Linksys to host a LibreSpeed server instance externally, at which point the Cloudflare option is simpler (no server to maintain, just data endpoints).

**Could work if:** Linksys hosts a LibreSpeed server instance on their infrastructure. The browser JS client makes requests to that server. But this means maintaining a LibreSpeed server deployment vs. just hosting simple data endpoints for Cloudflare's library.

### Option C: Ookla Speedtest Custom (enterprise, paid)

| Attribute | Detail |
|-----------|--------|
| Product | Speedtest Custom / Speedtest Powered |
| Architecture | Embeddable HTML/JS widget or SDK |
| License | Enterprise licensing — per-deployment or per-test fees |
| Flexibility | Tests against Ookla's global server network |

**Problem:** Enterprise licensing cost, vendor dependency, likely per-test billing. Ookla licenses this to ISPs (AT&T, Comcast use it). For a router manufacturer embedding in firmware, the licensing model may not fit. Also uncertain whether it works from `http://` origins on private IPs.

### Option D: fast.com (Netflix)

No embeddable SDK or API. fast.com is a single-purpose Netflix property. Cannot be embedded.

### Option E: Network Information API (browser native)

`navigator.connection.effectiveType` provides rough estimates ("4g", "3g", "slow-2g"). Not a real speed measurement. Useful as a supplementary signal ("connection type: wifi") but not a speed test replacement. Limited browser support (Chrome/Edge only, not Safari).

### Option F: DIY Speed Test

Build a minimal speed test using `fetch()` to download/upload data blobs from a Linksys-hosted server, measuring elapsed time with `performance.now()`. Simpler than LibreSpeed but less accurate (no Web Workers, no multi-connection, no loaded latency measurement). Could serve as a fallback if the Cloudflare library has issues.

### Speed Test Recommendation

**Primary: `@cloudflare/speedtest`** pointed at Linksys-hosted data endpoints. MIT license, pure client-side, supports custom servers, includes AIM quality scores.

**Fallback: DIY `fetch()`-based test** against same Linksys endpoints. Less sophisticated but zero external dependencies.

**Linksys infrastructure needed:** Two HTTP endpoints — one serving large random data (for download test), one accepting POST data (for upload test). These are trivial to host on any CDN or cloud service. No speed-test-specific logic server-side.

---

## 4. UX Patterns for Non-Technical Users

### What the Best Consumer Tools Do

**1. Single Verdict First, Details on Demand**

Every good tool leads with a plain-language verdict, not numbers:
- "Your internet is working well" (green)
- "Your WiFi needs attention" (yellow)  
- "Your internet is down" (red)

Numbers are secondary — shown smaller, below the verdict, or behind a "See details" tap.

**2. Traffic-Light Color System (Universal)**

Green/yellow/red is universal across ISPs and OEMs. But the best tools add:
- **Icon redundancy:** checkmark / warning triangle / X (for color-blind users)
- **Text redundancy:** "Good" / "Needs attention" / "Problem found" alongside color
- Three states, not five — avoid "orange" or "light green" confusion

**3. Speed Context, Not Raw Numbers**

Bad: "Download: 47.3 Mbps"
Good: "Your speed is 47 Mbps — fast enough for 4K streaming on 3 devices"

The pattern: **[Number] — [What it means for you]**

ISPs anchor against the customer's plan ("You're getting 47 of your 100 Mbps plan"). Since we don't know the customer's plan, anchor against activities:

| Speed | Verdict | Context |
|-------|---------|---------|
| >50 Mbps | Good | "Fast enough for 4K streaming and video calls" |
| 25-50 Mbps | OK | "Good for HD streaming; may slow with many devices" |
| 10-25 Mbps | Slow | "Enough for browsing; streaming may buffer" |
| <10 Mbps | Problem | "Your internet is very slow — video calls and streaming will struggle" |

**4. Sequential Diagnostic Flow**

The ISP pattern that works best:
1. Show what you're testing ("Checking your internet connection...")
2. Animate progress through steps (gateway check -> DNS check -> speed test -> done)
3. Show each step's result as it completes (green check / red X)
4. End with overall verdict + specific recommendations

This is the "doctor's visit" pattern — patient sees the doctor running tests, then gets a diagnosis.

**5. Action-Oriented Recommendations**

Bad: "Your DNS resolution is slow"
Good: "Try restarting your router. Unplug it for 30 seconds, then plug it back in."

Every finding maps to a concrete customer action. The recommendations ladder:
1. "Everything looks good — no action needed" (green)
2. "Try [specific action] — this usually fixes it" (yellow)
3. "Contact your internet provider — the issue is on their end" (red, external)
4. "Contact Linksys support — your router may need attention" (red, internal)

**6. Language Rules**

| Use | Avoid |
|-----|-------|
| "internet" | "WAN" |
| "WiFi signal" | "RSSI" |
| "your router" | "the gateway" / "AP" |
| "your device" | "the client" / "STA" |
| "internet provider" | "ISP" / "upstream" |
| "restart" | "reboot" / "power cycle" |
| "slow" / "fast" | "high latency" / "throughput" |
| "this device" vs "other devices" | "per-STA" / "aggregate" |

**7. What NOT to Show Customers**

Information that confuses more than it helps:
- Channel numbers (means nothing to customers)
- RSSI/dBm values
- TX/RX rates
- DNS server addresses
- IP addresses (except "your router's IP is 192.168.1.1" for setup)
- Firmware version numbers (unless action needed: "An update is available")
- Packet loss percentages
- Jitter values

**Reserve these for Support Agent mode.** In customer mode, translate everything to verdicts.

**8. The "What To Do Next" Pattern**

Best implementations use a prioritized action card:

```
[RED ICON] Your internet speed is slower than expected

What to do:
1. Restart your router (takes ~2 minutes)
   [Restart Button]
2. Move closer to your router
3. Disconnect devices you're not using
4. If still slow, contact your internet provider

[Share this report with support ->]
```

Key: numbered steps, most likely fix first, escalation path last, share button for support handoff.

---

## 5. Design Implications for Instant-Help

Based on this research, here's what to implement:

### Must Have (validated by all competitors)
1. **Single-tap diagnostic flow** that tests gateway, DNS, speed sequentially with animated progress
2. **Traffic-light verdict system** — green/yellow/red with icon + text redundancy
3. **Speed in context** — "47 Mbps — good for streaming" not just "47 Mbps"
4. **Prioritized action cards** — numbered "what to do" steps, easiest fix first
5. **Share report button** — generates a summary for support handoff

### Should Have (competitive differentiation)
6. **Guided troubleshooting flow** — "What's wrong? [Slow / Dropping / Can't connect / ...]" with branching logic. NO competitor does this in the router itself.
7. **Device-specific diagnosis** — "Is it slow on all devices or just this one?" flow
8. **Activity-anchored speed** — "Can I stream 4K?" / "Can I video call?" / "Can I game?" with yes/no answers

### Differentiator (no one does this)
9. **The tool is ON the router** — no app download, no account creation, works when WiFi is the problem (via LAN), works on any device with a browser
10. **SMS entry point (Tier 0)** — support agent texts a link, customer taps it, diagnostics run on cellular (bypasses broken WiFi entirely)

### Speed Test Architecture
- Bundle `@cloudflare/speedtest` JS with Flutter Web build
- Point at Linksys-hosted download/upload data endpoints
- Translate raw results to AIM-style quality scores for customer-facing display
- Show raw numbers only in Support Agent mode
