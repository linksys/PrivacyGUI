# USP 整合計劃適用性評估報告

**版本:** v1.0.0
**評估日期:** 2026-02-24
**摘要:** 評估 `doc/usp/integration/` 中三份整合計劃文件是否適用於目前專案狀況。分析範圍涵蓋全部 14 份 USP 規格文件、專案中所有 USP 相關程式碼、舊 PoC 依賴關係、新 WASM client 狀態、以及 codegen 工具可用性。

---

## 1. 整合計劃概述

### 1.1 三份整合文件

| 文件 | 角色 |
|------|------|
| `usp_integration.md` | 主計劃：4 階段遷移流程 |
| `yaml_generation_strategy.md` | Phase 2 細節：YAML 定義檔產生策略 |
| `tr181_mapping_status.md` | 盤點紀錄：JNAP→TR-181 映射狀態 |

### 1.2 四大遷移階段

| Phase | 目標 | 核心任務 |
|-------|------|----------|
| 1 | 專案清除與客戶端準備 | 移除舊 gRPC packages → 採用 WASM client |
| 2 | 定義檔配置與代碼產生 | 建立 YAML definitions → 執行 usp-codegen |
| 3 | Provider/UI 重構 | 改用強型別 `fetch()`/`save()`/`subscribe()` |
| 4 | 進階功能與驗證 | WASM 編譯確認、AI 動態介入整合 |

---

## 2. 專案現況全盤分析

### 2.1 已就緒的元件

| 元件 | 位置 | 詳細狀態 |
|------|------|----------|
| WASM Client 二進位 | `web/usp_client_bg.wasm` | 431KB WebAssembly MVP module |
| JS Wrapper | `web/usp_client.js` | 878 行，匯出 `UspClient` 類別含 `get/set/login/logout/refreshToken/getMultiple/setMultiple` |
| Dart JS Interop | `lib/usp/web/usp_client_wasm.dart` | 79 行，`UspClientJS` + `UspClientWeb` wrapper |
| UspService 抽象層 | `lib/usp/services/usp_service.dart` | 119 行，含類型強制轉換 (bool coercion)、多路徑操作 |
| CodeGen 工具 | `tools/usp-codegen` | Mach-O ARM64 binary (110KB)，支援 `--definitions-dir`/`--output-dir`/`--language dart|typescript|swift`/`--validate-paths` |
| TR-181 官方 XML | `doc/usp/tr-181-2-20-0-usp-full.xml` | 146,770 行 (5.3MB) BBF 參考模型 |
| 完整規格文件 | `doc/usp/Specifications/` (12 份) | 涵蓋 client、bridge、codegen、auth、definitions、UI、LLM proxy 等 |

### 2.2 尚未就緒的元件

| 元件 | 預期位置 | 狀態 | 影響 |
|------|----------|------|------|
| YAML Definition 檔 | `doc/usp/definitions/` 或 `definitions/` | 目錄完全不存在 | Phase 2 無法啟動 |
| Transform 檔 | `doc/usp/transforms/` | 目錄完全不存在 | 衍生計算功能無法使用 |
| Generated Dart Code | `lib/generated/` | 目錄不存在 | Phase 3 無素材 |
| codegen.sh 腳本 | `scripts/codegen.sh` | 不存在 | 需手動執行 codegen |

### 2.3 舊 PoC 架構詳細盤點

#### 2.3.1 舊 PoC 核心檔案 (lib/core/usp/)

| 檔案 | 行數 | 用途 |
|------|------|------|
| `_usp.dart` | 15 | Barrel export，re-export 所有 USP 元件 |
| `usp_mapper_repository.dart` | 206 | `RouterRepository` 實作，JNAP→USP 轉接層，支援 16 個 actions |
| `jnap_tr181_mapper.dart` | 1,187 | 手刻 TR-181 響應映射 (12 個 mapper 函式) |
| `usp_connection_provider.dart` | 82 | Riverpod providers：`uspGrpcServiceProvider`/`uspConnectionStateProvider` |
| `capabilities/capability_registry.dart` | 57 | Feature capability discovery providers |
| `capabilities/models/device_feature.dart` | 11 | 8 個 feature enum (wifi5Hz, guestNetwork 等) |
| `capabilities/repositories/capability_repository.dart` | 13 | 抽象介面 |
| `capabilities/repositories/local_capability_repository.dart` | 42 | 離線 Demo 模式 |
| `capabilities/repositories/usp_capability_repository.dart` | 57 | USP 裝置能力發現 |
| `capabilities/repositories/usp_wifi_repository.dart` | 94 | WiFi data bundling + polling |
| `providers/polling_manager_provider.dart` | 13 | PollingManager lifecycle |

