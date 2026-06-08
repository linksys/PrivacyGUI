# Reference: Shared Action Helpers

> The unified, cross-surface action helpers. Change the action once, here.

## `confirmAndRestart()` — `views/restart_helper.dart`
```dart
confirmAndRestart(BuildContext context, WidgetRef ref, {VoidCallback? onRestarted})
```
- Enforces once-per-session singleton (PRD B-5) and the confirmation dialog (PRD D-23).
- Calls the single `provider.restartRouter()`.
- `onRestarted` callback for surface-specific follow-up (e.g. overview's restart countdown).
- Used by: help_me_fix_it (`_confirmAndRestart` alias), overview_tab, my_network_tab.
- Replaced 3 duplicated dialogs (2026-06-08). my_network previously restarted with
  NO confirmation — that bug was fixed by this unification.

## `confirmAndDeauth()` — `views/device_actions.dart`
```dart
confirmAndDeauth(BuildContext context, WidgetRef ref,
    {required String mac, required String displayName, ValueChanged<bool>? onProgress})
```
- Confirmation dialog → `provider.deauthClient(mac)` → success snackbar.
- `onProgress(true/false)` drives a caller's local spinner (e.g. detail sheet's
  "Disconnecting…" button).
- Used by: my_devices detail sheet (`_disconnectDevice`), help_me_fix_it (`_doDeauth`).
- Replaced 2 divergent dialogs (2026-06-08).

## Provider (logic source of truth) — `providers/instant_verify_pivot_provider.dart`
`fetch({forceSpeedTest})`, `restartRouter()`, `deauthClient(mac)`,
`triggerFirmwareUpdate()`, channel change. UI helpers wrap these; never call a
mutation from a view without going through a shared helper.

## Related
- [[feature-linkage-map]]
- [[code-map]]

## Last Verified
2026-06-08
