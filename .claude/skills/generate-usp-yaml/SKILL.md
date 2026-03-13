---
name: generate-usp-yaml
description: Use when converting JNAP actions to USP YAML definition files. Trigger when user mentions JNAP action names (e.g., GetRadioInfo, GetDevices, SetFirewallSettings) and wants to generate YAML definitions for usp-codegen. Also triggers when user provides a Dart service file and wants to inventory its JNAP actions for YAML generation. Trigger keywords - generate yaml, JNAP to yaml, USP definition, convert action, YAML definition, 產生yaml, 轉換yaml, 產生定義檔, 盤點action, inventory actions.
---

# Generate USP YAML Definition

## Overview

Convert JNAP actions into USP YAML definition files by looking up TR-181 field mappings and following the yaml-spec.md format. The spec file is the single source of truth for all YAML structure, field names, type mappings, and path conventions.

## When to Use

- User provides one or more JNAP action names and wants USP YAML definitions
- User provides a Dart service file and wants to inventory its JNAP actions for YAML generation
- User wants to create a new YAML definition file for usp-codegen
- User is migrating a JNAP action to USP and needs the YAML definition

## When NOT to Use

- User wants to edit an existing YAML definition (just edit directly)
- User is writing extension/transform YAML files (different format)
- The JNAP action has no TR-181 mapping available

## Step 0: Read References (MANDATORY)

**Before doing anything else, read these files every time this skill is invoked:**

1. `doc/usp/yaml-spec.md` — **The single source of truth.** All YAML field names, type mappings, path conventions, structure rules, and supported features come from this file. Do NOT rely on memory or hardcoded rules.
2. `doc/jnap_to_tr181_field_mapping.md` — JNAP to TR-181 field-level mappings.

Also scan existing definitions for style consistency:
- `definitions/` — Production YAML files organized by category.

**CRITICAL: If yaml-spec.md defines a field name, type, convention, or rule, follow it exactly. This skill only provides the workflow logic for translating JNAP actions — the spec owns all format decisions.**

## Execution Workflow

### Phase 0: Inventory JNAP Actions from Service File (Optional)

**When to use**: User provides a Dart service file path (e.g., `internet_settings_service.dart`) instead of specific JNAP action names.

**Steps:**

1. Read the target service file
2. Identify all JNAP actions referenced by searching for:
   - `JNAPAction.xxx` enum references (e.g., `JNAPAction.getWANSettings`)
   - Transaction builder patterns: `MapEntry(JNAPAction.xxx, ...)`
   - Result extraction patterns: `JNAPTransactionSuccessWrap.getResult(JNAPAction.xxx, ...)`
3. For each action found, classify as:
   - **GET** — used in transaction fetch (input `{}`, output parsed into model)
   - **SET** — used in save/update (input from model `.toJson()`)
   - **ACTION** — standalone operation (e.g., `RenewDHCPWANLease`)
4. Identify the JNAP model files by following imports:
   - `import '...models/wan_settings.dart'` → Contains `RouterWANSettings`, `PPPoESettings`, etc.
5. For SET actions, also check for converter files in sibling directories:
   - Look for `services/ipv4/` and `services/ipv6/` converter files
   - Each converter's `toJNAP()` method reveals which fields are written
6. Present the full action inventory to the user for confirmation before proceeding to Phase 1

**Output format:**

| # | Action | Type | Model File | Purpose |
|---|--------|------|------------|---------|
| 1 | GetWANSettings | GET | wan_settings.dart | Read IPv4 WAN settings |
| 2 | SetWANSettings | SET | wan_settings.dart | Write IPv4 WAN settings |
| ... | ... | ... | ... | ... |

### Phase 1: Look Up JNAP Action

1. Read `doc/jnap_to_tr181_field_mapping.md`
2. Find the target JNAP action (e.g., `GetRadioInfo`)
3. Check the **Status** column:
   - **Direct** or **Partial** → Proceed to Phase 2
   - **Custom** → Warn user: requires Vendor Extension (`X_LINKSYS_COM_*`), standard TR-181 paths unavailable. Ask if they want to proceed with partial mappings or skip.
   - **N/A** → Inform user there is no TR-181 equivalent
