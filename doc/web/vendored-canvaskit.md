# Vendored CanvasKit

`web/assets/canvaskit.js` and `web/assets/canvaskit.wasm` are hand-copied from
the Flutter SDK and committed. They are the **only** CanvasKit that ever
executes in a PrivacyGUI build, so this file is the source of truth for which
SDK they came from.

Sibling of `doc/usp/vendored-artifacts.md`, which covers the USP artifacts
(`tools/usp-codegen`, `web/usp_client.*`) and nothing else.

## Manifest

**Last updated**: 2026-08-29 (#1316)

| Field | Value |
|---|---|
| Source SDK | Flutter **3.47.0** (stable) |
| Framework revision | `4cf24164269a5ebf0c16a028a00727d0e77bbb05` |
| Engine revision | `5f77625673248ee5846fbcaf5d3e1a3878386fd7` |
| Dart SDK | 3.13.0 |
| Source directory | `<sdk>/bin/cache/flutter_web_sdk/canvaskit/` |

| Artifact | Bytes | sha256 |
|---|---|---|
| `web/assets/canvaskit.js` | 86987 | `bb559f6080c7d312ac2a912b4abec9f68ff3d3022d4a603c7796b9b31460642b` |
| `web/assets/canvaskit.wasm` | 7284349 | `2898c0795cf4a694e86ee3445c7414c2503fbcb46967154762f50ebde988da04` |

`.fvmrc` and `.github/actions/setup/action.yml` both pin 3.47.0, and
`test/web/canvaskit_variant_test.dart` asserts that they agree with each other,
with the hashes above, and with the SDK the test is running under.

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
  capability detection routing Chromium browsers at the deleted path.
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
   CI pays the same cost explicitly, in `ci.yml`'s unit-test job.

2. Re-vendor both files. Copy **only** these two — the source directory also
   holds `chromium/` (must not come back, #1281), `*.js.symbols`, `skwasm*` and
   `wimp*`:

   ```bash
   SDK=.fvm/flutter_sdk/bin/cache/flutter_web_sdk/canvaskit
   cp "$SDK/canvaskit.js"   web/assets/canvaskit.js
   cp "$SDK/canvaskit.wasm" web/assets/canvaskit.wasm
   git status --porcelain -- web/assets   # exactly two modified, zero new
   ```

3. Update the tables above, including the sizes and hashes:

   ```bash
   shasum -a 256 web/assets/canvaskit.js web/assets/canvaskit.wasm
   python3 -c "import json;d=json.load(open('.fvm/flutter_sdk/bin/cache/flutter.version.json'));print(d['frameworkVersion'],d['frameworkRevision'],d['engineRevision'],d['dartSdkVersion'])"
   ```

4. Move the CI pin to match: `flutter-version:` in
   `.github/actions/setup/action.yml`.

5. Move the constants in `test/web/canvaskit_variant_test.dart`
   (`_pinnedFlutterVersion`, `_pinnedEngineRevision`, `_vendoredCanvasKit`).

6. Run the guard, then **prove it still bites** — a guard nobody has seen fail
   is not yet a guard:

   ```bash
   fvm flutter test test/web/canvaskit_variant_test.dart
   # revert one file on purpose; the run above must now fail
   ```

7. Golden baselines are SDK-sensitive: the first 3.47.0 run in
   `linksys/PrivacyGUI-golden-ci` produced 312 failures against a baseline
   rendered on 3.44.9, with no baseline change. Moving this pin means
   reconciling that repo's pin with ours; baseline and verify must share one.

8. Browser-verify. No automated check here can: `flutter build web` has no
   opinion on what wasm sits in `web/assets/`, and the golden suite runs in the
   Flutter test VM with no CanvasKit involved at all. Boot a release build in
   Chromium and in WebKit, confirm DevTools shows `assets/canvaskit.wasm` served
   locally with zero requests to `gstatic.com`, and check CJK / Thai / Arabic /
   Latin-Ext with WAN disconnected (intersects #1285 and the offline font
   subsets in `pubspec.yaml`).

## What the guard cannot see

The hashes catch a vendored copy that stopped matching the SDK, and the pin
comparison catches local and CI disagreeing. Neither can see a *rendering*
difference between two correctly-paired versions — that is browser-only, which
is why step 8 is a human step and not a test.
