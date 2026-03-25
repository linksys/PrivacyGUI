# Feature Branch Change Report: Apps Page & Package Dashboard Widget

**Branch**: `feature/apps-page` vs `dev-2.2.1`
**Commits**: 4
**Files**: 20 changed (+1,214 / -38 lines)
**Date**: 2026-03-25

---

## 1. Feature Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   feature/apps-page                         │
├────────────────────┬────────────────────────────────────────┤
│   Feature A        │   Feature B                            │
│   Apps Page        │   Package Dashboard Widget             │
│   (5 new files)    │   (6 new + 5 modified files)           │
├────────────────────┼────────────────────────────────────────┤
│ • Display router-  │ • opkg packages deploy dashboard cards │
│   installed system │ • JSON template → UiTreeBuilder render │
│   & user apps      │ • $bind data binding + SSE live update │
│ • 5s poll detect   │ • User-initiated Add (not auto-show)   │
│   install/remove   │ • 10s poll detect install/remove       │
│ • NEW badge 60s    │                                        │
│ • Store btn + JWT  │                                        │
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
  USP Service ──GET (initial)──────→├→ resolveBindings ($bind → data)
  SSE Manager ──subscribe──────────→├→ UiTreeBuilder.build()
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
       "text": {"$bind":                text: "3"                 ← resolve
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

---

## 3. Commit Details

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

## 4. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **User-initiated Add** | Installing a package ≠ auto-showing a card. Widgets appear in settings panel "Hidden Widgets" for user to manually add. Prevents unwanted dashboard clutter. |
| **Independent fetch** | `PackageWidgetLoader` does not reuse `UspAppsNotifier` (autoDispose — destroyed when Apps page is closed). Dashboard needs persistent template cache. |
| **`properties→props` + children merge** | Widget JSON uses `properties` + sibling `children`. UiTreeBuilder reads `child['props']['children']`. `bind_resolver` normalizes both in a single recursive pass. |
| **Passthrough normalizer** | 10-line local `_PassthroughNormalizer` avoids importing from `generative_ui` package. Only promotes `child→children`. |
| **`pkg_` prefix whitelist** | Layout validation allows `pkg_`-prefixed IDs to pass (package specs load asynchronously, not available during layout init). |
| **SizedBox.expand** | Applied at dashboard view level for ALL cards (native + package) to ensure every card fills its grid cell. |
| **Internal scroll pattern** | Package widget: AppCard shell + `SingleChildScrollView` inside. Connected Devices native card: fixed header + `Expanded(SingleChildScrollView)` for device list. |
| **10s polling** | Reduced from 30s to match Apps page detection speed. `/api/apps.json` is a lightweight local HTTP request. |

---

## 5. New File Structure

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
│   ├── models/
│   │   └── package_widget_template.dart   PackageWidgetTemplate + toWidgetSpec
│   ├── providers/
│   │   ├── all_widget_specs_provider.dart  native 17 + package merge
│   │   ├── package_widget_data_provider.dart  per-widget USP data
│   │   └── package_widget_loader.dart     fetch + cache + 10s poll
│   ├── utils/
│   │   └── bind_resolver.dart             $bind resolve + props normalize
│   └── widgets/
│       └── package_widget_renderer.dart   full lifecycle renderer
```

---

## 6. Bugs Fixed

| Bug | Root Cause | Fix |
|-----|-----------|-----|
| Package widget renders empty | `bind_resolver` renamed `properties→props` but left `children` as sibling at root level. UiTreeBuilder reads `props['children']` → null. | `_resolveMap` merges `children` into the `props` map after rename. |
| Card background doesn't fill grid cell | `SingleChildScrollView` wrapping entire card gave unconstrained height → AppCard only took natural content height. | Split root card from children; AppCard shell fills cell via `SizedBox.expand`, only inner content scrolls. |
| Connected Devices card overflow (95px) | Native card's Column expands all device rows without height constraint. | Fixed header + `Expanded(SingleChildScrollView)` for the device list section. |
| Dashboard card removal delay ~1min | `PackageWidgetLoader` polled every 30s. | Reduced to 10s polling interval. |

---

## 7. Reused Components

| Component | Source | Usage |
|-----------|--------|-------|
| `UiTreeBuilder` + `UiKitCatalog.standardBuilders` | ui_kit_library | JSON → Widget rendering engine (60+ registered components) |
| `SseManager.subscribe()` | lib/core/usp/ | Dynamic SSE subscription + async cleanup function |
| `UspService.get()` | lib/core/usp/ | USP GET with wildcard path support |
| `WidgetSpec` / `LayoutItemFactory` / `DashboardController` | lib/page/dashboard/ | Dashboard grid layout system |
| `UiKitPageView.withSliver` | ui_kit_library | Apps page scaffold with pull-to-refresh |
| `AppCard`, `AppText`, `AppButton`, `AppBadge` | ui_kit_library | UI components used across both features |

---

## 8. Known Limitations

| Limitation | Impact | Future Improvement |
|-----------|--------|-------------------|
| Router-side delay (10-15s) | `/api/apps.json` update after `opkg remove` is slow | Router-side SSE notification on package lifecycle events |
| SSE multi-path subscription | MVP uses `subscription.paths.first` only | Register per-path SSE subscriptions for full coverage |
| Template card prop forwarding | Only `padding` is forwarded from template to manual AppCard | Forward additional props (margin, width, height, onTap) as needed |
| Native card overflow | Each native card must handle overflow individually | Establish a `DashboardCard` base class with built-in scroll pattern |
