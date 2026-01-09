# Service Decoupling Audit Report

**Generated**: 2026-01-09  
**Project**: PrivacyGUI  
**Purpose**: Document JNAP coupling status for future USP/TR migration

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Service Files | 53 |
| Services with JNAP Dependency | 34 (64%) |
| RouterRepository References | 85 |
| Domain Models (JNAP) | 54 |
| Unique JNAP Actions Used | 110+ |
| **Architecture Violations** | **32** |

**Current Status**: 🔴 **High Coupling** — Most services directly depend on JNAP-specific types.

---

## ⚠️ Architecture Compliance Violations

The following sections document violations of the **Provider → Service → Repository** architecture pattern.

### RouterRepository Usage Outside Services (8 files)

These files directly access `routerRepositoryProvider` instead of going through a Service:

| File | Layer | Severity |
|------|-------|----------|
| `lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart` | View | 🔴 High |
| `lib/page/dashboard/views/prepare_dashboard_view.dart` | View | 🔴 High |
| `lib/page/ai_assistant/views/router_assistant_view.dart` | View | 🔴 High |
| `lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart` | View | 🔴 High |
| `lib/page/select_network/providers/select_network_provider.dart` | Provider | 🟡 Medium |
| `lib/page/vpn/providers/vpn_notifier.dart` | Provider | 🟡 Medium |
| `lib/page/wifi_settings/providers/channelfinder_provider.dart` | Provider | 🟡 Medium |
| `lib/page/instant_setup/troubleshooter/providers/_providers.dart` | Provider | 🟡 Medium |

### JNAPAction Usage Outside Services (3 files)

These files directly reference `JNAPAction` enum:

| File | Violation | Code Example |
|------|-----------|--------------|
| `select_network_provider.dart` | Direct JNAP call | `JNAPAction.isAdminPasswordDefault` |
| `prepare_dashboard_view.dart` | Direct JNAP call | `JNAPAction.getDeviceInfo` |
| `vpn_service.dart` | In service (acceptable) | - |

### JNAP Models Imported in Views/Providers (24 files)

Files that import `jnap/models/*` or `jnap/result/*` outside the Service layer:

**Views (14 files)**:
| File | Models Used |
|------|-------------|
| `dmz_settings_view.dart` | DMZ models |
| `internet_settings_view.dart` | WAN settings |
| `local_network_settings_view.dart` | LAN settings |
| `dashboard_home_view.dart` | Device info |
| `prepare_dashboard_view.dart` | Device info |
| `firmware_update_process_view.dart` | Firmware status |
| `instant_admin_view.dart` | Time settings |
| `node_detail_view.dart` | Node models |
| `instant_topology_view.dart` | Topology models |
| `instant_verify_view.dart` | Verify models |
| `login_local_view.dart` | Auth models |
| `pnp_*_view.dart` | ISP settings |

**Providers (10 files)**:
| File | Models Used |
|------|-------------|
| `node_light_settings_provider.dart` | LED settings |
| `channelfinder_provider.dart` | Radio info |
| `wifi_bundle_provider.dart` | WiFi settings |
| `select_network_provider.dart` | Network models |
| `wan_external_provider.dart` | WAN status |
| Others... | Various |

### Compliance Summary

| Violation Type | Count | Impact |
|----------------|-------|--------|
| **RouterRepository in Views** | 4 | 🔴 High - Direct protocol dependency |
| **RouterRepository in Providers** | 4 | 🟡 Medium - Should use Services |
| **JNAPAction in non-Services** | 2 | 🔴 High - Protocol leakage |
| **JNAP Models in Views** | 14 | 🟡 Medium - Model coupling |
| **JNAP Models in Providers** | 10 | 🟡 Medium - Model coupling |
| **Total Violations** | **34** | - |

### Recommended Fixes

1. **Views should NOT directly use RouterRepository**
   - Create/use appropriate Services for these operations
   - Pass data through Providers

2. **Providers should use Services, not RouterRepository**
   - `VpnNotifier` should use `VpnService`
   - `ChannelFinderProvider` should use `ChannelFinderService`

3. **Consider Domain Models separate from JNAP Models**
   - Create UI-specific models in `lib/page/**/models/`
   - Transform JNAP models to domain models in Services

---

## Service Inventory

### Core Services (`lib/core/data/services/`)

| Service | JNAP Coupled | Primary Functions |
|---------|--------------|-------------------|
| `polling_service.dart` | 🔴 Yes | Core data polling, transaction building |
| `dashboard_manager_service.dart` | 🔴 Yes | Dashboard state, device info |
| `device_manager_service.dart` | 🔴 Yes | Device CRUD, backhaul info |
| `firmware_update_service.dart` | 🔴 Yes | Firmware check/update |

### Feature Services (`lib/page/**/services/`)

