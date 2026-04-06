# Instant-Help Production Build Guide

## Quick Reference: Build & Deploy Runbook

**Prerequisites:** Fortinet VPN connected, code pushed to `origin/feature/wifi-troubleshooter`

### Pre-flight checks

```bash
cd ~/Projects/PrivacyGUI

# Must pass before any build
fvm flutter analyze lib/page/cs_diagnostic/    # Expect: 0 issues
fvm flutter test test/page/cs_diagnostic/      # Expect: 135/135 pass

# Push code
git push origin feature/wifi-troubleshooter
```

### Path 1: GUI-only deploy (fast — dev testing)

```bash
# 1. Build GUI on jenkins-cloud (~2-3 min)
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-cloud-token)" \
  "https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/buildWithParameters" \
  --data-urlencode "FlutterVersion=3.27.1" \
  --data-urlencode "Branch=origin/feature/wifi-troubleshooter" \
  --data-urlencode "Env=Production" \
  --data-urlencode "BUILD_MODE=Upload" \
  --data-urlencode "Compress=false" \
  --data-urlencode "UI_DEBUG=false"

# 2. Wait for success, note the build number (e.g. 493)
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-cloud-token)" \
  "https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/lastBuild/api/json?tree=number,result,building"

# 3. Download linksysnow.tgz from Jenkins artifacts page, then deploy:
scp linksysnow.tgz root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "cd /www && tar xzf /tmp/linksysnow.tgz"
```

### Path 2: Full firmware image (production — ISP delivery)

```bash
# 1. Build GUI (same as Path 1 step 1 above)
#    Wait for success. Note the build number — used in all subsequent steps.
#    Example: GUI_BUILD=493

# 2. Mirror GUI artifact to FW build repos (~30-60s)
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  -X POST "https://jenkins-fw.lswf.net/job/mirror-ui-privacygui/buildWithParameters" \
  --data-urlencode "BuildNumber=493"

# Check mirror status
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  "https://jenkins-fw.lswf.net/job/mirror-ui-privacygui/lastBuild/api/json?tree=number,result,building"

# 3. Build firmware with GUI (~49 min with Super)
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  -X POST "https://jenkins-fw.lswf.net/job/fw.linksyswrt.build.ui.dev/buildWithParameters" \
  --data-urlencode "GIT_BRANCH=origin/Pinnacle2.0-spf12.5_csu1" \
  --data-urlencode "GIT_COMMIT=" \
  --data-urlencode "BUILD_TYPE=release" \
  --data-urlencode "CUSTOMER_NAME=CF" \
  --data-urlencode "DEV_BUILD=true" \
  --data-urlencode "Performance=Super" \
  --data-urlencode "UI_BUILD_NU=493" \
  --data-urlencode "UI_VER_NU=2.0.0.700493"

# Check FW build status
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  "https://jenkins-fw.lswf.net/job/fw.linksyswrt.build.ui.dev/lastBuild/api/json?tree=number,result,building"

# 4. Download firmware image from Jenkins, then flash:
scp <firmware>.img root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "sysupgrade -n /tmp/<firmware>.img"
# WARNING: sysupgrade -n wipes config — device needs setup wizard after flash
```

### Path 2 alt: Manual firmware build (Jianrong's method — no jenkins-fw needed)

```bash
# 1. Build GUI (same as Path 1 step 1), download linksysnow.tgz artifact

# 2. Place tarball and rebuild
cp linksysnow.tgz Pinnacle2.0-spf12.5_csu1/store/sdk/qsdk/dl/linksysnow.tgz
cd Pinnacle2.0-spf12.5_csu1/store/sdk/qsdk
make package/linksysnow/{clean,compile}

# 3. Build firmware image
cd Pinnacle2.0-spf12.5_csu1/
make CUSTOMER_NAME=CF
```

### Key values to change per build

| Value | What to change | Pattern |
|-------|---------------|---------|
| `Branch` | Your PrivacyGUI branch | `origin/<branch-name>` |
| `BuildNumber` / `UI_BUILD_NU` | GUI build # from Step 1 | Integer from jenkins-cloud |
| `UI_VER_NU` | Version string | `2.0.0.700{BUILD_NU}` |
| `CUSTOMER_NAME` | ISP overlay | `CF` (CommunityFibre), `DU` (Du), empty (generic) |
| `GIT_BRANCH` | FW repo branch | `origin/Pinnacle2.0-spf12.5_csu1` |

### Pipeline verified on 2026-04-02

