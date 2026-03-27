# Feature Branch Change Report: Apps Page & Package Dashboard Widget

**Branch**: `feature/apps-page` vs `dev-2.2.1`
**Commits**: 4 + 3 (directive & QR)
**Files**: 24 changed (+1,800 / -38 lines)
**Date**: 2026-03-25 (updated 2026-03-26)

---

## 1. Feature Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   feature/apps-page                         │
├────────────────────┬────────────────────────────────────────┤
│   Feature A        │   Feature B                            │
│   Apps Page        │   Package Dashboard Widget             │
│   (5 new files)    │   (8 new + 6 modified files)           │
├────────────────────┼────────────────────────────────────────┤
│ • Display router-  │ • opkg packages deploy dashboard cards │
│   installed system │ • JSON template → UiTreeBuilder render │
│   & user apps      │ • $bind data binding + SSE live update │
│ • 5s poll detect   │ • $transform / $compute / $visible     │
│   install/remove   │ • AppQrCode component (WiFi QR)        │
│ • NEW badge 60s    │ • HTTP/CGI data source + polling        │
│ • Store btn + JWT  │ • BridgeRequestThrottler (max 3 conc.) │
│                    │ • User-initiated Add (not auto-show)   │
│                    │ • 10s poll detect install/remove       │
└────────────────────┴────────────────────────────────────────┘
```

---

## 2. Architecture Diagrams

### 2.1 Overall Data Flow

```
Router (lighttpd)                    LinksysNow (Flutter Web)
─────────────────                    ────────────────────────

  /api/apps.json ──────GET/5s──────→ UspAppsService
  (app_util.lua)                         │
       │                                 ├→ UspAppsNotifier (Apps Page)
       │                                 │    ├ polling 5s
       │                                 │    ├ NEW badge (60s auto-clear)
       │                                 │    └ install/remove detection
       │                                 │
  /api/apps.json ──────GET/10s─────→ PackageWidgetLoader (Dashboard)
  + widget entries                       │
       │                                 ├→ allWidgetSpecsProvider
       ▼                                 │    └ merge native 17 + package specs
  /api/widgets/                          │
  {id}.json ───────GET (per widget)──┘   ├→ PackageWidgetDataProvider
       │                                 │    └ per-widget USP data store
       │                                 │
       ▼                                 ▼
  Widget Template JSON            PackageWidgetRenderer
                                    │
                                    ├→ Data Source (mutually exclusive):
                                    │   ├ subscription → USP GET + SSE
                                    │   └ dataSource   → HTTP/CGI + poll
                                    │         │
                                    │   BridgeRequestThrottler (max 3)
                                    │         │
                                    ├→ resolveBindings
                                    │   ├ $bind → data lookup
                                    │   ├ $transform → pipeline / fn
                                    │   ├ $compute → multi-value ops
                                    │   └ $visible → show/hide nodes
                                    ├→ UiTreeBuilder.build()
                                    │   └ +PackageWidgetBuilders (AppQrCode)
                                    └→ AppCard + ScrollView
```

### 2.2 Package Widget Lifecycle

```
                        ┌──────────────────────────┐
  opkg install ────────→│  Router updates           │
                        │  /api/apps.json           │
                        └──────────┬───────────────┘
                                   │ ~10-15s router delay
                                   ▼
                        ┌──────────────────────────┐
                        │  PackageWidgetLoader      │
                        │  polls every 10s          │
                        │  detects new widget entry │
                        └──────────┬───────────────┘
                                   │
                    ┌──────────────┼──────────────────┐
                    ▼              ▼                    ▼
           allWidgetSpecs    Settings Panel       Dashboard View
           Provider updates  shows in "Hidden     (no auto-add)
                             Widgets" list
                                   │
                              User taps "Add"
                                   │
                                   ▼
                        ┌──────────────────────────┐
                        │  UspLayoutController      │
                        │  .addWidget(id, spec:)    │
                        │  → persist to SharedPrefs │
                        └──────────┬───────────────┘
                                   │
                                   ▼
                        ┌──────────────────────────┐
                        │  PackageWidgetRenderer    │
                        │  1. USP GET → initial data│
                        │  2. SSE subscribe         │
                        │  3. resolveBindings       │
                        │  4. UiTreeBuilder.build() │
                        │  5. dispose → SSE cleanup │
                        └──────────────────────────┘
```

### 2.3 Package Widget Removal Flow

```
  opkg remove ─────→ Router updates /api/apps.json
                          │
                          ▼
              PackageWidgetLoader (10s poll)
              detects key set difference
                          │
              ┌───────────┼───────────────┐
              ▼           ▼               ▼
  state = AsyncData   controller      dataNotifier
  (freshTemplates)    .removeWidget()  .clear()
              │           │               │
              ▼           ▼               ▼
  allWidgetSpecs      Card removed    Data cleaned
  updates → panel     from grid       from memory
  reflects removal
              │
              ▼
  PackageWidgetRenderer.dispose()
  → SSE cleanup function called
```

### 2.4 Template JSON → Widget Transformation

```
Widget Template JSON (from router)     resolveBindings()          UiTreeBuilder
──────────────────────────────────     ─────────────────          ──────────────

{                                      {
  "type": "AppCard",                     "type": "AppCard",
  "properties": {                        "props": {               ← rename
    "padding": 16                          "padding": 16,
  },                          ──────→      "children": [...]      ← merge
  "children": [                          }
    {"type":"AppText",                   }
     "properties": {
       "text": {"$bind":                text: "3"                 ← $bind
         "Device.Hosts.Count"}
     }}
  ]
}
                                                    │
                                                    ▼
                                         ┌───────────────────┐
                                         │ AppCard            │
                                         │  └ ScrollView      │
                                         │    └ Column        │
                                         │      └ AppText("3")│
                                         └───────────────────┘
