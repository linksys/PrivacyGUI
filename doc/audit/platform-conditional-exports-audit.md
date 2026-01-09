# Platform Conditional Exports Audit Report

**Project**: PrivacyGUI  
**Date**: 2026-01-09  
**Updated**: 2026-01-09T20:01  
**Author**: Antigravity Agent

---

## Executive Summary

This audit analyzes the PrivacyGUI project to identify platform-specific code that requires Conditional Exports (Stub Pattern) for proper cross-platform (Web/Native) support.

### Key Findings

| Category | Count | Status |
|----------|-------|--------|
| ✅ **Fully Encapsulated (Entry Point Pattern)** | 9 groups | Compliant |
| ⚠️ **Uses `dart:io` I/O Operations (Needs Stub)** | 4 files | Needs Refactoring |
| ✅ **Uses `dart:io` Constants Only** | 10+ files | No Action Needed |
| 🔶 **Runtime Platform Check Dependencies** | 7+ files | Acceptable |

> [!IMPORTANT]
> **Correction (2026-01-09)**: Previously identified `HttpHeaders.*` and `HttpStatus.*` usage from `dart:io` as requiring refactoring. After verification, `flutter build web` succeeds without errors. Dart SDK provides stub implementations for `dart:io` constants on Web, so files using only constants (not actual I/O operations) do **not** require changes.

---

## Problem Statement

- **`dart:io`** is not fully available on Web, but the Dart SDK provides stubs for constants
- **`dart:html`** cannot be used in Native builds
- **Actual I/O operations** (File, Socket, InternetAddress) throw errors on Web

### When to Use Conditional Exports

| Usage | Needs Stub Pattern? |
|-------|---------------------|
| `HttpHeaders.authorizationHeader` (constant) | ❌ No - SDK provides stub |
| `HttpStatus.ok` (constant) | ❌ No - SDK provides stub |
| `File.writeAsBytes()` (I/O operation) | ✅ Yes |
| `InternetAddress.lookup()` (I/O operation) | ✅ Yes |
| `Platform.isIOS` (platform check) | ⚠️ Depends on usage |

---

## Part 1: Fully Encapsulated Implementations ✅

These modules have a proper entry point file that hides the conditional import logic.

### 1.1 gRPC Transport Factory (usp_client_core) ✅
**Location**: `packages/usp_client_core/lib/src/grpc_creator/`

| File | Purpose |
|------|---------|
| [grpc_creator.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/packages/usp_client_core/lib/src/grpc_creator/grpc_creator.dart) | **Entry Point** |
| [transport_factory_stub.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/packages/usp_client_core/lib/src/grpc_creator/transport_factory_stub.dart) | Stub |
| [transport_factory_io.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/packages/usp_client_core/lib/src/grpc_creator/transport_factory_io.dart) | Native |
| [transport_factory_web.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/packages/usp_client_core/lib/src/grpc_creator/transport_factory_web.dart) | Web |

### 1.2 HTTP Client Factory ✅
**Location**: `lib/core/http/`

| File | Purpose |
|------|---------|
| [linksys_http_client.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/http/linksys_http_client.dart) | **Entry Point** |
| [client/get_client.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/http/client/get_client.dart) | Stub |
| [client/mobile_client.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/http/client/mobile_client.dart) | Native |
| [client/web_client.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/http/client/web_client.dart) | Web |

### 1.3 Cache Manager Factory ✅
**Location**: `lib/core/cache/`

| File | Purpose |
|------|---------|
| [linksys_cache_manager.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cache/linksys_cache_manager.dart) | **Entry Point** |
| [cache_manager_base.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cache/cache_manager_base.dart) | Stub |
| [cache_manager_mobile.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cache/cache_manager_mobile.dart) | Native |
| [cache_manager_web.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cache/cache_manager_web.dart) | Web |

### 1.4 IP Getter ✅ `[NEW - 2026-01-09]`
**Location**: `lib/core/utils/ip_getter/`

| File | Purpose |
|------|---------|
| [ip_getter.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/ip_getter.dart) | **Entry Point** |
| [get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/get_local_ip.dart) | Stub |
| [mobile_get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/mobile_get_local_ip.dart) | Native |
| [web_get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/web_get_local_ip.dart) | Web |

### 1.5 URL Helper ✅ `[NEW - 2026-01-09]`
**Location**: `lib/util/url_helper/`

| File | Purpose |
|------|---------|
| [url_helper.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/url_helper/url_helper.dart) | **Entry Point** |
| [url_helper_stub.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/url_helper/url_helper_stub.dart) | Stub |
| [url_helper_mobile.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/url_helper/url_helper_mobile.dart) | Native |
| [url_helper_web.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/url_helper/url_helper_web.dart) | Web |

