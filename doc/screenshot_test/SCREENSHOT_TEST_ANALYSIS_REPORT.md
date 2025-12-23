# Screenshot Test Analysis Report

**Generated**: 2025-12-23T22:30:00+08:00  
**Total Test Files**: 47  
**Analysis Based On**: `doc/screenshot_test/screenshot_testing_guideline.md`

---

## Summary Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| Files with View ID | 44 | 93.6% |
| Files with Summary Table | 26 | 55.3% |
| Files with expect() assertions | 44 | 93.6% |
| Files with Reference comment | 2 | 4.3% |

### Compliance Score by Category

| Category | Status |
|----------|--------|
| View ID Format (no hyphens) | ⚠️ 4 files have invalid format |
| Summary Table | ⚠️ 21 files missing |
| Test IDs | ✅ Most files compliant |
| Expect Assertions | ✅ 93.6% have assertions |

---

## Files Missing View ID (3 files)

| File | Recommended View ID |
|------|---------------------|
| `test/page/instant_setup/localizations/pnp_setup_view_test.dart` | `PNPS` |
| `test/page/instant_setup/localizations/pnp_admin_view_test.dart` | `PNPA` |
| `test/page/components/styled/top_bar_test.dart` | `TBAR` |

---

## Files with Invalid View ID Format (Contains Hyphens)

Per guideline: *"The View ID must consist of up to five uppercase English letters and must not contain hyphens (`-`) or underscores (`_`)."*

| File | Current View ID | Suggested Fix |
|------|-----------------|---------------|
| `pnp_isp_type_selection_view_test.dart` | `PNP-ISP-SEL` | `ISPSL` |
| `pnp_static_ip_view_test.dart` | `PNP-STATIC-IP` | `ISPST` |
| `pnp_isp_auth_view_test.dart` | `PNP-ISP-AUTH` | `ISPAU` |
| `pnp_pppoe_view_test.dart` | `PNP-PPPOE` | `ISPPP` |

---

## Files Missing Summary Table (21 files)

| File | View ID | Has Expects |
|------|---------|-------------|
| `internet_settings_view_test.dart` | ISET | ✅ 77 |
| `pnp_isp_type_selection_view_test.dart` | PNP-ISP-SEL | ✅ 23 |
| `pnp_static_ip_view_test.dart` | PNP-STATIC-IP | ✅ 26 |
| `pnp_isp_auth_view_test.dart` | PNP-ISP-AUTH | ✅ 11 |
| `pnp_pppoe_view_test.dart` | PNP-PPPOE | ✅ 22 |
| `instant_verify_view_test.dart` | IVER | ✅ 12 |
| `instant_admin_view_test.dart` | IADM | ✅ 14 |
| `instant_privacy_view_test.dart` | IPRV | ✅ 10 |
| `dashboard_home_view_test.dart` | DHOME | ✅ 23 |
| `instant_safety_view_test.dart` | ISAF | ✅ 6 |
| `wifi_main_view_test.dart` | WIFIS | ✅ 24 |
| `wifi_list_view_test.dart` | IWWL | ✅ 47 |
| `local_router_recovery_view_test.dart` | LRRV | ✅ 10 |
| `login_local_view_test.dart` | LGLV | ✅ 10 |
| `local_reset_router_password_view_test.dart` | LRRP | ✅ 12 |

---

## Files with Low Assertion Count (< 10 expects)

| File | View ID | Expect Count | Priority |
|------|---------|--------------|----------|
| `snack_bar_test.dart` | SNACKBAR | 0 | 🔴 Critical |
| `speed_test_external_test.dart` | STEXT | 0 | 🔴 Critical |
| `vpn_settings_page_test.dart` | VPN | 0 | 🔴 Critical |
| `top_bar_test.dart` | GENSET | 1 | 🔴 Critical |
| `auto_parent_first_login_view_test.dart` | APFLV | 3 | 🟡 Medium |
| `instant_safety_view_test.dart` | ISAF | 6 | 🟡 Medium |
| `dialogs_test.dart` | DIALOGS | 7 | 🟢 Low |
| `pnp_unplug_modem_view_test.dart` | PNPUM | 9 | 🟢 Low |

---

## Files with Summary Table (Compliant - 26 files)

✅ `apps_and_gaming_view_test.dart` (APPGAM)  
✅ `firewall_view_test.dart` (FWS)  
✅ `static_routing_view_test.dart` (SROUTE)  
✅ `administration_settings_view_test.dart` (ADMIN)  
✅ `dmz_settings_view_test.dart` (DMZS)  
✅ `advanced_settings_view_test.dart` (ADVSET)  
✅ `local_network_settings_view_test.dart` (LNS)  
✅ `dhcp_reservations_view_test.dart` (DHCPR)  
✅ `pnp_unplug_modem_view_test.dart` (PNPUM)  
✅ `pnp_no_internet_connection_view_test.dart` (PNPNI)  
✅ `pnp_modem_lights_off_view_test.dart` (PNPM)  
✅ `pnp_waiting_modem_view_test.dart` (PNPWM)  
✅ `firmware_update_detail_view_test.dart` (FUDV)  
✅ `manual_firmware_update_view_test.dart` (MFUV)  
✅ `node_detail_view_test.dart` (NDVL)  
✅ `add_nodes_view_test.dart` (ADDND)  
✅ `dashboard_menu_view_test.dart` (DMENU)  
✅ `dashboard_support_view_test.dart` (DSUP)  
✅ `snack_bar_test.dart` (SNACKBAR)  
✅ `top_bar_test.dart` (GENSET)  
✅ `dialogs_test.dart` (DIALOGS)  
✅ `select_device_view_test.dart` (IDSDV)  
✅ `instant_device_view_test.dart` (IDVC)  
✅ `device_detail_view_test.dart` (IDDV)  
✅ `auto_parent_first_login_view_test.dart` (APFLV)  
✅ `instant_topology_view_test.dart` (ITOP)  
✅ `speed_test_view_test.dart` (STV)  
✅ `speed_test_external_test.dart` (STEXT)

