## 1. Implementation

- [ ] 1.1 Create the new service file at `lib/core/jnap/services/firmware_update_service.dart`.
- [ ] 1.2 Define the `FirmwareUpdateService` class and its associated Riverpod provider.
- [ ] 1.3 Move all business logic and orchestration methods from `FirmwareUpdateNotifier` to `FirmwareUpdateService`. This includes:
    - `setFirmwareUpdatePolicy`
    - `fetchAvailableFirmwareUpdates`
    - `fetchFirmwareUpdateStream`
    - `updateFirmware`
    - `finishFirmwareUpdate`
    - `manualFirmwareUpdate`
    - `waitForRouterBackOnline`
    - All private helper methods related to the update logic (`_checkFirmwareUpdateComplete`, `_examineStatusResult`, etc.).
- [ ] 1.4 Adapt the moved methods within the service to get dependencies (like `RouterRepository`) via a `Ref` object passed to its constructor.
- [x] 1.5 Refactor `FirmwareUpdateNotifier` to be a thin wrapper. It will get an instance of `FirmwareUpdateService` from its `ref` and delegate all method calls to it.
- [x] 1.6 Ensure the public API of `FirmwareUpdateNotifier` (state structure and method signatures) remains identical to the original to guarantee no breaking changes for consumers.

## 2. Manual Firmware Update Refactoring
- [x] 2.1 Create the new service file at `lib/page/instant_admin/services/manual_firmware_update_service.dart`.
- [x] 2.2 Define the `ManualFirmwareUpdateService` class and its provider.
- [x] 2.3 Move the `manualFirmwareUpdate` method and `ManualFirmwareUpdateException` class from `FirmwareUpdateService` to `ManualFirmwareUpdateService`.
- [x] 2.4 Move the `manualFirmwareUpdate` and `waitForRouterBackOnline` orchestration logic from `FirmwareUpdateNotifier` to `ManualFirmwareUpdateNotifier`.
- [x] 2.5 Update `ManualFirmwareUpdateNotifier` to call the new `ManualFirmwareUpdateService`.
- [x] 2.6 Update `ManualFirmwareUpdateView` to use the `ManualFirmwareUpdateNotifier` for its actions.

## 3. Verification
- [ ] 3.1 Manually review the diff to confirm all complex logic has been successfully moved from the Notifier to the Service.
- [ ] 3.2 Run the application and manually test the primary firmware update user flows:
    - Auto-update notification on the dashboard.
    - The main Firmware Update page.
    - The Manual Firmware Update page.
    - The "Auto-update" toggle in settings.
- [ ] 3.3 Execute any existing automated tests in the project to check for regressions.