```

### 2.5 Template Directive System

Four directives are evaluated recursively during `resolveBindings()`:

```
 Template JSON property value
           │
           ▼
 ┌─ Is Map with "$bind"?       ──→ Lookup dataMap[path] → String
 ├─ Is Map with "$transform"?  ──→ Pipeline / fn → transformed value
 ├─ Is Map with "$compute"?    ──→ Multi-value computation → result
 ├─ Is Map with "$visible"?    ──→ Truthy / condition → show or _hidden
 ├─ Is Map (other)?            ──→ Recurse _resolveMap
 ├─ Is List?                   ──→ Recurse each item, filter _hidden
 └─ Primitive?                 ──→ Pass through
```

Directives can be **nested** — a `$compute` can contain `$bind` and `$transform` values:

```json
{
  "$compute": {
    "op": "template",
    "format": "{mem} used",
    "values": {
      "mem": {
        "$transform": {
          "input": {"$bind": "Device.Mem.Used"},
          "ops": [{"type": "suffix", "value": " MB"}]
        }
      }
    }
  }
}
```
→ `"512 MB used"`

---

## 3. Template Directive Reference (UI JSON)

### 3.1 `$bind` — Single Value Lookup

Resolves a USP path from the widget's data map. Returns `"--"` if missing.

```json
{"$bind": "Device.WiFi.SSID.1.SSID"}
```
→ `"MyNetwork"`

Usage in template:
```json
{"type": "AppText", "properties": {"text": {"$bind": "Device.Hosts.HostNumberOfEntries"}}}
```

### 3.2 `$transform` — Single Value Pipeline

Two modes: **function** (call `Transforms.*`) or **pipeline** (chain ops).

#### Function Mode

```json
{
  "$transform": {
    "input": {"$bind": "Device.WiFi.Radio.1.MaxBitRate"},
    "fn": "formatBandwidth",
    "precision": 2
  }
}
```
→ `"600.00 Mbps"`

Available functions:

| fn | Input | Output Example |
|----|-------|----------------|
| `formatBandwidth` | `double` (Mbps) | `"600.00 Mbps"` / `"2.40 Gbps"` |
| `formatDuration` | `int` (seconds) | `"1h 30m 45s"` |
| `formatBytes` | `int` (bytes) | `"1.0 GB"` |
| `formatPercent` | `double` | `"85.7%"` |
| `formatNumber` | `double` | `"1,234,567"` |
| `formatSpeed` | `double` (Kbps) | `"500.00 Kbps"` / `"1.50 Mbps"` |
| `cidrToNetmask` | `int` | `"255.255.255.0"` |

#### Pipeline Mode

```json
{
  "$transform": {
    "input": {"$bind": "Device.DeviceInfo.MemoryStatus.Total"},
    "ops": [
      {"type": "divide", "by": 1048576},
      {"type": "round", "precision": 0},
      {"type": "suffix", "value": " MB"}
    ]
  }
}
```
→ `"2.0 MB"`

Available ops:

| Op | Params | Description |
|----|--------|-------------|
| `divide` | `by: num` | `current / by` |
| `multiply` | `by: num` | `current * by` |
| `add` | `value: num` | `current + value` |
| `round` | `precision: int` | Round to N decimal places |
| `floor` | — | Floor to integer |
| `ceil` | — | Ceil to integer |
| `prefix` | `value: String` | Prepend string |
| `suffix` | `value: String` | Append string |
| `map` | `mappings: Map`, `default` | Value lookup table |
| `threshold` | `ranges: [{min, max, label}]`, `default` | Numeric range → label |
| `fn` | `name: String` | Call a Transforms function inline |

**`map` example** — translate enum to display text:
```json
{
  "$transform": {
    "input": {"$bind": "Device.WiFi.Radio.1.OperatingFrequencyBand"},
    "ops": [{"type": "map", "mappings": {"2.4GHz": "2.4 GHz", "5GHz": "5 GHz"}, "default": "Unknown"}]
  }
}
```

**`threshold` example** — signal strength to label:
```json
{
  "$transform": {
    "input": {"$bind": "Device.WiFi.SSID.1.Stats.SignalStrength"},
    "ops": [{
      "type": "threshold",
      "ranges": [
        {"min": -50, "max": 0, "label": "Excellent"},
        {"min": -70, "max": -51, "label": "Good"},
        {"min": -90, "max": -71, "label": "Fair"}
      ],
      "default": "Poor"
    }]
  }
}
```

### 3.3 `$compute` — Multi-Value Computation

Combines multiple data sources into a single result.

| Op | Params | Formula | Returns |
|----|--------|---------|---------|
| `percent_used` | `total`, `free` | `(total-free)/total*100` | `"85.0"` |
| `subtract` | `a`, `b` | `a - b` | number |
| `ratio` | `numerator`, `denominator` | `num / denom` | number |
| `template` | `format`, `values` | `{key}` → resolved value | string |

**`percent_used` example** — memory usage:
```json
{
  "$compute": {
    "op": "percent_used",
    "total": {"$bind": "Device.DeviceInfo.MemoryStatus.Total"},
    "free": {"$bind": "Device.DeviceInfo.MemoryStatus.Free"}
  }
}
```
→ `"75.0"`

**`template` example** — WiFi QR Code string:
```json
{
  "$compute": {
    "op": "template",
    "format": "WIFI:T:{mode};S:{ssid};P:{pass};;",
    "values": {
      "ssid": {"$bind": "Device.WiFi.SSID.1.SSID"},
      "pass": {"$bind": "Device.WiFi.AccessPoint.1.Security.KeyPassphrase"},
      "mode": {"$bind": "Device.WiFi.AccessPoint.1.Security.ModeEnabled"}
    }
  }
}
```
→ `"WIFI:T:WPA2-Personal;S:MyNetwork;P:secret123;;"`

### 3.4 `$visible` — Conditional Show/Hide

Node-level directive. When false, the entire node (and its children) is removed.

**Truthy mode** — show if value is non-empty/non-zero:
```json
{
  "type": "AppText",
  "$visible": {"$bind": "Device.X_LNK.GuestNetwork.Enabled"},
  "properties": {"text": "Guest network is active"}
}
```
Falsy values: `null`, `""`, `"false"`, `"0"`, `"--"`, `0`

**Condition mode** — compare values:
```json
{
  "type": "AppText",
  "$visible": {
    "condition": "neq",
    "value": {"$bind": "Device.WiFi.AccessPoint.1.Security.ModeEnabled"},
    "expected": "None"
  },
  "properties": {"text": "Security enabled"}
}
```

Available conditions:

| Condition | Description |
|-----------|-------------|
| `eq` | `value == expected` (string compare) |
| `neq` | `value != expected` |
| `gt` | `value > expected` (numeric) |
| `gte` | `value >= expected` |
| `lt` | `value < expected` |
| `lte` | `value <= expected` |
| `contains` | `value.contains(expected)` |
| `in` | `expected` is List, check if value is in it |

### 3.5 `AppQrCode` — QR Code Component

Custom builder registered via `PackageWidgetBuilders`. Renders QR codes using `qr_flutter`.

```json
{
  "type": "AppQrCode",
  "properties": {
    "data": "WIFI:T:WPA2-Personal;S:MyNetwork;P:secret123;;",
    "size": 180
  }
}
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `data` | String | `""` | QR code content (empty shows placeholder) |
| `size` | num | `200` | Width and height in pixels |

