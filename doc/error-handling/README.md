# Error Handling & Localization

Documentation for USP error handling and error-message localization. One through-line: **how an error flows from firmware all the way to the UI, and how to implement error handling and achieve localization by following the existing patterns**.

## Two documents

| Document | Answers | When to read |
|---|---|---|
| 📘 [**Implementation Guide**](error-handling-implementation-guide.md)<br>`error-handling-implementation-guide.md` | **"How to do it"** — when adding a USP feature page: how to write error handling across the Service / Provider / View layers, what to show, what not to show, how to localize, and a pre-PR checklist | Read before you start implementing |
| 📗 [**Round-trip Reference**](usp-error-handling-reference.md)<br>`usp-error-handling-reference.md` | **"Why"** — the full round trip of an error from firmware through WASM / codegen to the UI, the data format at each layer, an exhaustive list of error sources / forms, the difference between 9999 / 7xxx / 9xxx / 9998, and the cause of the two paths | When you're confused or need to investigate a root cause |

> **Suggested reading order**: read the **Implementation Guide** first (enough to write 80% of cases by following it). When you need to understand "why fetch and save have different error forms" or "how 9999 differs from 7xxx", then turn to the **Round-trip Reference**.

## Source of the existing patterns

The cross-cutting refactor of the error handling pipeline is in **PR #953** (`feat(l10n): centralize error message localization for USP features`). Every pattern in the Implementation Guide reflects the codebase as of after PR #953.

## Known, not yet fixed

- **GET 9999→9998 bug** (Round-trip Reference §2.5): a GET connection failure (9999) is disguised as an "invalid input" error (9998) at the transport layer. It is independent of localization and needs a separate fix — otherwise, no matter how good the l10n is, a GET connection failure will still be shown as "invalid input". Also summarized in the Implementation Guide §7 "Known limitations".
