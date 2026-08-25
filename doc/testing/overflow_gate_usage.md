# Overflow Gate — How To Use It

**Last Updated: 2026-08-25** · counts measured that day, all green

**This is the operator's guide.** If you are changing UI and want to know whether
it overflows before you open a PR, everything you need is here. The other three
are for people maintaining the gate itself:

| Document | Answers |
|---|---|
| **this one** | How do I run it, read it, and see a picture of what broke? |
| [../../.claude/skills/layout-gate/SKILL.md](../../.claude/skills/layout-gate/SKILL.md) | How do I *change* it? Triage playbooks, allowlist edits, onboarding a new card or page, adding a probe for a surface no suite renders. |
| [overflow_baselines.md](overflow_baselines.md) | How does the coverage dataset work? What do the four subcommands write? |
| [overflow_gate_architecture.md](overflow_gate_architecture.md) | Why these coordinates? What are the invariants and what does it cost? |

---

## 1. The one command

```bash
fvm flutter test --tags overflow
```

That runs every overflow sweep in the repo: **4,032 coordinates**, each one a
screen × width × tab × locale combination, pumped as its own widget tree and
asked one question — did a `RenderFlex` overflow?

**No baseline, no fixture, no setup.** A fresh clone gives an absolute verdict:
any overflow past **2.0px** fails. (The 2.0px absorbs sub-pixel text shaping
between macOS and CI; real clipping is tens or hundreds of px.)

In CI you need to do nothing at all — `run_tests.sh` excludes `golden||loc||ui`
and the gate is tagged `layout-gate`, so it already runs on every PR.

| Command | Tests | Test clock / wall | When |
|---|---|---|---|
| naming the five sweep files (below) | 296 | 25s / 32s | inner loop while fixing |
| `fvm flutter test --tags overflow` | 296 | 1m48s / 2m03s | before committing |
| `fvm flutter test --tags layout-gate` | 1,476 | 1m58s / 2m07s | the whole PR-blocking gate |
| `./run_tests.sh` | 5,463 | 3m08s / 3m13s | what CI runs |

The first two select **exactly the same tests**. `@Tags` is only readable by
loading a suite, so the tag compiles every test file in the repo to then skip all
but five. Name the files for a tight loop; use the tag when a sixth sweep must not
be silently missed.

```bash
fvm flutter test \
  test/page/dashboard/cards/dashboard_card_overflow_test.dart \
  test/page/dashboard/cards/dashboard_card_popup_overflow_test.dart \
  test/page/dashboard/cards/dashboard_card_forced_form_overflow_test.dart \
  test/page/shell/page_chrome_overflow_test.dart \
  test/page/_shared/page_surface_overflow_test.dart
```

---

## 2. It went red. Now what?

```
fvm flutter test --tags overflow
   │
   ├─ green ────→ done, open the PR
   │
   └─ red ─────→ the failure names the sweep and the source line:
                 │
                 │  card.width overflowed at card=network_health px=191 tab=0
                 │    in 3 locale(s):
                 │      de: +113.0px right at lib/page/.../usp_network_health_card.dart:424
                 │      fi: +98.0px right at ...
                 │      ▲          ▲                        ▲
                 │      │          │                        └─ the line to fix
                 │      │          └─ how far past the edge
                 │      └─ the sweep name's prefix → the `shoot` argument
                 ▼
       ./tool/overflow_baseline.sh shoot card failed
                 │
                 ▼
       browser opens build/overflow_baseline/report/card.shoot.html
       with a PNG of every cell that failed
                 │
                 ▼
            fix the layout → re-run
```

### Reading the failure

Three things are already in the message, so you rarely need anything else:

- **The family name** (`card.width`, `popup.dialog`, `chrome.top_bar`,
  `page.surface`, `forced_form.compact_floor`). Its prefix is the sweep name.
- **The coordinate** — which card, which width, which tab.
- **`file:line`** — the widget that overflowed. This exact string is also the
  allowlist key if one is ever needed, so copy it rather than reconstructing it.

Locales are aggregated into one failure on purpose: `overflowed at 640px in 7
locale(s)` is easier to act on than seven red tests, and *which* locales is the
clue — #1328's band was only visible because `en` cleared at 640px and `pl`
needed 768px.

### Seeing it

```bash
./tool/overflow_baseline.sh shoot <sweep> failed
```

`<sweep>` is one of **`card` `popup` `forced_form` `chrome` `page`**.

`failed` is a reserved word meaning "the sweep's own bar" — over 2.0px, or a pump
that threw — so you never have to copy a cell id. It runs against **your working
tree**, and produces the rows and the images from **one run** stamped with the
same commit, so a picture beside a verdict is evidence for it. A green sweep is
photographed zero times and says so.

Other patterns, when you want to look at something that passed:

```bash
./tool/overflow_baseline.sh shoot card 'px=191|tab=0|locale=de'   # cell-id substring
./tool/overflow_baseline.sh shoot page all                        # every cell
NO_OPEN=1 ./tool/overflow_baseline.sh shoot chrome failed         # don't auto-open
```

