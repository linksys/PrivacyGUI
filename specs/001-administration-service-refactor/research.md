# Phase 0: Research & Best Practices

**Date**: 2024-12-03
**Purpose**: Resolve unknowns and establish best practices for service extraction refactor

---

## 1. JNAP Action Orchestration Pattern

### Decision
Use a single coordinated `JNAPTransactionBuilder` with all four actions (getManagementSettings, getUPnPSettings, getALGSettings, getExpressForwardingSettings) bundled in one transaction call, as per the existing pattern in the codebase.

### Rationale
- **Consistency**: Existing codebase pattern (e.g., other providers) uses bundled transactions
- **Efficiency**: Single network roundtrip for all settings (vs. 4 sequential calls)
- **Atomicity**: All settings fetched at same timestamp; reduces inconsistency risk
- **Error handling**: Unified error context for the entire transaction

### Alternatives Considered
| Approach | Pros | Cons | Rejected Because |
|----------|------|------|-----------------|
| Sequential calls | Better granularity | 4 network roundtrips; timing skew | Performance penalty for single-use fetch |
| Bundled transaction | Atomic, efficient | Partial failure harder to debug | Existing codebase already uses bundled; no need to reinvent |
| Parallel futures (zip) | Potential performance gain | Complex dependency tracking | Over-engineering for this feature set |

---

## 2. Error Handling Strategy for Partial Failures

### Decision
If any of the four JNAP actions returns an error, the entire `fetchAdministrationSettings()` call fails with a descriptive error indicating which action failed and why.

### Rationale
- **Consistency**: Follows existing `JNAPTransactionSuccessWrap` patterns in the codebase
- **Simplicity**: Avoids partial state (some settings valid, others missing) which would complicate the Notifier
- **User experience**: Better to show "fetch failed; retry" than partial/stale settings
- **Testing**: Easier to verify (either all succeed or all fail)

### Alternatives Considered
| Approach | Behavior | Trade-off | Rejected Because |
|----------|----------|-----------|-----------------|
| Fail entire transaction | All/nothing semantics | No partial data | **CHOSEN**: Simplest; matches existing patterns |
| Return partial results | Some settings valid | Complex state merging | Notifier would need complex fallback logic |
| Retry failed action | Resilience | Unbounded latency | Over-engineering for administration settings |

---

## 3. Service Injection Pattern

### Decision
Service uses `ref.read(routerRepositoryProvider)` to access the JNAP router (provider-based injection).

### Rationale
- **Consistency**: Matches existing Notifier pattern for dependency access
- **Testability**: Riverpod's `ref.read()` can be mocked in tests via `ProviderContainer` or test helpers
- **Simplicity**: No constructor injection required; service remains stateless and lightweight

### Alternatives Considered
| Pattern | Access | Setup | Rejected Because |
|---------|--------|-------|-----------------|
| Provider injection (`ref.read()`) | Via ref parameter | Service method signature includes ref | **CHOSEN**: Consistent with codebase |
| Constructor injection | Via init parameter | Service(this.repo) | Less idiomatic for Riverpod-based code |
| Service Locator (GetIt) | Via global registry | Requires setup in main() | Inconsistent with project's Riverpod choice |

---

## 4. Data Model Transformation

### Decision
Service instantiates domain models (ManagementSettings, UPnPSettings, etc.) using their existing `fromMap()` constructors. No new data structures introduced.

### Rationale
- **Reuse**: Existing domain models already implement all required attributes
- **Consistency**: Follows existing data layer patterns (e.g., other repositories)
- **Minimal changes**: Reduces diff and risk of bugs
- **Type safety**: `fromMap()` is type-checked at compile time