| Step | Jenkins | Job | Build # | Result |
|------|---------|-----|---------|--------|
| GUI | jenkins-cloud | `private-gui-olympus` | #493 | SUCCESS |
| Mirror | jenkins-fw | `mirror-ui-privacygui` | #18 | SUCCESS |
| FW+UI | jenkins-fw | `fw.linksyswrt.build.ui.dev` | #63 | IN PROGRESS |

---

## Overview

Instant-Help is a route (`/troubleshoot`) within the main PrivacyGUI Flutter Web app. It is NOT a separate deployment. Building PrivacyGUI includes Instant-Help automatically.

The build artifact replaces `/www/` on the router. The `/troubleshoot` route is handled client-side by go_router.

---

## Code Location

All Instant-Help code lives in the PrivacyGUI repo:

```
~/Projects/PrivacyGUI/
├── lib/page/cs_diagnostic/          # All Instant-Help source
│   ├── models/                      # DiagnosticClient, OUI lookup
│   ├── providers/                   # State, provider, auth
│   ├── services/                    # JNAP service, browser diagnostics, mock data
│   └── views/
│       ├── agent/                   # Support agent dashboard, flow analysis, report
│       └── customer/               # Customer flows (slow internet, slow device, can't connect)
├── lib/route/
│   ├── constants.dart              # RoutePath.csDiagnostic = '/troubleshoot'
│   ├── route_cs_diagnostic.dart    # Route definition
│   └── router_provider.dart        # Redirect bypass for /troubleshoot (line ~141)
└── test/page/cs_diagnostic/         # 135 automated tests
```

Branch: `feature/wifi-troubleshooter` (based on `dev-1.2.9`)

---

## Build Pipeline Overview

There are **two paths** to get Instant-Help onto a router:

| Path | Steps | When to Use |
|------|-------|-------------|
| **GUI-only deploy** | GUI build → SCP to router | Quick iteration, dev testing |
| **Full firmware image** | GUI build → Mirror → FW build → Flash | Production releases, ISP delivery |

Both paths start with the same GUI build on jenkins-cloud.

---

## Step 1: GUI Build (jenkins-cloud)

**Job:** `private-gui-olympus`
**URL:** `https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/`
**Source:** Austin's dev notes (2026-04-01)

> **IMPORTANT:** Use `private-gui-olympus` for ALL PrivacyGUI builds, including Pinnacle.
> Do NOT use `private-gui-openwrt` — it exists but is not properly configured.

### Via Jenkins Web UI (Austin's instructions)

1. Go to: `https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/`
2. Click "Build with Parameters"
3. Set:
   - **Flutter SDK:** `3.27.1`
   - **Branch:** your branch (e.g. `origin/feature/wifi-troubleshooter`)
   - **Env:** `Production` or `QA` (unused field — either works)
   - **Build mode:** `Upload`
   - **No need to check any checkbox or theme**
4. Click Build

### Via API (CLI)

```bash
# Trigger GUI build
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-cloud-token)" \
  "https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/buildWithParameters" \
  --data-urlencode "FlutterVersion=3.27.1" \
  --data-urlencode "Branch=origin/feature/wifi-troubleshooter" \
  --data-urlencode "Env=Production" \
  --data-urlencode "BUILD_MODE=Upload" \
  --data-urlencode "Compress=false" \
  --data-urlencode "UI_DEBUG=false"

# Check build status
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-cloud-token)" \
  "https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/lastBuild/api/json?tree=number,result,building,timestamp"
```

### Parameters (verified from Jenkins API)

| Parameter | Value | Notes |
|-----------|-------|-------|
| `FlutterVersion` | `3.27.1` | Flutter SDK version (choices: 3.27.1, 3.38.7, 3.29.0) |
| `Branch` | `origin/feature/wifi-troubleshooter` | Our working branch |
| `Env` | `Production` | Unused field — either Production or QA works |
| `BUILD_MODE` | `Upload` | Produces deployable artifact (choices: Daily, Upload, Release, NoTest) |
| `Compress` | `false` | No compression |
| `UI_DEBUG` | `false` | Disables force logout on poll failure |

Output: `linksysnow.tgz` artifact. Note the **build number** (e.g. `493`).

---

## Step 2a: GUI-Only Deploy to Router (Quick)

After Step 1 succeeds, download the `linksysnow.tgz` artifact and deploy directly:

```bash
# Download from Jenkins artifacts page, then:
scp linksysnow.tgz root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "cd /www && tar xzf /tmp/linksysnow.tgz"
```

