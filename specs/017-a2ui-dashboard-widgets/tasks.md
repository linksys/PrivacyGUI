# Tasks: A2UI Dashboard Widget Extension

**Input**: Design documents from `/specs/017-a2ui-dashboard-widgets/`
**Status**: Phase 1-4 完成 ✅，48 個測試全數通過

---

## Phase 1: Setup ✅

- [x] T001 建立 `lib/page/dashboard/a2ui/` 目錄結構
- [x] T002 建立 `_a2ui.dart` barrel export 檔案

---

## Phase 2: Core Models ✅

- [x] T003 [P] 建立 `a2ui/models/a2ui_constraints.dart`
- [x] T004 [P] 建立 `a2ui/models/a2ui_template.dart`
- [x] T005 建立 `a2ui/models/a2ui_widget_definition.dart`

---

## Phase 3: Registry & Resolver ✅

- [x] T006 建立 `a2ui/registry/a2ui_widget_registry.dart`
- [x] T007 建立 `a2ui/resolver/data_path_resolver.dart`
- [x] T008 建立 `a2ui/resolver/jnap_data_resolver.dart`
- [x] T009 建立 `a2ui/renderer/template_builder.dart`
- [x] T010 建立 `a2ui/renderer/a2ui_widget_renderer.dart`
- [x] T011 建立 `a2ui/presets/preset_widgets.dart`
- [x] T012 修改 `models/widget_spec.dart`
- [x] T013 修改 `factories/dashboard_widget_factory.dart`

---

## Phase 4: Unit Tests ✅

- [x] T014 [P] `test/page/dashboard/a2ui/models/a2ui_constraints_test.dart`
- [x] T015 [P] `test/page/dashboard/a2ui/models/a2ui_template_test.dart`
- [x] T016 [P] `test/page/dashboard/a2ui/models/a2ui_widget_definition_test.dart`
- [x] T017 [P] `test/page/dashboard/a2ui/registry/a2ui_widget_registry_test.dart`
- [x] T018 [P] `test/page/dashboard/a2ui/resolver/jnap_data_resolver_test.dart`
- [x] T019 [P] `test/page/dashboard/a2ui/renderer/template_builder_test.dart`

---

## Phase 5: Integration Tests (In Progress)

- [x] T020 整合測試：A2UI Widget 在 Grid 中渲染
- [ ] T021 整合測試：拖拉/縮放行為
- [ ] T022 整合測試：資料綁定更新

---

## Phase 6: Data Binding Integration (TODO)

- [ ] T023 連接 `JnapDataResolver` 至實際 Provider
- [ ] T024 測試資料即時更新

---

## Notes

- Phase 1-4 已於 2026-01-19 完成
- 分析結果：0 errors, 1 warning (unused_field)
- 測試結果：48 tests passed
