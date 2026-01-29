# AppSwitch Replacement Catalog

Generated: 2026-01-26

## Summary
- Total AppSwitch usages: 21 (excluding RemoteAwareSwitch component itself)
- Requires replacement (IMMEDIATE): 12
- Form mode (auto-protected): 5
- UI-only (no action): 4

## Immediate Mode Switches (Require RemoteAwareSwitch)

### lib/page/instant_admin/views/instant_admin_view.dart:313
**Switch Purpose:** Auto firmware update toggle
**onChanged Trace:** `ref.read(firmwareUpdateProvider.notifier).setFirmwareUpdatePolicy()` - immediately sets firmware update policy
**JNAP Impact:** Triggers `setFirmwareUpdatePolicy()` which saves firmware settings via JNAP
**Action:** REPLACE with RemoteAwareSwitch

### lib/page/dashboard/views/components/widgets/parts/wifi_card.dart:79
**Switch Purpose:** WiFi network enable/disable toggle
**onChanged Trace:** `_handleWifiToggled()` -> shows dialog -> `wifiProvider.save()` or `wifiProvider.saveToggleEnabled()`
**JNAP Impact:** Triggers immediate WiFi enable/disable JNAP operations via save methods
**Action:** REPLACE with RemoteAwareSwitch

### lib/page/vpn/views/vpn_status_tile.dart:59
**Switch Purpose:** VPN service enable/disable toggle
**onChanged Trace:** `ref.read(vpnProvider.notifier).setVPNService()` then `notifier.save()` via doSomethingWithSpinner
**JNAP Impact:** Triggers immediate VPN service JNAP SET operation
**Action:** REPLACE with RemoteAwareSwitch

### lib/page/dashboard/views/components/widgets/quick_panel.dart:158 (compact mode)
**Switch Purpose:** Instant Privacy and Night Mode toggles in compact view
**onChanged Trace:** Lines 90-105 (Privacy) and 115-122 (Night Mode) - both call notifier.save() immediately
**JNAP Impact:** Triggers immediate JNAP operations for privacy/night mode
**Action:** REPLACE with RemoteAwareSwitch

### lib/page/dashboard/views/components/widgets/quick_panel.dart:403 (normal mode)
**Switch Purpose:** Instant Privacy and Night Mode toggles in normal view
**onChanged Trace:** Lines 196-214 (Privacy) and 236-243 (Night Mode) - both call notifier.save() immediately
**JNAP Impact:** Triggers immediate JNAP operations for privacy/night mode
**Action:** REPLACE with RemoteAwareSwitch

### lib/page/dashboard/views/components/widgets/quick_panel.dart:345 (expanded mode)
**Switch Purpose:** Instant Privacy and Night Mode toggles in expanded view
**onChanged Trace:** Lines 275-291 (Privacy) and 300-307 (Night Mode) - both call notifier.save() immediately
**JNAP Impact:** Triggers immediate JNAP operations for privacy/night mode
**Action:** REPLACE with RemoteAwareSwitch

### lib/page/instant_privacy/views/instant_privacy_view.dart:313
**Switch Purpose:** Instant Privacy enable/disable toggle
**onChanged Trace:** `_showEnableDialog()` -> confirms -> `_notifier.save()` via doSomethingWithSpinner
**JNAP Impact:** Triggers immediate MAC filtering JNAP SET operation
**Action:** REPLACE with RemoteAwareSwitch

### lib/page/instant_setup/model/impl/guest_wifi_step.dart:119
**Switch Purpose:** Guest WiFi enable toggle in setup wizard
**onChanged Trace:** `pnp.setStepData()` - updates local state for wizard
**JNAP Impact:** NO immediate JNAP operation - changes saved at wizard completion
**Action:** NO_ACTION (wizard context, not immediate mode)
**Reclassification:** FORM mode within setup wizard

