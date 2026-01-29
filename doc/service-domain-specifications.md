# PrivacyGUI Service Domain Specifications

**Document Version**: 1.0  
**Last Verified**: 2026-01-19  
**Total Specifications**: 19  
**Functional Requirements**: 155+ FR

---

## Executive Summary

This document consolidates all PrivacyGUI Service Layer refactoring specifications and cross-references with Audit documents for compliance verification.

### Compliance Verification Results

| Audit Document | Verification Item | Spec Coverage | Status |
|----------------|-------------------|---------------|--------|
| [architecture-analysis.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/audit/architecture-analysis.md) | 4-Layer Architecture | 19/19 specs | ✅ Compliant |
| [architecture-violations-detail.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/audit/architecture-violations-detail.md) | 14 Violations Fixed | All resolved by specs | ✅ Compliant |
| [service-decoupling-audit.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/audit/service-decoupling-audit.md) | Service Layer Establishment | 53 Service files | ✅ Compliant |

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Dashboard & System Management](#2-dashboard--system-management)
3. [Node Management](#3-node-management)
4. [Network Settings](#4-network-settings)
5. [Instant Features](#5-instant-features)
6. [Core Services](#6-core-services)
7. [Test Refactoring](#7-test-refactoring)

---

## 1. Authentication

### 1.1 001-auth-service-extraction

**Created**: 2025-12-10  
**Service File**: [auth_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/providers/auth/auth_service.dart)  
**Test File**: `test/providers/auth/auth_service_test.dart`  
**Full Spec**: [spec.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/specs/005-auth-service-extraction/spec.md)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | AuthService MUST extract all session token validation logic from AuthNotifier | ✅ |
| FR-002 | AuthService MUST extract all authentication flow orchestration (cloud/local/RA login) | ✅ |
| FR-003 | AuthService MUST extract all credential persistence operations | ✅ |
| FR-004 | AuthService MUST be stateless - no internal state management | ✅ |
| FR-005 | AuthService MUST accept all dependencies via constructor injection | ✅ |
| FR-006 | AuthService MUST use Result<T, AuthError> for error handling | ✅ |
| FR-007 | AuthService MUST handle session token refresh automatically | ✅ |
| FR-008 | AuthService MUST implement logout clearing all secure storage | ✅ |
| FR-009 | AuthNotifier MUST delegate all business logic to AuthService | ✅ |
| FR-010 | AuthNotifier MUST use Riverpod AsyncNotifier pattern | ✅ |
| FR-011 | AuthNotifier MUST transform results to AsyncValue states | ✅ |
| FR-012 | All existing auth flows MUST work identically (backward compatible) | ✅ |
| FR-013 | Unit tests MUST cover all business logic paths | ✅ |
| FR-014 | Existing tests MUST continue to pass | ✅ |
| FR-015 | authServiceProvider MUST be defined for DI | ✅ |
| FR-016 | AuthState tests MUST achieve ≥90% coverage | ✅ |

#### Audit Cross-Reference

> **architecture-violations-detail.md**:
> - ✅ Resolved `pnp_no_internet_connection_view.dart` direct `isLoggedIn()` usage violation
> - ✅ Resolved Provider layer direct RouterRepository call violations

---

### 1.2 001-auto-parent-login-service

**Created**: 2026-01-07  
**Service File**: [auto_parent_first_login_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/login/auto_parent/services/auto_parent_first_login_service.dart)  
**Test File**: `test/page/login/auto_parent/services/auto_parent_first_login_service_test.dart`

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Create AutoParentFirstLoginService in services/ directory | ✅ |
| FR-002 | Implement setUserAcknowledgedAutoConfiguration() | ✅ |
| FR-003 | Implement setFirmwareUpdatePolicy() | ✅ |
| FR-004 | Implement checkInternetConnection() | ✅ |
| FR-005 | Convert JNAPError to ServiceError subtypes | ✅ |
| FR-006 | Refactor AutoParentFirstLoginNotifier to delegate | ✅ |
| FR-007 | Create autoParentFirstLoginServiceProvider | ✅ |
| FR-008 | Maintain existing behavior | ✅ |

---

## 2. Dashboard & System Management

### 2.1 005-dashboard-service-extraction

**Created**: 2025-12-29  
**Service File**: [device_manager_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/data/services/device_manager_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Create DashboardManagerService class | ✅ |
| FR-002 | Implement transformPollingData() method | ✅ |
| FR-003 | Implement checkRouterIsBack() method | ✅ |
| FR-004 | Implement checkDeviceInfo() method | ✅ |
| FR-005 | Handle specified JNAP actions | ✅ |

---

### 2.2 006-dashboard-home-service-extraction

**Created**: 2025-12-29  
**Service File**: [dashboard_home_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/dashboard/services/dashboard_home_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Create DashboardHomeService in lib/page/dashboard/services/ | ✅ |
| FR-002 | Contain all data transformation from DashboardHomeNotifier.createState() | ✅ |
| FR-003 | Handle WiFi list building from main radios | ✅ |
| FR-004 | Handle WiFi list building from guest radios | ✅ |
| FR-005 | Determine node offline status, WAN type, port layout | ✅ |

---

### 2.3 001-administration-service-refactor

**Created**: 2024-12-03  
**Service File**: [administration_settings_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/administration/services/administration_settings_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Orchestrate 4 JNAP actions in single transaction | ✅ |
| FR-002 | Parse JNAP responses to domain models | ✅ |
| FR-003 | Accept optional caching parameters | ✅ |
| FR-004 | Return parsed data or clear error context | ✅ |
| FR-005 | Notifier MUST delegate to Service | ✅ |
| FR-006 | Notifier MUST use PreservableNotifierMixin | ✅ |
| FR-007 | JNAP imports MUST move to service layer | ✅ |
| FR-008 | Model instantiation MUST be centralized in service | ✅ |

---

## 3. Node Management

### 3.1 001-add-nodes-service

**Created**: 2026-01-06  
**Service Files**: [add_nodes_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/nodes/services/add_nodes_service.dart), [add_wired_nodes_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/nodes/services/add_wired_nodes_service.dart)

#### Functional Requirements - AddNodesService

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Create AddNodesService class | ✅ |
| FR-002 | Accept RouterRepository via constructor | ✅ |
| FR-003 | Implement startOnboarding() method | ✅ |
| FR-004 | Implement checkTimeout() method | ✅ |
| FR-005 | Implement setOnBoard() method | ✅ |
| FR-006 | Implement completeOnboarding() method | ✅ |
| FR-007 | Implement pollForNodesOnline() returning Stream | ✅ |
| FR-008 | Implement pollNodesBackhaulInfo() returning Stream | ✅ |
| FR-009 | Convert JNAPError to ServiceError | ✅ |
| FR-010-014 | Notifier delegation and isolation | ✅ |

#### Functional Requirements - AddWiredNodesService

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-015-028 | Full wired nodes service implementation | ✅ |

#### Audit Cross-Reference

> **architecture-violations-detail.md**:
> - ✅ Resolved `add_nodes_provider.dart` direct `BackHaulInfoData` reference violation

---

### 3.2 001-node-detail-service

**Created**: 2026-01-02  
**Service File**: [node_detail_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/nodes/services/node_detail_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001-010 | Complete node detail service with JNAP isolation | ✅ |

---

### 3.3 002-node-light-settings-service

**Created**: 2026-01-02  
**Service File**: [node_light_settings_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/nodes/services/node_light_settings_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Stateless NodeLightSettingsService class | ✅ |
| FR-002 | Implement fetchSettings() method | ✅ |
| FR-003 | Implement saveSettings() method | ✅ |
| FR-004 | Map JNAPError to ServiceError | ✅ |
| FR-005 | Notifier MUST delegate to Service | ✅ |

---

## 4. Network Settings

### 4.1 002-dmz-refactor ⭐ (Best Practice)

**Created**: 2025-12-08  
**Service File**: [dmz_settings_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/dmz/services/dmz_settings_service.dart)  
**Architecture Decision**: [ARCHITECTURE_DECISION.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/specs/003-dmz-refactor/ARCHITECTURE_DECISION.md)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Extract all JNAP logic from Provider to Service | ✅ |
| FR-002 | Implement fetchDmzSettings() parsing to DmzSettings | ✅ |
| FR-003 | Implement error handling with action-specific messages | ✅ |
| FR-004 | Implement saveDmzSettings() method | ✅ |
| FR-005 | Provider MUST delegate without JNAP imports | ✅ |
| FR-006 | Provider MUST manage state correctly | ✅ |
| FR-007 | State layer with Equatable, serialization | ✅ |
| FR-008 | Tests MUST use TestData builder pattern | ✅ |
| FR-009 | Tests MUST pass with 0 lint warnings | ✅ |
| FR-010 | Maintain backward compatibility | ✅ |

#### Audit Cross-Reference

> **architecture-analysis.md**:
> - ✅ DMZ module rated ⭐⭐⭐⭐⭐ (5/5) in "Decoupling Assessment Matrix"
> - ✅ Listed as "Best Practice Example"

---

### 4.2 003-firewall-refactor

**Created**: 2025-12-09  
**Service File**: [firewall_settings_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/firewall/services/firewall_settings_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Extract JNAP logic to FirewallSettingsService | ✅ |
| FR-002 | Create UI-specific models (FirewallUISettings) | ✅ |
| FR-003 | Provider depends only on Service | ✅ |
| FR-004 | Provider uses only UI models | ✅ |
| FR-005 | Views NEVER import jnap/models | ✅ |

---

### 4.3 004-static-routing-refactor

**Created**: 2025-12-12  
**Service File**: [static_routing_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/static_routing/services/static_routing_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Three-layer architecture separation | ✅ |
| FR-002 | Dedicated StaticRoutingService | ✅ |
| FR-003 | UI models isolate Presentation from JNAP | ✅ |
| FR-004 | Providers depend only on Service | ✅ |
| FR-005 | Views depend only on Providers and UI models | ✅ |

---

## 5. Instant Features

### 5.1 003-instant-admin-service

**Created**: 2025-12-22  
**Service Files**: [timezone_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_admin/services/timezone_service.dart), [power_table_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_admin/services/power_table_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Create TimezoneService for timezone JNAP | ✅ |
| FR-002 | Create PowerTableService for power table JNAP | ✅ |
| FR-003 | Accept RouterRepository via constructor | ✅ |
| FR-004 | Transform JNAP to application-layer models | ✅ |
| FR-005 | Convert JNAPError to ServiceError per Article XIII | ✅ |

#### Audit Cross-Reference

> **architecture-violations-detail.md**:
> - ✅ Resolved `instant_admin_view.dart` direct JNAP Models import violation

---

### 5.2 001-instant-privacy-service

**Created**: 2026-01-02  
**Service File**: [instant_privacy_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_privacy/services/instant_privacy_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001-010 | Complete instant privacy service implementation | ✅ |

---

### 5.3 004-instant-safety-service

**Created**: 2025-12-22  
**Service File**: [instant_safety_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_safety/services/instant_safety_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Create InstantSafetyService class | ✅ |
| FR-002 | Handle getLANSettings JNAP action | ✅ |
| FR-003 | Handle setLANSettings JNAP action | ✅ |
| FR-004 | Convert JNAPError to ServiceError | ✅ |
| FR-005 | Determine safe browsing type by DNS values | ✅ |

---

### 5.4 001-instant-topology-service

**Created**: 2026-01-02  
**Service File**: [instant_topology_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_topology/services/instant_topology_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001-010 | Complete topology service implementation | ✅ |

---

## 6. Core Services

### 6.1 001-device-manager-service-extraction

**Created**: 2025-12-28  
**Service File**: [device_manager_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/data/services/device_manager_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001-010 | Complete device manager service extraction | ✅ |

---

### 6.2 001-connectivity-service

**Created**: 2026-01-02  
**Service File**: [connectivity_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/providers/connectivity/services/connectivity_service.dart)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Create ConnectivityService class | ✅ |
| FR-002 | Implement testRouterType() returning RouterType | ✅ |
| FR-003 | Implement fetchRouterConfiguredData() | ✅ |
| FR-004 | Handle JNAP via RouterRepository | ✅ |
| FR-005 | Convert JNAP models internally | ✅ |
| FR-006 | Map JNAP errors to ServiceError | ✅ |
| FR-007 | Notifier delegates to Service | ✅ |
| FR-008 | Notifier has no JNAP imports | ✅ |
| FR-009 | Backward compatibility maintained | ✅ |
| FR-010 | Unit tests with mocked RouterRepository | ✅ |

---

### 6.3 002-router-password-service ⭐ (Reference Implementation)

**Created**: 2025-12-15  
**Service File**: [router_password_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_admin/services/router_password_service.dart)  
**Contract Document**: [router_password_service_contract.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/specs/007-router-password-service/contracts/router_password_service_contract.md)

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | Maintain all existing functionality | ✅ |
| FR-002 | Define routerPasswordServiceProvider | ✅ |
| FR-003 | Stateless with constructor injection | ✅ |
| FR-004 | Handle all password JNAP operations | ✅ |
| FR-005 | Handle password persistence via SecureStorage | ✅ |

---

## 7. Test Refactoring

### 7.1 refactor-screenshot-tests

**Created**: 2025-10-23  
**Implementation**: `test/common/unit_test_helper.dart`

#### Functional Requirements

| ID | Requirement | Verified |
|----|-------------|----------|
| FR-001 | All screenshot tests MUST use TestHelper | ✅ |
| FR-002 | Refactoring MUST NOT change test behavior | ✅ |
| FR-003 | TestHelper MUST instantiate mock notifiers | ✅ |
| FR-004 | Use pumpView() or pumpShellView() | ✅ |
| FR-005 | Remove manual mock creation boilerplate | ✅ |

---

## Summary Statistics

### Specification Coverage

| Category | Specs | FR Count | Verification |
|----------|-------|----------|--------------|
| Authentication | 2 | 24 | ✅ 100% |
| Dashboard | 3 | 18 | ✅ 100% |
| Node Management | 3 | 43 | ✅ 100% |
| Network Settings | 3 | 15 | ✅ 100% |
| Instant Features | 4 | 25 | ✅ 100% |
| Core Services | 3 | 25 | ✅ 100% |
| Test Refactoring | 1 | 5 | ✅ 100% |
| **Total** | **19** | **155** | **✅ 100%** |

### Audit Compliance

| Audit Document | Original Issues | Resolved by Specs | Status |
|----------------|-----------------|-------------------|--------|
| architecture-violations-detail.md | RouterRepository in Views (4) | ✅ All fixed | ✅ |
| architecture-violations-detail.md | RouterRepository in Providers (4) | ✅ All fixed | ✅ |
| architecture-violations-detail.md | JNAPAction in non-Services (2) | ✅ All fixed | ✅ |
| architecture-violations-detail.md | JNAP Models in Views (4) | ✅ All fixed | ✅ |
| service-decoupling-audit.md | High JNAP coupling | 53 Service files created | ✅ |

---

## Related Documents

| Document | Description |
|----------|-------------|
| [Constitution](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/constitution.md) | Architecture Constitution - Development Standards |
| [architecture-analysis.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/audit/architecture-analysis.md) | Complete Project Architecture Analysis |
| [architecture-violations-detail.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/audit/architecture-violations-detail.md) | Violation Fix History |
| [service-decoupling-audit.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/audit/service-decoupling-audit.md) | Service Decoupling Audit |
| [specs/README.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/specs/README.md) | Specs Index with Implementation Links |
