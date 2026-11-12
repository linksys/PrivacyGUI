# Vendored USP Artifacts

Files in this repo that are built or generated from `linksys/usp_framework` and checked in as-is. This is the single source of truth for their upstream origin and current version.

**Not the only vendored artifacts.** `web/assets/canvaskit.{js,wasm}` are also hand-copied and committed, from the pinned Flutter SDK rather than from `usp_framework`. They have their own manifest and update procedure in `doc/web/vendored-canvaskit.md`. They were missing from every manifest in the repo until #1316, which is how a 3.44.0 CanvasKit survived CI's move to 3.47.0 unnoticed.

## Upstream

- **Local path**: `linksys/usp/usp_framework/`
- **Repo**: `github.com/linksys/usp_framework`

## Manifest

**Last updated**: 2026-11-11 (usp-client 0.16.0, linksys/usp_framework#61 and #118, #1787; see below). Before that 2026-11-09 (usp-client 0.14.0, linksys/usp_framework#114). Before that 2026-10-27 (all of `lib/generated` on usp-codegen 0.19.0, from `usp_framework` `main` @ `3d0bbef`, #1654; see below)

The web package records reviewed `usp_framework` commit
`7902af856a08f324009b533cd2b26bbdc1741b70`, the commit CI built the 0.16.0
package from (run 42764973857, artifact `usp-client-wasm-7902af85…`, whose
`artifact-manifest.json` binds the bytes to that commit). It reached `main` as
`dba763c` (PR #121, linksys/usp_framework#118), and the `pkg/` files there are
byte-identical to the artifact: the three files match its SHA-256 digests and
upstream's git blobs. It was built with both the `wasm` and `websocket`
features.

**0.15.0 and 0.16.0 change how a failed call reads (#1787).** 0.15.0 (PR #119,
linksys/usp_framework#61): a request the router refuses as a whole (a USP
`Error`) keeps the router's code and message, where it used to be a 9999
wrapping `Protocol error: … Received error response: … (code: N)`; an answer
the client cannot decode is 9998 (`Protocol error: …`) and input it refuses is
9997 (`Validation error: …`), both 9999 before; a transport failure has one
`Transport error: ` prefix instead of two. 0.16.0 (PR #121,
linksys/usp_framework#118) adds `result.errors`, a list of
`{ kind, path?, errorCode, errorMessage }` next to the `error` map, which is
deprecated and goes in the next minor release. `UspClient` reads a Get and an
Operate by it: an entry of `kind: request` is the call failing as a whole, and
throws; `kind: path` is one path (a Get's 7026, a command the router refused).
A router code under `kind: request` is rethrown as `Protocol error: … (code: N)`,
the shape 0.14.0 gave it, so `mapUspErrorToServiceError` maps it as before: a
7016 for a mesh node that has left is still `ResourceNotFoundError`. Writes
read the same list (`UspResultParser`): one failure per entry, its `kind`
carried for the log and deciding nothing, so a write still reads as success,
partial success or failure by `success` and whether any entry is there. A
refused atomic write carries the router's code under `kind: request`. Nothing
in the app reads the `error` map any more, so the client release that drops it
needs no app change; the list also keeps a second entry under a path the map
would overwrite. `test/web/usp_operate_test.mjs` runs the
vendored client from Node against `test/web/usp_operate_errors.json`, the same
fixture the Dart mapping tests read.

0.14.0 was built from `d5604633785091f94d93c9a992f3848ece7fb6e8` (run
42589938930), and reached `main` as `381d69f` (PR #116,
linksys/usp_framework#114).

**0.14.0 changes what a refused Add returns.** An agent that creates an object
but refuses some of its parameters reports each one in AddResp's
`OperationSuccess.param_errs`. The client sends every Add parameter with
`required: false`, so FL-WRT's FWDEV#204 checks land there, and 0.13.0 dropped
them: a refused Add answered as a clean success. 0.14.0 keeps `success: true`
and the instance in `data.instances`, since the row does exist on the router,
and adds one `error` entry per refused parameter, keyed
`<instance path><param>`. `UspResultParser.parseAddResult` reads that as a
`UspPartialSuccess`, so the services that add rows now report a failed save.
Measured, 2026-11-09: the bench's captured response to a 26th port trigger
(FW 2.0.4.26103108) decodes under 0.13.0 as a clean success, and under 0.14.0
with `Device.NAT.PortTrigger.26.Port` →
`ErrorTooManyRules: at most 25 port triggering rules.` (code 7005).
**The half-written row stays on the router**, so the app deletes it:
every service that adds rows parses the Add with
`parseAddRemovingRefusedRows` (`lib/page/_shared/services/refused_add_service.dart`;
batch saves call it through `BatchTally.recordAdd`). It deletes each instance
row a failure names, highest number first, and never a table path. When that
was every row the Add created, the Add reads as a complete failure, so the
page keeps the user's edit. Otherwise it stays a partial success, and the page
reads the router again. Port forwarding, IPv6 port services and DMZ do that
through `saveReadingBackAfterPartialWrite`
(`lib/framework/preservable_notifier_mixin.dart`), which also makes the next
Save read the router first when that re-read fails. DHCP reservations (#1698)
and static routes re-read after any failed save, since a refused Set there
still writes the rest, through `saveReadingBackAfterFailure`, which keeps the
same read-first rule. The dashboard's quick adds (port forwarding, DHCP)
refresh their card after a failure. DHCP's batch save moved to `BatchTally`
at the same time: it used to log a partial result and report it as saved.
`required: true` is linksys/usp_framework#115, still open.

0.13.0 was built from `d135f4df` (merged `main`, PR #59, the unmodified
Broadband Forum USP schemas, which fixed `OperateResp` swallowing synchronous
failures). Machine-verifiable local hashes and the
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
| 1 | `usp-codegen` (Mach-O arm64) | **0.19.0** | `tools/usp-codegen` | `usp-codegen/bin/usp-codegen` (built from `src/` via `Makefile.standalone`) |
| 2 | `usp_client.js` | **0.16.0** | `web/usp_client.js` | `usp-client/pkg/usp_client.js` |
| 3 | `usp_client_bg.wasm` | **0.16.0** | `web/usp_client_bg.wasm` | `usp-client/pkg/usp_client_bg.wasm` |
| 4 | `usp_client.d.ts` | **0.16.0** | `web/usp_client.d.ts` | `usp-client/pkg/usp_client.d.ts` |

## Derived (generated locally, not copied)

`lib/generated/*.g.dart` is produced on this machine by running `tools/usp-codegen` against `usp_framework/usp-definitions/`. Its output is a function of:
- the codegen binary version above, and
- the YAML snapshot in `usp_framework/usp-definitions/` at generation time.

The YAML definitions are **not vendored** into this repo and individual definitions commits are **not pinned** here. `lib/generated` is regenerated from the fork clone's latest `main`, so re-run the codegen (Update procedure step 2) when you need the output to be current rather than assuming what is checked in already is.

**All of `lib/generated` is on 0.19.0 (#1654).** It was generated from `usp_framework` `main` @ `3d0bbef`. 0.18.x reads every multi-instance table as a list, so a service picks the row it uses itself: the LAN DHCP pool by `Alias == dhcp-lan`, the firewall chain by `Name == Defaults Configuration`, the DHCP client of the WAN by its `Interface`, the routing table as the first router. 0.19.0 also checks the required leaves of every child, flattened and `interfaces:` row, so a row missing one fails the whole `fetch()` with 9998 instead of reading defaults; a test fixture must give each row every required leaf. `dynamic_routing` (#1100) and `data_elements_mlo_clients` (#1686) first came in on 0.18.1, and their 0.19.0 output is the same. Every definition has a consumer, so a full regeneration copies every file it writes. `ble_onboarding` (#879), `data_elements_network_operations` and the `X_LINKSYS_SupportedOperations` / `X_LINKSYS_DetectedName` leaves (#876, #1719) came in on earlier codegen; their 0.19.0 output has the same fields and paths, and adds the required-leaf check (issue #1730 re-checks `ble_onboarding` on a bench). `tr181_paths.g.dart` is not codegen output and is never regenerated.

**`data_elements_network.g.dart`, `data_elements_network_operations.g.dart` and `device_operations.g.dart` carry linksys/usp_framework#98 (#876).** They were first generated with 0.17.0 as below, and are now 0.19.0 output like the rest of `lib/generated` (#1654). #98 (FWDEV#225, merged 2026-10-23 as `8da6818`) adds FWDEV#202's `X_LINKSYS_SupportedOperations` leaf (`data_elements_network.yaml` 2.1.0), the `rebootNode` / `factoryResetNode` commands (`data_elements_network_operations.yaml` 1.1.0), and the children-first timing on `Device.Reboot()` / `Device.FactoryReset()` (`device_operations.yaml` 1.0.1, descriptions only). They were first generated contract first from #98's head `1fe6fd4`, then regenerated from upstream `main` at `3d0bbef` once it merged; #97 was the first PR for the same definitions and was closed in its favour. The 0.17.0 binary is the one checked in before #1597 (`git show abe529d33^:tools/usp-codegen`): `data_elements_network` is still on 0.17.0, and 0.18.1 rewrites 377 lines of it. Generated from upstream `main` before #98, 0.17.0 reproduces the earlier checked-in `data_elements_network.g.dart` byte for byte, so the diff is #98's additions alone; `device_operations.g.dart`'s diff is its two doc comments. `data_elements_network_operations.g.dart` is new (upstream has had `InitiateWPSPBC()` in it without a generated file here) and `index.dart` got its export by hand. **Recheck after #98 merged (#876):**
1. ~~Regenerate the three files from upstream `main` with the 0.17.0 binary and diff against the contract-first output.~~ **Done 2026-10-27** at `3d0bbef`: `data_elements_network.g.dart` unchanged; four doc comments changed, none of the code. `rebootNode` / `factoryResetNode` now say a freshly joined agent reads `""` until its capabilities reply, and `Device.Reboot()` / `Device.FactoryReset()` say the children are "commanded" first rather than all reboot first (#98 review W1/W2).
2. ~~Confirm upstream kept `supportedOperations` as `optional: true`.~~ **Done 2026-10-27**: it is, at `3d0bbef`. (It is fetched in the same `Device.*.` batch as the whole topology, and an unknown wildcard leaf in that batch is a per-path 7026 on 2.0.3.26102008, measured 2026-10-22.)
3. Re-read `X_LINKSYS_SupportedOperations` on a bench with a Linksys agent and, if one is available, a third-party one: `Reboot,FactoryReset` on the first, empty on the second. #98's review also expects `""` on a Linksys agent until its capabilities reply arrives; measure how long a freshly joined node shows no actions.
4. Re-check the error codes on an agent: 7022 when it does not confirm, 7016 for a row that is gone, and the 25 s cap with one resend. The page's messages are written against those (`usp_node_detail_view.dart`, `_nodeActionFailureText`).
5. ~~Re-measure the controller's `Device.Reboot()` with agents attached against the Administration recovery cooldown (#876 item 7).~~ **Superseded by linksys/Architecture#195 (#1777):** `Device.Reboot()` acts on the controller alone once linksys/feed_usp#79 is in the image, and the whole network is `X_LINKSYS_RebootAll()`, whose countdown starts when `NetworkActionStatus` reads `Completed` rather than at the reply. The measurement moved to the #113 recheck list below, item 3.
6. ~~Measure what a child that missed a controller reset looks like, and reword `factoryResetMeshMessage` then.~~ **Superseded by linksys/Architecture#195 (#1777):** `X_LINKSYS_FactoryResetAll()` resets the controller even when an agent does not confirm, as LinksysWRT 1.0 did, and names that agent in a syslog warning; the agent keeps the old network until it is reset with its button. `factoryResetMeshMessage` is kept as it is (decided 2026-11-12).


**`connected_devices.g.dart` carries `X_LINKSYS_DetectedName` (#1719).** #99 merged into upstream `main` and the file is now 0.19.0 output from `3d0bbef` (#1654), with the same fields, paths and `linksysDetectedName` parse as the 0.17.0 output described next. It was 0.17.0 output, like the rest of the 0.17 set, from upstream `main` at `89edd33` (`connected_devices.yaml` 2.1.0) with one optional, read-only leaf added locally: `linksysDetectedName` on `.X_LINKSYS_DetectedName`, which linksys/FWDEV#224 specifies and linksys/feed_premium#61 implements. Without the local leaf, the same command reproduces the checked-in file before #1719 byte for byte after formatting. The definition is linksys/usp_framework#99 (`connected_devices.yaml` 2.2.0, open), and its YAML at `bb261cb`, applied to `89edd33`, generates this file byte for byte after formatting (checked 2026-10-22). Once #99 merges, regenerate this one file with 0.17.0 from merged `main` and diff it against this one; a difference in anything but the description is a contract change to read before taking it.

**`gre_tunnels.g.dart`, `l2tp_tunnels.g.dart` and `wan_settings.g.dart` are contract first (#839, #840).** They are 0.19.0 output from `usp_framework` `main` @ `3d0bbef` plus linksys/usp_framework PR #105 (branch `feat/usp-definitions-wan-tunnel-interface-lowerlayers`, open): `gre_tunnel.yaml` / `l2tp_tunnel.yaml` 2.2.0 add the tunnel's `Interface.` child with `single: true` (an optional `Alias`, read only so the row is listed), `wan_settings.yaml` 4.2.0 adds the WAN's `LowerLayers`, read-only and required, and `ppp_interface.yaml` 1.2.0 changes only a description. Every other file the same command writes is unchanged. Each tunnel row now carries its interface's `instancePath`, which the service writes to `PPP.Interface.{i}.LowerLayers`, and the PPP row is the one the WAN's `LowerLayers` names (bench 2.0.3.26102008, see `doc/usp/issues/wan-fixed-instance-rows.md`). **Recheck once it merges:**
1. Regenerate the three files from `main` once linksys/usp_framework PR #105 merges and diff them against these; anything but a description is a contract change to read first.
2. ~~On an image with linksys/feed_usp PR #68 (PPP `LCPEcho` writable), save Keep Alive once and read `LCPEcho`, `LCPEchoRetry` and `LCPEchoAdaptive` back.~~ **Done 2026-10-28** on `2.0.3.26102124`, which has that PR: `LCPEcho` takes 20–180 and refuses 19 and 181, and one Set of `LCPEcho` 60, `LCPEchoRetry` 5, `LCPEchoAdaptive` false leaves uci `keepalive` `5 60` and `keepalive_adaptive` `0`. A PPPoE WAN went Keep Alive → On Demand (`IdleDisconnectTime` 900) → Keep Alive, and `ConnectionTrigger` = `AlwaysOn` cleared `demand` by itself.
3. Read `Device.Ethernet.VLANTermination.{i}` and the WAN's `LowerLayers` chain with VLAN tagging on, on an image with FWDEV#231's preconfig row; the page takes the only VLAN row until then.
4. Ask FW which `Device.IPv6rd.InterfaceSetting.{i}` row is the WAN's: with 6rd on, `TunneledInterface` stays empty on every row on `2.0.3.26102008`. The page takes the first row the table lists, which there is the row mapped to `network.wan6rd`.

**`system_info.g.dart` carries `hostName` (#1751).** It is 0.19.0 output from `usp_framework` `main` @ `4eabb53`, the merge of linksys/usp_framework#108: `system_info.yaml` 2.4.0 adds `hostName` on `.HostName`, read-only and optional, which the controller's name falls back to before its model (`MeshNetworkBuilder`, master branch). `lan_network_info.yaml` already reads the same leaf and keeps the write. It was first generated contract first from #108's branch (`5ccebaa`, on `a19b9d5`, the merge of PR #105); #107 was the same commit from a fork, closed because CI does not run on fork PRs there. **Recheck after #108 merged:** ~~regenerate `system_info.g.dart` from merged `main` and diff it against the contract-first output.~~ **Done 2026-11-02** at `4eabb53`: byte-identical, and every other file the command writes is unchanged, `gre_tunnels.g.dart`, `l2tp_tunnels.g.dart` and `wan_settings.g.dart` included, so the checked-in output of PR #105's head agrees with merged `main` too; `index.dart` comes out in a different order with the same exports and is left as checked in.

**`mac_filter_network.g.dart` and `subscriptions.g.dart` carry the MAC filter mode subscription (#1755).** They are 0.19.0 output from `usp_framework` `main` @ `4eabb53` with `mac_filter_network.yaml` replaced by its 1.1.0 from linksys/usp_framework#112, which has since merged as `298af0d`. The 1.1.0 file adds a ValueChange subscription, `mac-filter-mode-valuechange`, on `Device.WiFi.DataElements.Network.X_LINKSYS_MACFilterMode` alone. The two files differ from `4eabb53`'s output only by that subscription: a `subscribe()` method the app does not call, and one `coreSubscriptions` row, which a session registers only on firmware with `wifiMacFilter` (`coreSubscriptionsFor`). Every other file the same command writes is unchanged, and with the base YAML the command reproduces both checked-in files byte for byte. They are not generated from `main` because `main` has since gained `dynamic_dns.yaml` (#641), whose `ddns-valuechange` would enter `coreSubscriptions` with no consumer here. **Recheck after #112 merged:** ~~regenerate the two files from merged `main` and diff them against these.~~ **Done 2026-11-05** at `298af0d`, the merge of linksys/usp_framework#112: `mac_filter_network.g.dart` is byte-identical, and `subscriptions.g.dart` differs only by the `ddns-valuechange` row, which stays out until #641 consumes it. Until then, regenerate `subscriptions.g.dart` with `network/dynamic_dns.yaml` left out of the definitions directory, so the row does not come back; never delete it from the output by hand. **#641 now consumes it** (below), so this exclusion no longer applies.

**`dynamic_dns.g.dart` and `subscriptions.g.dart` carry Dynamic DNS (#641).** They are 0.19.0 output from `usp_framework` `main` @ `dba763c`, taken with `git archive upstream/main usp-definitions` as #1782 did, which holds `network/dynamic_dns.yaml` 1.0.0 from linksys/usp_framework#111 (merged 2026-11-04). Only these two files are taken, and `index.dart` gets the `dynamic_dns.g.dart` export by hand. `subscriptions.g.dart` differs from the checked-in file only by the `ddns-valuechange` row — ValueChange on `Device.DynamicDNS.Client.` — which the DDNS page's status now reads through `InvalidationDomain.dynamicDns`. The same command still rewrites `data_elements_network.g.dart`, `data_elements_network_info.g.dart`, `data_elements_network_operations.g.dart` and `device_operations.g.dart` (linksys/usp_framework#113, which belongs to #1777) and reorders `index.dart`; those were left as checked in, as #1782 left them, until #1777 took them (below). From here on `subscriptions.g.dart` is generated **with** `dynamic_dns.yaml`. PR #111's merge gate was a bench read, recorded here because the PR merged without one: on an M60-US at 2.0.4.26110110 (2026-11-11), `obuspa -c get Device.DynamicDNS.` serves all 14 paths of the definition with the shipped rows — `Server.1` DynDNS and `Server.2` No-IP enabled, `Client.1` and `Client.1.Hostname.1` disabled, `Client.1.Password` `""`, `Client.1.Interface` `""` (present, not absent), `Hostname.1.LastUpdate` `0001-01-01T00:00:00Z`. `Client.Server` and `Client.Interface` accept a path with or without the trailing dot and read back without it; the page writes the dotless form. A Set of `Client.Server` to `""` is refused (`This Server object has no ServiceName`, 7002), which the page never sends: "Disabled" writes `Enable` alone. The push the subscription relies on, which #111's review left unverified, holds on the same bench: with a ValueChange subscription on `Device.DynamicDNS.Client.`, the agent sends a Notify for `Client.1.Status`, `Client.1.LastError` and `Client.1.Hostname.1.Status` each time the updater moves them, and none for `Password`. Saving No-IP with a made-up account read `Connecting` / `NO_ERROR` / `Updating`, then within 4 s `Error` / `CONNECTION_ERROR` / `UpdateNeeded`, the WAN address being private (`192.168.200.118`); with `ddnsmngr.global.upd_privateip` set to `1` for the test it read `Error` / `AUTHENTICATION_ERROR` / `Error` within 7 s. `Enable` false then read `Disabled` and kept `Username`. Everything was put back to the shipped rows afterwards.

**`wi_fi_radios.g.dart` carries `channelsInUse` (#1782).** It is 0.19.0 output from `usp_framework` `main` @ `5292301`, which contains linksys/usp_framework#120 (merged 2026-11-11 as `5887110`): `wi_fi_radios.yaml` 1.2.0 adds `channelsInUse` on `.ChannelsInUse`, read-only, a required `string`, and says `channel` is the configured channel. Generated with `network/dynamic_dns.yaml` left out, as above, from `git archive upstream/main usp-definitions` rather than from the fork clone's checkout. Only this file is taken. The same command also rewrites `data_elements_network.g.dart`, `data_elements_network_info.g.dart`, `data_elements_network_operations.g.dart` and `device_operations.g.dart`; that is linksys/usp_framework#113 (Architecture#195, whole-network `X_LINKSYS_RebootAll()` / `X_LINKSYS_FactoryResetAll()`, the action-status leaves, and `Device.Reboot()` / `Device.FactoryReset()` described as this node only), which belongs to #1777 and was left as checked in until #1777 took it (below). With the definitions of `298af0d` the command reproduces every checked-in file byte for byte except `index.dart`'s order. Because the new leaf is required, a radio row without it fails `WiFiRadios.fetch()` with 9998; demo mode and the E2E runs read the canonical fixture in linksys/PrivacyGUI-USP-E2E, whose radios gain it in linksys/PrivacyGUI-USP-E2E#179.

**`data_elements_network.g.dart`, `data_elements_network_info.g.dart`, `data_elements_network_operations.g.dart` and `device_operations.g.dart` carry linksys/usp_framework#113 (#1777).** They are 0.19.0 output from `usp_framework` `main` @ `dba763c`, taken with `git archive dba763c usp-definitions`, which holds #113 (merged 2026-11-09 as `2ac8ad9`; linksys/Architecture#195). `data_elements_network_operations.yaml` 1.2.0 adds `rebootAll` / `factoryResetAll` on `Network.X_LINKSYS_RebootAll()` / `X_LINKSYS_FactoryResetAll()`; `data_elements_network_info.yaml` 1.1.0 adds `networkActionStatus` on `Network.X_LINKSYS_NetworkActionStatus`; `data_elements_network.yaml` 2.2.0 adds `nodeActionStatus` on `Device.{i}.X_LINKSYS_NodeActionStatus`; `device_operations.yaml` 1.0.3 describes `Device.Reboot()` / `Device.FactoryReset()` as acting on this node only, descriptions only. Both new leaves are read-only and optional. Every other file the command writes is unchanged, and `index.dart` comes out in a different order with the same exports and is left as checked in. On firmware without the leaves — 2.0.4.26110110 refuses a Get of `NetworkActionStatus` as not in the schema — each `fetch()` that carries one still succeeds with it absent, because a path the router does not have is a per-path 7026 that `UspClient.extractGetResult` leaves out. `UspAdminService` does not use the generated `DataElementsNetworkInfo.fetch()` for the status: it polls the one leaf with `fresh: true`, past the throttler's cache. `nodeActionStatus` has no consumer yet (#1777 item 6). **Recheck on the first image with linksys/feed_usp#79 and linksys/targets#316 (#1777):**
1. `NetworkActionStatus` is present with the mesh on and absent with it off, and reads `""` before any whole-network action. The app picks the command on presence alone (`UspAdminService.readNetworkActionStatus`), so a leaf that is absent on a meshed controller would send `Device.Reboot()` and restart the controller only. A read the router answers with a per-path error other than `7026` reads as absent too, because `UspClient.extractGetResult` throws only on `9999` and drops the rest; check that the leaf answers without one from the moment the controller accepts a login, right after boot included.
2. The reply's shape: `Status` `Started` in the output, and a second call while one runs refused with 7002. `UspAdminService` reads 7002 from the refusal's code and `Busy` from the output; record which one the agent sends, and what a `Failed` reply carries.
3. `NetworkActionStatus` goes `Running` → `Completed` while the app reads it every 2 s, then the controller goes down: measure how long after `Completed`, against the 60 s (reboot) and 90 s (factory reset) cooldown that starts there, with at least one agent attached.
4. Per-node progress (#1777 item 6): during a Reboot All, read `NodeActionStatus` on each agent row, for how long it can be read, and whether a row stays while its node restarts.
5. With the browser connected through an agent: the status read fails when that agent goes down, and the wait counts down from that failure. Record whether the probe then finds the controller still up, before its own turn.

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

3. **Web client assets** — copy CI's bytes, never a local build.
   `usp-client/pkg/` on `usp_framework` `main` already is CI's output (each
   release vendors it from the producer artifact). A local `wasm-pack build`
   does not reproduce it: measured for #1787, a local `usp_client_bg.wasm` is
   570427 bytes where CI's 0.16.0 is 562086.
   ```bash
   S=<full usp_framework commit on main>
   for f in usp_client.js usp_client_bg.wasm usp_client.d.ts; do
     gh api -H "Accept: application/vnd.github.raw" \
       "repos/linksys/usp_framework/contents/usp-client/pkg/$f?ref=$S" > web/$f
   done
   ```
   Then compare `git hash-object web/<file>` with upstream's blob for each
   file, and `shasum -a 256` with the producer artifact's
   `artifact-manifest.json` (`gh run download <run> -R linksys/usp_framework
   -n usp-client-wasm-<commit>`). The upstream commit to record is that
   manifest's `commit`, the one CI built from, not the merge on `main`.

4. **Update `web/usp-artifacts.json` and the version table above** in the same
   commit as the artifact change. Use the full upstream commit SHA and hashes
   from the producer artifact.

5. **Sanity checks**
   - `python3 tools/usp_boundary/verify_artifacts.py --manifest web/usp-artifacts.json --root .`
   - `python3 tools/usp_boundary/check_boundary.py --dts web/usp_client.d.ts --dart-root lib/core/usp/web --policy tools/usp_boundary/policy.json --root .`
   - `node --test test/web/usp_operate_test.mjs` — the vendored client against the shared error fixture
   - `flutter analyze lib/generated` — no new errors
   - `flutter analyze lib/page lib/core` — no new errors
   - Grep for removed APIs when bumping `usp-client` (e.g. `setOrderedWithOptions` was removed in 0.9.0)