### lib/page/instant_setup/model/impl/night_mode_step.dart:85
**Switch Purpose:** Night Mode enable toggle in setup wizard
**onChanged Trace:** `pnp.setStepData()` - updates local state for wizard
**JNAP Impact:** NO immediate JNAP operation - changes saved at wizard completion
**Action:** NO_ACTION (wizard context, not immediate mode)
**Reclassification:** FORM mode within setup wizard

---

## Form Mode Switches (Auto-Protected by UiKitBottomBarConfig)

### lib/page/wifi_settings/views/widgets/main_wifi_card.dart:102
**Switch Purpose:** WiFi band enable/disable
**Form Context:** Part of WiFi settings with UiKitBottomBarConfig in parent view - changes saved via Save button
**onChanged:** `ref.read(wifiBundleProvider.notifier).setWiFiEnabled(value, radio.radioID)` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/wifi_settings/views/widgets/main_wifi_card.dart:205
**Switch Purpose:** Broadcast SSID toggle
**Form Context:** Part of WiFi settings with UiKitBottomBarConfig in parent view
**onChanged:** `ref.read(wifiBundleProvider.notifier).setEnableBoardcast(value, radio.radioID)` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/wifi_settings/views/mac_filter/mac_filtering_view.dart:165
**Switch Purpose:** MAC filtering enable toggle
**Form Context:** Part of WiFi settings with UiKitBottomBarConfig in parent view
**onChanged:** `notifier.setMacFilterMode()` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/wifi_settings/views/advanced/wifi_advanced_settings_view.dart:193
**Switch Purpose:** Client steering, node steering, DFS, MLO, IPTV toggles
**Form Context:** Part of WiFi settings with UiKitBottomBarConfig in parent view
**onChanged:** Multiple calls like `notifier.setClientSteeringEnabled(value)` - all update local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/wifi_settings/views/widgets/guest_wifi_card.dart:67
**Switch Purpose:** Guest WiFi enable toggle
**Form Context:** Part of WiFi settings with UiKitBottomBarConfig in parent view
**onChanged:** `ref.read(wifiBundleProvider.notifier).setWiFiEnabled(value)` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/advanced_settings/internet_settings/widgets/optional_settings_form.dart:309
**Switch Purpose:** MAC address clone enable toggle
**Form Context:** Part of internet settings form with UiKitBottomBarConfig in parent view
**onChanged:** `notifier.updateMacAddressCloneEnable(value)` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/advanced_settings/dmz/views/dmz_settings_view.dart:109
**Switch Purpose:** DMZ enable toggle
**Form Context:** Has UiKitBottomBarConfig at line 79-99 with Save button
**onChanged:** `ref.read(dmzSettingsProvider.notifier).setSettings()` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/vpn/views/vpn_settings_page.dart:581
**Switch Purpose:** VPN enabled toggle
**Form Context:** Has UiKitBottomBarConfig at line 179-183 with Save button
**onChanged:** `notifier.setVPNService()` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/vpn/views/vpn_settings_page.dart:603
**Switch Purpose:** VPN auto-connect toggle
**Form Context:** Has UiKitBottomBarConfig at line 179-183 with Save button
**onChanged:** `notifier.setVPNService()` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/instant_safety/views/instant_safety_view.dart:62
**Switch Purpose:** Instant Safety (safe browsing) enable toggle
**Form Context:** Has UiKitBottomBarConfig at line 44-47 with Save button
**onChanged:** `_notifier.setSafeBrowsingEnabled(enable)` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

