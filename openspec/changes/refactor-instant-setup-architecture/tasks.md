## 1. File Structure Reorganization
- [x] 1.1 Create `lib/page/instant_setup/providers/` directory.
- [x] 1.2 Create `lib/page/instant_setup/models/` directory.
- [x] 1.3 Create `lib/page/instant_setup/services/` directory.
- [x] 1.4 Move `lib/page/instant_setup/data/pnp_provider.dart` to `lib/page/instant_setup/providers/pnp_provider.dart`.
- [x] 1.5 Move `lib/page/instant_setup/data/pnp_state.dart` to `lib/page/instant_setup/providers/pnp_state.dart`.
- [x] 1.6 Update all import paths affected by file movements.

## 2. Define UI Models
- [x] 2.1 Create `lib/page/instant_setup/models/pnp_ui_models.dart`.
- [x] 2.2 Define `PnpDeviceInfoUIModel` (and other necessary UI models) based on UI requirements, including fields like `imageUrl` for router images.
- [x] 2.3 Update `PnpState` to use `PnpDeviceInfoUIModel` instead of `NodeDeviceInfo`.

## 3. Implement PnpService Layer
- [x] 3.1 Create `lib/page/instant_setup/services/pnp_service.dart`.
- [x] 3.2 Define `PnpService` class with methods to:
    - [x] Accept `Ref` or necessary dependencies (e.g., `RouterRepository`).
    - [x] Fetch raw domain models (e.g., `NodeDeviceInfo`).
    - [x] Implement business logic for data processing and transformation.
    - [x] Convert domain models to UI models (e.g., `getDeviceInfoUIModel`).

## 4. Refactor PnpNotifier
- [x] 4.1 Modify `PnpNotifier` to depend on `PnpService`.
- [x] 4.2 Update `fetchDeviceInfo` to store raw `NodeDeviceInfo` internally or pass it to `PnpService`.
- [x] 4.3 Introduce a new method (e.g., `fetchAndPrepareDeviceInfo`) in `PnpNotifier` that:
    - [x] Calls `PnpService` to get UI models.
    - [x] Updates `PnpState` with the new UI models.
- [x] 4.4 Adjust other `PnpNotifier` methods to leverage `PnpService` for business logic and data transformation, simplifying their responsibilities.

## 5. Update UI Components
- [x] 5.1 Update `PnpAdminView` to consume `PnpDeviceInfoUIModel` from `PnpState`.
- [x] 5.2 Update `PnpSetupView` and other relevant UI components to use the new UI models.
- [x] 5.3 Simplify UI logic by removing data transformation directly within widgets.

## 6. Validate and Test
- [ ] 6.1 Run existing unit and integration tests to ensure no regressions.
- [ ] 6.2 Write new unit tests for `PnpService`.
- [ ] 6.3 Manually test the PnP flow to verify functionality and UI correctness.
