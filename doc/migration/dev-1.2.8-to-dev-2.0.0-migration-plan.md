# dev-1.2.8 → dev-2.0.0 Migration Plan

> Created: 2026-02-04
> Status: Planning
> Owner: TBD

---

## 1. Overview

### 1.1 Background

The `dev-1.2.8` branch contains multiple production fixes and new features that need to be merged into the `dev-2.0.0` main development branch. Since `dev-2.0.0` underwent a major three-layer architecture refactoring, a direct merge would result in approximately 30 file conflicts. Therefore, a **Cherry-pick with manual adaptation** strategy is adopted.

### 1.2 Branch Status

| Branch | Commits | Last Updated | Description |
|--------|---------|--------------|-------------|
| `dev-1.2.8` | 9 unique commits | 2026-02-03 | Production fixes branch |
| `dev-2.0.0` | 47+ commits | 2026-02-04 | Three-layer architecture refactoring branch |
| Common ancestor | `08b486f9` | - | merge 1.2.7 to main |

### 1.3 Migration Strategy

```
Cherry-pick with manual adaptation
├── Phase 1: Clean additions (direct cherry-pick)
├── Phase 2: Moderate integration (cherry-pick + adjustments)
└── Phase 3: Architecture adaptation (manual re-implementation)
```

---

## 2. Feature List

### 2.1 Features to Migrate Overview

| # | Feature | PR/Commit | Risk Level | Migration Method |
|---|---------|-----------|------------|------------------|
| F1 | PWA Install Prompt (DU model only) | #609 | 🟢 Low | Cherry-pick |
| F2 | SpeedTest Error Handling & Server Selection | #607 | 🔴 High | Manual adaptation |
| F3 | Brand Asset Loading Optimization | #600 | 🟡 Medium | Cherry-pick + adjustments |
| F4 | Speed Formatting SI Units | ca1717b2 | 🟢 Low | Cherry-pick |
| F5 | SPNM62/M62 Speed Test Enable | 7dae63b6 | 🟢 Low | Cherry-pick |

### 2.2 Feature Details

#### F1: PWA Install Prompt (DU Model Only)

**Commit**: `d7d14197`

**Description**:
- Implement PWA install prompt banner, displayed only on 'DU' model devices
- Include iOS and Mac Safari installation instruction sheets
- Create `device_features.dart` device feature detection system

**New Files**:
```
lib/core/pwa/
├── pwa_install_service.dart
├── pwa_logic.dart
├── pwa_logic_stub.dart
└── pwa_logic_web.dart

lib/core/utils/device_features.dart

lib/page/components/pwa/
├── install_prompt_banner.dart
├── ios_install_instruction_sheet.dart
└── mac_safari_install_instruction_sheet.dart

web/
├── logo_icons/logo-icon-512.png
├── manifest.json (updated)
├── service_worker.js
├── index.html (updated)
└── flutter_bootstrap.js (updated)

test/
├── core/utils/device_features_test.dart
└── page/components/pwa/install_prompt_banner_test.dart
```

**Dependencies**: None (standalone feature)

---

#### F2: SpeedTest Error Handling & Server Selection

**Commit**: `dffec0dc`

**Description**:
- Add `HealthCheckServer` model
- Implement server selection dialog
- Handle `SpeedTestExecutionError`
- Fix empty timestamp date parsing

**Affected Files**:
```
lib/page/health_check/
├── models/health_check_server.dart (new)
├── providers/health_check_provider.dart (conflict)
├── providers/health_check_state.dart (conflict - different architecture)
├── views/speed_test_view.dart (conflict)
└── views/components/speed_test_server_selection_dialog.dart (new)

lib/page/instant_verify/views/
├── instant_verify_view.dart (conflict)
└── components/speed_test_widget.dart (deleted in dev-2.0.0)

lib/page/dashboard/views/components/
└── port_and_speed.dart (deleted in dev-2.0.0)
```

**Architecture Differences**:

| Item | dev-1.2.8 | dev-2.0.0 |
|------|-----------|-----------|
| State Type | `String step, status` | `HealthCheckStep, HealthCheckStatus` enum |
| Result Model | `List<HealthCheckResult>` | `SpeedTestUIModel` |
| Error Handling | `JNAPError?` | `SpeedTestError?` enum |
| Server List | `List<HealthCheckServer>` | Needs integration |

**Migration Strategy**: Manually adapt feature logic to new architecture

---

#### F3: Brand Asset Loading Optimization

**Commit**: `09e12846`

**Description**:
- Add `BrandAssetType` enum
- Create `GlobalModelNumberProvider` for persistent model number
- Optimize brand asset path resolution

**Affected Files**:
```
lib/providers/
├── brand_asset_provider.dart (needs merge)
└── global_model_number_provider.dart (new)
```

**Migration Strategy**: Cherry-pick then adjust Provider registration

---

#### F4: Speed Formatting SI Units

**Commit**: `ca1717b2`

**Description**: Change network speed formatting from binary (1024) to SI units (1000)

**Affected Files**:
```
lib/utils.dart (needs merge)
test/utils_test.dart (needs merge)
```

**Migration Strategy**: Direct merge utility functions

---

#### F5: SPNM62/M62 Speed Test Enable

**Commit**: `7dae63b6`

**Description**: Enable Speed Test feature for SPNM62 and M62 models

**Affected Files**: Device feature configuration files

**Migration Strategy**: Direct cherry-pick

---

## 3. Conflict File List

### 3.1 Content Conflicts

| File | Conflict Reason | Resolution Strategy |
|------|-----------------|---------------------|
| `lib/page/health_check/providers/health_check_state.dart` | Architecture completely rewritten | Manually integrate new fields |
| `lib/page/health_check/providers/health_check_provider.dart` | Service layer extraction | Manual adaptation |
| `lib/page/health_check/views/speed_test_view.dart` | UI Model changes | Manual adaptation |
| `lib/core/jnap/providers/polling_provider.dart` | Cache logic changes | Merge cache logic |
| `lib/page/dashboard/providers/dashboard_home_provider.dart` | Provider refactoring | Evaluate then decide |
| `lib/page/dashboard/views/dashboard_shell.dart` | Layout changes | Manual merge |
| `lib/page/dashboard/views/dashboard_menu_view.dart` | Menu changes | Manual merge |
| `lib/providers/auth/auth_provider.dart` | Auth logic changes | Review then merge |
| `lib/route/router_provider.dart` | Route changes | Review then merge |
| `lib/utils.dart` | SI unit changes | Use 1.2.8 version directly |
| `pubspec.yaml` | Version differences | Keep 2.0.0 version number |

### 3.2 Modify/Delete Conflicts

| dev-1.2.8 File | dev-2.0.0 Status | Resolution |
|----------------|------------------|------------|
| `lib/page/wifi_settings/providers/wifi_list_provider.dart` | Deleted (refactored to service layer) | Analyze then decide if needed |
| `lib/page/wifi_settings/views/wifi_list_view.dart` | Moved to `views/main/` | Merge to new location |
| `lib/page/wifi_settings/views/wifi_list_simple_mode_view.dart` | Moved to `views/main/` | Merge to new location |
| `lib/page/instant_verify/views/components/speed_test_widget.dart` | Deleted | Evaluate if rebuild needed |
| `lib/page/dashboard/views/components/port_and_speed.dart` | Deleted | Evaluate if rebuild needed |

---

## 4. Implementation Plan

### 4.1 Prerequisites

```bash
# 1. Ensure local branches are up to date
git fetch origin

# 2. Create migration working branch
git checkout dev-2.0.0
git pull origin dev-2.0.0
git checkout -b feature/merge-1.2.8-features

# 3. Confirm dev-1.2.8 commit list
git log --oneline dev-2.0.0..origin/dev-1.2.8
```

### 4.2 Phase 1: Clean Additions

#### Task 1.1: PWA Feature Migration

**Steps**:

```bash
# Copy PWA core files
git checkout origin/dev-1.2.8 -- lib/core/pwa/
git checkout origin/dev-1.2.8 -- lib/core/utils/device_features.dart
git checkout origin/dev-1.2.8 -- lib/page/components/pwa/

# Copy Web resources
git checkout origin/dev-1.2.8 -- web/logo_icons/
git checkout origin/dev-1.2.8 -- web/service_worker.js

# Copy test files
git checkout origin/dev-1.2.8 -- test/core/utils/device_features_test.dart
git checkout origin/dev-1.2.8 -- test/page/components/pwa/
```

**Manual Adjustments**:
1. Update import paths in `lib/page/components/pwa/`
2. Integrate PWA banner in `lib/page/components/styled/top_bar.dart`
3. Update `web/index.html` and `web/manifest.json` (manual merge)
4. Register `PwaInstallService` to Provider tree

**Verification**:
```bash
flutter analyze lib/core/pwa/
flutter analyze lib/page/components/pwa/
flutter test test/core/utils/device_features_test.dart
flutter test test/page/components/pwa/
```

---

#### Task 1.2: Brand Asset Provider Migration

**Steps**:

```bash
# Copy new Provider
git checkout origin/dev-1.2.8 -- lib/providers/global_model_number_provider.dart
```

**Manual Adjustments**:
1. Review `lib/providers/brand_asset_provider.dart` differences
2. Merge `BrandAssetType` enum and related methods
3. Update Provider registration (if needed)

**Verification**:
```bash
flutter analyze lib/providers/
```

---

#### Task 1.3: Utility Function Updates

**Steps**:

```bash
# View differences
git diff dev-2.0.0 origin/dev-1.2.8 -- lib/utils.dart
```

**Manual Adjustments**:
1. Merge SI unit formatting function
2. Update related tests

**Verification**:
```bash
flutter test test/utils_test.dart
```

---

#### Task 1.4: Model Enable Configuration

**Steps**:

```bash
# View SPNM62/M62 related changes
git show 7dae63b6 --stat
```

**Manual Adjustments**: Adjust configuration based on changes

---

### 4.3 Phase 2: Moderate Integration

#### Task 2.1: HealthCheckServer Model Creation

**Steps**:

```bash
# Copy model file
git checkout origin/dev-1.2.8 -- lib/page/health_check/models/health_check_server.dart
```

**Manual Adjustments**:
1. Confirm model compatibility with existing architecture
2. Update barrel export file

---

#### Task 2.2: Server Selection Dialog Migration

**Steps**:

```bash
# Copy UI component
git checkout origin/dev-1.2.8 -- lib/page/health_check/views/components/speed_test_server_selection_dialog.dart
```

**Manual Adjustments**:
1. Adjust import paths
2. Confirm compatibility with existing `HealthCheckState`
3. Update dialog state source

---

#### Task 2.3: Update HealthCheckState

**Manual Implementation**:

Add to existing `lib/page/health_check/providers/health_check_state.dart`:

```dart
// New fields
final List<HealthCheckServer> servers;
final HealthCheckServer? selectedServer;

// Update copyWith
HealthCheckState copyWith({
  // ... existing fields
  List<HealthCheckServer>? servers,
  HealthCheckServer? selectedServer,
}) {
  return HealthCheckState(
    // ... existing fields
    servers: servers ?? this.servers,
    selectedServer: selectedServer ?? this.selectedServer,
  );
}
```

---

#### Task 2.4: Update SpeedTestView

**Manual Adjustments**:
1. Compare `speed_test_view.dart` differences
2. Integrate server selection UI
3. Adapt to new state model

---

### 4.4 Phase 3: Architecture Adaptation

#### Task 3.1: SpeedTest Error Handling Integration

**Analyze dev-1.2.8 implementation**:
```bash
git show dffec0dc -- lib/page/health_check/providers/health_check_provider.dart
```

**Manual Implementation**:
1. Add necessary error types to `SpeedTestError` enum
2. Implement error handling logic in `HealthCheckProvider`
3. Update UI to display error messages

---

#### Task 3.2: Polling Provider Cache Integration

**Analyze differences**:
```bash
git diff dev-2.0.0 origin/dev-1.2.8 -- lib/core/jnap/providers/polling_provider.dart
```

**Manual Adjustments**:
1. Integrate `GetCloseHealthCheckServers` cache logic
2. Ensure compatibility with existing polling mechanism

