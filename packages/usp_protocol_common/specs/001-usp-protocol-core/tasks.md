# Tasks: USP Protocol Common Core Library

**Input**: Design documents from `/specs/001-usp-protocol-core/`
**Prerequisites**: spec.md

## Phase 1: Project Setup & Core Dependencies

This phase ensures the project is correctly configured with all necessary dependencies.

- [x] T001 Verify and update `pubspec.yaml` with `protobuf`, `equatable`, `json_annotation` dependencies and `build_runner`, `json_serializable`, `test` dev_dependencies.
- [x] T002 [P] Create `build.yaml` to configure `json_serializable` for `explicit_to_json: true` and `any_map: true`.
- [x] T003 [P] Create `analysis_options.yaml` for strict linting rules
- [x] T004 Verify existing directory structure as per `plan.md`: `lib/src/value_objects`, `lib/src/dtos`, `lib/src/exceptions`, `lib/src/generated`, `lib/src/converter`, `lib/src/services`, `lib/src/interfaces`, `lib/src/record` in `lib/src`.

---

## Phase 2: Foundational (Protocol Contracts)

**Purpose**: Define the contract-first source of truth for the protocol.

- [x] T005 Create `protos/usp_msg.proto` with message definitions for Header, Body, Request, Response, Error, etc.
- [x] T006 [P] Create `protos/usp_record.proto` with the Record message definition
- [x] T007 Run `protoc` compiler to generate initial Dart classes in `lib/src/generated/`

---

## Phase 3: User Story 3 - Robust Path & Value Handling (Priority: P3) 🎯 MVP

**Goal**: Implement the core data primitives of the USP protocol for reliable and type-safe data handling.
**Independent Test**: Value objects can be created, validated, and compared independently of any other library components.

### Tests for User Story 3 ⚠️
- [x] T008 [P] [US3] Create `test/value_objects/usp_path_test.dart` to test path parsing, normalization (trailing dots), and property access (`name`, `parent`)
- [x] T009 [P] [US3] Create `test/value_objects/usp_path_wildcard_test.dart` for wildcard path scenarios.
- [x] T010 [P] [US3] Create `test/value_objects/usp_value_test.dart` to test type-aware JSON serialization and deserialization.

### Implementation for User Story 3
- [x] T011 [P] [US3] Implement `UspPath` in `lib/src/value_objects/usp_path.dart` with `Equatable` and `json_serializable`
- [x] T012 [P] [US3] Implement `UspValue` and `UspValueType` in `lib/src/value_objects/usp_value.dart`
- [x] T013 [P] [US3] Implement `InstanceId` in `lib/src/value_objects/instance_id.dart`

---

## Phase 4: User Story 1 - Type-Safe Message Handling (Priority: P1)

**Goal**: Provide developers with strongly-typed Dart objects for all USP messages.
**Independent Test**: DTOs can be instantiated and compared. Their properties can be accessed correctly.

### Tests for User Story 1 ⚠️
- [x] T014 [P] [US1] Create `test/dtos/requests/get_request_test.dart` for `UspGetRequest` ensuring correct property assignment and `Equatable` implementation.
- [x] T015 [P] [US1] Create `test/dtos/responses/get_response_test.dart` for `UspGetResponse` ensuring correct property assignment and `Equatable` implementation.
- [x] T016 [P] [US1] Create `test/dtos/requests/set_request_test.dart` for `UspSetRequest` ensuring correct property assignment and `Equatable` implementation.
- [x] T017 [P] [US1] Create `test/dtos/responses/set_response_test.dart` for `UspSetResponse` ensuring correct property assignment and `Equatable` implementation.
- [x] T018 [P] [US1] Create `test/dtos/requests/add_request_test.dart` for `UspAddRequest` ensuring correct property assignment and `Equatable` implementation.
- [x] T019 [P] [US1] Create `test/dtos/responses/add_response_test.dart` for `UspAddResponse` ensuring correct property assignment and `Equatable` implementation.
- [x] T020 [P] [US1] Create `test/dtos/requests/delete_request_test.dart` for `UspDeleteRequest` ensuring correct property assignment and `Equatable` implementation.
- [x] T021 [P] [US1] Create `test/dtos/responses/delete_response_test.dart` for `UspDeleteResponse` ensuring correct property assignment and `Equatable` implementation.
- [x] T022 [P] [US1] Create `test/dtos/responses/error_response_test.dart` for `UspErrorResponse` ensuring correct property assignment and `Equatable` implementation.
- [x] T023 [P] [US1] Create `test/dtos/requests/operate_request_test.dart` for `UspOperateRequest` ensuring correct property assignment and `Equatable` implementation.
- [x] T024 [P] [US1] Create `test/dtos/responses/operate_response_test.dart` for `UspOperateResponse` ensuring correct property assignment and `Equatable` implementation.
- [x] T025 [US1] Write unit tests for `UspException` in `test/exceptions/usp_exception_test.dart`.

