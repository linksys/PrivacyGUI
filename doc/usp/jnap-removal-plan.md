# JNAP Removal & Page Reorganization Plan

> **Created**: 2026-03-19
> **Status**: Draft — Pending execution
> **Branch**: `dev-2.2.1`

## Objective

Remove all JNAP protocol code and legacy pages from the codebase, reorganize `lib/usp_page/` into `lib/page/` as the primary page structure, making USP the sole protocol.

---

## Scope Summary

| Metric | Count |
|--------|-------|
| Files to remove (old pages) | ~485 |
| Files to remove (JNAP core) | ~76 |
| Files to move (usp_page → page) | ~176 |
| Import paths to update | ~695 |
| JNAP imports to clean across codebase | ~383 |

---

## Phase 1 — Remove Legacy `lib/page/` (JNAP Pages)

### Action
Delete old JNAP-dependent page directories from `lib/page/`.

### Directories to DELETE (18 directories, ~485 files)

**Already replaced by USP equivalents:**

| Old Page | Files | USP Replacement |
|----------|-------|-----------------|
| `advanced_settings/` | 136 | `usp_page/` internet_settings, firewall, dmz, port_forwarding, ipv6_port_service, static_routing, local_network |
| `dashboard/` | 91 | `usp_page/dashboard/` |
| `wifi_settings/` | 36 | `usp_page/wifi_settings/` |
| `instant_privacy/` | 5 | `usp_page/instant_privacy/` |
| `instant_safety/` | 6 | `usp_page/instant_safety/` |
| `instant_device/` | 16 | `usp_page/devices/` |
| `instant_topology/` | 14 | `usp_page/topology/` |
| `instant_verify/` | 11 | `usp_page/network_diagnostics/` |
| `instant_admin/` | 18 | `usp_page/admin/` |
| `nodes/` | 24 | `usp_page/topology/` |
| `health_check/` | 17 | `usp_page/network_diagnostics/` |
| `firmware_update/` | 6 | `usp_page/admin/` |
| `components/` | 39 | `usp_page/_shared/` |

**Removed without USP equivalent (rebuild later if needed):**

| Old Page | Files | Reason |
|----------|-------|--------|
| `instant_setup/` | 29 | PnP setup wizard — rebuild on USP when needed |
| `vpn/` | 8 | VPN settings — rebuild on USP when needed |
| `select_network/` | 8 | Cloud multi-network selection — rebuild when needed |

### Directories to KEEP in `lib/page/`

| Directory | Files | Reason |
|-----------|-------|--------|
| `landing/` | 3 | No JNAP dependency, infrastructure page |
| `models/` | 1 | Shared `AppSectionItemData`, no JNAP dependency |
| `support/` | 9 | No JNAP dependency, may merge with `usp_page/support/` |
| `usp_test/` | 1 | Dev-only test page, no JNAP dependency |

---

## Phase 2 — Reorganize `lib/usp_page/` → `lib/page/`

### Action
Move all USP page directories into `lib/page/`, making them the primary pages.

### Directories to MOVE (25 directories)

```
lib/usp_page/_framework/       → lib/page/_framework/
lib/usp_page/_shared/          → lib/page/_shared/
lib/usp_page/admin/            → lib/page/admin/
lib/usp_page/advanced_settings/→ lib/page/advanced_settings/
lib/usp_page/dashboard/        → lib/page/dashboard/
lib/usp_page/devices/          → lib/page/devices/
lib/usp_page/dhcp/             → lib/page/dhcp/
lib/usp_page/dmz/              → lib/page/dmz/
lib/usp_page/firewall/         → lib/page/firewall/
lib/usp_page/instant_privacy/  → lib/page/instant_privacy/
lib/usp_page/instant_safety/   → lib/page/instant_safety/
lib/usp_page/internet_settings/→ lib/page/internet_settings/
lib/usp_page/ipv6_port_service/→ lib/page/ipv6_port_service/
lib/usp_page/local_network/    → lib/page/local_network/
lib/usp_page/menu/             → lib/page/menu/
lib/usp_page/network_diagnostics/ → lib/page/network_diagnostics/
lib/usp_page/port_forwarding/  → lib/page/port_forwarding/
lib/usp_page/shell/            → lib/page/shell/
lib/usp_page/static_routing/   → lib/page/static_routing/
lib/usp_page/statistics/       → lib/page/statistics/
lib/usp_page/support/          → lib/page/support/  (merge with existing if needed)
lib/usp_page/system_log/       → lib/page/system_log/
lib/usp_page/test_console/     → lib/page/test_console/
lib/usp_page/topology/         → lib/page/topology/
lib/usp_page/wifi_settings/    → lib/page/wifi_settings/
```

