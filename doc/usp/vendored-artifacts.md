# Vendored USP Artifacts

Files in this repo that are built or generated from `linksys/usp_framework` and checked in as-is. This is the single source of truth for their upstream origin and current version.

**Not the only vendored artifacts.** `web/assets/canvaskit.{js,wasm}` are also hand-copied and committed, from the pinned Flutter SDK rather than from `usp_framework`. They have their own manifest and update procedure in `doc/web/vendored-canvaskit.md`. They were missing from every manifest in the repo until #1316, which is how a 3.44.0 CanvasKit survived CI's move to 3.47.0 unnoticed.

## Upstream

- **Local path**: `linksys/usp/usp_framework/`
- **Repo**: `github.com/linksys/usp_framework`

## Manifest

**Last updated**: 2026-10-27 (`data_elements_network`, `data_elements_network_operations` and `device_operations` from linksys/usp_framework#98, regenerated from upstream `main` `3d0bbef` after it merged, #876; see below). Before that 2026-10-16 (usp-codegen 0.17.0 → 0.18.1: multi-instance tables as lists, write builders, linksys/usp_framework#76 / #79; Internet Settings only)

The web package records reviewed `usp_framework` commit
`d135f4df652684bc176bc02d83ec4a1c7b84c65c` (merged `main`, PR #59 — the
unmodified Broadband Forum USP schemas, which fixed `OperateResp` swallowing
synchronous failures) and was built with both the
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
| 1 | `usp-codegen` (Mach-O arm64) | **0.18.1** | `tools/usp-codegen` | `usp-codegen/bin/usp-codegen` (built from `src/` via `Makefile.standalone`) |
| 2 | `usp_client.js` | **0.13.0** | `web/usp_client.js` | `usp-client/pkg/usp_client.js` |
| 3 | `usp_client_bg.wasm` | **0.13.0** | `web/usp_client_bg.wasm` | `usp-client/pkg/usp_client_bg.wasm` |
| 4 | `usp_client.d.ts` | **0.13.0** | `web/usp_client.d.ts` | `usp-client/pkg/usp_client.d.ts` |

## Derived (generated locally, not copied)

`lib/generated/*.g.dart` is produced on this machine by running `tools/usp-codegen` against `usp_framework/usp-definitions/`. Its output is a function of:
- the codegen binary version above, and
- the YAML snapshot in `usp_framework/usp-definitions/` at generation time.

The YAML definitions are **not vendored** into this repo and individual definitions commits are **not pinned** here. `lib/generated` is regenerated from the fork clone's latest `main`, so re-run the codegen (Update procedure step 2) when you need the output to be current rather than assuming what is checked in already is.

**`lib/generated` is only partly on 0.18.1 (#1597).** 0.18.x reads every multi-instance table as a list and removes fixed-row models, which breaks most services that consume them. The re-vendor is therefore split by feature, and only the definitions Internet Settings consumes were regenerated with 0.18.1: `wan_settings`, `ppp_interface`, `vlan_termination`, `ipv6settings`, `gre_tunnels`, `l2tp_tunnels`, `dhcpv6clients`, `ipv6rd_settings`. `wan_static_ip`, `wan_dhcp`, `wan_bridge`, `wan_pppoe`, `gre_tunnel` and `l2tp_tunnel` were removed and `index.dart` was edited by hand to match. Every other generated file, including `subscriptions.g.dart`, is still 0.17.0 output; the remaining features move with #1654. Until then, **do not regenerate the whole directory**: copy only the files of the feature being migrated. `wan_settings.yaml` 4.1.0 (`Enable` writable) is linksys/usp_framework#87. `data_elements_mlo_clients` (#1686, linksys/usp_framework#93) is new and was generated with 0.18.1 from that one definition alone; the other DataElements files (`data_elements_network`, `data_elements_network_info`, `data_elements_interfaces`) are still 0.17.0 output.

**`ble_onboarding.g.dart` and `ble_onboarding_operations.g.dart` are 0.18.1 output (#879).** They are new files for adding a node over BLE (`core/ble_onboarding.yaml` and `core/ble_onboarding_operations.yaml` 1.0.0, linksys/usp_framework#82, generated from upstream `main` at `89edd33`), the read side and the `Start()` / `Scan()` / `Stop()` commands of `Device.X_LINKSYS_BLEOnboarding.`. Only they were copied, and `index.dart` got their exports by hand. The generator writes the `Device.{i}` table's base path in `ble_onboarding.g.dart` as a `final` string, which `flutter analyze` reports as one `prefer_const_declarations` info; it is left as generated.

**`data_elements_network.g.dart`, `data_elements_network_operations.g.dart` and `device_operations.g.dart` are 0.17.0 output from linksys/usp_framework#98 (#876).** #98 (FWDEV#225, merged 2026-10-23 as `8da6818`) adds FWDEV#202's `X_LINKSYS_SupportedOperations` leaf (`data_elements_network.yaml` 2.1.0), the `rebootNode` / `factoryResetNode` commands (`data_elements_network_operations.yaml` 1.1.0), and the children-first timing on `Device.Reboot()` / `Device.FactoryReset()` (`device_operations.yaml` 1.0.1, descriptions only). They were first generated contract first from #98's head `1fe6fd4`, then regenerated from upstream `main` at `3d0bbef` once it merged; #97 was the first PR for the same definitions and was closed in its favour. The 0.17.0 binary is the one checked in before #1597 (`git show abe529d33^:tools/usp-codegen`): `data_elements_network` is still on 0.17.0, and 0.18.1 rewrites 377 lines of it. Generated from upstream `main` before #98, 0.17.0 reproduces the earlier checked-in `data_elements_network.g.dart` byte for byte, so the diff is #98's additions alone; `device_operations.g.dart`'s diff is its two doc comments. `data_elements_network_operations.g.dart` is new (upstream has had `InitiateWPSPBC()` in it without a generated file here) and `index.dart` got its export by hand. **Recheck after #98 merged (#876):**
1. ~~Regenerate the three files from upstream `main` with the 0.17.0 binary and diff against the contract-first output.~~ **Done 2026-10-27** at `3d0bbef`: `data_elements_network.g.dart` unchanged; four doc comments changed, none of the code. `rebootNode` / `factoryResetNode` now say a freshly joined agent reads `""` until its capabilities reply, and `Device.Reboot()` / `Device.FactoryReset()` say the children are "commanded" first rather than all reboot first (#98 review W1/W2).
2. ~~Confirm upstream kept `supportedOperations` as `optional: true`.~~ **Done 2026-10-27**: it is, at `3d0bbef`. (It is fetched in the same `Device.*.` batch as the whole topology, and an unknown wildcard leaf in that batch is a per-path 7026 on 2.0.3.26102008, measured 2026-10-22.)
3. Re-read `X_LINKSYS_SupportedOperations` on a bench with a Linksys agent and, if one is available, a third-party one: `Reboot,FactoryReset` on the first, empty on the second. #98's review also expects `""` on a Linksys agent until its capabilities reply arrives; measure how long a freshly joined node shows no actions.
4. Re-check the error codes on an agent: 7022 when it does not confirm, 7016 for a row that is gone, and the 25 s cap with one resend. The page's messages are written against those (`usp_node_detail_view.dart`, `_nodeActionFailureText`).
5. Re-measure the controller's `Device.Reboot()` with agents attached against the Administration recovery cooldown (#876 item 7). Per #98 there is no fixed maximum: about a second per level that confirms and 22 to 25 s per level that does not, so three unresponsive levels take 72 s plus up to 15 s of topology reads.
6. The children of a controller reset are best-effort (#98 review): a child that does not confirm is not reported and does not stop the controller. `factoryResetMeshMessage` (`router_restart_actions.dart`) says every node returns to factory settings; measure what a child that missed the command looks like, and reword it then (decided 2026-10-22 to wait for the measurement).

**`dynamic_routing.g.dart` is 0.18.1 output too (#1100).** It is a new file for the NAT / Dynamic routing switch (`dynamic_routing.yaml` 1.0.0, linksys/usp_framework#89, generated from upstream `main` at `ebfcbd0`), one object with one leaf, so 0.18.x's list change does not touch it. Only it was copied, and `index.dart` got its export by hand. `static_routing.g.dart` was **not** regenerated: upstream's `static_routing.yaml` is now 2.0.0, which nests the forwarding rules under `Device.Routing.Router.{i}` and so changes what the Static Routing service reads; it moves with #1654.

Make sure that clone's `main` is up to date with `upstream` (`github.com/linksys/usp_framework`), not just with `origin`. Generating from a stale fork `main` silently reproduces the bug #1555 fixed: the fork's `data_elements_network.yaml` was the 2026-08-05 revision and had no `data_elements_network_info.yaml`.

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
   fvm dart format lib/generated
   ```
   Run the format **from the repo root**, on `lib/generated` — not on a temp
   output directory. The style is decided by this package's language version
   (`pubspec.yaml` pins `sdk: ">=3.3.0 <4.0.0"`, below 3.7), so formatting in
   place is a no-op on untouched files; formatting a temp directory resolves to
   the newest language version, switches to the 3.7 "tall" style, and turns a
   3-file change into a 46-file diff of pure noise.

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