### Dashboard cards have a richer report

The card sweep alone can also render before/after PNGs plus a recommended grid
width:

```bash
./tool/run_overflow_test.sh -c network_health -L de -o
./tool/run_overflow_test.sh -l          # list every card id, its spans and tab count
```

`shoot` shows you what it looks like now; `run_overflow_test.sh` shows you what it
would look like at the width it wants. Narrowing to one card and one locale takes
seconds. Output lands in `build/overflow_testing/`.

---

## 3. Vocabulary

The names in this subsystem mislead in a specific way, so:

| Term | What it actually is |
|---|---|
| **overflow test** | The test. What `--tags overflow` runs. |
| **sweep** | Not a second kind of test — it is *how* the overflow test works: walk every coordinate, pump a fresh tree, judge it. "The card sweep" is one such walk. |
| **family** | The declaration of one sweep: which coordinates exist, and how one coordinate becomes a widget. Five sweeps, nine families. |
| **cell** | One coordinate. A `clean` cell is a recorded row, **not** an absence. |
| **ratchet** / **allowlist** | [known_overflows.json](../../test/fixtures/known_overflows.json). A tolerance list that *weakens* the verdict. **Currently empty**, so nothing is exempt. See §6. |
| **baseline** (`.tsv`) | A coverage register — a record of *which* 4,032 coordinates were measured. It judges nothing. See §5. |
| `sweep_test.dart`, `ratchet_test.dart` | **Not sweeps.** Unit tests of the framework itself. You never run them deliberately. |

The two easiest mistakes: thinking `sweep` is an auxiliary check on top of the
overflow test (it *is* the overflow test), and thinking the baseline is the
pass/fail standard (nothing in the gate reads it — see §5).

---

## 4. What exists, in three layers

```
┌───────────────────────────────────────────────────────────────┐
│ ① What you use                                                │
│                                                               │
│   5 sweep suites          ← what --tags overflow runs         │
│   tool/overflow_baseline.sh shoot   ← pictures                │
│   tool/run_overflow_test.sh         ← pictures, cards only    │
└───────────────────────────────────────────────────────────────┘
                          │ built on
                          ▼
┌───────────────────────────────────────────────────────────────┐
│ ② The engine — test/layout_gate/                              │
│                                                               │
│   The runner, the overflow collector, the ratchet, the        │
│   families. NOT tests: a library the five suites declare       │
│   themselves through.                                          │
└───────────────────────────────────────────────────────────────┘
                          │ policed by
                          ▼
┌───────────────────────────────────────────────────────────────┐
│ ③ The engine's own oracles                                    │
│                                                               │
│   sweep_test.dart · ratchet_test.dart ·                       │
│   families/dashboard_card_gate_test.dart                      │
│   "does the engine lie?" — e.g. are 26 locales really 26      │
│   fresh trees, or 26 measurements of the first one?           │
└───────────────────────────────────────────────────────────────┘

   ┌──────────────────────────────────────────┐
   │ Beside all three, judging nothing:       │
   │ the coverage register                    │
   │ test/fixtures/overflow_baselines/*.tsv   │
   └──────────────────────────────────────────┘
```

②③ carry `layout-gate` but deliberately **not** `overflow`: that tag means
"pumps cells and asserts zero overflow", and letting it drift wider would slide it
back over the whole family. Nothing in ②③ needs configuring; they simply run.

Coverage today, per sweep:

| Sweep | Cells | What it pumps |
|---|---:|---|
| `card` | 1,943 | every dashboard card × narrowest grid width per span × tab × 26 locales |
| `chrome` | 1,248 | top bar and dashboard header at screen width × locale × action mode |
| `popup` | 347 | the same cards pinned into the popup form |
| `page` | 416 | `page.dhcp` and `page.wifi_settings`, 8 widths × 26 locales |
| `forced_form` | 78 | the boxes a user's forced-size pick produces, which no drag could |
| | **4,032** | |

---

## 5. When to touch a sweep, and when to update the register

You do not have to remember any of this. The gate tells you.

| What you did | Add a sweep? | Update the register? |
|---|:---:|:---:|
| Changed a card's layout (`Row`, `Column`, padding) | no | no |
| Changed copy, added a translation | no | no |
| **Added or removed a dashboard card** | no — enumerated automatically | **yes** |
| **Added or removed a tab on a card** | no | **yes** |
| **Added a supported locale** (26 → 27) | no | **yes**, all five |
| **Found an overflow on a surface no sweep renders** | **yes** — write a family | **yes** |
| Refactored `test/layout_gate/` | — | **the diff must be empty** |

### Adding a sweep

Only when the overflow is on a surface nothing currently renders. Not covered
today: **43 of the 45 page views** — named one per line in
[`test/fixtures/page_roster.tsv`](../../test/fixtures/page_roster.tsv) since #1382,
so "~40" is no longer an estimate — plus dialogs and bottom sheets. You write a
*family* — which coordinates exist, and how one becomes a widget — and declare it
once:

```dart
runOverflowSweep(family: MyDialogFamily(), expectedCellCount: 208);
```