| Category | Services | JNAP Coupled |
|----------|----------|--------------|
| **WiFi Settings** | `wifi_settings_service.dart`, `channel_finder_service.dart` | 🔴 Yes |
| **Network Settings** | `local_network_settings_service.dart`, `internet_settings_service.dart` | 🔴 Yes |
| **Security** | `firewall_settings_service.dart`, `dmz_settings_service.dart` | 🔴 Yes |
| **Instant Features** | `instant_privacy_service.dart`, `instant_safety_service.dart`, `instant_verify_service.dart`, `instant_topology_service.dart` | 🔴 Yes |
| **Administration** | `administration_settings_service.dart`, `router_password_service.dart`, `timezone_service.dart`, `power_table_service.dart` | 🔴 Yes |
| **Advanced Settings** | `static_routing_service.dart`, `ddns_service.dart`, port services | 🔴 Yes |
| **Nodes** | `node_detail_service.dart`, `add_nodes_service.dart`, `add_wired_nodes_service.dart`, `node_light_settings_service.dart` | 🔴 Yes |
| **Health Check** | `health_check_service.dart` | 🔴 Yes |
| **Setup** | `pnp_service.dart`, `pnp_isp_service.dart`, `auto_parent_first_login_service.dart` | 🔴 Yes |

### Non-JNAP Services (Cloud/Auth)

| Service | Purpose |
|---------|---------|
| `auth_service.dart` | Authentication (uses JNAP for local login) |
| `connectivity_service.dart` | Network connectivity check |
| Cloud services (`lib/core/cloud/`) | Linksys Cloud API (separate protocol) |

---

## JNAP Action Usage (Top 20)

| Action | Usage Count | Used By Services |
|--------|-------------|------------------|
| `getGuestRadioSettings` | 10 | wifi_settings, polling |
| `getLANSettings` | 9 | local_network_settings, internet_settings |
| `getWANStatus` | 8 | polling, dashboard, instant_verify |
| `getRadioInfo` | 8 | wifi_settings, polling, dashboard |
| `getDevices` | 8 | device_manager, polling |
| `getDeviceInfo` | 8 | dashboard, polling, side_effect |
| `getFirmwareUpdateSettings` | 6 | firmware_update, polling |
| `setFirmwareUpdateSettings` | 4 | firmware_update |
| `reboot` | 4 | administration, pnp |
| `getMACFilterSettings` | 4 | wifi_settings |
| `getInternetConnectionStatus` | 4 | polling, pnp |
| `getBackhaulInfo` | 4 | device_manager, polling |
| `factoryReset` | 4 | administration |

---

## Service Contracts Summary

### Core Read Operations

| Domain | Operation | JNAP Action | USP Equivalent (TBD) |
|--------|-----------|-------------|----------------------|
| Device | Get device info | `getDeviceInfo` | `Device.DeviceInfo.` |
| Device | Get device list | `getDevices` | `Device.Hosts.Host.` |
| Network | Get WAN status | `getWANStatus` | `Device.IP.Interface.` |
| WiFi | Get radio info | `getRadioInfo` | `Device.WiFi.Radio.` |
| WiFi | Get guest settings | `getGuestRadioSettings` | `Device.WiFi.SSID.` |
| System | Get system stats | `getSystemStats` | TBD |

### Core Write Operations

| Domain | Operation | JNAP Action | Side Effects |
|--------|-----------|-------------|--------------|
| Device | Set device name | `setDeviceProperties` | None |
| WiFi | Set radio settings | `setRadioSettings` | WiFi restart |
| System | Reboot | `reboot` | Device restart |
| System | Factory reset | `factoryReset` | Device restart |
| Firmware | Start update | `updateFirmwareNow` | Device restart |

---

## Migration Readiness

### Ready for Migration (After Protocol Defined)
- Services with clean separation between JNAP calls and business logic
- Services using `RouterRepository` through dependency injection

### Requires Refactoring
- Services with inline JNAP action handling
- Services with complex transaction building logic

### Special Considerations
- **Polling**: Batch transaction pattern may differ in USP
- **Side Effects**: Device restart handling needs protocol-agnostic abstraction
- **Real-time Updates**: USP supports WebSocket subscriptions

---

## Recommendations

### Short Term (Now)
1. ✅ Document all service contracts (this report)
2. Keep new services clean with single responsibility
3. Avoid spreading JNAP dependencies to Providers

### Medium Term (When USP Spec Available)
1. Review USP data model mapping
2. Identify common vs protocol-specific operations
3. Design protocol adapter interface based on actual needs

### Long Term (Migration)
1. Implement `UspAdapter` alongside `JnapAdapter`
2. Migrate services one by one with feature flags
3. Maintain parallel support during transition period

---

## Appendix: Service File Locations

### Core Services
```
lib/core/data/services/
├── polling_service.dart
├── dashboard_manager_service.dart
├── device_manager_service.dart
└── firmware_update_service.dart
```

### Feature Services
```
lib/page/
├── advanced_settings/
│   ├── administration/services/
│   ├── apps_and_gaming/ddns/services/
│   ├── apps_and_gaming/ports/services/
│   ├── dmz/services/
│   ├── firewall/services/
│   ├── internet_settings/services/
│   ├── local_network_settings/services/
│   └── static_routing/services/
├── health_check/services/
├── instant_admin/services/
├── instant_privacy/services/
├── instant_safety/services/
├── instant_setup/services/
├── instant_topology/services/
├── instant_verify/services/
├── login/auto_parent/services/
├── nodes/services/
└── wifi_settings/services/
```
