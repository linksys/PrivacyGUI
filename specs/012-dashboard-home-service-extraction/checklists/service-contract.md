# Service Contract Requirements Quality Checklist

**Purpose**: PR review gate for DashboardHomeService contract requirements
**Created**: 2025-12-29
**Feature**: [spec.md](../spec.md) | [contract](../contracts/dashboard_home_service_contract.md)
**Focus**: Service Contract + Breaking Changes Risk

---

## Requirement Completeness

- [ ] CHK001 - Are all transformation behaviors from the original `createState()` method documented in the service contract? [Completeness, Spec §FR-002]
- [ ] CHK002 - Is the complete list of input parameters for `buildDashboardHomeState` specified with types and descriptions? [Completeness, Contract §Public Methods]
- [ ] CHK003 - Are all output fields of `DashboardHomeState` documented as being populated by the service? [Completeness, Gap]
- [ ] CHK004 - Is the `getBandForDevice` callback parameter requirement documented with its expected behavior? [Completeness, Contract §Parameters]
- [ ] CHK005 - Are all private helper methods documented with their input/output contracts? [Completeness, Contract §Private Methods]

---

## Breaking Changes Prevention

- [ ] CHK006 - Is the requirement for "identical behavior before and after refactoring" explicitly testable? [Measurability, Spec §FR-010]
- [ ] CHK007 - Are all current `DashboardHomeState` field values documented to ensure no regression? [Coverage, Gap]
- [ ] CHK008 - Is the WiFi list ordering requirement specified (must match original grouping logic)? [Clarity, Gap]
- [ ] CHK009 - Are connected device count calculation requirements specified to match original logic? [Clarity, Spec §FR-003]
- [ ] CHK010 - Is the guest network `isEnabled` flag propagation requirement documented? [Completeness, Gap]
- [ ] CHK011 - Are the `uptime`, `wanPortConnection`, `lanPortConnections` pass-through requirements specified? [Completeness, Gap]

---

## Requirement Clarity

- [ ] CHK012 - Is "groups main radios by band" clearly defined with the grouping key (`element.band`)? [Clarity, Contract §Behavior]
- [ ] CHK013 - Is the "first polling" detection logic (`lastUpdateTime == 0`) explicitly specified? [Clarity, Spec §Edge Cases]
- [ ] CHK014 - Are the `routerIconTestByModel` input requirements (modelNumber, hardwareVersion) documented? [Clarity, Contract §Dependencies]
- [ ] CHK015 - Are the `isHorizontalPorts` input requirements and fallback values documented? [Clarity, Contract §Dependencies]
- [ ] CHK016 - Is the callback signature `String Function(LinksysDevice)` unambiguous about return value semantics? [Clarity, Contract §Parameters]

---

## Contract Consistency

- [ ] CHK017 - Do the edge case behaviors in the contract align with the spec's edge case requirements? [Consistency, Spec §Edge Cases vs Contract §Error Handling]
- [ ] CHK018 - Is the service provider naming (`dashboardHomeServiceProvider`) consistent with constitution Article III? [Consistency, Constitution §3.4.1]
- [ ] CHK019 - Are the import requirements in the contract consistent with the architecture compliance goals in the spec? [Consistency, Spec §FR-007, FR-008]
- [ ] CHK020 - Does the contract's "no exceptions thrown" statement align with the pure transformation requirement? [Consistency, Contract §Error Handling]

---

## Acceptance Criteria Quality

- [ ] CHK021 - Can the "zero imports from `core/jnap/models/`" requirement be objectively verified with grep? [Measurability, Spec §SC-001]
- [ ] CHK022 - Is "identical behavior" defined with specific UI elements to verify (WiFi list, uptime, ports, nodes)? [Measurability, Spec §SC-002]
- [ ] CHK023 - Is the 90% test coverage requirement scoped to specific methods/classes? [Measurability, Spec §SC-003]
- [ ] CHK024 - Are the unit test requirements in the contract sufficient to verify all documented behaviors? [Coverage, Contract §Testing Contract]

---

## Scenario Coverage

- [ ] CHK025 - Are requirements defined for when `mainRadios` has multiple radios with the same band? [Coverage, Edge Case]
- [ ] CHK026 - Are requirements defined for when `deviceList` is empty (affects master icon)? [Coverage, Edge Case]
- [ ] CHK027 - Are requirements defined for partial data scenarios (some fields null in input states)? [Coverage, Exception Flow]
- [ ] CHK028 - Is the behavior specified when `getBandForDevice` callback returns an unexpected value? [Coverage, Exception Flow, Gap]

---

## Dependencies & Assumptions

- [ ] CHK029 - Is the assumption that `DashboardManagerState` and `DeviceManagerState` expose JNAP models validated? [Assumption, Spec §Assumptions]
- [ ] CHK030 - Are the utility function dependencies (`routerIconTestByModel`, `isHorizontalPorts`) validated as available? [Dependency, Contract §Dependencies]
- [ ] CHK031 - Is the `collection` package dependency for `groupFoldBy` documented in pubspec requirements? [Dependency, Gap]

---

## Summary

| Category | Item Count |
|----------|------------|
| Requirement Completeness | 5 |
| Breaking Changes Prevention | 6 |
| Requirement Clarity | 5 |
| Contract Consistency | 4 |
| Acceptance Criteria Quality | 4 |
| Scenario Coverage | 4 |
| Dependencies & Assumptions | 3 |
| **Total** | **31** |
