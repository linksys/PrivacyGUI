# Instant Devices: traffic blocking belongs to Parental Controls

Status: decision and enforcement research, 2026-10-15. No traffic blocking API,
enforcement module, firmware build, or GUI action is implemented by this
change.

## Decision

Instant Devices does not ship a standalone **Block** action or its own blocking
API. Per-device traffic blocking is owned by Parental Controls
([LinksysWRT #386](https://github.com/linksys/LinksysWRT/issues/386), UI
[PrivacyGUI #1003](https://github.com/linksys/PrivacyGUI/issues/1003)).

Parental Controls already needs the same capability: its `ParentalControl2`
rules block a device's internet access by MAC address on a weekly schedule of
48 half-hour slots per day (`0` = blocked). "Block now" is a rule whose slots
are all `0`. Building a second blocking path for Instant Devices would duplicate
the hardest firmware work and create precedence conflicts between two policies.

Once Parental Controls enforcement exists, Instant Devices may offer a shortcut
that creates or edits a Parental Controls rule for the selected device through
`GetParentalControlSettings` / `SetParentalControlSettings` (atomic replace of
the whole rule set). Until then the device menu offers only **Remove**.

**Remove** is unaffected and separate. It restricts WiFi admission (MAC filter)
and deauthenticates; it does not block traffic for a connected device.

## Enforcement on Pinnacle hardware

This section is input for the Parental Controls firmware work, recorded here
because it decides whether a GUI block action can ever be honest.

### The problem

On the M60, an nftables rule matching a blocked MAC stops **new** connections
but not established ones. Qualcomm's Enhanced Connection Manager (ECM) offloads
established flows to the PPE/SFE acceleration engines, which bypass netfilter.
On 2026-07-06 an in-progress download kept running through the block, and
`conntrack -D` plus `ecm defunct_all` did not stop it: the flow re-accelerated.
See the Linksys Engineering Wiki `firmware/parental-controls.md`.

A plausible cause, not yet verified: the test rule matched only
`ether saddr` (traffic from the client). After `defunct_all`, packets arriving
from the WAN toward the client did not match, ECM rebuilt the connection, and
re-accelerated it in both directions before the client's packets were seen.

### Qualcomm's interface for this: the PCC classifier

ECM includes a Parental Control Classifier (PCC) intended for exactly this use.
A kernel module registers one `ecm_classifier_pcc_registrant`. For each new
connection, ECM calls the registrant's `okay_to_accel_v4/v6` (or
`get_accel_info_v4/v6`) with **both source and destination MAC addresses** and
the 5-tuple. The registrant answers:

| Result | Effect |
|---|---|
| `PERMITTED` | Connection may be accelerated. |
| `DENIED` | Connection is never accelerated; every packet stays in the slow path where netfilter sees it. The decision is cached for the connection's lifetime. |
| `NOT_YET` | Not accelerated now; ECM asks again later, at most once per second. |

For connections that are already accelerated when a device becomes blocked,
`ecm_classifier_pcc_deny_accel_v4/v6(tuple)` sets the cached decision to
`DENIED` and calls the frontend's `decelerate()`. `permit_accel_v4/v6` reverses
it. `ecm_classifier_pcc_decel_v4/v6` decelerates without changing the decision.
Only one registrant may exist (`-EALREADY` otherwise), and registering or
unregistering calls `ecm_db_connection_defunct_all()`.

Source, QSDK 12 (`openwrt-qsdk12` mirror at
[`981ff32a`](https://github.com/niniming/openwrt-qsdk12/tree/981ff32aede2ffdc416036d001738b50a6ed7c2f/qca/src/qca-nss-ecm)):
`ecm_classifier_pcc_public.h`, `ecm_classifier_pcc.c` (`process`, lines
664–963; `deny_accel_v4`, lines 380–445; `register`, lines 132–163).

### Evidence it is available on Pinnacle

Pinnacle's vendor ECM package
(`linksys/PSIRT_Pinnacle2_full@e427f176:src/vendor_sdk/package/feeds/nss_host/qca-nss-ecm/Makefile`)
enables the PPE and SFE frontends on IPQ53xx and builds Qualcomm's PCC example
module `ecm_pcc_test.ko` by default on IPQ53xx/IPQ95xx
(`QCA_NSS_ECM_EXAMPLES_PCC default y`).

The example is a test harness, not a production registrant. It registers when
loaded and returns `NOT_YET` for every flow without an exact 5-tuple rule, so
loading it would stop acceleration for all traffic. It must not be loaded on a
production image, and if it is loaded it occupies the single registrant slot.

### Production reference

Norton Core, a shipped Qualcomm-based security router, includes a GPL
registrant, `cpc.c` ("Classifier for Parental Control",
[`larrikinist/Norton-Core@b34e7aab`](https://github.com/larrikinist/Norton-Core/blob/b34e7aabcc42be45e1f853c68b80ee6f48129a33/qsdk/qca/src/qca-nss-ecm/cpc.c)).
It keeps a cache of permitted connections, removes entries through an ECM
database listener, and exposes a debugfs command that decelerates every
connection to or from one IP address by calling `deny_accel_v4` per tuple. Its
policy is allow-listed acceleration after inspection; Parental Controls needs
the inverse (deny for blocked MACs, permit otherwise).

### Proposed enforcement sequence

1. Add the device's MACs to the Parental Controls nftables set, in the
   `forward` chain ahead of the LAN-to-WAN accept, so new connections are
   dropped.
2. A small Parental Controls PCC registrant returns `DENIED` when the source
   **or** destination MAC is in the blocked set and `PERMITTED` otherwise, so
   a blocked device's flows cannot be accelerated in either direction.
3. On the block transition, enumerate the device's conntrack entries and call
   `deny_accel` for each LAN-side tuple. Each decelerated flow's next packet
   reaches netfilter and is dropped.
4. On unblock, remove the MACs from the set and call `permit_accel` for the
   device's tuples, or let those flows finish in the slow path.

The registrant's MAC set must be updated by the same daemon that maintains the
nftables set, so the two cannot drift.

### Open questions for hardware qualification

- Is the PCC classifier enabled in the shipped `ecm.ko`, and is
  `ecm_pcc_test.ko` installed or loaded (`lsmod`, `/sys/kernel/debug/ecm/`)?
- Does deceleration cover every IPQ5332 path, including PPE, SFE, and WiFi
  traffic offloaded directly to PPE?
- Does an already-accelerated download stop within one second of the block,
  over IPv4 and IPv6, TCP and UDP/QUIC?
- What is the throughput impact on a blocked device's remaining allowed
  traffic (DNS, router access) and on unblocked devices (expected: none)?
- In a mesh, does the controller see the client MAC for traffic from a client
  on a satellite, or the backhaul MAC?
- Per-SSID MAC randomization remains a bypass for any MAC-based policy.

No registered router was reachable on 2026-10-15, so none of these have been
tested on hardware.
