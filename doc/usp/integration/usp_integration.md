# PrivacyGUI: USP 系統整合與架構重構指南 (Integration Guideline)

**版本:** v1.0.0
**最新更新:** 2026-02-24
**摘要:** 說明如何將專案中的 USP PoC（JNAP 攔截/轉發器與 gRPC）替換為內部 Platform 團隊規格下透過 WebAssembly 執行的原生物件 (目前全面以 Web 為目標平臺)，並透過 CodeGen 自動產生強型別存取 API。

---

## 1. 架構異動目的

由於目前的 USP 整合屬早期概念驗證（PoC），使用 `UspMapperRepository` 在中間將舊有 JNAP 的 JSON Request/Response 與 USP TR-181 發揮「轉接與翻譯」的作用。在模組規模擴大時，難以維護且容易產生同步延遲，也不具備高效的即時推送機制。

根據 `CODEGEN_GUIDE.md` 規範，最終解決方案將導入由 Platform 團隊以 Rust 打造的核心 `usp-client`（目前專案聚焦支援 WebAssembly，存放於 `lib/usp`），並利用 `usp-codegen` 以 YAML 定義表為基底產生 Dart 程式碼。

### 架構比較
| 項目 | 舊作法 (PoC) | 新標準寫法 (內部核心版本) |
|---|---|---|
| **底層客戶端** | 客製化 `usp_client_core` (依賴 gRPC 傳輸) | 內部 Platform 團隊提供的 `usp_client` 模組 (原生 WebAssembly，已放於 `lib/usp`) |
| **資料與欄位對應** | 手刻大量 `_mapXXX(response)` 將扁平鍵值轉成 JSON | `usp-codegen` 解析 `.yaml` 目錄，自動產生 Model Class |
| **衍生/單位邏輯** | 在 UI 的 View 層或 Provider 中自行判斷與算數 | 在 `_ext.yaml` 預先定義 `transforms`，CodeGen 生出 Getter (例如 `.uptimeHuman`) |
| **呼叫方式** | `routerRepository.send(JNAPAction...)` | `await WifiSsid.fetch(client)` |
| **資料監測** | 定時不斷重查 API (使用 `PollingManager`) | 原生物件自帶 `.subscribe(client).stream` 產生響應資料流 |

---

## 2. 遷移與執行四大階段 (Phases of Integration)

本系統的移植分為四個詳細步驟，需依序且分批引入：

### Phase 1: 專案清除與客戶端準備 (Project Cleanup & Client Preparation)
我們必須將原本專案中不需要的東西全部下架，直接使用已寫好的 Web 版 Client。
1. 重構 `pubspec.yaml`，完全移除對 `usp_client_core` 與 `usp_protocol_common` 目錄的使用。
2. 刪除 `lib/core/usp/usp_mapper_repository.dart` 及其關連之 Mapper 檔案。
3. 確認專案中 `lib/usp/web/usp_client_wasm.dart` 以及 `lib/usp/services/usp_service.dart` 能夠正確提供 JS Interop 功能。
4. 尋找與替換連線管理的提供者，將舊有 `usp_connection_provider` 代換為新的 `UspService` 實例，並負責登入 (`login()`) 與設定。

### Phase 2: USP 定義檔配置與代碼產生器 (Definitions & CodeGen)
資料庫或欄外資訊都將由一堆 `.yaml` 檔案接管，確保 UI 與韌體擁有唯一的真理標準 (Source of Truth)。
1. 在專案中或共用空間中設立 `doc/usp/definitions/` 與 `doc/usp/transforms/`。
2. 開發者如需任何 Router 的參數，僅能透過修改或增加 YAML 定義檔達成。
3. 撰寫命令列 Shell 腳本 `codegen.sh`：
   ```bash
   #!/bin/bash
   # Generator: Run C CLI codegen tool
   usp-codegen --definitions-dir ./doc/usp/definitions \
               --output-dir ./lib/generated \
               --language dart
   ```
4. 確認產出的 `*.g.dart` 被正確匯入並提交至版控。

### Phase 3: Provider 與 UI 邏輯之重構 (State & UI Refactoring)
從傳統 JNAP 架構中解放，改使用具備 Typescript/Dart 語言特性的強型別。
1. **讀取 (Fetch):** UI / Provider 將不會再收發任何 Dictionary (Map)。
   例如 `SystemInfo.fetch(client)` 將為開發者返回帶有各種預先計算好的 `String` 與 `double`。
2. **存入 (Save):** 改變屬性如 `wifi.ssid = "Home"`，並立刻執行 `await wifi.save(client)`。
3. **訂閱 (Subscribe/SSE):** 切換狀態更新為 Streaming 接收機制。在 Provider 中調用 `ConnectedDevices.subscribe(client)` 來接收並只在串流收到資料才重繪畫面 (`notifyListeners()`)。

### Phase 4: 進階功能開拓與驗證 (Advanced Testing & AI Capability)
1. **Web 平臺編譯確認**: 確保瀏覽器的 WASM 沒有因為載入動態套件發生找不到模組的錯誤。
2. **AI 動態介入**: `usp-client` 已原生支援從 AI 助手傳遞而來的完整結構 Json (包含 Get/Set/Operate ... 等等)。我們可以調用 `client.execute_json()` 達成不依賴 `usp-codegen` 更新也能新增強大控制的功能，此有待整合進 LLM 服務層中。

---

## 3. 開發者守則 (Rules of Engagement)

1. **嚴禁手寫 TR-181 路徑**：任何 `Device.WiFi...` 都禁止出現在 `.dart` 程式碼中。它應該只在 `.yaml` 定義檔中出現。
2. **嚴禁編輯 Generator 檔案**： `lib/generated/*.g.dart` 每次都會被重製。若有需要額外擴充，請在 `transforms/*_ext.yaml` 新增運算與公式，或以 `extension` 方式掛載。