### Import Path Updates

- **Pattern**: `package:privacy_gui/usp_page/` → `package:privacy_gui/page/`
- **Scope**: ~695 occurrences across ~176 files
- **External file**: `lib/route/router_provider.dart` (only external import point)
- **Test files**: `test/usp_page/` → `test/page/` (move + update imports)

### Naming Convention

- File names with `usp_` prefix: **KEEP** (e.g., `usp_dashboard_view.dart`)
- Class names with `Usp` prefix: **KEEP** (e.g., `UspFirewallNotifier`)
- Can be gradually renamed in future iterations

---

## Phase 3 — Special Page Handling

### 3a. Login Page — Copy & Rewrite

**Source**: `lib/page/login/` (10 files)
**Target**: `lib/page/login/`

| File | Action |
|------|--------|
| `views/login_local_view.dart` | Copy, remove `JNAPError` import, remove `isUspOnlyMode` branch (always go to USP dashboard) |
| `views/login_cloud_view.dart` | Copy as-is |
| `views/login_cloud_auth_view.dart` | Copy as-is |
| `views/local_reset_router_password_view.dart` | Copy as-is |
| `views/local_router_recovery_view.dart` | Copy as-is |
| `views/_views.dart` | Copy as-is |
| `auto_parent/views/auto_parent_first_login_view.dart` | Copy as-is (UI only) |
| `auto_parent/providers/auto_parent_first_login_provider.dart` | Copy, rewire to USP service |
| `auto_parent/providers/auto_parent_first_login_state.dart` | Copy as-is |
| `auto_parent/services/auto_parent_first_login_service.dart` | **REWRITE** — replace 3 JNAP actions with USP codegen equivalents |

**JNAP Actions to replace in `auto_parent_first_login_service.dart`:**

| JNAP Action | USP Equivalent | Notes |
|-------------|---------------|-------|
| `setUserAcknowledgedAutoConfiguration` | TBD | May need new YAML definition |
| `getFirmwareUpdateSettings` / `setFirmwareUpdateSettings` | `FirmwareImages` codegen | Check `firmware_images.g.dart` |
| `getInternetConnectionStatus` | `WanStatus` codegen | Use `wan_status.g.dart` |

### 3b. AI Assistant — Keep Framework, Remove JNAP

**Source**: `lib/page/ai_assistant/` (2 files)
**Target**: `lib/page/ai_assistant/`

| File | Action |
|------|--------|
| `views/router_assistant_view.dart` | Keep as-is (no JNAP imports) |
| `providers/router_command_provider.dart` | Replace `JnapCommandProvider` with USP-based `IRouterCommandProvider` implementation |

**Dependencies in `lib/ai/`:**

| File | Action |
|------|--------|
| `lib/ai/abstraction/i_router_command_provider.dart` | Keep (abstract interface, no JNAP) |
| `lib/ai/providers/jnap_command_provider.dart` | Remove or replace with USP implementation |

---

## Phase 4 — Remove JNAP Core

### 4a. Delete `lib/core/jnap/` (76 files)

```
lib/core/jnap/
├── actions/           (6 files) — JNAPAction, JNAPService enums
├── command/           (6 files) — HTTP + Bluetooth command implementations
├── extensions/        (2 files) — Batch extensions
├── models/            (55 files) — All JNAP data models
├── providers/         (1 file)  — Polling provider
├── result/            (1 file)  — JNAPResult types
├── spec/              (2 files) — Command specs
├── jnap_command_executor_mixin.dart
├── jnap_command_queue.dart
└── router_repository.dart       — 46 files depend on this (most critical cut point)
```

### 4b. Clean JNAP Providers & Services

