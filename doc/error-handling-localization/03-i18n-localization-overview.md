# i18n Localization 修復計畫（合併版）

> **目標：** 處理掉專案內所有 hard-coded 顯示字串，最大程度 localization。
> **基礎：** 合併自 2026-06-03 的 hard-coded 稽核 + i18n 框架決策兩份報告，更新至當前進度。
> **已定案、不在本計畫內：** ❌ 不遷移 slang（保留 flutter_localizations，理由見 §6）；❌ CI 防線（非當前處理範圍）。
> **方法回顧：** grep 全量掃描 → 697 筆初步命中 → 6 路 subagent 逐筆判讀剔除誤報 → 分類。
>
> **🎉 狀態：P0 + P1 已全部完成（2026-06-19），共 ~844 處 hardcoded strings → localized**

---

## 1. TL;DR

- 全專案待 localize 的 hard-coded 顯示字串約 **460+ 筆**，集中在**新近 USP 遷移的 feature**（這些頁面開發時直接寫死英文、未補 ARB key）。
- 舊有 JNAP/legacy 頁面 + `app_en.arb`（~883 keys / 26 locales）本地化覆蓋良好；落差全來自 USP 新頁面。
- 框架維持 **flutter_localizations**（`loc(context).xxx`）——不換 slang。
- **error 訊息**這一塊的地基（ServiceError 型別化）已於近期重構完成（見 §3），是整個計畫中唯一已動工的部分。

---

## 2. 現況量化（2026-06-03 稽核，2026-06-16 抽查仍有效）

### 2.1 各區塊分布

| 區塊 | 涵蓋 feature | 確認 hard-coded | 主要嚴重度 |
|---|---|---|---|
| 1 | statistics, unified_diagnostics | ~147 | high（section 標題/副標題、診斷流程） |
| 2 | dashboard, devices | ~87 | medium（card 標題、dialog） |
| 3 | port_forwarding, wifi_settings | ~73 | medium（表單 label、空狀態句） |
| 4 | _shared, menu, firmware_update | ~46 | high（firmware 流程、menu 描述） |
| 5 | local_network, admin, dhcp, firewall, internet_settings | ~74 | 混合（admin/firewall 句子） |
| 6 | 其餘 page + components/util/ai/core | ~95 | 混合（ai_assistant 對話、instant_* 表單） |
| **合計** | — | **~460–522** | — |

> 數字為各 subagent 判讀彙整，含少量判準邊界差異（見 §7）。粗量化（`Text(` 60 + `AppText.` 306 = 366，未含命名參數類）與此量級吻合。

### 2.2 嚴重度定義

- **high**：完整句子、error/snackbar 訊息、使用者明顯看到的標題 → 優先
- **medium**：短 label、button、placeholder、tooltip
- **low**：技術詞/協定名（TCP/UDP/PPPoE/DMZ/dBm/Mbps…）、分隔符號 → 多數無需翻譯

### 2.3 最嚴重的檔案

| 檔案 | 數量 | 說明 |
|---|---|---|
| `firmware_update/views/firmware_update_view.dart` | ~22（全 high） | 上傳/驗證/重啟/完成等流程文案全寫死 |
| `menu/views/usp_menu_view.dart` | ~14 | 主選單每項標題 + 描述全寫死 |
| `dashboard/views/components/*` + dialogs | ~30+ | card 標題、DHCP/port/wifi dialog label |
| `statistics/views/sections/*` | ~35+ | 每個 stats section 的 title/subtitle |
| `unified_diagnostics/**` | ~50+ | speed test、診斷流程選單、manual tools |
| `wifi_settings/views/components/wifi_network_card.dart` | ~10 | Name/Password/Security mode/Channel 等 label |
| `port_forwarding/views/dialogs/*` | ~25 | port 規則 dialog label 與協定名 |
| `ai_assistant/views/router_assistant_view.dart` | ~8（high） | AI 對話 UI |
| `admin/views/usp_admin_view.dart` | ~7 | Reboot/Factory reset 動作與狀態句 |
| `dmz/views/usp_dmz_view.dart` | ~6 | DMZ 表單 label |
| `_shared/services/usp_pdf_service.dart` | ~8（medium） | PDF 報表標題（多語 PDF 才需處理） |

