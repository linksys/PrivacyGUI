# Decision Log

## 2026-04-02 — Login loop root cause identified, polling_provider reverted

- **Root cause:** `sysupgrade -n` (clean flash) wipes device config. `devicedb` doesn't start until setup wizard completes. `GetNodesWirelessNetworkConnections` (first call in polling transaction) depends on `devicedb` — fails → aborts entire transaction → force logout → loop.
- **Not our bug:** Production `origin/dev-1.2.9` has the identical transaction ordering and immediate-logout behavior. It works in production because customers always complete the setup wizard.
- **Reverted `polling_provider.dart`** back to exact production code. Our 3-consecutive-failure change was solving a non-customer problem and diverged from Austin's team's infrastructure code.
- **Lesson:** After any clean flash (`sysupgrade -n`), complete the setup wizard before testing the UI. Do not modify core polling infrastructure to work around dev-only issues.

## 2026-04-01 — Bug fixes, tests, first build

- **Login loop fix:** polling_provider.dart now requires 3 consecutive poll failures before force-logout (was 1). Prevents transient JNAP errors from kicking users to login screen.
- **DNS check fix:** Switched from `detectportal.firefox.com` (CORS-blocked from self-signed `192.168.1.1` origin) to Cloudflare `1.1.1.1/cdn-cgi/trace` + Google `generate_204` fallback.
- **Gateway ping fix:** Fast TLS rejection (< timeout) now treated as "reachable" — TCP connected but TLS rejected by self-signed cert still means gateway is up.
- **TX/RX data:** Extracted from `GetDevices3 → wirelessConnectionInfo` (Kbps→Mbps) as fallback when NodesWirelessNetworkConnections lacks rate data.
- **Wired clients:** Now merged from GetNetworkConnections when primary NodesWireless path returns wireless-only.
- **Radio channels:** Cross-references `getSelectedChannels` to show actual operating channel when config says "Auto".
- **Dark theme:** Brightened text across all agent views (label alpha 0.6→0.8, value text uses explicit onSurface, severity colors use lighter shade variants).
- **Unit tests:** 102 tests added (diagnostic_client, cs_diagnostic_state, mock_diagnostic_data). All passing.
- **GUI build #491:** Triggered on jenkins-cloud (`private-gui-olympus`), completed SUCCESS.
- **Firmware build:** `fw.linksyswrt.build.ui.dev` identified as the right job. Requires `Job/Build` permission on jenkins-fw (Deven's account lacks it — escalated).
- **Build pipeline:** Two Jenkins instances: jenkins-cloud (GUI tarball) → jenkins-fw (firmware image with UI baked in). UI_BUILD_NU parameter links them.

## 2026-03-30 — Project created

- Split from Firmware Inspector: customer tool vs. internal QA tool are separate concerns
- Flutter for all tiers: router already ships Flutter Web (privacy_gui v1.2.2 on lighttpd)
- Web-first delivery: install barrier paradox means Tier 0/1 ship before native app
- Admin URL confirmed: `http://192.168.1.1` (lighttpd, /www/ docroot, port 80/443)
- Tier 1 embed path: `http://192.168.1.1/troubleshoot` — infrastructure exists, needs firmware team buy-in
