# Tasks: A2UI Dashboard Widget Extension

**Input**: Design documents from `/specs/017-a2ui-dashboard-widgets/`
**Status**: Phases 1-4 completed ✅, all 48 tests passed.

---

## Phase 1: Setup ✅

- [x] T001 Establish `lib/page/dashboard/a2ui/` directory structure.
- [x] T002 Create `_a2ui.dart` barrel export file.

---

## Phase 2: Core Models ✅

- [x] T003 [P] Create `a2ui/models/a2ui_constraints.dart`.
- [x] T004 [P] Create `a2ui/models/a2ui_template.dart`.
- [x] T005 Create `a2ui/models/a2ui_widget_definition.dart`.

---

## Phase 3: Registry & Resolver ✅

- [x] T006 Create `a2ui/registry/a2ui_widget_registry.dart`.
- [x] T007 Create `a2ui/resolver/data_path_resolver.dart`.
- [x] T008 Create `a2ui/resolver/jnap_data_resolver.dart`.
- [x] T009 Create `a2ui/renderer/template_builder.dart`.
- [x] T010 Create `a2ui/renderer/a2ui_widget_renderer.dart`.
- [x] T011 Create `a2ui/presets/preset_widgets.dart`.
- [x] T012 Modify `models/widget_spec.dart`.
- [x] T013 Modify `factories/dashboard_widget_factory.dart`.

---

## Phase 4: Unit Tests ✅

- [x] T014 [P] `test/page/dashboard/a2ui/models/a2ui_constraints_test.dart`.
- [x] T015 [P] `test/page/dashboard/a2ui/models/a2ui_template_test.dart`.
- [x] T016 [P] `test/page/dashboard/a2ui/models/a2ui_widget_definition_test.dart`.
- [x] T017 [P] `test/page/dashboard/a2ui/registry/a2ui_widget_registry_test.dart`.
- [x] T018 [P] `test/page/dashboard/a2ui/resolver/jnap_data_resolver_test.dart`.
- [x] T019 [P] `test/page/dashboard/a2ui/renderer/template_builder_test.dart`.

---

## Phase 5: Integration Tests (In Progress)

- [x] T020 Integration Test: Rendering A2UI Widgets in the Grid.
- [ ] T021 Integration Test: Drag-and-drop/scaling behavior.
- [ ] T022 Integration Test: Data binding updates.

---

## Phase 6: Data Binding Integration (TODO)

- [ ] T023 Connect `JnapDataResolver` to actual Providers.
- [ ] T024 Test real-time data updates.

---

## Notes

- Phases 1-4 completed on 2026-01-19.
- Analysis results: 0 errors, 1 warning (unused_field).
- Test results: 48 tests passed.
