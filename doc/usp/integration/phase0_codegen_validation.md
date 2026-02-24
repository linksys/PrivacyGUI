# Phase 0: Codegen Validation Report

**Date:** 2026-02-24
**Branch:** `doc/usp-integration-assessment`
**Status:** Completed — codegen pipeline validated end-to-end

---

## 1. Objective

Validate the end-to-end pipeline: **YAML definition → usp-codegen → generated Dart → compilation** before proceeding with the main migration plan (Phase 1-4).

---

## 2. Validated YAML Format

After iterating on the YAML schema, the **correct working format** is:

```yaml
name: system_info              # snake_case, matches output filename
version: 1.0.0
schema_version: 1.0.0
description: Human-readable description

parameters:
  - field_name: manufacturer   # snake_case → becomes camelCase in generated code
    path: Device.DeviceInfo.Manufacturer  # FULL absolute TR-181 path
    type: string               # string | int | boolean | double
    writable: false
    description: Doc comment for generated code
```

### Key Findings on YAML Schema

| Field | Behavior |
|-------|----------|
| `name` | Used for generated class name (snake_case → PascalCase: `system_info` → `SystemInfo`) |
| `field_name` | **Required** for unique method names. Without it, all getters are named `get()` (compilation error) |
| `path` | Must be **full absolute TR-181 path** (e.g., `Device.DeviceInfo.Manufacturer`) |
| `base_path` | **Do NOT use** — codegen uses relative `path` values as-is, does NOT prepend `base_path`. Results in incomplete TR-181 paths sent to the USP client |
| `type` (top-level) | Not recognized (warning: `Unknown field 'type'`). Only `type` inside `parameters` is used |
| `type` (parameter) | `string` → Dart `String`, `int` → Dart `int` (with `int.parse()`), others TBD |
| `writable` | Recognized but no `save()` method generated in current tool version |
| `description` (parameter) | Used as `///` doc comments in generated code |
| `version` | Accepted, no visible effect on output |
| `schema_version` | Accepted, no visible effect on output |

---

## 3. Codegen CLI Reference

```bash
./tools/usp-codegen \
  --definitions-dir doc/usp/definitions \
  --output-dir lib/generated \
  --language dart \
  --dart-import 'package:privacy_gui/usp/services/usp_service.dart'
```

| Flag | Purpose | Required |
|------|---------|----------|
| `--definitions-dir` | YAML definitions directory (recursively scans) | Yes |
| `--output-dir` | Generated code output | Yes |
| `--language` | `dart` / `typescript` / `swift` | Yes |
| `--dart-import` | Custom import path for client class | No (default: `package:usp_test/services/usp_service.dart`) |
| `--client-class` | Custom client class name | No (default: `UspService`) |
| `--validate-paths` | Enable TR-181 path validation | No |
| `--json` | JSON error output (CI mode) | No |

---

## 4. Generated Code Analysis

### 4.1 What the Tool Generates

For `system_info.yaml` with 9 parameters, the tool generates [system_info.g.dart](lib/generated/system_info.g.dart):

```dart
class SystemInfo {
  final UspService _client;
  SystemInfo(this._client);

  // Batch fetch — returns raw Map
  Future<Map<String, dynamic>> fetchAll() async { ... }

  // Individual typed getters
  Future<String> getManufacturer() async { ... }
  Future<int> getUptime() async { ... }  // includes int.parse()
  // ... etc
}
```

### 4.2 Generated Code vs. CODEGEN_GUIDE Spec

