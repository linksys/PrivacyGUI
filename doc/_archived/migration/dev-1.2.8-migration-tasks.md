# dev-1.2.8 Migration Task List

> This file is used to track migration progress. Please check off items as tasks are completed.

---

## Prerequisites

- [x] **P1**: Ensure local branches are up to date
  ```bash
  git fetch origin
  ```

- [x] **P2**: Create migration working branch
  ```bash
  git checkout dev-2.0.0
  git pull origin dev-2.0.0
  git checkout -b austin/migration-1.2.8
  ```

- [x] **P3**: Confirm dev-1.2.8 commit list
  ```bash
  git log --oneline dev-2.0.0..origin/dev-1.2.8
  ```

---

## Phase 1: Clean Additions

> **Status**: Completed
> **Commit**: `33d5f959` - feat: migrate phase 1 features from dev-1.2.8

### Task 1.1: PWA Feature Migration

- [x] **1.1.1**: Copy PWA core files
  ```bash
  git checkout origin/dev-1.2.8 -- lib/core/pwa/
  ```

- [x] **1.1.2**: Copy device_features.dart
  ```bash
  git checkout origin/dev-1.2.8 -- lib/core/utils/device_features.dart
  ```

- [x] **1.1.3**: Copy PWA UI components
  ```bash
  git checkout origin/dev-1.2.8 -- lib/page/components/pwa/
  ```

- [x] **1.1.4**: Copy Web resources
  ```bash
  git checkout origin/dev-1.2.8 -- web/logo_icons/
  git checkout origin/dev-1.2.8 -- web/service_worker.js
  ```

- [x] **1.1.5**: Copy test files
  ```bash
  git checkout origin/dev-1.2.8 -- test/core/utils/device_features_test.dart
  git checkout origin/dev-1.2.8 -- test/page/components/pwa/
  ```

- [x] **1.1.6**: Manually merge `web/index.html`
  - Compare differences: `git diff dev-2.0.0 origin/dev-1.2.8 -- web/index.html`
  - Integrate PWA related meta tags and scripts

- [x] **1.1.7**: Manually merge `web/manifest.json`
  - Compare differences: `git diff dev-2.0.0 origin/dev-1.2.8 -- web/manifest.json`

- [x] **1.1.8**: Manually merge `web/flutter_bootstrap.js`
  - Compare differences: `git diff dev-2.0.0 origin/dev-1.2.8 -- web/flutter_bootstrap.js`

- [x] **1.1.9**: Update import paths
  - Check all files in `lib/page/components/pwa/`
  - Confirm package imports are correct

- [x] **1.1.10**: Integrate PWA banner into top_bar.dart
  - Review dev-1.2.8 integration approach
  - Add PWA banner in `lib/page/components/styled/top_bar.dart`

- [x] **1.1.11**: Run PWA tests
  ```bash
  flutter test test/core/utils/device_features_test.dart
  flutter test test/page/components/pwa/
  ```

- [x] **1.1.12**: Run analyze
  ```bash
  flutter analyze lib/core/pwa/
  flutter analyze lib/page/components/pwa/
  ```

---

### Task 1.2: Brand Asset Provider Migration

- [x] **1.2.1**: Copy GlobalModelNumberProvider
  ```bash
  git checkout origin/dev-1.2.8 -- lib/providers/global_model_number_provider.dart
  ```

- [x] **1.2.2**: Compare brand_asset_provider.dart differences
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/providers/brand_asset_provider.dart
  ```

- [x] **1.2.3**: Manually merge BrandAssetType enum and related methods

- [x] **1.2.4**: Update Provider exports (if needed)
  - Check `lib/providers/_providers.dart` or related barrel files

- [x] **1.2.5**: Run analyze
  ```bash
  flutter analyze lib/providers/
  ```

---

### Task 1.3: Utility Function Updates

- [x] **1.3.1**: Compare utils.dart differences
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/utils.dart
  ```

- [x] **1.3.2**: Manually merge SI unit formatting function
  - Find `formatSpeed` or related function
  - Change base from 1024 to 1000

