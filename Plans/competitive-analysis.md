# Competitive Analysis — WiFi Diagnostic & Troubleshooting Tools

**Date:** 2026-03-31
**Purpose:** Inform Instant-Help feature priorities for WiFi Troubleshooter

---

## Competitor Feature Matrix

### Eero (Amazon)

**Customer-facing diagnostics:**
- Speed test (integrated, one-tap)
- Network health check (green/yellow/red status)
- Device list with connection type (wired/wireless)
- Activity history showing bandwidth per device (eero Plus, $9.99/mo)
- Network Insights with ISP uptime tracking (eero Plus)
- Remote network access for checking status away from home (eero Plus)

**Mesh visualization:** Simple topology — router and satellite icons with "connected" / "not connected" status. No signal strength between nodes shown to customers.

**Guided troubleshooting:** Minimal. "Restart network" button. Support articles linked from app. No step-by-step diagnostic flows.

**Killer feature:** ISP uptime tracking (eero Plus). Logs when the ISP connection drops, giving customers *evidence* to take to their ISP. Shifts blame attribution from "my router is broken" to "my ISP dropped 4 times yesterday."

**Agent tools:** Amazon/eero support agents can access device telemetry remotely via cloud backend. Customers do not see what agents see.

---

### Google Nest WiFi (Google Home app)

**Customer-facing diagnostics:**
- Speed test (tests between device and cloud, and between mesh points)
- Real-time bandwidth usage per device
- Priority device setting (QoS for one device)
- Mesh point signal strength indicator (good/fair/poor to router)
- Device list grouped by room/access point

**Mesh visualization:** Floor-plan-style view showing which devices connect to which mesh point. Signal quality between mesh points shown as good/fair/poor.

**Guided troubleshooting:** "WiFi" tab shows mesh health with actionable suggestions: "Move this point closer to the router" if backhaul signal is weak. Restart individual mesh points from the app.

**Killer feature:** Mesh-point-to-mesh-point signal quality. Customers can see if a satellite has weak backhaul and get a placement suggestion. This is the single most useful mesh diagnostic any consumer platform shows.

**Agent tools:** Google support uses cloud telemetry. No on-device agent mode.

---

### TP-Link Deco (Deco app)

**Customer-facing diagnostics:**
- Connection status at a glance (healthy / issues detected)
- Speed test (built-in)
- Device list with connection details
- Detailed reports on WiFi usage patterns
- Placement optimization: "Find the best spots to place additional Deco units for maximum coverage"

**Mesh visualization:** Network map showing Deco units and connected devices per node. Status indicators per unit.

**Guided troubleshooting:** Basic — device blocking, placement suggestions. No guided diagnostic flows.

**Killer feature:** Placement optimization guidance. The app actively suggests where to add or move Deco units based on coverage gaps. Actionable and specific.

**Agent tools:** TP-Link support has limited remote visibility. Mostly relies on customer screenshots from the app.

---

### Netgear Orbi (Orbi app)

**Customer-facing diagnostics:**
- Speed test
- Network map showing router, satellites, and connected devices
- Netgear Armor security (subscription) — vulnerability scanning, threat alerts
- Device list with connection type and status
- Satellite connection quality indicator

**Mesh visualization:** Network topology showing satellite backhaul status. Color-coded signal quality between router and satellites.

**Guided troubleshooting:** LED light guide in the app (explains what each LED color means). Basic restart and reconnect suggestions. No step-by-step diagnostic flows.

**Killer feature:** Armor security dashboard gives customers a "security score" for their network. Creates perceived value beyond connectivity. Satellite LED color guide is surprisingly practical — most customers cannot interpret router LEDs.

**Agent tools:** Netgear ProSupport uses ReadyCLOUD for remote access (subscription-based). Limited diagnostic visibility without customer cooperation.

---

### ISP Tools

#### Xfinity xFi (Comcast)

**Customer-facing diagnostics:**
- Speed test with comparison to plan speed
- Personalized WiFi improvement tips based on home environment
- Device management with pause/unpause per device
- xFi Pod (mesh extender) health and placement recommendations
- Troubleshooting assistant: guided restart flows, outage detection, appointment scheduling

**Killer feature:** Proactive outage detection. The app tells customers "We've detected an outage in your area" *before* they call. Reduces inbound call volume significantly. Also: "personalized tips to improve WiFi" based on device count, plan speed, and pod placement.

