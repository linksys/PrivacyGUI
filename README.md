# Linksys PrivacyGUI

Flutter application for Linksys router management. The `dev-1.x` line uses the
JNAP control plane; newer product lines may use different management APIs.

## Router AI (Instant AI) build flag

Router AI client code ships only in builds made with `ENABLE_ROUTER_AI=true`.
`build_web.sh` reads it (default `false`; anything other than exactly `true`
or `false` fails the build) and passes `--dart-define=enable_router_ai=...`.
`BuildConfig.enableRouterAi` is `const`, so a default build compiles the AI
paths out:

| | Default build (flag off) | Router AI build (`ENABLE_ROUTER_AI=true`) |
|---|---|---|
| Widget bundle `/ai/linksys-ai.js` | never referenced | one deferred, root-relative `<script>` added at startup |
| Local login | unchanged; no AI request | password posted once to `/cgi-bin/ai-session.cgi` |
| Logout / idle logout / startup | unchanged; no AI request | AI session revoked; conversation cleared |

Only AI-enabled firmware lanes (for example the CF test images, pinned with
`UI_VER`) use a Router AI build.

## Optional Router AI loader

In a Router AI build, `lib/core/ai_session/router_ai_loader.dart` adds one
deferred reference to `/ai/linksys-ai.js` before the first login. `web/index.html`
does not reference it. PrivacyGUI owns only that stable integration point; the
`ai-msdm-web` firmware package owns the script and its supporting assets.

- A router without the optional package may return 404 for the script. The base
  Flutter application must continue loading normally.
- The bundle must not be copied into or compiled with PrivacyGUI.
- Query-string or fragment variants still count as references to the same
  bundle and must not create a duplicate loader.
- Keep the tag root-relative and deferred so it works independently of the
  Flutter base path and does not block application startup.
- After local `CheckAdminPassword3` succeeds, PrivacyGUI posts the password once
  to `/cgi-bin/ai-session.cgi`. The endpoint validates it natively and returns
  an HttpOnly cookie; the chat JavaScript never receives the password. Logout
  revokes that server-side AI session. Failure or absence of the optional AI
  endpoint must not break the normal router login/logout workflow.

Run the loader and build-flag contract before submitting a web-shell change:

```bash
python3 tools/test_router_ai_loader.py
```

## Optional AI sessions

In a Router AI build, the optional AI session bootstrap and revocation run independently of native
router login/logout. Each AI request has a five-second deadline; logout aborts
pending bootstrap requests before revocation so a delayed response cannot
restore the browser session. AI unavailability leaves native authentication
usable. Revocation retries transient failures (three attempts with backoff),
a newer login supersedes a pending retry loop, and every GUI startup without
a restored local login sends a revocation so a stale cookie from a failed
logout cannot be resurrected by the widget's status poll. Successful
server-side revocation still requires the endpoint to be reachable within
the retry window.

Run the native-auth and transport regression tests in both build modes:

```bash
# Default build: proves no AI request and unchanged login/logout.
flutter test --no-pub test/core/ai_session/ai_session_service_test.dart test/providers/auth
# Router AI build: the AI session paths.
flutter test --no-pub --dart-define=enable_router_ai=true test/core/ai_session/ai_session_service_test.dart test/providers/auth
python3 tools/test_ai_session_browser.py
```

The browser test uses a loopback fixture and synthetic credentials. Set
`CHROME_EXECUTABLE` when Chrome is not on the default path; use `--flutter` to
select the Flutter executable.

## JNAP firmware build path

JNAP PrivacyGUI branches are built by the Jenkins Cloud
`private-gui-olympus` job with Flutter `3.27.1` and `BUILD_MODE=Upload`. The job
publishes `linksysnow.tgz`; its integer Jenkins build number is then passed to
the Jenkins v2 firmware pipeline as `UI_VER`.

For example, cloud build #550 produced LinksysNow `1.3.0.700550`, so the
firmware parameter is `UI_VER=550`, not the dotted installed version. A
firmware build request is not proof of integration: retain the generated
firmware metadata and verify the installed version after flashing.

Firmware integration validation confirmed both the package-owned
`/www/ai/linksys-ai.js` asset and the optional loader on an installed device.
The device-hosted browser suite covers package-present rendering and
package-absent non-interference. Exact build identities and hashes belong in
the private release evidence record; a build request alone is not proof of
integration.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
