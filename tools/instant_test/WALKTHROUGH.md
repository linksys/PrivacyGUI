# Instant-Test feature acceptance — simplified JNAP workflow

The standard harness runs all Instant-Test view tests. The browser walkthrough uses the isolated local preview, with fixed diagnostic fixtures and neutralized router actions. This is feature acceptance for the presentation branch; authenticated on-device acceptance remains required.

## Path inventory

| Feature | Executed coverage |
| --- | --- |
| Home and results | Six symptom entries; five overview scenarios; visible verdict/action; optional explanations, secondary findings, test checklist and individual results; rerun; device/network detail links. |
| Internet unavailable | Healthy result; device cannot reach router; router cannot reach internet; DNS failure; unavailable probe; retry; manual next/previous instructions; restart cancellation and confirmed simulated restart; provider escalation and current diagnostic summary. |
| Whole internet slow | Normal, slow, and high-latency results; expanded speed details; failed test/retry; whole-home, one-device, and gaming branches; restart cancellation; successful/slow/failed post-restart results; already-restarted/provider path; return from device help. |
| Device help | Visible list, selection/change, missing device, Ethernet, WiFi-name yes/no, credentials guidance, manual next/previous, completion, slow connection details, alternative suggestions, general advice, dropping WiFi, problem switching, reconnect confirmation/cancellation, simulated reconnect and return. |
| Coverage | All three placement choices, tailored tips, extra coverage guidance, mesh warning, completion and return. |
| Connection drops | Both frequency choices; all/specific devices; start prerequisites; completed tests with/without drops; failed probes; cancellation/leave; changed scope and stale results; restart cancellation and confirmed simulated restart; continued drops versus recovery; provider handoff. |
| Two routers | Bridge-mode guidance, access-point guidance, provider handoff, leave-as-is, and each terminal return. These are instructions, not automatic network-mode changes. |
| Device/network details | Inventory, weak/missing signal, mesh health, firmware action availability, simulated firmware request, device-specific troubleshooting handoff, cancel/Escape, return/history. |
| Cross-cutting | Browser Back/Forward/refresh, retained lateral visits, keyboard access, selectable content, pending-confirmation dismissal, mobile/wide resizing, preserved expanded details, compact actions, shared support footer, router-light guide. |

Conditional data cases also run in widget tests: no/lost device lists, search/paging, absent telemetry, signal boundaries, unknown mesh health, radio disabled/SSID hidden/WPA3-only guidance, wired versus wireless reconnect availability, and channel-change availability/confirmation. These cases are not claims of live router operations.

## Regressions found and fixed during this pass

- A thrown connection probe left the workflow unfinished. It now shows an inconclusive result and retry, clearing previous probe flags.
- Cancelling a restart triggered follow-up diagnostics/speed tests. The shared confirmation now reports whether a restart was requested, and follow-up work requires that result.
- Changing advice retained the previous instruction index. Different instructions now start at step one, while unchanged instructions retain position through resizing.
- Escalation summaries used older overview results. Internet and speed workflows now supply their current test evidence.
- A failed post-restart speed test jumped to an ISP conclusion. It now reports an incomplete check and offers retry.
- Error messages and escalation values were visually present but absent from Chromium’s accessible text. They now use standard text within the existing selection area, keeping copy support while exposing their content.

## Verification

Final local pass, September 8, 2026: **193 Flutter view tests and 47 Chromium scenarios pass**, and the local JNAP web build succeeds. Targeted analysis has no errors; existing warnings/style diagnostics remain. Desktop and mobile screenshots were inspected, including failure and escalation states.

```sh
FLUTTER_BIN=/Users/deven.ducommun/fvm/versions/3.27.2/bin/flutter tools/instant_test/check.sh --build
npm test --prefix tools/instant_test -- 'http://127.0.0.1:8105/#/instant-prototype'
```

Screenshots and machine-readable results are written to ignored `artifacts/`. The runner fails on failed assertions, uncaught browser errors, or unexpected request failures. Previously reproduced font/version asset 404s are recorded separately.

## Remaining device acceptance

Verify router login and expired sessions, actual JNAP probe results and failures, disruptive-action success/failure and recovery, channel/blocklist changes where supported, firmware update behavior, customer-build exclusion of preview controls, and the selected LinksysWRT 1.0 release branch. Pre-login assistance and USP migration remain later phases.
