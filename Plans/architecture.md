# Customer WiFi Troubleshooter — Architecture Plan
**Status:** Planning
**Date:** 2026-03-30
**Author:** Deven Ducommun
**Relation to Firmware Inspector:** Separate repo. This is a customer-facing product; Firmware Inspector remains an internal engineering/QA tool.

---

## The Core Insight (Read This First)

**The install barrier is an architectural contradiction.**

The customers who most need a WiFi troubleshooter are, at the moment of need, the least able to install a new app. An Android user who *cannot connect to WiFi* cannot easily download an app from the Play Store. A customer whose internet is down is not opening the App Store.

This changes the architecture priority:

> **A zero-install path must exist as the primary delivery mechanism. The native app is an enhancement layer, not the product.**

The recommended architecture is **tiered delivery**, not "build four apps":

| Tier | Delivery | Install Required | Works When WiFi Down? | Capability |
|------|----------|-----------------|----------------------|------------|
| **0** | SMS link → cellular web | None | Yes (over cellular) | Basic: IP, gateway, SSID, connectivity |
| **1** | Web app (router admin page or support URL) | None | LAN only | Full local diagnostics |
| **2** | Progressive Web App (browser install) | Browser prompt | No (after install) | Full diagnostics + saved history |
| **3** | Native app (Flutter) | App Store/Play Store | No | Full diagnostics + background monitoring + enhanced UX |

**Phase 1 ships Tier 0 + Tier 1. Tier 3 (native) is Phase 2.**

---

## Project Structure

### Separation from Firmware Inspector

**New repo:** `linksys/wifi-troubleshooter` (or `LinksysQuality/wifi-troubleshooter`)

Do **not** branch from Firmware Inspector. These are different tools with different audiences, different data models, different distribution, and different privacy requirements. Shared code (if any) belongs in a published library, not a fork.

```
wifi-troubleshooter/
├── lib/                    # All tiers — Flutter (single codebase)
│   ├── diagnostics/        # Platform-agnostic diagnostic logic (runs on web + native)
│   ├── ui/                 # Flutter UI widgets
│   └── main.dart           # Entry point
├── web/                    # Flutter Web output → Cloudflare Pages + router /www/troubleshoot/
├── native/                 # Flutter native targets
│   ├── lib/
│   │   ├── diagnostics/    # Platform-agnostic diagnostic logic
│   │   └── ui/             # Flutter UI
│   ├── android/
│   ├── ios/
│   ├── macos/
│   └── windows/
├── shared/                 # Shared diagnostic schemas (JSON/TypeScript types)
│   └── schemas/            # Report format, diagnostic result types
└── docs/
    ├── privacy-policy.md   # Required for app store submission
    └── data-dictionary.md  # Every field collected, why, retention
```

---

## Framework Decision

### Recommendation: **Flutter** for all tiers

> **Device confirmed (2026-03-30):** The M60CF production image already ships Flutter Web. `/www/` on the device contains `flutter.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`, and `main.dart.js` — the existing router admin UI (`privacy_gui` v1.2.2) is a Flutter Web app served by lighttpd at `http://192.168.1.1`. This eliminates the question of whether Flutter is the right choice for this team — it already is.

This means:
- **Tier 3 (native app):** Flutter — already the team's framework
- **Tier 1 (router embed):** Flutter Web — can share the same diagnostic package as the native app, served from `/www/troubleshoot/` by the existing lighttpd instance
- **Tiers 0/2 (external web):** Flutter Web compiled to static output, deployed to CDN — same codebase as the router bundle

#### Why Flutter for native (Tier 3)

| Criterion | Flutter | React Native | Native per Platform |
|-----------|---------|--------------|---------------------|
| Single codebase | ✅ Dart | ✅ JS/TS | ❌ 4× |
| Native compilation | ✅ AOT | ⚠️ Bridge/JSI | ✅ |
| WiFi platform channels | ✅ First-class escape hatch | ✅ Native modules | ✅ Maximum |
| Plugin ecosystem stability | ✅ Google-backed | ⚠️ Community-driven | ✅ Vendor |
| Desktop (Win/Mac) | ✅ Stable | ⚠️ Electron fallback | ✅ |
| Team maintainability | ✅ 1 codebase | ✅ 1 codebase | ❌ 4 codebases |
| Migration path if wrong | ✅ Logic layer portable | ✅ Logic layer portable | ⚠️ Full rewrite |

