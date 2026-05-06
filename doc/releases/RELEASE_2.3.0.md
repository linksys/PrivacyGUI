# PrivacyGUI v2.3.0 Release Notes

**Release Date:** 2026-05-06  
**Milestone:** [2.3.0](https://github.com/linksys/PrivacyGUI/milestone/4)  
**Compare:** [dev-2.2.0...dev-2.3.0](https://github.com/linksys/PrivacyGUI/compare/dev-2.2.0...dev-2.3.0)

## Summary

| Metric | Value |
|--------|-------|
| Commits | 103 |
| Files Changed | 300 |
| Lines Added | +15,272 |
| Lines Removed | -62,892 |
| Issues Closed | 19 |
| Issues Open | 6 |

This release marks a major architectural shift to **USP-only architecture**, removing legacy JNAP protocol support. Key highlights include a comprehensive L1 Service layer extraction, user-friendly timezone selection, and significant test coverage improvements.

---

## Dependencies

| Package | Version | Notes |
|---------|---------|-------|
| **ui_kit_library** | v2.18.1 | Semantic labels for E2E testing, AppTextField Tab fix, AppIpv4TextField focus traversal |
| **usp-codegen** | 0.12.5 | Grouped `setOrdered` support, batch priority writes |
| **usp-client (WASM)** | 0.9.0 | USP protocol client for web browsers |

---

## Breaking Changes

- **USP-Only Architecture** — Removed JNAP, Remote Access, and Cloud Login. The application now exclusively uses the USP (TR-369) protocol for router communication.
- **Project Restructure** — Reorganized `lib/` directory structure to align with USP-only architecture.

---

## New Features

### Timezone Selection Interface (#814)

Implemented a user-friendly timezone configuration experience:
- Searchable list selector with 39 timezone options (GMT-12:00 to GMT+12:00)
- Human-readable timezone names with GMT offset display
- Global DST toggle with automatic POSIX string generation
- Live local time display synchronized with router

### Apps Page & Package Widgets (#766, #767)

- New Apps page displaying router-installed applications
- Server-driven dashboard widget system for dynamic card rendering
- Package widget specifications with grid constraints

### Infrastructure Improvements (#768, #769)

- **Bridge Request Throttler** — Concurrency control (max 2 concurrent requests) with priority queue and deduplication for OBUSPA backend stability
- **Two-Phase SSE Boot** — Optimized dashboard startup: SSE connects first, subscriptions register after data providers settle

### USP Error Handling (#812)

- Centralized error handling system across all feature pages
- `UspResultParser` with strict mode for structured response validation
- Unified `ServiceError` hierarchy with improved error messages

---

## Bug Fixes

### Internet Settings (#758, #759)
- Fixed connection type incorrectly displaying as Bridge after saving MTU
- Fixed connection type switching producing unexpected form state
- Fixed PPPoE mode switch using `allowPartial` for proper USP SET handling

### DHCP Settings (#749, #750, #751, #752)
- Fixed back button incorrectly navigating to Menu instead of previous page
- Fixed MAC address input field lacking format validation
- Fixed adding reservation accepting invalid MAC address without error feedback
- Fixed deleting reservation showing failure message despite successful deletion

### Port Forwarding (#755, #756)
- Fixed port range dialog lacking input validation and error messages
- Fixed newly added port range rule incorrectly appearing in single port tab

### IPv6 Port Service (#753, #754)
- Fixed back button incorrectly navigating to Menu instead of Advanced Settings
- Fixed IPv6 address validation rules for accepted address ranges

### WiFi Settings (#835)
- Fixed Quick Setup save and UI improvements
- Fixed dirty guard issues during tab navigation

### Other Fixes
- Fixed local time display after timezone change
- Fixed infinite redirect loop on logout
- Fixed WASM layer Add params stringify to prevent JsValue corruption
- Fixed OPERATE/DELETE response parsing in USP client layer
- Fixed dashboard orchestrator exponential backoff for provider retry

---

## Refactoring

### L1 Service Layer Extraction (#815)

Extracted stateless service classes from all data providers following Constitution Article VI:

| Domain | Service |
|--------|---------|
| WiFi | `UspWifiDataService` |
| Time | `UspTimeDataService` |
| System Info | `UspSystemInfoDataService` |
| Devices | `UspDevicesDataService` |
| LAN/DHCP/Ethernet | `UspLanDataService`, `UspDhcpDataService`, `UspEthernetDataService` |
| Internet (WAN) | `UspWanDataService` |
| Firewall | `UspFirewallDataService` |
| Port Forwarding/Triggering | `UspPortForwardingDataService`, `UspPortTriggeringDataService` |
| System Monitor/Traffic | `UspSystemMonitorService`, `UspTrafficAnalysisService` |

### Internet Settings (#790)

- Split monolithic `_saveWanSettings` into per-mode dispatch functions
- Split `wan_settings.yaml` into per-mode YAML definitions
- Aligned with ordered USP Set and codegen-only API

### Other Refactoring

- Unified USP client API across all layers (codegen v0.12.1)
- Simplified `ServiceError` hierarchy
- Unified `NavigationExtra` and `navigateBack` for consistent navigation
- Menu feature Constitution compliance review

---

## Testing (#704, #771)

Comprehensive test coverage improvements across multiple phases:

| Phase | Focus | Tests | Coverage |
|-------|-------|-------|----------|
| Phase 4 | Complex service layer | 116 | 90.2% |
| Phase 5 | transforms.g.dart | - | - |
| Phase 6 | Auth system | - | - |
| Phase 7 | Preservable notifier | - | - |
| Phase 8 | Async notifier | 56 | 95.7% |
| Phase 9 | Shared data provider | 47 | 99.3% |
| SSE | Implementation tests | 179 | ~88% |
| Dashboard | Custom layout | 293 | 99.8% |
| Framework | Preservable mixin | - | 100% |

---

## Chores & Maintenance

### USP Codegen Upgrades (#819)
- v0.12.1 → v0.12.2 → v0.12.3 → v0.12.5
- Grouped `setOrdered` support for batch priority writes
- Regenerated all 36 YAML definitions

### Other
- Upgraded ui_kit to v2.18.1 with semantic labels for E2E testing
- Externalized USP definitions to separate repository
- Archived 20 stale planning/migration documents
- Temporarily hidden System Logs menu item
- Disabled MAC clone / PPPoE service name UI until backend support

---

## Known Issues

### Incomplete Work (2.3.0 Milestone)

| Issue | Description |
|-------|-------------|
| #778 | USP Golden Test Framework: Declarative screenshot testing for all USP views |
| #762 | [Internet Settings] implement proper Bridge Mode via TR-181 Bridging model |
| #757 | [Internet Settings] MTU auto toggle is non-functional |
| #717 | Dashboard loading resilience, edit mode resize & SSE banner grace period |
| #714 | Unified NavigationExtra & navigateBack for consistent back navigation |
| #708 | [USP] Unified Error Handling Strategy Implementation |

### Firmware Blockers

Features blocked by missing firmware/USP backend support:

| Issue | Description | Impact |
|-------|-------------|--------|
| #844 | usp-bridge fails to start after router reboot (503) | All USP API calls fail after reboot until manual restart |
| #843 | MAC Address Clone Not Writable via USP | UI disabled until FW supports write path |
| #842 | PPPoE ServiceName SET Rejected (fault 9001) | UI disabled, cannot configure PPPoE service name |
| #839 | PPTP Connection Support | Connection type not available |
| #840 | L2TP Connection Support | Connection type not available |

---

## Upgrade Notes

### For Developers
- All JNAP-related code has been removed. Ensure your development environment uses USP-compatible router firmware (v1.0.16+).
- L1 Services are now the standard pattern for data fetching. Update any custom providers to use the service layer.

### For QA
- Test all Advanced Settings pages for navigation flow (back button behavior).
- Verify timezone changes persist correctly with DST toggle.
- Confirm error messages display properly for validation failures.

---

## Contributors

- Austin Chang (@AustinChangLinksys)
- Development Team

---

## Full Changelog

See [CHANGELOG.md](./CHANGELOG.md) for complete commit history.
