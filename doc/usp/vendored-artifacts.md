# Vendored USP Artifacts

Files in this repo that are built or generated from `linksys/usp_framework` and checked in as-is. This is the single source of truth for their upstream origin and current version.

## Upstream

- **Local path**: `/Users/hankyu/linksys/usp/usp_framework/`
- **Repo**: `github.com/linksys/usp_framework`

## Manifest

**Last updated**: 2026-04-29

| # | Artifact | Version | Checked-in path | Upstream source |
|---|----------|---------|-----------------|-----------------|
| 1 | `usp-codegen` (Mach-O arm64) | **0.12.5** | `tools/usp-codegen` | `usp-codegen/bin/usp-codegen` (built from `src/` via `Makefile.standalone`) |
| 2 | `usp_client.js` | **0.9.0** | `web/usp_client.js` | `usp-client/pkg/usp_client.js` |
| 3 | `usp_client_bg.wasm` | **0.9.0** | `web/usp_client_bg.wasm` | `usp-client/pkg/usp_client_bg.wasm` |

## Derived (generated locally, not copied)

`lib/generated/*.g.dart` is produced on this machine by running `tools/usp-codegen` against `usp_framework/usp-definitions/`. Its output is a function of:
- the codegen binary version above, and
- the YAML snapshot in `usp_framework/usp-definitions/` at generation time.

The YAML definitions are **not vendored** into this repo.

## Update procedure

1. **Codegen binary**
   ```bash
   cd /Users/hankyu/linksys/usp/usp_framework/usp-codegen
   make -f Makefile.standalone clean all
   cp bin/usp-codegen /Users/hankyu/linksys/PrivacyGUI/tools/usp-codegen
   /Users/hankyu/linksys/PrivacyGUI/tools/usp-codegen --version  # verify
   ```

2. **Regenerate `.g.dart`** (bypasses the known `--local` bug in `tools/usp-codegen.sh`, see `doc/usp/issues/usp-codegen-script-issue.md`)
   ```bash
   cd /Users/hankyu/linksys/PrivacyGUI
   ./tools/usp-codegen \
     --definitions-dir /Users/hankyu/linksys/usp/usp_framework/usp-definitions \
     --output-dir lib/generated \
     --language dart \
     --client-import 'package:privacy_gui/core/usp/services/usp_client.dart' \
     --client-class 'UspClient'
   dart format lib/generated
   ```

3. **Web client assets**
   ```bash
   cp /Users/hankyu/linksys/usp/usp_framework/usp-client/pkg/usp_client.js      web/usp_client.js
   cp /Users/hankyu/linksys/usp/usp_framework/usp-client/pkg/usp_client_bg.wasm web/usp_client_bg.wasm
   ```

4. **Update the version table above** in the same commit as the artifact change.

5. **Sanity checks**
   - `flutter analyze lib/generated` — no new errors
   - `flutter analyze lib/page lib/core` — no new errors
   - Grep for removed APIs when bumping `usp-client` (e.g. `setOrderedWithOptions` was removed in 0.9.0)
