# Screenshot Testing Guidelines

This document outlines the core principles and best practices for writing high-quality screenshot tests in this project, based on the patterns established in files like `pnp_admin_view_test.dart`, `pnp_setup_view_test.dart`, and `dashboard_home_view_test.dart`.

---

### 1. Structure & Documentation

Clear documentation is crucial for test maintainability and traceability.

- **Reference to Implementation File**: At the top of the test file, explicitly state the path to the implementation file under test (e.g., `lib/page/instant_setup/pnp_admin_view.dart`). This helps developers quickly locate the corresponding source code.
    - **Placement**: This comment, along with the View ID and File-Level Summary, should be placed after all `import` statements and before the `main()` function.

- **View ID**: At the very beginning of the file, specify a unique ID for the view being tested (e.g., `// View ID: PNPS`). The View ID must consist of up to five uppercase English letters and must not contain hyphens (`-`) or underscores (`_`). This is used for high-level test management and reporting.
    - **Placement**: This comment, along with the Reference to Implementation File and File-Level Summary, should be placed after all `import` statements and before the `main()` function.

- **Test ID**: Assign a unique, hierarchical ID to each test case. The Test ID must follow the format `{View ID}-{SHORT_DESCRIPTION}`, where the description is a short, uppercase string of at most 10 characters, using underscores (`_`) to connect words (e.g., `// Test ID: PNPS-WIZ_INIT`). This ID represents the logical test scenario. All golden files associated with this test case will use this Test ID as a prefix.

- **Golden File Naming Convention**: All golden files (both the main `goldenFilename` in `testLocalizations` and intermediate screenshots from `TestHelper.takeScreenshot`) must follow the convention: `[TestID]-[number]-[description]`.
    - `[TestID]`: The base Test ID (e.g., `PNPS-WIZ_INIT`).
    - `[number]`: A two-digit incremental number (e.g., `01`, `02`) to order screenshots within a single test case.
    - `[description]`: A short, descriptive string (e.g., `initial_state`, `info_dialog`, `ssid_error`).
    - **Example**: `PNPS-WIZ_INIT-01-initial_state`

- **Descriptive Titles**: Test descriptions should be colloquial and clear English (e.g., `'Verify admin password prompt with login and "Where is it?" buttons'`). The title should explain the purpose of the test, not just state the condition.

- **File-Level Summary**: Provide a summary block at the top of the file indexing all covered test cases and their brief descriptions. It is recommended to use a Markdown table for clarity and readability.
    - **Placement**: This summary, along with the View ID and Reference to Implementation File, should be placed after all `import` statements and before the `main()` function.
    - **Example Table Format**:
      ```markdown
      /// | Test ID             | Description                                                                 |
      /// | :------------------ | :-------------------------------------------------------------------------- |
      /// | `PNPA-INIT`         | Verifies loading spinner and "Initializing Admin" message on startup.       |
      /// | `PNPA-NETCHK`       | Verifies "Checking Internet Connection" message while network is being checked. |
      /// | `PNPA-NETOK`        | Verifies "Internet Connected" message and continue button when online.      |
      /// | `PNPA-UNCONF`       | Verifies unconfigured router view with "Start Setup" button.                |
      /// | `PNPA-PASSWD`       | Verifies admin password prompt with login and "Where is it?" buttons.       |
      /// | `PNPA-PASSWD_MODAL` | Verifies "Where is it?" modal appears when button is tapped on password screen. |
      ```

### 2. Centralized Test Helper (`TestHelper`)

A centralized `TestHelper` class is used to encapsulate repetitive setup, mocks, and utility functions, simplifying test cases.

