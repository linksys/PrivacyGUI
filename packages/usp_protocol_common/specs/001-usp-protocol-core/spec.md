# Feature Specification: USP Protocol Common Core Library

**Feature Branch**: `001-usp-protocol-core`
**Created**: 2025-11-22
**Status**: Draft
**Input**: User description: "Technical Specification for `usp_protocol_common` library"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Type-Safe Message Handling (Priority: P1)

As a developer building a USP Agent or Controller, I want to create, read, and handle USP requests and responses using strongly-typed Dart objects, so that I can ensure communication correctness at compile-time and reduce runtime errors.

**Why this priority**: This is the fundamental purpose of the library—providing a reliable contract between communicating parties.

**Independent Test**: Can be tested by creating an instance of each request/response DTO, verifying its properties, and ensuring `Equatable` works as expected.

**Acceptance Scenarios**:
1.  **Given** a developer needs to request a parameter value, **When** they instantiate a `UspGetRequest` with a list of path strings, **Then** the object is created successfully with the correct properties.
2.  **Given** a `UspAddResponse` is received, **When** a developer accesses its properties, **Then** they can retrieve the `instantiatedPath` for the newly created object.
3.  **Given** two identical `UspSetRequest` objects are created, **When** they are compared using `==`, **Then** the result is `true`.

---

### User Story 2 - Protocol Serialization & Deserialization (Priority: P2)

As a developer, I need to convert the Dart USP message objects to and from the standard binary wire format (Protobuf), so that my application can send and receive messages over a network connection.

**Why this priority**: This enables actual communication; without it, the DTOs are just local data structures.

**Independent Test**: Can be tested by converting a DTO to its Protobuf representation and then converting it back to a DTO, ensuring the result is identical to the original.

**Acceptance Scenarios**:
1.  **Given** a `UspSetRequest` DTO, **When** it is converted to the Protobuf format, **Then** the output is a valid `pb.Msg` object with the correct `oneof` field (request) populated.
2.  **Given** a `List<int>` of bytes representing a USP Record, **When** it is unwrapped and converted from Protobuf, **Then** the correct `UspMessage` DTO (e.g., `UspGetResponse`) is returned.
3.  **Given** a Protobuf message with an unknown or unsupported type is received, **When** it is converted, **Then** a `UspException` with a specific error code (e.g., 7004) is thrown.

---

### User Story 3 - Robust Path & Value Handling (Priority: P3)

As a developer, I want to work with USP paths and values as reliable, validated objects, so that I can avoid common formatting errors and safely handle data of different types.

**Why this priority**: Ensures that the fundamental data primitives of the protocol are handled correctly and consistently, including validation against USP path rules, graceful handling of malformed inputs, and type integrity across conversions.

**Independent Test**: Can be tested by creating `UspPath` and `UspValue` objects with various inputs (valid, invalid, edge cases) and asserting their properties or error states.

**Acceptance Scenarios**:
1.  **Given** a path string like `"Device.LocalAgent."`, **When** a `UspPath` object is created, **Then** it is correctly normalized (e.g., trailing dot removed) and its `name` and `parent` properties are correctly identified.
2.  **Given** a `UspValue` containing a string, **When** it is serialized to JSON, **Then** the output JSON includes both the value and its type information to allow for correct deserialization.
3.  **Given** an invalid path string is used to create a `UspPath`, **When** the parse method is called, **Then** an exception is thrown immediately.

## Requirements *(mandatory)*

### Functional Requirements

-   **FR-001**: The system MUST provide immutable Dart classes (DTOs) for all standard USP requests and responses (Get, Set, Add, Delete, Operate, Error).
-   **FR-002**: The system MUST provide tools to convert DTOs to and from the binary Protobuf format as defined in the `usp_msg.proto` and `usp_record.proto` files.
-   **FR-003**: The system MUST provide a `UspPath` value object that can parse, validate, and normalize USP path strings, including support for wildcard (`*`) characters.
-   **FR-004**: The system MUST provide a `UspValue` value object that encapsulates different data types (string, int, bool, etc.) and supports type-aware JSON serialization.
-   **FR-005**: All DTOs and Value Objects MUST implement `Equatable` for value-based comparison.
-   **FR-006**: The library MUST throw a custom `UspException` with appropriate error codes for failures like parsing errors or unsupported message types.
-   **FR-007**: The library MUST provide a stateless `PathResolver` utility that can search a data structure implementing the `ITraversableNode` interface using a `UspPath`.

### Key Entities *(include if feature involves data)*

-   **UspMessage**: The base concept for all requests and responses. It is specialized into concrete DTOs like `UspGetRequest` and `UspGetResponse`.
-   **UspPath**: Represents a path to an object or parameter in the USP data model.
-   **UspValue**: A container for a value of a specific USP data type.
-   **UspRecord**: A wrapper for a `UspMessage` used for transport, containing sender/receiver IDs.
-   **ITraversableNode**: An interface representing a node in a tree-like data structure that can be traversed by `PathResolver`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

-   **SC-001**: All core logic (converters, path parsing, resolver) achieves at least 95% unit test coverage.
-   **SC-002**: A round-trip conversion (DTO -> Proto -> DTO) of any standard USP message results in an object that is equal to the original.
-   **SC-003**: The library passes `flutter analyze` with zero warnings or errors, adhering to all strict linting rules defined in `analysis_options.yaml`.
-   **SC-004**: The library can be successfully compiled and run on all three target platforms: Dart VM (server-side), Flutter Mobile (iOS/Android), and Flutter Web.
-   **SC-005**: All public APIs, DTOs, and value objects are fully documented with DartDoc comments explaining their purpose and usage.