### 3.6 Complete Widget Template Example — WiFi QR Code Card

```json
{
  "widgetId": "pkg_wifi_qr",
  "displayName": "WiFi QR Code",
  "constraints": {
    "minColumns": 3, "maxColumns": 4,
    "preferredColumns": 3, "preferredRows": 3
  },
  "subscription": {
    "paths": ["Device.WiFi.SSID.1.", "Device.WiFi.AccessPoint.1.Security."],
    "notifType": "ValueChange"
  },
  "template": {
    "type": "AppCard",
    "properties": {"padding": 16},
    "children": [
      {
        "type": "AppText",
        "properties": {"text": "WiFi QR Code", "variant": "titleSmall"}
      },
      {"type": "AppGap", "properties": {"size": "md"}},
      {
        "type": "AppQrCode",
        "properties": {
          "data": {
            "$compute": {
              "op": "template",
              "format": "WIFI:T:{mode};S:{ssid};P:{pass};;",
              "values": {
                "ssid": {"$bind": "Device.WiFi.SSID.1.SSID"},
                "pass": {"$bind": "Device.WiFi.AccessPoint.1.Security.KeyPassphrase"},
                "mode": {"$bind": "Device.WiFi.AccessPoint.1.Security.ModeEnabled"}
              }
            }
          },
          "size": 180
        }
      },
      {"type": "AppGap", "properties": {"size": "sm"}},
      {
        "type": "AppText",
        "properties": {
          "text": {"$bind": "Device.WiFi.SSID.1.SSID"},
          "variant": "bodySmall"
        }
      }
    ]
  }
}
```

### 3.7 Complete Widget Template Example — Memory Usage Card

```json
{
  "widgetId": "pkg_mem_usage",
  "displayName": "Memory Usage",
  "constraints": {"minColumns": 2, "maxColumns": 3, "preferredColumns": 2, "preferredRows": 2},
  "subscription": {
    "paths": ["Device.DeviceInfo.MemoryStatus."],
    "notifType": "ValueChange"
  },
  "template": {
    "type": "AppCard",
    "properties": {"padding": 16},
    "children": [
      {"type": "AppText", "properties": {"text": "Memory", "variant": "titleSmall"}},
      {"type": "AppGap", "properties": {"size": "sm"}},
      {
        "type": "AppText",
        "properties": {
          "text": {
            "$compute": {
              "op": "template",
              "format": "{pct}% used",
              "values": {
                "pct": {
                  "$compute": {
                    "op": "percent_used",
                    "total": {"$bind": "Device.DeviceInfo.MemoryStatus.Total"},
                    "free": {"$bind": "Device.DeviceInfo.MemoryStatus.Free"}
                  }
                }
              }
            }
          },
          "variant": "headlineMedium"
        }
      },
      {
        "type": "AppText",
        "properties": {
          "text": {
            "$compute": {
              "op": "template",
              "format": "{free} free / {total} total",
              "values": {
                "free": {
                  "$transform": {
                    "input": {"$bind": "Device.DeviceInfo.MemoryStatus.Free"},
                    "fn": "formatBytes"
                  }
                },
                "total": {
                  "$transform": {
                    "input": {"$bind": "Device.DeviceInfo.MemoryStatus.Total"},
                    "fn": "formatBytes"
                  }
                }
              }
            }
          },
          "variant": "bodySmall"
        }
      },
      {
        "$visible": {"$bind": "Device.DeviceInfo.MemoryStatus.Warning"},
        "type": "AppText",
        "properties": {"text": "Low memory warning", "variant": "labelSmall"}
      }
    ]
  }
}
```

---

## 4. Commits

### Commit 1: `9eec101b`

**fix: dashboard orchestrator exponential backoff for provider retry**

Added exponential backoff to the dashboard orchestrator's provider retry
mechanism to prevent rapid retries on failure.

### Commit 2: `3306cdbe`

**feat: add Apps page displaying router-installed applications**

