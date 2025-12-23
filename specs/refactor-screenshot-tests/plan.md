# Implementation Plan: Refactor Screenshot Tests to use TestHelper

**Branch**: `refactor/screenshot-tests` | **Date**: 2025-10-23 | **Spec**: [specs/refactor-screenshot-tests/spec.md](specs/refactor-screenshot-tests/spec.md)

## Summary

This plan outlines the process of refactoring all screenshot tests to use the `TestHelper` class. This will simplify the test setup, reduce boilerplate code, and improve the maintainability of the tests.

## Technical Context

**Language/Version**: Dart 3.0+ / Flutter 3.3.0+
**Primary Dependencies**: Flutter, Riverpod, go_router
**Storage**: N/A
**Testing**: flutter_test, integration_test
**Target Platform**: iOS, Android, Web
**Project Type**: Mobile/Web App
**Performance Goals**: N/A
**Constraints**: N/A
**Scale/Scope**: ~40 files, ~400 tests

## Constitution Check

- **User-Centric Design**: N/A
- **Solid Architecture**: This refactoring improves the test architecture.
- **Comprehensive Testing**: This task is all about improving the testing framework.
- **Code Quality and Style**: The refactoring will improve code quality and style.
- **Modularity and Reusability**: The `TestHelper` is a reusable component.

## Project Structure

### Files to be modified

- `test/page/instant_privacy/views/localizations/instant_privacy_view_test.dart`
- `test/page/health_check/views/localizations/speed_test_external_test.dart`
- `test/page/health_check/views/localizations/speed_test_view_test.dart`
- `test/page/instant_topology/localizations/instant_topology_view_test.dart`
- `test/page/instant_topology/localizations/add_wired_node_view_test.dart`
- `test/page/login/localizations/local_reset_router_password_view_test.dart`
- `test/page/login/localizations/login_local_view_test.dart`
- `test/page/login/localizations/local_router_recovery_view_test.dart`
- `test/page/instant_device/views/localizations/device_detail_view_test.dart`
- `test/page/instant_device/views/localizations/instant_device_view_test.dart`
- `test/page/wifi_settings/views/localizations/wifi_list_view_test.dart`
- `test/page/components/localizations/dialogs_test.dart`
- `test/page/components/localizations/top_bar_test.dart`
- `test/page/components/localizations/snack_bar_test.dart`
- `test/page/dashboard/localizations/dashboard_support_view_test.dart`
- `test/page/dashboard/localizations/dashboard_menu_view_test.dart`
- `test/page/instant_safety/views/localizations/instant_safety_view_test.dart`
- `test/page/vpn/views/localizations/vpn_settings_page_test.dart`
- `test/page/nodes/views/localizations/add_nodes_view_test.dart`
- `test/page/instant_admin/views/localizations/manual_firmware_update_view_test.dart`
- `test/page/instant_admin/views/localizations/instant_admin_view_test.dart`
- `test/page/firmware_update/views/localizations/firmware_update_detail_view_test.dart`
- `test/page/instant_verify/views/localizations/instant_verify_view_test.dart`
- `test/page/instant_setup/troubleshooter/views/isp_settings/localizations/pnp_pppoe_view_test.dart`
- `test/page/instant_setup/troubleshooter/views/isp_settings/localizations/pnp_static_ip_view_test.dart`
- `test/page/instant_setup/troubleshooter/views/isp_settings/localizations/pnp_isp_type_selection_view_test.dart`
- `test/page/instant_setup/troubleshooter/localizations/pnp_waiting_modem_view_test.dart`
- `test/page/instant_setup/troubleshooter/localizations/pnp_modem_lights_off_view_test.dart`
- `test/page/instant_setup/troubleshooter/localizations/pnp_no_internet_connection_view_test.dart`
- `test/page/instant_setup/troubleshooter/localizations/pnp_unplug_modem_view_test.dart`
- `test/page/instant_setup/localizations/pnp_admin_view_test.dart`
- `test/page/instant_setup/localizations/pnp_setup_view_test.dart`
- `test/page/advanced_settings/local_network_settings/views/localizations/dhcp_reservations_view_test.dart`
- `test/page/advanced_settings/local_network_settings/views/localizations/local_network_settings_view_test.dart`
- `test/page/advanced_settings/views/localizations/advanced_settings_view_test.dart`
- `test/page/dashboard/localizations/dashboard_home_view_test.dart`
- `test/page/nodes/localizations/node_detail_view_test.dart`
- `test/page/wifi_settings/views/localizations/wifi_main_view_test.dart`
- `test/page/advanced_settings/internet_settings/views/localizations/internet_settings_view_test.dart`
- `test/page/advanced_settings/dmz/views/localizations/dmz_settings_view_test.dart`
- `test/page/advanced_settings/administration/views/localizations/administration_settings_view_test.dart`
- `test/page/advanced_settings/firewall/views/localizations/firewall_view_test.dart`
- `test/page/advanced_settings/apps_and_gaming/views/localizations/apps_and_gaming_view_test.dart`
- `test/page/advanced_settings/static_routing/views/localizations/static_routing_view_test.dart`

## Complexity Tracking

N/A