- **Purpose**: To simplify test case authoring and improve consistency by abstracting away boilerplate code.
- **Implementation**:
    - **Handling Routing Differences (`pumpView` vs. `pumpShellView`)**: The `TestHelper` provides different `pump` methods for different routing structures.
        - `pumpView`: Use for testing standalone pages that do not have a surrounding UI shell. These methods return the `BuildContext` of the pumped widget, which should be captured directly (e.g., `final context = await testHelper.pumpView(...)`) for use in localization lookups and other context-dependent operations.
        - `pumpShellView`: Use for pages that are part of a `ShellRoute` and require a UI "shell" (like a `DashboardShell`) to be rendered correctly. These methods also return the `BuildContext` of the pumped widget, which should be captured directly.
    - **Centralized Mocks**: Access shared mock objects via the helper (e.g., `testHelper.mockPnpNotifier`) to configure them in the setup phase.
    - **Shared Utilities**: Consolidate helper functions (like `loc`) into the `TestHelper` to provide a unified toolkit.
    - **Lifecycle Management**: Use `testHelper.setup()` in the global `setUp` block to perform initialization before each test case runs.

### 3. Test Setup

Properly preparing the state for each test is critical for isolation and determinism.

- **State Mocking**: Each test case must precisely simulate the specific state it intends to test using `when(...).thenReturn(...)`.
    - **Simple State Mocking**: For views dependent on a single Notifier (e.g., `PnpAdminView`), mocking its state is sufficient.
    - **Complex State Composition**: For complex views dependent on multiple Notifiers (e.g., `DashboardHomeView`), all relevant Notifiers (`DashboardHomeState`, `DeviceManagerState`, `FirmwareUpdateState`, etc.) must be mocked to compose the complete initial state of the page.

### 4. Test Execution & Verification

Verification should be precise and robust.

- **Prerequisite: Understand Implementation Code**: Before writing any `expect` assertions, it is **critical** to thoroughly read and understand the actual UI implementation file (e.g., `lib/page/instant_setup/pnp_setup_view.dart`). This step is essential to accurately identify:
    - The types of widgets used (e.g., `AppText`, `AppFilledButton`, `TextButton`).
    - Any unique `Key`s assigned to widgets (e.g., `Key('pnp_loading_spinner')`).
    - The exact localization keys used for text content (e.g., `loc(context).pnpModemLightsOffTitle`).
    - The presence and `semanticsLabel` of images (e.g., `find.bySemanticsLabel('modem Device image')`).
    - The overall structure and hierarchy of the UI.
  Failing to do so can lead to brittle or incorrect assertions.

- **Precise UI Verification**: Do not rely solely on screenshots. Each test case must include a series of `expect` assertions to programmatically verify that all critical UI elements are in the correct state. These assertions must be rigorously cross-referenced with the actual implementation code (e.g., `lib/page/instant_setup/pnp_setup_view.dart`) to ensure they accurately reflect the UI elements, text content (using localization keys where applicable), and icons used in the production code.

- **In-Test Screenshots**: For a test case that involves a sequence of user interactions (e.g., open dialog -> enter invalid text -> show error), use a custom helper (like `TestHelper.takeScreenshot`) to capture screenshots at multiple points within the **same `testLocalizations` block**. This is more efficient than creating a separate test case for each intermediate state.

- **Disambiguating Finders**: When multiple widgets with the same text might exist on the screen (e.g., a `hintText` and a dialog `title`), use `find.descendant` to scope the search within a parent widget and ensure test stability.

- **Handling Asynchronicity**:
    - **Image Pre-caching**: For tests that display images, use the `preCacheRouterImages` parameter or `tester.runAsync` with `precacheImage` to prevent flaky tests caused by image loading delays.
    - **UI Stabilization**: After triggering a state change or UI animation (e.g., tapping a button that shows a dialog), use `await tester.pumpAndSettle()` to ensure the UI has reached a stable state before making assertions or taking a screenshot.

### 5. Test-Related File Locations

This section lists common test-related files and their locations for quick reference.

- `@test/common/test_helper.dart`: Contains the `TestHelper` class, which centralizes setup, mocks, and utility functions for screenshot tests.
- `@test/common/test_responsive_widget.dart`: Provides utilities for testing responsive widgets across different screen sizes and locales, including `testResponsiveWidgets` and `testLocalizations`.