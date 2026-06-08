# Instant-Test — Overview

> Customer-facing WiFi diagnostic tool embedded in the PrivacyGUI router UI.

## What It Is
Instant-Test helps end customers and Linksys support agents diagnose home WiFi
problems from the browser at the router (`192.168.1.1`). It runs browser-based
speed/gateway/DNS tests, reads router state over JNAP/USP, and turns the results
into plain-language findings and guided fixes — no engineering knowledge required.

Four tabs:
1. **Instant-Test** (overview) — one-glance diagnostic summary + auto-fix actions
2. **My Devices** — connected devices, signal quality, per-device troubleshooting
3. **My Network** — internet/mesh/WiFi/guest overview
4. **Help Me Fix It** — 5 guided flows (slow, drops, device won't connect, etc.)

## Who It's For
- **End customers** — self-service, unauthenticated, simple language
- **Linksys support agents** — deeper diagnostics during a call

## What It Is NOT
No SSH, no serial, no TR-standards, no packet capture, no router-admin config.
Not an engineering tool. (That's Firmware_Inspector, a separate project.)

## The Two-Line Reality (important)
Instant-Test ships on **two parallel firmware platforms** that have fully forked:
- **JNAP line** — `feature/Instant-Troubleshooting` on `dev-1.2.9`, code in
  `lib/page/instant_verify/`. Currently the live/deployed line.
- **USP line** — `feature/instant-test-usp` on `dev-2.4.0`, code in
  `lib/page/instant_test/`. The platform direction.

Both are long-lived. See [[concepts/two-line-strategy]] and [[processes/branch-strategy]].

## Privacy
Every field collected (MACs, IPs, SSIDs) is GDPR PII. Session-only unless the
user explicitly shares (e.g. a future "Send to Support" handoff).

## Relationships
- [[code-map]] — where the code lives
- [[concepts/two-line-strategy]] — JNAP vs USP
- [[roadmap]] — what's planned

## Last Verified
2026-06-08