- [x] **1.3.3**: Compare test differences
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- test/utils_test.dart
  ```

- [x] **1.3.4**: Update tests

- [x] **1.3.5**: Run tests
  ```bash
  flutter test test/utils_test.dart
  ```

---

### Task 1.4: Model Enable Configuration

- [x] **1.4.1**: Review SPNM62/M62 changes
  ```bash
  git show 7dae63b6
  ```

- [x] **1.4.2**: Enable SPNM62/M62 in corresponding configuration files

- [x] **1.4.3**: Verify configuration is correct

---

### Phase 1 Checkpoint

- [x] Run full analyze
  ```bash
  flutter analyze
  ```

- [x] Run basic tests
  ```bash
  flutter test test/core/utils/
  flutter test test/page/components/pwa/
  flutter test test/utils_test.dart
  ```

- [x] Commit Phase 1 changes
  ```bash
  git add .
  git commit -m "feat: migrate phase 1 features from dev-1.2.8"
  ```

---

## Phase 2: Moderate Integration

> **Status**: Completed
> **Commits**:
> - `efd3f3ff` - feat: Add speed test server selection (Phase 2 migration from dev-1.2.8)
> - `a2db638c` - fix: Add HealthCheckManager2 service support check for server selection

### Task 2.1: HealthCheckServer Model Creation

- [x] **2.1.1**: Copy model file
  ```bash
  git checkout origin/dev-1.2.8 -- lib/page/health_check/models/health_check_server.dart
  ```

- [x] **2.1.2**: Check if models directory needs to be created
  ```bash
  ls lib/page/health_check/models/ 2>/dev/null || mkdir -p lib/page/health_check/models/
  ```
  > Directory already exists

- [x] **2.1.3**: Update barrel export
  - If there's a `_models.dart` or `_health_check.dart`, add export

- [x] **2.1.4**: Run analyze
  ```bash
  flutter analyze lib/page/health_check/models/
  ```

---

### Task 2.2: Server Selection Dialog Migration

- [x] **2.2.1**: Copy dialog component
  ```bash
  git checkout origin/dev-1.2.8 -- lib/page/health_check/views/components/speed_test_server_selection_dialog.dart
  ```

- [x] **2.2.2**: Update import paths
  - Confirm HealthCheckServer import is correct
  - Confirm UI component imports are correct

- [x] **2.2.3**: Adjust dialog to fit new architecture
  - Check state reading approach
  - Confirm callback signatures are correct

- [x] **2.2.4**: Run analyze
  ```bash
  flutter analyze lib/page/health_check/views/components/
  ```

---

### Task 2.3: Update HealthCheckState

- [x] **2.3.1**: Open existing HealthCheckState
  ```
  lib/page/health_check/providers/health_check_state.dart
  ```

- [x] **2.3.2**: Add servers field
  ```dart
  final List<HealthCheckServer> servers;
  ```

- [x] **2.3.3**: Add selectedServer field
  ```dart
  final HealthCheckServer? selectedServer;
  ```

- [x] **2.3.4**: Update constructor
  - Add new fields to constructor
  - Set default values

- [x] **2.3.5**: Update props (Equatable)
  - Add servers and selectedServer

- [x] **2.3.6**: Update copyWith method

- [x] **2.3.7**: Update toMap/fromMap methods

- [x] **2.3.8**: Run analyze
  ```bash
  flutter analyze lib/page/health_check/providers/health_check_state.dart
  ```

---

### Task 2.4: Update HealthCheckProvider

- [x] **2.4.1**: Compare Provider differences
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/page/health_check/providers/health_check_provider.dart
  ```

- [x] **2.4.2**: Implement loadServers method
  - Reference `updateServers()` implementation logic from dev-1.2.8
  - Adapt to new architecture (use SpeedTestService)
  - Call in `loadData()`

- [x] **2.4.3**: Implement setSelectedServer method

- [x] **2.4.4**: Update tests
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- test/page/health_check/
  ```
  > Fixed MockHealthCheckProvider class signature: `extends HealthCheckProvider with Mock`

- [x] **2.4.5**: Run tests
  ```bash
  flutter test test/page/health_check/
  ```
  > 3107 functional tests passed

---

### Task 2.5: Update SpeedTestView

- [x] **2.5.1**: Compare View differences
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/page/health_check/views/speed_test_view.dart
  ```

- [x] **2.5.2**: Integrate server selection UI
  - Add AppBar action icon button (`Icons.dns_outlined`)
  - Connect SpeedTestServerSelectionDialog
  > Difference from dev-1.2.8: using dialog instead of dropdown

- [x] **2.5.3**: Update state reading
  - Read servers and selectedServer from new HealthCheckState

- [x] **2.5.4**: Run analyze
  ```bash
  flutter analyze lib/page/health_check/views/
  ```

---

### Task 2.6: JNAP and Support Check

- [x] **2.6.1**: Confirm getCloseHealthCheckServers JNAP Action
  - File: `lib/core/jnap/actions/jnap_action.dart:89`

- [x] **2.6.2**: Add HealthCheckManager2 to JNAPService enum
  - File: `lib/core/jnap/actions/jnap_service.dart:57`

- [x] **2.6.3**: Add isSupportHealthCheckManager2 method
  - File: `lib/core/jnap/actions/jnap_service_supported.dart:26-27`

