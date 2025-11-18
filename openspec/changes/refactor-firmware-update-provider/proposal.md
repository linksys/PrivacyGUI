## Why

The `FirmwareUpdateNotifier` has become a "God Object", mixing UI state management, complex business logic orchestration, and direct infrastructure access (HTTP requests, local storage). This violates Clean Architecture principles, making the provider difficult to test, maintain, and reason about.

## What Changes

This refactoring will improve the architecture by separating concerns, following the existing `PnpService` pattern found in the project.

-   **Create a new `FirmwareUpdateService`:** A new service class will be created at `lib/core/jnap/services/firmware_update_service.dart`.
-   **Move Logic to Service:** All business logic for general firmware updates (checking, policy, auto-update) will be moved from `FirmwareUpdateNotifier` to the new `FirmwareUpdateService`.
-   **Isolate Manual Update Logic:** To further separate concerns, the logic for manual firmware updates will be moved out of the general firmware update providers and into its own dedicated service and provider. A new `ManualFirmwareUpdateService` will be created.
-   **Simplify Notifiers:** Both `FirmwareUpdateNotifier` and the existing `ManualFirmwareUpdateNotifier` will be refactored into thin layers. Their sole responsibility will be to delegate calls to their respective services and update the UI state.
-   **No Breaking Changes:** This is an internal refactoring. The public API of the providers will remain unchanged to consumers.

## Impact

-   **Affected specs:** None. This is a refactoring of the implementation, not a change in behavior or requirements.
-   **Affected code:**
    -   `lib/core/jnap/providers/firmware_update_provider.dart`: Will be significantly simplified.
    -   `lib/core/jnap/services/firmware_update_service.dart`: Will be created and then have manual update logic removed.
    -   `lib/page/instant_admin/providers/manual_firmware_update_provider.dart`: Will be updated to contain the manual update orchestration logic.
    -   `lib/page/instant_admin/views/manual_firmware_update_view.dart`: Call sites will be updated.
-   **New files created:**
    -   `lib/page/instant_admin/services/manual_firmware_update_service.dart`
-   **UI Impact:** None. All dependent UI components will continue to function as before without any required changes.