| Feature | CODEGEN_GUIDE Spec | Actual Generated Code | Gap |
|---------|-------------------|----------------------|-----|
| Fetch pattern | `SystemInfo.fetch(client)` (static) → typed data class | `SystemInfo(client).fetchAll()` (instance) → `Map<String, dynamic>` | Significant |
| Typed data class | `info.manufacturer` property access | No data class; individual `getManufacturer()` methods | Significant |
| `save()` method | `wifi.save(client)` with writable fields | Not generated | Major |
| `subscribe()` | Returns typed stream | Not generated | Major |
| `add()` / `delete()` | For multi-instance definitions | Not generated | Major |
| Transforms | Computed getters from `_ext.yaml` | Not supported — `_ext.yaml` treated as regular definition (fails validation) | Major |
| Presets | `applyPreset()` method | Not generated | Major |
| Type safety | Full typed class with fields | Only return type casting (`as String`, `int.parse()`) | Moderate |
| Field naming | camelCase from `field_name` | camelCase getter methods (e.g., `getModelName`) | Minor naming diff |

### 4.3 Client Interface Compatibility

**Compatible.** The generated code calls:
- `_client.get(List<String> paths)` → matches `UspService.get()` returning `Future<Map<String, dynamic>>`
- Values accessed via `params['path'] as String` → works with `UspService._coerceValue()` which returns raw strings for non-boolean values
- `int.parse(params['path'] as String)` → correct for USP protocol (all values are strings on the wire)

---

## 5. Compilation Results

| Check | Result |
|-------|--------|
| `dart analyze lib/generated/system_info.g.dart` | **No issues found** |
| `dart analyze lib/generated/` | **No issues found** |
| Import resolution | `package:privacy_gui/usp/services/usp_service.dart` resolves correctly |

---

## 6. Transform (`_ext.yaml`) Test Results

**Not supported.** When a `system_info_ext.yaml` with transforms was placed in the same directory:

```
ERROR: Required field 'description' is missing
ERROR: Required field 'parameters' is missing
ERROR: Field 'transforms' must be an object
ERROR: Schema validation failed
```

The tool treats all `.yaml` files in the definitions directory as regular definitions. The `_ext.yaml` pairing mechanism described in CODEGEN_GUIDE is not yet implemented.

---

## 7. Conclusions and Recommendations

### What Works
1. **Basic pipeline is validated**: YAML → codegen → compilable Dart
2. **Client interface is compatible**: Generated code uses `UspService.get()` correctly
3. **Type conversion works**: `string` and `int` types generate correct Dart code
4. **Import customization works**: `--dart-import` flag properly sets the import path
5. **Recursive directory scanning works**: Definitions can be organized in subdirectories

### What Needs Enhancement (Codegen Tool)
1. **`base_path` handling**: Should prepend to relative paths but doesn't — workaround: use full absolute paths
2. **Transform support**: `_ext.yaml` not recognized — transforms must be deferred
3. **`save()` / `subscribe()` / `add()` / `delete()`**: Not generated — only `get` operations work
4. **Typed data classes**: No fetch-and-return-typed-object pattern — only raw `Map` + individual getters
5. **Static `fetch()` method**: Not generated — uses instance pattern instead

### Recommended YAML Conventions for This Project

Until the codegen tool is enhanced to match the CODEGEN_GUIDE spec, use this working format:

```yaml
name: feature_name           # snake_case
version: 1.0.0
schema_version: 1.0.0
description: "..."

parameters:
  - field_name: field_name   # snake_case → camelCase getter
    path: Device.Full.Path   # FULL absolute TR-181 path (NOT relative)
    type: string|int|boolean
    writable: false          # true has no effect currently
    description: "..."
```

### Phase 1 Readiness Assessment

| Requirement | Status |
|-------------|--------|
| YAML → Dart codegen pipeline | Ready |
| Client interface compatibility | Ready |
| Write operations (`save()`) | Not ready (codegen limitation) |
| Subscription (`subscribe()`) | Not ready (codegen limitation) |
| Transform computations | Not ready (codegen limitation) |
| Multi-instance definitions | Untested |

**Conclusion:** The project can proceed with **read-only** definition files (Phase 2 MIL-1 scope). Write operations, subscriptions, and transforms will require codegen tool enhancements or manual wrapper code.