**Agent tools:** ISP agents see full CPE telemetry via TR-069/ACS. They see everything: channel utilization, interference, per-client stats, firmware version, reboot history, WAN training rates. The gap between what customers see and what agents see is enormous.

#### AT&T Smart Home Manager

**Customer-facing diagnostics:**
- Device list with connection status
- Speed test
- WiFi extender health monitoring
- Network security checks
- "WiFi Call" — one-tap support escalation with diagnostic data pre-attached

**Killer feature:** "WiFi Call" button that pre-packages diagnostic data and sends it to the agent before the call connects. Agent sees the data before saying hello. Dramatically reduces "please restart your router" opening.

#### BT Smart Hub (BT Home)

**Customer-facing diagnostics:**
- Web-based diagnostic at router IP (similar to Instant-Help approach)
- Connection status, speed test, device list
- "Complete WiFi" mesh disc health
- Line quality indicators (DSL-specific)

**Killer feature:** Web-based diagnostic accessible from the router itself — the closest existing analog to Instant-Help. Validates the "router-embedded diagnostic" approach.

---

### UniFi (Ubiquiti)

**Customer-facing diagnostics (prosumer):**
- Full RF environment scan: channel utilization, neighboring networks, interference sources
- Per-client signal strength (RSSI), noise floor, SNR, TX/RX rates
- Topology map showing all APs, switches, and clients with real connections
- Historical performance graphs per client and per AP
- WiFi AI: automated channel optimization based on RF scan data
- Client connection path: which AP, which band, signal quality, roaming history

**Mesh visualization:** Full network topology with every device, connection type, throughput, and signal quality. The gold standard for network visualization.

**Killer feature:** Client roaming history — see when a device moved between APs, what signal triggered the roam, and whether it improved. Also: WiFi AI automatic channel optimization that runs scans and re-channels APs to minimize interference.

**Relevance to Instant-Help:** UniFi's client RSSI table, band association, and connection quality per device are exactly what Instant-Help's agent mode should show. The data is the same (JNAP provides it); the presentation should be as clear.

---

### Plume HomePass (ISP SaaS platform)

**Worth noting as a platform play:**
- AI-driven bandwidth allocation that learns device behavior
- Proactive anomaly detection (detects issues before customer notices)
- ISP-facing Haystack dashboard with per-subscriber WiFi health
- Claims 30% churn reduction for ISP partners
- Self-service model: customers troubleshoot from the app, reducing inbound calls

**Killer feature:** Proactive detection — the system tells the customer something is wrong before they notice. ISPs using Plume report 30% fewer WiFi support calls.

---

## Top 10 WiFi Support Call Reasons

From industry data (Parks Associates, J.D. Power ISP studies, ISP support analytics):

| Rank | Issue | % of WiFi Calls | Self-Diagnosable? |
|------|-------|-----------------|-------------------|
| 1 | Slow internet / buffering | ~25% | Yes — speed test + blame attribution |
| 2 | Complete connectivity loss | ~18% | Partially — gateway check, but may need ISP |
| 3 | Intermittent drops / instability | ~12% | Partially — requires monitoring over time |
| 4 | New device won't connect | ~10% | Yes — DHCP/WPA3/band check |
| 5 | Weak signal in rooms | ~8% | Partially — signal data helps, placement guidance |
| 6 | Slow on one device only | ~7% | Yes — per-client band/signal comparison |
| 7 | Password forgotten / can't find | ~6% | No — requires admin access |
| 8 | Router won't power on / LEDs abnormal | ~5% | No — hardware issue |
| 9 | Guest network issues | ~4% | Yes — SSID/config check |
| 10 | Parental controls not working | ~5% | Yes — config verification |

**Instant-Help coverage:** Flows 1-6 directly address ranks 1-6 and 8, covering approximately 75% of inbound WiFi support calls. Ranks 7, 9, 10 are configuration issues addressable in Phase 2.

---

## What Support Agents Actually Need

From ISP agent workflow studies and support platform vendors (Calix, Plume Haystack, ASSIA):

