# Implementation Plan: A2UI Dashboard Widget Extension

**Branch**: `017-a2ui-dashboard-widgets` | **Date**: 2026-01-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/017-a2ui-dashboard-widgets/spec.md`

## Summary

Extend Dashboard Widgets via the A2UI protocol while preserving existing native components. A new independent A2UI module will be added to handle Widget registration, rendering, and data binding. The DataPathResolver abstraction layer is used to support future USP protocol compatibility.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.13+  
**Primary Dependencies**: flutter, flutter_riverpod, sliver_dashboard, generative_ui (partial concepts)  
**Storage**: SharedPreferences (Layout persistence)  
**Testing**: flutter_test, mocktail  
**Target Platform**: Web, iOS, Android  
**Project Type**: Mobile/Web Application  
**Performance Goals**: Data binding updates < 100ms  
**Constraints**: Compatible with existing Dashboard architecture, minimize code changes  
**Scale/Scope**: 3-5 predefined Widgets initially

## Constitution Check

- [x] High cohesion: A2UI code is concentrated in a single module.
- [x] Low coupling: Minimal impact on existing code.
- [x] Extensible: Supports future USP protocol.

## Project Structure

### Documentation (this feature)

```text
specs/017-a2ui-dashboard-widgets/
├── spec.md              # Feature specification
├── plan.md              # This file
└── contracts/           # (if needed)
```

### Source Code (repository root)

```text
lib/page/dashboard/
├── a2ui/                                    # A2UI Extension Module (High Cohesion)
│   ├── _a2ui.dart                          # Barrel export
│   ├── models/
│   │   ├── a2ui_widget_definition.dart     # Widget definition
│   │   ├── a2ui_template.dart              # Template structure
│   │   └── a2ui_constraints.dart           # Grid constraints
│   ├── registry/
│   │   └── a2ui_widget_registry.dart       # Registration and lookup
│   ├── resolver/
│   │   ├── data_path_resolver.dart         # Abstract interface
│   │   └── jnap_data_resolver.dart         # JNAP implementation
│   ├── renderer/
│   │   ├── a2ui_widget_renderer.dart       # Rendering entry point
│   │   └── template_builder.dart           # Template construction
│   └── presets/
│       └── preset_widgets.dart             # Predefined Widgets

├── models/
│   └── widget_spec.dart                    # [Modified]

└── factories/
    └── dashboard_widget_factory.dart       # [Modified]

test/page/dashboard/a2ui/
├── models/
│   └── a2ui_widget_definition_test.dart
├── registry/
│   └── a2ui_widget_registry_test.dart
├── resolver/
│   └── jnap_data_resolver_test.dart
└── renderer/
    └── template_builder_test.dart
```

**Structure Decision**: All A2UI-related code is concentrated in the `lib/page/dashboard/a2ui/` module, with only public interfaces exposed via the `_a2ui.dart` barrel export.

---

## Component Specifications

### 1. A2UIWidgetDefinition

```dart
class A2UIWidgetDefinition {
  final String widgetId;
  final String displayName;
  final String? description;
  final A2UIConstraints constraints;
  final A2UITemplateNode template;
  
  factory A2UIWidgetDefinition.fromJson(Map<String, dynamic> json);
  WidgetSpec toWidgetSpec();
}
```

### 2. A2UIConstraints

```dart
class A2UIConstraints {
  final int minColumns;
  final int maxColumns;
  final int preferredColumns;
  final int minRows;
  final int maxRows;
  final int preferredRows;
  
  WidgetGridConstraints toGridConstraints();
}
```

### 3. A2UITemplateNode

```dart
sealed class A2UITemplateNode {
  final String type;
  final Map<String, dynamic> props;
}

class ContainerNode extends A2UITemplateNode {
  final List<A2UITemplateNode> children;
}

class LeafNode extends A2UITemplateNode {}

