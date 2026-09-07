# Instant-Test local acceptance harness

This harness tests the authenticated launch UI through its **simulated prototype**, without adding CI or deploying to a router. Hardware/session acceptance is still required for launch.

## Simplified presentation branch

The previous UI is preserved on `feat/instant-test-single-page-workflows` at `157cea5b45517ca29ab819255031765f02827174` (PR #1485). The presentation changes are isolated on `feat/instant-test-progressive-disclosure`, based on that commit. Its PR should target the preserved feature branch so the simplification can be reviewed or discarded independently.

The default view keeps results, the recommended next step, and action consequences visible. Test checklists, connection measurements, radio inventories, extra findings, and supporting explanations open on demand. The initial device list remains visible with eight-device paging/search; after selection it is available through Change device. Manual advice shows one instruction at a time with next/previous controls; those controls do not execute router actions. Existing router confirmations, navigation/history, and login boundaries remain in effect.

Acceptance covers collapsed and expanded states, changing a device or problem, sequential advice, absent telemetry, and agreement between compact and detailed signal labels. Dark desktop and light mobile browser scenarios exercise the same workflows. The snapshot comparison uses the same mock data on both branches; it is presentation evidence, not hardware acceptance.

## Flutter regression tests and preview build

Use the repository's Flutter version (3.27.2 on this prototype branch), with dependencies already resolved:

```sh
./tools/instant_test/check.sh
./tools/instant_test/check.sh --build
```

Set `FLUTTER_BIN` to an explicit Flutter executable if needed. `--build` uses the local JNAP deployment build flags and writes to `build/instant_test`. It does not deploy. The local build includes internal scenario controls and must not be treated as a customer release artifact.

The suites cover six symptom entries, finding routing, mesh health, missing/stale device data, device paging/search, mouse selection, qualifiers, retained lateral returns, speed failure/retry, monitor cancellation and stale results, preview action isolation, route restoration, and dismissal of pending confirmations when leaving a workflow. The original legacy workflow regressions run too.

## Browser acceptance

Install the pinned browser dependency once, then serve the fresh build:

```sh
npm ci --prefix tools/instant_test
cd tools/instant_test && npx playwright install chromium
```

From the repository root, in a separate terminal:

```sh
python3 -m http.server 8105 --bind 127.0.0.1 --directory build/instant_test
```

Run the browser checks from the repository root:

```sh
npm test --prefix tools/instant_test -- 'http://127.0.0.1:8105/#/instant-prototype'
```

The runner accepts only localhost prototype URLs, checks the single-page preview heading, and verifies that retired layout options are absent before interacting. It uses fresh Chromium contexts, dark desktop and light mobile viewports, and records screenshots plus `tools/instant_test/artifacts/results.json`. Any failed assertion, uncaught page error, or unexpected failed request gives a nonzero exit code. The three previously reproduced font/version asset 404 paths are recorded separately as known baseline failures; the report is not a claim of a clean console.

The browser pass checks the six action tiles at desktop and mobile widths, removal of the old top detail links, and the relocated detail links below the summary. A widget regression verifies that the chooser scrolls with the diagnostic content. It also covers mobile device-details handoff, Cancel/Escape for restart and reconnect confirmations, browser Back during confirmation, and leaving an active monitor. Action headings use compact theme-colored strips, while diagnostic status remains visually separate.

## Navigation contract

The `instant` route query contains only known view/flow identifiers. Browser Back/Forward follows workflow and detail-page visits. Returning from lateral help preserves the origin's in-memory choices while that origin remains mounted. In-app Back can additionally reverse an advice step within a workflow.

Refresh reopens the addressed page/workflow and fetches current data. It does not restore a selected device, old results, qualifier answers, or a running monitor/router action. Forward recreates a disposed workflow with the same safeguards. Authentication and redirects remain owned by the router's existing route guard; query parameters cannot grant access.

## Remaining release checks

Run mandatory login and expired-session behavior, real router data/error states, confirmation/cancellation of disruptive actions, restart/reconnect recovery, support/escalation, broader accessibility, and the selected JNAP release line's existing checks on the target device. Confirm customer builds exclude prototype/scenario controls. No pre-login or USP capability is part of this launch pass.