Flutter is preferred over React Native for this use case because:
1. WiFi APIs are called via **platform channels** — Flutter's channel system is more stable and better documented than RN's Native Modules for platform-specific low-level APIs
2. Flutter compiles natively on Windows and macOS with no Electron dependency
3. Google backs the project — lower plugin ecosystem risk than RN's community-dependent plugins

**Critical rule:** All WiFi diagnostic logic (scanning, interpretation, result modeling) must live in a **platform-agnostic Dart service layer** with clear interfaces. The UI never calls WiFi APIs directly. This means if Flutter ever needs to be replaced, the diagnostic logic is portable.

#### Why Flutter Web for all tiers

- **Same codebase across all tiers** — the diagnostic logic package compiles to native (iOS/Android/Mac/Windows) and to web (WASM/JS) from one Dart codebase
- The router embed bundle and the CDN-hosted web app are the same build artifact pointed at different hosts
- The firmware team already owns Flutter — no new framework skill required
- Flutter Web compiles to a static bundle that lighttpd serves without modification

---

## Per-Platform Diagnostic Capability Reality

**This is the most important table in this document.** Platform restrictions are not bugs to route around — they are hard ceilings that must be designed around honestly.

| Capability | iOS | Android | macOS | Windows |
|------------|-----|---------|-------|---------|
| Current SSID | ✅ (iOS 14: requires location permission) | ✅ | ✅ CoreWLAN | ✅ WlanAPI |
| BSSID (access point MAC) | ❌ (NEHotspotHelper required — denied) | ✅ (location permission) | ✅ | ✅ |
| RSSI / signal strength | ✅ current AP only | ✅ | ✅ | ✅ |
| Nearby SSID list / channel scan | ❌ (entitlement denied) | ✅ (location + NEARBY_WIFI_DEVICES) | ✅ | ✅ |
| Channel / band (2.4/5/6 GHz) | ✅ (inferred from frequency) | ✅ | ✅ | ✅ |
| Gateway IP / reachability | ✅ | ✅ | ✅ | ✅ |
| Local IP / subnet | ✅ | ✅ | ✅ | ✅ |
| DNS resolution test | ✅ | ✅ | ✅ | ✅ |
| LAN device enumeration (mDNS) | ⚠️ Local Network permission prompt | ⚠️ NEARBY_WIFI_DEVICES | ✅ | ✅ |
| Traceroute | ✅ (ICMP) | ✅ | ✅ | ✅ |
| Speed test | ✅ | ✅ | ✅ | ✅ |
| Packet capture | ❌ Out of scope | ❌ Out of scope | ❌ Out of scope | ❌ Out of scope |
| Router admin SSH | ❌ Out of scope | ❌ Out of scope | ❌ Out of scope | ❌ Out of scope |

**iOS design contract:** The iOS app is a reduced-scope product by design. It cannot deliver channel scan or neighbor AP data. The iOS UI must never show empty "channel congestion" panels — that creates trust failure. iOS delivers: connected SSID, signal strength, band, gateway reachability, DNS, speed, traceroute, per-device tests. No more, no less.

**Android note:** `WifiManager.startScan()` is on a deprecation trajectory (Google moving toward passive scan delivery). Design toward passive scan result consumption now. Treat active scan as deprecated for planning purposes.

---

## Diagnostic Feature Architecture

### The Six Customer Complaints

The four specified + two additional that round out the tier-1 support picture:

| # | Complaint | Root Causes We Can Diagnose | Root Causes We Cannot (honest) |
|---|-----------|----------------------------|-------------------------------|
| 1 | Slow internet | ISP under-delivering, DNS slow, gateway congested, WiFi signal poor | ISP routing, CDN issues, server-side |
| 2 | Slow device (others fine) | Device on wrong band, low signal, DNS cache issues | Device OS issues, app-level bugs |
| 3 | Connectivity drops | DHCP lease expiry, band steering failure, channel congestion, interference | Router firmware bug, ISP line drop |
| 4 | Can't add/connect new device | Wrong password, WPA3 incompatibility, band steering blocking, DHCP pool full, hidden SSID | Router device limit (no admin access) |
| 5 | WiFi dead spots / weak signal in room | Signal strength too low, wall interference, wrong channel | Requires router relocation or mesh node |
| 6 | Router appears offline / rebooting | Power/thermal issue, firmware crash loop | Requires physical inspection |

---

### Diagnostic Flow Architecture

Each flow follows the same UX pattern (from the Experiential lens):
1. **Validate** — confirm the symptom before diagnosing ("yes, your internet IS slower than expected")
2. **Scope** — narrow to device vs. network vs. ISP
3. **Diagnose** — run the specific tests for that scope
4. **Verdict** — single plain-language finding with confidence level
5. **Action** — one recommended next step
6. **Export** — structured report for support handoff

#### Flow 1: Slow Internet
```
Start
 ├── Run speed test → compare to provisioned plan
 │    ├── Near plan speed: "Your internet speed is fine — this is likely a device or app issue"
 │    └── Well below plan speed:
 │         ├── Test DNS resolution (multiple resolvers)
 │         ├── Ping gateway latency + jitter
 │         ├── Check WiFi signal strength + band
 │         ├── [Desktop] Check channel congestion
 │         └── Verdict: ISP / gateway / WiFi / specific-device blame attribution
```

**Speed test strategy:** Use LibreSpeed (open source, self-hostable) or negotiate Ookla SDK license. Do NOT roll a custom speed test — accuracy and trust suffer. LibreSpeed is preferred for cost and data control.

#### Flow 2: Slow Device (Others Fine)
```
Start
 ├── Verify: "Is this happening on all apps or just one?" [Yes/No gate]
 ├── Check device WiFi signal strength vs. other devices
 ├── Check device WiFi band — is it stuck on 2.4 GHz?
 ├── Run device-specific speed test + DNS test
 └── Verdict: device signal / band issue / device-specific / recommend router relocation
```

#### Flow 3: Connectivity Drops
```
Start
 ├── Passive: monitor gateway ping every 5s for 2 minutes (with user consent)
 ├── Check DHCP lease validity + expiry time
 ├── [Desktop] Check channel + neighbor channel interference
 ├── Check band (2.4 GHz drops more in congested areas)
 └── Verdict: DHCP issue / band/channel issue / ISP drops / inconclusive (drop not observed)
```
*Key: intermittent drops will NOT appear in a 30-second test. The app must be honest: "No drops observed in 2 minutes — run in background for 10 minutes to catch intermittent drops."*

#### Flow 4: Can't Add / Connect New Device
```
Start
 ├── "What happens when you try to connect?" [Branching: password wrong / connects then drops / never appears]
 ├── Check: is SSID hidden? (user must be told to show it)
 ├── Check: DHCP pool — how many leases active vs. total? (LAN scan + estimate)
 ├── Check: WPA version — WPA3-only? Some older devices can't connect
 ├── Check: band steering — 6 GHz-only? Old devices can't see it
 └── Verdict + action: specific configuration guidance
```

#### Flow 5: Dead Spots / Weak Signal
```
Start
 ├── Walk-test mode: show live RSSI as user walks room to room
 ├── Mark weak zones on simple floor map (optional, Phase 2)
 ├── Check band: 5/6 GHz drops faster with distance/walls
 └── Verdict: move router / add mesh node / switch to 2.4 GHz for that area
```

#### Flow 6: Router Rebooting / Offline
```
Start
 ├── Check: did the internet drop suddenly? (connectivity test)
 ├── Check: can we reach the router's local IP? (gateway ping)
 ├── If gateway unreachable: "This is likely a hardware issue — check power and lights"
 └── If gateway reachable but internet down: likely ISP issue — provide ISP contact + evidence
```

---

## Data & Privacy Model

**Every field collected must be here. If it's not listed, it's not collected.**

