# Feature Specification: Refactor Screenshot Tests to use TestHelper

**Feature Branch**: `refactor/screenshot-tests`  
**Created**: 2025-10-23  
**Status**: Draft  
**Input**: User description: "This is the task to update all old screenshot testing to the new testHelper."

## Constitution Compliance

- **User-Centric Design**: N/A. This is a refactoring task with no direct impact on the user experience.
- **Solid Architecture**: This refactoring improves the test architecture by centralizing test setup logic, making it more maintainable and scalable.
- **Comprehensive Testing**: This task is all about improving the testing framework.
- **Code Quality and Style**: The refactoring will improve code quality and style by removing boilerplate code and enforcing a consistent way of writing tests.
- **Modularity and Reusability**: The `TestHelper` is a reusable component that encapsulates test setup logic.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Refactor a single screenshot test (Priority: P1)

As a developer, I want to refactor a single screenshot test to use the `TestHelper` class, so that the test is cleaner, more readable, and easier to maintain.

**Why this priority**: This is the core task of this refactoring effort.

**Independent Test**: A refactored test can be run independently and should produce the same screenshot as the original test.

**Acceptance Scenarios**:

1. **Given** an old screenshot test file (e.g., `apps_and_gaming_view_test.dart`), **When** it is refactored, **Then** it must use the `TestHelper` for mock setup and widget pumping.
2. **Given** a refactored test, **When** the test is executed, **Then** it must pass and generate the same golden file as before the refactoring.
3. **Given** a refactored test, **Then** all unused imports and variables must be removed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All screenshot tests (`*_test.dart` files containing `testLocalizations`) MUST be refactored to use the `TestHelper` class.
- **FR-002**: The refactoring MUST NOT change the behavior or coverage of the existing tests.
- **FR-003**: The `TestHelper` class MUST be used to instantiate and set up all mock notifiers.
- **FR-004**: The `testHelper.pumpView()` or `testHelper.pumpShellView()` methods MUST be used to render the widget under test.
- **FR-005**: All manual mock creation, `setUp` boilerplate, and direct calls to `testableSingleRoute` in the test files MUST be removed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of screenshot tests are refactored to use `TestHelper`.
- **SC-002**: The lines of code in the screenshot test files are significantly reduced (estimated 30-50% reduction).
- **SC-003**: The time to write a new screenshot test is reduced due to the simplified setup.
