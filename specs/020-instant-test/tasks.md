# Tasks: Instant-Test USP 2.4.0 Port

## Phase 1 (DONE)
- [x] Create `feature/instant-test-usp` from `dev-2.4.0` commit `f0db1915`
- [x] Create `lib/page/instant_test/` directory structure
- [x] Migrate `verdict.dart` to `DeviceUIModel` + `NodeUIModel`
- [x] Migrate `device_score.dart` to `DeviceUIModel` (downlinkRate bits/sec)
- [x] Migrate `customer_journey.dart` (no changes needed)
- [x] Copy `browser_diagnostic_service.dart` (pure HTTP, no changes)
- [x] Write `instant_test_state.dart` (typed USP fields)
- [x] Write `instant_test_provider.dart` (watches 4 providers)
- [x] Add route `RouteNamed.uspInstantTest` to constants + dashboard route
- [x] Add menu card to `UspMenuView`
- [x] 4-tab scaffold (`InstantTestPage`, stub tabs)
- [x] `dart analyze lib/page/instant_test/` = zero errors

## Phase 2 (DONE)
- [x] Mock notifier (`test/mocks/mock_instant_test_notifier.dart`)
- [x] Test data (`test/mocks/test_data/instant_test_state_data.dart`)
- [x] `verdict_test.dart` (all 19 checks, migrated to DeviceUIModel/NodeUIModel)
- [x] `device_score_test.dart` (scoring math)
- [x] `node_ui_model_test.dart` (backhaul weak detection)
- [x] `instant_test_mock_scenarios_test.dart` (state factory scenarios)
- [x] `overview_tab_test.dart`, `my_devices_tab_test.dart`, `my_network_tab_test.dart`, `help_me_fix_it_tab_test.dart`
- [x] 88 tests passing
- [x] `restartRouter()` with `uspMutationLockProvider` + localStorage timestamp
- [x] `showRecoveryDialog(trigger: RecoveryTrigger.operationalReboot)` in `overview_tab.dart`
- [x] `speedTestProvider` wired for router→internet leg
- [x] `routerInternetResult` field in state + WiFi bottleneck finding in VerdictEngine
- [x] Flow 3 whitelist copy (D-R3): `help_me_fix_it_tab.dart` uses `disable()`, "allow" wording
- [x] Spec docs: spec.md, plan.md, tasks.md

## Phase 3 (DONE)
- [x] My Devices tab: `UspDeviceListTile` + score badge + "Troubleshoot this device" bottom sheet
- [x] My Network tab: `UspNetworkTopologyCard` embedded + backhaul health rows + speed legs summary
- [x] Client→Router speed leg: `runRouterSpeedTest()` called after client→internet leg
- [x] Localization: 30+ keys added to `app_en.arb`, `flutter gen-l10n` passes
- [x] All views use `loc()` for user-facing strings
- [x] `dart analyze lib/page/instant_test/` = zero errors

## Remaining (post-GA backlog)
- [ ] Guest toggle V1.1 (D-R2): add once USP WiFi-settings save semantics are understood
- [ ] iOS native (D-R5): unblock when USP native transport lands
- [ ] Integration test on M60CF-EU hardware (router + 3 mesh nodes)
- [ ] Localize non-English ARB files (translate from English keys)
- [ ] PR to `dev-2.4.0` once firmware GA timeline is confirmed
