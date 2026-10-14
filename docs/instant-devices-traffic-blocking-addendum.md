# Instant Devices: persistent traffic blocking addendum

Status: feasibility investigation, 2026-10-14. This is a follow-on to the
Instant Devices removal feature, not a dependency of its release. No traffic
blocking API, enforcement package, firmware build, or customer enablement is
implemented by this addendum.

## Release boundary

The current GUI feature at runtime commit `bd77429885da38be2c8c56617b6717d0609636ea`
continues independently:

- **Remove** saves the MAC admission restriction and requests deauthentication.
- **Restore access** reverses the MAC restriction while preserving other rules.
- **Offline** describes connection status; being away is not an access restriction.
- **Blocked / Removed devices** appears beneath Offline only when the router's
  MAC access policy identifies restricted devices. Removing the final
  restriction hides it and returns to Offline.
- **Block** remains disabled and marked **Coming soon**.

The current 82 targeted Flutter tests, web build, and base-matched analyzer
result apply to that GUI implementation. Publication/review/CI, the existing
GUI's router acceptance, and translations remain its own work. No Block API,
firmware prototype, Block hardware qualification, or companion PR becomes a
new gate for shipping it. Future enforcement work belongs in separate firmware
branches and PRs; only this document accompanies the GUI change.

Relevant current code: [action menu](../lib/page/instant_device/views/client_action_menu.dart),
[removal and restoration](../lib/page/instant_device/providers/client_removal_provider.dart),
and [restricted-device enumeration](../lib/page/instant_device/providers/client_access_policy_provider.dart).

## Follow-on behavior

**Block** should stop the selected WiFi client's application traffic in both
directions while retaining its authentication and association. It must cover
Internet access, local peers, and access to the router itself, for IPv4 and
IPv6, including sessions already active at the transition. Authentication and
necessary WiFi management/control exchanges must remain possible. This is not
a promise of radio silence or suppression of every shared broadcast frame;
group traffic delivery needs explicit validation on the chosen backend.

**Unblock** removes only the traffic restriction and restores normal traffic
without forcing reconnection. It must not override a separate MAC admission
restriction. A device may be online and blocked, offline with a saved block,
or both removed and traffic-blocked. Display the actual restriction and use
separate recovery actions when both apply; do not infer enforcement from an
Offline label or from a saved policy bit alone.

Initial feasibility scope matches the existing menu: WiFi clients on Pinnacle
M60/M62. Wired-client enforcement is a separate extension. MAC-based policies
cannot identify an unknown replacement/private MAC; known WiFi aliases and
MLO links must be resolved explicitly rather than treated as one timeless MAC.

## Evidence and source bindings

Read-only source inspection established these bindings. They describe source
and packaging, not the contents or behavior of an available router image.

| Repository | Inspected revision | Finding |
|---|---|---|
| `linksys/JNAP`, `sysevent_integration` | `6e53c4c255129e34806ebfaef5992b24af1ab25d` | WirelessAP exposes ClientDeauth. The inspected Firewall, NetworkSecurity, and ParentalControl specifications do not expose an all-client-data block preserving WiFi authentication. NetworkSecurity/ParentalControl describe WAN/website restrictions. |
| `linksys/feed_linksys`, `develop` | `31e6193dea3773668d4183e5ed9bf7580b8c7f6e` | `jnap/Makefile` pins that JNAP revision. Inspected package configuration has no parental-control enable entry. Runtime packaging belongs in the feed. |
| `linksys/targets`, `develop` | `1f0b6b81b99ac44425e082c439d0e1a48ea99004` | SPF12.5 platform metadata maps Pinnacle2.0 to M60, Pinnacle2.1 to M61, and Pinnacle2.2 to M62. M60 and M62 CF/DU `feeds.conf` files select `feed_linksys;develop`. |