This is the fastest path — no firmware rebuild needed. Good for dev testing and quick iterations.

---

## Step 2b: Full Firmware Image (Production)

To bake the GUI into a firmware image, there are two methods:

### Method A: Jenkins Pipeline (Automated)

**Step 2b-1: Mirror the GUI artifact**

The mirror job copies the GUI tarball from jenkins-cloud into the git repos used by firmware builds.

**Job:** `mirror-ui-privacygui` on **jenkins-fw**
**URL:** `https://jenkins-fw.lswf.net/job/mirror-ui-privacygui/`
**Parameter:** `BuildNumber` = the GUI build number from Step 1 (e.g. `493`)

```bash
# Trigger mirror
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  -X POST "https://jenkins-fw.lswf.net/job/mirror-ui-privacygui/buildWithParameters" \
  --data-urlencode "BuildNumber=493"

# Check mirror status
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  "https://jenkins-fw.lswf.net/job/mirror-ui-privacygui/lastBuild/api/json?tree=number,result,building"
```

**Step 2b-2: Build firmware with GUI**

**Job:** `fw.linksyswrt.build.ui.dev` on **jenkins-fw**
**URL:** `https://jenkins-fw.lswf.net/job/fw.linksyswrt.build.ui.dev/`

The FW build fetches the GUI tarball from:
`http://fw-qa-internal.lswf.net/private-gui-olympus/$UI_BUILD_NU/linksysnow.tgz`

```bash
# Trigger firmware + UI build
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  -X POST "https://jenkins-fw.lswf.net/job/fw.linksyswrt.build.ui.dev/buildWithParameters" \
  --data-urlencode "GIT_BRANCH=origin/Pinnacle2.0-spf12.5_csu1" \
  --data-urlencode "GIT_COMMIT=" \
  --data-urlencode "BUILD_TYPE=release" \
  --data-urlencode "CUSTOMER_NAME=CF" \
  --data-urlencode "DEV_BUILD=true" \
  --data-urlencode "Performance=Super" \
  --data-urlencode "UI_BUILD_NU=493" \
  --data-urlencode "UI_VER_NU=2.0.0.700493"

# Check FW build status (~49 min with Super)
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  "https://jenkins-fw.lswf.net/job/fw.linksyswrt.build.ui.dev/lastBuild/api/json?tree=number,result,building"
```

**Parameters (verified from Jenkins API):**

| Parameter | Value | Notes |
|-----------|-------|-------|
| `GIT_BRANCH` | `origin/Pinnacle2.0-spf12.5_csu1` | FW repo branch |
| `GIT_COMMIT` | _(empty)_ | Leave empty for HEAD of branch |
| `BUILD_TYPE` | `release` | Choices: release, production |
| `CUSTOMER_NAME` | `CF` | ISP customer overlay (CF=CommunityFibre, DU=Du, empty=generic) |
| `DEV_BUILD` | `true` | Dev build flag |
| `Performance` | `Super` | Build speed: Normal (100m), Fast (65m), Super (49m) |
| `UI_BUILD_NU` | `493` | GUI build number from Step 1 |
| `UI_VER_NU` | `2.0.0.700493` | UI version string (pattern: `2.0.0.700{BUILD_NU}`) |

### Method B: Manual Local Build (Jianrong's Method)

If Jenkins firmware access is unavailable, build on a machine with the firmware source:

```bash
# 1. Download linksysnow.tgz from jenkins-cloud Step 1 artifact

# 2. Place the GUI tarball
cp linksysnow.tgz Pinnacle2.0-spf12.5_csu1/store/sdk/qsdk/dl/linksysnow.tgz

# 3. Rebuild the LinksysNow package
cd Pinnacle2.0-spf12.5_csu1/store/sdk/qsdk
make package/linksysnow/{clean,compile}

# 4. Build the full firmware image
cd Pinnacle2.0-spf12.5_csu1/
make CUSTOMER_NAME=CF
```

**Alternative:** Update the Makefile to sync a specific build from Jenkins automatically:

```bash
# 1. Modify the Makefile to point to your build number
#    Edit: Pinnacle2.0-spf12.5_csu1/store/sdk/qsdk/feeds/linksys_feed/linksysnow/Makefile

# 2. Clean and rebuild
cd Pinnacle2.0-spf12.5_csu1/store/sdk/qsdk
rm -rf ./dl/linksysnow.tgz
make package/linksysnow/{clean,compile}

# 3. Build the firmware image
cd Pinnacle2.0-spf12.5_csu1/
make CUSTOMER_NAME=CF
```