| File | Type | Description |
|------|------|-------------|
| `lib/page/apps/models/app_event.dart` | New | `AppEvent` model — opkg install/remove/update event |
| `lib/page/apps/models/app_info_ui_model.dart` | New | `AppInfoUIModel` + `AppCategory` (system/user) |
| `lib/page/apps/services/usp_apps_service.dart` | New | `UspAppsService` — fetch `/api/apps.json`, link normalization, icon/color mapping, `_safeList` for empty Map handling |
| `lib/page/apps/providers/usp_apps_notifier.dart` | New | `UspAppsNotifier` — autoDispose AsyncNotifier, 5s polling, NEW badge with 60s auto-clear |
| `lib/page/apps/views/usp_apps_view.dart` | New | `UspAppsView` — responsive GridView (desktop 3-col / mobile 1-col), loading/error/empty states |
| `lib/page/shell/usp_top_bar.dart` | Modified | Added Apps icon button in top bar (visible when logged in) |
| `lib/route/constants.dart` | Modified | Added `uspApps` route constant |
| `lib/route/route_usp_dashboard.dart` | Modified | Added `UspAppsView` route entry |
| `lib/route/router_provider.dart` | Modified | Pass `loginType` to `_prepare()` to avoid disposed provider issue |

### Commit 3: `52488343`

**feat: add Store button with JWT token on Apps page**

Added Store button to `UspAppsView` that opens `{origin}/app-store/?token=$jwt`
for authenticated access to the router's app store.

### Commit 4: `81daccd5`

**feat: package dashboard widget system & overflow fixes**

| File | Type | Description |
|------|------|-------------|
| `models/package_widget_template.dart` | New | `PackageWidgetTemplate` (Equatable) + `WidgetSubscriptionConfig`, `toWidgetSpec()` conversion |
| `utils/bind_resolver.dart` | New | Recursive `$bind` resolution + `properties→props` rename + **`children` merge into `props`** (fixes UiTreeBuilder empty render bug) |
| `providers/package_widget_loader.dart` | New | `AsyncNotifier`, fetch apps.json → filter widget entries → fetch templates, **10s polling** with install/remove detection |
| `providers/all_widget_specs_provider.dart` | New | Merge native 17 + package specs, graceful degradation on loading/error |
| `providers/package_widget_data_provider.dart` | New | `StateNotifier.family` keyed by widgetId, `setAll` / `updatePath` / `clear` |
| `widgets/package_widget_renderer.dart` | New | Full lifecycle: USP GET → SSE subscribe → $bind resolve → **split root card + internal scroll** → dispose cleanup |
| `orchestrator/dashboard_orchestrator.dart` | Modified | Trigger `packageWidgetLoaderProvider` in `_buildImpl` |
| `providers/usp_layout_controller.dart` | Modified | `pkg_` prefix whitelist in layout validation + `addWidget(id, {WidgetSpec? spec})` |
| `views/.../usp_layout_settings_panel.dart` | Modified | `UspWidgetSpecs.all` → `allWidgetSpecsProvider` |
| `views/usp_sliver_dashboard_view.dart` | Modified | `PackageWidgetRenderer` fallback + `SizedBox.expand` for all cards + package spec resize fallback |
| `devices/cards/usp_connected_devices_card.dart` | Modified | Fixed header + `Expanded(SingleChildScrollView)` scrollable device list |

---

## 5. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **User-initiated Add** | Installing a package ≠ auto-showing a card. Widgets appear in settings panel "Hidden Widgets" for user to manually add. Prevents unwanted dashboard clutter. |
| **Independent fetch** | `PackageWidgetLoader` does not reuse `UspAppsNotifier` (autoDispose — destroyed when Apps page is closed). Dashboard needs persistent template cache. |
| **`properties→props` + children merge** | Widget JSON uses `properties` + sibling `children`. UiTreeBuilder reads `child['props']['children']`. `bind_resolver` normalizes both in a single recursive pass. |
| **Passthrough normalizer** | 10-line local `_PassthroughNormalizer` avoids importing from `generative_ui` package. Only promotes `child→children`. |
| **Directive pure functions** | `template_directives.dart` contains only pure functions with `resolveValue` callback — no dependency on provider, widget, or data map. Testable in isolation (96.5% line coverage). |
| **`_hidden` sentinel** | `$visible=false` returns `{'_hidden': true}` instead of `null`. Avoids changing `_resolveMap` return type to nullable. List processing filters hidden items via `.where()`. |
| **AppQrCode in PrivacyGUI, not ui_kit** | `qr_flutter` dependency is PrivacyGUI-only. Builder map merge (`...PackageWidgetBuilders.all`) extends UiTreeBuilder without modifying ui_kit_library. |
| **`pkg_` prefix whitelist** | Layout validation allows `pkg_`-prefixed IDs to pass (package specs load asynchronously, not available during layout init). |
| **SizedBox.expand** | Applied at dashboard view level for ALL cards (native + package) to ensure every card fills its grid cell. |
| **Internal scroll pattern** | Package widget: AppCard shell + `SingleChildScrollView` inside. Connected Devices native card: fixed header + `Expanded(SingleChildScrollView)` for device list. |
| **10s polling** | Reduced from 30s to match Apps page detection speed. `/api/apps.json` is a lightweight local HTTP request. |

---

## 6. File Structure

```
lib/page/
├── apps/                              ← Feature A: Apps Page
│   ├── models/
│   │   ├── app_event.dart                 AppEvent (installed/removed/updated)
│   │   └── app_info_ui_model.dart         AppInfoUIModel + AppCategory
│   ├── providers/
│   │   └── usp_apps_notifier.dart         UspAppsNotifier (5s poll, NEW badge)
│   ├── services/
│   │   └── usp_apps_service.dart          fetch /api/apps.json + link normalize
│   └── views/
│       └── usp_apps_view.dart             GridView + _AppGridCard + Store btn
│
├── dashboard/                         ← Feature B: Package Widget
│   ├── builders/
│   │   └── package_widget_builders.dart   AppQrCode + custom builders registry
│   ├── models/
│   │   ├── http_data_source_config.dart   HttpDataSourceConfig (planned)
│   │   └── package_widget_template.dart   PackageWidgetTemplate + toWidgetSpec
│   ├── providers/
│   │   ├── all_widget_specs_provider.dart  native 17 + package merge
│   │   ├── package_widget_data_provider.dart  per-widget USP data
│   │   └── package_widget_loader.dart     fetch + cache + 10s poll
│   ├── utils/
│   │   ├── bind_resolver.dart             directive dispatch + props normalize
│   │   ├── http_data_source.dart          HTTP fetch + JSON mapping (planned)
│   │   └── template_directives.dart       $transform / $compute / $visible
│   └── widgets/
│       └── package_widget_renderer.dart   full lifecycle renderer
│
core/usp/services/
│   └── bridge_request_throttler.dart      Centralized request queue (planned)
```

