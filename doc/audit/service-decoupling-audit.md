# Service Decoupling Audit Report

**Generated**: 2026-01-09  
**Last Updated**: 2026-01-19  
**Project**: PrivacyGUI  
**Purpose**: Document JNAP coupling status for future USP/TR-369 migration

---

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| Total Service Files | 53 | - |
| Services with JNAP Dependency | 34 (64%) | 🟡 Expected |
| RouterRepository References | 85 | - |
| Domain Models (JNAP) | 54 | - |
| Unique JNAP Actions Used | 110+ | - |
| **Architecture Violations** | ~~32~~ → **0** | ✅ Fixed |

**Current Status**: 🟡 **Service Layer Coupled to JNAP** — This is expected and acceptable. Architecture violations have been resolved.

> [!NOTE]
> **2026-01-19 Update**: All architecture violations (Views/Providers directly using RouterRepository) have been fixed.  
> See [architecture-violations-detail.md](architecture-violations-detail.md) for details.

---
## ✅ Architecture Compliance Violations (Fixed)

> [!TIP]
> All violations in this section were fixed on 2026-01-19. For detailed history, please refer to [architecture-violations-detail.md](architecture-violations-detail.md).

### Fix Summary

| Violation Type | Original Count | Status |
|----------------|----------------|--------|
| RouterRepository in Views | 4 | ✅ Fixed |
| RouterRepository in Providers | 4 | ✅ Fixed |
| JNAPAction in non-Services | 2 | ✅ Fixed |
| JNAP Models in Views | 4 | ✅ Fixed |
| **Total** | **14** | **✅ All Fixed** |

---

## Service Inventory

### Core Services (`lib/core/data/services/`)

| Service | JNAP Coupled | Primary Functions |
|---------|--------------|-------------------|
| `DeviceManagerService` | ✅ Yes | Device CRUD, Backhaul info |
| `SessionService` | ✅ Yes | Session token management |
| `CloudDeviceService` | ❌ No | Cloud connectivity only |

### Feature Services (`lib/page/*/services/`)

| Service | JNAP Coupled | Notes |
|---------|--------------|-------|
| `AuthService` | ✅ Yes | Handles Login/Auth (refactored) |
| `DashboardHomeService` | ⚠️ Yes | Aggregates multiple JNAP calls |
| `NodeDetailService` | ✅ Yes | Node config management |
| `DmzSettingsService` | ✅ Yes | DMZ configuration |
| `FirewallSettingsService` | ✅ Yes | Firewall rules |
| `StaticRoutingService` | ✅ Yes | Routing tables |
| `InstantPrivacyService` | ✅ Yes | New feature |
| `InstantSafetyService` | ✅ Yes | New feature |
| `InstantTopologyService` | ✅ Yes | Topology data |
| `ConnectivityService` | ✅ Yes | Network status checks |
| ... (and 10+ others) | | |

---

## Service Contracts & Interfaces

Analysis of abstraction quality for 53 existing services:

1.  **Strict Interfaces**: ~25 services define clear public methods returning domain models.
2.  **Leaky Abstractions**: ~5 services still return `JNAPResult` or raw JNAP exceptions.
3.  **Perfect Decoupling**: 0 services (Currently, all implementation files import JNAP directly).

**Recommendation**:
In the future USP migration phase, we need to extract **Interfaces** (abstract classes) for each Service, moving the JNAP implementation to a subclass (e.g., `JnapAuthService` implements `AuthService`).

---

## Migration Readiness

### Blockers for USP Migration

1.  **Direct JNAP Usage in Services**: All Services import JNAP packages directly.
2.  **Data Model Coupling**: Many Services return JNAP models (`NodeInfo`, `DeviceList`) instead of domain entities.
3.  **Error Handling**: Exception types are often JNAP-specific.

### Next Steps

1.  **Interface Extraction**: Define abstract base classes for all critical Services.
2.  **Model Mapping**: Ensure all Services return app-specific Domain Models, not JNAP Models.
3.  **Repository Pattern**: Introduce feature-specific repositories if Services become too complex.

---

## References

- [Architecture Analysis](architecture-analysis.md)
- [Constitution](../../constitution.md)
