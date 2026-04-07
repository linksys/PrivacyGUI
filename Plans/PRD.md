# Instant Help — Customer Self-Help Page
## Product Requirements Document

**Version:** 0.7
**Date:** 2026-04-07
**Status:** DRAFT — Review Loop 4 (not approved for implementation)
**Replaces:** WiFi Troubleshooter PRD v2.0 (agent-mode design)

---

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1 | 2026-04-07 | Deven + William | Initial customer self-help design — dropped agent mode, defined 4 customer tabs, full JNAP feasibility map, 7 open questions |
| 0.2 | 2026-04-07 | Deven + William | All 7 open questions resolved: tab names finalized, guest network toggle confirmed (cross-page impact noted), WiFi password display confirmed, MAC filter toggle confirmed (cross-page impact noted), auto-run confirmed, child node naming defined, weak-WiFi speed test handling elevated to primary finding |
| 0.3 | 2026-04-07 | Deven + William | Customer flow walkthrough — 16 findings applied: firmware update disconnect warning, post-restart check-again CTA, guest device separation, wired device help path, node naming simplified (no model number → use "satellite node" consistently), uptime display gated to 30+ days, guest network minimal off state, modem assumption fixed with combo-unit path, speed result contextualized by what it supports, device picker collapsed to device-type question, IoT/WPA3 compatibility path added, apartment interference acknowledged, new Flow 5 "My connection keeps cutting out" added |
| 0.7 | 2026-04-07 | Deven + William | 5-round deliberation (25 walkthroughs) — polish pass: ISP escalation bridge sentence added ("Since restarting didn't fix it, the issue is likely outside your router"); ISP script phrasing naturalised ("I restarted my router but the problem persists"); speed result variance note added; Flow 3 blocklist copy rewritten to reduce fear — explains what it does and why turning it off is safe |
| 0.6 | 2026-04-07 | Deven + William | Flow 5 restructured: Step 1 now asks frequency + scope (whole internet vs. specific devices) before running the monitoring test — specific device drops redirect to Flow 3 immediately, skipping the 2-minute test entirely; post-restart ISP script simplified since scope is already known |
| 0.5 | 2026-04-07 | Deven + William | Dead-end fixes: Tab 0 swaps restart button to escalation after failed Check Again; Flow 2 ISP script uses speed-specific language; Flow 5 adds "everything or specific devices?" qualifying question before ISP handoff to catch Flow 3 mis-entries; ISP scripts now include "I already restarted" in all paths; "modem" replaced with "box from your internet company" throughout; restart countdown adds page-reload reassurance |
| 0.4 | 2026-04-07 | Deven + William | Deliberation synthesis — 8 findings from 15-persona customer walkthrough (3 rounds × 5 AI models): all-clear state redesigned as "what are you running into?" with flow cards (S-7 + user request); router light guide added as persistent reference (S-1); visual aid spec for "one box or two?" (S-2); inline plain-language alias enforcement (S-3); speed result now shows Mbps + label together (S-4); per-check "Show details" expandable in Tab 0 (S-5); IoT/smart home intermittent drops path in Flow 5 (S-6); restart reassurance copy added (S-8) |

---

## What We're Building

A 5-flow 4-tab customer self-help page that replaces the Instant Verify agent dashboard. Every screen is designed for a frustrated customer at home — no technical knowledge required, no support agent needed.

**Access point:** `http://192.168.1.1` → Instant Verify section (same route as today)
**Audience:** End customers only. No agent features, no technical data tables.
**Builds on:** Existing `instant_verify_pivot_view.dart` + `overview_tab.dart` (Tab 0 ~85% done; Tabs 1-3 are "Coming Soon" stubs to be replaced)

---

## What Changed From the Previous Design

The old design had a customer mode + support agent mode split. **Agent mode is dropped entirely for Phase 1.** All four tabs are customer-facing. Technical data that has no customer action path is hidden or removed.

---

## The Four Tabs

| Tab | Name | Purpose |
|-----|------|---------|
| 0 | Instant-Test | One-touch automated diagnostics — finds problems and fixes them automatically |
| 1 | My Devices | See all connected devices, check signal quality, get device-specific help |
| 2 | My Network | See your mesh nodes, internet connection, and WiFi overview |
| 3 | Help Me Fix It | 5 guided flows for issues that need investigation or physical action |

---

## Cross-Page Impact Register

> Features on this page that **write** router settings also affect other pages in PrivacyGUI. Future development must ensure these pages stay in sync and reflect changes made here.

| Feature | Action | Pages Affected | Status |
|---------|--------|----------------|--------|
| Guest network toggle | `SetGuestNetworkSettings` | Guest Network settings page | ⚠️ Future dev required — ensure settings page reflects state changes made here |
| MAC filter toggle | `SetMACAddressFilterSettings` | MAC Filter / Access Control settings page | ⚠️ Future dev required — ensure settings page reflects state changes made here |

---

## Tab 0: Instant-Test

