# Instant-Test Wiki — Index

> Project knowledge base for the Instant-Test customer WiFi diagnostic feature.
> Lives in-repo so it travels with the code. Mirrors the Linksys Engineering Wiki schema.

Last updated: 2026-06-09

---

## Start Here

| Page | Summary |
|------|---------|
| [[overview]] | What Instant-Test is, who it's for, the two-line (JNAP/USP) reality |
| [[code-map]] | Where every file lives, what each does, route entry points |
| [[feature-linkage-map]] | Cross-surface action duplication map — change-everywhere reference |

## Concepts

| Page | Summary |
|------|---------|
| [[concepts/two-line-strategy]] | JNAP + USP parallel lines; shared-core-via-git-dep model |
| [[concepts/verdict-engine]] | How diagnostics become customer-facing findings |
| [[concepts/design-system]] | AppCard framing, color matching to dashboardMenu, SelectionArea |

## Processes

| Page | Summary |
|------|---------|
| [[processes/build-and-deploy]] | Canonical deploy: scripts/deploy_local.sh (force=local). Don't improvise. |
| [[processes/branch-strategy]] | Two long-lived branches, what each is for |

## Reference

| Page | Summary |
|------|---------|
| [[reference/jnap-calls]] | JNAP actions the feature uses |
| [[reference/shared-helpers]] | restart_helper, device_actions — the unified action helpers |

## Planning

| Page | Summary |
|------|---------|
| [[next-steps]] | **START HERE next session** — done/outstanding/validation after 2026-06-09/10 |
| [[roadmap]] | Improvement queue (I-1…I-8), backlog, what's done vs remaining |
| [[usp-port-plan]] | USP branch port plan + change classification |

---

## Maintenance
- New info from a session/PR → update the affected page, bump its `Last Verified`, add to [[log]].
- Interlink with `[[page-name]]`. Every page links ≥2 others.
- File names: lowercase-hyphens. Titles: Title Case H1.
