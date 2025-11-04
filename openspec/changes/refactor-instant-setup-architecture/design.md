## Context
The `instant_setup` module in the PrivacyGUI application is responsible for the initial setup and configuration of Linksys routers. The existing architecture, particularly within the `PnpNotifier`, has evolved to handle a mix of UI state management, direct interaction with JNAP (router API) models, and complex business logic. This has led to a monolithic `PnpNotifier` that is difficult to maintain, test, and extend.

## Goals / Non-Goals
- **Goals**:
    - Establish a clear separation of concerns within the `instant_setup` module.
    - Improve the maintainability and readability of the code.
    - Enhance the testability of business logic.
    - Decouple UI components from raw JNAP domain models.
    - Define a consistent data flow for the PnP setup process.
- **Non-Goals**:
    - Rewrite the entire JNAP interaction layer (`RouterRepository`).
    - Introduce new state management solutions beyond Riverpod.
    - Change the core functionality or user experience of the PnP flow.

## Decisions
- **Layered Architecture**: Adopt a layered architecture consisting of:
    - **UI Layer**: Widgets responsible solely for rendering and user interaction. They will consume `PnpState` which holds UI-specific models.
    - **Notifier Layer (`PnpNotifier`)**: Manages the overall state of the PnP flow (`PnpState`) and orchestrates interactions between the UI and the Service layer. It will primarily update `PnpState` based on events and results from the Service layer.
    - **Service Layer (`PnpService`)**: Encapsulates all business logic related to the PnP flow. It will fetch raw data (domain models) from the `RouterRepository`, apply transformations, validations, and business rules, and convert domain models into UI-specific models.
    - **Data Layer (`RouterRepository`)**: Remains responsible for direct interaction with the JNAP API, fetching and sending raw domain models.

- **UI Models**: Introduce dedicated UI models (e.g., `PnpDeviceInfoUIModel`) that are flattened, formatted, and optimized for UI consumption. These models will contain only the data points and formats directly required by the UI, abstracting away the complexities of the underlying JNAP domain models. For example, instead of the UI calculating an image path from a `modelNumber`, the UI model will directly provide a `imageUrl`.

- **Data Flow**: The data flow will be unidirectional and explicit:
    1.  **UI Event**: User interaction triggers an action in the `PnpNotifier`.
    2.  **Notifier Action**: `PnpNotifier` calls a method on `PnpService`.
    3.  **Service Logic**: `PnpService` fetches domain models from `RouterRepository`, applies business logic, and transforms them into UI models.
    4.  **Service Result**: `PnpService` returns UI models or processed data to `PnpNotifier`.
    5.  **Notifier State Update**: `PnpNotifier` updates `PnpState` with the new UI models or status.
    6.  **UI Re-render**: UI widgets react to `PnpState` changes and re-render using the UI models.

## Risks / Trade-offs
- **Increased File Count**: Introducing new layers and models will increase the number of files in the `instant_setup` module.
- **Initial Development Overhead**: The refactoring requires an upfront investment in moving files, creating new classes, and updating existing logic.
- **Migration Complexity**: Existing UI components that directly access `NodeDeviceInfo` or perform data transformations will need to be updated.

## Open Questions
- What is the exact scope of UI models needed? (To be determined during implementation based on UI requirements).
- Are there any existing utility functions that should be moved into the `PnpService` or a new utility class?
