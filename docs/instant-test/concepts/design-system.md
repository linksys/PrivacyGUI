# Concept: Design System Usage

> How Instant-Test stays visually consistent with the rest of PrivacyGUI.

## AppCard — the framing primitive
All section framing uses `AppCard` from `plugins/widgets` (the same widget the
`dashboardMenu` page uses). This guarantees border color (`outlineVariant`),
surface, and radius match the app and track the theme.

**Rule:** never hand-roll a `Card()` or `Container(BoxDecoration)` for a section
frame — use `AppCard`. For list-style content, pass `padding: EdgeInsets.zero`.
`AppCard` accepts `color`, `borderColor`, `margin`, `padding`.

History: sections used bare Material `Card()` which has invisible borders on the
dark theme (the "floating text" problem). Converted all 4 tabs to AppCard 2026-06-08.

## Color Matching
Match colors to the `dashboardMenu` page by **using the same widget**, not by
copying hex values. Blues = `colorScheme.primary` (already consistent).

## Text Selection
The pivot `TabBarView` and each modal bottom sheet are wrapped in `SelectionArea`
so all text is drag-selectable/copyable natively. Modals need their own wrap
(separate overlay tree). The old per-row copy icons were removed in favor of this.

## Router Info Header
The AppBar shows router identity top-right (tappable for full details), replacing
the ⓘ icon. **Stacked, labeled lines** — `Model:` / `Ver:` / `Serial:` — each a
plain `Text` (right-aligned, ellipsis, MainAxisSize.min), with `toolbarHeight: 64`
so 3 lines fit. (A RichText version regressed to invisible — use plain Text.)

## Check States (Test details rows)
`_CheckDisplayState` = pass (green ✓) / warning (amber ⚠) / fail (red ✗) /
skipped (grey) / available (blue, firmware). Rows reflect their finding: e.g.
Speed check → amber on high latency or a failed test; Devices checked → amber
when any device has a weak signal. Keeps the lower boxes consistent with the
top findings.

## Modal Sheets
Bottom sheets that can grow tall (e.g. the Test-scenarios picker, 5 items) must
be `isScrollControlled: true`, capped (~80% screen height), with the list in a
scrollable `ListView` — otherwise lower items clip on short windows.

## Menu Cards (dashboardMenu)
Section cards use `AppMenuCard` → `AppCard`. Instant-Test uses the `troubleshoot`
icon (distinct from the speed-test cards' `networkCheck`). The menu grid height
must round rows UP (`.ceil()`) or a lone final-row card gets clipped.

## Related
- [[code-map]]
- [[feature-linkage-map]]

## Last Verified
2026-06-08
