# PrivacyGUI Build & Deploy Guide

How to build the PrivacyGUI Flutter web app and deploy it to a Linksys router.

## Prerequisites

- Fortinet VPN connected
- Jenkins account on **both** Jenkins instances (they have separate user databases)
- SSH access to target router (`root@192.168.1.1`)
- FVM (Flutter Version Manager) installed locally for dev builds

## Jenkins Instances

Linksys has **two separate Jenkins servers** with independent user databases:

| Instance | URL | What it builds |
|----------|-----|----------------|
| **jenkins-cloud** | `https://jenkins-cloud.lswf.net` | GUI-only builds (PrivacyGUI Flutter web) |
| **jenkins-fw** | `https://jenkins-fw.lswf.net` | Full firmware images |

An API token from one **will not work** on the other. Generate tokens separately on each.

## Setting Up Jenkins API Tokens

### 1. Generate tokens

1. Log into `https://jenkins-cloud.lswf.net` (VPN required)
2. Click your name (top right) -> Configure
3. Under "API Token" click "Add new Token", give it a name, click Generate
4. Copy the token immediately (you won't see it again)
5. Repeat for `https://jenkins-fw.lswf.net` if you need firmware builds

### 2. Store tokens securely

```bash
# Create secrets directory
mkdir -p ~/.secrets && chmod 700 ~/.secrets

# Store credentials (replace with your values)
printf '%s' 'your.username' > ~/.secrets/jenkins-user
printf '%s' 'your-cloud-token-here' > ~/.secrets/jenkins-cloud-token
printf '%s' 'your-fw-token-here' > ~/.secrets/jenkins-token

# Lock permissions
chmod 600 ~/.secrets/*
```

> **Important:** Use `printf '%s'` (not `echo`) to avoid trailing newlines. Never pass tokens as CLI arguments or export to environment — both can leak to shell history and process listings.

### 3. Verify access

```bash
# Test jenkins-cloud (GUI builds)
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-cloud-token)" \
  "https://jenkins-cloud.lswf.net/api/json?tree=description" -w "\nHTTP: %{http_code}\n"

# Test jenkins-fw (firmware builds)
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  "https://jenkins-fw.lswf.net/api/json?tree=description" -w "\nHTTP: %{http_code}\n"
```

Both should return HTTP 200.

## GUI Build Job

Per Austin: use `private-gui-olympus` on **jenkins-cloud** for **all** PrivacyGUI builds (including Pinnacle).

- **Job:** `private-gui-olympus`
- **URL:** `https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/`

### Via Jenkins Web UI (Austin's instructions)

1. Go to: `https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/`
2. Click "Build with Parameters"
3. Set:
   - **Flutter SDK:** `3.27.1`
   - **Branch:** your branch (e.g. `origin/feature/wifi-troubleshooter`)
   - **Env:** `Production` or `QA` (unused field, either works)
   - **Build mode:** `Upload`
   - **No need to check any checkbox or theme**
4. Click Build

### Via API (CLI)

```bash
# Trigger build
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
  "https://jenkins-cloud.lswf.net/view/mobile/job/private-gui-olympus/lastBuild/api/json?tree=number,result,building"
```

### Deploy to router

```bash
scp <artifact>.tgz root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "cd /www && tar xzf /tmp/<artifact>.tgz"
```

## Option B: Local Dev Build (No Jenkins)

Build locally and SCP directly. Good for rapid iteration.

```bash
cd ~/Projects/PrivacyGUI
~/.pub-cache/bin/fvm flutter build web
scp -r build/web/* root@192.168.1.1:/www/
```

For local testing before deploying, use the dev server with a CORS-disabled Chrome:

```bash
# Terminal 1: Run dev server
~/.pub-cache/bin/fvm flutter run -d web-server --web-port 8080

# Terminal 2: Open CORS-disabled Chrome (quit Chrome first)
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --disable-web-security --user-data-dir=/tmp/chrome-cors-dev \
  http://localhost:8080/#/troubleshoot
```

## Option C: Full Firmware Build (GUI + Firmware Image)

Use when you need a complete firmware `.img` that includes your GUI changes. This is a two-step pipeline:

1. **GUI build** on jenkins-cloud produces a `linksysnow.tgz` tarball
2. **Firmware build** on jenkins-fw downloads that tarball and bakes it into the firmware image

### Step 1: GUI Build (jenkins-cloud)

Use Option A or A2 above to produce the GUI tarball. Note the **build number** when complete (e.g. `491`).

### Step 2: Firmware + UI Build (jenkins-fw)

**Job:** `fw.linksyswrt.build.ui.dev` on **jenkins-fw**

This job fetches the GUI tarball from: `http://fw-qa-internal.lswf.net/private-gui-olympus/$UI_BUILD_NU/linksysnow.tgz`

#### Parameters

| Parameter | Description | Example Value |
|-----------|-------------|---------------|
| `GIT_BRANCH` | Firmware repo branch | `origin/Pinnacle2.0-spf12.5_csu1` |
| `GIT_COMMIT` | Specific commit (leave empty for HEAD) | `` |
| `BUILD_TYPE` | `release` or `production` | `release` |
| `CUSTOMER_NAME` | ISP customer overlay (CF, DU, etc.) | `CF` |
| `DEV_BUILD` | Dev build flag | `true` |
| `Performance` | Build speed: Normal (100m), Fast (65m), Super (49m) | `Super` |
| `UI_BUILD_NU` | GUI build number from jenkins-cloud Step 1 | `491` |
| `UI_VER_NU` | UI version string (pattern: `2.0.0.700{BUILD_NU}`) | `2.0.0.700491` |

#### Via API (CLI)

```bash
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  -X POST "https://jenkins-fw.lswf.net/job/fw.linksyswrt.build.ui.dev/buildWithParameters" \
  --data-urlencode "GIT_BRANCH=origin/Pinnacle2.0-spf12.5_csu1" \
  --data-urlencode "GIT_COMMIT=" \
  --data-urlencode "BUILD_TYPE=release" \
  --data-urlencode "CUSTOMER_NAME=CF" \
  --data-urlencode "DEV_BUILD=true" \
  --data-urlencode "Performance=Super" \
  --data-urlencode "UI_BUILD_NU=491" \
  --data-urlencode "UI_VER_NU=2.0.0.700491"
```

#### Via Jenkins Web UI

1. Go to: `https://jenkins-fw.lswf.net/job/fw.linksyswrt.build.ui.dev/`
2. Click "Build with Parameters"
3. Fill in parameters per table above
4. Click Build (~49 minutes with Super performance)

#### Check Build Status

```bash
curl -s -u "$(cat ~/.secrets/jenkins-user):$(cat ~/.secrets/jenkins-token)" \
  "https://jenkins-fw.lswf.net/job/fw.linksyswrt.build.ui.dev/lastBuild/api/json?tree=number,result,building"
```

#### Known Permission Issue

Your jenkins-fw account may lack `Job/Build` permission even if you can read job configs. If you get "Access Denied: missing Job/Build permission", ask a Jenkins admin (Reza Rahimi created the job) or someone on the firmware team to either:
- Grant your account Build permission on `fw.linksyswrt.build.ui.dev`
- Trigger the build for you with your parameters

### Alternative: Manual Firmware Build (Jianrong's Method)

If Jenkins firmware access is unavailable, build locally on a machine with the firmware source:

```bash
# 1. Place the GUI tarball (from jenkins-cloud build artifact)
cp linksysnow.tgz Pinnacle2.0-spf12.5_csu1/store/sdk/qsdk/dl/linksysnow.tgz

# 2. Rebuild the LinksysNow package
cd Pinnacle2.0-spf12.5_csu1/store/sdk/qsdk
make package/linksysnow/{clean,compile}

# 3. Build the full firmware image
cd Pinnacle2.0-spf12.5_csu1/
make CUSTOMER_NAME=CF
```

Output: firmware `.img` file for flashing.

### Option D: Firmware-Only Build (No GUI Change)

**Job:** `fw.linksyswrt.pinnacle2.0.dev` on **jenkins-fw**

Use when you need a firmware rebuild without changing the GUI (e.g., kernel or package changes).

| Parameter | Description | Default |
|-----------|-------------|---------|
| `GIT_BRANCH` | Firmware branch | `origin/Pinnacle2.0-spf12.5_csu1` |
| `MAIN_ENV_S3` | S3 env (leave empty) | `` |

## Branching

- **Base branch:** `dev-1.2.9` (latest JNAP release branch)
- Feature branches off `dev-1.2.9`, PR back to `dev-1.2.9`
- Push own branches freely for testing/builds — no PR required for personal branches
- Don't merge into `dev` or `main` without PR + code review (per Austin)

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| 401 on jenkins-cloud | Wrong token / wrong instance | Generate token on jenkins-cloud specifically |
| 401 on jenkins-fw | Wrong token / wrong instance | Generate token on jenkins-fw specifically |
| Can't reach Jenkins | VPN disconnected | Connect Fortinet VPN |
| Build fails | Branch not pushed | `git push -u origin <branch>` first |
| Router shows old UI | Browser cache | Hard refresh (Cmd+Shift+R) or clear `/www/` first |
| Login loop after clean flash | `devicedb` not running — setup wizard never ran | Complete the setup wizard (connects to cloud, checks FW), or reboot the device. `sysupgrade -n` wipes config; the device must go through setup before the dashboard works. `GetNodesWirelessNetworkConnections` depends on `devicedb` and is the first call in the polling transaction — if it fails, the entire poll aborts and the app force-logs out. |