Naming, the locale inner loop, one fresh tree per cell, viewport restore, the
dataset row and the cell-count pin all come with it. #1349 added two pages this
way and changed nothing in the engine — a page is a `PageSurfaceCase` data entry,
not a class.

**Onboarding a page also moves its roster row** from `queued` to `swept`, with the
ms/cell the run measured. You will not forget: the roster oracle asserts `swept` and
`kPageSurfaceCases` agree in both directions, so a page added to the sweep without
its row goes red naming the path. See the architecture doc §11.5.

### Updating the register

The cell-count pin is your alarm. Add a card and the gate goes red like this
*before* anything else:

```
card.width enumerated 1,995 cells, not the 1,943 this sweep pins.
```

That is when — and the only time — you run:

```bash
./tool/overflow_baseline.sh check      # 1. look at the difference first
                                       # 2. read the diff: every line must be
                                       #    a change you can explain
./tool/overflow_baseline.sh capture    # 3. only then record it
```

**Step 2 is the point.** `capture` is the only way lost coverage becomes
permanent. A `no longer measured` line you cannot explain means the change
quietly dropped a coordinate — and a dropped coordinate is **green**, because
"this card was fixed" and "this card was never measured" look identical in a test
report. That asymmetry is the entire reason the register exists.

For an engine refactor the direction reverses: `capture` first, refactor, then
`check` should exit 0. A diff there is the bad news — it means the refactor
changed *what is measured*, which the green suite will never tell you.

Nothing in the gate reads these files. `grep` confirms it: the five `.tsv` files
appear in `test/**` only inside comments. Their only readers are
`tool/overflow_baseline.sh` and `test_scripts/overflow_baseline.dart`, both of
which a human invokes.

---

## 6. The allowlist, and why it is empty

[known_overflows.json](../../test/fixtures/known_overflows.json) is
`{"tracking": {}, "allowlist": {}}` today. It is the one mechanism that can turn
an overflow into a pass, so an empty file is what makes the verdict absolute.

**Keep it empty.** Fix the layout instead. If an entry is genuinely unavoidable:

```jsonc
{
  "tracking": {
    "lib/page/.../usp_network_health_card.dart:424": "legend fix #1145/#1174"
  },
  "allowlist": {
    "lib/page/.../usp_network_health_card.dart:424": ["de", "fi", "pl"],
    "ui_kit_library/lib/src/widgets/app_chip.dart:63": ["*"]
  }
}
```

- The key is the `file:line` the failure already printed — copy it.
- List the locales that actually overflow; `"*"` means "every locale"
  (text-length independent, i.e. structural).
- A `tracking` note is expected alongside it: an exemption with no owner is a
  permanent one.
- It does not rot silently. An entry that nothing overflows against any more fails
  the gate as a **dead exemption**, and a locale tag that was never needed fails as
  an **over-broad exemption**. It will not empty itself, though.

An incident whose source location could not be resolved can never be exempted —
a null site is not a key, and `"*"` will not cover it.

---

## 7. Two known blind spots

`clean` means "no `RenderFlex` reported an overflow". It does not mean readable.

- **Text can be truncated to nothing and still pass.** Measured: four dashboard
  cards pass at 191px rendering unreadably (#1240 AC1).
- **A fix that trades an overflow for a *wrap* is invisible to every cell.**
  #1349's `Flexible` did exactly that, which is why `PageSurfaceFamily` declines
  the per-cell readability assertion in writing and guards the one changed site
  with its own pumps instead.

Both are why `shoot` exists. When a cell's verdict matters, look at the picture.

---

## 8. Command reference

```bash
# ── run ─────────────────────────────────────────────────────────────────────
fvm flutter test --tags overflow          # the five sweeps, 4,032 cells
fvm flutter test --tags layout-gate       # the whole PR-blocking gate
./run_tests.sh                            # what CI runs (includes the above)

# ── look ────────────────────────────────────────────────────────────────────
./tool/overflow_baseline.sh shoot <sweep> failed   # photograph what broke
./tool/overflow_baseline.sh shoot <sweep> <id-substring|all>
./tool/overflow_baseline.sh render [sweep...]      # read committed rows, no flutter, 6s
./tool/run_overflow_test.sh -c <card> -L <locale> -o
./tool/run_overflow_test.sh -l                     # list cards, spans, tab counts

# ── coverage register (only when the coordinate set changes on purpose) ──────
./tool/overflow_baseline.sh check [sweep...]       # exit 0 identical · 1 differs · 2 bad run
./tool/overflow_baseline.sh capture [sweep...]

# <sweep> ∈ card | popup | forced_form | chrome | page
# NO_OPEN=1 suppresses auto-opening the report
```

`render` and `shoot` differ in whose rows they hold: `render` reads the
**committed** dataset (`<sweep>.baseline.html`), `shoot` reads **this working
tree** (`<sweep>.shoot.html`). Both are gitignored, under
`build/overflow_baseline/report/`. If a `render` report announces *"These images
are not of this dataset's tree"* above its gallery and exits 1, the pictures and
the verdicts came from two different commits — do not read one as evidence for the
other.
