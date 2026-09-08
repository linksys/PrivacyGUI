# Authenticated JNAP device acceptance

The September 8, 2026 device pass uses the M60CF-EU lab router, hardware MAC `74:12:13:21:55:c8`, running JNAP firmware `1.2.4.26090412`. The tested GUI is the simplified Instant-Test branch; this is a development deployment, not a customer release image.

## Deployment evidence

The original GUI was archived before installation and copied off the router through authenticated SSH. Both archive transfers were checked with SHA-256. The installed `main.dart.js` and the file served over HTTPS match the local build.

- Original GUI archive SHA-256: `5509586087ce37498a5ebf7d1377a57866757e3332adc9848fa87c7c02c48e04`.
- Corrected GUI `main.dart.js` SHA-256: `c1c5ce072e0ad0aaef56a1905563d0b1bde18347cc5087702eabfc4cca1d6d79`.
- Original archive on the router: `/tmp/instant-test-original-gui-8e4c6649.tgz`.
- Local backup: ignored `artifacts/device/backup/original-gui.tgz`.
- Device overlay space after installation: approximately 11 MiB free.

A proposed unauthenticated LAN transfer server was rejected by automatic approval review and was never started. The actual deployment used authenticated SSH with the existing device identity verification.

## Finding corrected

The router returns `_ErrorUnknownAction` for parental controls, wireless scheduling, and network-security settings. The provider converted these absent results to `false`, so the verdict counted them as passed. Missing results now remain unknown and are excluded from the pass count. The device changed from **16 checks passed to 13** with the same supported data.

The provider file was identical to the preserved base branch before this fix. A regression reproduces the counting error and now passes. The standard harness also includes the provider scenario tests: **215 Flutter tests pass**, the web build succeeds, and **47 preview browser scenarios pass**. Targeted analysis has no errors; existing style diagnostics remain.

The final hardware run completed **11 checkpoints**, with **zero uncaught browser errors and zero blocked requests**. The real two-minute connection monitor reported no drops. The normal first-login acknowledgement and unchanged firmware-settings requests both completed successfully. No disruptive action was executed. Local evidence is in ignored `artifacts/device/results.json` and the accompanying screenshots.

## Repeatable device walkthrough

With this GUI already deployed and the Mac connected to the registered lab router:

```sh
bun tools/instant_test/device.ts 74:12:13:21:55:c8
```

The harness uses the installed `linksys-mcp` identity verifier and credential resolver. By default that checkout is a sibling of PrivacyGUI; set `LINKSYS_MCP_ROOT` if it is elsewhere. No password is passed on the command line or written to the report. Bun and the existing Playwright dependency/browser installation are required.

The healthy-lab pass covers the login redirect, authenticated overview, live internet and speed checks, selection of an actual WiFi client, connection guidance, optional measurements, reconnect cancellation, coverage guidance, a real two-minute monitor, device/network inventories, and redirect after removing this isolated browser session. Screenshots and action/result summaries are saved under ignored `artifacts/device/`.

The request guard permits reads and read-only transactions. Firmware availability checks require `onlyCheck: true`. Ordinary first-login acknowledgement is permitted; firmware settings are permitted only if the requested policy and update window equal their current values. Other setting changes, actual firmware installation, reboot, and deauthentication requests are blocked. A blocked request or uncaught browser error fails the run.

## Remaining release acceptance

- Actual restart/reconnect execution and recovery, channel/blocklist actions, and firmware installation were not performed by this guarded pass.
- True server/session timeout and expired-credential behavior still require dedicated acceptance; removing browser session storage only verifies return to login.
- Customer builds must exclude scenario controls and the mock preview route.
- Release-branch integration and independent PR review remain open.
