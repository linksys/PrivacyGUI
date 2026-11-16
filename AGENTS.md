# AGENTS.md

This is the 1.x line of PrivacyGUI. Its rules, and how each one is enforced, are in `constitution.md`; 2.x's constitution and patterns (USP, `ui_kit_library`, a mandatory service layer) are not rules here. Read `constitution.md` before you change anything under `lib/` or `test/`, and before you add a row to one of its exception lists, which is an amendment (Article IX).

## Set up a checkout

`lib/l10n/gen/` and `test/**/*.mocks.dart` are generated and gitignored, so a fresh checkout does not compile until you run:

1. `git submodule update --init plugins/widgets`
2. `flutter pub get`
3. `flutter gen-l10n`
4. `dart run build_runner build --delete-conflicting-outputs`

Rerun all four after pulling: a pull can move the `plugins/widgets` pointer or change `pubspec.yaml`.

Use the Flutter version in `.fvmrc`. `run_tests.sh` runs the `flutter` it finds on `PATH`, and a shell alias such as one for fvm does not reach inside the script, so put that version's `bin/` first on `PATH`.

## Run tests

Every test run passes `--exclude-tags="golden||loc"` (constitution 3.1). Run the whole suite with `./run_tests.sh <reportDir>` before you push; while you work, run `flutter test <file or directory> --exclude-tags="golden||loc"`.