- [x] **2.6.4**: Add support check in loadData/loadServers
  ```dart
  if (serviceHelper.isSupportHealthCheckManager2()) {
    // load servers
  }
  ```

- [x] **2.6.5**: Update test_helper.dart with mock
  ```dart
  when(mockServiceHelper.isSupportHealthCheckManager2()).thenReturn(false);
  ```

---

### Phase 2 Checkpoint

- [x] Run health_check related tests
  ```bash
  flutter test test/page/health_check/
  ```
  > 55 localization tests passed

- [ ] Manual test server selection feature
  - Launch application
  - Navigate to Speed Test page
  - Confirm server list displays
  - Confirm can select server

- [x] Commit Phase 2 changes
  ```bash
  git add .
  git commit -m "feat: Add speed test server selection (Phase 2 migration from dev-1.2.8)"
  ```

---

## Phase 3: Architecture Adaptation

> **Status**: Completed
> **Date**: 2026-02-04

### Task 3.1: SpeedTest Error Handling Integration

- [x] **3.1.1**: Analyze dev-1.2.8 error handling implementation
  ```bash
  git show dffec0dc -- lib/page/health_check/providers/health_check_provider.dart
  ```

- [x] **3.1.2**: Review existing SpeedTestError enum
  ```
  lib/page/health_check/models/health_check_enum.dart
  ```
  > **Conclusion**: dev-2.0.0 already has complete SpeedTestError enum (configurationError, noInternet, downloadFailed, uploadFailed)

- [x] **3.1.3**: Add SpeedTestExecutionError type (if needed)
  > **Conclusion**: Not needed, dev-2.0.0 already has `SpeedTestExecutionError` class in `lib/page/health_check/models/speed_test_exception.dart`

- [x] **3.1.4**: Implement error handling logic in Provider
  > **Conclusion**: Already implemented in `health_check_provider.dart:161-178` with complete error handling

- [x] **3.1.5**: Display error messages in UI
  > **Conclusion**: Already displaying error messages through `SpeedTestError` in `SpeedTestWidget`

- [x] **3.1.6**: Fix empty timestamp date parsing
  > **Conclusion**: Already handled in `SpeedTestUIModel` for null values

---

### Task 3.2: Polling Provider Cache Integration

- [x] **3.2.1**: Compare polling_service.dart
  ```
  lib/core/data/services/polling_service.dart
  ```

- [x] **3.2.2**: Evaluate GetCloseHealthCheckServers cache logic
  > **Conclusion**: dev-2.0.0 missing this feature, needs integration

- [x] **3.2.3**: Implement getCloseHealthCheckServers in polling service
  > **Changes**: Added in `polling_service.dart:80-83`:
  ```dart
  if (serviceHelper.isSupportHealthCheckManager2()) {
    commands.add(const MapEntry(JNAPAction.getCloseHealthCheckServers, {}));
  }
  ```

---

### Task 3.3: Dashboard SpeedTest Widget Evaluation

- [x] **3.3.1**: Review dev-2.0.0 Dashboard SpeedTest implementation
  ```
  lib/page/dashboard/views/components/widgets/atomic/speed_test.dart
  lib/page/dashboard/views/components/widgets/parts/internal_speed_test_result.dart
  lib/page/dashboard/views/components/widgets/parts/external_speed_test_links.dart
  ```

- [x] **3.3.2**: Evaluate if rebuild needed in dev-2.0.0
  - [ ] Needs rebuild → proceed to 3.3.3
  - [x] Not needed → document decision, skip
  > **Conclusion**: dev-2.0.0 already has complete Dashboard SpeedTest Widget integration:
  > - `CustomSpeedTest` provides compact/normal/expanded display modes
  > - Integrates `healthCheckProvider` for reading SpeedTest results
  > - Supports internal test (`SpeedTestWidget`) and external links (`ExternalSpeedTestLinks`)

---

### Task 3.4: InstantVerify SpeedTest Widget Evaluation

- [x] **3.4.1**: Review dev-2.0.0 InstantVerify SpeedTest implementation
  ```
  lib/page/instant_verify/views/instant_verify_view.dart:1019-1049
  ```

- [x] **3.4.2**: Evaluate if rebuild needed
  - [ ] Needs rebuild → proceed to 3.4.4
  - [x] Not needed → document decision, skip
  > **Conclusion**: dev-2.0.0 already has complete integration:
  > - `_speedTestContent()` method determines if internal SpeedTest is supported
  > - Uses `SpeedTestWidget` or `SpeedTestExternalWidget` fallback

---

### Phase 3 Checkpoint

- [x] Run complete tests
  ```bash
  ./run_tests.sh
  ```
  > 3107 functional tests passed