### 1.6 Export Selector ✅ `[NEW - 2026-01-09]`
**Location**: `lib/util/export_selector/`

| File | Purpose |
|------|---------|
| [export_selector.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/export_selector/export_selector.dart) | **Entry Point** |
| [export_base.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/export_selector/export_base.dart) | Stub |
| [export_mobile.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/export_selector/export_mobile.dart) | Native |
| [export_web.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/export_selector/export_web.dart) | Web |

### 1.7 Get Log Selector ✅ `[NEW - 2026-01-09]`
**Location**: `lib/util/get_log_selector/`

| File | Purpose |
|------|---------|
| [get_log_selector.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/get_log_selector/get_log_selector.dart) | **Entry Point** |
| [get_log_base.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/get_log_selector/get_log_base.dart) | Stub |
| [get_log_mobile.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/get_log_selector/get_log_mobile.dart) | Native |
| [get_log_web.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/util/get_log_selector/get_log_web.dart) | Web |

### 1.8 Client Type Constants ✅ `[NEW - 2026-01-09]`
**Location**: `lib/constants/client_type/`

| File | Purpose |
|------|---------|
| [client_type.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/constants/client_type/client_type.dart) | **Entry Point** |
| [get_client_type.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/constants/client_type/get_client_type.dart) | Stub |
| [mobile_client_type.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/constants/client_type/mobile_client_type.dart) | Native |
| [web_client_type.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/constants/client_type/web_client_type.dart) | Web |

### 1.9 Assign IP ✅ `[NEW - 2026-01-09]`
**Location**: `lib/core/utils/assign_ip/`

| File | Purpose |
|------|---------|
| [assign_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/assign_ip/assign_ip.dart) | **Entry Point** |
| [base_assign_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/assign_ip/base_assign_ip.dart) | Stub |
| [mobile_assign_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/assign_ip/mobile_assign_ip.dart) | Native (no-op) |
| [web_assign_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/assign_ip/web_assign_ip.dart) | Web |

---

## Part 2: Files Using `dart:io` I/O Operations (May Need Attention) ⚠️

These files use actual I/O operations from `dart:io` that may not work on Web:

| File | I/O Operations Used | Status |
|------|---------------------|--------|
| [logger.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/logger.dart) | `File.writeAsBytes()`, `stdout.supportsAnsiEscapes` | ⚠️ Guarded by `kIsWeb` |
| [storage.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/storage.dart) | `File`, `Directory` | ⚠️ Guarded by `kIsWeb` |
| [mixin.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/providers/connectivity/mixin.dart) | `InternetAddress.lookup()` | ⚠️ Guarded by `kIsWeb` |
| [main.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/main.dart) | `HttpOverrides.global` | ✅ Guarded by `!kIsWeb` |

> [!NOTE]
> These files are already protected by `kIsWeb` runtime checks, so they work correctly. Consider migrating to Stub Pattern for cleaner architecture if desired.

---

## Part 3: Files Using `dart:io` Constants Only ✅ NO ACTION NEEDED

These files import `dart:io` but only use **constants** (not I/O operations). The Dart SDK provides stub implementations for these constants on Web, so **no changes are required**.

| File | Constants Used |
|------|----------------|
| [authorization_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/authorization_service.dart) | `HttpHeaders.authorizationHeader`, `HttpHeaders.contentTypeHeader` |
| [device_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/device_service.dart) | `HttpHeaders.authorizationHeader` |
| [event_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/event_service.dart) | `HttpHeaders.authorizationHeader` |
| [user_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/user_service.dart) | `HttpHeaders.authorizationHeader` |
| [remote_assistance_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/remote_assistance_service.dart) | `HttpHeaders.authorizationHeader` |
| [asset_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/asset_service.dart) | `HttpHeaders.*` |
| [ping_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/ping_service.dart) | `HttpStatus.*` |
| [guardians_remote_assistance_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/guardians_remote_assistance_service.dart) | `HttpHeaders.*` |
| [linksys_cloud_repository.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_cloud_repository.dart) | `HttpStatus.ok`, `HttpStatus.noContent` |
| [router_repository.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/jnap/router_repository.dart) | `HttpHeaders.*`, `HttpStatus.*` |
| [base_http_command.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/jnap/command/http/base_http_command.dart) | `HttpStatus.*` |
| [linksys_http_client.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/http/linksys_http_client.dart) | `HttpHeaders.*`, `ContentType.*` |

---

## Part 4: Special Cases

### 4.1 smart_device_service.dart

| File | Issue |
|------|-------|
| [smart_device_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/cloud/linksys_requests/smart_device_service.dart) | Uses `Platform.isIOS` for `tokenType` |

