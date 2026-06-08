# Concept: Two-Line Strategy (JNAP + USP)

> Instant-Test ships on two permanent, parallel firmware lines. This is how they
> coexist and share code.

## Explanation
Product vision diverges permanently into JNAP products and USP products, so we
maintain two development lines indefinitely.

| | JNAP line | USP line |
|---|---|---|
| Feature branch | `feature/Instant-Troubleshooting` | `feature/instant-test-usp` |
| Base branch | `dev-1.2.9` | `dev-2.4.0` |
| Code home | `lib/page/instant_verify/` | `lib/page/instant_test/` |
| Data shapes | raw JNAP (`DiagnosticClient`, `MeshNodeInfo`) | UI models (`DeviceUIModel`, `NodeUIModel`) |

The two lines do NOT share a code tree (their bases forked ~300 commits ago and
never re-merge).

## Code Sharing Model (verified)
Both lines already consume shared code as **external pinned dependencies** — JNAP
via the `plugins/widgets` git submodule; USP via versioned `git:` deps
(`ui_kit_library` @ a tagged ref). So the planned shared diagnostics core is a
**separate git repo consumed as a versioned `git:` dependency**, NOT an in-tree
folder or cherry-pick. Propagation = bump the `ref:`, per line, on its own schedule.

Architecture: platform raw data → per-line **adapter** → `NormalizedDiagnosticModel`
→ shared core (zero platform conditionals) → per-line UI. A logic bug fixes once;
a data-shape quirk stays quarantined in one adapter.

Full plan: `Plans/two-line-strategy.md` (in the PRODUCT_MANAGEMENT docs repo).

## Examples
- `verdict.dart` is ~95% identical across lines — only the input *types* differ.
  That's the seam the normalized model removes.
- 3 of 5 core files were byte-identical at survey time.

## Status
Planned. Extraction sequenced AFTER current JNAP hardware validation.

## Related
- [[processes/branch-strategy]]
- [[concepts/verdict-engine]]
- [[roadmap]]

## Last Verified
2026-06-08