| Field | Why Collected | PII Under GDPR? | Retention |
|-------|--------------|-----------------|-----------|
| WiFi SSID | Identify network being diagnosed | Yes (can identify household) | Session only, not persisted to server |
| BSSID | Identify access point | Yes (MAC = PII) | Session only |
| Device IP (LAN) | Verify DHCP validity | No (LAN IP is not public) | Session only |
| Gateway IP | Verify connectivity | No | Session only |
| Speed test result (Mbps) | Core diagnostic | No | Report only (user controls) |
| DNS resolution result (ms, success/fail) | Diagnose DNS issues | No | Report only |
| Signal strength (RSSI, dBm) | Diagnose signal issues | No | Report only |
| WiFi band (2.4/5/6) | Diagnose band issues | No | Report only |
| App version + platform | Support triage | No | Report only |
| Timestamp | Support triage | No | Report only |
| Crash/error telemetry | App stability | No PII in stack traces | 30 days, aggregated only |

**What is never collected:**
- Public IP address (ISP can see it; we don't need it)
- Connected device names or MAC addresses of client devices
- Network passwords
- Router model (without explicit user input)
- Location / GPS
- Any packet content

**Consent flow:** On first diagnostic run, a single screen: "To diagnose your WiFi, this app reads your network signal, speed, and connection status. [See exactly what we read →]. This data stays on your device unless you choose to share a report with Linksys support."

---

## Build & Distribution

### Web (Tiers 0-2)

| Channel | Mechanism | Update |
|---------|-----------|--------|
| Support URL (`support.linksys.com/troubleshoot`) | Standard web deploy | Instant (CDN) |
| Router admin page embed (`http://192.168.1.1/troubleshoot`) | Flutter Web bundle in `/www/troubleshoot/` — same lighttpd, same server already running | Firmware update |
| SMS link | Short URL → web app | Instant |
| PWA install | Browser "Add to Home Screen" | Service Worker push |

Build: Flutter Web → `flutter build web` → static output → Cloudflare Pages. Same build artifact used for router firmware bundle. CI: GitHub Actions on main merge.

### Native (Tier 3 — Flutter)

| Platform | Distribution | Build |
|----------|-------------|-------|
| iOS | Apple App Store | Xcode + fastlane + GitHub Actions |
| Android | Google Play Store | Gradle + fastlane + GitHub Actions |
| macOS | Mac App Store + direct DMG | Xcode + GitHub Actions |
| Windows | Microsoft Store + direct MSIX | GitHub Actions Windows runner |

**CI/CD:** GitHub Actions matrix build across all platforms. Single workflow file triggers on release tag. Secrets: Apple signing cert, Google Play service account, Windows code signing cert.

**Minimum OS versions (Phase 1):**
- iOS 16+ (2022, ~85% of active iPhones as of 2026)
- Android 11+ (API 30, 2020, ~80% of active Android devices)
- macOS 13 Ventura+ (2022)
- Windows 10 21H2+

---

## Update Strategy

| Platform | Mechanism | Forced Update? |
|----------|-----------|---------------|
| iOS | App Store only (Apple controls) | No — user must approve |
| Android | Play Store (in-app update API) | Soft prompt in-app; hard block if critical security |
| macOS (App Store) | App Store | No |
| macOS (direct DMG) | Sparkle framework (Rust-compatible) | Soft prompt on launch |
| Windows (Store) | Microsoft Store | No |
| Windows (direct MSIX) | Windows Package Manager / in-app check | Soft prompt on launch |
| Web | Automatic (CDN / Service Worker) | Yes — transparent |

**Versioning:** Semantic versioning (`MAJOR.MINOR.PATCH`). All platforms ship the same version simultaneously via release tag. A version mismatch between app and report schema must never produce a broken report.

**Critical update handling:** If a diagnostic is producing wrong results (false positive/negative bug), the web tier can be patched instantly. Native apps require store review (1-3 days). Design the diagnostic logic to live in the shared schema layer where web can lead and native catches up.

---

## Phase 1 Scope

**Ship this. Nothing else.**

- [ ] Web app (Flutter Web) deployed at support URL + SMS-triggerable link
- [ ] Flows 1, 2, 4 fully implemented (Slow Internet, Slow Device, Can't Connect)
- [ ] Structured report export (JSON + human-readable summary)
- [ ] Plain-language results UI (no raw metrics shown to users)
- [ ] Consent screen + data dictionary
- [ ] iOS and Android apps (Flutter) with reduced scope per platform API reality
- [ ] macOS app (Flutter) with full diagnostic capability
- [ ] Windows app (Flutter) with full diagnostic capability
- [ ] Basic crash telemetry (no PII)
- [ ] App Store + Play Store accounts configured (can take 2-4 weeks)

**Defer to Phase 2:**
- Flows 3, 5, 6 (Drops, Dead Spots, Router Offline) — these need more nuanced UX
- Background monitoring (connectivity drop detection over time)
- Walk-test / signal mapping
- Router admin page embed (requires firmware team coordination)
- Localization beyond English

---

## QA Tool vs. Customer Tool — Clear Distinction

| Dimension | Firmware Inspector (QA Tool) | WiFi Troubleshooter (Customer Tool) |
|-----------|------------------------------|--------------------------------------|
| Audience | Linksys engineers + QA | End customers |
| Access | SSH + serial to device | Standard OS networking APIs only |
| Purpose | TR-069/369 compliance, firmware diff, device state | WiFi problem diagnosis |
| Distribution | Internal only | App Store / web / SMS |
| Data model | Technical (TR-181 data model) | Customer-friendly (plain language) |
| Credentials | Device admin creds | None — no router login required |
| Privacy | Engineering use, no PII concern | Full GDPR/CCPA compliance required |
| Repo | `firmware-inspector` | New repo |

These tools must **never share a data schema, telemetry pipeline, or distribution channel.**

---

## Architecture Decision Log

| Decision | Choice | Rationale | Alternatives Rejected |
|----------|--------|-----------|----------------------|
| Primary delivery | Web-first, native second | Install barrier paradox — customers need it when they can't install | Native-first (wrong for outage scenario) |
| Cross-platform framework | Flutter | Stable WiFi platform channels, native compilation, single codebase, Google-backed | React Native (plugin stability risk), Native/platform (4× maintenance) |
| Web framework | Flutter Web | Same codebase as native app; team already uses Flutter; router already ships Flutter Web (`privacy_gui`) | SvelteKit (separate codebase), plain HTML (acceptable fallback for Tier 0 only) |
| Speed test | LibreSpeed (open source) | No licensing cost, self-hostable, data control | Ookla SDK (licensing cost + data sharing), custom (poor accuracy/trust) |
| iOS feature scope | Reduced — no channel scan, no BSSID | NEHotspotHelper entitlement will be denied; design honestly | Promise parity with Android (sets up failure) |
| Packet capture | Out of scope permanently | Too invasive, requires root, app store rejection risk, not needed for top complaints | In scope (overkill for customer use case) |
| Backend / cloud | Minimal — report export only | Core diagnostics must work with internet down; cloud-dependent = fails when most needed | Full cloud backend (anti-pattern for outage use case) |
| Project separation | New repo | Different audience, data model, privacy requirements, distribution | Branch of Firmware Inspector (conflates tools) |

---

## Open Questions for Next Session

1. **Speed test:** LibreSpeed self-hosted (Linksys infrastructure) or third-party server? LibreSpeed servers need to be close to customers (UAE, UK markets).
2. **SMS trigger:** Which short code / SMS provider? Needs legal/compliance review for UAE/UK.
3. **Router admin page embed:** Confirmed URL is `http://192.168.1.1` (lighttpd, `/www/` doc root). The path `http://192.168.1.1/troubleshoot` is available — firmware team just needs to include the Flutter Web bundle in the image under `/www/troubleshoot/`. Infrastructure is already there. Question is whether firmware team will prioritize including it in production images.
4. **App Store accounts:** Does Linksys have existing Apple/Google developer accounts for consumer apps, or does this need new registrations?
5. **Report storage:** Should reports ever go to a backend for support agents to pull, or is copy-paste / screenshot the intended handoff? Backend adds significant GDPR scope.
