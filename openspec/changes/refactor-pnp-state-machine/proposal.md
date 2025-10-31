## Why
The current PnP (Plug and Play) flow's state management logic is scattered across multiple `StatefulWidget`s (`PnpAdminView`, `PnpSetupView`), relying on local variables, boolean flags, and exception handling to control the UI. This makes the flow difficult to understand, debug, and maintain.

## What Changes
This proposal outlines an internal refactoring to centralize the PnP flow's state management into a unified state machine, following best practices for Riverpod.
- A single `PnpFlowStatus` enum will be created to explicitly define every possible state in the end-to-end flow.
- The `PnpState` will be updated to hold this status, centralizing the single source of truth.
- All business and flow-control logic will be moved from the UI widgets into the `PnpNotifier`.
- The UI widgets (`PnpAdminView`, `PnpSetupView`) will be simplified into `ConsumerWidget`s that declaratively render the UI based on the state from the `PnpProvider`.

**BREAKING**: This is a significant internal refactoring but is not expected to introduce any breaking changes to user-facing behavior or public APIs.

## Impact
- **Affected specs:** None. This is a purely internal architectural refactoring to improve code quality and does not alter any existing requirements.
- **Affected code:**
  - `lib/page/instant_setup/data/pnp_state.dart`
  - `lib/page/instant_setup/data/pnp_provider.dart`
  - `lib/page/instant_setup/pnp_admin_view.dart`
  - `lib/page/instant_setup/pnp_setup_view.dart`
  - Potentially `lib/page/instant_setup/model/pnp_step.dart` and its implementations.