### 2.4 代表性樣本

**完整句子/狀態文案（high）**
```
firmware_update_view.dart  'Uploading firmware' / 'Verifying firmware' / 'Update complete' / 'Update failed'
admin/usp_admin_view.dart  'Router is rebooting' / 'Factory reset in progress'
local_network/...view.dart  'Change Network Settings?'
unified_diagnostics/.../diagnostic_flow_menu.dart  'What issue are you experiencing?'
ai_assistant/.../router_assistant_view.dart  'Confirmation Required'
```
**Error/Snackbar 訊息（high）** — 與 §3 的 ServiceError 工作直接相關
```
dmz/usp_dmz_view.dart  'Unable to load DMZ settings'
firewall/usp_firewall_view.dart  'Unable to load firewall settings'
dashboard/usp_dashboard_view.dart  'Unable to load USP data'
instant_privacy_view.dart  'Failed to enable Instant Privacy: $e'
```
**Section/Card 標題（high/medium）**
```
statistics/.../stats_traffic_monitor_section.dart  'Traffic Monitor'
menu/usp_menu_view.dart  'WiFi Settings' (+描述 'Networks, security, MAC filtering')
devices/cards/usp_connected_devices_card.dart  'Connected Devices'
```
**表單 Label/Placeholder（medium/low）**
```
wifi_network_card.dart  'Name' / 'Password' / 'Security mode'
dashboard/.../dhcp_reservation_dialog.dart  'MAC Address (e.g. AA:BB:CC:DD:EE:FF)'
dmz/usp_dmz_view.dart  'e.g. 192.168.1.0/24'
```
**技術詞/協定名（low，多數不翻）**：`TCP` `UDP` `PPPoE` `DHCP` `WiFi` `Mbps` `dBm` `SSID` `DMZ` …

---

## 3. 進度追蹤

### 3.1 P0 + P1 已全部完成 ✅

| 範圍 | 文件 | 狀態 |
|------|------|------|
| ServiceError 診斷欄位重構 | `02-serviceerror-diagnostic-fields-DONE.md` | ✅ 完成 |
| Error 訊息 localization | `04-error-message-localization-plan.md` | ✅ 完成（PR #953） |
| Admin/Menu localization | `05-p0-admin-menu-localization-plan.md` | ✅ 完成 |
| Firmware Update localization | `06-p0-firmware-update-localization-plan.md` | ✅ 完成 |
| **P1 全區域 hardcoded strings** | `05-p0-hardcoded-strings-localization.md` | ✅ 完成 |

**P0 + P1 總計：~844 處 hardcoded strings → localized**

### 3.2 原始地基工作（已完成）

兩份原始報告（2026-06-03）都指出「真正該做的事」之一是**重構 notifier/service 錯誤模型，讓 View 用 `loc()` 翻譯**。這部分的地基已於近期重構完成：

- `ServiceError` 基類加 `code` / `detail`（診斷用），移除 5 子類各自的 `message`、統一 `detail`。
- `mapUspErrorToServiceError` 各 `_mapXxx` 保留 `code` + `detail`。
- `UspCompleteFailureError` / `UspPartialFailureError` 改存 `List<UspErrorDetail> failures`（完整 path+code+message）。
- **結果：firmware fault code / 原始訊息不再流失到 ServiceError**——View 之後能依型別 + code 產出在地化訊息。

> 詳見 `01-usp-error-roundtrip-reference.md` §4（localization 大方向）。

---

## 4. 修復優先順序

> 已排除（不修）：`test_console`（USP 偵錯工具）、`demo/theme_studio`（開發工具）、Service 層 error 文本（自 firmware 上傳、非 App 決定）。