**共 11 個檔案，約 1,777 行程式碼**

#### 2.3.2 舊 PoC Packages

**packages/usp_client_core** — gRPC Client SDK：
- 依賴：`grpc ^5.0.0`、`usp_protocol_common`
- 包含：`UspGrpcClientService`、6 個 Service 類 (Device/WiFi/Network/Topology/Diagnostics/Capability)
- 包含：`PollingManager`、`ResourceWatcher`、TR-181 paths 常數

**packages/usp_protocol_common** — Protocol Definitions：
- 依賴：`protobuf ^5.1.0`、`grpc ^5.0.0`
- 包含：3 個 `.proto` 檔 (usp_msg/usp_record/usp_transport)
- 包含：protobuf generated code、DTOs、UspPath/UspValue value objects

#### 2.3.3 舊 PoC 引用分析

**直接 import `usp_client_core` 的檔案 (6 個)：**
1. `lib/core/usp/usp_mapper_repository.dart` :14
2. `lib/core/usp/usp_connection_provider.dart` :7
3. `lib/core/usp/capabilities/repositories/usp_capability_repository.dart` :2
4. `lib/core/usp/capabilities/repositories/usp_wifi_repository.dart` :3
5. `lib/core/usp/providers/polling_manager_provider.dart` :2
6. `lib/main_usp_demo.dart` :26

**主要入口點：** `lib/main_usp_demo.dart` (201 行)
- 初始化 gRPC service → 連線 localhost:8090
- Override `routerRepositoryProvider` 為 `UspMapperRepository`
- 有 fallback 到 `LocalCapabilityRepository`

**新 WASM client 引用狀況：零引用**
`lib/usp/` 目前完全未被專案其他程式碼引用，屬於孤立的 WIP 模組。

#### 2.3.4 舊 PoC 資料流

```
Flutter UI Widget
    ↓
Riverpod Provider (lib/providers/)
    ↓
JNAPAction 請求
    ↓
UspMapperRepository._dispatchToService() (16 action mappings)
    ↓
UspXxxService (from usp_client_core)
    ↓
UspGrpcClientService → gRPC-Web → USP Simulator
    ↓
USP TR-181 Response
    ↓
JnapTr181Mapper.toJnapResponse() (1,187 行手刻映射)
    ↓
JNAP JSON 格式 → 回傳 UI
```

---

## 3. JNAP Actions 遷移規模

### 3.1 全專案 JNAP 使用統計

| 指標 | 數量 |
|------|------|
| 唯一 JNAP Actions | **182 個** |
| 使用 JNAP 的檔案 | **51 個** |
| 舊 PoC 已支援 Actions | **16 個** (UspMapperRepository 中) |
| **尚未映射的 Actions** | **166 個 (91.2%)** |

### 3.2 遷移差距分析

整合計劃的 Phase 2 (YAML 定義) 與 Phase 3 (Provider 重構) 需要覆蓋全部 182 個 JNAP actions。而目前：
- TR-181 mapping status 僅盤點了 **8 個欄位**
- 舊 PoC 僅處理 **16 個 actions** 中的部分欄位
- 完整遷移需處理分布在 **51 個檔案** 中的 JNAP 呼叫

---

## 4. 規格文件交叉一致性檢查 (14 份文件)

### 4.1 整合計劃 vs 核心規格 — 一致的部分

| 面向 | 整合計劃 | 規格文件 | 來源 |
|------|---------|---------|------|
| 定義檔格式 | YAML | YAML | usp-definitions-spec |
| Transform 機制 | `_ext.yaml` | 同名配對 `<name>_ext.yaml` | CODEGEN_GUIDE |
| 生成檔命名 | `*.g.dart` | `<feature>.g.dart` | usp-codegen-spec |
| 呼叫模式 | `WifiSsid.fetch(client)` | 同 | CODEGEN_GUIDE |
| Client 技術棧 | Rust + WASM | 同 | usp-client-spec |
| Subscribe 機制 | SSE stream | 同 | ui-side-spec |
| Transforms 可選 | 未明確說明但隱含 | 明確表示 transforms are optional | usp-definitions-spec |

### 4.2 發現的不一致