Sources: [JNAP specifications](https://github.com/linksys/JNAP/tree/6e53c4c255129e34806ebfaef5992b24af1ab25d/openwrt-jnap/src/spec),
[feed JNAP package](https://github.com/linksys/feed_linksys/tree/31e6193dea3773668d4183e5ed9bf7580b8c7f6e/jnap),
[M60 platform](https://github.com/linksys/targets/blob/1f0b6b81b99ac44425e082c439d0e1a48ea99004/sdks/qualcomm/qsdk-spf12.5_csu1/Pinnacle2.0/platform.json),
[M62 platform](https://github.com/linksys/targets/blob/1f0b6b81b99ac44425e082c439d0e1a48ea99004/sdks/qualcomm/qsdk-spf12.5_csu1/Pinnacle2.2/platform.json),
[M60 DU feed selection](https://github.com/linksys/targets/blob/1f0b6b81b99ac44425e082c439d0e1a48ea99004/sdks/qualcomm/qsdk-spf12.5_csu1/Pinnacle2.0/customers/DU/feeds.conf),
[M62 DU feed selection](https://github.com/linksys/targets/blob/1f0b6b81b99ac44425e082c439d0e1a48ea99004/sdks/qualcomm/qsdk-spf12.5_csu1/Pinnacle2.2/customers/DU/feeds.conf).
Re-read the selected customer lane before any future build or feed pin change.
These findings do not select an SPF14/Linksys 2.0 package home.

The existing [WiFi steering blacklist helper](https://github.com/linksys/feed_linksys/blob/31e6193dea3773668d4183e5ed9bf7580b8c7f6e/service_init/service_wifi/wifi_steer_util.sh)
adds a MAC admission blacklist and optionally applies soft-blocking timers.
Its stated purpose is preventing connection to a band. It is not evidence of
the required retained-authentication traffic block and must not be reused as
such without an independent probe.

Prior Linksys Engineering Wiki investigations of parental controls and Smart
QoS record accelerated-flow bypass on M60. Those are historical hardware
observations, not new tests in this session. Linux's
[flowtable documentation](https://docs.kernel.org/networking/nf_flowtable.html)
also describes forwarding that bypasses normal Netfilter hooks. Neither a
successful rule readback nor a conntrack flush proves that all existing
Pinnacle ECM/PPE flows have stopped. The open WAN-scheduling work in
[LinksysWRT #386](https://github.com/linksys/LinksysWRT/issues/386) is related
background, not this addendum's implementation or an approved dependency.

## Enforcement candidates

No backend is selected for production. Test the controlled-port candidate
first because it is closest to the requested WiFi behavior.

| Candidate | What it could provide | Decisive uncertainty |
|---|---|---|
| WiFi controlled port through hostapd/driver integration | Deny station data without ClientDeauth, an admission blacklist, or an SSID restart | Does the shipped QCA driver retain authentication/association and stop existing traffic in both directions? Does hostapd or key offload immediately undo the change? |
| nftables bridge filtering plus selective prevention of acceleration | Filter payload between bridge ports and between the client and router | Does every required path, including same-AP traffic and established accelerated flows, reach the rules? Can only the governed clients be kept out of acceleration? |
| QCA-supported per-client WiFi/PPE ACL | Enforcement at the accelerated packet path | Is there a supported per-client API with counters, readback, session teardown, and lifecycle ownership on these exact images? |

The upstream [nl80211 station flags](https://kernel.googlesource.com/pub/scm/linux/kernel/git/jberg/iw/+/997e5f13e7bc2267b28e541a2904d7f7d84227d0/nl80211.h)
distinguish data authorization from authentication and association. That makes
controlled-port enforcement a plausible experiment, not a demonstrated
Pinnacle capability. Integrate with normal key/authorization handling;
Unblock must not authorize a client that has not completed the required
security handshake. Do not substitute station deletion or deauthentication.

[nftables bridge filtering](https://wiki.nftables.org/wiki-nftables/index.php/Bridge_filtering)
has separate hooks for bridge forwarding and traffic to/from the local IP
stack. A WAN-only FORWARD rule does not cover the complete product behavior.
The actual hook coverage, precedence, and acceleration behavior require proof.
Do not disable acceleration for the whole household to make a prototype pass.

## What can be built separately

1. **An isolated enforcement probe.** On an identity-verified lab unit, use one
   designated non-admin WiFi client and one unaffected control client. Record
   station flags and traffic before a reversible per-station experiment.
   Stop this path if the client deauthenticates, payload still flows, or the
   effect cannot be reversed without an SSID/radio restart. No router is
   currently available, so this first feasibility decision remains open.
2. **A runtime prototype in `feed_linksys`.** After a backend passes the probe,
   package a separate `client-traffic-control` service with persistent policy,
   serialized updates, backend adapters, observed state, and restart/reconnect
   reconciliation. Scope ownership to its own rules/objects. Coordinate with
   firewall and WiFi services; never flush shared tables, restart all WiFi, or
   delete another service's policy to recover.
3. **A thin JNAP adapter in `JNAP`.** Add the authenticated specification and
   handler, delegate enforcement to the runtime, and register its service only
   on supported configurations. Wire the feed's `jnap/Config-defaults.in`,
   `Config.in`, and `Makefile`, including the runtime dependency and a reviewed
   source pin. No package flag or targets pin changes occur in the GUI release.
4. **A later GUI integration.** Extend the access-policy model and list with
   independent traffic-block state. Enable Block only when firmware advertises
   the required scope and ready enforcement. Add Block/Unblock dialogs,
   uncertainty/error handling, and write-policy tests in its own follow-on PR.

## Proposed API boundary

The following names and fields are design proposals, not existing JNAP actions.
Keep the domain transport-independent; JNAP is its first adapter.

| Proposed action | Responsibility |
|---|---|
| `GetClientTrafficControlSettings` | Return supported traffic scopes, whether authentication is preserved, runtime readiness, capacity, policy revision, and desired/observed per-client state. |
| `SetClientTrafficBlock` | Atomically change one client's block intent using a fresh expected policy revision and an idempotent operation ID. Resolve trusted WiFi aliases/serving nodes, apply enforcement, and report the observed result. |

Illustrative mutation:

```json
{
  "macAddress": "02:AA:BB:CC:DD:01",
  "blocked": true,
  "expectedRevision": "r17",
  "operationId": "preview-operation-1"
}
```

Return distinct `pending`, `applied`, `failed`, or `unsupported` enforcement
states alongside the saved intent. Readback verifies backend configuration;
hardware traffic tests establish the enforcement guarantee. Do not label a
client **Blocked** simply because persistence succeeded. On timeout, read the
operation/state back before retrying. Reject stale revisions and conflicting
concurrent mutations rather than replacing an entire unrelated rule set.

Firmware must enforce administrator access and self/mesh/backhaul protections;
GUI guards alone are insufficient. Validate MACs and capacity, resolve current
station identity, and reject unsupported coverage before acknowledging an
applied block. Do not expose shell commands, interfaces, or executable paths
as caller-controlled API inputs. Keep traffic policy separate from MAC
admission policy so Unblock cannot silently undo Remove.

## Persistence and mesh requirements

Persist desired policy through the platform's supported UCI/backup mechanism,
with an explicit schema version and no stored credentials. Reapply on boot,
service restart, WiFi reload, reconnection, roam, and role/topology changes.
Apply at the AP actually serving the client. Blocking must not have a usable
payload window on reassociation, and unblocking must resume normal security
authorization rather than bypass it.

For mesh, the controller owns intent and each serving node reports application
state for the same revision. Missing/unsupported nodes and partial application
must remain visible as uncertainty; controller persistence is not evidence
that a satellite applied the block. Reconcile new nodes and all qualified MLO
links. A single-node prototype is not mesh qualification.

## Qualification before enabling Block

| Test | Required evidence |
|---|---|
| New and established TCP, UDP/QUIC, IPv4 and IPv6 | Traffic in both directions stops for the governed client, including a download already accelerated before Block. |
| WAN, local peer, same-AP peer, and router access | Every promised path is covered; management/authentication remains available. Resolve multicast/broadcast delivery semantics explicitly. |
| Station state and Unblock | No deauth/disassociation or forced reassociation; Unblock restores traffic through normal security handling. |
| Control client | Connectivity and accelerated performance remain unaffected. |
| Two simultaneous restrictions | Unblocking one client preserves every other block and all admission rules. |
| Read-only, current administrator, mesh/backhaul, invalid/stale identity | Refusal before policy/enforcement changes, including direct API calls. |
| Lost response, stale revision, process crash, backend failure | Idempotent operations, bounded recovery, accurate observed/desired state, no false success. |
| Reboot, WiFi/firewall reload, reconnect, roam, guest network, MLO | Persistent intent reapplied at the correct node/link without a payload bypass window. |
| Upgrade, downgrade, uninstall | Defined cleanup/compatibility behavior limited to owned state; no foreign-rule deletion. |

Local contract tests and a simulated enforcement adapter can cover mutation
serialization, persistence recovery, capacity, identity protections, and
errors. They cannot prove QCA driver semantics, authentication retention,
accelerated-flow teardown, mesh coverage, or actual packet loss. Keep those
claims pending until representative M60 and M62 hardware is available.

## Investigation outcome

A separate API/runtime prototype is a concrete follow-on path. The smallest
useful next experiment is per-station controlled-port behavior on the shipped
driver. If that fails, investigate bridge coverage with selective offload
control or obtain a supported QCA per-client ACL. The architecture and release
boundary are defined; enforcement feasibility remains unproven. The existing
Remove/Restore GUI feature does not wait for that decision.
