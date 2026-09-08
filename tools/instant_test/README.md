# Instant-Test local acceptance harness

This harness tests the authenticated launch UI through its **simulated prototype**, without adding CI or deploying to a router. Hardware/session acceptance is still required for launch.

## Simplified presentation branch

The previous UI is preserved on `feat/instant-test-single-page-workflows` at `157cea5b45517ca29ab819255031765f02827174` (PR #1485). The presentation changes are isolated on `feat/instant-test-progressive-disclosure`, based on that commit. Its PR should target the preserved feature branch so the simplification can be reviewed or discarded independently.

The default view keeps results, the recommended next step, and action consequences visible. Test checklists, connection measurements, radio inventories, extra findings, and supporting explanations open on demand. The initial device list remains visible with eight-device paging/search; after selection it is available through Change device. Manual advice shows one instruction at a time with next/previous controls; those controls do not execute router actions. Existing router confirmations, navigation/history, and login boundaries remain in effect.

Acceptance covers collapsed and expanded states, changing a device or problem, sequential advice, absent telemetry, and agreement between compact and detailed signal labels. Dark desktop and light mobile browser scenarios exercise the same workflows. The snapshot comparison uses the same mock data on both branches; it is presentation evidence, not hardware acceptance.

The simplified page also groups connection-outcome explanations inside their action cards, uses section-width blue heading bands and content-sized action buttons, and measures the available layout width instead of imposing a 1,120-pixel cap. `InstantTestLayout` owns the page margins once, with an explicit wide-content option. It follows PrivacyGUI’s spacing and breakpoints: 16/32/24-pixel margins on smaller layouts and 2.5% gutters from the 1,240-pixel breakpoint. Nested views retain vertical scroll padding without adding side margins. Acceptance includes resizing from a 2,048-pixel window to mobile and following the compact healthy-connection action into device help.

## Flutter regression tests and preview build

Use the repository's Flutter version (3.27.2 on this prototype branch), with dependencies already resolved:

```sh
./tools/instant_test/check.sh
./tools/instant_test/check.sh --build
```

Set `FLUTTER_BIN` to an explicit Flutter executable if needed. `--build` uses the local JNAP deployment build flags and writes to `build/instant_test`. It does not deploy. The local build includes internal scenario controls and must not be treated as a customer release artifact.

The suites cover six symptom entries, finding routing, mesh health, missing/stale device data, device paging/search, mouse selection, qualifiers, retained lateral returns, speed failure/retry, monitor cancellation and stale results, preview action isolation, route restoration, and dismissal of pending confirmations when leaving a workflow. The original legacy workflow regressions run too. Layout regressions cover resizing from 320 to 2,048 pixels, retaining open details, and embedding the workflow in a narrower container on a wide screen. The standard command now runs the complete views directory, including the reconciled overview, device, network, single-page, and legacy workflow suites. Overview coverage checks visible outcomes, optional explanations/checklists, nested detail expansion, secondary findings, device/mesh inventories, and untested or failed connection evidence. No overview tests are excluded.


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

To rerun one scenario, append its name after the URL (for example, `responsive-layout-state`). An unknown scenario name fails instead of reporting an empty successful run.

The runner accepts only localhost prototype URLs, checks the single-page preview heading, and verifies that retired layout options are absent before interacting. It uses fresh Chromium contexts, dark desktop and light mobile viewports, and records screenshots plus `tools/instant_test/artifacts/results.json`. Any failed assertion, uncaught page error, or unexpected failed request gives a nonzero exit code. The three previously reproduced font/version asset 404 paths are recorded separately as known baseline failures; the report is not a claim of a clean console.

The browser pass checks the six action tiles at desktop and mobile widths, removal of the old top detail links, and the relocated detail links below the summary. A widget regression verifies that the chooser scrolls with the diagnostic content. It also covers mobile device-details handoff, Cancel/Escape for restart and reconnect confirmations, browser Back during confirmation, and leaving an active monitor. Action headings use theme-colored bands across their sections, while diagnostic status remains visually separate. Page titles and the home introduction are centered; instructions stay left-aligned. Controls use PrivacyGUI’s shared buttons, typography, and icons. `InstantTestColumns` places both diagnostic and device sidebars next to guidance when the available content width reaches PrivacyGUI’s 905-pixel breakpoint, and stacks them below it. The same child structure preserves expanded details during resizing. The symptom chooser uses the same breakpoint and a minimum tile width on smaller screens. Support appears once, below the page actions in the shared footer.

## Navigation contract

The `instant` route query contains only known view/flow identifiers. Browser Back/Forward follows workflow and detail-page visits. Returning from lateral help preserves the origin's in-memory choices while that origin remains mounted. In-app Back can additionally reverse an advice step within a workflow.

Refresh reopens the addressed page/workflow and fetches current data. It does not restore a selected device, old results, qualifier answers, or a running monitor/router action. Forward recreates a disposed workflow with the same safeguards. Authentication and redirects remain owned by the router's existing route guard; query parameters cannot grant access.

## Feature walkthrough

See [WALKTHROUGH.md](WALKTHROUGH.md) for the executed path inventory and release limits. `walkthroughs.mjs` extends the browser runner with failure, recovery, and terminal paths. Its fixed `probe` query values are read only by `PrototypeRoot`; the authenticated router route uses the real diagnostic service. Each fixture change loads a fresh document, avoiding stale state from hash-only navigation. Connection-monitor checks advance the browser clock through the real timer callbacks; they do not change the production monitoring interval.

## Remaining release checks

Run mandatory login and expired-session behavior, real router data/error states, confirmation/cancellation of disruptive actions, restart/reconnect recovery, support/escalation, broader accessibility, and the selected JNAP release line's existing checks on the target device. Confirm customer builds exclude prototype/scenario controls. No pre-login or USP capability is part of this launch pass.

## Authenticated router harness

[DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md) documents the device deployment and `bun tools/instant_test/device.ts <registered-MAC>` walkthrough. It uses real JNAP reads and probes in an isolated authenticated browser, and blocks disruptive actions. Its results are separate from the simulated preview suite.