---

## Recommendations

### Priority 1: Critical Fixes (Immediate Action Required)

1. **Add expect() assertions** to files with 0 assertions:
   - `snack_bar_test.dart`
   - `speed_test_external_test.dart`
   - `vpn_settings_page_test.dart`
   - `top_bar_test.dart`

2. **Fix invalid View IDs** (remove hyphens):
   - `PNP-ISP-SEL` → `ISPSL`
   - `PNP-STATIC-IP` → `ISPST`
   - `PNP-ISP-AUTH` → `ISPAU`
   - `PNP-PPPOE` → `ISPPP`

3. **Add missing View IDs**:
   - `pnp_setup_view_test.dart` → `PNPS`
   - `pnp_admin_view_test.dart` → `PNPA`
   - `top_bar_test.dart` → `TBAR`

### Priority 2: Documentation Improvements

1. **Add Summary Tables** to 21 files listed above
2. **Add Reference comments** to all files (only 2 currently have them)
3. **Standardize golden file naming** to follow `[TestID]-[number]-[description]` pattern

### Priority 3: Test Quality Enhancements

1. Increase expect() assertion coverage in files with < 10 assertions
2. Review files with duplicate Test IDs (e.g., `static_routing_view_test.dart` has duplicate `SROUTE-EMPTY`)
3. Ensure all complex views mock all required Notifiers

---

## File-by-Module Breakdown

### Advanced Settings (9 files)
| File | View ID | Table | Expects | Status |
|------|---------|-------|---------|--------|
| administration_settings_view_test | ADMIN | ✅ | 22 | ✅ |
| apps_and_gaming_view_test | APPGAM | ✅ | 68 | ✅ |
| dmz_settings_view_test | DMZS | ✅ | 29 | ✅ |
| firewall_view_test | FWS | ✅ | 23 | ✅ |
| internet_settings_view_test | ISET | ❌ | 77 | ⚠️ |
| advanced_settings_view_test | ADVSET | ✅ | 18 | ✅ |
| local_network_settings_view_test | LNS | ✅ | 23 | ✅ |
| dhcp_reservations_view_test | DHCPR | ✅ | 31 | ✅ |
| static_routing_view_test | SROUTE | ✅ | 33 | ✅ |

### Dashboard (3 files)
| File | View ID | Table | Expects | Status |
|------|---------|-------|---------|--------|
| dashboard_home_view_test | DHOME | ❌ | 23 | ⚠️ |
| dashboard_menu_view_test | DMENU | ✅ | 25 | ✅ |
| dashboard_support_view_test | DSUP | ✅ | 16 | ✅ |

### Instant Setup (12 files)
| File | View ID | Table | Expects | Status |
|------|---------|-------|---------|--------|
| pnp_admin_view_test | ❌ | ❌ | 47 | 🔴 |
| pnp_setup_view_test | ❌ | ❌ | 37 | 🔴 |
| pnp_modem_lights_off_view_test | PNPM | ✅ | 16 | ✅ |
| pnp_no_internet_connection_view_test | PNPNI | ✅ | 18 | ✅ |
| pnp_unplug_modem_view_test | PNPUM | ✅ | 9 | ✅ |
| pnp_waiting_modem_view_test | PNPWM | ✅ | 10 | ✅ |
| pnp_isp_auth_view_test | PNP-ISP-AUTH | ❌ | 11 | 🟡 |
| pnp_isp_type_selection_view_test | PNP-ISP-SEL | ❌ | 23 | 🟡 |
| pnp_pppoe_view_test | PNP-PPPOE | ❌ | 22 | 🟡 |
| pnp_static_ip_view_test | PNP-STATIC-IP | ❌ | 26 | 🟡 |

---

## Conclusion

The screenshot test suite has **good overall coverage** with 47 test files. However, there are several areas for improvement:

1. **4 files have invalid View ID formats** (contain hyphens)
2. **3 files are missing View IDs entirely**
3. **21 files (44.7%) are missing Summary Tables**
4. **4 files have no expect() assertions** (screenshot-only tests)
5. **Only 2 files have Reference comments** pointing to implementation files

The recommended approach is to address Priority 1 issues first, as they represent violations of the testing guidelines. Priority 2 and 3 improvements can be addressed incrementally during regular maintenance.