### Alternatives Considered
| Approach | Data Structure | Responsibility | Rejected Because |
|----------|----------------|-----------------|-----------------|
| Use existing `fromMap()` | Domain models | Service calls `.fromMap()` on raw JNAP data | **CHOSEN**: Minimal and proven |
| Create DTO layer | Intermediate objects | Service → DTO → Domain | Over-engineering; existing models are already lightweight |
| Parse in Notifier | Raw maps | Notifier performs transformation | Violates Clean Architecture; JNAP logic leaks to UI layer |

---

## 5. Test Coverage Strategy

### Decision
- Service unit tests: mock `RouterRepository`, verify transformation and error paths (target >90% coverage)
- Notifier tests: mock `AdministrationSettingsService`, verify state updates and PreservableNotifierMixin behavior
- No integration tests (out of scope for this refactor; existing integration tests cover end-to-end flows)

### Rationale
- **Isolation**: Unit tests for service and Notifier separately; clear layer boundaries
- **Speed**: Mocked tests run <100ms per test suite (no real JNAP calls)
- **Maintainability**: Each test class focuses on one layer's responsibility
- **Coverage goal**: 80%+ per file (constitution requirement); service designed for easy mockability

### Test Structure
```
test/page/advanced_settings/administration/services/
├── administration_settings_service_test.dart
   ├── "fetches all four settings successfully"
   ├── "handles individual action failure"
   ├── "parses ManagementSettings correctly"
   ├── "parses UPnPSettings correctly"
   ├── "parses ALGSettings correctly"
   ├── "parses ExpressForwardingSettings correctly"
   └── "returns error with context on failure"

test/page/advanced_settings/administration/providers/
└── administration_settings_provider_test.dart (MODIFIED)
    ├── "delegates to service on performFetch"
    ├── "updates state with service results"
    └── "handles service errors gracefully"
```

---

## 6. Backward Compatibility

### Decision
External API of `AdministrationSettingsNotifier` remains completely unchanged:
- Same provider interface (`administrationSettingsProvider`)
- Same state structure (`AdministrationSettingsState`)
- Same public methods (`performFetch()`, `set*()`, etc.)
- Internal refactor only; no consumers need changes

### Rationale
- **Stability**: Other components and tests continue to work without modification
- **Simplicity**: Reduces PR review scope (implementation detail only)
- **Risk mitigation**: Zero chance of breaking existing functionality

---

## 7. Performance Targets

### Decision
- Service instantiation + JNAP transaction: <50ms
- Notifier's `performFetch()` total: <200ms (cold start with network), <50ms (cache hit)
- No UI frame drops during fetch (async operation, non-blocking)

### Rationale
- **User experience**: Settings screen loads within normal app response time (<200ms perceived latency)
- **Smooth UI**: Data fetching doesn't block main thread (Riverpod handles async naturally)
- **Acceptable for network**: JNAP transaction over local network typically <100ms; service overhead <50ms leaves room

### Measurement Plan
- Use `Stopwatch` in service for internal timing (debug-only)
- Riverpod's built-in async handling ensures non-blocking on main thread
- Integration tests (existing) will validate end-to-end latency

---

## Summary of Decisions

| Decision | Chosen | Impact |
|----------|--------|--------|
| **JNAP orchestration** | Bundled transaction | Single network call; atomic consistency |
| **Partial failure handling** | Fail entire fetch | Simpler state management in Notifier |
| **Service injection** | Provider-based (ref.read) | Consistent with codebase; testable |
| **Data models** | Reuse existing fromMap() | Minimal changes; proven patterns |
| **Testing** | Unit tests per layer + mocks | Fast, focused, >80% coverage |
| **Backward compatibility** | Fully maintained | No breaking changes |
| **Performance** | <50ms service, <200ms fetch | Acceptable for administration settings use case |

All decisions are **aligned with the project constitution** (Clean Architecture, Testability, Adapter Pattern) and **follow existing codebase patterns**.

---

## Ready for Phase 1: Design & Contracts

✅ All unknowns resolved. No NEEDS CLARIFICATION markers remain.

Next: Generate `data-model.md` and service interface contracts.
