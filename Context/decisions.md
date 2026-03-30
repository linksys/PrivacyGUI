# Decision Log

## 2026-03-30 — Project created

- Split from Firmware Inspector: customer tool vs. internal QA tool are separate concerns
- Flutter for all tiers: router already ships Flutter Web (privacy_gui v1.2.2 on lighttpd)
- Web-first delivery: install barrier paradox means Tier 0/1 ship before native app
- Admin URL confirmed: `http://192.168.1.1` (lighttpd, /www/ docroot, port 80/443)
- Tier 1 embed path: `http://192.168.1.1/troubleshoot` — infrastructure exists, needs firmware team buy-in