### Goal
Customer lands on this tab, waits ~30 seconds, sees either a "what are you running into?" handoff or a ranked list of issues with one-tap fix buttons. Auto-runs — no button press required.

### Behavior

**Auto-runs on page load.** Live checklist updates as each check completes:
```
✓ Router reached
✓ Internet connected
✓ Websites loading
⟳ Speed check… → ✓ Speed: 45 Mbps
✓ Devices checked
✓ Software is up to date  |  ⬆ Software update available
```

Note: "Software is up to date" shows ✓ when current. If an update is available, it shows as "⬆ Software update available" — not a failure, not a pass. It's a separate state that leads to an action button.

Each checklist item is **tappable for plain-language detail** — see "Progressive Disclosure" section below.

**Preliminary state** (JNAP loaded in <1s, browser tests still running in background):
- Device/firmware/WAN findings show immediately
- "Still checking your speed…" note shown

**Complete state — No Issues Found:**

> *We didn't detect any issues. Still having a problem?*
> *12 checks passed*
>
> *Tell us what's happening and we'll help:*
>
> ```
> ┌──────────────────────┐  ┌──────────────────────┐
> │  🌐  My internet     │  │  🐢  My internet     │
> │      isn't working   │  │      is slow         │
> └──────────────────────┘  └──────────────────────┘
> ┌──────────────────────┐  ┌──────────────────────┐
> │  📶  A device won't  │  │  🏠  WiFi doesn't    │
> │      connect         │  │      reach a room    │
> └──────────────────────┘  └──────────────────────┘
> ┌──────────────────────┐
> │  🔄  My connection   │
> │      keeps cutting   │
> │      out             │
> └──────────────────────┘
> ```
>
> *[Run Again]*

Rationale: A clean all-clear is a dead end if the customer still has a problem. This state actively invites the customer to self-select their issue and routes them into the Help Me Fix It flows without requiring a tab switch. The tone ("we didn't detect") is honest — it positions the tool as looking carefully, not dismissing the problem.

**Complete state — Issues found:**
- Findings listed in severity order (most severe first)
- First 2 findings always visible
- Additional findings collapsed behind "Show more"
- Each finding: plain-language headline + explanation + action button (if applicable)

### Progressive Disclosure: Per-Check Details (S-5)

Every checklist item in the live list is tappable. On tap, an inline expansion shows:

```
✓ Websites loading
   ▼ [tapped]
   ─────────────────────────────────────────────
   We sent a request to look up a website address
   (like google.com). Your router found it — websites
   should load normally.
   ─────────────────────────────────────────────
```

For a failed check:
```
✗ Websites loading
   ▼ [tapped]
   ─────────────────────────────────────────────
   We tried to look up a website address and your
   router couldn't find it. This means websites may
   not load even though your router shows connected.
   Restarting your router usually fixes this.
   ─────────────────────────────────────────────
   [Restart Router]
```

**Rules:**
- No technical terms in the detail text — ever. "Look up a website address" not "DNS resolution."
- Detail text is a full sentence or two. Not a tooltip.
- Tapping again collapses the detail.
- Only one detail open at a time.

### Auto-Fix Actions

**Restart Router**
- Confirm: "This will disconnect all devices for about 2 minutes. Continue?"
- 2-minute countdown with cancel option
- During countdown, show inline reassurance:
  ```
  ⟳ Restarting your router…  1:42 remaining

  Don't worry — this is normal. Your devices will
  disconnect for a couple minutes, then reconnect
  on their own. You don't need to do anything.

  This page will reload automatically when your
  router is back online.
  ```
- Completion state: "Your router is back online. Tap 'Check again' to see if the issue is resolved." → [Check again] button triggers a fresh run

**After Check Again — if same finding still shows:**
Do not show [Restart Router] again. Swap to the appropriate escalation based on which check is still failing:

| Finding still present | Action shown instead |
|---|---|
| Check #1 — router still unreachable | "Your router may not be responding. Contact Linksys support." |
| Check #3 — still no IP from provider | ISP contact script (see below) |
| Check #4 — websites still not loading | ISP contact script |
| Check #5 or #6 — still slow | ISP contact script |

ISP contact script (used above):
```
Since restarting didn't fix it, the issue is likely
outside your router.

When you call your internet provider, say:
"My router shows it's connected but [websites won't load /
my speed is only X Mbps]. I restarted my router but the
problem persists."

[I'll call my provider]
```

The bridging sentence explains *why* we're escalating — prevents the customer from feeling abandoned. The phrasing "I restarted my router but the problem persists" is natural speech and signals to the ISP agent to skip their tier-1 restart script.

**Update Software**
- Warning dialog before starting:
  ```
  This update takes about 5 minutes.

  During the update:
  • Your WiFi will turn off
  • All devices will disconnect
  • This page will stop responding

  Your router will restart automatically when done.
  Your devices will reconnect on their own.

  Don't unplug your router during the update.
  ```
- Progress bar shown while update runs
- When router reboots, the page will lose connection — this is expected and normal
- Post-update: when the customer reconnects and returns to the page, show "Your software was updated successfully" if the new version is confirmed

