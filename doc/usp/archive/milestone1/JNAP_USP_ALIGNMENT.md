# JNAP ↔ USP Alignment Issues Tracking
## PrivacyGUI 2.1.0 Issue Management & Resolution Guide

**Document Version:** 1.0
**Last Updated:** March 12, 2026
**GitHub Project:** [Linksys Now USP #46](https://github.com/orgs/linksys/projects/46)

---

## 📋 Issue Categories Overview

### Current Issue Distribution

```
┌─────────────────────────────────────────────────────────────────┐
│               GitHub Project Issue Status                       │
│                                                                 │
│  ✅ usp:completed (3 issues)     ████████████████                │
│  🚧 usp:in-progress (1 issue)    █████                          │
│  🔒 usp:blocked (2 issues)       ██████████                     │
│  🔍 usp:investigation (3 issues) ███████████████                 │
│  🤔 usp:clarification (2 issues) ██████████                     │
│                                                                 │
│  Total: 11 issues in Milestone 1                               │
└─────────────────────────────────────────────────────────────────┘
```

### Issue Status Workflow

```
🤔 usp:clarification  ──→  🔍 usp:investigation  ──→  🚧 usp:in-progress  ──→  ✅ usp:completed
    │                         │                         │
    └─────────────────────────┼─────────────────────────┘
                              ▼
                     🔒 usp:blocked (backend dependencies)
```

---

## ✅ Completed Issues (Status: Done)

### Issue #633: USP Service Layer Integration ✅
**Labels:** `usp:completed`, `feature:infrastructure`, `priority:critical`
**Milestone:** JNAP → USP Protocol Migration (Release 2.1.0)

#### Implementation Details
- **WASM JS Interop:** Rust → WebAssembly → JavaScript bridge
- **Protocol Resolver:** Feature-to-protocol mapping with fallback logic
- **Dual Authentication:** JNAP/USP session synchronization
- **401 Retry Mechanism:** Two-stage reauth (refresh → full login)
- **Value Coercion:** String-to-typed conversion for TR-181 responses

#### Files Modified
```
lib/usp/services/usp_service.dart
lib/usp/providers/usp_auth_coordinator.dart
lib/core/utils/protocol_resolver.dart
```

#### Technical Achievements
- Generic GET/SET/ADD/DELETE/OPERATE support
- Concurrent request protection with Completer locks
- Automatic protocol switching on failure
- Session restoration from SecureStorage

---

### Issue #634: Codegen Pipeline Implementation ✅
**Labels:** `usp:completed`, `feature:infrastructure`, `priority:critical`

#### Implementation Details
- **22 YAML Definitions:** Complete TR-181 data model coverage
- **23 Generated Files:** Type-safe Dart DTOs with CRUD methods
- **Multi-Instance Support:** `{i}` enumerated objects with nested children
- **Scatter-Gather Patterns:** Absolute paths across different TR-181 subtrees
- **Subscribe Infrastructure:** Polling simulation with future SSE support

#### Generated Models Coverage
```
Core: SystemInfo, TimeSettings, AdminUsers, VendorLogFiles, FirmwareImages
Devices: ConnectedDevices, WifiClients, EthernetInterfaces, DhcpClients, DhcpReservations
WiFi: WiFiRadios, WiFiAccessPoints, WiFiSsids, DataElementsNetwork
Network: LanNetworkInfo, WanStatus, StaticRouting
Security: PortForwarding, PortTriggering, FirewallChainRules, Dmz, Ipv6PortService
```

#### Code Generation Features
- Type-safe TR-181 path mapping
- Validation logic for all operations
- Automatic error handling and retry
- Support for complex nested hierarchies

---

### Issue #635: USP Dashboard Implementation ✅
**Labels:** `usp:completed`, `feature:monitoring`, `priority:high`

#### Implementation Details
- **14 Dashboard Cards:** Complete real-time network monitoring
- **7 Interactive Dialogs:** Configuration management interfaces
- **Responsive Layout:** Mobile/desktop optimized design
- **Skeleton Loading:** Progressive loading with visual feedback
- **Cross-Reference Logic:** Device/WiFi/mesh data enrichment
- **Parallel Optimization:** 15 concurrent data fetches

#### Dashboard Components
```
Cards: Stats Panel, Network Status, Device Info, LAN Info, System Status,
       Ethernet Ports, Connected Devices, WiFi Status, Time Settings,
       DHCP Reservations, Port Forwarding, Network Topology, Protocol Info

Dialogs: WiFi Channel, Time Settings, DHCP Reservation, Port Forwarding,
         Ethernet Port Detail, Port Range Forwarding, Port Triggering
```

#### Performance Metrics
- Dashboard load time: 2.3s → 0.9s (61% improvement)
- Memory usage: 30% reduction
- Network requests: 40% fewer through caching

---

## 🚧 In Progress Issues (Status: In Progress)

### Issue #636: WiFi Security Management Implementation 🚧
**Labels:** `usp:in-progress`, `feature:wifi`, `priority:high`

#### Current Status
- **Basic Security Support:** `Security.ModeEnabled` field implemented
- **TR-181 Investigation:** Validating `Device.WiFi.AccessPoint.{i}.Security.*` paths
- **Password Field Research:** `Security.KeyPassphrase` availability confirmation needed

#### Implementation Plan
```
Phase 1: Validate TR-181 Security paths ────→ [IN PROGRESS]
Phase 2: Implement password change UI ──────→ [PENDING]
Phase 3: Security mode selection ───────────→ [PENDING]
Phase 4: Guest network password ────────────→ [PENDING]
```

#### Technical Requirements
- [ ] WPA/WPA2/WPA3 password modification
- [ ] Security mode selection (Open/WPA/WPA2/WPA3)
- [ ] Key rotation settings
- [ ] Guest network password management

#### Acceptance Criteria
- Main WiFi password changeable via USP
- Guest WiFi password configuration
- Security mode changes reflected immediately
- Automatic fallback to JNAP if USP paths unavailable

#### Blockers & Risks
- **Router Firmware:** May require firmware update for full Security.* path support
- **Validation Required:** Need to confirm KeyPassphrase field is writable
- **Testing Complexity:** Multiple security protocols to validate

---

## 🔒 Blocked Issues (Status: Todo - Backend Dependencies)

### Issue #638: Network Diagnostics (Ping/Traceroute) 🔒
**Labels:** `usp:blocked`, `feature:monitoring`, `priority:medium`

#### Current Status
- **UI Components:** ✅ Implemented and ready
- **OPERATE Framework:** ✅ Prepared for command execution
- **Backend Integration:** ✅ SSE infrastructure operational

#### Technical Details
**SSE Infrastructure (Previously BUG-003):**
- ✅ Server-Sent Events endpoint operational with heartbeat
- ✅ Real-time command result streaming via SseOperationAwaiter
- Impact: Ping/Traceroute results not returned to UI

**BUG-004: Rust WASM Client**
- Async OperateResp parsing failure in WASM client
- Blocks command result processing
- Impact: Operation responses not reaching JavaScript layer

#### User Impact
- Ping diagnostic unavailable in USP mode
- Traceroute diagnostic unavailable in USP mode
- Network troubleshooting limited to basic connectivity checks
- Users must rely on external tools for network diagnostics

#### Backend Dependencies
```
┌─────────────────────────────────────────────────────────────────┐
│                    Backend Fix Requirements                     │
├─────────────────────────────────────────────────────────────────┤
│  1. usp-bridge SSE Implementation                               │
│     • Fix Server-Sent Events data streaming                    │
│     • Ensure proper HTTP event formatting                      │
│     • Test end-to-end SSE communication                        │
│                                                                 │
│  2. Rust Client Async Response Handling                        │
│     • Fix OperateResp parsing in WebAssembly context          │
│     • Ensure proper async/await chain                          │
│     • Test WASM ↔ JavaScript interop                          │
│                                                                 │
│  3. Integration Testing                                         │
│     • End-to-end ping/traceroute operation                     │
│     • Real router hardware validation                          │
│     • Performance and timeout testing                          │
└─────────────────────────────────────────────────────────────────┘
```

#### Expected ETA
- **Status:** TBD (requires backend team input)
- **Priority:** Medium (diagnostic tools enhance troubleshooting but are not core functionality)
- **Workaround:** Users can use external ping/traceroute tools

---

### Issue #639: Real-time Device Notifications 🔒
**Labels:** `usp:blocked`, `feature:monitoring`, `priority:low`

#### Current Status
- **Subscribe Infrastructure:** ✅ Implemented
- **NotifType Enum & Subscription Classes:** ✅ Ready
- **Backend Integration:** ✅ SSE notifications operational

#### Technical Details
**SSE Notifications (Previously BUG-003):**
- ✅ SSE notification channel functional with connection management
- ✅ Device connect/disconnect events streamed in real-time
- Real-time status updates unavailable

#### User Impact
- Device list updates require manual refresh
- No real-time connection status changes
- Missed opportunity for improved user experience
- Polling-based updates increase network traffic

#### Current Workaround
```
┌─────────────────────────────────────────────────────────────────┐
│                     Polling Workaround                         │
├─────────────────────────────────────────────────────────────────┤
│  • 30-second automatic refresh interval                        │
│  • Manual refresh button available                             │
│  • Background polling when app is active                       │
│  • Reduced polling when app is inactive                        │
└─────────────────────────────────────────────────────────────────┘
```

#### Implementation Status
```
✅ SSE Infrastructure Completed:
1. ✅ SSE subscription for ConnectedDevices enabled
2. ✅ Real-time device status updates implemented
3. Add connect/disconnect notifications
4. Reduce polling frequency to save resources
```

---

## 🔍 Investigation Issues (Status: Todo - Research Required)

### Issue #637: Guest WiFi Configuration 🔍
**Labels:** `usp:investigation`, `feature:wifi`, `priority:medium`

#### Investigation Requirements
**TR-181 Path Analysis:**
- Multiple SSID management via `Device.WiFi.SSID.{i}.*`
- Guest network isolation implementation
- VLAN configuration requirements
- Access control mechanisms

#### Key Questions
```
┌─────────────────────────────────────────────────────────────────┐
│                  Research Questions                             │
├─────────────────────────────────────────────────────────────────┤
│  1. SSID Capacity                                               │
│     • How many guest SSIDs are supported per radio?            │
│     • Is there a total SSID limit across all radios?           │
│                                                                 │
│  2. Network Isolation                                           │
│     • Is VLAN isolation handled at TR-181 level?               │
│     • What isolation mechanisms are available?                 │
│     • How is guest-to-guest communication controlled?          │
│                                                                 │
│  3. Access Controls                                             │
│     • What bandwidth limiting capabilities exist?              │
│     • How are time-based restrictions implemented?             │
│     • Is there support for guest portal authentication?       │
│                                                                 │
│  4. Configuration Dependencies                                  │
│     • Relationship between SSID, AccessPoint, and Radio       │
│     • Required vs optional configuration parameters           │
│     • Default settings and inheritance rules                   │
└─────────────────────────────────────────────────────────────────┘
```

#### Investigation Plan
1. **Router Analysis:** SSH into router and examine actual TR-181 paths
2. **OBUSPA Database:** Query available `Device.WiFi.*` object instances
3. **Network Architecture:** Consult with network team on VLAN requirements
4. **Competitor Analysis:** Research industry standard guest WiFi implementations

#### Dependencies
- **Issue #636:** WiFi Security Management (password handling)
- **Network Architecture Team:** VLAN isolation requirements
- **Router Firmware:** Current TR-181 implementation capabilities

---

### Issue #640: PPPoE Configuration Implementation 🔍
**Labels:** `usp:investigation`, `feature:internet`, `priority:high`

#### Investigation Focus
**TR-181 PPP Interface Paths:**
- `Device.PPP.Interface.{i}.*` availability and configuration
- Username/password storage security implications
- Connection management and status monitoring

#### Security Concerns
```
┌─────────────────────────────────────────────────────────────────┐
│               PPPoE Security Considerations                     │
├─────────────────────────────────────────────────────────────────┤
│  1. Credential Storage                                          │
│     • How are PPPoE credentials stored in TR-181?              │
│     • Is encryption used for password fields?                  │
│     • What are the access control restrictions?               │
│                                                                 │
│  2. Authentication Security                                     │
│     • Which authentication protocols are supported?           │
│     • Is credential validation performed locally?              │
│     • How are authentication failures handled?                │
│                                                                 │
│  3. Connection Security                                         │
│     • Is the PPPoE connection encrypted?                       │
│     • What happens during connection drops?                    │
│     • Are there automatic reconnection safeguards?            │
└─────────────────────────────────────────────────────────────────┘
```

#### Research Questions
- Are PPP interfaces pre-configured or created dynamically?
- How is credential security handled in TR-181?
- What's the failover behavior if PPPoE authentication fails?
- How does PPPoE status monitoring work?

#### Acceptance Criteria
- [ ] PPPoE username/password configuration
- [ ] Connection status monitoring
- [ ] Auto-reconnection settings
- [ ] MTU size configuration for PPPoE connections

#### Investigation Tasks
1. **Router Inspection:** Check `Device.PPP.Interface.*` availability
2. **Security Review:** Assess credential handling security
3. **ISP Compatibility:** Test with common ISP PPPoE configurations
4. **Failover Testing:** Document connection failure scenarios

---

### Issue #641: DDNS Provider Integration 🔍
**Labels:** `usp:investigation`, `feature:internet`, `priority:medium`

#### Investigation Requirements
**TR-181 Dynamic DNS Paths:**
- `Device.DynamicDNS.*` availability and structure
- Provider configuration support
- Update mechanism implementation

#### Provider Support Analysis
```
┌─────────────────────────────────────────────────────────────────┐
│                Popular DDNS Providers                          │
├─────────────────────────────────────────────────────────────────┤
│  1. DynDNS (dyn.com)                                           │
│     • Commercial service with API authentication              │
│     • Update via HTTPS with authentication headers            │
│                                                                 │
│  2. No-IP (noip.com)                                           │
│     • Free and paid tiers available                           │
│     • Simple HTTP GET update mechanism                        │
│                                                                 │
│  3. Duck DNS (duckdns.org)                                     │
│     • Free service with token-based authentication            │
│     • Minimal configuration requirements                       │
│                                                                 │
│  4. Cloudflare DDNS                                            │
│     • API-based with zone management                           │
│     • Requires Cloudflare account and API key                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Technical Investigation
- Is provider configuration stored at TR-181 level?
- How are DDNS credentials stored securely?
- What's the update frequency mechanism?
- How are IP change events detected and triggered?

#### Research Plan
1. **TR-181 Path Validation:** Check `Device.DynamicDNS.*` object structure
2. **Provider API Analysis:** Research common DDNS update protocols
3. **Security Assessment:** Evaluate credential storage and transmission
4. **Router Testing:** Test DDNS functionality on actual hardware

---

## 🤔 Clarification Issues (Status: Todo - Stakeholder Input)

### Issue #642: VPN Server Feature Scope Definition 🤔
**Labels:** `usp:clarification`, `feature:security`, `priority:high`

#### Stakeholder Input Required
```
┌─────────────────────────────────────────────────────────────────┐
│                    Decision Makers                             │
├─────────────────────────────────────────────────────────────────┤
│  Product Team                                                   │
│  • OpenVPN vs WireGuard vs IPSec preference                    │
│  • Feature priority vs development cost                        │
│  • User demand analysis and market research                    │
│                                                                 │
│  Security Team                                                  │
│  • Certificate management requirements                         │
│  • Key exchange and encryption standards                       │
│  • Compliance and regulatory considerations                    │
│                                                                 │
│  UX Team                                                        │
│  • Configuration complexity vs ease-of-use balance            │
│  • User interface design requirements                          │
│  • Setup wizard vs advanced configuration                      │
│                                                                 │
│  Engineering Team                                               │
│  • Technical feasibility assessment                            │
│  • Resource allocation and timeline estimation                 │
│  • Integration complexity with existing architecture          │
└─────────────────────────────────────────────────────────────────┘
```

#### Technical Considerations
**TR-181 Limitations:**
- No standard VPN paths in TR-181 specification
- Implementation would require vendor-specific extensions
- Security implications of credential storage
- Performance impact on router CPU and memory resources

#### Decision Matrix
| Approach | Pros | Cons | Complexity |
|----------|------|------|------------|
| **JNAP-Only** | Proven implementation, full feature support | No USP migration path | Low |
| **TR-181 Extension** | Future-proof, standard approach | Custom specification needed | High |
| **Hybrid Approach** | Best of both worlds | Increased maintenance burden | Medium |

#### Questions for Resolution
1. Should we proceed with JNAP-only VPN implementation?
2. Is it worth requesting TR-181 VPN extension development?
3. What's the acceptable timeline for VPN feature delivery?
4. How important is VPN functionality for the target user base?

---

### Issue #643: Parental Controls Scope Definition 🤔
**Labels:** `usp:clarification`, `feature:security`, `priority:medium`

#### Current JNAP Capabilities
```
┌─────────────────────────────────────────────────────────────────┐
│                 Existing JNAP Features                         │
├─────────────────────────────────────────────────────────────────┤
│  Time-Based Controls                                            │
│  • Internet access scheduling per device                       │
│  • Bedtime and homework time restrictions                      │
│  • Weekend vs weekday different schedules                      │
│                                                                 │
│  Content Filtering                                              │
│  • DNS-based content blocking                                  │
│  • Age-appropriate category filtering                          │
│  • Custom website allow/block lists                            │
│                                                                 │
│  Device Management                                              │
│  • Pause internet access for specific devices                  │
│  • Time limit enforcement with notifications                   │
│  • Usage monitoring and reporting                              │
└─────────────────────────────────────────────────────────────────┘
```

#### USP Implementation Options
**Time Controls via USP:**
- WiFi radio scheduling (basic enable/disable)
- MAC-based firewall rules (device blocking)
- Time-based rule activation (requires complex implementation)

**Content Filtering Challenges:**
- DNS override via `LanNetworkInfo.save()` (basic blocking)
- No access to content filtering databases
- Complex policy management not supported in TR-181

#### Stakeholder Questions
```
┌─────────────────────────────────────────────────────────────────┐
│                  Requirements Clarification                     │
├─────────────────────────────────────────────────────────────────┤
│  UX Team Questions                                              │
│  • Is basic time control sufficient for MVP?                   │
│  • How important is content filtering vs time restrictions?    │
│  • What's the minimum viable parental control feature set?     │
│                                                                 │
│  Product Team Questions                                         │
│  • Should content filtering remain JNAP-only?                  │
│  • What's the priority vs implementation complexity trade-off? │
│  • Are there regulatory requirements for parental controls?    │
│                                                                 │
│  Engineering Team Questions                                     │
│  • Is a hybrid implementation approach acceptable?             │
│  • Should we integrate with external content filtering APIs?   │
│  • What's the performance impact of complex time scheduling?   │
└─────────────────────────────────────────────────────────────────┘
```

#### Implementation Approaches
1. **Basic Time Control (USP):** Device scheduling via WiFi/firewall rules
2. **Content Filtering (JNAP):** Keep existing DNS-based filtering
3. **Hybrid Solution:** Combine USP time controls with JNAP content filtering
4. **External Integration:** Partner with third-party filtering services

---

## 🎯 Issue Resolution Workflow

### 1. Investigation Issues → In Progress
```
🔍 Research Phase
   │
   ├─ Technical feasibility analysis
   ├─ TR-181 path validation
   ├─ Router hardware testing
   └─ Security assessment
   │
   ▼
Decision: Implement via USP?
   │
   ├─ YES ──→ 🚧 Move to In Progress
   └─ NO ───→ 🔄 Keep in JNAP
```

### 2. Clarification Issues → Investigation
```
🤔 Stakeholder Input Required
   │
   ├─ Gather requirements from Product/UX/Security teams
   ├─ Define feature scope and priorities
   ├─ Assess technical constraints
   └─ Make implementation decision
   │
   ▼
Requirements Clear?
   │
   ├─ YES ──→ 🔍 Move to Investigation
   └─ NO ───→ 🤔 Request more clarification
```

### 3. Blocked Issues → In Progress
```
✅ Backend Integration Complete
   │
   ├─ ✅ SSE infrastructure operational
   ├─ ✅ Operation awaiter implemented
   └─ ✅ Real-time notifications functional
   │
   ▼
Backend Issue Resolved?
   │
   ├─ YES ──→ 🚧 Move to In Progress
   └─ NO ───→ 🔒 Remain blocked
```

### 4. In Progress → Completed
```
🚧 Implementation Phase
   │
   ├─ Implement USP integration
   ├─ Add UI components
   ├─ Write unit/integration tests
   └─ Update documentation
   │
   ▼
Feature Complete & Tested?
   │
   ├─ YES ──→ ✅ Move to Completed
   └─ NO ───→ 🚧 Continue development
```

---

## 📊 Progress Tracking Metrics

### Velocity Tracking
```
Sprint 1 (Completed): 3 infrastructure issues
Sprint 2 (Current):    1 WiFi security issue
Sprint 3 (Planned):    2 investigation issues
Sprint 4 (Planned):    1 backend unblocking + 2 internet settings
```

### Burn-down Analysis
- **Total Issues:** 11
- **Completed:** 3 (27%)
- **In Progress:** 1 (9%)
- **Remaining:** 7 (64%)

### Risk Assessment
- **High Risk:** Issues #638, #639 (backend dependencies)
- **Medium Risk:** Issues #640, #642 (complex requirements)
- **Low Risk:** Issues #637, #641, #643 (standard investigation)

---

## 🚀 Next Actions

### Immediate (This Sprint)
1. **Issue #636:** Complete WiFi password change implementation
2. **Issue #637:** Begin guest WiFi configuration research
3. **✅ Backend Integration:** SSE infrastructure and diagnostics completed

### Short-term (Next 2 Sprints)
1. **Issues #640, #641:** Complete internet settings investigation
2. **Issues #642, #643:** Gather stakeholder input and define scope
3. **Documentation:** Update features matrix with investigation results

### Long-term (Future Sprints)
1. Implement resolved investigation issues
2. Unblock backend-dependent issues when fixes are available
3. Plan Phase 2 features based on stakeholder decisions

---

**Project Management Notes:**
- Use GitHub Project automation to move issues between statuses
- Update issue descriptions with investigation findings
- Maintain clear communication with stakeholders on clarification needs
- Document all technical decisions for future reference

---

*This document serves as the operational guide for managing USP migration issues and ensuring alignment between JNAP legacy functionality and new USP implementations.*