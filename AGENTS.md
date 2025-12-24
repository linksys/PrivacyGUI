<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Use `@/openspec/SCREENSHOT_TESTING.md` to learn:
- How to create and run screenshot tests
- How to define mock spec files and modify mock notifiers

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

## Active Technologies
- Dart 3.0+, Flutter 3.3+ + ui_kit_library (Git), privacygui_widgets (local plugin), flutter_riverpod, go_router (001-ui-kit-migration)
- Local preferences, shared_preferences, flutter_secure_storage (001-ui-kit-migration)

## Recent Changes
- 001-ui-kit-migration: Added Dart 3.0+, Flutter 3.3+ + ui_kit_library (Git), privacygui_widgets (local plugin), flutter_riverpod, go_router
