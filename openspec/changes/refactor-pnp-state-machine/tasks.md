## 1. Documentation & Planning
- [x] 1.1 Create `doc/pnp-flow.md` with as-is and to-be state diagrams.
- [x] 1.2 Create `doc/pnp-refactor.md` with the detailed refactoring plan.
- [x] 1.3 Create this OpenSpec proposal.

## 2. Core State Refactoring
- [x] 2.1 Define the unified `PnpFlowStatus` enum in a new file or in `pnp_state.dart`.
- [x] 2.2 Update `PnpState` to include `status`, `error`, and `loadingMessage` fields.

## 3. Notifier Logic Migration
- [x] 3.1 Create `startPnpFlow()` in `PnpNotifier` and move logic from `PnpAdminView._runInitialChecks`.
- [x] 3.2 Create `submitPassword()` in `PnpNotifier` and move logic from `PnpAdminView._doLogin`.
- [x] 3.3 Create `savePnpSettings()` in `PnpNotifier` and move logic from `PnpSetupView._saveChanges`.
- [x] 3.4 Create `checkForFirmwareUpdate()` in `PnpNotifier` and move logic from `PnpSetupView._doFwUpdateCheck`.
- [x] 3.5 Create `testPnpReconnect()` in `PnpNotifier` and move logic from `PnpSetupView.testConnection`.

## 4. UI Refactoring
- [x] 4.1 Refactor `PnpAdminView` to manage only necessary local UI state (e.g., `TextEditingController`) and be primarily driven by `PnpState.status`, with business logic decoupled to `PnpNotifier`.
- [x] 4.2 Refactor `PnpSetupView` to manage only necessary local UI state (e.g., `TextEditingController`) and be primarily driven by `PnpState.status`, with business logic decoupled to `PnpNotifier`.
- [ ] 4.3 Remove all obsolete local state variables, flags, and logic from the UI widgets.

## 5. Verification
- [ ] 5.1 Manually test the entire PnP flow to ensure behavior is identical to the pre-refactor version.
- [ ] 5.2 Run all relevant integration tests (`integration_test/`) and ensure they pass.
- [ ] 5.3 Review and remove any obsolete code.