---

## 7. Bugs Fixed

| Bug | Root Cause | Fix |
|-----|-----------|-----|
| Package widget renders empty | `bind_resolver` renamed `properties→props` but left `children` as sibling at root level. UiTreeBuilder reads `props['children']` → null. | `_resolveMap` merges `children` into the `props` map after rename. |
| Card background doesn't fill grid cell | `SingleChildScrollView` wrapping entire card gave unconstrained height → AppCard only took natural content height. | Split root card from children; AppCard shell fills cell via `SizedBox.expand`, only inner content scrolls. |
| Connected Devices card overflow (95px) | Native card's Column expands all device rows without height constraint. | Fixed header + `Expanded(SingleChildScrollView)` for the device list section. |
| Dashboard card removal delay ~1min | `PackageWidgetLoader` polled every 30s. | Reduced to 10s polling interval. |

---

## 8. Reused Components

| Component | Source | Usage |
|-----------|--------|-------|
| `UiTreeBuilder` + `UiKitCatalog.standardBuilders` | ui_kit_library | JSON → Widget rendering engine (60+ registered components) |
| `Transforms` (10 static methods) | lib/generated/transforms.g.dart | `$transform fn` mode runtime calls (formatBandwidth, formatBytes, etc.) |
| `QrImageView` | qr_flutter ^4.0.0 | QR code rendering for AppQrCode builder |
| `SseManager.subscribe()` | lib/core/usp/ | Dynamic SSE subscription + async cleanup function |
| `UspService.get()` | lib/core/usp/ | USP GET with wildcard path support |
| `WidgetSpec` / `LayoutItemFactory` / `DashboardController` | lib/page/dashboard/ | Dashboard grid layout system |
| `UiKitPageView.withSliver` | ui_kit_library | Apps page scaffold with pull-to-refresh |
| `AppCard`, `AppText`, `AppButton`, `AppBadge` | ui_kit_library | UI components used across both features |

---

## 9. Planned — HTTP DataSource & Request Throttler

### 9.1 Problem Statement

**Current concurrency bug**: Dashboard startup fires 6+ USP GET requests simultaneously
(3 domain providers × 2 parallel internal GETs + N package widgets). Router bridge has
limited resources and HTTP/1.1 allows only 6 concurrent connections per origin. Under load,
some requests timeout → partial data missing on dashboard.

**New requirement**: Package widgets need HTTP/CGI data sources (e.g., `/cgi-bin/whereismyip.cgi`)
in addition to USP. Adding more concurrent HTTP requests without throttling will worsen the
overload problem.

**Solution**: A centralized `BridgeRequestThrottler` that governs ALL outbound requests to the
router — USP GET, HTTP DataSource, and future request types — with concurrency limiting,
request queuing, and URL deduplication.

### 9.2 Architecture

```
Dashboard Init
     │
     ├─ systemInfoProvider ─── usp.get() ──┐
     ├─ devicesProvider ────── usp.get() ──┤
     ├─ ethernetProvider ───── usp.get() ──┤      ┌──────────────────────────┐
     │                                      ├─────→│  BridgeRequestThrottler   │
     ├─ PkgWidget A ────────── usp.get() ──┤      │                          │
     ├─ PkgWidget B (USP) ──── usp.get() ──┤      │  maxConcurrent = 3       │
     ├─ PkgWidget C (HTTP) ─── http.get()──┤      │  stagger = 100ms         │
     └─ PkgWidget D (HTTP) ─── http.get()──┘      │  dedup by cacheKey       │
                                                   │  retry with backoff      │
                                                   │                          │
                                                   │  ┌────────┐  ┌────────┐  │
                                                   │  │ Queue   │  │ Cache  │  │
                                                   │  │ FIFO    │  │ TTL    │  │
                                                   │  └───┬────┘  └───┬────┘  │
                                                   └──────┴──────────┴────────┘
                                                          │
                                                    max 3 concurrent
                                                          │
                                               ┌──────────┴──────────┐
                                               ▼                      ▼
                                          USP Bridge             CGI Endpoints
                                       /api/v1/usp          /cgi-bin/*.cgi
```

### 9.3 New Files

```
lib/core/usp/services/
  bridge_request_throttler.dart      -- Centralized request queue + concurrency limiter

lib/page/dashboard/
  models/
    http_data_source_config.dart     -- HttpDataSourceConfig model (parsed from JSON)
  utils/
    http_data_source.dart            -- HTTP fetch + JSON→flat map mapping logic
```

### 9.4 Modified Files

| File | Changes |
|------|---------|
| `models/package_widget_template.dart` | Add optional `HttpDataSourceConfig? dataSource` field + `fromJson` parsing |
| `widgets/package_widget_renderer.dart` | Add HTTP fetch branch + polling Timer, use throttler for both USP and HTTP |
| `core/usp/services/usp_service.dart` | Wrap `get()` through throttler (opt-in, backward compatible) |

### 9.5 Step 1: `BridgeRequestThrottler`

**Path**: `lib/core/usp/services/bridge_request_throttler.dart`

Singleton that serializes all outbound requests to the router with configurable concurrency.