| Path | Files | Action |
|------|-------|--------|
| `lib/core/data/providers/device_info_provider.dart` | 1 | Remove |
| `lib/core/data/providers/device_manager_state.dart` | 1 | Remove |
| `lib/core/data/providers/device_manager_provider.dart` | 1 | Remove |
| `lib/core/data/providers/ethernet_ports_provider.dart` | 1 | Remove |
| `lib/core/data/providers/firmware_update_provider.dart` | 1 | Remove |
| `lib/core/data/providers/firmware_update_state.dart` | 1 | Remove |
| `lib/core/data/providers/node_internet_status_provider.dart` | 1 | Remove |
| `lib/core/data/providers/polling_helpers.dart` | 1 | Remove |
| `lib/core/data/providers/polling_provider.dart` | 1 | Remove |
| `lib/core/data/providers/router_time_provider.dart` | 1 | Remove |
| `lib/core/data/providers/side_effect_provider.dart` | 1 | Remove |
| `lib/core/data/providers/system_stats_provider.dart` | 1 | Remove |
| `lib/core/data/providers/wifi_radios_provider.dart` | 1 | Remove |
| `lib/core/data/services/device_manager_service.dart` | 1 | Remove |
| `lib/core/data/services/firmware_update_service.dart` | 1 | Remove |
| `lib/core/data/services/polling_service.dart` | 1 | Remove |
| `lib/core/data/services/session_service.dart` | 1 | Remove |

### 4c. Refactor Auth Provider

**File**: `lib/providers/auth/auth_provider.dart`

| Change | Detail |
|--------|--------|
| Remove JNAP 401 fallback | Lines 58-62: Remove `isUspOnlyMode` conditional |
| Remove JNAP login sync | Lines 286-287: Remove post-JNAP USP sync |
| Remove JNAP failure fallback | Line 325: Remove USP fallback on JNAP error |
| Keep USP auth | Lines 113, 425: USP session restore + SSE disconnect |

### 4d. Clean Related Files

| File | Action |
|------|--------|
| `lib/core/errors/jnap_error_mapper.dart` | Remove |
| `lib/constants/jnap_const.dart` | Remove |
| `lib/core/protocol/protocol_resolver.dart` | Simplify (remove JNAP mode) |
| `constants/build_config.dart` | Remove `jnapOnly`/`jnapPreferred` from `protocolPreference` |

---

## Phase 5 — Route & Test Cleanup

### 5a. Route Files

| File | Action |
|------|--------|
| `lib/route/route_usp_dashboard.dart` | Rename → `route_dashboard.dart` |
| `lib/route/route_pnp.dart` | Remove |
| `lib/route/route_local_login.dart` | Review — update to USP-only login flow |
| `lib/route/route_cloud_login.dart` | Review — update if needed |
| `lib/route/route_dashboard.dart` (old) | Remove (replaced by renamed USP route) |
| `lib/route/route_menu.dart` (old) | Remove if JNAP-only |
| `lib/route/route_advanced_settings.dart` | Remove |
| `lib/route/constants.dart` | Clean up old JNAP route constants |

### 5b. Test Cleanup

| Path | Action |
|------|--------|
| `test/mocks/jnap_service_supported_mocks.dart` | Remove |
| `test/mocks/mockito_specs/jnap_service_supported_spec.dart` | Remove |
| `test/mocks/mockito_specs/jnap_service_supported_spec.mocks.dart` | Remove |
| `test/page/dashboard/a2ui/resolver/jnap_data_resolver_*.dart` | Remove |
| `test/core/jnap/result/jnap_result_test.dart` | Remove |
| `test/usp_page/` | Move → `test/page/`, update imports |

---

## Execution Order

```
Phase 1  ──→  Phase 2  ──→  Phase 3  ──→  Phase 4  ──→  Phase 5
Remove        Move           Login +       Remove        Routes +
old pages     usp_page→page  AI assistant  JNAP core     Tests
```

Each phase should be a **separate commit** for easy rollback.

---

## Risk & Mitigation

| Risk | Mitigation |
|------|-----------|
| Missed JNAP imports cause compile errors | Run `flutter analyze` after each phase |
| Login service rewrite incomplete | Stub USP calls initially, fill in when codegen definitions confirmed |
| `landing/` or `models/` have hidden JNAP deps | Already confirmed zero JNAP imports |
| Shared `components/` used by USP pages | Check before deletion; migrate useful widgets to `_shared/` |
| Auth provider breaks after JNAP removal | Test login flow end-to-end after Phase 4 |

---

## Post-Completion Checklist

- [ ] `flutter analyze` passes with zero errors
- [ ] `flutter test --tags ui` passes
- [ ] `./run_tests.sh` passes
- [ ] Login flow works (local + cloud)
- [ ] All USP pages accessible from dashboard
- [ ] No remaining `import.*jnap` in codebase (except comments/docs)
- [ ] No remaining `import.*usp_page/` in codebase
- [ ] AI assistant page loads (framework only, commands stubbed)
