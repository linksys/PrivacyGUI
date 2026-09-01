# Linksys PrivacyGUI

Flutter application for Linksys router management. The `dev-1.x` line uses the
JNAP control plane; newer product lines may use different management APIs.

## Optional Router AI loader

The web shell contains one deferred reference to
`/ai/linksys-ai.js`. PrivacyGUI owns only that stable integration point; the
`ai-msdm-web` firmware package owns the script and its supporting assets.

- A router without the optional package may return 404 for the script. The base
  Flutter application must continue loading normally.
- The bundle must not be copied into or compiled with PrivacyGUI.
- Query-string or fragment variants still count as references to the same
  bundle and must not create a duplicate loader.
- Keep the tag root-relative and deferred so it works independently of the
  Flutter base path and does not block application startup.

Run the loader contract before submitting a web-shell change:

```bash
python3 tools/test_router_ai_loader.py
```

## JNAP firmware build path

JNAP PrivacyGUI branches are built by the Jenkins Cloud
`private-gui-olympus` job with Flutter `3.27.1` and `BUILD_MODE=Upload`. The job
publishes `linksysnow.tgz`; its integer Jenkins build number is then passed to
the Jenkins v2 firmware pipeline as `UI_VER`.

For example, cloud build #550 produced LinksysNow `1.3.0.700550`, so the
firmware parameter is `UI_VER=550`, not the dotted installed version. A
firmware build request is not proof of integration: retain the generated
firmware metadata and verify the installed version after flashing.

Jenkins v2 firmware build #504 is the retained build-level proof for this
example. Its generated manifest records `ui_ver=550`, and image inspection
finds `/www/version.json` with `1.3.0.700550` plus the package-owned
`/www/ai/linksys-ai.js`. Installed-device loader behavior remains a separate
browser-acceptance gate and must not be inferred from image contents alone.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
