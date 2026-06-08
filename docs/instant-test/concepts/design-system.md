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
The AppBar shows model · firmware · serial top-right (tappable for full details),
width-capped with ellipsis so it can't overflow into the tabs. Replaced the ⓘ icon.

## Related
- [[code-map]]
- [[feature-linkage-map]]

## Last Verified
2026-06-08
