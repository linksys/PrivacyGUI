# Instant-Test — Code Map

> Where everything lives. JNAP line (`lib/page/instant_verify/`) unless noted.

## Route Entry
- **Instant-Test** (our customer tool): `RouteNamed.menuInstantTest` / path `/menuInstantTest`
  → serves `InstantVerifyPivotView` (the 4-tab pivot). New dashboardMenu card "Instant-Test".
- **Instant-Verify** (technician tool, separate): `RouteNamed.menuInstantVerify` / `/menuInstantVerify`
  → serves `InstantVerifyView` (single-view, ping/traceroute). Its own "Instant-Verify" card.
- History: the menuInstantVerify route was briefly co-opted to point at our pivot view, and
  `InstantVerifyView` was deleted 2026-06-08 as "dead". Restored 2026-06-09 (identical to
  `dev-1.2.9` original) and given Instant-Test its own route/card so the two are cleanly separate.

## Views (`lib/page/instant_verify/views/`)
| File | Role |
|------|------|
| `instant_verify_pivot_view.dart` | 4-tab Scaffold shell — AppBar (router-info top-right), TabBar, SelectionArea wrapper |
| `overview_tab.dart` | Tab 0 — Instant-Test landing / diagnostic summary + auto-fix |
| `my_devices_tab.dart` | Tab 1 — device list, device detail sheet, refresh |
| `my_network_tab.dart` | Tab 2 — internet/mesh/WiFi/guest cards |
| `help_me_fix_it_tab.dart` | Tab 3 — 5 guided flows (largest file) |
| `restart_helper.dart` | **Shared** `confirmAndRestart()` — used by all surfaces |
| `device_actions.dart` | **Shared** `confirmAndDeauth()` — force-reconnect, all surfaces |
| `components/speed_test_widget.dart` | Speed test UI |
| `components/speed_test_external_widget.dart` | Cloudflare external speed test |

## Providers (`providers/`)
| File | Role |
|------|------|
| `instant_verify_pivot_provider.dart` | **The brain.** `fetch()`, `restartRouter()`, `deauthClient()`, channel change, speed orchestration. Single source of truth for actions. |
| `instant_verify_pivot_state.dart` | Pivot state (clients, findings, speedTest, router info, hasRestartedThisSession) |
| `local_storage_web.dart` / `local_storage_stub.dart` | Session persistence (restart timestamp) |

## Models (`models/`)
`verdict.dart` (VerdictEngine — see [[concepts/verdict-engine]]), `device_score.dart`,
`customer_journey.dart`, `diagnostic_client.dart`, `mesh_node_info.dart`, `jnap_capability.dart`.

## Services (`services/`)
`browser_diagnostic_service.dart` — three-leg browser speed/ping/traceroute.

## USP Line (`lib/page/instant_test/`)
Parallel, smaller file set (`instant_test_page.dart`, `overview_tab.dart`,
`my_devices_tab.dart`, `my_network_tab.dart`, `help_me_fix_it_tab.dart`, models,
providers, services). Uses `_shared/models/` UI models (DeviceUIModel etc.).
See [[concepts/two-line-strategy]].

## Design System Primitives (shared, repo-wide)
- `plugins/widgets` (git submodule) → `AppCard` — the card used for all framing.
- See [[concepts/design-system]].

## Relationships
- [[feature-linkage-map]] — which actions repeat across these files
- [[reference/shared-helpers]] — the unified helpers
- [[overview]]

## Last Verified
2026-06-08
