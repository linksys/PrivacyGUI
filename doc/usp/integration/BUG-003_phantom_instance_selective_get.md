# BUG-003: Phantom Empty Instances with Selective Get

## Status: OPEN
## Severity: Medium (workaround exists, blocks optimization)
## Date: 2026-03-06

---

## Problem Statement

When using USP selective get (TR-369 search paths with `*` wildcard), the router
returns **phantom empty instances** that do not appear when using subtree fetch
(partial path without wildcard).

These phantom instances contain all-default values (`0`, `''`, `false`) and
produce invalid UI entries (e.g., "Unnamed rule" with `0 → :0` in port
forwarding).

## Reproduction

### Selective Get (search paths with `*`)

Request:
```
GET Device.NAT.PortMapping.*.Enable
GET Device.NAT.PortMapping.*.ExternalPort
GET Device.NAT.PortMapping.*.Description
...
```

Response includes instance ID `1` with all-default values:
```
Device.NAT.PortMapping.1.Enable        = "0"
Device.NAT.PortMapping.1.ExternalPort  = "0"
Device.NAT.PortMapping.1.Description   = ""
Device.NAT.PortMapping.1.InternalPort  = "0"
Device.NAT.PortMapping.1.InternalClient = ""
Device.NAT.PortMapping.1.Protocol      = ""
Device.NAT.PortMapping.2.Enable        = "1"       ← real data
Device.NAT.PortMapping.2.ExternalPort  = "8080"    ← real data
...
```

### Subtree Fetch (partial path, no wildcard)

Request:
```
GET Device.NAT.PortMapping.
```

Response does NOT include instance `1`:
```
Device.NAT.PortMapping.2.Enable        = "1"
Device.NAT.PortMapping.2.ExternalPort  = "8080"
...
```

### Result

| Query Type | Instance 1 (phantom) | Instance 2+ (real) |
|------------|----------------------|---------------------|
| Selective (`*.Enable`) | Returned (all defaults) | Returned (real data) |
| Subtree (`PortMapping.`) | NOT returned | Returned (real data) |

## Root Cause

Router-side behavioral difference between two TR-369 query mechanisms:

1. **Subtree fetch** (`Device.NAT.PortMapping.`): Router evaluates each instance
   and apparently skips instances that are "empty" or template/placeholder entries.

2. **Search path** (`Device.NAT.PortMapping.*.Enable`): Router expands `*` to ALL
   instance IDs in the table schema (including reserved/template slots) and returns
   whatever value is stored, even if the instance was never explicitly created by a
   user.

This is likely a router firmware behavior, not a USP protocol violation — the spec
does not mandate filtering empty instances from search results.

## Impact

### Current Workaround

`port_forwarding.yaml` uses `fetchAll: true` to force subtree fetch, avoiding the
phantom instance. This sacrifices the payload optimization benefit (estimated
90-97% reduction with selective get).

### Affected Scope

Any `multiInstance` definition using selective get could potentially encounter
phantom instances. Confirmed affected:

| Definition | Table Path | Phantom Observed |
|------------|-----------|------------------|
| PortForwarding | `Device.NAT.PortMapping.` | **YES** — empty instance `1` |
| PortTriggering | `Device.NAT.PortTrigger.` | Not observed (needs verification) |
| FirewallChainRules | `Device.Firewall.Chain.1.Rule.` | Not observed |

Potentially affected (not yet migrated to selective get):
- `Device.DHCPv4.Server.Pool.1.StaticAddress.` (DHCP Reservations)
- `Device.Hosts.Host.` (Connected Devices)
- `Device.WiFi.Radio.` (WiFi Radios)
- `Device.WiFi.AccessPoint.` (WiFi Access Points)
- `Device.WiFi.SSID.` (WiFi SSIDs)
- Others in `doc/usp/definitions/`

## Proposed Solution: Codegen Empty Instance Filter

### Approach

Add a **skip-empty-instance** check in the generated `_fromResponse()` factory
method for all multi-instance definitions. Before constructing each instance
object, verify that at least one field has a non-default value. If all fields
are at their default values, skip the instance.

### Why Codegen (Not App Layer)

| Option | Pros | Cons |
|--------|------|------|
| **Codegen filter** (chosen) | Automatic for all definitions; survives regen; type-aware defaults | Requires codegen update |
| App-layer filter | No codegen change | Manual per-file; overwritten on regen |
| Keep fetchAll | No code change | Loses 90-97% payload optimization |
| Router fix | Perfect solution | Out of our control; timeline unknown |