sealed class PropValue {}
class StaticValue extends PropValue { final dynamic value; }
class BoundValue extends PropValue { final String path; }
```

### 4. A2UIWidgetRegistry

```dart
class A2UIWidgetRegistry {
  void register(A2UIWidgetDefinition definition);
  void registerFromJson(Map<String, dynamic> json);
  List<WidgetSpec> get widgetSpecs;
  A2UIWidgetDefinition? get(String widgetId);
  bool contains(String widgetId);
}
```

### 5. DataPathResolver

```dart
abstract class DataPathResolver {
  dynamic resolve(String path);
  ProviderListenable<dynamic>? watch(String path);
}

class JnapDataResolver implements DataPathResolver {
  // Maps abstract paths to Riverpod Providers
}
```

### 6. A2UIWidgetRenderer

```dart
class A2UIWidgetRenderer extends ConsumerWidget {
  final String widgetId;
  final DisplayMode? displayMode;
  
  @override
  Widget build(BuildContext context, WidgetRef ref);
}
```

### 7. TemplateBuilder

```dart
class TemplateBuilder {
  static Widget build({
    required A2UITemplateNode template,
    required DataPathResolver resolver,
    required WidgetRef ref,
  });
}
```

---

## Data Path Mapping

| Abstract Path | JNAP Provider | USP Path (Future) |
|:---|:---|:---|
| `router.deviceCount` | `deviceListProvider.length` | `Device.Hosts.HostNumberOfEntries` |
| `router.nodeCount` | `nodesStateProvider.nodes.length` | TBD |
| `router.wanStatus` | `healthCheckProvider.wanStatus` | `Device.IP.Interface.1.Status` |
| `wifi.ssid` | `wifiStateProvider.ssid` | `Device.WiFi.SSID.1.SSID` |

---

## Widget Definition Format

```json
{
  "widgetId": "custom_device_count",
  "displayName": "Connected Devices",
  "constraints": {
    "minColumns": 2, "maxColumns": 4, "preferredColumns": 3,
    "minRows": 1, "maxRows": 2, "preferredRows": 1
  },
  "template": {
    "type": "Column",
    "props": {"mainAxisAlignment": "center"},
    "children": [
      {"type": "AppIcon", "props": {"icon": "devices"}},
      {"type": "AppText", "props": {"text": {"$bind": "router.deviceCount"}, "variant": "headline"}},
      {"type": "AppText", "props": {"text": "Connected Devices", "variant": "label"}}
    ]
  }
}
```

---

## Implementation Phases

| Phase | Content | Estimate |
|:---|:---|:---:|
| **Phase 1** | Models (Definition, Constraints, Template) | 2hr |
| **Phase 2** | Registry + Presets | 1hr |
| **Phase 3** | DataPathResolver (JNAP) | 1hr |
| **Phase 4** | Renderer + TemplateBuilder | 3hr |
| **Phase 5** | WidgetSpec & Factory Integration | 1hr |
| **Phase 6** | Tests | 1hr |
| **Total** | | 9hr |

---

## Modifications to Existing Code

### WidgetSpec

```dart
// lib/page/dashboard/models/widget_spec.dart
class WidgetSpec {
  final Map<DisplayMode, WidgetGridConstraints>? constraints;
  final WidgetGridConstraints? defaultConstraints; // [NEW]
  
  bool get supportsDisplayModes => constraints != null && constraints!.length > 1; // [NEW]
  
  WidgetGridConstraints getConstraints(DisplayMode mode) {
    return constraints?[mode] ?? defaultConstraints ?? _fallback;
  }
}
```

### DashboardWidgetFactory

```dart
// lib/page/dashboard/factories/dashboard_widget_factory.dart
import '../a2ui/_a2ui.dart';

static Widget? buildAtomicWidget(String id, {DisplayMode? displayMode, WidgetRef? ref}) {
  final native = _buildNativeWidget(id, displayMode);
  if (native != null) return native;
  
  if (ref != null) {
    final registry = ref.read(a2uiWidgetRegistryProvider);
    if (registry.contains(id)) {
      return A2UIWidgetRenderer(widgetId: id, displayMode: displayMode);
    }
  }
  return null;
}
```

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| DataPathResolver Abstraction | USP compatibility requirement | Direct Provider binding cannot adapt to future protocol changes |