4. Extract all field mappings:
   - JNAP field name, type
   - TR-181 path, type, access mode (R/W/RW)
   - Note any nested structures (e.g., `RadioInfo[]`, `SinglePortForwardingRule[]`)

5. **Deep Field Expansion** (for fields marked `—` in the mapping document):

   The mapping document (`jnap_to_tr181_field_mapping.md`) sometimes maps at the **top-level object granularity** (e.g., `staticSettings → —`), even though the sub-fields inside that object DO have standard TR-181 paths.

   For fields marked `—` that are **nested objects** (e.g., `staticSettings`, `pppoeSettings`, `tpSettings`, `bridgeSettings`):

   a. Read the corresponding JNAP model file (identified in Phase 0 or by import path in the service file)
   b. Find the nested class definition (e.g., `class StaticSettings`, `class PPPoESettings`)
   c. List ALL sub-fields from the class with their types
   d. For each sub-field, determine the TR-181 path by:
      - First checking if the mapping document has a direct entry for the sub-field
      - Then applying TR-181 Device:2 Data Model standard knowledge:
        - Static IP: `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress`, `.SubnetMask`
        - Default Gateway: `Device.Routing.Router.{i}.IPv4Forwarding.{i}.GatewayIPAddress`
        - DNS Servers: `Device.DNS.Client.Server.{i}.DNSServer`
        - PPP/PPPoE: `Device.PPP.Interface.{i}.Username`, `.Password`, `.PPPoE.ServiceName`, `.ConnectionTrigger`, `.IdleDisconnectTime`, `.LCPEcho`
        - VLAN: `Device.Ethernet.VLANTermination.{i}.Enable`, `.VLANID`
        - Bridge: `Device.Bridging.Bridge.{i}.Enable`
        - IPv6: `Device.IP.Interface.{i}.IPv6Enable`
        - DHCPv6: `Device.DHCPv6.Client.{i}.DUID`, `.Enable`
        - 6rd Tunnel: `Device.IPv6rd.InterfaceSetting.{i}.Enable`, `.SPIPv6Prefix`, `.IPv4MaskLength`, `.BorderRelayIPv4Addresses`
        - MAC Address: `Device.Ethernet.Interface.{i}.MACAddress` (R), `Device.Ethernet.Link.{i}.MACAddress` (RW)
        - DHCP Operations: `Device.DHCPv4.Client.{i}.Renew()`, `Device.DHCPv6.Client.{i}.Renew()`
        - MTU: `Device.IP.Interface.{i}.MaxMTUSize`
      - If no standard TR-181 path exists for a sub-field, mark it as `# NO TR-181 MAPPING` with the reason
   e. Present the complete field-level audit to user, including:
      - Sub-fields with TR-181 paths found (these become active YAML parameters)
      - Sub-fields genuinely without TR-181 mapping (these become commented-out entries)

6. **Determine writable from paired actions:**

   If a Get action has a corresponding Set action (e.g., `GetWANSettings` / `SetWANSettings`):
   - Read the Set action's converter or model `toJson()` method to see which fields are written
   - Fields that appear in Set input → `writable: true`
   - Fields only in Get output → read-only (omit `writable`)
   - For services with type-specific converters (e.g., `DhcpConverter`, `PppoeConverter`), check ALL converters to get the complete writable field set

### Phase 2: Determine YAML Structure

Based on the extracted mapping, apply yaml-spec.md rules to decide:

**Decision: Single-instance vs Multi-instance**

```
TR-181 path contains {i}?
  YES → Does the action return a list/array of items?
    YES → multiInstance: true + use basePath (strip trailing .{i}.)
    NO  → Use instance with a specific instance number
  NO  → Single-instance, use instance or absolute paths
```

**Decision: Path Mode (refer to yaml-spec.md §Path Modes)**

```
All parameters share the same TR-181 object prefix?
  YES → Use instance (Mode A) or basePath (Mode B) with relative paths
  NO  → Parameters come from multiple TR-181 objects?
    Same definition context → Use related (Mode A + related, see §1.7)
    Unrelated aggregation  → Use absolute paths (Mode C)
```

