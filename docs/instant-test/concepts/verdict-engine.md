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
