# Implementation Plan: USP Protocol Common Core Library

**Branch**: `001-usp-protocol-core` | **Date**: 2025-11-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/Users/austin.chang/flutter-workspaces/usp_protocol_common/specs/001-usp-protocol-core/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This plan outlines the implementation of `usp_protocol_common`, a pure Dart shared library that serves as the communication contract between a USP Agent (Server) and a Controller (Client). It will provide type-safe, platform-agnostic, and stateless objects for USP messages, paths, and values, along with tools for serialization to and from the standard Protobuf wire format.

## Technical Context

**Language/Version**: Dart 3.x
**Primary Dependencies**:
- `protobuf`: For handling the binary wire format.
- `equatable`: For value-based equality in DTOs and Value Objects.
- `json_serializable`: For type-aware JSON serialization of `UspValue`.
**Storage**: N/A (The library is stateless as per the constitution).
**Testing**: `test` (the standard Dart testing framework).
**Target Platform**: Dart VM (server-side), and consumable by Flutter Mobile (iOS/Android) and Flutter Web applications. This library itself is a pure Dart package with no direct Flutter SDK dependencies, upholding the Purity Rule.
**Project Type**: Single project (Pure Dart Package).

**Constraints**:
- Must be a pure Dart package (no Flutter SDK, `dart:io`, or `dart:html`).
- Must be stateless.
**Scale/Scope**: The library must cover all standard USP messages (Get, Set, Add, Delete, Operate, Error) and provide a `PathResolver` utility.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Neutrality Rule**: Does the proposed code maintain neutrality between Client and Server roles? **PASS**. The library's purpose is to define the contract, not implement role-specific logic.
- **Purity Rule**: Does the proposed code avoid dependencies on `flutter` and `dart:io`/`dart:html`? **PASS**. This is a core requirement and principle.
- **Stateless Rule**: Does the proposed code avoid holding runtime state? **PASS**. The library will only contain data structures and pure functions.
- **Structural Integrity**: Does the proposed code fit within the defined module structure (Primitives, Contracts, Wire Format, Tools)? **PASS**. The feature spec aligns perfectly with the constitutional structure.
- **Boundary Compliance**: Does the proposed code avoid out-of-scope concerns (Business Logic, Persistence, Transport, Internal Events)? **PASS**. The spec clearly delineates what is out of scope.

## Project Structure

### Documentation (this feature)

```text
specs/001-usp-protocol-core/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── usp_protocol_common.dart
└── src/
    ├── converter/
    │   └── usp_protobuf_converter.dart
    ├── dtos/
    │   ├── base_dto.dart
    │   ├── requests/
    │   └── responses/
    ├── exceptions/
    │   └── usp_exception.dart
    ├── generated/
    ├── interfaces/
    │   └── i_traversable_node.dart
    ├── record/
    │   └── usp_record_helper.dart
    ├── services/
    │   └── path_resolver.dart
    └── value_objects/
        ├── instance_id.dart
        ├── usp_path.dart
        ├── usp_value_type.dart
        └── usp_value.dart
test/
└── value_objects/
    ├── usp_path_alias_test.dart
    ├── usp_path_test.dart
    ├── usp_path_wildcard_test.dart
    └── usp_value_test.dart

```

**Structure Decision**: The project is a single, pure Dart library. The existing directory structure aligns with the constitution and is appropriate for this feature. New files will be added within this structure.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *No violations at this time.* | | |
| | | |