```dart
class BridgeRequestThrottler {
  BridgeRequestThrottler({
    this.maxConcurrent = 3,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.defaultCacheTtl = const Duration(seconds: 5),
  });

  final int maxConcurrent;
  final Duration staggerDelay;
  final Duration defaultCacheTtl;

  /// Enqueue a request. Identical cacheKeys within TTL return cached result.
  /// Returns the result of [action] when it completes.
  Future<T> enqueue<T>({
    required String cacheKey,
    required Future<T> Function() action,
    Duration? cacheTtl,
    RequestPriority priority = RequestPriority.normal,
  });
}

enum RequestPriority { high, normal, low }
```

**Key behaviors**:

| Behavior | Detail |
|----------|--------|
| **Concurrency limit** | At most `maxConcurrent` (default 3) requests in-flight. Remaining queued FIFO. |
| **Stagger delay** | 100ms pause between dispatching queued requests to avoid burst. |
| **URL dedup** | Same `cacheKey` within `cacheTtl` shares one in-flight Future (no duplicate requests). |
| **Priority** | `high` = auth/SSE, `normal` = domain providers, `low` = package widgets / HTTP datasource. |
| **Retry** | NOT in throttler — callers handle their own retry (existing `_withAuthRetry` in UspService). |
| **Cache** | Short-lived (5s default). Prevents duplicate GETs when multiple widgets request overlapping paths. |
| **Connection budget** | 3 slots for data + 3 reserved for SSE/auth/etc = 6 total (browser HTTP/1.1 limit). |

**Why 3 concurrent, not 6?** The browser caps at 6 connections per origin. We need to reserve
slots for: (1) SSE persistent connection, (2) auth refresh, (3) bridge subscription API.
Leaving 3 for data requests ensures SSE/auth never get blocked.

### 9.6 Step 2: `HttpDataSourceConfig` Model

**Path**: Inline in `lib/page/dashboard/models/package_widget_template.dart`

```dart
class HttpDataSourceConfig extends Equatable {
  final String type;                          // "http" (for future extensibility)
  final String url;                           // "/cgi-bin/whereismyip.cgi"
  final String method;                        // "POST" (default) or "GET"
  final Map<String, dynamic>? body;           // POST body (optional)
  final int refreshInterval;                  // seconds, 0 = no polling
  final Map<String, String> mapping;          // dot-path → virtual key mapping

  const HttpDataSourceConfig({
    this.type = 'http',
    required this.url,
    this.method = 'POST',
    this.body,
    this.refreshInterval = 0,
    required this.mapping,
  });

  factory HttpDataSourceConfig.fromJson(Map<String, dynamic> json) {
    return HttpDataSourceConfig(
      type: json['type'] as String? ?? 'http',
      url: json['url'] as String,
      method: json['method'] as String? ?? 'POST',
      body: json['body'] as Map<String, dynamic>?,
      refreshInterval: json['refreshInterval'] as int? ?? 0,
      mapping: Map<String, String>.from(json['mapping'] as Map),
    );
  }

  @override
  List<Object?> get props => [type, url, method, body, refreshInterval, mapping];
}
```

**Key design choices**:

| Choice | Rationale |
|--------|-----------|
| **Default `POST`** | Router CGI actions typically use POST with `{"action": "xxx"}` body |
| **`type: "http"`** | Future extensibility — could add `"websocket"`, `"grpc"` etc. |
| **`refreshInterval` as int (seconds)** | Matches router CGI convention; 0 = fetch once, no polling |
| **No auth token** | CGI endpoints are no-auth actions (lookup/result); no JWT/session needed |
| **Mapping uses dot-notation** | `"data.query"` not `"$.data.query"` — simpler, matches JS convention |

### 9.7 Step 3: Modify `PackageWidgetTemplate`

Add optional `dataSource` field. `dataSource` and `subscription` are mutually exclusive —
if both present, `subscription` takes precedence (USP is the primary data source).

```dart
class PackageWidgetTemplate extends Equatable {
  // ... existing fields ...
  final HttpDataSourceConfig? dataSource;     // NEW

  factory PackageWidgetTemplate.fromJson(Map<String, dynamic> json) {
    return PackageWidgetTemplate(
      // ... existing parsing ...
      dataSource: json['dataSource'] != null
          ? HttpDataSourceConfig.fromJson(json['dataSource'] as Map<String, dynamic>)
          : null,
    );
  }
}
```

### 9.8 Step 4: Modify `PackageWidgetRenderer` — HTTP Branch

`_initializeData()` gains a second branch for HTTP data sources.

**Data flow**: HTTP JSON response → `_applyMapping()` → flat `Map<String, dynamic>` →
`PackageWidgetDataProvider.setAll()` → `resolveBindings($bind)` → `UiTreeBuilder` (unchanged).

```dart
Timer? _pollTimer;

Future<void> _initializeData() async {
  final template = widget.template;

  if (template.dataSource != null) {
    // ── HTTP data source ──
    await _fetchHttpData(template.dataSource!);
    _startHttpPolling(template.dataSource!);
  } else if (template.subscription != null) {
    // ── USP data source (existing logic, unchanged) ──
    await _fetchUspData(template.subscription!);
    await _subscribeSse();
  }

  if (mounted) setState(() => _initialFetchDone = true);
}
```

**HTTP fetch implementation**:

```dart
Future<void> _fetchHttpData(HttpDataSourceConfig ds) async {
  try {
    // Security: only allow local CGI paths (no external URLs)
    final uri = Uri.parse(ds.url);
    if (uri.hasAuthority || !ds.url.startsWith('/cgi-bin/')) {
      logger.w('[HTTP][PkgWidget] Blocked non-local URL: ${ds.url}');
      return;
    }

    final targetUrl = Uri.parse('${Uri.base.origin}${ds.url}');
    final http.Response response;

    if (ds.method.toUpperCase() == 'GET') {
      response = await http.get(targetUrl);
    } else {
      response = await http.post(
        targetUrl,
        headers: {'Content-Type': 'application/json'},
        // No auth token — CGI endpoints are no-auth actions
        body: ds.body != null ? jsonEncode(ds.body) : null,
      );
    }

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final mapped = _applyMapping(json, ds.mapping);
      if (!mounted) return;
      ref.read(packageWidgetDataProvider(widget.template.widgetId).notifier)
          .setAll(mapped);
    } else {
      logger.w('[HTTP][PkgWidget] ${ds.url} returned ${response.statusCode}');
    }
  } catch (e) {
    logger.w('[HTTP][PkgWidget] Fetch error for ${widget.template.widgetId}: $e');
  }
}
```

**Mapping: JSON response → flat data map**:

```dart
/// Transform JSON response into flat map via dot-notation mapping.
///
/// Example:
///   json = {"data": {"query": "1.2.3.4", "city": "Taipei"}}
///   mapping = {"ip": "data.query", "city": "data.city"}
///   → {"ip": "1.2.3.4", "city": "Taipei"}
Map<String, dynamic> _applyMapping(
  Map<String, dynamic> json,
  Map<String, String> mapping,
) {
  final result = <String, dynamic>{};
  for (final entry in mapping.entries) {
    result[entry.key] = _resolvePath(json, entry.value);
  }
  return result;
}

/// Resolve dot-notation path: "data.query" → json["data"]["query"]
dynamic _resolvePath(Map<String, dynamic> json, String path) {
  dynamic current = json;
  for (final segment in path.split('.')) {
    if (current is Map<String, dynamic>) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}
```

**Polling timer**:

```dart
void _startHttpPolling(HttpDataSourceConfig ds) {
  if (ds.refreshInterval <= 0) return;
  _pollTimer = Timer.periodic(
    Duration(seconds: ds.refreshInterval),
    (_) {
      if (!mounted) return;
      _fetchHttpData(ds);
    },
  );
}

@override
void dispose() {
  _pollTimer?.cancel();       // HTTP polling cleanup
  _sseCleanup?.call();        // SSE cleanup (existing)
  super.dispose();
}
```

**Throttler integration** — both USP and HTTP paths use the throttler:

```dart
// HTTP path wraps fetch in throttler
final data = await throttler.enqueue(
  cacheKey: 'http:${ds.method}:${ds.url}',
  priority: RequestPriority.low,
  action: () => http.post(targetUrl, ...),
);

// USP path wraps GET in throttler
final data = await throttler.enqueue(
  cacheKey: 'usp:${subscription.paths.join(",")}',
  priority: RequestPriority.low,
  action: () => usp.get(subscription.paths),
);
```

### 9.9 Complete Widget JSON Examples

#### 9.9a Where Is My IP Card (`whereismyip_card.json`)

CGI response format: `{"data": {"query": "1.2.3.4", "city": "Taipei", "country": "Taiwan", "countryCode": "TW", "isp": "Chunghwa Telecom"}}`

```json
{
  "widgetId": "whereismyip_card",
  "displayName": "Where Is My IP",
  "description": "Public IP address and location",
  "constraints": {
    "minColumns": 2, "maxColumns": 4,
    "preferredColumns": 2, "preferredRows": 2,
    "minRows": 2, "maxRows": 3
  },
  "dataSource": {
    "type": "http",
    "url": "/cgi-bin/whereismyip.cgi",
    "method": "POST",
    "body": {"action": "lookup"},
    "refreshInterval": 300,
    "mapping": {
      "ip": "data.query",
      "city": "data.city",
      "country": "data.country",
      "countryCode": "data.countryCode",
      "isp": "data.isp"
    }
  },
  "template": {
    "type": "AppCard",
    "properties": {"padding": 16},
    "children": [
      {
        "type": "AppText",
        "properties": {"text": "Where Is My IP", "variant": "titleSmall"}
      },
      {"type": "AppGap", "properties": {"size": "sm"}},
      {
        "type": "AppText",
        "properties": {
          "text": {"$bind": "ip"},
          "variant": "headlineMedium"
        }
      },
      {
        "type": "AppText",
        "properties": {
          "text": {
            "$compute": {
              "op": "template",
              "format": "{city}, {country}",
              "values": {
                "city": {"$bind": "city"},
                "country": {"$bind": "country"}
              }
            }
          },
          "variant": "bodyMedium"
        }
      },
      {
        "type": "AppText",
        "properties": {
          "text": {"$bind": "isp"},
          "variant": "bodySmall"
        }
      }
    ]
  }
}
```

#### 9.9b Speed Test Card (`speed_test_card.json`)

CGI response format: `{"download_mbps": 450.2, "upload_mbps": 85.1, "ping_ms": 12, "server_name": "HiNet Taipei"}`