### Language Rules (non-negotiable everywhere in the product)

| ❌ Never use | ✅ Say instead |
|------------|--------------|
| Latency | Lag / delay |
| Throughput | Speed |
| RSSI / dBm | Signal strength (Good / Weak / Poor) |
| WAN | Internet connection |
| Firmware | Software / software update |
| Backhaul | Connection between your nodes |
| DHCP | (never show to customer) |
| Band / frequency | 2.4 GHz or 5 GHz (explain when first used) |
| Ping | Check connection / test |
| DNS | (never show — frame as "looking up website addresses") |
| Child Node | Satellite node |
| MAC address / MAC filter | Device blocklist |
| WPA3 / WPA2 | Security type (only mention if troubleshooting compatibility) |

**Inline alias rule (S-3):** If a technical term must appear anywhere in the UI (headings, check names, settings labels), it must be immediately followed by a plain-language alias in parentheses. Example: "Device Blocklist (prevents specific devices from connecting)". Prefer removing the technical term entirely when possible. The Language Rules table above lists the required substitutions — the inline alias is a last resort when the term is unavoidable.

### Router Light Guide (S-1)

A persistent "What does my router light mean?" help link appears at the top of Tab 0 (and optionally as an inline callout when a WAN failure is detected). On tap, a sheet opens showing the light pattern reference for the customer's router model.

**Content required (new open question — see OQ-6):** Light pattern descriptions for each LED state on the M60. Content to be sourced from the Linksys product team / hardware docs. Do not hardcode; load from a model-specific config.

Format of the light guide sheet:
```
What does my router light mean?

● Solid white      Everything is fine
● Pulsing white    Starting up — wait about a minute
● Solid blue       Your router is in setup mode
● Pulsing blue     Connecting…
● Solid red        No internet — check your cables
● Pulsing red      Router is overheating
● Off              No power — check the power cable
```

