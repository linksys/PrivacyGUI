---
description: Manual testing workflow for PrivacyGUI web application with browser automation
---

# Manual Testing Workflow

This workflow guides the process of manually testing the PrivacyGUI web application using browser automation.

## Prerequisites

- Ensure you are in the PrivacyGUI project directory
- Have the router/mock server accessible at localhost
- User should provide the router password when prompted

## Steps

### 1. Start the Web Server

1. Execute background command: `nohup flutter run -d web-server --web-port 61672 --web-browser-flag --disable-web-security --dart-define force=local --target lib/main.dart < /dev/null > server.log 2>&1 & echo $! > flutter_pid.txt`
2. Pause for 15 seconds (to give Flutter time to start).
3. Read the last 20 lines of `server.log`.
4. Check the Log for "listening on" or URL information.
5. If successful, proceed with the test task; otherwise, report an error.

### 2. Open Browser and Navigate

Use the `browser_subagent` tool to:
1. Navigate to `https://localhost` (IMPORTANT: Do NOT include the port number 61672, use default HTTPS port)
2. If a certificate warning appears, bypass it by clicking "Advanced" → "Proceed to localhost"
3. Wait for the page to fully load

### 3. Determine Login State

Check the current URL/page state:

#### If Login Page (`#/localLoginPassword`)
1. The page shows "Log in" with a "Router Password" input field
2. **Ask the user for the password** if not provided
3. Click the password input field
4. Type the provided password
5. Click "Log in" button or press Enter
6. Wait for dashboard to load

#### If PNP Flow (Plug and Play Setup)
The PnP flow is detected when the URL contains `/pnp` or shows setup wizard UI.

**PnP Flow States** (reference: `doc/pnp/pnp-flow.md`):

| State | Description | Expected UI |
|-------|-------------|-------------|
| `AdminInitializing` | Initial checks running | Loading spinner |
| `AdminUnconfigured` | Router not yet configured | "Continue" button shown |
| `AdminAwaitingPassword` | Password required | Password input field |
| `AdminInternetConnected` | Connected, auto-advancing | Brief loading then wizard |
| `WizardConfiguring` | Setup wizard steps | PnpStepper with WiFi/Guest/Network config |
| `WizardSaved` | Configuration saved | Success message |
| `WizardWifiReady` | Setup complete | "Done" button to go to dashboard |
| `NoInternetRoute` | No internet connection | Troubleshooter views |

**PnP Step Components**:
- **Step 1**: WiFi Configuration (SSID, Password)
- **Step 2**: Guest Network (Optional)
- **Step 3**: Network Settings (Name It, Topology)
- **Final**: Firmware check and completion

### 4. Execute Test Instructions

Based on user's test instructions:
1. Navigate to the specified page/feature
2. Perform the requested actions (click buttons, fill forms, etc.)
3. Capture screenshots at key points
4. Record any errors or unexpected behaviors

**Common Test Areas**:
- **Dashboard**: Home, Menu, Network status
- **Instant-Devices**: Device list, filters, editing
- **Instant-WiFi**: WiFi settings, SSID changes
- **Instant-Admin**: Router password, firmware, timezone
- **Instant-Topology**: Node management, LED settings
- **Advanced Settings**: Detailed configuration
- **PnP Troubleshooter**: ISP settings, modem checks

### 5. Generate Test Results

After completing the test, generate a comprehensive report:

#### Create Test Report Artifact

Save to: `<artifact_dir>/test_report.md`

Include:
1. **Test Summary**: Date, time, test scope
2. **Environment**: Browser, URL, router model
3. **Test Steps Executed**: Numbered list of actions taken
4. **Results**: 
   - ✅ Passed items
   - ❌ Failed items with details
   - ⚠️ Warnings or observations
5. **Screenshots**: Embed captured screenshots using `![description](path)`
6. **Video Recording**: Reference the browser recording `.webp` file
7. **Recommendations**: Any suggested fixes or improvements

#### Example Report Structure

```markdown
# Manual Test Report

**Date**: YYYY-MM-DD HH:MM
**Tester**: Gemini Browser Agent
**Build**: Flutter Web

## Test Scope
[Description of what was tested]

## Test Environment
- URL: https://localhost/#/...
- Router/Mock: [Model info]
- Browser: Chrome (headless)

## Test Steps & Results

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | Login with password | Dashboard loads | Dashboard loaded | ✅ |
| 2 | Click Menu | Menu opens | Menu opened | ✅ |
| ... | ... | ... | ... | ... |

## Screenshots

![Dashboard after login](path/to/screenshot.png)

## Video Recording

Browser session recorded at: [path/to/recording.webp]

## Issues Found
[List any bugs or issues discovered]

## Recommendations
[Suggested fixes or improvements]
```

### 6. Cleanup (Optional)

If the test is complete and you want to stop the server:
```bash
if [ -f flutter_pid.txt ]; then
  kill $(cat flutter_pid.txt)
  rm flutter_pid.txt
  echo "Server stopped"
else
  echo "PID file not found"
fi
```

## Tips

- **SSL Issues**: Always use `https://localhost` instead of `http://localhost` for API calls to work properly
- **Flutter Web Rendering**: DOM may appear empty due to Flutter's canvas rendering; use pixel-based clicking
- **Wait Times**: Allow 3-5 seconds after navigation for Flutter to render
- **Screenshots**: Capture at every significant state change for documentation
- **PnP Testing**: May require router reset or mock mode to trigger PnP flow

## Related Documentation

- PnP Flow: `doc/pnp/pnp-flow.md`
- PnP Overview: `doc/pnp/pnp.md`
- Test Cases: `doc/tests/cases/`
- Screenshot Tests: `doc/screenshot_test/`