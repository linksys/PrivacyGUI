# USP-Driven UI Project Constitution

This constitution defines the foundational principles, constraints, and practices that govern all development on the USP-Driven UI project. All implementation decisions must align with these principles.

**Scope:** This constitution applies to all packages in the project. Each package has its own specification document (in `USP_Driven_UI/Specifications/`) that defines component-specific interfaces, APIs, and implementation details. The constitution governs *principles*; specs govern *implementation*.

---

## 1. Project Vision

**Build an open, standards-based UI architecture for OpenWRT routers that hides TR-181 complexity behind typed APIs while remaining UI-framework agnostic.**

### Success Criteria

- A Flutter developer can build router UI features without learning TR-181 paths
- The UI framework can be replaced (Flutter → React → native) without rewriting the client library
- Any USP-compliant agent (not just OBUSPA) can serve as the backend
- AI can assist users via natural language without compromising security

---

## 2. Architectural Principles

### 2.1 Standards First

- **USP (TR-369)** is the wire protocol — no proprietary extensions to the protocol itself
- **TR-181** is the data model — vendor extensions use the `X_VENDOR_` prefix convention
- **Protobuf** is the encoding format — as specified by Broadband Forum
- Deviation from standards requires explicit justification and documentation

### 2.2 Separation of Concerns

| Layer | Responsibility | Does NOT handle |
|-------|---------------|-----------------|
| UI (Flutter/TS/Swift) | User interaction, presentation | USP encoding, transport |
| Generated API classes | Type-safe parameter grouping | Network communication |
| usp-client (Rust) | Protobuf, HTTP/SSE, WebSocket | Business logic, UI state |
| Router daemons (C) | Auth, bridging, validation | Persistent state |
| OBUSPA | Device configuration truth | UI concerns |

### 2.3 Single Source of Truth

- **YAML definitions** are the single source for API structure → generate all language bindings
- **OBUSPA** is the single source for device state → no caching in bridge
- **UCI files** are the single source for daemon configuration → standard OpenWRT patterns

### 2.4 UI Framework Independence

The architecture must support replacing the UI technology without touching:
- The Rust usp-client core
- The YAML definitions
- The router-side components

This is achieved through:
- Rust compiling to both native (FFI) and WASM
- Language-specific binding packages with identical APIs
- Code generation from language-agnostic YAML

### 2.5 Minimal Footprint

Target environment is resource-constrained embedded devices:
- Router daemons: ~50KB binaries, written in C
- No persistent state in bridge (survives restart via re-registration)
- Protobuf encoding offloaded to UI-side (usp-client)
- UCI configuration files (standard OpenWRT)

---

## 3. Security Principles

### 3.1 Defense in Depth

| Layer | Security Measure |
|-------|-----------------|
| Transport | TLS termination at lighttpd |
| Authentication | JWT with HttpOnly, Secure, SameSite cookies |
| Authorization | lighttpd validates JWT before proxying |
| Localhost binding | USP Bridge and OBUSPA only on 127.0.0.1 |
| AI validation | Schema + whitelist validation on router, not UI |

### 3.2 AI Security Model

- **UI cannot bypass validation** — all AI-generated operations validated on router
- **Explicit deny list** — sensitive paths (passwords, security config) blocked
- **Retry loop on router** — validation failures corrected by LLM without UI involvement
- **Privacy modes** — customer controls cloud vs local vs disabled AI

### 3.3 Secure Defaults

- No credentials in generated code or YAML definitions
- Sensitive parameters marked explicitly (`sensitive: true`)
- TR-181 paths baked into compiled binary (not runtime-modifiable JSON)

---

## 4. Technology Constraints

### 4.1 Language Choices

| Component | Language | Rationale |
|-----------|----------|-----------|
| Router daemons | C | Native performance, minimal binary size, OpenWRT standard |
| usp-client core | Rust | Memory safety, FFI + WASM from single codebase |
| Code generator | C | Portability across build environments |
| Definitions | YAML | Human-readable, AI-friendly, language-agnostic |
| UI (reference) | Flutter/Dart | Cross-platform, but replaceable |

### 4.2 Dependencies

Router-side packages must use only:
- Standard OpenWRT libraries (libubox, libuci, etc.)
- Proven lightweight libraries (libmosquitto, libyaml, libjansson, libevent)
- No heavy frameworks or runtimes

### 4.3 Protocol Choices

| Purpose | Protocol | Rationale |
|---------|----------|-----------|
| Normal operations | HTTP/SSE | Multi-client, via USP Bridge |
| High-bandwidth streaming | WebSocket | Single-client turbo channel, direct to OBUSPA |
| LLM communication | MQTT | Async, supports cloud and local routing |
| Internal (bridge ↔ OBUSPA) | UDS MTP | Unix Domain Socket, USP-compliant |

