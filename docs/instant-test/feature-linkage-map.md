# Instant-Test — Feature Linkage Map

> Which actions appear in multiple places, and whether the logic is shared or
> duplicated. The "to change X, edit these files" reference.

Last Verified: 2026-06-09 (JNAP line)

## Headline
Business logic is centralized in the provider (single source of truth). After
the refactors, the previously-duplicated UI dialogs are now shared too. This map
tracks remaining and historical seams.

> Note: Instant-Test and Instant-Verify are now **separate tools** with their own
> dashboardMenu cards and routes (`menuInstantTest` → `InstantVerifyPivotView`;
> `menuInstantVerify` → the restored technician `InstantVerifyView`). This map
> covers the Instant-Test (`InstantVerifyPivotView`) surfaces. See [[code-map]].

## Cross-Surface Action Map
| Action | Logic (1 place) | UI trigger(s) | State |
|--------|-----------------|---------------|-------|
| **Restart router** | `provider.restartRouter()` | `confirmAndRestart()` in [[reference/shared-helpers]] — called from help_me_fix_it, overview (with countdown), my_network | ✅ Unified (was 3 dialogs) |
| **Force-reconnect** | `provider.deauthClient(mac)` | `confirmAndDeauth()` in [[reference/shared-helpers]] — my_devices detail sheet, help_me_fix_it Flow 3 | ✅ Unified (was 2 dialogs) |
| **Refresh / re-fetch** | `provider.fetch()` | overview "Run/Check Again"; my_devices header btn + pull-to-refresh; my_network header btn + pull-to-refresh; help_me_fix_it refresh icons | ✅ Consistent |
| **Card framing** | `AppCard` (design system) | All 4 tabs via AppCard | ✅ Unified |
| **Change WiFi channel** | provider channel change + `_showChannelChangePicker` | help_me_fix_it, my_devices | 🟡 Picker in help_me_fix_it; recommendation HARDCODED 6/36 — see [[roadmap]] B-18 |
| **Speed test** | provider + `browser_diagnostic_service` | speed_test widgets, overview, help_me_fix_it | 🟢 Widget-encapsulated |
| **Device detail** | — | `_DeviceDetailSheet` (my_devices only) | 🟢 Single location |

## The "force reconnect" linkage (Deven's example)
My Devices detail sheet, Help Me Fix It → device flow, and (conceptually) WiFi
overview all reconnect a device. Logic was always shared (`deauthClient`); the
confirm dialog + snackbar are now shared too via `confirmAndDeauth()`.

## Design Rule
To change a cross-surface action: edit the shared helper (one place). If a
change must differ per platform/surface, it belongs in the caller, not the
helper. Never re-fork a unified dialog.

## Relationships
- [[reference/shared-helpers]] — the helpers this map references
- [[code-map]] — file locations
- [[roadmap]] — open items (B-18 channel)

## Last Verified
2026-06-08
