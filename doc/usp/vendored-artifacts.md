# Vendored USP Artifacts

Files in this repo that are built or generated from `linksys/usp_framework` and checked in as-is. This is the single source of truth for their upstream origin and current version.

## Upstream

- **Local path**: `linksys/usp/usp_framework/`
- **Repo**: `github.com/linksys/usp_framework`

## Manifest

**Last updated**: 2026-08-05

The web package records reviewed `usp_framework` commit
`344a1757f97bcc8643b05322027aafd7053856cd` (merged `main`, PR #45
WebSocket readiness) and was built with both the
`wasm` and `websocket` features. Machine-verifiable local hashes and the
reviewed upstream paths are recorded in `web/usp-artifacts.json`. Consumer CI
does not authenticate the cross-repository commit reference; the producer
repository owns the source-to-committed-package rebuild gate.

The generated TypeScript surface includes `UspClient.subscribe()` and
`unsubscribe()`, but PrivacyGUI intentionally does not bind those methods.
Application subscriptions go through the authenticated `UspBridgeClient` and
SSE lifecycle instead. `tools/usp_boundary/policy.json` records that decision
and fails if either the upstream method or the consumer policy disappears
without review.

| # | Artifact | Version | Checked-in path | Upstream source |
|---|----------|---------|-----------------|-----------------|
| 1 | `usp-codegen` (Mach-O arm64) | **0.16.0** | `tools/usp-codegen` | `usp-codegen/bin/usp-codegen` (built from `src/` via `Makefile.standalone`) |
| 2 | `usp_client.js` | **0.12.0** | `web/usp_client.js` | `usp-client/pkg/usp_client.js` |
| 3 | `usp_client_bg.wasm` | **0.12.0** | `web/usp_client_bg.wasm` | `usp-client/pkg/usp_client_bg.wasm` |
| 4 | `usp_client.d.ts` | **0.12.0** | `web/usp_client.d.ts` | `usp-client/pkg/usp_client.d.ts` |

## Derived (generated locally, not copied)

`lib/generated/*.g.dart` is produced on this machine by running `tools/usp-codegen` against `usp_framework/usp-definitions/`. Its output is a function of:
- the codegen binary version above, and
- the YAML snapshot in `usp_framework/usp-definitions/` at generation time.

The YAML definitions are **not vendored** into this repo.

## Update procedure

1. **Codegen binary**
   ```bash
   cd linksys/usp/usp_framework/usp-codegen
   make -f Makefile.standalone clean all
   cp bin/usp-codegen linksys/PrivacyGUI/tools/usp-codegen
   linksys/PrivacyGUI/tools/usp-codegen --version  # verify
   ```

2. **Regenerate `.g.dart`** (bypasses the known `--local` bug in `tools/usp-codegen.sh`, see `doc/usp/issues/usp-codegen-script-issue.md`)
   ```bash
   cd linksys/PrivacyGUI
   ./tools/usp-codegen \
     --definitions-dir linksys/usp/usp_framework/usp-definitions \
     --output-dir lib/generated \
     --language dart \
     --client-import 'package:privacy_gui/core/usp/services/usp_client.dart' \
     --client-class 'UspClient'
   dart format lib/generated
   ```

3. **Web client assets**
   ```bash
   cd linksys/usp/usp_framework/usp-client
   wasm-pack build --release --target web --out-dir pkg --features wasm,websocket
   cd -
   cp linksys/usp/usp_framework/usp-client/pkg/usp_client.js      web/usp_client.js
   cp linksys/usp/usp_framework/usp-client/pkg/usp_client_bg.wasm web/usp_client_bg.wasm
   cp linksys/usp/usp_framework/usp-client/pkg/usp_client.d.ts    web/usp_client.d.ts
   ```

4. **Update `web/usp-artifacts.json` and the version table above** in the same
   commit as the artifact change. Use the full upstream commit SHA and hashes
   from the producer artifact.

5. **Sanity checks**
   - `python3 tools/usp_boundary/verify_artifacts.py --manifest web/usp-artifacts.json --root .`
   - `python3 tools/usp_boundary/check_boundary.py --help`
   - `flutter analyze lib/generated` — no new errors
   - `flutter analyze lib/page lib/core` — no new errors
   - Grep for removed APIs when bumping `usp-client` (e.g. `setOrderedWithOptions` was removed in 0.9.0)