```json
{
  "widgetId": "speed_test_card",
  "displayName": "Speed Test",
  "description": "Last speed test result",
  "constraints": {
    "minColumns": 2, "maxColumns": 4,
    "preferredColumns": 3, "preferredRows": 2,
    "minRows": 2, "maxRows": 3
  },
  "dataSource": {
    "type": "http",
    "url": "/cgi-bin/speed-test.cgi",
    "method": "POST",
    "body": {"action": "result"},
    "refreshInterval": 0,
    "mapping": {
      "download": "download_mbps",
      "upload": "upload_mbps",
      "ping": "ping_ms",
      "server": "server_name"
    }
  },
  "template": {
    "type": "AppCard",
    "properties": {"padding": 16},
    "children": [
      {
        "type": "AppText",
        "properties": {"text": "Speed Test", "variant": "titleSmall"}
      },
      {"type": "AppGap", "properties": {"size": "sm"}},
      {
        "type": "Row",
        "properties": {
          "mainAxisAlignment": "spaceBetween",
          "children": [
            {
              "type": "Column",
              "properties": {
                "children": [
                  {
                    "type": "AppText",
                    "properties": {
                      "text": {
                        "$transform": {
                          "input": {"$bind": "download"},
                          "ops": [{"type": "suffix", "value": " Mbps"}]
                        }
                      },
                      "variant": "headlineSmall"
                    }
                  },
                  {"type": "AppText", "properties": {"text": "Download", "variant": "labelSmall"}}
                ]
              }
            },
            {
              "type": "Column",
              "properties": {
                "children": [
                  {
                    "type": "AppText",
                    "properties": {
                      "text": {
                        "$transform": {
                          "input": {"$bind": "upload"},
                          "ops": [{"type": "suffix", "value": " Mbps"}]
                        }
                      },
                      "variant": "headlineSmall"
                    }
                  },
                  {"type": "AppText", "properties": {"text": "Upload", "variant": "labelSmall"}}
                ]
              }
            },
            {
              "type": "Column",
              "properties": {
                "children": [
                  {
                    "type": "AppText",
                    "properties": {
                      "text": {
                        "$transform": {
                          "input": {"$bind": "ping"},
                          "ops": [{"type": "suffix", "value": " ms"}]
                        }
                      },
                      "variant": "headlineSmall"
                    }
                  },
                  {"type": "AppText", "properties": {"text": "Ping", "variant": "labelSmall"}}
                ]
              }
            }
          ]
        }
      },
      {"type": "AppGap", "properties": {"size": "sm"}},
      {
        "type": "AppText",
        "properties": {
          "text": {"$bind": "server"},
          "variant": "bodySmall"
        }
      }
    ]
  }
}
```

### 9.10 Security Considerations

| Rule | Implementation |
|------|---------------|
| **Local CGI only** | URL must start with `/cgi-bin/` — reject external URLs with `uri.hasAuthority` check |
| **No auth token** | HTTP requests to CGI do NOT include JWT or session token — CGI actions are no-auth |
| **No credential leak** | Mapping only reads response data — never sends user credentials in request body |
| **Origin-bound** | Request URL is constructed as `${Uri.base.origin}${ds.url}` — always same-origin |

### 9.11 Implementation Order

| Step | Content | Dependencies |
|------|---------|-------------|
| 1 | `BridgeRequestThrottler` + provider + unit tests | None |
| 2 | Wire throttler into `PackageWidgetRenderer` USP path | Step 1 |
| 3 | `HttpDataSourceConfig` model in `package_widget_template.dart` | None (parallel with 1) |
| 4 | `_applyMapping` / `_resolvePath` + `_fetchHttpData` in renderer | Step 1, 3 |
| 5 | HTTP branch in `_initializeData()` + polling timer + dispose | Step 4 |
| 6 | Unit tests for `_applyMapping` / `_resolvePath` | Step 4 |
| 7 | Deploy whereismyip_card.json + speed_test_card.json to router | Step 5 |

### 9.12 Throttler Integration with Existing Domain Providers (Phase 2)

After the throttler is proven with package widgets, extend it to domain providers
to fix the existing dashboard concurrency bug:

```dart
// dashboard_orchestrator.dart — future change
// Instead of fire-and-forget all at once:
ref.read(systemInfoDataProvider);   // ← internally uses throttler
ref.read(devicesDataProvider);      // ← queued behind if maxConcurrent reached
ref.read(ethernetDataProvider);     // ← queued behind
```

This is a non-breaking incremental change — each domain provider wraps its `usp.get()` call
with `throttler.enqueue()`. No changes to provider interfaces or orchestrator logic.

### 9.13 Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Singleton throttler via Riverpod provider** | Lifecycle tied to app, accessible from any widget/provider |
| **maxConcurrent = 3** | Reserve 3 of 6 browser connections for SSE + auth + bridge API |
| **stagger = 100ms** | Prevent burst load on bridge's lighttpd (limited CGI workers) |
| **Short cache TTL (5s)** | Prevent stale data while deduping concurrent identical requests |
| **Priority queue** | Auth/SSE = high, domain providers = normal, package widgets = low |
| **No retry in throttler** | Callers own their retry logic (`_withAuthRetry`, orchestrator backoff) |
| **Cache key = request identity** | USP: `usp:{paths}`, HTTP: `http:{method}:{url}` |
| **`dataSource` vs `subscription` mutual exclusion** | One widget = one data source. USP wins if both present. |
| **Default POST for CGI** | Router CGI convention: `POST {"action": "xxx"}` body pattern |
| **Dot-notation mapping** | `"data.query"` not `"$.data.query"` — simpler, no prefix ceremony |
| **`_applyMapping` in renderer** | Private methods in renderer; extract to utils only if reuse needed |
| **`type: "http"` field** | Future extensibility for WebSocket, gRPC, or other data source types |
| **No auth on CGI** | CGI endpoints are no-auth actions — no JWT/session token in request |

---

## 10. Known Limitations

| Limitation | Impact | Future Improvement |
|-----------|--------|-------------------|
| Router-side delay (10-15s) | `/api/apps.json` update after `opkg remove` is slow | Router-side SSE notification on package lifecycle events |
| SSE multi-path subscription | MVP uses `subscription.paths.first` only | Register per-path SSE subscriptions for full coverage |
| Template card prop forwarding | Only `padding` is forwarded from template to manual AppCard | Forward additional props (margin, width, height, onTap) as needed |
| Native card overflow | Each native card must handle overflow individually | Establish a `DashboardCard` base class with built-in scroll pattern |
| Dashboard GET concurrency | 6+ concurrent requests can overwhelm bridge on startup | `BridgeRequestThrottler` (Section 9) limits to 3 concurrent |
| Package widget silent failure | GET failure renders empty widget without error state | Add retry + error UI in renderer (with throttler backoff) |