---

## 5. Development Practices

### 5.1 Test-Driven Development

All implementation MUST follow TDD:

1. **Write failing test first** — defines expected behavior
2. **Implement minimum code to pass** — no speculative features
3. **Refactor with confidence** — tests ensure no regression

Test categories:
- **Unit tests**: Each module in isolation (mock dependencies)
- **Integration tests**: Component interactions (usp-client ↔ mock server)
- **End-to-end tests**: Full stack on real router hardware
- **Contract tests**: Verify binding packages implement required API surface

### 5.2 Specification-Driven Development

1. **Spec first** — document behavior before implementing
2. **YAML definitions first** — define API shape before writing glue code
3. **Generated code preferred** — reduce hand-written boilerplate
4. **Spec-implementation parity** — specs are living documents, update when implementation changes

### 5.3 Code Quality Standards

- **No warnings** — treat compiler/linter warnings as errors
- **No TODO in main branch** — track in issues instead
- **No magic numbers** — use named constants
- **No global state** — explicit dependency passing
- **Error handling explicit** — no silent failures

### 5.4 Package Isolation

The 8 packages are independently:
- Versioned (semantic versioning)
- Tested (each has own test suite)
- Deployable (can update one without rebuilding others)
- Replaceable (clear interfaces between packages)

---

## 6. AI Integration Principles

### 6.1 YAML for LLM Output

LLMs generate YAML (not JSON) for dynamic calls because:
- No trailing comma errors
- Simpler string escaping
- Better token efficiency
- More readable for debugging

### 6.2 Two-Phase Workflow

1. **Query phase**: User question → LLM generates YAML → router validates → UI executes
2. **Interpret phase**: Execution results → LLM → human-readable answer

The UI never talks directly to the LLM.

### 6.3 Graceful Degradation

- AI features can be completely disabled (enterprise policy)
- UI remains fully functional without AI
- Static (generated) API covers 99% of operations

---

## 7. Extensibility Principles

### 7.1 Vendor Extensions

- Use `X_VENDOR_` prefix for proprietary TR-181 paths
- Place in `definitions/vendor/<vendor>/` directory
- Never modify core definitions for vendor features

### 7.2 Dynamic Modules (Future)

Architecture supports LuCI-style module installation:
- Modules define own YAML → run usp-codegen at module build time
- Main UI discovers modules via `app_db.json` registry
- No main UI rebuild required to add features

### 7.3 New Languages

Adding a new target language requires:
1. New generator backend in usp-codegen
2. New binding package wrapping usp-client Rust core
3. Default import path registered in codegen

---

## 8. Documentation Standards

### 8.1 Specification Documents

Each package has a spec document covering:
- Purpose and responsibility
- Public API / interfaces
- Configuration options
- Error codes and handling
- Build and deployment

### 8.2 Code Documentation

- Public APIs: Doc comments explaining purpose, parameters, return values
- Complex logic: Inline comments explaining "why" not "what"
- No documentation for self-evident code

### 8.3 YAML Definitions

- Every definition has `description` field
- Complex presets have `description` for each option
- i18n keys follow `feature_element_variant` naming

---

## 9. Compatibility Commitments

### 9.1 Backward Compatibility

- Generated API classes maintain backward compatibility within major version
- YAML definition schema changes require migration path
- Router API endpoints versioned (`/api/v1/`, `/api/v2/`)

### 9.2 USP Compliance

- Any USP-compliant agent can replace OBUSPA
- Any USP-compliant controller can manage the device
- No reliance on OBUSPA-specific behavior

---

## 10. Decision Log

Major architectural decisions and their rationale:

| Decision | Rationale | Date |
|----------|-----------|------|
| Rust for usp-client | Single codebase for FFI + WASM | - |
| C for router daemons | OpenWRT standard, minimal footprint | - |
| YAML for definitions | Human-readable, AI-friendly, replaced JSON | - |
| YAML for LLM output | Better LLM generation reliability than JSON | - |
| JWT in HttpOnly cookie | XSS protection, multi-tab session sharing | - |
| Router-side AI validation | Security cannot be bypassed by client | - |
| Two-phase AI workflow | Separation of query generation and result interpretation | - |
| Turbo channel exclusivity | Prevent resource contention for streaming | - |

---

## Amendments

This constitution may be amended when:
1. New architectural insight requires principle update
2. Technology constraints change significantly
3. Security requirements evolve

All amendments must be documented with rationale and date.