When WAN is down (check #2 fails), show the light guide inline as a callout:
```
⚠ No internet connection detected.

  Check your router's light. What color is it?
  [What does my light mean?]  ← opens light guide sheet
```

### Diagnostic Checks (all 12 run automatically)

Listed in display priority order (most severe first):

| # | Check | Customer Label | Action Available |
|---|-------|---------------|-----------------|
| 1 | Gateway ping to 192.168.1.1 | Router reachable | Restart Router |
| 2 | WAN connected | Internet connection detected | Check cables + modem |
| 3 | WAN IP assigned | Internet provider assigned address | Restart Router |
| 4 | DNS resolving | Website addresses loading | Restart Router |
| 5 | Download < 5 Mbps | Internet is very slow | Restart Router |
| 6 | Download < 25 Mbps or < 50% plan | Internet slower than expected | Restart Router |
| 7 | Latency > 100ms | High lag detected | Contact provider |
| 8 | Device signal < -75 dBm OR data rate < 10 Mbps | Satellite nodes or devices with weak signal | Move device / move router |
| 9 | ≥60% on 2.4 GHz AND ≥4 wireless clients | Many devices on slower band | Switch to 5 GHz (instructions) |
| 10 | Mesh backhaul RSSI < -70 dBm | Satellite node weak connection | Move node or use Ethernet |
| 11 | Firmware update available | Software update available | Update Now |
| 12 | Uptime ≥ 30 days | Running a long time without restart | Restart Router |

### Speed Test + Weak WiFi Device Interaction

If the customer's own device has weak WiFi (signal < -75 dBm or data rate < 10 Mbps) and the speed test returns a slow result:

- The **weak device WiFi finding is elevated as a primary finding** ahead of the speed finding
- Speed finding explanation includes: "This speed test runs from your device — your device has a weak WiFi connection, which may be making the reading look lower than your actual internet speed."
- Primary advice: "Fix your device's signal first, then run again"
- "Run Again" button shown after the weak WiFi advice to close the loop

---

## Tab 1: My Devices

### Header
"N devices connected" (total, wireless + wired)

### Sort Order
Issues (Poor → Weak) listed first → then alphabetical within each signal tier

### Device Rows

```
[icon] Deven's iPhone           5 GHz   Good ●
[icon] Samsung TV               2.4 GHz Weak ● ⚠
[icon] Nest Thermostat          2.4 GHz Good ●
[icon] Desktop PC                       [Wired]
```

Signal quality badges:
- **Good** (green): signal ≥ -70 dBm AND data rate ≥ 30 Mbps
- **Weak** (orange): signal -70 to -75 dBm OR data rate 10-30 Mbps
- **Poor** (red): signal < -75 dBm OR data rate < 10 Mbps

### Mesh Grouping (only when mesh network detected)

Devices grouped under the node they're connected to. Nodes are called **"Satellite Node 1", "Satellite Node 2"** etc. (sequential, 1-indexed). No model number shown in the customer-facing label.

```
▶ Main Router  (3 devices)
    Deven's iPhone          5 GHz   Good ●
    Deven's MacBook         5 GHz   Good ●
    Samsung TV              2.4 GHz Weak ● ⚠

▶ Satellite Node 1  (2 devices)
    Nest Thermostat         2.4 GHz Good ●
    Amazon Echo Dot         2.4 GHz Good ●

▶ Satellite Node 2  (0 devices)
    No devices connected
```

Each group is expandable. Groups with issues are expanded by default.

### Guest Device Separation

Guest network devices appear in a separate collapsible group, clearly labeled:

```
▶ Guest Devices  (2 devices)
    Guest Device (Apple)    2.4 GHz Good ●
    Unknown Device          2.4 GHz Good ●
```

Guest devices are identified by their SSID association from `GetNodesWirelessNetworkConnections`. This prevents customers from seeing unfamiliar devices and worrying their network is compromised.

### Device Detail Sheet (tap a device)

**Wireless device:**
- Device name + type icon
- "Connected to Satellite Node 1 on 5 GHz" or "Connected to router on 2.4 GHz"
- Signal: plain-language description + colored bar
- Tailored advice:
  - **Poor signal:** "Move this device closer to your router, or move your router to a more central location."
  - **On 2.4 GHz:** "Connect to the 5 GHz network for faster speeds — it has the same name and password."
  - **Slow data rate (not signal):** "Thick walls, metal objects, or appliances may be blocking the signal between this device and your router."
  - **Good:** "This device has a strong WiFi connection."

**Wired device:**
- Device name + cable icon
- "Connected by Ethernet cable"
- If customer taps for help: basic path shown:
  ```
  □ Check that the Ethernet cable is firmly plugged in at both ends
  □ Try a different cable if available
  □ Try a different port on your router
  [Restart Router] if still not working
  ```

---

## Tab 2: My Network

### Section 1: Internet Connection (always shown)
- Status: Connected ✓ / Not Connected ✗
- Connection type: Cable / Fiber / DSL
- IP: Partially masked (last 2 octets shown — e.g., `*.*.12.45`)
- If disconnected → Restart Router button

### Section 2: Your Router (always shown)
- Model name (from GetDeviceInfo)
- Software: "Up to date" or "Update available" + button
- Running time: **only shown if ≥ 30 days** — displayed as "Running for N days — a restart may help" with Restart button. Below 30 days: omit entirely.

### Section 3: Your Satellite Nodes (only when isMeshNetwork)

Nodes labeled as "Satellite Node 1", "Satellite Node 2", etc.

Each node card:
```
┌────────────────────────────────────┐
│ ● Satellite Node 1                 │
│   Connected wirelessly   Weak ⚠   │
│   3 devices connected              │
│                                    │
│   ⚠ This node has a weak          │
│   connection to your router.       │
│   [Move it closer or use Ethernet] │
└────────────────────────────────────┘
```

Backhaul quality:
- **Good:** RSSI ≥ -70 dBm
- **Weak:** RSSI < -70 dBm → show warning + advice
- **Wired:** "Connected by Ethernet" — no signal rating needed

### Section 4: WiFi Overview (always shown)
- "N devices on 2.4 GHz (slower, longer range)"
- "N devices on 5 GHz (faster, shorter range)"
- If overcrowded (≥60% on 2.4 GHz, ≥4 wireless clients):
  > "Many of your devices are on the slower 2.4 GHz band. Connect fast devices like phones and laptops to the 5 GHz network for better speeds."

### Section 5: Guest Network

**When guest network is ON:**
```
┌────────────────────────────────────┐
│ Guest Network          On  ●───○  │
│ 2 guest devices connected          │
└────────────────────────────────────┘
```
- Toggle calls `SetGuestNetworkSettings`
- Turning off shows confirmation: "This will disconnect your guests. Continue?"
- **Cross-page impact:** ⚠️ Guest Network settings page must reflect this change

**When guest network is OFF:**
```
┌────────────────────────────────────┐
│ Guest Network          Off  ○───● │
└────────────────────────────────────┘
```
- Minimal display — toggle only, no device count
- Turning on: no confirmation needed

---

## Tab 3: Help Me Fix It

### Landing: Flow Selection Cards

```
┌──────────────────────┐  ┌──────────────────────┐
│  🌐                  │  │  🐢                  │
│  My internet         │  │  My internet         │
│  isn't working       │  │  is slow             │
└──────────────────────┘  └──────────────────────┘
┌──────────────────────┐  ┌──────────────────────┐
│  📶                  │  │  🏠                  │
│  Device              │  │  WiFi doesn't        │
│  connectivity        │  │  reach a room        │
│  issues              │  │                      │
└──────────────────────┘  └──────────────────────┘
┌──────────────────────┐
│  🔄                  │
│  My connection       │
│  keeps cutting out   │
└──────────────────────┘
```

---

### Flow 1: My internet isn't working

**Step 1 — One box or two?**

```
How is your home set up?

(•) I have two boxes — a modem from my provider AND a Linksys router
( ) I only have one box — my Linksys router is the only device
```

Visual aid: Show two simple illustrations side by side — one showing two separate physical boxes with a cable between them (labeled "Box from your internet company" and "Linksys Router"), one showing a single Linksys box alone. Caption: "Not sure? Look at the devices plugged into your wall — if you have two separate boxes, pick the first option." (S-2: visual aid for box identification)

- Two boxes → Step 2a (modem check)
- One box → Skip to Step 3 (ISP contact — the router IS the modem/gateway)

**Step 2a — Check your modem**
```
□ The box from your internet company (like Comcast, Spectrum,
  or AT&T) is powered on — look for a power light on the front
□ The cable between that box and your Linksys router is
  firmly plugged in at both ends

[Try restarting your router] ← auto-fix button
```

**Step 2b — Checking your connection** *(auto-runs DNS test, or after restart)*
```
⟳ Checking if websites are loading…   → ✓ Connected  |  ✗ Still not loading
```

**Step 3 — Still not working?**
```
Since restarting didn't fix it, the issue is likely
outside your router.

Call your internet provider (the company you pay for
internet — like Comcast, Spectrum, or AT&T) and say:
"My router shows it's connected, but websites won't load.
I restarted my router but the problem persists."

[Done — my internet is working now]
```

---

### Flow 2: My internet is slow

**Step 1 — Run a speed test**
```
[Check my speed]  ← triggers inline browser speed test (~20 seconds)
```

If the test device has weak WiFi, show before the result:
```
⚠ Your device has a weak WiFi connection.
  This reading may be lower than your actual internet speed.
  Move closer to your router, then run again.
  [Run Again]
```

**Step 2 — Your speed result** (shown when device WiFi is good)

Display the Mbps number AND the plain-language context together — both are shown (S-4):

```
Your speed: 18 Mbps
Basic browsing and streaming for 1–2 people

Speed can vary based on time of day, how many devices
are active, and your distance from the router.

┌─────────────────────────────────────────────────────┐
│ Speed         What it handles                        │
│ < 5 Mbps      Barely enough for one video call       │
│ 5–25 Mbps   ▶ Basic browsing and streaming for 1–2  │
│ 25–100 Mbps   Good for most households               │
│ 100+ Mbps     Fast — handles many devices at once    │
└─────────────────────────────────────────────────────┘
```

The active tier is highlighted. Customers who want the number can see it; customers who want meaning can read the label. Neither is hidden. The variance note prevents distrust when the result is lower than a customer's plan speed — they understand why before asking "why is this wrong?"

- If slow: "Try restarting your router." [Restart button]
- If normal but still feels slow: → Step 3

**Step 3 — Is it all devices or just one?**
- [All devices slow] → [Restart Router] then re-run speed test
  - If still slow after restart:
    ```
    Since restarting didn't fix it, the issue is likely
    outside your router.

    Call your internet provider and say:
    "My internet is slower than what I'm paying for.
    My speed test shows [X] Mbps. I restarted my router
    but the problem persists."

    [I'll call my provider]
    ```
- [Just one device] → "Go to My Devices and tap that device for specific help." [Link → Tab 1, scrolled to that device]

---

### Flow 3: Device connectivity issues
*(Covers both "a device won't connect" AND "a device keeps dropping off WiFi")*

**Step 1 — What kind of device is it?**
```
( ) Phone or tablet
( ) Laptop or computer
( ) Smart home device (thermostat, camera, smart bulb, speaker)
( ) Gaming console or TV
( ) Something else
```

This replaces the known/new device picker (which was often empty for devices that had dropped off). Device type drives the advice branch.

**Path A — Phone, tablet, laptop, computer, gaming console, TV:**
```
Network name: [SSID from router]
Password:     [WiFi password from GetWirelessSettings]

□ Make sure you're selecting the right network name above
□ Check that caps lock is off when entering the password
□ Try forgetting the network on your device and reconnecting

[Check for connection blockers] ← auto-checks MAC filter (device blocklist)
```

If device blocklist (MAC filter) is ON:
```
ℹ Your router has a device blocklist turned on.
  This is a setting that controls which devices are
  allowed to connect — it may be blocking this device.

  Turning it off lets any device join using your WiFi
  password. Your password is still required — this just
  removes the extra approval step.

  [Turn off blocklist]  |  [Leave it on — I'll check the list]
```
- **Cross-page impact:** ⚠️ MAC Filter / Access Control settings page must reflect this change

If still failing after blocklist check:
```
[Try restarting your router]
```

**Path B — Smart home device (thermostat, camera, smart bulb, speaker):**

These devices commonly have two issues: they only support 2.4 GHz, and they may not support newer security types.

```
□ Make sure your phone is connected to the same WiFi network
  you want the device on — not a guest network

□ Use the 2.4 GHz network if your router has separate network names
  for 2.4 and 5 GHz

Network name: [SSID — 2.4 GHz band if identifiable, or main SSID]
Password:     [WiFi password]
```

If security compatibility may be an issue (WPA3-only mode detected):
```
ℹ Some older smart home devices don't support the latest
  WiFi security standard. If this device keeps failing:

  Go to My Network → WiFi Security and check if "WPA2 compatibility"
  is enabled. [Link → relevant settings page]
```

---

### Flow 4: WiFi doesn't reach a room

**Step 1 — Where is your router right now?**
```
( ) Center of my home or close to it
( ) Near a wall, door, or in a corner
( ) Inside a closet, cabinet, or behind the TV
```

**Step 2 — Advice based on placement**
- *Closet/cabinet:* "Move your router out into the open. Enclosures block WiFi signals significantly — even a shelf in the open can double your range."
- *Corner/door:* "Move your router toward the center of your home — halfway between the router and the room with weak signal."
- *Central:* "Your placement is good. The issue may be building materials (concrete, brick, or metal studs between rooms)."

**Step 3 — Quick tips**
```
✓ Keep your router elevated (shelf or table, not the floor)
✓ Point antennas vertically if your router has them
✓ Keep it away from microwaves, baby monitors, and cordless phones
✓ Don't put it inside a cabinet, closet, or entertainment unit
```

**Step 4 — If you're in an apartment or building with many neighbors**
```
ℹ If you live in an apartment building or dense area, interference
  from neighboring WiFi networks can cause weak signal — even with
  perfect placement. This is common and hard to fix without changing
  your router's WiFi channel, which requires a software update
  to support. (This feature is on our roadmap.)
```

**Step 5 — Need more coverage?**
```
Adding a Linksys satellite node in that room extends your WiFi
coverage using the same network name and password — your devices
connect automatically.
```

---

### Flow 5: My connection keeps cutting out

**Step 1a — How often does it drop?**
```
( ) Every few minutes
( ) A few times a day
```

**Step 1b — Is it everything or specific devices?**
```
( ) My whole internet goes out — all devices stop working at once
( ) Just specific devices lose connection (phone, camera, smart bulb, etc.)
```

If **specific devices** → skip the monitoring test entirely:
```
This sounds like a device issue rather than a
whole-network problem.

[Go to Device connectivity issues →]
```

If **whole internet** → continue to Step 2.

**Step 2 — Run a connection test**
```
[Start 2-minute connection test]

⟳ Monitoring your connection…

→ "No drops detected in 2 minutes. The issue may be intermittent."
→ "X drops detected in 2 minutes."
```

**Step 3 — Based on result + frequency:**

*Drops detected OR every few minutes:*
```
Restarting your router clears up most drop issues.
[Restart Router]
```

After restart → run connection test again:
- No more drops → "Looks like the restart fixed it. Run the test again any time." [Done]
- Still dropping → ISP contact (customer already confirmed this is whole-network in Step 1b):
  ```
  Since restarting didn't fix it, the issue is likely
  outside your router.

  Call your internet provider and say:
  "My connection drops [several times a day / every few
  minutes]. I restarted my router but the problem persists."

  [I'll call my provider]
  ```

*No drops detected, happens a few times a day:*
```
No drops were detected during this 2-minute test.
Intermittent drops are hard to catch in a short test.

Try these steps:
□ Restart your router — this fixes most intermittent drop issues
□ Check if the drops happen at a specific time of day
  (heavy usage periods like evenings can cause congestion)

[Restart Router]

If drops continue, call your internet provider and say:
"My connection drops several times a day. I restarted
my router but the problem persists."
```

---

## What This Removes (vs. Previous Design)

| Removed | Reason |
|---------|--------|
| Support agent login + agent dashboard | Out of scope for Phase 1 |
| CRM copy button / call reference | Agent feature |
| Callback risk score | Agent feature |
| Ookla speed test widget | Agent feature (external, requires licensing) |
| Debug log export | Agent feature |
| Raw per-client dBm numbers | No customer action path |
| CPU% / memory% stats | No customer action path |
| DHCP pool utilization % | No customer action path |
| All 6 agent diagnostic flows | Agent feature |
| Ping output / traceroute output (raw) | No customer action path |
| Router uptime below 30 days | Not actionable below threshold |
| Model number in satellite node label | Technical jargon — simplified to "Satellite Node N" |

---

## Decisions Log

| # | Decision | Rationale |
|---|----------|-----------|
| D-1 | Agent mode dropped entirely (Phase 1) | Customer self-help is the Phase 1 focus |
| D-2 | Tab 0 auto-runs on page load | Faster; customer doesn't need to understand what's happening |
| D-3 | Tab names: Instant-Test / My Devices / My Network / Help Me Fix It | Customer-language names confirmed by Deven |
| D-4 | Guest network: full toggle (on/off) | Router auth available; cross-page impact flagged for future dev |
| D-5 | WiFi password displayed in flows | Router auth available; reduces friction for reconnecting |
| D-6 | MAC filter (device blocklist): full toggle with security warning | Customer deserves the control; warning added; cross-page impact flagged |
| D-7 | Satellite nodes labeled "Satellite Node 1/2/3" — no model number | Model number is jargon; simple sequential name is clearer to customers |
| D-8 | Weak-WiFi device + slow speed test: elevate weak WiFi as primary finding | Prevents false "slow internet" verdict when root cause is device placement |
| D-9 | 5 flows in Help Me Fix It (added: "connection keeps cutting out") | Drops are 3rd most common support call; no path existed |
| D-10 | Device picker replaced with device-type question | DHCP table only has connected devices; picker was often empty for the exact problem case |
| D-11 | Router uptime only shown when ≥ 30 days | Below threshold it's not actionable — adds noise |
| D-12 | Firmware update: explicit disconnect warning with reconnect guidance | Customer's page goes dead during update; must set expectations |
| D-13 | "One box or two?" question added to internet-not-working flow | Many customers have ISP combo units and can't identify a "modem" |
| D-14 | Speed result shows usage context, not just Mbps | Customers don't know if their plan speed is good or bad |
| D-15 | IoT/smart home device path in won't-connect flow | 2.4 GHz-only and WPA2-only devices are a very common failure mode |
| D-16 | Tab 0 all-clear state redesigned: "We didn't detect any issues — what are you running into?" with flow cards | All-clear was a dead end; customers still have problems the tool didn't detect; proactive handoff to Help Me Fix It flows removes the need to find the right tab |
| D-17 | Per-check progressive disclosure (tappable detail expansions, no mode toggle) | Satisfies curious/technical users without cluttering the view for non-technical ones; one detail open at a time keeps it focused |
| D-18 | Visual aid added to "one box or two?" step in Flow 1 | Non-technical customers (Margaret persona) cannot identify a modem from a description; illustration removes the ambiguity |
| D-19 | Speed result shows Mbps number AND plain-language label together | Customers who want the number and customers who want meaning should both be served; neither is hidden |
| D-20 | Router light guide added as persistent reference + inline WAN callout | Light color is the first thing a non-technical customer checks; without a guide, it means nothing; must be model-specific from product team content |
| D-21 | Inline alias rule: technical terms get plain-language alias in parentheses if unavoidable | Some terms (like 2.4 GHz) must appear; the alias prevents the customer from stopping at an unfamiliar word |
| D-22 | IoT/smart home intermittent drops: dedicated branch in Flow 5 "only on one device" path | Smart home device drops have a different root cause (2.4 GHz + WPA2 compatibility) than phone/laptop drops; mixing the paths gives the wrong advice |
| D-23 | Restart countdown: add "Don't worry — this is normal. Your devices will reconnect on their own." | Multiple personas stopped at the restart confirmation because the disconnect warning read as scary; reassurance must be shown during the countdown, not just in the confirm dialog |
| D-24 | Flow 3 renamed "Device connectivity issues" — covers both won't-connect AND keeps-dropping | "A device won't connect" title caused customers with dropping devices to skip this flow; generic title captures both scenarios |
| D-25 | Tab 0 is intentionally a point-in-time snapshot — no historical drop/event data in Phase 1 | Temporal network history requires persistent event logging not available via JNAP; Tab 0 solves "is something wrong right now"; the all-clear + flow cards handoff is the path for intermittent issues; roadmap item for future phase |
| D-26 | Tab 0: after Check Again, if same finding persists — swap [Restart Router] to ISP contact or Linksys support | A second restart would be redundant; if the problem survived a restart it's no longer a router-state issue — escalation is the right next step |
| D-27 | Flow 2: ISP script uses speed-specific language — "slower than what I'm paying for, X Mbps" | The generic "websites won't load" script was wrong for a slow-speed complaint; ISP agents need the right symptom description to act |
| D-28 | Flow 5: after restart → still dropping, ask "everything or specific devices?" before ISP handoff | Catches Flow 3 mis-entries at exit: customers who landed in Flow 5 for device-specific drops get redirected to the right path rather than receiving an ISP contact script that won't help them |
| D-29 | Flow 2 ISP script and Flow 5 ISP script both include "I already restarted my router" | Prevents ISP agent from suggesting a restart as first step, reducing call handle time and customer frustration |
| D-30 | Flow 5 Step 1 split into 1a (frequency) + 1b (scope: whole internet vs. specific devices) | Customers answer frequency naturally but scope is what determines the fix path; asking scope upfront redirects device-specific drops to Flow 3 before the 2-minute test runs, eliminating a dead-end test for the wrong problem |
| D-31 | All ISP escalations prefixed with "Since restarting didn't fix it, the issue is likely outside your router" | Prevents customers feeling abandoned mid-flow; explains why the tool is escalating rather than just stopping |
| D-32 | ISP script phrasing changed from "I already restarted my router" to "I restarted my router but the problem persists" | Natural speech pattern; "already" reads as defensive, "but the problem persists" is informative and signals urgency to ISP agent |
| D-33 | Speed result adds variance note: "Speed can vary based on time of day, how many devices are active, and your distance from the router" | Prevents distrust when result is lower than plan speed — customer understands why before concluding the tool is wrong |
| D-34 | Flow 3 blocklist warning rewritten: explains what the setting does, clarifies password is still required, changes ⚠ to ℹ | Original warning with two ⚠ icons read as dangerous; Priya persona stopped here every round; new copy explains the security model plainly so customer can make an informed choice |

---

## JNAP Feasibility Map

| Feature | JNAP Source | Available on M60? |
|---------|------------|------------------|
| Diagnostics: WAN status | `GetWANStatus` | ✅ Yes |
| Diagnostics: firmware update | `GetFirmwareUpdateStatus` | ✅ Yes |
| Diagnostics: uptime | `GetSystemStats` | ✅ Yes |
| Device list with names | `GetDevices3` + `GetNodesWirelessNetworkConnections` | ✅ Yes |
| Per-device signal + data rate | `GetNodesWirelessNetworkConnections` | ✅ Yes |
| Guest device identification | `GetNodesWirelessNetworkConnections` (SSID field) | ✅ Yes |
| Mesh node list | `GetDevices3` (nodeType field) | ✅ Yes |
| Mesh backhaul quality | `GetBackhaulInfo` | ✅ Yes |
| Band distribution | `GetNodesWirelessNetworkConnections` (band field) | ✅ Yes |
| Guest network status | `GetGuestNetworkSettings` | ✅ Yes |
| Guest network toggle | `SetGuestNetworkSettings` | ❓ Needs verification on M60 |
| Router model/firmware | `GetDeviceInfo` | ✅ Yes |
| Restart router | `router/Reboot` | ✅ Yes |
| Firmware update trigger | `UpdateFirmwareNow` | ✅ Yes |
| MAC filter (device blocklist) status | `GetMACAddressFilterSettings` | ✅ Yes |
| MAC filter toggle | `SetMACAddressFilterSettings` | ❓ Needs verification on M60 |
| WiFi password (read) | `GetWirelessSettings` | ❓ Needs verification — may require specific auth scope |
| WPA3/security mode read | `GetNetworkSecuritySettings` | ✅ Yes |
| 2-minute connection monitor | Browser ping loop (existing `BrowserDiagnosticService`) | ✅ Yes |
| WiFi channel / SNR data | `GetSelectedChannels` | ❌ `_ErrorUnknownAction` on M60 — USP roadmap |
| Per-client error rates | No JNAP action available | ❌ USP roadmap item |
| Channel auto-switch (apartment interference fix) | No JNAP action available | ❌ USP roadmap item |
| Router LED state (light color) | No JNAP action identified | ❓ OQ-6 — may need firmware team support |
| Historical disconnect/drop events | No JNAP history log available | ❌ Roadmap — Tab 0 is intentionally point-in-time for Phase 1 |

---

## Open Questions (Remaining)

| # | Question | Owner | Status |
|---|----------|-------|--------|
| OQ-1 | Does `SetGuestNetworkSettings` work on M60 without errors? | Austin / FW team | 🔲 Open |
| OQ-2 | Does `SetMACAddressFilterSettings` work on M60? | Austin / FW team | 🔲 Open |
| OQ-3 | Does `GetWirelessSettings` return the WiFi password in the authenticated PrivacyGUI context? | Austin / FW team | 🔲 Open |
| OQ-4 | Can we identify guest devices by SSID from `GetNodesWirelessNetworkConnections`? What field? | Austin / codebase | 🔲 Open |
| OQ-5 | Does `GetNetworkSecuritySettings` return the WPA mode (WPA2/WPA3) so we can detect compatibility issues? | Austin / codebase | 🔲 Open |
| OQ-6 | What are the LED light patterns and meanings for the M60? Can we read the current LED state via JNAP, or is the light guide a static content resource by model? | Product team / FW team | 🔲 Open |

---

## Implementation Notes (READ ONLY — no building until PRD approved)

- **Tab 0 (Instant-Test):** ~80% done. Changes: (1) Replace all-clear "12 checks passed" state with "what are you running into?" + flow cards. (2) Add tappable per-check progressive disclosure with detail expansions. (3) Add restart countdown reassurance copy. (4) Add "what does my light mean?" persistent link + WAN-down inline callout. (5) Add "Run Again" + "Check again" post-restart CTA. (6) Update firmware checklist item to 3-state. (7) Add weak-WiFi elevation logic to VerdictEngine.
- **Tab 1 (My Devices):** New widget. Node labels: "Satellite Node N". Guest device group separate. Wired device detail sheet with cable-check steps.
- **Tab 2 (My Network):** New widget. Uptime gated to ≥30 days. Guest network minimal off state.
- **Tab 3 (Help Me Fix It):** New widget. 5 flows. Flow 1: visual aid for box identification. Flow 2: speed result shows Mbps + tier label together. Flow 3: device-type picker, IoT path. Flow 5: smart home device intermittent drops branch added to "only one device" path.
- **Tab name change:** `['Instant-Test', 'My Devices', 'My Network', 'Help Me Fix It']`
- **Router light guide:** Static content resource keyed by model number. Requires content from product team (OQ-6). Do not build until content is supplied.
- **New JNAP questions to verify (OQ-1 through OQ-6):** Block writing of guest toggle, MAC filter toggle, WiFi password display, guest device grouping, WPA3 compatibility check, and LED state read until verified.
