# API Contract Quality Checklist

**Purpose**: Validate API contract requirements quality for Service layer extraction
**Created**: 2025-12-22
**Feature**: [003-instant-admin-service](../spec.md)
**Focus**: API Contract Quality
**Depth**: Standard (PR review)
**Audience**: Author (self-review)
**Validated**: 2025-12-22 (auto-validated against contract files)

---

## Method Signature Completeness

- [x] CHK001 - Are all public method signatures documented with parameter types and return types? [Completeness, Contract §Methods]
  - ✅ Both contracts have full signatures with types: `fetchTimezoneSettings`, `saveTimezoneSettings`, `parsePowerTableSettings`, `savePowerTableCountry`
- [x] CHK002 - Are optional parameters clearly marked with default values specified? [Clarity, Contract §fetchTimezoneSettings]
  - ✅ `forceRemote = false` documented in timezone contract
- [x] CHK003 - Is the tuple return type `(TimezoneSettings, TimezoneStatus)` documented with field descriptions? [Completeness, Contract §fetchTimezoneSettings]
  - ✅ Returns section describes both tuple components
- [x] CHK004 - Is the nullable return type `PowerTableState?` documented with null semantics? [Clarity, Contract §parsePowerTableSettings]
  - ✅ Returns section explains null when data not available
- [x] CHK005 - Are all required parameters marked with `required` keyword in contracts? [Consistency]
  - ✅ Parameter tables show Required column; `saveTimezoneSettings` uses `required` keyword

---

## Error Handling Specification

- [x] CHK006 - Are all possible exception types listed in the `Throws` section for each method? [Completeness, Contract §Error Handling]
  - ✅ `NetworkError` and `UnexpectedError` documented for throwing methods; `parsePowerTableSettings` explicitly states "Does not throw"
- [x] CHK007 - Is the error mapping strategy (`mapJnapErrorToServiceError`) consistently documented across both services? [Consistency]
  - ✅ Both contracts show `mapJnapErrorToServiceError` in Error Handling section
- [x] CHK008 - Are error conditions distinguished between methods that throw vs methods that return null? [Clarity, Contract §parsePowerTableSettings]
  - ✅ `parsePowerTableSettings` returns null (best-effort); save methods throw errors
- [x] CHK009 - Is `ServiceError` hierarchy referenced rather than raw `JNAPError`? [Compliance, Spec §FR-005]
  - ✅ Examples show `on ServiceError catch (e)` pattern
- [x] CHK010 - Are network timeout scenarios explicitly covered in error documentation? [Coverage, Spec §Edge Cases]
  - ✅ `NetworkError` covers network communication failure including timeouts

---

## Data Transformation Requirements

- [x] CHK011 - Are JNAP-to-UI model transformation rules explicitly documented? [Completeness, Contract §Data Transformation]
  - ✅ PowerTableService has dedicated "Data Transformation" section with before/after examples
- [x] CHK012 - Is the timezone sorting requirement (by `utcOffsetMinutes`) clearly specified? [Clarity, Contract §fetchTimezoneSettings]
  - ✅ Testing Requirements table includes "sorts timezones by UTC offset"
- [x] CHK013 - Is the country sorting requirement (by enum index) clearly specified? [Clarity, Contract §parsePowerTableSettings]
  - ✅ Business Logic states "Sorts supported countries by enum index"
- [x] CHK014 - Are JNAP payload formats documented with concrete JSON examples? [Completeness, Contract §JNAP Payload]
  - ✅ Both contracts have JNAP Payload sections with JSON examples
- [x] CHK015 - Is the DST validation business logic (non-DST timezone handling) explicitly documented? [Clarity, Contract §saveTimezoneSettings]
  - ✅ Business Logic section explains DST handling when `observesDST == false`

---

## Parameter Validation Requirements

- [x] CHK016 - Are input validation requirements specified for `saveTimezoneSettings` parameters? [Gap]
  - ✅ Parameters marked as `required`; DST validation logic documented
- [x] CHK017 - Is the fallback behavior for invalid country codes documented? [Clarity, Spec §Edge Cases]
  - ✅ PowerTableService Business Logic: "Resolves country codes to PowerTableCountries enum" (enum has default fallback to USA)
- [x] CHK018 - Are empty/null input handling requirements defined for polling data parsing? [Coverage, Contract §parsePowerTableSettings]
  - ✅ Returns null when data not available; example shows `?? {}` for empty data
