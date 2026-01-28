---
description: Audit service layer decoupling from JNAP and document service contracts for future protocol migration
---

# Service Decoupling Audit Workflow

This workflow checks the current state of service-layer decoupling from JNAP-specific implementations and documents service contracts for future USP/TR migration.

## Prerequisites

- Access to `lib/core/data/services/` directory
- Access to `lib/page/**/services/` directories
- Understanding of JNAP actions in `lib/core/jnap/actions/`

---

## Step 1: Identify All Services

// turbo
```bash
cd /Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI
find lib -name "*_service.dart" -type f | head -50
```

List all service files and categorize them:
- **Core Services**: `lib/core/data/services/`
- **Feature Services**: `lib/page/**/services/`

---

## Step 2: Check JNAP Coupling in Each Service

For each service file, check for direct JNAP dependencies:

// turbo
```bash
cd /Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI
grep -l "JNAPAction\|JNAPResult\|JNAPSuccess\|JNAPError\|JNAPTransaction" lib/core/data/services/*.dart lib/page/**/services/*.dart 2>/dev/null | head -30
```

**Decoupling Criteria:**
| Level | Criteria | Status |
|-------|----------|--------|
| 🔴 High Coupling | Service directly uses `JNAPAction`, `JNAPResult` | Needs refactoring |
| 🟡 Medium Coupling | Service uses `RouterRepository` but abstracts JNAP | Acceptable |
| 🟢 Low Coupling | Service uses protocol-agnostic interfaces | Ideal |

---

## Step 3: Analyze RouterRepository Usage

Check how services interact with RouterRepository:

// turbo
```bash
cd /Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI
grep -n "routerRepositoryProvider\|RouterRepository" lib/core/data/services/*.dart lib/page/**/services/*.dart 2>/dev/null | head -50
```

Document the usage pattern:
- `send()` - Single JNAP command
- `transaction()` - Batch JNAP commands  
- `scheduledCommand()` - Polling JNAP commands

---

## Step 4: Document Service Contracts

For each service, create a contract document with the following template:

```markdown
## [ServiceName]

**Location**: `lib/path/to/service.dart`

**Responsibility**: Brief description of what this service does

**Dependencies**:
- RouterRepository (JNAP communication)
- Other services or providers

### Read Operations
| Operation | Description | JNAP Action(s) |
|-----------|-------------|----------------|
| getXxx() | Description | JNAPAction.xxx |

### Write Operations
| Operation | Description | JNAP Action(s) |
|-----------|-------------|----------------|
| setXxx() | Description | JNAPAction.xxx |

### Data Models
- Input: List of input types
- Output: List of output/state types

### Side Effects
- Does this trigger device restart?
- Does this require polling for completion?
```

---

## Step 5: Generate Service-JNAP Mapping Table

// turbo
```bash
cd /Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI
grep -h "JNAPAction\." lib/core/data/services/*.dart lib/page/**/services/*.dart 2>/dev/null | grep -o "JNAPAction\.[a-zA-Z]*" | sort | uniq -c | sort -rn | head -30
```

Create a mapping table for migration planning:

| JNAP Action | Used By Service(s) | USP Equivalent (TBD) |
|-------------|-------------------|----------------------|
| getDeviceInfo | DashboardManagerService, PollingService | Device.DeviceInfo. |
| getDevices | DeviceManagerService, PollingService | Device.Hosts.Host. |
| ... | ... | ... |

---

## Step 6: Check Domain Model Independence

Verify that domain models don't expose JNAP-specific structures:

// turbo
```bash
cd /Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI
grep -l "fromMap\|fromJson" lib/core/jnap/models/*.dart | head -20
```

**Model Checklist:**
- [ ] Field names are domain-specific, not JNAP-specific
- [ ] Factory constructors handle data transformation
- [ ] Models are in `lib/core/jnap/models/` (acceptable for now)

---

## Step 7: Generate Audit Report

Create a summary report at:
`/Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/docs/service-decoupling-audit.md`

Report should include:
1. **Executive Summary**: Overall decoupling status
2. **Service Inventory**: List of all services with coupling level
3. **JNAP Action Usage**: Which actions are used and where
4. **Migration Readiness**: Services ready for protocol swap
5. **Recommendations**: Priority actions for better decoupling

---

## Step 8: Update Service Documentation

For services with missing contracts, add documentation comments:

```dart
/// [ServiceName] - Brief description
///
/// ## Responsibilities
/// - List of responsibilities
///
/// ## JNAP Actions Used
/// - `JNAPAction.xxx` - Purpose
/// - `JNAPAction.yyy` - Purpose
///
/// ## Future Migration Notes
/// - USP equivalent operations (when known)
/// - Special considerations
class ServiceName {
  // ...
}
```

---

## Output Artifacts

After completing this workflow, you should have:

1. **Service Inventory List** - All services with their locations
2. **Coupling Assessment** - Red/Yellow/Green status for each service
3. **JNAP Action Mapping** - Complete list of JNAP actions and their services
4. **Service Contracts** - Documented interfaces for each service
5. **Audit Report** - Summary document for planning

---

## When to Run This Workflow

- Before starting USP/TR integration planning
- After adding new services
- During quarterly architecture reviews
- Before major refactoring efforts