### lib/page/advanced_settings/apps_and_gaming/ddns/views/dyn_ddns_form.dart:168
**Switch Purpose:** Backup MX toggle
**Form Context:** This is a form component used within a page with UiKitBottomBarConfig
**onChanged:** Updates form model via `widget.onFormChanged.call()` - local state only
**Action:** NO_ACTION (auto-protected by parent's UiKitBottomBarConfig Save button)

### lib/page/advanced_settings/apps_and_gaming/ddns/views/dyn_ddns_form.dart:186
**Switch Purpose:** Wildcard toggle
**Form Context:** This is a form component used within a page with UiKitBottomBarConfig
**onChanged:** Updates form model via `widget.onFormChanged.call()` - local state only
**Action:** NO_ACTION (auto-protected by parent's UiKitBottomBarConfig Save button)

### lib/page/instant_admin/views/timezone_view.dart:149
**Switch Purpose:** Daylight savings time toggle
**Form Context:** Has UiKitBottomBarConfig at line 61-77 with Save button
**onChanged:** `_notifier.setDaylightSaving(value)` - updates local state only
**Action:** NO_ACTION (auto-protected by UiKitBottomBarConfig Save button)

---

## UI-Only Switches (No JNAP Operations)

### lib/page/dashboard/views/components/settings/dashboard_layout_settings_panel.dart:199
**Switch Purpose:** Dashboard widget visibility toggle
**Reason:** Pure UI preference - toggles visibility of dashboard widgets, no JNAP operations
**onChanged:** `ref.read(dashboardPreferencesProvider.notifier).setVisibility()` - updates local preferences only
**Action:** NO_ACTION

### lib/page/wifi_settings/views/main/wifi_list_view.dart:101
**Switch Purpose:** Quick setup mode toggle
**Reason:** UI mode switch - toggles between simple and advanced WiFi configuration views, no JNAP operations
**onChanged:** `notifier.setSimpleMode(value)` - updates local UI state only
**Action:** NO_ACTION

### lib/page/components/composed/app_switch_trigger_tile.dart:100
**Switch Purpose:** Generic reusable switch component
**Reason:** This is a composed component that wraps AppSwitch - not a direct usage, serves as a wrapper
**Action:** NO_ACTION (this is a reusable component wrapper)

### lib/page/components/composed/app_loadable_widget.dart:190
**Switch Purpose:** Generic loadable switch component
**Reason:** This is a composed component that wraps AppSwitch - not a direct usage, serves as a wrapper for async operations
**Action:** NO_ACTION (this is a reusable component wrapper)

---

## Analysis Notes

### Total Switches by Category:
1. **IMMEDIATE mode (12 switches)** - Require RemoteAwareSwitch replacement:
   - instant_admin_view.dart (1)
   - wifi_card.dart (1)
   - vpn_status_tile.dart (1)
   - quick_panel.dart (6 - across 3 display modes)
   - instant_privacy_view.dart (1)
   - guest_wifi_step.dart (1) - reclassified to FORM
   - night_mode_step.dart (1) - reclassified to FORM

2. **FORM mode (13 switches)** - Auto-protected by UiKitBottomBarConfig:
   - main_wifi_card.dart (2)
   - mac_filtering_view.dart (1)
   - wifi_advanced_settings_view.dart (5)
   - guest_wifi_card.dart (1)
   - optional_settings_form.dart (1)
   - dmz_settings_view.dart (1)
   - vpn_settings_page.dart (2)
   - instant_safety_view.dart (1)
   - dyn_ddns_form.dart (2)
   - timezone_view.dart (1)
   - guest_wifi_step.dart (1) - wizard form
   - night_mode_step.dart (1) - wizard form

3. **UI_ONLY (4 switches)** - No JNAP operations:
   - dashboard_layout_settings_panel.dart (1)
   - wifi_list_view.dart (1)
   - app_switch_trigger_tile.dart (1 - wrapper component)
   - app_loadable_widget.dart (1 - wrapper component)

### Implementation Priority:
**High Priority** - Immediate mode switches that trigger JNAP operations:
1. instant_admin_view.dart:313 - Firmware update
2. wifi_card.dart:79 - WiFi enable/disable
3. vpn_status_tile.dart:59 - VPN service toggle
4. quick_panel.dart (all 6 instances) - Dashboard quick actions
5. instant_privacy_view.dart:313 - Instant Privacy toggle

**No Action Needed** - Form mode and UI-only switches are already protected by existing patterns.

### Reclassifications:
- guest_wifi_step.dart and night_mode_step.dart were initially categorized as IMMEDIATE but are actually FORM mode within the setup wizard context. They save changes at wizard completion, not immediately.