**Decision: Read-only vs Writable**

- TR-181 Access `R` → omit writable (defaults to false per spec)
- TR-181 Access `W` or `RW` → `writable: true`

**Decision: Add/Delete support (refer to yaml-spec.md §1.6)**

```
JNAP has both Get and Set actions for the same multi-instance object?
  AND the Set action creates/removes instances → type: add
  AND the Set action only removes instances   → type: delete
  Otherwise → omit type field
```

**Decision: Get+Set action pairs**

When the user specifies a pair of JNAP actions (e.g., `GetRadioInfo` + `SetRadioSettings`):
- Combine read fields from Get and write fields from Set into a single YAML definition
- Fields that appear in Get response → read-only (unless also in Set request)
- Fields that appear in Set request → `writable: true`

**Decision: Multi-Action Aggregation (Mode C)**

```
Service file uses multiple JNAP actions that map to different TR-181 objects?
  YES → All actions serve a single logical "page" or "feature"?
    YES → Consider Mode C (absolute paths) to aggregate into fewer YAML files
          Benefits: fewer fetch() calls, simpler service layer
          Trade-off: larger single YAML, cross-object coupling
    NO  → Separate YAML files per action/object group
  NO  → Use standard Mode A/B based on single object path
```

**Grouping heuristic for Mode C:**
- Group by functional domain: e.g., all IPv4 WAN settings (DHCP, Static, PPPoE, PPTP, L2TP, Bridge) → 1 YAML
- Keep IPv6 settings separate from IPv4 → 1 YAML
- Operate commands (e.g., Renew) → 1 YAML with `type: operate`
- Read-only capability queries (e.g., supportedWANTypes) → consider separate YAML if never written

**Decision: Advanced features**

Check if any of these yaml-spec.md features apply:
- **Children / Nested Multi-Instance** (§1.9) — TR-181 has nested `{i}.{j}` sub-tables
- **Flatten Mode** (§1.10) — User needs a flat list across all parent instances
- **Presets** (§1.3) — Action has well-known configuration templates (e.g., DNS providers)
- **Operate** (§1.8) — Action maps to a USP Operate command, not Get/Set

### Phase 3: Map Types

Refer to yaml-spec.md §3 (Type Mapping) for the authoritative type conversion table. Map TR-181 types to YAML types according to that table.

If TR-181 type is not specified in the mapping document, default to `string`.

### Phase 4: Generate YAML

**Use the field names, structure, and conventions exactly as defined in yaml-spec.md §1.1 (Top-Level Fields), §1.2 (Parameters), §4 (Path Conventions), and §5 (Naming Conventions).**

