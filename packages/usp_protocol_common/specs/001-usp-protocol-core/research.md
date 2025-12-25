# Research for USP Protocol Common Core Library

This document outlines the research tasks needed to resolve ambiguities and define best practices for the `usp_protocol_common` library.

## Research Findings and Decisions

### 1. Clarify Dependency Choices: `freezed` vs. `equatable`

**Decision**: Adopt the `equatable` package for creating DTOs and Value Objects that support value-based equality.

**Rationale**:
The user prefers `equatable` over `freezed`. While `freezed` offers extensive boilerplate reduction and enforced immutability, `equatable` provides a simpler approach to value equality without requiring code generation for class definitions. This simplifies the build process and reduces project complexity. To ensure immutability, classes will be designed with `final` fields and appropriate constructors.

**Alternatives Considered**:
- **`freezed`**: Provides comprehensive features like immutability, `copyWith`, and union types with code generation. Rejected due to user preference.

### 2. Define Performance Goals

**Decision**: Establish initial, measurable performance goals for key serialization and deserialization operations.

**Rationale**: Defining performance goals upfront provides clear targets for optimization and testing, ensuring the library meets practical application needs. Without explicit goals, performance characteristics might drift, leading to unexpected bottlenecks in dependent applications.

**Initial Performance Goals**:
- **Serialization (Dart object to Protobuf binary)**: A typical USP message (e.g., a `Get` response with 10 parameters) should serialize in under **5 milliseconds** on a standard developer workstation (e.g., Intel i7/AMD Ryzen 7 or Apple M-series chip) and under **50 milliseconds** on mid-range mobile devices.
- **Deserialization (Protobuf binary to Dart object)**: A typical USP message should deserialize in under **5 milliseconds** on a standard developer workstation and under **50 milliseconds** on mid-range mobile devices.
- **Memory Usage**: The memory footprint of the library itself (excluding instantiated DTOs/Value Objects) should be minimal, ideally under **5MB** during typical operation. Individual message objects should aim for efficient memory utilization, relative to their data content.

**Measurement and Testing Plan**:
- Implement micro-benchmarks using Dart's `benchmark_harness` or similar tools for serialization and deserialization of various USP message types and sizes.
- Integrate performance tests into the CI/CD pipeline to track regressions.
- Conduct profiling on target platforms (Dart VM, Flutter Mobile, Flutter Web) to identify and address bottlenecks.

### 3. Best Practices for Dependencies

**Decision**: Document best practices for using the chosen dependencies: `protobuf`, `json_serializable`, and `equatable`.

**Rationale**: Establishing clear guidelines for dependency usage ensures code consistency, reduces cognitive load for developers, and simplifies onboarding for new team members. It also helps in avoiding common pitfalls and leveraging the full potential of each package.

**Key Best Practices (to be detailed in a `CONTRIBUTING.md` or similar document)**:
- **Protobuf**:
    - Adhere strictly to a defined `.proto` style guide (e.g., Google's Protobuf style guide).
    - All `.proto` changes must be followed by `flutter pub run build_runner build` (or `dart run`) to regenerate Dart code. Generated files must not be manually modified.
    - Use `oneof` fields judiciously for mutually exclusive message types (e.g., for `Request` and `Response` types within a `UspMessage`).
    - Use `repeated` fields for lists and arrays, ensuring they are properly initialized.
- **`json_serializable`**:
    - Configure `build.yaml` for optimal code generation, including `explicit_to_json: true` and `any_map: true` if needed for flexibility.
    - Utilize `@JsonKey` for mapping JSON field names that differ from Dart property names.
    - For custom type serialization (e.g., `DateTime` to ISO 8601 string), use `toJson` and `fromJson` converters via `@JsonKey(fromJson: ..., toJson: ...)`. 
- **`equatable`**:
    - All properties in classes extending `Equatable` should be declared as `final` to ensure immutability.
    - Override the `props` getter to include all fields that define the object's value for correct comparison.
    - Ensure a `const` constructor is used where possible for compile-time constants.