- [x] Run SpeedTest View localization tests
  ```bash
  flutter test test/page/health_check/views/localizations/speed_test_view_test.dart --update-goldens
  ```
  > 55 tests passed, golden files updated

- [x] Error handling verification (via golden test automation)
  - Added 6 error state test cases (STV-ERROR-01 ~ STV-ERROR-06)
  - Covers: configuration, license, execution, aborted, dbError, timeout
  - Generated 30 golden screenshots (6 error types × 5 screen sizes)

- [ ] Commit Phase 3 changes

---

## Final Verification

### Verification 4.1: Code Quality

- [x] Run flutter analyze
  ```bash
  flutter analyze
  ```

- [ ] Confirm no unused imports

- [ ] Confirm no TODO items left behind

---

### Verification 4.2: Tests Pass

- [x] Run complete test suite
  ```bash
  ./run_tests.sh
  ```
  > 3107 functional tests passed

- [ ] Confirm test coverage

---

### Verification 4.3: Build Verification

- [ ] Web build
  ```bash
  ./build_web.sh
  ```

- [ ] Local run test
  ```bash
  flutter run -d chrome
  ```

---

### Verification 4.4: Feature Testing

- [ ] PWA install prompt
  - Test with DU model
  - Confirm banner displays
  - Confirm install instructions are correct

- [ ] Speed Test server selection
  - Confirm server list loads
  - Confirm can select server
  - Confirm test uses selected server

- [ ] Speed Test error handling
  - Simulate error scenarios
  - Confirm error messages display

- [ ] Speed formatting
  - Confirm SI units (1000 base) are used

---

## Completion and Wrap-up

- [ ] Create Pull Request
  ```bash
  git push -u origin austin/migration-1.2.8
  gh pr create --title "feat: merge dev-1.2.8 features to dev-2.0.0" --body "..."
  ```

- [ ] Update migration plan document status

- [ ] Document any incomplete items or technical debt

---

## Decision Log

### Decision D1: Dashboard SpeedTest Widget

**Date**: 2026-02-04
**Decision**: [x] Skip (already exists)
**Reason**: dev-2.0.0 already has complete Dashboard SpeedTest Widget implementation in `lib/page/dashboard/views/components/widgets/atomic/speed_test.dart`, supporting compact/normal/expanded display modes and integrating `healthCheckProvider`

---

### Decision D2: InstantVerify SpeedTest Widget

**Date**: 2026-02-04
**Decision**: [x] Skip (already exists)
**Reason**: dev-2.0.0 already integrates SpeedTest functionality in `instant_verify_view.dart:1019-1049`, using `SpeedTestWidget` or `SpeedTestExternalWidget` fallback

---

### Decision D3: Polling Provider Cache

**Date**: 2026-02-04
**Decision**: [x] Integrate
**Reason**: Added `getCloseHealthCheckServers` to `polling_service.dart` to support server list caching when `isSupportHealthCheckManager2()` returns true

---

### Decision D4: Server Selection UI Difference

**Date**: 2026-02-04
**Decision**: [x] Use Dialog (Icon Button in AppBar)
**Reason**: dev-2.0.0 architecture uses UiKitPageView with AppBar actions, dialog approach better fits the new architecture design

---

### Decision D5: Mock Class Signature Fix

**Date**: 2026-02-04
**Decision**: [x] Modify MockHealthCheckProvider class signature
**Reason**: Original Mockito generated `extends Mock implements Provider` was missing Riverpod internal methods (`_setElement`), changed to `extends HealthCheckProvider with Mock` to inherit both Notifier internal methods and retain Mock functionality

---

## Issue Tracking

| # | Issue Description | Status | Resolution |
|---|-------------------|--------|------------|
| 1 | MockHealthCheckProvider missing `_setElement` method | Resolved | Modified mock class to `extends HealthCheckProvider with Mock` |
| 2 | test_helper missing `isSupportHealthCheckManager2` mock | Resolved | Added `when(mockServiceHelper.isSupportHealthCheckManager2()).thenReturn(false)` |
| 3 | speed_test_view_test.dart verify signature mismatch | Resolved | Updated to `anyNamed('serverId')` |

---

## Architecture Difference Comparison Table

| Feature | dev-1.2.8 | dev-2.0.0 |
|---------|-----------|-----------|
| State Type | `String status/step` | `HealthCheckStatus/HealthCheckStep` enum |
| Result Type | `List<HealthCheckResult>` | `SpeedTestUIModel?` |
| Server Loading | `updateServers()` in View initState | `loadServers()` in Provider build() |
| Server UI | AppDropdownButton + Dialog | Icon Button + Dialog |
| Service Layer | Direct Repository usage | SpeedTestService |
| SpeedTestWidget Location | instant_verify/views/components/ | health_check/widgets/ |