---

#### Task 3.3: Dashboard SpeedTest Widget Evaluation

**Decision Point**:
- `lib/page/dashboard/views/components/port_and_speed.dart` deleted in dev-2.0.0
- Evaluate whether to rebuild this feature in new architecture

**Options**:
1. Re-implement in new Dashboard architecture
2. Skip this feature for now
3. Create new Dashboard component

---

#### Task 3.4: InstantVerify SpeedTest Widget Evaluation

**Decision Point**:
- `lib/page/instant_verify/views/components/speed_test_widget.dart` deleted in dev-2.0.0
- Evaluate whether to rebuild

---

### 4.5 Verification and Wrap-up

#### Task 4.1: Complete Testing

```bash
# Run all tests
./run_tests.sh

# Run UI tests
flutter test --tags ui

# Run health_check related tests
flutter test test/page/health_check/
```

#### Task 4.2: Build Verification

```bash
# Web build
./build_web.sh

# Local run
flutter run -d chrome
```

#### Task 4.3: Code Review

- [ ] Confirm all import paths are correct
- [ ] Confirm no unused code
- [ ] Confirm test coverage
- [ ] Run `flutter analyze` with no errors

---

## 5. Risk Assessment

### 5.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| HealthCheckState integration failure | High | Medium | Prepare rollback plan, integrate in phases |
| PWA feature incompatible with existing architecture | Medium | Low | PWA is standalone module, risk is controllable |
| Dashboard feature gaps | Medium | Medium | Document missing features, address later |
| Insufficient test coverage | Medium | Medium | Add manual testing items |

### 5.2 Rollback Plan

```bash
# If serious issues occur, rollback to dev-2.0.0
git checkout dev-2.0.0
git branch -D feature/merge-1.2.8-features
```

---

## 6. Schedule Estimate

| Phase | Estimated Time | Description |
|-------|----------------|-------------|
| Prerequisites | 0.5 hours | Environment preparation, branch creation |
| Phase 1 | 1-2 hours | Clean addition features |
| Phase 2 | 2-3 hours | Moderate integration |
| Phase 3 | 3-4 hours | Architecture adaptation |
| Verification & wrap-up | 1-2 hours | Testing and review |
| **Total** | **8-12 hours** | - |

---

## 7. Checklist

### 7.1 Phase 1 Completion Check

- [ ] PWA feature works correctly
- [ ] device_features.dart tests pass
- [ ] GlobalModelNumberProvider correctly registered
- [ ] SI unit formatting correct
- [ ] No analyze errors

### 7.2 Phase 2 Completion Check

- [ ] HealthCheckServer model available
- [ ] Server selection dialog displays correctly
- [ ] HealthCheckState new fields work correctly
- [ ] SpeedTestView can select server

### 7.3 Phase 3 Completion Check

- [ ] SpeedTest errors handled and displayed correctly
- [ ] Polling cache works correctly
- [ ] Dashboard/InstantVerify feature evaluation complete
- [ ] All tests pass

### 7.4 Final Check

- [ ] `flutter analyze` no errors
- [ ] `./run_tests.sh` all pass
- [ ] Web build successful
- [ ] PR ready

---

## 8. Appendix

### 8.1 Related Commit SHAs

```
dev-1.2.8 unique commits:
d7d14197 - feat: restrict PWA install banner to 'DU' models only (#609)
dffec0dc - fix: handle SpeedTestExecutionError and fix date parsing (#607)
09e12846 - Refactor: Optimize Brand Asset Loading and Fix Model Number State Loss (#600)
8f3db457 - chore: update build_web.sh
162ac087 - style: apply PR suggestions for robustness and clarity
ca1717b2 - fix: update network speed formatting to use SI units (base 1000)
7dae63b6 - fix: enable speed test for SPNM62 and M62 models
f9b41751 - init commit for 1.2.8 version
```

### 8.2 Reference Documents

- [Architecture Analysis Document](../architecture_analysis_2026-01-16.md)
- [Service Layer Specification](../service-domain-specifications.md)
- [Speed Test Specification](../speedtest.md)

### 8.3 Change History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-04 | 1.0 | Initial version |
