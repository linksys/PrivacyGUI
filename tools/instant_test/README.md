# Instant-Test local acceptance harness

This harness tests the authenticated launch UI through its **simulated prototype**, without adding CI or deploying to a router. Hardware/session acceptance is still required for launch.

## Flutter regression tests and preview build

Use the repository's Flutter version (3.27.2 on this prototype branch), with dependencies already resolved:

```sh
./tools/instant_test/check.sh
./tools/instant_test/check.sh --build
```

Set `FLUTTER_BIN` to an explicit Flutter executable if needed. `--build` uses the local JNAP deployment build flags and writes to `build/instant_test`. It does not deploy. The local build includes internal scenario controls and must not be treated as a customer release artifact.

The suites cover six symptom entries, finding routing, mesh health, missing/stale device data, device paging/search, mouse selection, qualifiers, retained lateral returns, speed failure/retry, monitor cancellation and stale results, preview action isolation, and route restoration. The original legacy workflow regressions run too.

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

The runner accepts only localhost prototype URLs and checks the prototype heading before interacting. It uses fresh Chromium contexts, dark desktop and light mobile viewports, and records screenshots plus `tools/instant_test/artifacts/results.json`. Any failed assertion, uncaught page error, or unexpected failed request gives a nonzero exit code. The three previously reproduced font/version asset 404 paths are recorded separately as known baseline failures; the report is not a claim of a clean console.

## Navigation contract

The `instant` route query contains only known view/flow identifiers. Browser Back/Forward follows workflow and detail-page visits. Returning from lateral help preserves the origin's in-memory choices while that origin remains mounted. In-app Back can additionally reverse an advice step within a workflow.

Refresh reopens the addressed page/workflow and fetches current data. It does not restore a selected device, old results, qualifier answers, or a running monitor/router action. Forward recreates a disposed workflow with the same safeguards. Authentication and redirects remain owned by the router's existing route guard; query parameters cannot grant access.

## Remaining release checks

Run mandatory login and expired-session behavior, real router data/error states, confirmation/cancellation of disruptive actions, restart/reconnect recovery, support/escalation, broader accessibility, and the selected JNAP release line's existing checks on the target device. Confirm customer builds exclude prototype/scenario controls. No pre-login or USP capability is part of this launch pass.