This file uses `Platform.isIOS` to determine push notification token type ('APNS' vs 'GCM'). Since this is mobile-specific functionality (push notifications), it may not be used on Web at all. **No action needed** if this code path is not executed on Web.

### 4.2 Assign IP (Incomplete Pattern)
**Location**: `lib/core/utils/assign_ip/`

| File | Status |
|------|--------|
| [base_assign_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/assign_ip/base_assign_ip.dart) | ⚠️ Missing entry point |
| [web_assign_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/assign_ip/web_assign_ip.dart) | ⚠️ Missing native impl |

> [!WARNING]
> Missing `mobile_assign_ip.dart` and conditional export entry point. Low priority if not actively used.

---

## Part 5: Files Using `kIsWeb` Runtime Checks ✅

These files use runtime platform detection, which is an acceptable pattern for UI/behavior branching:

| File | Usage |
|------|-------|
| [build_config.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/constants/build_config.dart) | `!kIsWeb` for debug panel |
| [app.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/app.dart) | `kIsWeb` for page transitions |
| [router_repository.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/jnap/router_repository.dart) | `kIsWeb` for URL building |
| [connectivity_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/providers/connectivity/connectivity_provider.dart) | `!kIsWeb` for connectivity |
| [local_network_settings_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart) | `kIsWeb` for redirect |
| [internet_settings_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/internet_settings/views/internet_settings_view.dart) | `kIsWeb` for redirect |
| [dashboard_menu_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/dashboard/views/dashboard_menu_view.dart) | `kIsWeb` for menu options |

> [!TIP]
> Runtime `kIsWeb` checks are an acceptable pattern and do not require refactoring to Stub Pattern.

---

## Part 6: Verification Checklist

| Check | Status |
|-------|--------|
| `flutter build web` completes without errors | ✅ Verified |
| `flutter analyze` passes | ✅ Verified |
| Consumers only import entry point files | ✅ Phase 1 Complete |
| All new entry points have documentation | ✅ Complete |

---

## Appendix A: Change Log

### 2026-01-09T20:01 - Analysis Correction

**Correction**: Removed `HttpHeaders.*` and `HttpStatus.*` from "needs refactoring" list. After verifying `flutter build web` succeeds, confirmed that Dart SDK provides stub implementations for `dart:io` constants on Web. Only actual I/O operations require Stub Pattern.

### 2026-01-09T19:50 - Phase 1 Completed

**New Entry Point Files Created**:
- `lib/core/utils/ip_getter/ip_getter.dart`
- `lib/util/url_helper/url_helper.dart`
- `lib/util/url_helper/url_helper_stub.dart`
- `lib/util/export_selector/export_selector.dart`
- `lib/util/get_log_selector/get_log_selector.dart`
- `lib/constants/client_type/client_type.dart`
- `lib/core/utils/assign_ip/assign_ip.dart`
- `lib/core/utils/assign_ip/mobile_assign_ip.dart`

**Consumer Files Updated** (17 files):
- `lib/core/jnap/router_repository.dart`
- `lib/core/cloud/linksys_cloud_repository.dart`
- `lib/core/cloud/linksys_device_cloud_service.dart`
- `lib/route/router_provider.dart`
- `lib/page/instant_admin/providers/manual_firmware_update_provider.dart`
- `lib/constants/url_links.dart`
- `lib/page/health_check/widgets/speed_test_external_widget.dart`
- `lib/page/health_check/views/speed_test_external.dart`
- `lib/page/dashboard/views/components/widgets/parts/external_speed_test_links.dart`
- `lib/page/advanced_settings/internet_settings/widgets/wan_forms/bridge_form.dart`
- `lib/utils.dart`
- `lib/page/dashboard/views/components/widgets/parts/wifi_card.dart`
- `lib/constants/cloud_const.dart`
- `lib/page/dashboard/views/dashboard_home_view.dart`
- `lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart`
- `lib/page/advanced_settings/internet_settings/views/internet_settings_view.dart`

**Branch**: `austin/platform-conditional-exports-encapsulation`

---

## Appendix B: Files Excluded from Analysis

The following files import `dart:io` but are **test/tooling scripts** (not part of production build):

- `test_scripts/grep_loc_fils.dart`
- `test_scripts/test_result_parser.dart`
- `test_scripts/combine_results.dart`
- `test/common/theme_data.dart`
- `tools/generate_screenshot_test_cases_report.dart`
- `tools/delete_mockito_mocks.dart`
- `tools/remove_unused_strings.dart`
- `tools/run_screenshot_tests.dart`

---

*End of Audit Report*