### Implementation for User Story 1
- [x] T026 [P] [US1] Implement `UspGetRequest` in `lib/src/dtos/requests/get_request.dart`.
- [x] T027 [P] [US1] Implement `UspGetResponse` in `lib/src/dtos/responses/get_response.dart`.
- [x] T028 [P] [US1] Implement `UspSetRequest` in `lib/src/dtos/requests/set_request.dart`.
- [x] T029 [P] [US1] Implement `UspSetResponse` in `lib/src/dtos/responses/set_response.dart`.
- [x] T030 [P] [US1] Implement `UspAddRequest` in `lib/src/dtos/requests/add_request.dart`.
- [x] T031 [P] [US1] Implement `UspAddResponse` in `lib/src/dtos/responses/add_response.dart`.
- [x] T032 [P] [US1] Implement `UspDeleteRequest` in `lib/src/dtos/requests/delete_request.dart`.
- [x] T033 [P] [US1] Implement `UspDeleteResponse` in `lib/src/dtos/responses/delete_response.dart`.
- [x] T034 [P] [US1] Implement `UspErrorResponse` in `lib/src/dtos/responses/error_response.dart`.
- [x] T035 [P] [US1] Implement `UspOperateRequest` in `lib/src/dtos/requests/operate_request.dart`.
- [x] T036 [P] [US1] Implement `UspOperateResponse` in `lib/src/dtos/responses/operate_response.dart`.
- [x] T037 [P] [US1] Implement `UspException` in `lib/src/exceptions/usp_exception.dart`.

---

## Phase 5: User Story 2 - Protocol Serialization & Deserialization (Priority: P2)

**Goal**: Enable conversion between the high-level Dart DTOs and the low-level Protobuf wire format.
**Independent Test**: A full round-trip conversion (DTO -> Proto -> DTO) results in an identical object.

### Tests for User Story 2 ⚠️
- [x] T038 [P] [US2] Create `test/converter/usp_protobuf_converter_test.dart` with round-trip tests for all message types.
- [x] T039 [P] [US2] Create `test/record/usp_record_helper_test.dart` to test wrapping and unwrapping of plaintext records.
- [x] T040 [P] [US2] Create `test/services/path_resolver_test.dart` with mock `ITraversableNode` objects to test path resolution logic.

### Implementation for User Story 2
- [x] T041 [US2] Implement `UspProtobufConverter` in `lib/src/converter/usp_protobuf_converter.dart`.
- [x] T042 [US2] Implement `UspRecordHelper` in `lib/src/record/usp_record_helper.dart`.
- [x] T043 [P] [US2] Define the `ITraversableNode` interface in `lib/src/interfaces/i_traversable_node.dart`.
- [x] T044 [US2] Implement the stateless `PathResolver` service in `lib/src/services/path_resolver.dart`.

---

## Phase 6: Polish & Finalization

- [x] T045: Add comprehensive DartDoc comments to all public APIs, classes, and methods.
- [x] T046: Run `dart analyze` and fix all reported issues.
- [x] T047: Verify 95% unit test coverage for core logic (converters, path parsing, resolver) using `dart test --coverage` and generate a report.
- [x] T048: Review and refactor code for readability (adherence to Dart style guide and effective use of language features), performance (identify and optimize critical paths/avoid common pitfalls), and adherence to the project's constitution.

---

## Dependencies & Execution Order

- **Foundational (Phase 2)** depends on **Setup (Phase 1)**.
- **User Story 3 (Primitives)** depends on **Setup (Phase 1)**.
- **User Story 1 (DTOs)** depends on **User Story 3 (Primitives)**.
- **User Story 2 (Converters/Tools)** depends on **Foundational (Phase 2)** and **User Story 1 (DTOs)**.
- **Polish** should be done last.

The recommended sequential implementation order is: **Setup -> Foundational -> US3 -> US1 -> US2 -> Polish**.

## Implementation Strategy

### MVP First (User Story 3)

1.  Complete Phase 1: Setup
2.  Complete Phase 3: User Story 3 (Primitives)
3.  **STOP and VALIDATE**: All value objects are fully tested and reliable. This forms the core of the library.

### Incremental Delivery

1.  Complete **Setup** and **Foundational** phases.
2.  Add **User Story 3 (Primitives)** -> Core data types are ready.
3.  Add **User Story 1 (DTOs)** -> Full message contracts are available.
4.  Add **User Story 2 (Tools)** -> The library is now fully functional for serialization and path resolution.
5.  Complete **Polish** phase for a production-ready release.