| 優先 | 範圍 | 為何 | 狀態 |
|---|---|---|---|
| **P0** | **error/snackbar 訊息** + firmware_update 流程 + admin 動作 + menu 描述 | 使用者最常見、最影響體驗的 high 項 | ✅ **完成** |
| **P1** | statistics / diagnostics / dashboard / wifi / port_forwarding / devices / _shared 等全區域 | 量大但機械、覆蓋主要 USP 頁面 | ✅ **完成** |
| **P2** | 技術詞（多數可不翻，僅統一）、PDF 報表多語 | 低價值或特殊情境 | ⏭️ 跳過（技術詞本就不翻、PDF 為靜態報告） |

### 共通做法（不分優先序）
1. 以 feature 為單位，把字串抽進 `app_en.arb`（沿用既有 camelCase 命名）。
2. View 改用 `loc(context).xxx`。
3. error 類另循 §3 的型別化路徑（View 依 ServiceError 型別翻譯，而非顯示 raw `toString()`）。
4. 其他 26 locale 的翻譯後補。

---

## 5. 根因（為何會累積這麼多）

- **USP 遷移頁面未沿用 l10n 慣例**：`loc(context)` 機制健全，但新 USP feature 快速開發時直接寫死英文、未補 ARB key。
- **notifier 直接組裝錯誤文案**（架構缺口）：~35–40 個 notifier 在無 context 處寫死英文錯誤——這是 §3 重構在解的問題，非框架問題。
- dashboard widget i18n 本就標為 "future feature"（見 `doc/dashboard-widget-card-authoring-guide.md`）。

---

## 6. 框架決策：維持 flutter_localizations（不遷移 slang）

> 完整論證見本檔 §6（原 i18n-slang-migration-decision.md 已併入），此處留結論。

- 遷移 slang 的觸發動機是「無 context 翻譯」，但本專案此需求**實測為 0**——所有錯誤文案都可（且應）在 View 層用 context 翻譯，notifier/service 只回型別。
- flutter_localizations **也能**無 context（`AppLocalizations.delegate.load` 等），非 slang 獨佔。
- 遷移成本中-大（361 處呼叫改寫 + 12 個 rich-text key 需重新設計 parser + 單作者 bus-factor 風險），換到的主要是 DX 甜度 → ROI 為負。
- 結論：**不遷移**。真問題是「開發紀律 + notifier 架構」，不是框架。

---

## 7. 判準邊界（列入與否的政策）

| 類別 | 範例 | 處置 |
|---|---|---|
| Service 層 error 文本 | `ServiceNotInitializedError('USP service not available')` | **排除**（自 firmware、非 App 決定） |
| 字串插值 | `'WiFi: ${count}'` vs 純 `'$count'` | 含字面文案者**列入**，純變數**剔除** |
| `semanticLabel` | `'unsaved-go-back'` | **剔除**（a11y 識別碼，非顯示文字） |
| ARB placeholder metadata | `description: 'time'` | **剔除**（ARB 結構欄位） |
| LLM 工具 description | 餵給 LLM 的工具定義 | **剔除**（非 UI） |
| 分隔符號 | `'|'` `'#'` `'--'` `'N/A'` | 列入但標 low |

> grep 初步 697 → 各 agent 剔除約 150–170 筆誤報（service error / 純變數 / ARB metadata / semanticLabel），誤報率約 22%。

---

## 附錄：掃描指令（可重現）

```bash
grep -rEn "Text\(\s*(const\s+)?['\"][^'\"]" lib --include="*.dart"
grep -rEn "AppText\.[a-zA-Z]+\(\s*(const\s+)?['\"][^'\"]" lib --include="*.dart"
grep -rEn "(hintText|labelText|helperText|errorText|tooltip|title|header|message|content|description|placeholder):\s*(const\s+)?['\"][^'\"]" lib --include="*.dart"
# 排除 codegen 與已 loc 化
| grep -vE "lib/l10n/gen/|\.g\.dart:|\.freezed\.dart:" | grep -vE "loc\("
```
> grep 為初步篩選，最終需逐筆讀上下文判讀。