#### 不一致 #1：定義檔位置

| 文件 | 路徑 |
|------|------|
| 整合計劃 | `doc/usp/definitions/` + `doc/usp/transforms/` |
| yaml_generation_strategy | `doc/usp/definitions/` + `doc/usp/transforms/` |
| CODEGEN_GUIDE | `definitions/` (project root 相對路徑) |
| ui-side-spec | `lib/api/definitions/` |
| usp-codegen-spec | `definitions/` + `transforms/` (獨立 repo) |

**分析**：`usp-definitions-spec` 和 `usp-codegen-spec` 將 definitions 視為獨立 repo (`usp-definitions/`)；`ui-side-spec` 將其放在 `lib/api/` 下；整合計劃放在 `doc/usp/`。三者不一致但都只是路徑慣例，不影響 codegen 工具運作（codegen 透過 `--definitions-dir` flag 指定）。

#### 不一致 #2：定義檔格式 (JSON vs YAML)

| 文件 | 格式 |
|------|------|
| ui-side-spec (較早版本) | JSON (`hardware_info.json`) |
| usp-definitions-spec (較新版本) | YAML (`wifi-ssid.yaml`) |
| CODEGEN_GUIDE (較新版本) | YAML |
| 整合計劃 | YAML |

**分析**：`ui-side-spec` 使用 JSON 是較早版本的設計。`usp-definitions-spec` 明確記載 "Converted to YAML; merged transforms; renamed to usp-definitions"。**YAML 為最終決定**。

#### 不一致 #3：API endpoint 版本

| 文件 | 路徑格式 |
|------|---------|
| router-side-spec | `/api/v1/auth/login` |
| usp-bridge-spec | `/api/auth/login` |
| usp-auth-cgi-spec | `/api/auth/login` |

**分析**：無版本前綴 (`/api/auth/*`) 為正確路徑。router-side-spec 為較舊版本。

#### 不一致 #4：Build 機制

| 文件 | 方式 |
|------|------|
| 整合計劃 | Shell script (`codegen.sh`) |
| ui-side-spec | `flutter pub run build_runner build` |
| CODEGEN_GUIDE | 直接 CLI (`./bin/usp-codegen ...`) |
| usp-codegen-spec | 直接 CLI / Makefile |

**分析**：`usp-codegen` 是獨立 C CLI 工具（已有二進位檔），不是 Dart build_runner 插件。Shell script 或直接 CLI 呼叫為正確方式。ui-side-spec 的 build_runner 描述已過時。

### 4.3 codegen 工具實際 CLI 介面 (已驗證)

```
Usage: usp-codegen [OPTIONS]

Required:
  --definitions-dir DIR    YAML 定義檔目錄
  --output-dir DIR         生成程式碼輸出目錄
  --language LANG          dart | typescript | swift

Optional:
  --validate-paths         啟用 TR-181 路徑驗證
  --json                   JSON 格式錯誤輸出 (CI 用)
  --dart-import PATH       自訂 Dart client import 路徑
  --client-class CLASS     自訂 client 類別名稱
  --help
```

---

## 5. 新 WASM Client API 分析

### 5.1 目前已實作的 API

`UspService` (`lib/usp/services/usp_service.dart`) 目前支援：

| 方法 | 簽名 | 對應 codegen 需求 |
|------|------|------------------|
| `login` | `Future<void> login(String password)` | 驗證 |
| `logout` | `Future<void> logout()` | 驗證 |
| `refreshToken` | `Future<void> refreshToken()` | 驗證 |
| `get` | `Future<Map<String, dynamic>> get(List<String> paths)` | `fetch()` 底層 |
| `set` | `Future<void> set(Map<String, dynamic>, {bool allowPartial})` | `save()` 底層 |
| `isAuthenticated` | `bool get isAuthenticated` | 狀態查詢 |

### 5.2 與 codegen 生成程式碼的銜接

codegen 生成的 `SystemInfo.fetch(client)` 會呼叫 `client.get([...paths])`。目前 `UspService.get()` 回傳 `Map<String, dynamic>`，與 codegen 預期的介面可能存在落差。需確認 `usp-codegen --dart-import` 的實際需求。

### 5.3 尚未實作的功能

| 功能 | 規格要求 | 目前狀態 |
|------|---------|---------|
| Subscribe (SSE) | `subscribe()` 返回 typed stream | 未實作 |
| Add instance | `client.add(path, params)` | 未實作 |
| Delete instance | `client.delete(paths)` | 未實作 |
| Operate command | `client.operate(command, inputs)` | 未實作 |
| execute_json | `client.execute_json(json)` | 未實作 |
| Turbo channel | WebSocket direct to OBUSPA | 未實作 |