### Implementation Detail

#### Current Generated Pattern (no filter)

```dart
for (final id in sorted) {
  final p = '$basePath$id.';
  items.add(SomeModel(
    instancePath: p,
    name: (response['${p}Name'] ?? '') as String,
    enabled: response['${p}Enable'] == true || ...,
    count: int.tryParse(response['${p}Count']?.toString() ?? '') ?? 0,
  ));
}
```

#### Proposed Generated Pattern (with filter)

```dart
for (final id in sorted) {
  final p = '$basePath$id.';

  // Skip phantom instances where all parameter values are absent or default.
  // Router may return empty placeholder entries for search-path queries.
  final _vals = response.entries
      .where((e) => e.key.startsWith(p) && e.key.length > p.length);
  if (_vals.every((e) =>
      e.value == null ||
      e.value == '' ||
      e.value == '0' ||
      e.value == 0 ||
      e.value == false ||
      e.value == 'false')) {
    continue;
  }

  items.add(SomeModel(
    instancePath: p,
    name: (response['${p}Name'] ?? '') as String,
    enabled: response['${p}Enable'] == true || ...,
    count: int.tryParse(response['${p}Count']?.toString() ?? '') ?? 0,
  ));
}
```

#### Filter Logic

The filter checks all response keys under the instance prefix (`$basePath$id.`).
An instance is considered **phantom/empty** if EVERY value is one of:
- `null` — key absent from response
- `''` — empty string
- `'0'` or `0` — numeric zero (default for int fields)
- `false` or `'false'` — boolean false (default for bool fields)

An instance is **kept** if ANY value is non-default (e.g., a non-empty description,
a non-zero port, or `true`/`'1'`).

### Edge Cases

| Scenario | Behavior | Correct? |
|----------|----------|----------|
| All fields empty/zero | Skipped | YES — phantom |
| One field has real data | Kept | YES — valid partial instance |
| `Enable = false` but other fields have data | Kept | YES — disabled but real |
| `Enable = true` but everything else empty | Kept | YES — `true` ≠ default |
| Instance with only `'0'` values but they're meaningful | Kept? | Edge case — see note |

**Note on `'0'` ambiguity**: A port value of `0` is semantically "not set" in
TR-181. If a real use case needs `0` as a valid value, the filter should be
refined. For current definitions (firewall rules, port forwarding, DHCP), `0` is
always a default/invalid value.

### YAML Spec Impact

No YAML schema changes needed. The filter is applied unconditionally to all
`multiInstance` definitions. The `fetchAll` flag remains available as an escape
hatch if a definition needs to avoid selective get for other reasons.

### Codegen Source Change

In the C codegen source (`tools/usp-codegen`), the multi-instance Dart emitter
needs to insert the filter block before the `items.add(...)` call in the
`_fromResponse` factory loop. The filter is:

1. Collect all response entries whose key starts with the instance prefix
2. Check if all values are in the "default" set
3. If yes, `continue` (skip this instance)
4. If no, proceed to construct and add the instance

This applies to:
- Top-level multi-instance (`_fromResponse`)
- Nested multi-instance / children (same loop pattern)
- Flattened multi-instance (same loop pattern)

### Rollout Plan

1. **Phase 1**: Update codegen with filter → regen all existing files
2. **Phase 2**: Remove `fetchAll: true` from `port_forwarding.yaml` → verify phantom instance is filtered
3. **Phase 3**: Migrate old-format YAMLs (`multi_instance: true` + `base_path`) to new format (`multiInstance: path`) to enable selective get
4. **Phase 4**: Verify each migrated definition on real router

### Verification

After codegen update:
```bash
# Regenerate all definitions
./tools/usp-codegen \
  --definitions-dir doc/usp/definitions/firewall \
  --output-dir lib/generated \
  --language dart \
  --client-import 'package:privacy_gui/usp/services/usp_service.dart'

# Verify filter present in generated code
grep -A 8 'Skip phantom' lib/generated/port_forwarding.g.dart

# Test: remove fetchAll from port_forwarding.yaml → rebuild → verify UI
# Expected: phantom "Unnamed rule" no longer appears
```

## References

- TR-369 (USP) Section 7.3: Search Paths and Wildcards
- TR-181 Issue #2: Data Model Object Lifecycle
- BUG-002: `Device.Firewall.` top-level GET failure (related but separate)
- Phase 2C commit: `1281594e` — subscribe support, codegen v0.9.0 regen
