# PrivacyGUI: YAML 定義檔產生與轉換策略 (Phase 2 Strategy)

由於我們需要從舊有的 JNAP (JSON) 轉換到 USP (TR-181)，而且團隊中沒有現成的 YAML 定義檔可以使用，本文件規劃了如何「**有系統地產生這些 YAML 定義檔**」。

## 核心策略：以畫面需求驅動 (UI-Driven Definition)

我們不應該一開始就試圖把 Router 所有的 TR-181 樹狀結構寫成 YAML，這會耗費太多時間且產生許多用不到的屬性。
正確的做法是「**UI 需要什麼，YAML 就寫什麼**」。

我們將依照目前的 UI Provider / Screen 分成幾個小模組來各個擊破：

### 步驟一：全面盤點專案中的 JNAP Actions (Codebase Audit)
不能只依賴 `jnap_to_usp_actions_mapper.dart` 這種概念驗證 (PoC) 過渡產物，必須深入掃描整個專案 `lib/` 底下所有的 `services/`、`providers/` 或 `repositories/`。
尋找所有使用到 `JNAPAction.*` 或是呼叫 JNAP API 的地方。
例如，以 `Dashboard` 與 `WiFi` 為例：
- `DeviceInfoProvider` 呼叫了 `JNAPAction.getHardwareInfo`
- `WifiSettingsService` 呼叫了 `JNAPAction.getRadioInfo` 與 `setRadioInfo`

### 步驟二：對應官方 TR-181 樹狀結構 (Path Discovery)
拋棄舊有憑感覺或 Demo JSON 對應的方式。請嚴格查閱專案內已準備好的 **官方 TR-181 定義檔 (`doc/usp/tr-181-2-20-0-usp-full.xml`)**
在大量的 XML 節點中，搜尋對應的功能，找出正確的 Base Path 以及子屬性：
- 搜尋硬體資訊 $\rightarrow$ 確切對應至 `Device.DeviceInfo.` 裡面的 `Manufacturer`, `ModelName` 等節點。
- 搜尋無線電 $\rightarrow$ 對應至 `Device.WiFi.Radio.{i}.` 等節點。

### 步驟三：記錄對應狀態與異常 (Mapping Status Documentation)
在對應 TR-181 結構時，很有可能會遇到「無法直接對應」或「標準 TR-181 中根本沒有該欄位」的狀況。
必須將尋找的結果先製作成表格並持續維護於：**`doc/usp/integration/tr181_mapping_status.md`**。
- 將對應狀況分為：🟢 直接對應、🟡 需運算轉換、🔴 無法對應。
- 對於 🔴 無法對應的項目（如 `firmwareDate` 等特定自定義功能），後續需與 Firmware 團隊討論是否由 Router 端提供 `X_LINKSYS_` 開頭的自定義擴充節點，或是由 UI 放棄該顯示。

### 步驟四：撰寫基礎定義檔 (Base YAML)
在 `doc/usp/definitions/` 建立對應模組的檔名（例如 `system_info.yaml`）。
將找到的路徑填入，並賦予友善的 `field_name` 供 Dart 使用。

```yaml
# doc/usp/definitions/system_info.yaml
name: system_info
base_path: Device.DeviceInfo

parameters:
  - field_name: manufacturer
    path: Manufacturer
    type: string
    writable: false

  - field_name: up_time
    path: UpTime
    type: int
    writable: false
```

### 步驟五：撰寫轉換檔 (Transforms YAML)
檢查 UI 畫面上是否需要加工後的資料。例如：發現 UI 需要顯示「已開機 3 天」而不是「259200 秒」。
在 `doc/usp/transforms/` 建立對應檔名（例如 `system_info_ext.yaml`）。

```yaml
# doc/usp/transforms/system_info_ext.yaml
name: system_info
transforms:
  - name: up_time_display
    type: converter
    converter: seconds_to_dhms # 假設 codegen 支援的內建方法，或自己在 UI 擴充
    input: up_time
    output_type: string
```

### 步驟六：驗證與程式碼生成
執行 `./scripts/codegen.sh` (或手動指令)。
確認 `lib/generated/system_info.g.dart` 成功產生，且沒有語法錯誤。

---

## 預定執行的模組拆分計畫 (Work Breakdown)

建議在 Phase 2 實際動手時，不要一次做完，而是分下列幾個 Milestone 循序漸進：

1. **MIL-1: 基礎系統與設備資訊 (System & Device Info)**
   - 目標: `getHardwareInfo`, `getFirmwareUpdateState`
   - YAML: `hardware_info.yaml`, `firmware_status.yaml`
2. **MIL-2: 網路與連線狀態 (Network & Connectivity)**
   - 目標: `getDeviceNetwork`, `getWanStatus`
   - YAML: `wan_status.yaml`, `lan_config.yaml`
3. **MIL-3: 無線網路設定 (WiFi Settings)**
   - 目標: `getRadioInfo`, `setRadioInfo`
   - YAML: `wifi_radio.yaml`, `wifi_ssid.yaml` (會包含 writable 屬性)
4. **MIL-4: 連線設備列表 (Connected Devices)**
   - 目標: `getDevices` 以及 SSE 推播支援
   - YAML: `connected_devices.yaml` (包含 `subscription` 定義)
