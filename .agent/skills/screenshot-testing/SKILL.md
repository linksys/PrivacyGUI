---
name: screenshot-testing
description: Write and fix screenshot tests for PrivacyGUI views following project conventions
---

# Screenshot Testing Skill

> **Purpose**: Capture visual snapshots of UI states, NOT functional testing.

## Before You Start

**ALWAYS** read the implementation file first to identify widget types, keys, and localization keys.

## Essential Commands

```bash
# Development (480w only, faster)
sh ./run_generate_loc_snapshots.sh -c true -f test/page/{feature}/localizations/{view}_test.dart -l "en" -s "480"

# Final verification (REQUIRED - both sizes)
sh ./run_generate_loc_snapshots.sh -c true -f test/page/{feature}/localizations/{view}_test.dart -l "en" -s "480,1280"
```

## Naming Conventions

| Element | Format | Example |
|---------|--------|---------|
| View ID | Up to 5 uppercase letters | `PNPA`, `DASHH` |
| Test ID | `{ViewID}-{DESCRIPTION}` | `PNPA-INIT` |
| Golden File | `{TestID}-{##}-{desc}` | `PNPA-INIT-01-loading` |

## Key Points

- Use `pumpView` for standalone pages, `pumpShellView` for shell views
- Use `testHelper.loc(context)` for localized text (never hardcode)
- Use UI Kit widget types: `AppButton`, `AppLoader`, `AppTextField`
- Animations disabled by default via `testHelper.disableAnimations`

## Resources

See skill subdirectories for detailed information:
- `examples/` - Test file templates and patterns
- `resources/` - Complete guidelines, mock generation, troubleshooting

## Project Documentation

- `doc/screenshot_test/screenshot_testing_guideline.md` - Core conventions
- `doc/screenshot_test/screenshot_testing_knowledge_base.md` - Complete reference
- `doc/screenshot_test/screenshot_testing_fix_workflow.md` - Debugging failed tests
- `doc/testing/mock_generation_guide.md` - Adding new mocks

## Example Files in Codebase

- `test/page/instant_setup/localizations/pnp_admin_view_test.dart`
- `test/page/dashboard/localizations/dashboard_support_view_test.dart`
