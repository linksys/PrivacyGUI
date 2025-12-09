## Why
The `instant_setup` module currently mixes UI logic, business logic, and state management within the `PnpNotifier`. This leads to a tightly coupled architecture, making the code harder to read, test, and maintain. The current structure also uses domain models directly in the UI, which can lead to unnecessary UI rebuilds and a lack of clear separation between data layers.

## What Changes
This proposal outlines a refactoring of the `instant_setup` module to introduce a clearer, layered architecture:
- **File Structure Reorganization**:
    - Move `pnp_provider.dart` and `pnp_state.dart` from `lib/page/instant_setup/data/` to `lib/page/instant_setup/providers/`.
    - Create a new directory `lib/page/instant_setup/models/` to house UI-specific models.
    - Create a new directory `lib/page/instant_setup/services/` to encapsulate business logic and data transformation.
- **Introduction of UI Models**: Define dedicated UI models in `lib/page/instant_setup/models/` that are tailored to the UI's needs, containing only formatted data ready for display. These will replace direct usage of domain models (JNAP models) in the `PnpState` and UI.
- **Introduction of a Service Layer**: Implement a `PnpService` in `lib/page/instant_setup/services/` responsible for:
    - Fetching raw domain models from `RouterRepository` or `PnpNotifier`.
    - Applying business logic (e.g., data combination, calculation, validation).
    - Transforming domain models into UI models.
- **Refactoring of PnpNotifier**: Simplify the `PnpNotifier`'s responsibilities to primarily manage `PnpState` and coordinate calls to the new `PnpService` for data processing and UI model generation. It will no longer directly handle complex data transformations.

## Impact
- **Improved Separation of Concerns**: Clearly separates UI, business logic, and state management, making each layer more focused and independent.
- **Enhanced Maintainability**: Changes in business logic or UI requirements will be localized to their respective layers, reducing the risk of unintended side effects.
- **Increased Testability**: The new `PnpService` layer can be unit-tested independently of the UI and state management, improving code quality and reliability.
- **Clearer Data Flow**: Establishes a well-defined data flow: `Repository (raw data) -> Service (business logic/transformation) -> Notifier (state management) -> UI (rendering)`.
- **Better UI Performance**: UI components will interact with simpler, pre-formatted UI models, potentially reducing unnecessary rebuilds and simplifying UI logic.
- **Breaking Changes**: This refactoring will involve significant changes to existing files within `lib/page/instant_setup/`, including file movements, class modifications, and updates to import paths. All UI components consuming `PnpState` will need to be updated to use the new UI models.
