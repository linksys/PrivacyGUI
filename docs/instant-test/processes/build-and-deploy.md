# Process: Build & Deploy to the Local Router

> How to get Instant-Test changes onto the M60 at 192.168.1.1 for testing.

## When To Use
Any time you want to see a code change live on the router (UI-only changes).

## The Canonical Way — use the script
```bash
cd ~/Projects/PrivacyGUI
./scripts/deploy_local.sh
```
This is the ONLY supported quick-deploy. Do NOT improvise `flutter build web` + `scp`.

### Why the script (what it gets right)
1. `--dart-define=force=local` — **REQUIRED**. Without it the web app sends JNAP
   calls to a malformed URL and fails to authenticate.
2. `--no-tree-shake-icons` — keeps icon fonts.
3. Uses the HTML renderer (production renderer). A plain `flutter build web`
   defaults to canvaskit (~4× larger, wrong for this target).
4. Legacy SSH algos the router needs: `scp -O -o KexAlgorithms=+diffie-hellman-group1-sha1 -o HostKeyAlgorithms=+ssh-rsa`.
5. Auth via `sshpass -f ~/.secrets/router-pass` (never echo the secret).

## Verify After Deploy
**A new browser session/private window is required** — Flutter's service worker
(`flutter_service_worker.js`, `flutter-app-cache`) caches the old bundle and a
plain hard-refresh does NOT reliably evict it. Open a fresh/incognito window.

Server-side sanity (independent of browser cache):
```bash
curl -sk https://192.168.1.1/main.dart.js | md5
# compare to the "main.dart.js":"<hash>" entry in
curl -sk https://192.168.1.1/flutter_service_worker.js
# match → deploy is correct; "not showing" is browser cache.
```

## Full Firmware Build (when you need an .img)
Two-step Jenkins pipeline (GUI on jenkins-cloud → firmware on jenkins-fw,
`fw.linksyswrt.build.devops`, `CUSTOMER_NAME=CF`, `UI_VER={build}`). Details in the
PRODUCT_MANAGEMENT docs `Context/build-and-deploy.md`. ~1 hour.

## Key Details
- Router on JNAP firmware required for the JNAP branch GUI; USP branch needs USP firmware.
- `version.json` is unreliable after an overlay deploy (it isn't rewritten) —
  fingerprint the code, not the version stamp.

## Related
- [[processes/branch-strategy]]
- [[overview]]

## Last Verified
2026-06-08