**Naming (this skill's convention, not from spec):**
- `name`: Based on the **feature/functionality**, NOT derived from the JNAP action name. Use PascalCase.
  - Derive from the TR-181 object path and functional semantics (e.g., `Device.WiFi.Radio` → `WiFiRadios`, `Device.Hosts.Host` → `ConnectedDevices`)
  - For multi-instance definitions, use plural form (e.g., `WiFiRadios`, `ConnectedDevices`, `PortForwardingRules`)
  - For single-instance definitions, use singular form (e.g., `DeviceInfo`, `FirewallSettings`, `WANStatus`)
  - **Suggest a name and present it to the user for confirmation.** The user may override.

**field_name derivation (this skill's convention):**
- Strip the TR-181 object prefix, keep only the parameter leaf name
- Convert to camelCase: `HostName` → `hostName`, `IPAddress` → `ipAddress`
- For boolean fields: prefer descriptive names like `isEnabled`, `isActive` when the TR-181 name is just `Enable` or `Active`
- If the JNAP field mapping document provides a JNAP field name, prefer that as a reference

**Unmapped Field Handling:**

Fields from JNAP that have no standard TR-181 path MUST be included as YAML comments at the end of the `parameters` section, grouped under a `# === NO TR-181 MAPPING ===` header:

```yaml
parameters:
  # === Active Parameters ===
  - path: Device.IP.Interface.1.MaxMTUSize
    field_name: mtu
    type: int
    writable: true
    description: Maximum transmission unit size

  # ... more active parameters ...

  # === NO TR-181 MAPPING (preserved from JNAP for reference) ===
  # - field_name: tpServer
  #   jnap_source: tpSettings.server
  #   type: string
  #   description: "PPTP/L2TP tunnel server address (no standard TR-181 path)"
  #
  # - field_name: domainName
  #   jnap_source: staticSettings.domainName
  #   type: string
  #   description: "Domain name (no standard TR-181 path)"
```

Each commented-out field must include:
- `field_name`: camelCase name derived from JNAP field
- `jnap_source`: Full dot-path in JNAP model (e.g., `tpSettings.server`)
- `type`: JNAP type converted to YAML type
- `description`: What the field does AND why there is no TR-181 mapping

**Value Transformation Notes:**

When JNAP and TR-181 use different value formats for the same concept, document the transformation in a YAML comment near the parameter:

```yaml
  - path: Device.PPP.Interface.1.ConnectionTrigger
    field_name: connectionTrigger
    type: string
    writable: true
    description: PPP connection mode (AlwaysOn, OnDemand, Manual)
    # Value mapping: JNAP KeepAlive → TR-181 AlwaysOn, JNAP ConnectOnDemand → TR-181 OnDemand

  - path: Device.PPP.Interface.1.IdleDisconnectTime
    field_name: idleDisconnectTime
    type: int
    writable: true
    description: Idle timeout before disconnection in seconds (0=never)
    # Unit conversion: JNAP maxIdleMinutes (minutes) → TR-181 IdleDisconnectTime (seconds), multiply by 60
```

**Everything else (field names, path format, type values, structure) → follow yaml-spec.md exactly.**

### Phase 5: Present and Confirm

1. Show the generated YAML to the user
2. Explain any decisions made (path mode, multi-instance, type mapping, advanced features)
3. Summarize the field audit:
   - Number of active parameters (with TR-181 paths)
   - Number of commented-out fields (no TR-181 mapping) and their reasons
   - Any value transformations documented
4. Ask the user:
   - Confirm or override the suggested `name`
   - Where to save the file (suggest `definitions/{category}/{snake_case_name}.yaml`)
   - Whether to add subscribe configuration
   - Whether any fields need adjustment
   - Whether the YAML file grouping/split is acceptable (especially for Mode C aggregation)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Not reading yaml-spec.md before generating | ALWAYS read the spec first — it is the single source of truth |
| Including `{i}` in basePath | Strip instance placeholder: `Device.WiFi.Radio` not `Device.WiFi.Radio.{i}` |
| Forgetting to check both Get and Set actions | Always check paired actions for writable field information |
| Silently dropping fields with `—` TR-181 path | Include as YAML comments with `jnap_source` annotation for traceability — never silently omit JNAP fields |
| Only checking mapping document top-level for TR-181 paths | When mapping shows `—` for a nested object (e.g., `staticSettings`), expand sub-fields and check each individually against TR-181 standard |
| Not reading the JNAP model file to discover sub-fields | Always read the model class (`class StaticSettings`, `class PPPoESettings`, etc.) to get the complete field list, especially for nested objects |
| Using JNAP types directly | Convert types per yaml-spec.md §3 Type Mapping |
| Deriving name from JNAP action name | Name should reflect the feature/functionality based on TR-181 object semantics, not the JNAP action name (e.g., `WiFiRadios` not `RadioInfos`) |
| Hardcoding spec rules | Always defer to yaml-spec.md for field names, types, conventions — the spec may have been updated |
| Ignoring value transformations between JNAP and TR-181 | Document unit conversions (minutes→seconds) and value mappings (KeepAlive→AlwaysOn) as YAML comments near the parameter |

## Output File Location

Suggest saving to: `definitions/{category}/{snake_case_name}.yaml`

Categories:
- `core` — Device info, system settings, time
- `wifi` — WiFi radios, SSIDs, access points
- `devices` — Connected devices, host management
- `firewall` — Firewall rules, port forwarding, DMZ
- `network` — WAN, LAN, DHCP, routing, IPv6
- `vendor` — Vendor extension features