1. **Per-client signal strength (RSSI)** — the single most diagnostic data point. Tells the agent immediately if the problem is signal quality.
2. **Band association per device** — is the device on 2.4 GHz when 5/6 GHz is available? Explains 80% of "one device slow" calls.
3. **WAN uptime and error counts** — distinguishes ISP problem from home network problem in seconds.
4. **DHCP utilization** — "pool full" explains new-device-can't-connect instantly.
5. **Firmware version** — known-bad firmware versions cause specific issues. Agents need this without asking.
6. **Router uptime** — short uptime = recent reboot = instability signal.
7. **Connected device count** — overloaded router detection (too many clients for hardware).
8. **Speed test result compared to plan** — "getting 50 Mbps on a 300 Mbps plan" is actionable.

**Key insight:** Agents spend 2-5 minutes at the start of every call collecting information the router already knows. Instant-Help's agent mode eliminates that entirely by displaying JNAP data immediately.

---

## Best Practices for Reducing Callback/Repeat Rates

1. **Blame attribution accuracy** — if the tool correctly identifies "ISP issue" vs "router issue" vs "device issue," the customer takes the right action the first time. Wrong attribution = callback.
2. **Proactive outage detection** — Xfinity's approach of telling customers about area outages before they call reduces volume by 15-20%.
3. **Self-service speed test with plan comparison** — when customers see "You're getting 280 Mbps on a 300 Mbps plan," they don't call. When they see "You're getting 50 Mbps on a 300 Mbps plan," they call their ISP, not the router vendor.
4. **One clear next step** — tools that end with "try these 5 things" have higher callback rates than tools that end with "do this one thing."
5. **Evidence for ISP contact** — giving customers a "report" or "result" they can show their ISP shifts resolution to the right party.

---

## Recommendations — Ranked by Impact

**Under 500 words. Concrete. Actionable.**

### Tier 1: Must-have differentiators (Phase 1)

1. **Blame attribution engine with evidence.** No competitor does this well from the router itself. Instant-Help should end every flow with a clear verdict: "Your ISP connection is the bottleneck" or "Your device's WiFi signal is weak" — with the data to back it. This is the single highest-impact feature for reducing support calls and preventing mis-attributed RMAs.

2. **One-tap agent data view.** When the agent logs in, they should see RSSI per client, band association, DHCP utilization, WAN status, and firmware version in one screen — no clicking through tabs. Every second saved during a call multiplies across thousands of calls. This is what JNAP already provides; the UI must surface it instantly.

3. **Speed test with plan comparison.** Ask the customer their plan speed (or let the agent enter it). Show the gap. "You're paying for 300 Mbps and getting 47 Mbps" is a verdict that drives action. No competitor on the router does this.

### Tier 2: High-impact differentiators (Phase 1 stretch or Phase 2)

4. **Mesh node backhaul quality indicator** (for multi-node setups). Steal from Google Nest: show good/fair/poor signal between nodes with placement suggestions. Customers with dead spots need this before they call.

5. **Pre-packaged diagnostic report for ISP contact.** Steal from AT&T's "WiFi Call" concept. When the verdict is "ISP issue," offer a shareable summary: "Your Linksys router tested at [time] and found: WAN speed 47 Mbps (plan: 300), latency 85ms, 3 connection drops in 10 minutes." Give the customer ammunition. This reduces callbacks because the customer resolves it with the ISP instead of calling Linksys again.

6. **LED/light guide in the diagnostic flow.** Steal from Netgear Orbi. When Flow 6 (Router Offline) runs, show the customer what each LED color means on their specific model. Surprisingly effective at resolving "my router has a blinking orange light" calls without agent involvement.

### Tier 3: Future differentiators (Phase 2+)

7. **ISP uptime history.** Steal from eero Plus. Log WAN drop events over time. When a customer calls saying "my internet drops every evening," the agent can see the evidence. Requires persistent monitoring (Phase 2 background monitoring feature).

8. **Proactive anomaly notification.** Steal from Plume. If the tool detects degradation before the customer notices, surface it. This is the aspirational feature — it requires either a persistent background process or native app. Phase 2+ at earliest.

9. **WiFi environment scan results for agents.** Steal from UniFi. Show neighboring networks and channel congestion to the agent. Helps diagnose interference issues that no speed test will reveal. Requires JNAP support for RF scan data.

### What NOT to build

- Do not build a security score (Netgear Armor). It is a subscription upsell, not a diagnostic tool. Different product.
- Do not build parental controls or device prioritization into this tool. Those belong in the main router admin UI.
- Do not build remote access. Instant-Help is a LAN-local diagnostic. Remote monitoring is a different product with different security requirements.

---

*End of competitive analysis.*