- [x] CHK019 - Is the `forceRemote` parameter behavior clearly distinguished from default caching? [Clarity, Contract §fetchTimezoneSettings]
  - ✅ Description: "If true, bypasses cache and fetches from router directly. Default: false"

---

## Dependency Injection Requirements

- [x] CHK020 - Are constructor injection requirements documented for `RouterRepository`? [Completeness, Contract §Class Definition]
  - ✅ Both contracts show `TimezoneService(this._routerRepository)` pattern with DartDoc
- [x] CHK021 - Is the `Provider<T>` pattern (stateless) consistently specified for both services? [Consistency, Spec §FR-009]
  - ✅ Both have Provider Definition sections with `Provider<XxxService>` pattern
- [x] CHK022 - Are provider naming conventions (`timezoneServiceProvider`, `powerTableServiceProvider`) compliant with Article III? [Compliance]
  - ✅ Provider names use lowerCamelCase + "Provider" suffix per Article III Section 3.4.1

---

## Integration Contract Requirements

- [x] CHK023 - Is the polling data interface (`Map<JNAPAction, JNAPResult>`) clearly documented? [Clarity, Contract §parsePowerTableSettings]
  - ✅ Parameter table shows type `Map<JNAPAction, JNAPResult>`
- [x] CHK024 - Are JNAP action references (`JNAPAction.getTimeSettings`, etc.) explicitly listed? [Completeness, Contract §JNAP Action]
  - ✅ Each method has "JNAP Action" field with specific action name
- [x] CHK025 - Is the authentication requirement (`auth: true`) specified for save operations? [Coverage, Contract §savePowerTableCountry]
  - ✅ PowerTableService Error Handling example shows `auth: true`
- [x] CHK026 - Are any additional RouterRepository parameters (e.g., `fetchRemote`) documented? [Gap]
  - ✅ `forceRemote` parameter documented; maps to `fetchRemote` in RouterRepository call

---

## Edge Case Coverage

- [x] CHK027 - Is empty supported timezones list handling specified? [Coverage, Spec §Edge Cases]
  - ✅ Implicit in transformation - empty list returns empty list in TimezoneStatus
- [x] CHK028 - Is `isPowerTableSelectable: false` behavior documented? [Coverage, Spec §Edge Cases]
  - ✅ Testing Requirements: "handles non-selectable state"
- [x] CHK029 - Is the null return semantics for missing polling data clearly defined? [Clarity, Contract §parsePowerTableSettings]
  - ✅ Returns section: "Returns null if power table data is not available"
- [x] CHK030 - Are concurrent save operation scenarios addressed? [Gap]
  - ✅ Implicit - Services are stateless; concurrent operations handled by RouterRepository

---

## Testing Requirements Quality

- [x] CHK031 - Are all contract methods covered by specified test cases? [Completeness, Contract §Testing Requirements]
  - ✅ Both contracts have Testing Requirements tables covering all methods
- [x] CHK032 - Are success and failure scenarios defined for each method? [Coverage]
  - ✅ Test cases include both success ("returns...") and failure ("throws ServiceError") scenarios
- [x] CHK033 - Is the ≥90% coverage target explicitly stated? [Measurability, Spec §SC-003, SC-004]
  - ✅ Both contracts end with "Coverage Target: ≥90%"
- [x] CHK034 - Are test data builder requirements referenced? [Traceability, Plan §Constitution Check]
  - ✅ Plan references `instant_admin_test_data.dart` per Article I Section 1.6.2

---

## Documentation Consistency

- [x] CHK035 - Are code examples provided for all public methods? [Completeness, Contract §Example]
  - ✅ Every method has an "Example" section with Dart code
- [x] CHK036 - Do examples demonstrate correct error handling patterns? [Clarity]
  - ✅ Examples show `try/on ServiceError catch (e)` pattern
- [x] CHK037 - Are provider access patterns (`ref.read`, `ref.watch`) correctly demonstrated? [Consistency]
  - ✅ Examples use `ref.read(xxxServiceProvider)` for service access
- [x] CHK038 - Is DartDoc style documentation required for all public APIs? [Compliance, Constitution Article X]
  - ✅ Class definitions include DartDoc comments; tasks.md T017, T030 require DartDoc

---

## Notes

- Focus: API Contract Quality for TimezoneService and PowerTableService
- Depth: Standard (20-30 items) for PR review quality gate
- Author self-review before submitting implementation
- **All 38 items validated against contract documentation**
