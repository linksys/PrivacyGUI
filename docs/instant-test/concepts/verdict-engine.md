# Concept: Verdict Engine

> Turns raw diagnostic inputs into prioritized, customer-facing findings.

## Explanation
`models/verdict.dart` (`VerdictEngine`) takes the collected state — WAN status,
DNS results, speed test, client list, mesh backhaul, DHCP utilization, etc. — and
produces a list of **findings**, each with a priority (critical / warning / info /
all-clear), a customer-readable headline, a detail, and a suggested fix/action.

The overview tab renders these findings; auto-fix actions (restart, firmware
update, channel change, bridge-mode help) map to action keys the engine emits.

## Key Points
- Pure logic over normalized inputs — this is the prime candidate for the shared
  core in [[concepts/two-line-strategy]].
- JNAP and USP versions are ~95% identical; only input *types* differ
  (`DiagnosticClient` vs `DeviceUIModel`).
- Channel recommendation is currently a hardcoded best-practice (6 / 36), NOT a
  scan result — see [[roadmap]] B-18.

## Principle: an incomplete check is an issue
A check that runs but doesn't finish must NEVER be swept into a green all-clear.
The pattern (established for the speed test, extends to others):
1. Provider sets a `*Failed` flag in state on timeout/error/0-result (e.g.
   `speedTestFailed`) — it does NOT silently discard.
2. That flag is passed into `VerdictEngine.compute(...)` and emits a **warning
   finding** (e.g. "We couldn't finish the speed test") — gated on WAN/DNS being
   otherwise up, so a real outage stays the headline.
3. The finding shows at the top like any other; the corresponding Test-details
   row flags amber (see [[concepts/design-system]] warning check state).

This is the robust approach — a finding flows through normal rendering, unlike a
view-only special-case card (which was the rejected first attempt; it was gated
on isAllClear and got suppressed by other findings). See [[roadmap]] BUG-4.

## Finding → Test-details row mapping
Findings that have a matching detail row flag that row (latency→Speed check,
weak device→Devices checked, WAN→Internet connected, DNS→Websites loading).
~7 findings (CPU, memory, WiFi schedule, privacy, paused, interference,
band-steering) have no row and surface top-only by design. See [[feature-linkage-map]].

## Examples
- DNS three-way root-cause: public-DNS-works + configured-DNS-unreachable →
  "can't reach your ISP's DNS servers" vs. service-broken vs. internet-down.
- All-clear data rows: speed, active device count, band distribution with
  contextual notes (the screen in the framing screenshot).

## Related
- [[code-map]]
- [[concepts/two-line-strategy]]

## Last Verified
2026-06-08