Output: firmware `.img` file ready for flashing.

---

## Step 3: Flash Firmware to Router

```bash
# Full firmware flash via sysupgrade
scp <firmware>.img root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "sysupgrade -n /tmp/<firmware>.img"
```

**Warning:** `sysupgrade -n` wipes config. The device must go through the setup wizard before the dashboard works. `GetNodesWirelessNetworkConnections` depends on `devicedb` — if setup hasn't run, the poll aborts and the app force-logs out.

---

## Local Dev Build (No Jenkins)

For rapid development iteration:

```bash
cd ~/Projects/PrivacyGUI

# Build web artifact
~/.pub-cache/bin/fvm flutter build web

# Deploy directly to router via SCP
scp -r build/web/* root@192.168.1.1:/www/
```

For local testing with dev server:

```bash
# Terminal 1: Dev server
~/.pub-cache/bin/fvm flutter run -d web-server --web-port 8080 --dart-define=force=local

# Terminal 2: CORS-disabled Chrome (quit Chrome first)
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --disable-web-security --user-data-dir=/tmp/chrome-cors-dev \
  http://localhost:8080/#/troubleshoot
```

The `force=local` dart-define is for DEV ONLY (makes JNAP use `window.location.host`). Do NOT use it in production — production uses gateway IP from connectivity provider.

---

## PrivacyGUI Team Standards

Per Austin's dev notes:

1. **Branching:** Use `dev-1.2.9` as base. Don't merge into dev or main without PR + code review.
2. **Own branches OK:** Can push `feature/wifi-troubleshooter` without PR for testing/builds.
3. **Architecture:** Follow N-layer architecture with provider decoupling. Read `doc/` folder.
4. **Build script:** `build_web.sh` handles dart-defines. Parameters: `buildNumber force href cloud picker ca`
5. **Testing:** Run `flutter test test/page/cs_diagnostic/` before every push. 135 tests must pass.
6. **Analysis:** Run `flutter analyze lib/page/cs_diagnostic/` — must show 0 issues.

---

## Build Verification Checklist

Before triggering a production build:

- [ ] `flutter analyze lib/page/cs_diagnostic/` — 0 issues
- [ ] `flutter test test/page/cs_diagnostic/` — 135/135 pass
- [ ] No `force=local` dart-define in build (that's dev-only)
- [ ] No mock data enabled by default (mock FAB only shows when `useMock` is true)
- [ ] All changes committed and pushed to `origin/feature/wifi-troubleshooter`
- [ ] Speed test uses JNAP HealthCheck (agent mode) — no mock speed values
- [ ] Customer speed test hits real Cloudflare endpoints (not mock)

---

## What's on the Router After Build

```
/www/
├── index.html              # Flutter Web bootstrap
├── main.dart.js            # Compiled Flutter app (includes /troubleshoot)
├── flutter.js              # Flutter engine
├── flutter_bootstrap.js    # Bootstrap loader
├── manifest.json           # PWA manifest
├── assets/                 # Fonts, icons, resources
└── ...                     # Other static assets
```

The router's lighttpd serves everything under `/www/` on ports 80 and 443.
Users access `http://192.168.1.1/#/troubleshoot` — the `#` is Flutter's hash routing.

---

## Jenkins Access Notes

| Instance | URL | Token File | Purpose |
|----------|-----|------------|---------|
| jenkins-cloud | `https://jenkins-cloud.lswf.net` | `~/.secrets/jenkins-cloud-token` | GUI builds |
| jenkins-fw | `https://jenkins-fw.lswf.net` | `~/.secrets/jenkins-token` | FW builds, mirror |

Both require **Fortinet VPN**. Each has its own user database — tokens are NOT interchangeable.

**Note:** If you get 403 "missing Job/Build permission" on jenkins-fw, ask a Jenkins admin (Reza Rahimi) to grant Build permission. Deven's account was granted access on 2026-04-02.

---

## Firmware Team Ask List

These features need firmware team support (not blocking Phase 1):

1. **GetSystemStats CPU/Memory** — M60CF only returns `uptimeSeconds`. Need `CPULoad`, `MemoryLoad`.
2. **Debug log JNAP call** — Need endpoint to retrieve/stream router debug logs.
3. **GetSelectedChannels** — M60CF returns `_ErrorUnknownAction`. Need this for actual operating channel display.
