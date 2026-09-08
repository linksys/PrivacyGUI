# Authenticated JNAP device acceptance

The September 8, 2026 device pass uses the M60CF-EU lab router, hardware MAC `74:12:13:21:55:c8`, running JNAP firmware `1.2.4.26090412`. The tested GUI is the simplified Instant-Test branch; this is a development deployment, not a customer release image.

## Deployment evidence

The original GUI was archived before installation and copied off the router through authenticated SSH. Both archive transfers were checked with SHA-256. The installed `main.dart.js` and the file served over HTTPS match the local build.

- Original GUI archive SHA-256: `5509586087ce37498a5ebf7d1377a57866757e3332adc9848fa87c7c02c48e04`.
- Corrected GUI `main.dart.js` SHA-256: `c1c5ce072e0ad0aaef56a1905563d0b1bde18347cc5087702eabfc4cca1d6d79`.
- Initial router backup path: `/tmp/instant-test-original-gui-8e4c6649.tgz` (temporary RAM storage; the restart clears it). The durable copy is the local backup below.
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

- The follow-up below covers physical reconnect/restart and post-rejoin recovery. Channel/blocklist changes and firmware installation remain untested.
- The follow-up covers actual local JNAP authorization rejection, re-login, and five-minute browser idle logout. Cloud-token expiry remains outside this local JNAP pass.
- Scenario controls and the mock preview are intentionally retained for reviewers and demos. Their exclusion is deferred to productization.
- Release-branch integration and independent PR review remain open.

## Reviewer/demo follow-up

The current milestone remains a review and demo build. Scenario controls are retained and expanded: the preview exposes five overview fixtures and twelve workflow outcomes, including connection/speed probe failures and rejected restart/reconnect requests. Applying any scenario resets workflow state. Choosing a scenario from the live page opens the isolated mock provider instead of putting mock clients into the live action provider.

The follow-up corrected four reproduced failures:

- HTTP-200 JNAP authorization rejection did not reach the existing authentication handler. Instant-Test now forwards it, suppresses repeated rejection callbacks until authentication succeeds, and allows later sessions to reject correctly too.
- A rejected restart was swallowed, leaving progress active and allowing recovery claims. Failure now dismisses progress, retains retry availability, and avoids follow-up success claims.
- A rejected reconnect was swallowed and reported as disconnection. Failure now reports an unconfirmed request and clears local progress without claiming the device disconnected.
- PrivacyGUI started its initial privacy-settings fetch without an error handler. The real rejection trace identified this separate background request, and a regression reproduced the unhandled error in the unchanged base code. Initialization now handles failure; explicit fetch callers still receive their errors.

The restart and reconnect failures reproduced in regression tests before their fixes; the underlying action handling was present on the preserved base. Authentication rejection reproduced against the previously deployed GUI using actual router responses to read requests without authorization. No credential was changed.

The combined follow-up suite passes **221 Flutter tests and 51 preview browser scenarios**. The web build succeeds. Targeted analysis reports no errors and 22 existing warning/style diagnostics. Live follow-up results are recorded below after completion.

### Real reconnect and restart

The UI sent one `ClientDeauth` for the selected lab client and one `Reboot`; both returned `OK`. The console confirmed a new boot ID after the restart. Both secondary WiFi clients reassociated, including the selected reconnect target, and the mismatch-event count was zero. No WiFi password or firmware image was changed by this pass.

The recovery harness's three-minute automatic return failed because the Mac switched to another network while the router restarted. This was observed in its changed default route while the console showed the lab router and clients online. Rejoining the existing lab WiFi restored identity-verified SSH and browser access. The raw recovery report remains `pass: false` to preserve that limitation; the post-rejoin device walkthrough is separate acceptance evidence. A repeat of the disruptive harness requires keeping/rejoining the test network within its timeout.

The JavaScript SHA-256 used for the physical recovery pass is `75fb6c69905cee7ad3ccd3621f4b5a9bbf0c8fa16e31cc60b5e451f1c495a4dd`. It survived the actual reboot unchanged. The overlay has approximately 30 MiB free afterward. The original GUI backup remains on the Mac.

The final post-rejoin device harness passes **12 checkpoints**, with zero uncaught browser errors and zero blocked requests. This includes all six live workflow entries, device/network inventories, the real two-minute monitor, authenticated entry into isolated demo mode, a simulated restart with no live mutation, and a fresh-document login redirect after clearing browser session storage. The HTTPS-served JavaScript matches the installed SHA above.

The final background-initialization fix is deployed with JavaScript SHA-256 `aa9edd246e0a778e310fe6f25998d6c2ccdf46661522fb1718d35697026c8fd4`. The final source suite has 221 passing Flutter tests, and all 51 browser scenarios pass again.

Final-build acceptance: **4 authentication checkpoints and 12 device checkpoints pass**, both with zero uncaught browser errors and zero blocked requests. Authentication uses real router rejection of reads with authorization omitted, successful re-login, and the actual five-minute browser idle timer (no clock acceleration). The initially observed background error is covered by the privacy-initialization fix and no longer occurs. Both result sets were regenerated after the final deployment.

The original recovery timeout remains documented above: macOS selected another network during the reboot. The router and clients recovered, and rejoining the lab network restored access. This is a lab-connection requirement for repeat recovery tests, not a claim of automatic WiFi rejoin by the browser.
