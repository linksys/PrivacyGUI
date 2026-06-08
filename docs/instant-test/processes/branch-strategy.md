# Process: Branch Strategy

> Two long-lived branches, what each is for, and the rules.

## The Two Branches
| Branch | Base | Purpose | Code |
|--------|------|---------|------|
| `feature/Instant-Troubleshooting` | `dev-1.2.9` | JNAP line — currently live/deployed | `lib/page/instant_verify/` |
| `feature/instant-test-usp` | `dev-2.4.0` | USP line — platform direction | `lib/page/instant_test/` |

Both are permanent (per product decision). Neither is "the temporary one."
See [[concepts/two-line-strategy]].

## Rules
- Feature branches push directly to `linksys/PrivacyGUI` (no PR needed for personal branches).
- Don't merge into `dev`/`main` without PR + review.
- GitHub pushes require explicit approval (owner-access protection hook) — list
  the exact command(s), approve, push within the 60s token window.
- Before any code change, know which line you're on (`git branch --show-current`).
  When switching branches mid-work, commit or stash first — never chain a branch
  switch with a stash op in one command (it can create unmerged-state tangles).

## Porting Between Lines
Changes are NOT automatic across lines. UI-layer changes are ported deliberately
(USP has a different file layout). Shared *logic* will move to a git-dep core
(see [[concepts/two-line-strategy]]); until then, port by hand and verify.

## Related
- [[concepts/two-line-strategy]]
- [[processes/build-and-deploy]]
- [[roadmap]]

## Last Verified
2026-06-08
