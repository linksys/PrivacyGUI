# Wiring the English-only build into a Jenkins freestyle job

What to add to a freestyle job so it can produce an English-only build. See
[ADR 0001](adr/0001-english-only-build-by-build-time-stripping.md) for why the flavour is a
build-time strip rather than a branch.

The short version: **add one string parameter and change nothing else.** The existing shell
step already does the work, because `LOCALES` defaults to shipping every language pack.

## 1. Add the build parameter

Job → **Configure** → **This project is parameterised** → **Add Parameter** → **String
Parameter**:

| Field | Value |
| --- | --- |
| Name | `LOCALES` |
| Default Value | `all` |
| Description | `Language packs to ship. "all" for the retail build; "en" for English-only (saves ~3.8 MB of flash). Comma-separated, e.g. "en,fr".` |

`all` as the default is what makes this safe to add to an existing job: every build that
does not touch the parameter produces byte-for-byte what it produced before.

Prefer a **Choice Parameter** (`all`, then `en`) if the job should not accept free text —
the reduction is only measured for those two, and a typo in a string parameter fails the
build rather than silently shipping the wrong thing.

## 2. Leave the shell step alone

The existing step needs no change. Jenkins exports every build parameter as an environment
variable, and `build_web.sh` reads `LOCALES` from the environment:

```bash
./build_web.sh "${BUILD_NUMBER}" false "/" prod false true
```

The script strips before building and restores afterwards. It prints the delivered payload
size at the end, so the reduction shows up in the console log:

```
Delivered payload: 25908 KB (25.30 MB)
  build output:    63524 KB
  pruned by CI:    37616 KB (canvaskit/)
Reduction vs 29812 KB baseline: 3904 KB (3.81 MB)
```

If you would rather be explicit than rely on the exported variable, pass it inline instead
— same effect:

```bash
LOCALES="${LOCALES:-all}" ./build_web.sh "${BUILD_NUMBER}" false "/" prod false true
```

## 3. Optionally, assert the flavour that was built

A separate shell step, after the build, that fails the job if the payload does not match
the parameter. Worth adding if English-only builds go to a carrier and shipping the wrong
flavour would be expensive:

```bash
# Fail if the build did not produce the flavour the parameter asked for.
expected=1
[ "${LOCALES}" = "all" ] && expected=26

actual=$(grep -c "Locale(" lib/l10n/gen/app_localizations.dart)
# One entry per locale plus the `Locale` in the list's type annotation.
actual=$((actual - 1))

if [ "${actual}" -ne "${expected}" ]; then
  echo "expected ${expected} locales for LOCALES=${LOCALES}, built ${actual}"
  exit 1
fi
echo "built ${actual} locale(s), as asked"
```

## What does not need adding

**A cleanup step.** The strip is restored by an `EXIT` trap, so a failed build restores
too. More importantly this job wipes its workspace and re-clones every build, so nothing
can survive to the next one — a Jenkins abort escalates to `SIGKILL`, which would skip the
trap, and the fresh clone is what makes that harmless.

If the job is ever switched to reusing its workspace, that changes: an aborted English-only
build would leave the tree stripped, and the next build — retail included — would ship
English-only at full size. Add `dart run tools/locale_strip.dart verify` as the first step
if that happens; it exits non-zero on a tree that is still stripped.

**A `pub get` before the strip.** `tools/locale_strip.dart` imports only `dart:io`, so it
runs on a freshly cloned workspace with no `.dart_tool` and no resolved dependencies. Order
the strip and `pub get` however suits the job.

**A separate `gen-l10n` step.** `build_web.sh` runs it after stripping, and again after
restoring.

## Verifying the parameter works

Run the job twice and compare the `Delivered payload` line in each console log:

| `LOCALES` | delivered payload |
| --- | --- |
| `all` | 29,812 KB (29.11 MB) |
| `en` | 25,908 KB (25.30 MB) |

A build where the two agree means the parameter is not reaching the script — check that it
is defined on the job rather than only passed at trigger time.