---

## 6. TR-181 映射差距分析

### 6.1 映射盤點 vs 實際需求

| 指標 | 數量 |
|------|------|
| 已盤點的欄位 | 8 |
| 舊 PoC mapper 涵蓋的欄位 (jnap_tr181_mapper.dart) | ~120 (12 個 mapper 函式) |
| 全專案 JNAP actions 數量 | 182 |
| yaml_generation_strategy 規劃的 Milestone | 4 個 (MIL-1 ~ MIL-4) |

### 6.2 已知的 Unmappable 欄位

詳見 `unmappable_fields_tracker.md` 追蹤表。

---

## 7. 總評：整合計劃適用性

### 7.1 架構方向：正確

整合計劃的核心架構決策（WASM client → YAML definitions → codegen → typed API）與 14 份規格文件的最終共識一致。舊的不一致（JSON vs YAML、build_runner vs CLI）已被較新的規格文件解決。

### 7.2 就緒度

| Phase | 就緒度 | 阻擋因素 |
|-------|--------|----------|
| Phase 1 | 70% | 需確認移除舊 packages 的影響範圍 (6 個檔案 import) |
| Phase 2 | 10% | 無任何 YAML 定義檔；TR-181 映射僅 8/182 actions |
| Phase 3 | 0% | 依賴 Phase 2 產出 |
| Phase 4 | 20% | WASM 已編譯但 Subscribe/Turbo/execute_json 未實作 |

### 7.3 整合計劃需要修正的項目

| # | 問題 | 修正建議 |
|---|------|---------|
| 1 | 計劃未量化 JNAP 遷移規模 | 補充：全專案 182 actions / 51 files 的遷移工作量 |
| 2 | 計劃假設 YAML 定義檔已存在 | 補充：yaml_generation_strategy 是 Phase 2 的前置工作，非平行工作 |
| 3 | 計劃未提及 `UspService` 缺少 Subscribe/Add/Delete/Operate API | 補充：Phase 1 需擴充 `lib/usp/` 的 API 或確認 codegen 生成的程式碼如何銜接 |
| 4 | codegen `--dart-import` 的客製路徑未確定 | 需驗證 codegen 生成的 import 語句是否與 `lib/usp/services/usp_service.dart` 相容 |
| 5 | 定義檔位置規格不一致 | 統一決定：建議採用獨立 `definitions/` 目錄於 project root (codegen 透過 flag 指定) |
| 6 | 新 WASM client 尚未被任何程式碼引用 | Phase 1 需增加：建立至少一個 provider 驗證 `UspService` 可正常運作 |

### 7.4 建議執行順序

```
Phase 0 (補足前置條件 — 計劃未涵蓋)
├── 驗證 usp-codegen 工具：建立 1 個最小 YAML → 生成 → 編譯
├── 確認 codegen 生成程式碼與 UspService API 的銜接方式
├── 擴充 UspService：至少支援 Add/Delete/Operate (參照 usp-client-spec)
└── 完成 MIL-1 (System & Device Info) 的完整 TR-181 映射盤點

Phase 1 (清除 + 驗證)
├── 建立 lib/usp/ 的 Riverpod provider (替代 usp_connection_provider)
├── 移除 packages/usp_client_core、usp_protocol_common
├── 更新 pubspec.yaml
└── 驗證 main_usp_demo.dart 可改用新架構啟動

Phase 2 (定義檔 + Codegen)
├── 建立 definitions/ 目錄結構
├── 依 yaml_generation_strategy 的 MIL-1~4 順序撰寫 YAML
├── 建立 codegen.sh 自動化腳本
└── 驗證 lib/generated/ 可正常編譯

Phase 3-4 (如整合計劃所述)
```

---

## 8. 驗證方式

| 階段 | 驗證指令 |
|------|---------|
| codegen 工具 | `./tools/usp-codegen --definitions-dir definitions --output-dir lib/generated --language dart` |
| 依賴清理 | `flutter pub get` 無錯誤 |
| 編譯驗證 | `flutter build web` 成功 |
| 單元測試 | `./run_tests.sh` 無新增失敗 |
| Generated code | 確認 `lib/generated/*.g.dart` 可被 import 且類型正確 |
