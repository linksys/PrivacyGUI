# Vendored CanvasKit

`web/assets/canvaskit.js` and `web/assets/canvaskit.wasm` are hand-copied from
the Flutter SDK and committed. They are the **only** CanvasKit that ever
executes in a PrivacyGUI build, so this file is the source of truth for which
SDK they came from.

Sibling of `doc/usp/vendored-artifacts.md`, which covers the USP artifacts
(`tools/usp-codegen`, `web/usp_client.*`) and nothing else.

## Manifest

**Last updated**: 2026-08-29 (#1316, pinned to the 3.47.2 hotfix)

| Field | Value |
|---|---|
| Source SDK | Flutter **3.47.2** (stable) |
| Framework revision | `d3b14c876900e553bc736ca19295fc09e3853e8e` |
| Engine revision | `a804b261645ef8c13eb3d5c44a5c2fb0340c5539` |
| Dart SDK | 3.13.2 |
| Source directory | `<sdk>/bin/cache/flutter_web_sdk/canvaskit/` |

| Artifact | Bytes | sha256 |
|---|---|---|
| `web/assets/canvaskit.js` | 86987 | `bb559f6080c7d312ac2a912b4abec9f68ff3d3022d4a603c7796b9b31460642b` |
| `web/assets/canvaskit.wasm` | 7284602 | `fbed517a43e82452404446683f00f2e876d835aed84410695759e67b6bb01cd3` |

`.fvmrc` and `.github/actions/setup/action.yml` both pin 3.47.2, and
`test/web/canvaskit_variant_test.dart` asserts that they agree with each other,
with the hashes above, and with the SDK the test is running under.

## The patch digit is part of the pin

A hotfix is not a cosmetic version bump for this file. Each 3.47 hotfix ships its
own engine, and `canvaskit.wasm` changes with it:

| SDK | Engine | `canvaskit.js` | `canvaskit.wasm` |
|---|---|---|---|
| 3.47.0 | `5f77625673` | `bb559f60…` 86,987 B | `2898c079…` 7,284,349 B |
| 3.47.1 | `5d53178869` | — | — |
| 3.47.2 | `a804b26164` | `bb559f60…` 86,987 B (**identical**) | `fbed517a…` 7,284,602 B (**+253 B**) |

Three consequences:

- **Pin all three digits.** `3.47` would let the runner pick any 3.47.x and put
  the vendored CanvasKit back out of step with the engine compiling the app —
  the same defect as the original 3.44-under-3.47, one digit further down.
  `canvaskit_variant_test.dart` asserts the pin matches `\d+\.\d+\.\d+`.
- **A hotfix bump may modify only one of the two files.** `canvaskit.js` was
  byte-identical across 3.47.0 → 3.47.2, so `git status` showed one modified
  file, not two. Copy both anyway: which one moves is not knowable in advance.
- **The mismatch is not always a crash.** The hard failures in the pairing table
  below come from the glue's API changing. When the glue is byte-identical, a
  stale wasm still loads and simply lacks whatever that hotfix fixed. Nothing in
  the loader catches it either. `wasmHashes` looks like it might, and does not:
  a clean 3.47.2 build emits exactly six keys — `canvaskit.wasm`,
  `chromium/canvaskit.wasm`, `webparagraph/canvaskit.wasm`, `skwasm.wasm`,
  `skwasm_heavy.wasm`, `wimp.wasm` — all hashed from the **engine's** own web SDK
  output. None is hashed from `web/assets/`, and `flutter.js` resolves our
  `assets/canvaskit.wasm` to the bare `canvaskit.wasm` entry through a basename
  fallback (`e.split("/").pop()`). It then uses that hash purely as a
  Cross-Origin Storage retrieve/store key: the bytes actually fetched are never
  compared against it. A stale vendored copy therefore passes unremarked — and
  on a browser that ships Cross-Origin Storage it could even be *masked*, since a
  hit on the engine's hash returns that file in place of ours.

  Do not read those keys off an incremental build. One carried a leftover
  `"assets/canvaskit.wasm"` entry from an earlier build, holding the previous
  hotfix's hash; `flutter clean` plus a full rebuild is what showed the six keys
  above and no seventh.

3.47.0 → 3.47.2 moves no pixels: `linksys/PrivacyGUI-golden-ci` run 33214834347
(2026-08-28) verified a 3.47.0-rendered baseline under 3.47.2 with 0 failures
across the whole suite. Hotfixes are therefore cheap to adopt, which is a reason
to track them promptly rather than to leave the digit unspecified.

## Why these files are authoritative

`web/flutter_bootstrap.js` sets `canvasKitBaseUrl: "./assets/"`. That single
line is the offline requirement from #1281 and the whole reason CanvasKit
resolves locally: `buildConfig` sets no `useLocalCanvasKit`, so without it the
loader fetches from `https://www.gstatic.com/flutter-canvaskit/<engineRevision>/`
and the GUI white-screens on a router with no WAN.

Consequences worth knowing before touching any of this:

- The engine also emits its own (correct) CanvasKit into `build/web/canvaskit/`.
  Nothing ever requests it. `build_web.sh`'s `pruneWebOutput()` deletes it
  (#1292) because it is ~37 MB of flash, but pruning is a payload decision — it
  is not what makes the committed copy authoritative. That line above is.
- Only the `full` variant ships. `web/assets/chromium/` was deleted in #1281 to
  reclaim 1.71 MB, and `canvasKitVariant: "full"` in the bootstrap is what stops
  capability detection routing Chromium browsers at the deleted path. **3.47 adds
  a second such path**: the loader now chooses between `webparagraph/` and
  `chromium/`, both behind the same `variant !== "full"` check, and the SDK ships
  both (they appear in `wasmHashes`). We vendor neither, so that one config line
  now guards two holes rather than one.
- `web/flutter_bootstrap.js` is a **template**: the build substitutes three
  `{{...}}` placeholders into the committed file. Do not replace one with a value
  read out of `build/web/`. #1316 found all three frozen as literals, which is
  how a 3.27-era loader and an `engineRevision` belonging to no pinned SDK
  survived every upgrade. That file's own header comment has the detail.

## The two files are one artifact

`canvaskit.js` is glue for `canvaskit.wasm` and the two are version-locked.
Copy both or neither — a half-copy white-screens immediately. Verified by
instantiating all four combinations in Node:

| glue | wasm | Result |
|---|---|---|
| 3.44 | 3.44 | OK |
| 3.47 | 3.47 | OK |
| 3.44 | 3.47 | **CRASH** — `pb.setFillType is not a function` |
| 3.47 | 3.44 | **CRASH** — `this._setFillType is not a function` |

The coupling point is `PathBuilder.prototype._setFillType`, which exists only in
3.47.

## Update procedure

Do all of this in **one** commit.

1. Install and select the SDK, and bump the local pin:

   ```bash
   fvm install <version>
   fvm use <version>              # rewrites .fvmrc
   fvm flutter --version          # confirm
   fvm flutter precache --web     # see below — the source directory does not
                                  # exist until this runs
   ```

   `flutter_web_sdk/` is an **on-demand** artifact. A fresh `fvm install` does
   not fetch it, and neither does `flutter test`, so without the precache the
   path in step 2 simply does not exist and `cp` fails as if it were mistyped.
   `run_tests.sh` runs the same precache itself, right after it resolves
   `$FLUTTER`, so both a developer's pre-push command and CI's unit-test job are
   covered by that one line — the prerequisite travels with the command instead of
   with a runner. Any job that runs `test/web/` *without* going through that
   script needs its own precache; the guard's failure message says so.

2. Re-vendor both files. Copy **only** these two — the source directory also
   holds `chromium/` (must not come back, #1281), `*.js.symbols`, `skwasm*` and
   `wimp*`:

   ```bash
   SDK=.fvm/flutter_sdk/bin/cache/flutter_web_sdk/canvaskit
   cp "$SDK/canvaskit.js"   web/assets/canvaskit.js
   cp "$SDK/canvaskit.wasm" web/assets/canvaskit.wasm
   git status --porcelain -- web/assets   # one or two modified, zero new
   ```

   One modified file is a normal outcome, not a half-copy: across a hotfix the
   glue often does not change at all (3.47.0 → 3.47.2 changed only the wasm).
   Zero new files is the part that matters — a new entry means `chromium/` or a
   `.symbols` file came along, and #1281 says it must not.

3. Update the tables above, including the sizes and hashes:

   ```bash
   shasum -a 256 web/assets/canvaskit.js web/assets/canvaskit.wasm
   python3 -c "import json;d=json.load(open('.fvm/flutter_sdk/bin/cache/flutter.version.json'));print(d['frameworkVersion'],d['frameworkRevision'],d['engineRevision'],d['dartSdkVersion'])"
   ```

4. Move the CI pin to match: `flutter-version:` in
   `.github/actions/setup/action.yml`.

5. Move the constants in `test/web/canvaskit_variant_test.dart`
   (`_pinnedFlutterVersion`, `_pinnedEngineRevision`, `_vendoredCanvasKit`), and
   the two **prose** copies of the version the guard also greps: the
   `## Flutter SDK Pin` section of `CLAUDE.md` and the `Environment:` header
   comment in `build_web.sh`. The guard will name whichever you forget, so this
   is a checklist and not a trap — but it fails the suite, so do it in the same
   commit.

6. Run the guard, then **prove it still bites** — a guard nobody has seen fail
   is not yet a guard:

   ```bash
   fvm flutter test test/web/canvaskit_variant_test.dart
   # revert one file on purpose; the run above must now fail
   ```

   Then run `fvm flutter analyze`, and read the result as a bump artefact rather
   than a surprise. Warnings are **fatal** in CI (`ci.yml`, job 1), so an SDK that
   introduces a new diagnostic class turns some unrelated PR red — that is the
   deliberate tradeoff, and `invalid_return_type_for_then` arrived exactly that
   way in Dart 3.13. Fix the warnings in this commit, or downgrade that one
   diagnostic under `analyzer: errors:` in `analysis_options.yaml`. Do not reach
   for `--no-fatal-warnings`.

   Two more things the same SDK swap can move, both cheap to re-check and both
   silent when they drift:

   * `analysis_options.yaml`'s `exclude:` block — `flutter pub get` rewrites it,
     and 3.47.0 vs 3.47.2 already disagree about it. See the comment there.
   * the `serviceWorkerVersion` reasoning in `web/flutter_bootstrap.js`, which is
     measured against the SDK's own `flutter_js/flutter.js`. That comment names
     the one-line grep that re-verifies it.

7. Golden baselines are SDK-sensitive: the first 3.47.0 run in
   `linksys/PrivacyGUI-golden-ci` produced 312 failures against a baseline
   rendered on 3.44.9, with no baseline change. Moving this pin means
   reconciling that repo's pin with ours; baseline and verify must share one.

   Sensitive to the *minor*, on the evidence so far — a hotfix has not moved a
   pixel (3.47.0 baseline verified clean under 3.47.2). Do not read that as a
   rule: check the first verify run after any bump rather than assuming it.

8. Browser-verify. No automated check here can: `flutter build web` has no
   opinion on what wasm sits in `web/assets/`, and the golden suite runs in the
   Flutter test VM with no CanvasKit involved at all. Boot a release build in
   Chromium and in WebKit, confirm DevTools shows `assets/canvaskit.wasm` served
   locally, and check CJK / Thai / Arabic / Latin-Ext with WAN disconnected
   (intersects #1285 and the offline font subsets in `pubspec.yaml`).

   **Two different gstatic hosts, and only one of them must be silent.**
   `www.gstatic.com/flutter-canvaskit/<engineRevision>/` is the CDN path the
   loader falls back to when `canvasKitBaseUrl` is missing, and it must show
   **zero** requests — a hit there means the offline requirement is already
   broken. `fonts.gstatic.com` is a different matter: `fontFallbackBaseUrl` in
   `web/flutter_bootstrap.js` points at it deliberately, so that an online client
   can still render code points outside the bundled subsets. Requests to it are
   expected, and offline they fail by design — which is what the bundled subsets
   cover. Filtering DevTools on "gstatic" alone therefore looks like a failure
   when it is not; filter on `flutter-canvaskit`.

9. Deploy to the router and verify there, not only behind a local server. A
   desktop server proves the bundle boots; it does not prove what the device
   serves. The router's lighttpd (1.4.75) has **no** compression built in — `-V`
   prints `- brotli support` — so `Compress=true` output is served by the
   pre-compressed rewrite in `/etc/lighttpd/conf.d/60-brotli-precompressed.conf`,
   which rewrites `main.dart.js` and `assets/canvaskit.wasm` to their `.br`
   siblings and restates the headers. Two consequences for a CanvasKit bump:
   `build_web.sh` deletes the originals, so the `.br` **is** the shipped wasm and
   a re-vendor that skips recompression ships the previous hotfix's bytes; and
   because no original survives, a client that does not offer `br` gets a 404
   (measured: `Accept-Encoding: gzip, deflate` → 404, `br` → 200 +
   `content-encoding: br` + `application/wasm`). Chrome only offers `br` over
   TLS, which the router's `:80 → :443` redirect guarantees.

## What the guard cannot see

The hashes catch a vendored copy that stopped matching the SDK, and the pin
comparison catches local and CI disagreeing. Neither can see a *rendering*
difference between two correctly-paired versions — that is browser-only, which
is why steps 8 and 9 are human steps and not tests.
