# Single-page workflow feedback and copy review

This pass is based on PrivacyGUI `35a40e7691f61446a6c1f43771644ce46465d277`, the source included in GUI #557 and firmware #554. The launch remains authenticated JNAP. Pre-login help and USP migration remain later phases.

| Surface | Customer-facing behavior |
| --- | --- |
| First entry / rerun | Visible checking headline, activity indicator, and individual check states appear before the workflow chooser. Received successful results turn green. Missing measurements remain unavailable. Completion or failure replaces progress in the same place with the outcome. |
| Required read / diagnostic failure | End checking with an inconclusive message and Run Again. Do not turn a missing verdict into an all-clear or infer an internet outage from missing router data. |
| Home navigation | Six symptom workflows and contextual troubleshooting actions; no View devices or View network shortcuts. |
| Exit | Back to router home stays available on the overview, workflows, and bookmarked detail pages, including direct URL entry. The destination retains PrivacyGUI authentication. |
| Device summary | Describe available connection measurements; do not claim every connected device supplied WiFi signal and speed. Direct affected customers to One device is slow, or the contextual Troubleshoot these devices action. |
| Missing measurements | Device results remain partial; absent internet or firmware evidence is untested, not passed. |
| Speed finding | A weak connection on another client does not identify the browser's own connection. Describe WiFi as a possible contributor and send the user through device help. |
| WiFi security advice | Refer to Back to router home and the actual Incredible-WiFi page, replacing My Network / WiFi Security tab instructions. |
| Provider gateway advice | Refer to the router's internet/WAN MAC address in router settings; do not send the user to the retired My Network tab or substitute a LAN MAC. |
| Completed status | Keep the outcome visible with expandable supporting results. Unsupported and incomplete checks retain their limitations. |

The text review covered overview verdicts, expanded check results, device findings, and the internet, speed, device connection, coverage, intermittent connection, and two-router workflows. Existing retry, confirmation, cancellation, support, and lateral-return paths remain covered by the browser inventory. Reviewer/demo scenarios are retained. Legacy device/network URLs remain supported for existing bookmarks and are exercised directly by compatibility tests.

## Validation scope

Five new behavioral regressions fail against the unchanged base: collapsed progress, required-read failure remaining in loading, a missing verdict shown as all-clear, unwanted navigation shortcuts, and no router-home exit. The baseline archive uses the same widget dependency and generated localization files as the working checkout.

The focused Flutter command is:

```sh
flutter test --no-pub test/page/instant_verify/views test/page/instant_verify/providers test/page/instant_verify/models --reporter expanded
```

The local HTML web build uses the same renderer as GUI #557. Browser acceptance runs `node tools/instant_test/browser.mjs <local-preview-URL>` with desktop and mobile contexts, screenshots, page errors, and failed-request reporting. `progress=1` fixtures exercise the real progress widget with simulated data only.

No home-router deployment or hardware acceptance is claimed for this pass. The previously captured authenticated hard-reload browser error remains a separate investigation; these changes are not evidence that it is fixed. Full firmware rebuild and on-device acceptance remain necessary before distributing an updated image.

Final local acceptance: **369 Flutter tests passed**, **54/54 Chromium scenarios passed**, and the HTML web build succeeded. Chromium recorded no uncaught page errors or unexpected failed requests. The existing preview-only asset 404 remains: /assets/assets/resources/versions.json. Firmware packaging provides this version-history asset; this preview result does not qualify a new firmware image.
