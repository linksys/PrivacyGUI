# USP 全鏈路參考：資料格式、錯誤窮舉、Error Handling 機制

> 源碼：`PrivacyGUI`(Dart) + `usp_framework/usp-client`(Rust/WASM)。firmware 內的 `usp-bridge` / `OBUSPA` 讀不到，為黑箱。
> 本文三件事（背景知識，回答「為什麼」）：**(1) request 每層長什麼樣 (2) WASM 能丟出的所有 error 窮舉 (3) 現有 error handling pattern 的成因**。
> 「怎麼照著實作」見 [實作指南](error-handling-implementation-guide.md)。

> **在 codebase 的哪裡**
> - **診斷欄位**：`ServiceError` 基類帶 `code` / `detail`；5 子類用統一的 `detail`（不再各自 `message`）；`mapUspErrorToServiceError` 各 `_mapXxx` 會帶 `code`+`detail`；`UspCompleteFailureError`/`UspPartialFailureError` 存 `List<UspErrorDetail> failures`（`failedPaths` 是衍生 getter）。fault code / 原始訊息因此不會流失到 ServiceError，UI/log 兩用。
> - **localization**：View 依 ServiceError 型別產出在地化訊息（中央 mapper `localizeServiceError`），實作在 PR #953。怎麼照著寫見 [實作指南](error-handling-implementation-guide.md)。
> - **§2.5 GET bug（已知，尚未修）**：9999 GET 失敗被偽裝成 9998。

---

## 層級速查（主線：USP 讀寫 = HTTP POST，不是 WebSocket）

**先擺正全貌**：本專案跟 router 溝通底層只有 **HTTP / SSE / WebSocket** 三種 transport（SSE 本質是 HTTP 長連線；Bluetooth 雖列在 `pubspec.yaml` 但 `lib/` 未實際使用）。
但對「USP request 怎麼出去、錯誤怎麼回來」這個主題，**只有一條主線，外加兩個旁支**——它們不是對等的「三選一」，維度不同：

**主線（request / response）——本文 §1–§3 幾乎都在講這條：**
所有 feature 的 get/set/add/delete/operate，走 `UspClient`(WASM) → HTTP POST `/api/v1/usp`。
```
1 Notifier/Provider   Dart   mutation lock、ref.listen invalidation
2 Service             Dart   業務邏輯 + 錯誤映射 (mapUspErrorToServiceError) ◄ 錯誤契約邊界
3 Codegen (.g.dart)   Dart   TR-181 型別 ↔ Dart、組完整路徑
4 UspClient facade    Dart   throttler(GET去重)、401 retry、值 stringify、GET coerce
5 UspClientWeb        Dart   Dart↔WASM (jsify/dartify)
6 JS glue             JS     window.UspClient、WASM 載入
─────────────────────── WASM 邊界 ───────────────────────
7 wasm/mod.rs         Rust   匯出 fn、JS value→struct、錯誤兩種策略
8 client.rs           Rust   msg_id、command_key、ResponsePool 關聯
9 protocol            Rust   protobuf encode/decode、Record/Msg
10 transport/http.rs  Rust   POST /api/v1/usp (fetch)、Bearer token
─────────────────────── 可讀最右端 ───────────────────────
11 usp-bridge (黑箱) → 12 OBUSPA (黑箱) → 13 TR-181 data model
```

**旁支 1 — SSE 通知（push，不是 request/response）**：firmware **主動推**的 invalidation / 事件，
`UspBridgeClient.notifications()` 用 Fetch + ReadableStream 讀 `/api/v1/notifications`，**純 Dart、不經 WASM**。
它不是「另一條送 request 的路」，而是另一種互動模式（伺服器→前端）。跟「錯誤映射」是不同故事，知道存在即可。

**旁支 2 — WebSocket（特例，獨立 class）**：**只**用於 firmware 上傳，
`UspWsClientWrapper` 連 `wss://.../usp-ws`（WASM 持有 socket），全 codebase 僅 `firmware_ws_upload_strategy.dart` 一處使用，有自己的 exception 處理。本文其餘部分不涉及它。

> 一句話：**跟著主線走就對了**；SSE 是「收推播」、WebSocket 是「傳韌體」，都不在 §1–§3 的錯誤映射主題上。

---

# 1. Request 資料格式：每一層長什麼樣

以 **DMZ** 為例（SET：啟用 DMZ 指向 `192.168.1.150`）。

### 下行（request 出去）

| 層 | 資料形狀 | 檔案 |
|---|---|---|
| **2 Service 輸入** | typed 物件，null 欄位=「這次不設」<br>`DmzEntryUpdate(instancePath:'Device.Firewall.DMZ.1.', enable:true, destIp:'192.168.1.150', sourcePrefix:'0.0.0.0/0')` | `usp_dmz_service.update` |
| **3 Codegen 組路徑** | `Map<String,dynamic>`，key=完整 TR-181 路徑，值仍是**原生型別**<br>`{'Device.Firewall.DMZ.1.Enable': true, '...DestIP': '192.168.1.150', '...SourcePrefix': '0.0.0.0/0'}` | `dmz.g.dart Dmz.update` |
| **4 UspClient stringify** | `Map<String,String>`，值全轉字串<br>`{'...Enable': 'true', '...DestIP': '192.168.1.150', ...}` | `usp_client.dart _batchSet` |
| **5 → JS** | `parameters.jsify()` → JS object；options `allowPartial:false` → **`undefined`** | `usp_client_wasm.dart UspClientWeb.set` |
| **7 Rust 解析** | `Vec<(String,String)>`（⚠ 必須先 stringify，否則 `as_string()` 回 None → 變 `"JsValue(true)"`） | `wasm/mod.rs UspClient::set` |
| **9 protobuf** | 依**父路徑分組**（在最後一個 `.` 切開）成 `UpdateObject`：<br>`Msg{Header{msg_id:uuid, msg_type:SET}, Body{Set{allow_partial:false, update_objs:[{obj_path:'Device.Firewall.DMZ.1.', param_settings:{Enable:'true', DestIP:'192.168.1.150', SourcePrefix:'0.0.0.0/0'}}]}}}` | `encode.rs encode_set_request` / `extract_object_and_param` |
| **10 線上** | `POST /api/v1/usp`｜`Content-Type: application/octet-stream`｜`Authorization: Bearer <jwt>`｜body=binary protobuf（**裸 Msg，無 Record**，Record 由 bridge 補） | `http.rs post`（wasm）/ `post_protobuf` |

### 上行（response 回來）— unified envelope

回程一律是 WASM v0.11.0 統一格式：`{ success, result: { data, error? } }`。**`error` 無錯時整個省略；partial 失敗時 `success:true` 但帶 `error`**——所以 `success===true` 也要檢查 `error`。

```js
// SET 成功
{ success: true, result: { data: { "Device.Firewall.DMZ.1.Enable": "true", ... } } }

// SET partial（SourcePrefix 值非法）
{ success: true, result: {
    data:  { "Device.Firewall.DMZ.1.Enable": "true", "...DestIP": "192.168.1.150" },
    error: { "Device.Firewall.DMZ.1.SourcePrefix": { errorCode: 7006, errorMessage: "..." } } } }

// transport 失敗（401/timeout）
{ success: false, result: { error: { "<path>": { errorCode: 9999, errorMessage: "Transport error: ..." } } } }
```

| 層 | 動作 | 檔案 |
|---|---|---|
| **10 dartify** | JS object → `Map<String,dynamic>`（遞迴 coerce） | `usp_client_wasm.dart UspClientWeb.set` |
| **11 UspClient** | 原樣回傳（只 log），codegen 也原樣回給 service | `usp_client.dart` |
| **12 Service 解析** | `UspResultParser.parseSetResult(map)` → `UspSuccess` / `UspPartialSuccess` / `UspFailure` | `usp_operation_result.dart _parseGenericResult` |

### get/set 是「同步 HTTP 一來一回」，只有 operate 用 SSE

- **get / set / add / delete**：`client.rs` 的 `send_usp(...).await` 直接拿到 **同一個 HTTP 回應的完整 protobuf body**（`post` 回 `response.bytes()`），當場 `decode_*_response` 解出資料。**全程不碰 SSE，HTTP 一來一回就結束。**
- **`response_pool`（msg_id 關聯）的用途**：當**並發 HTTP 請求的 response 亂序回來**時，用 msg_id 配對「哪個 body 屬於哪個 request」。是同步 req/resp 的內部機制，與 SSE 無關。
- **operate 分同步/非同步兩種**：
  - **同步 operate（多數，如 reboot、factory reset）**：結果直接在 HTTP 回應的 `OperSuccess.output_args`，**同 get/set 一樣一來一回，不碰 SSE**，直接呼叫 `UspClient.operate`。
  - **非同步 operate（少數，僅 diagnostics：ping/traceroute/nslookup/download）**：HTTP 只回 **ACK**（protobuf `operate_resp = None`，含 client 自產的 commandKey）；真正結果由 Dart `SseOperationAwaiter`（`network_diagnostics_executor`）等 SSE 的 `OperationComplete` 事件取得（Direct Data Delivery）。
  - **SSE 等待僅此一類**，get/set/add/delete 與其他 operate 都不適用。

> ⚠ **GET 與 SET 的錯誤處理不對稱**：SET 保留 envelope 走 `UspResultParser`；GET 則在 `UspClientWeb.get` 把 envelope 丟掉、只留攤平的 `data`，失敗只在 WASM 自己 throw 字串時才浮現。這個不對稱導致一個重大缺陷（9999 GET 失敗被偽裝成 9998）——**完整因果見 §2.5**。

---

# 2. 錯誤來源與形式（窮舉 → ServiceError 映射 spec）

### 2.0.0 核心總綱：錯誤「來源」與「形式」是兩條獨立的軸 ⚠⚠

理解整個錯誤模型，最重要的是**別把「誰產生 error」和「error 長什麼形式」綁在一起**。它們是兩條獨立的軸：

**軸一 — 來源（誰產生）有 3 個：**
1. **Rust WASM client**（層 7–10）
2. **firmware**（bbfdm / OBUSPA，Rust 只透傳）
3. **Dart codegen**（`lib/generated/*.g.dart`）

**軸二 — 形式（長什麼樣）有 2 種：**
- **A. 拋字串**（Promise reject / Dart throw）：`"{Op} failed: {category}: {detail}"`
- **B. structured envelope**：`{success, result:{data, error?{path:{errorCode, errorMessage}}}}`

**關鍵：兩種形式裡都混著不同來源——不能說「WASM=字串、firmware=envelope」。** 真正的對應是：

| 來源 | 形式 | code / 識別 | 含義 |
|---|---|---|---|
| **WASM**（生命週期方法 login/logout/subscribe…） | **拋字串** | `"Login failed: ..."` 等 prefix | client 端失敗 |
| **WASM**（資料操作 get/set… 失敗時） | **envelope** | **9999** | request **沒到 firmware**（網路/auth/編碼） |
| **firmware**（透傳） | **envelope**（GET 經 codegen 時也可能在拋字串的 `(code:)` 裡） | **7xxx / 9xxx** | **到了 firmware，但被它拒絕** |
| **firmware**（透傳） | **envelope** | `success:true` | **firmware 成功處理** |
| **Dart codegen** | **拋字串** | **9998** | GET 回應缺必填欄位 |

> **「生命週期方法」**指管理「會話/連線本身」而非讀寫 router 資料的方法：login/logout/refreshToken/subscribe/unsubscribe。
> 它們不由 UI 直接呼叫——login/logout 由 `UspAuthCoordinator` 跟著**本地登入流程**（使用者輸入 router 密碼）連動觸發：本地登入成功後用同一組密碼幫 USP 登入，重開 app 時用存下的密碼 `restoreSession`。subscribe/unsubscribe 則由 SSE 系統（`SseManager`）內部自動管理。

---

### 2.0 分界規則：丟字串 vs structured envelope —— **按「哪個方法」分，不是按「錯誤類型」分** ⚠

這是整個錯誤模型最容易誤解的地方。要分**兩個交接點**看：**(1) WASM 回傳給 Dart 的格式** 與 **(2) Service 從 Dart 第 5 層（`UspClientWeb`）拿到的格式**。兩者不同，GET 尤其明顯。

**(1) WASM 回傳給 Dart 的格式**——每個方法在 `wasm/mod.rs` hard-code 了失敗形式，分界**按「哪個方法」**，不是按錯誤類型：

| 方法群組 | WASM 回傳的失敗形式 | 即使是網路/auth/timeout 錯誤？ | 源碼 |
|---|---|---|---|
| **生命週期方法**：`login` / `logout` / `refreshToken` / `subscribe` / `unsubscribe` / `listSubscriptions` / constructor | **A. 丟字串**（Promise reject） | 是，一律丟字串 | 各方法的 `Err(e) => Err(JsValue::from_str(...))` |
| **資料操作**：`get` / `set` / `setOrdered` / `add` / `delete` / `operate` | **B. structured envelope**（`{success:false 或 partial, result:{error}}`，code 9999） | **是！網路/auth 錯也包成 envelope（9999），不丟字串** | `set` 的 `Err(e) => build_transport_error_unified(...)` |

證據（`wasm/mod.rs` 中 `UspClient::set` 的兩個分支，get 同理）：
```rust
match client.set_with_options(params_vec, ...).await {
    Ok(response) => serialize_set_response_to_js(&response),       // → envelope，code 由 firmware 決定 (7xxx/9xxx/成功)
    Err(e)       => build_transport_error_unified(&path_list, ...),// → envelope，code 寫死 9999（連 timeout/401 都走這）
}
```

**(2) Service 從 Dart 第 5 層拿到的格式**——Dart 第 5 層（`UspClientWeb`）會再加工，使 service 拿到的形式**與 WASM 回傳的不同**，這是 GET 不精確的根源：

| 操作 | service 從第 5 層拿到的失敗形式 |
|---|---|
| `set` / `setOrdered` / `add` / `operate` | **維持 envelope**（`UspResultParser` 解析） |
| `delete` | WASM 例外被第 5 層合成 envelope（仍 envelope） |
| **`get`** | ⚠ **變字串**：第 5 層只取 `result.data`、丟掉 envelope 的 `success`/`error`；失敗時 service 拿到的是 **codegen 拋的 9998 字串**或 WASM rethrow 的字串，**不是 envelope**（見 §2.5） |

> 一句話：**WASM 回給 Dart 的 GET 失敗是 envelope，但這個 envelope 被第 5 層拆掉，所以 service 拿到的 GET 失敗是字串。** 上面 §2.0.0 表格與 §2.5 描述的都是 service 拿到的格式（GET=字串）。

> structured envelope 的判讀見 §2.3：**`success:false` ≠ firmware 成功處理**。看 errorCode 才知道 request 有沒有到 firmware。

### 2.1 丟字串的統一格式（三層巢狀）

是的，丟字串格式**完全統一**，由 Rust 的 `Display` impl 層層 `write!` 組出，結構固定為三層：

```
"{操作 prefix}{category}: {detail}"
   └─ §2.1 表    └─ §2.2 五選一   └─ 實際錯誤訊息（可能再含 (code: XXXX)）
```

組裝來源（Rust `error.rs` 的 `Display` impl）：外層 `UspError::Display` 寫 `"{category} error: {子錯誤}"`，再被各 WASM 方法在前面接上操作 prefix。範例拆解：

```
"Set failed: Protocol error: Decoding error: Received error response: ... (code: 7026)"
 ─────┬────  ──────┬───────  ───────────────────────┬──────────────────────────────
 操作 prefix     category(protocol)           detail（含透傳的 firmware code 7026）

"Login failed: Authentication error: Invalid credentials"
 ──────┬─────  ─────────┬───────────  ────────┬─────────
 操作 prefix       category(auth)          detail

"Get failed: Validation error: Required fields missing from response: DestIP (code: 9998)"
 ─────┬────  ───────┬─────────  ──────────────────┬─────────────────────────────────────
 操作 prefix   category(validation)    detail（Dart codegen 丟的缺欄位錯，code 9998）
```

Dart 端 `parseUspError`（`usp_error.dart`）就是靠這個固定結構拆解：
- `_opPrefix = ^(\w+) failed: (.+)$` 切出操作與其餘
- `_parseCategoryAndMessage` 比對 5 個 category 前綴（§2.2）
- `_faultCode = \(code:\s*(\d+)\)` 從 detail 末尾抓 fault code
- `_httpStatus = HTTP error: HTTP (\d+)` 抓 HTTP 狀態碼

⚠ 例外：少數不符 `"{X} failed:"` 的字串（如 WS 的 `"UspWsClient is closed"`、SSE 的 `StateError`）parse 不出來 → `parseUspError` 回 null → 映射成 `UnexpectedError`。

### 2.1.1 丟字串的 prefix

Dart 錯誤映射**只需處理這 7 個**（主線，日常 USP 請求路徑）：

（均在 `wasm/mod.rs` 各方法的 `Err(e) => Err(JsValue::from_str(...))`）

| 操作 | prefix |
|---|---|
| constructor | `"Failed to create client: "` |
| login | `"Login failed: "` |
| logout | `"Logout failed: "` |
| refreshToken | `"Token refresh failed: "` |
| subscribe | `"Subscribe failed: "` |
| unsubscribe | `"Unsubscribe failed: "` |
| listSubscriptions | `"List subscriptions failed: "` |

**另有 7 個 WebSocket 字串可忽略**（`"encode Msg failed: "`、`"wrap Record failed: "`、`"unwrap Record failed: "`、`"decode Msg failed: "`、`"encode Operate failed: "`、`"build WSConnect failed: "`、`"UspWsClient is closed"`）。原因：
- 它們屬 **旁支 2（WebSocket firmware 上傳）**，不在日常 GET/SET/通知路徑上。
- 整段被 `#[cfg(feature = "websocket")]` 包住（`wasm/mod.rs` 的 `ws_binding` 模組），而 `Cargo.toml` 的 `default = ["native"]` **不含 websocket feature** —— 除非 build 時明確 `--features websocket`，這 7 個 function 連同其錯誤字串**根本不會編進 WASM binary**。
- 結論：`mapUspErrorToServiceError` 無需處理它們。

### 2.2 category（5 種）+ 巢狀子字串（error.rs，這是 prefix 後面接的字串，也出現在 9999 的 errorMessage 內）

| category 前綴 | 子變體 Display 字串（detail） |
|---|---|
| `Transport error: ` | `Network error: {m}`／`HTTP error: {m}`（m 可為 `HTTP 500`/`HTTP 404`/`WASM not yet implemented`）／`Request timeout`／`Connection refused`／`TLS error: {m}`／`Invalid URL: {m}`／`Response correlation timeout for msg_id: {id}` |
| `Protocol error: ` | `Encoding error: {m}`／`Decoding error: {m}`（含 `Received error response: {msg} (code: {code})`）／`Malformed message: {m}`／`Unsupported version: {m}`／`Missing field: {m}` |
| `Authentication error: ` | `Invalid credentials`／`Session expired`／`Invalid token: {m}`（`No token in response`/`No token in refresh response`）／`Permission denied`／`Authentication required` |
| `Operation error: ` | `Get/Set/Add/Delete failed for '{path}': {reason}`／`Operate failed for '{command}': {reason}`／`Path not found: {path}`／`Parameter is read-only: {path}`／`Invalid value '{value}' for '{path}': {reason}` ⚠ 這組只在 Rust **native ffi**（`ffi/mod.rs`，`#[cfg(not(target_arch="wasm32"))]`）建構，**WASM build 不含 → 生產不可達**。對應 `_mapOperationError` 是死碼（見 `usp_error.dart` 該函式註解） |
| `Validation error: ` | client 端：`Delete paths cannot be empty`／`Invalid JSON: ...`／`... not yet implemented` 等 |

另有 3 個直接包進 9999 的輸入驗證字串：`"Invalid path format: all paths must be strings"`、`"Invalid input: paths must be string or array of strings"`、`"Invalid input: items must be object or array of objects with {path, params}"`。

### 2.3 數字 error code

> ⚠ **fault code 分兩類來源**，**只有 client-side 的 9999 能從 Rust 窮舉**；
> firmware fault code（7xxx / 9xxx）是 **router 端 bbfdm 的開放集合**，Rust client 只**透傳、不列舉、不 hard-code**。
> 因此「從 usp-client 源碼窮舉所有 error code」對透傳碼**不成立**——它們不在 Rust 源碼裡。
> 真正的 fault code 清單在 firmware（bbfdm/OBUSPA）端，需向 firmware 團隊索取 vendor fault code 表。

| code | 何時 | 來源 | 給 Dart 的處理 |
|---|---|---|---|
| **9999** | 任何 transport/auth/protocol/validation 失敗（含輸入驗證）。message = `"Transport error: " + UspError Display` | **Rust client 自己生成**（`wasm/mod.rs build_transport_error_unified`，唯一 hard-code 的 code） | 解析 message 內的 category/detail 再 map |
| **7xxx**（TR-369 標準範圍） | firmware 回的 per-path/per-param 失敗。message = firmware 原文 | **firmware 透傳**（原樣拷貝，Rust 不合成） | 語意化：7004/7005/7006→InvalidInput、7026/7027→ResourceNotFound；其餘歸 agent error |
| **9xxx**（bbfdm vendor 範圍） | bbfdm backend 拒絕的 SET/GET（如 `9001` 拒絕、`9005` 未實作參數、`9008` 唯讀） | **firmware(bbfdm) 透傳** | 9001→Unauthorized、9005/9007→ResourceNotFound、9008→InvalidInput |
| **9998** | GET 回應**缺必填欄位**（router 沒回某些 param）。**Rust 不發、由 Dart codegen 丟出**：`'Get failed: Validation error: Required fields missing from response: ... (code: 9998)'`（34 個 `lib/generated/*.g.dart`） | **Dart codegen** | 走 `category=validation` → `InvalidInputError` |
| 9997 | — | Rust / lib / test 三邊皆無此 code | 不存在，無需處理 |
| 0 | success sentinel，不出現在 error block | — | — |

> 證據（9xxx 確實是 router 行為，非死碼）：`usp_test_console_view.dart` 標 "expect fault 9005/9008"；
> `usp_ipv4_section.dart` + `usp_internet_settings_service.dart` 註解 "bbfdm rejects SET (fault 9001)"；
> `test/core/usp/errors/usp_error_test.dart` 已驗證 9001/9005/9008 映射。

#### 9999 vs 7xxx/9xxx —— 本質差別：**request 有沒有到 firmware**

這是判讀 structured envelope 的核心。兩者都長成 `{success:false, error:{path:{errorCode, errorMessage}}}`，但意義相反：

| | **9999** | **7xxx / 9xxx** |
|---|---|---|
| 誰產生 | **Rust client 自己**（`build_transport_error_unified`，唯一寫死的 code） | **firmware**（OBUSPA/bbfdm），Rust 只透傳 |
| 來自哪個分支 | `set/get/...` 的 `Err(e)` 分支 | `Ok(response)` 分支，從解碼成功的回應讀 `err_code`（`wasm/mod.rs` 的 `serialize_*_response_to_js`） |
| request 到 firmware 了嗎 | **沒有**——在 client 端就失敗，根本沒（成功）連到 router | **到了**——firmware 收到、處理了、並主動拒絕 |
| 涵蓋的底層錯誤 | **一個 code 打包了五類**：① transport（timeout / connection refused / HTTP 5xx / TLS）② auth（401 / session expired）③ protocol（protobuf encode/decode 失敗、correlation timeout）④ client validation（path 格式錯）⑤ 輸入形狀錯 | 單一明確語意：參數唯讀 / 值非法 / path 不存在 / bbfdm 拒絕… |
| errorMessage | `"Transport error: " + UspError Display`（細節全藏在字串裡，要再 parse） | firmware 原文 |
| 對 UI 的意義 | 「**沒送出去**，請檢查連線/重新登入/重試」 | 「**送到了但被拒**，請改你的輸入」 |

**一句話**：
- `errorCode == 9999` → 這不是 firmware 的錯，是 **client 端到 router 之間**出問題（網路、認證、編碼）。同一個 9999 涵蓋 timeout、401、TLS、protobuf 錯等**五大類**，真正類型只能再 parse `errorMessage` 裡的 `"Transport error: {category}: ..."` 才知道。
- `errorCode` 是 7xxx 或 9xxx → request **確實抵達 firmware 並被它處理**，firmware 主動回了這個 fault code（7xxx=TR-369 標準、9xxx=bbfdm vendor）。code 本身就是明確語意，直接 map 即可。

> 推論：看到 `success:false` **不能**斷定「firmware 成功處理了」。**只有 `success:true`（全成功或 partial）才保證 firmware 有處理。**
> `success:false` 要先看 code：9999=沒到 firmware；7xxx/9xxx=到了且被拒。

#### 各來源的「資訊完整度」：code 與 message 一定有嗎？

每個來源在組錯誤時塞了什麼，決定了 Dart 能不能信任 code / message 一定存在：

| 來源 | errorCode | errorMessage | 說明 |
|---|---|---|---|
| 生命週期字串（login…） | ⚠ **不保證** | ✅ 一定有 | 字串 = prefix + category + detail；只有底層是 protocol（透傳 firmware）時 detail 才帶 `(code:)`。**auth 類錯誤本來就沒 code** → `parseUspError` 抓不到 → faultCode=null |
| 9999 envelope | ✅ 一定 9999 | ✅ 一定有 | `errorMessage` 至少是 `"Transport error: ..."`，但可能短（如 `Request timeout`） |
| firmware 透傳 envelope（7xxx/9xxx） | ✅ 欄位一定在 | ⚠ **欄位一定在，值可能空字串** | `serialize_*_response_to_js` 無條件塞兩欄；但 `err_msg` 是 protobuf `string`，firmware 沒填時是 `""`（非 null） |
| codegen 9998 字串 | ✅ 一定 9998 | ✅ 一定有 | 訊息含缺漏欄位清單，且只有 `missing.isNotEmpty` 時才拋 |

**Dart 模型層兜底**（`UspErrorDetail.fromMap`）：`errorCode` 缺→`-1`、`errorMessage` 缺/null→`'Unknown error'`。所以到了 Dart 模型層，**兩者永遠非 null**。

> 一句話：envelope 類（9999/firmware/9998）的 **欄位**都保證存在（Dart 層再加 `-1`/`'Unknown error'` 兜底）；唯二不保證的是——**生命週期字串常缺 code**（auth 錯誤無 code），以及 **firmware message 的值可能是空字串**（欄位仍在）。

### 2.4 Dart 映射規則（`usp_error.dart` 的 `mapUspErrorToServiceError`）對照

現有 fault-code map（`usp_error.dart` 的 `_mapProtocolError`）：
`7004/7005/7006→InvalidInput`、`7026/7027→ResourceNotFound`、`9001→Unauthorized`、`9005/9007→ResourceNotFound`、`9008→InvalidInput`。
此時與 `UspErrorDetail`（`usp_operation_result.dart`，認得 7004/7005/7006/7026/7027）的語意已對齊。

> **診斷欄位**：各 `_mapXxx` 在產出 ServiceError 時會帶上 `code`（faultCode / httpStatus）+ `detail`（原始訊息）。即使型別資訊較粗（如 `ResourceNotFoundError`），底層 code/detail 仍在 ServiceError 上供 log 與 View 取用。

行為特性與限制：
1. **envelope 路徑的語意化在 View 消費**：batch SET/ADD/DELETE 失敗走 `UspResultParser` → service 拋 `Usp{Partial,Complete}FailureError`。
   - 這兩個型別存 `List<UspErrorDetail> failures`（完整 path+code+message），fault code 不會流失；`UspErrorDetail` 的 `isObjectNotFound`/`isInvalidParameterValue` 等 helper 可用。
   - 路徑 2 只產出 `UspPartial/CompleteFailureError` 這兩個**容器型別**，不像路徑 1 會依 code 細分成 `ResourceNotFoundError`/`InvalidInputError`。這是**設計使然**——batch 可能多筆、各有不同 code，無法塞進單一語意型別。語意化發生在 **View**：遍歷 `failures`、對每筆用 helper 判 code 決定顯示（做法見 [實作指南](error-handling-implementation-guide.md) §4.2）。
2. **9999 沒有專門映射**：它是 client 端最常見 code，但映射只看 message 內的 category 字串、不看 code 9999 本身（目前可正常運作，因字串夠用）。
3. **WS / SSE 的 `StateError`**（如 `'WebSocket connection timeout'`）不符 `"{Op} failed:"` 格式，落到 `mapUspErrorToServiceError` 只會變泛用 `UnexpectedError`。
4. **字串契約脆弱**（`usp_error.dart` 開頭「Error Contract」自註表）：transport/auth/protocol 的映射靠對 Rust 字串 substring/regex；**Rust 端字串一改就無聲失效**。§2.1/§2.2 是當前 Rust 的完整 client-side 輸出契約，可做成 contract test 固定它（注意：透傳的 7xxx/9xxx 不在此契約內，由 firmware 決定）。

### 2.5 ⚠⚠ 重大缺陷：GET 失敗的 9999 被偽裝成 9998，網路錯誤誤判為輸入錯誤

這是錯誤模型裡**語意錯置最嚴重**的一條，**屬未修的 bug**。

**對稱性斷裂**：SET/ADD/DELETE 保留 envelope → 走 `UspResultParser.parseSetResult` → 語意正確；
但 **GET 在第 5 層（`usp_client_wasm.dart` 的 `UspClientWeb.get`）就把 envelope 拆掉，只取 `result.data`，丟棄 `success`/`error`**。
因此對應的 `UspResultParser.parseGetResult`（`usp_operation_result.dart`）**是死碼，無人呼叫**（僅存定義 + 一個單元測試）。

**後果——9999 GET 失敗的實際流向**：
```
WASM 回 {success:false, error:{path:{errorCode:9999}}}   ← 網路斷/沒到 firmware
   ↓ UspClientWeb.get 只取 data（success/error 丟棄）
data = {}                                                 ← 失敗 envelope 沒 data → 空 map
   ↓ codegen _fromResponse 檢查必填欄位（dmz.g.dart）
必填欄位全缺 → throw 'Get failed: Validation error: ... (code: 9998)'
   ↓ service catch → mapUspErrorToServiceError
→ category=validation → InvalidInputError
```
**一個 9999（連不上 router，應為 `NetworkError`「請重試」）被無聲轉成 9998（缺欄位）→ `InvalidInputError`（「你的輸入有問題」）。** 錯誤語意完全錯置，使用者會收到誤導訊息。

**唯一不中招的情況**：若 WASM 的 GET 是整個 Promise **reject**（拋字串而非回 envelope），`UspClientWeb.get` 的 `catch → rethrow` 會讓字串原樣冒上去被正確 map。但 §2.0 已證實 GET 失敗多走 `build_transport_error_unified` 回 envelope 那條 → 中招。

**對照表**：

| | 設計意圖 | 實際程式 |
|---|---|---|
| GET 失敗 envelope | 交給 `parseGetResult` 判 success/error | envelope 在層 5 被拆，只留 data |
| 9999 GET 失敗 | → `NetworkError`（連不上） | 偽裝成 9998 → `InvalidInputError`（輸入錯） |
| `parseGetResult` | GET 路徑的解析器 | **死碼，無人呼叫** |

**修補方向**（未執行，供日後評估）：
- **方向 A（治標，小）**：`UspClientWeb.get` 在 `success==false` 時不要默默回空 data，改 throw 帶 9999 的字串 → 被正確 map 成 `NetworkError`。影響面小。
- **方向 B（治本，大）**：GET 也保留 envelope、改走 `parseGetResult`，與 SET 對稱。但需動 codegen 所有 `fetch` 的回傳型別，影響面大。

> 呼應 §1「GET 的特殊轉換」末條 ⚠（GET 丟掉 envelope，失敗只在 WASM 自己 throw 字串時才浮現）——本節是該註記的完整後果與根因。

### 2.6 匯流總圖：兩條路徑 → ServiceError → View

所有錯誤最終都在 **service 的 `catch (e)`** 匯合成 `ServiceError`。分流的真正依據是 **fetch（GET）vs 寫入（SET/ADD/DELETE/operate）**——與 §3 的 fetch/save pattern 完全對應。

> ⚠ 不在此圖內的：**生命週期錯誤**（login/logout/refreshToken 失敗）由 `UspAuthCoordinator` 在內部消化，**raw 字串不會變成 `ServiceError`、不流進此圖**。但 app 仍以「認證狀態」形式得知結果，只是不是錯誤物件：
> - `syncAfterLocalLogin`：catch 後只 log、吞掉（本地登入照常成功，USP 失敗不影響，fallback 回 JNAP）
> - `tryUspLogin` / `restoreSession`：catch → `return false`（app 拿到布林，不是字串）
> - `ensureAuth`（refreshToken）：401 → 觸發 `onForceLogout` callback（強制登出）
>
> 設計意圖：USP 是附加在本地登入旁的第二認證 channel，失敗時降級成「能不能用」的狀態，不該讓 app 爆 `ServiceError`。

```
        路徑 1：fetch (GET)                    路徑 2：寫入 (SET/ADD/DELETE/operate)
   收到「字串」                            收到「envelope」{success,result:{data,error?}}
   ┌────────────────────────────┐         ┌────────────────────────────────────┐
   │ GET 失敗的字串，兩個來源：    │         │ envelope 的 error 內含 code：         │
   │ • codegen 缺必填欄位 → 9998  │         │ • 9999  (WASM 沒到 firmware)         │
   │ • WASM get 自己 rethrow 的字串│         │ • 7xxx/9xxx (firmware 透傳，拒絕)    │
   └────────────────────────────┘         └────────────────────────────────────┘
                  │                                          │
                  │                          UspResultParser.parseSetResult/Add/Delete
                  │                                → _parseGenericResult
                  │                                          │
                  │                       ┌──────────────────┼──────────────────┐
                  │                       ▼                  ▼                  ▼
                  │                  success且無error    success且有error    success=false
                  │                       │                  │                  │
                  │                       ▼                  ▼                  ▼
                  │                  UspSuccess       UspPartialSuccess     UspFailure
                  │                   (不拋)                │                  │
                  │                                        ▼                  ▼
                  │                               service switch → throw
                  │                       UspPartialFailureError / UspCompleteFailureError
                  │                              （本身就是 ServiceError）
                  │                                          │
                  ▼                                          ▼
        ╔═══════════════════════════════════════════════════════════════╗
        ║            service 的  catch (e) { ... }   ← 兩條路在此匯合       ║
        ║   if (e is ServiceError) rethrow;    // 路徑2 自拋的直接放行      ║
        ║   else throw mapUspErrorToServiceError(e);  // 路徑1 字串才 map   ║
        ║        └ parseUspError 拆字串 → UspError{category,faultCode}      ║
        ║        → NetworkError / InvalidInputError / ResourceNotFound /   ║
        ║          Unauthorized / UnexpectedError                         ║
        ╚═══════════════════════════════════════════════════════════════╝
                                  │
                                  ▼   throw ServiceError
                          ┌──────────────┐
                          │   provider    │  save : rethrow
                          │               │  fetch: state.error = e（型別透傳，不壓字串）
                          └──────────────┘
                                  │
                                  ▼   ServiceError（型別保留）
                          ┌──────────────┐
                          │     View      │  localizeServiceError(ctx, e) → 在地化訊息
                          └──────────────┘
```

**兩條路徑對照**：

| | 路徑 1：fetch (GET) | 路徑 2：寫入 (SET/ADD/DELETE/operate) |
|---|---|---|
| service 收到的形式 | **字串**（envelope 已被第 5 層 `UspClientWeb.get` 拆掉，只剩 data） | **envelope** `{success,result:{data,error?}}` |
| 失敗時的字串/code 來源 | codegen 缺欄位拋 9998、或 WASM rethrow 的字串 | error 內 `errorCode`：9999（WASM）或 7xxx/9xxx（firmware） |
| 關卡方法 | `mapUspErrorToServiceError` → `parseUspError` | `UspResultParser.parseXxxResult` → `_parseGenericResult` |
| 中間型別 | `UspError`（暫時，純為拆字串） | `UspSuccess` / `UspPartialSuccess` / `UspFailure` + `UspErrorDetail` |
| 產出的 ServiceError | `NetworkError` / `InvalidInputError` / `ResourceNotFoundError` / `Unauthorized` / `UnexpectedError` | `UspPartialFailureError` / `UspCompleteFailureError` |
| 怎麼匯合 | service catch 接到字串 → `mapUspErrorToServiceError` | service 自己 `throw Usp*FailureError`（已是 ServiceError）→ `if (e is ServiceError) rethrow` 放行，**不重複 map** |

**分流判斷點**（`_parseGenericResult`，僅路徑 2）：
- `success && error==null` → `UspSuccess`（不拋，正常返回）
- `success && error!=null` → `UspPartialSuccess` → service 轉 `UspPartialFailureError`
- `success==false` → `UspFailure` → service 轉 `UspCompleteFailureError`

> ⚠ 注意 9999 的歸屬：它是 WASM 產的、代表「沒到 firmware」（§2.3），但**形式上是 envelope 裡的 errorCode**，所以走**路徑 2**（parser），不是路徑 1。「誰產生」與「走哪條路」是兩回事。

> 一句話：**字串走 `mapUspErrorToServiceError`，envelope 走 `UspResultParser`，兩條都在 service `catch` 收斂成 `ServiceError`**；之後 provider 透傳型別（save rethrow / fetch 存 `state.error`）、view 用 `localizeServiceError` 在地化的做法見 §3 與 [實作指南](error-handling-implementation-guide.md)。

---

# 3. Error Handling Pattern 的成因（Service 層機制）

> 本節解釋**為什麼** Service 層的 fetch 與 save 寫法不同（fetch 無守衛、save 有守衛）——這是整個 pipeline 最容易誤解、且不會隨時間改變的核心機制。
> Provider / View 兩層的**現行做法**（型別怎麼透傳、怎麼在地化顯示）見 [實作指南](error-handling-implementation-guide.md)；本節末尾只說明 PR #953 之前的痛點，作為「為何要做那次重構」的背景。

Service 層的錯誤收斂（fetch / save 都把錯誤轉成 `ServiceError`，靠 `mapUspErrorToServiceError` + `UspResultParser`），保留 typed `ServiceError`，且帶 `code`/`detail`（路徑1）或 `failures` list（路徑2）診斷資訊。

### Service 層細節：fetch 與 save 是兩種不同 pattern —— 差別在「有沒有自拋 ServiceError」

兩者唯一的結構差異是 **`if (e is ServiceError) rethrow` 這道守衛**。理解它要從「catch 之前會不會有人先丟 ServiceError」看：

**fetch pattern（GET，無守衛）** — 如 `usp_dmz_service.fetch`：
```dart
try {
  final data = await Dmz.fetch(_usp);   // codegen / WASM 失敗 → 一律丟「raw 字串」
  return _toModel(data);                 // 純資料組裝，不丟 ServiceError
} catch (e) {
  throw mapUspErrorToServiceError(e);    // 直接 map，不需守衛
}
```
**為何 fetch 不需要守衛**：fetch 的 try 區塊裡，唯一會丟的是 codegen / WASM 的 **raw 字串**（如 `'Get failed: ... (code: 9998)'`），以及純資料組裝（不會丟 ServiceError）。**catch 收到的 `e` 不可能是 ServiceError**，所以 `if (e is ServiceError)` 永遠為 false，加了也沒用 → 標準 fetch 都不加。

**save pattern（SET/ADD/DELETE，有守衛）** — 如 `usp_dmz_service.add` / `.update`：
```dart
try {
  final result = await Dmz.update(...);
  switch (UspResultParser.parseSetResult(result)) {
    case UspSuccess(): break;
    case UspPartialSuccess(...): throw UspPartialFailureError(...);  // ← service 自己丟 ServiceError
    case UspFailure(...):        throw UspCompleteFailureError(...); // ← 同上
  }
} catch (e) {
  if (e is ServiceError) rethrow;       // 守衛：別把自己剛丟的 Usp*FailureError 又包一層
  throw mapUspErrorToServiceError(e);    // 其餘 raw 字串才 map
}
```
**為何 save 需要守衛**：save 會先解析 batch envelope、**主動 `throw UspPartialFailureError` / `UspCompleteFailureError`（這些已是 ServiceError）**。若沒有守衛，這些自拋的 ServiceError 會被外層 catch 接住、再丟進 `mapUspErrorToServiceError`，因不符 `"{Op} failed:"` 格式而被誤包成 `UnexpectedError`，語意全失。守衛就是讓「自己丟的 ServiceError 原樣冒上去」。

> **一句話**：守衛 = 「try 區塊裡會不會自拋 ServiceError」的指標。會（save）→ 需要守衛；不會（fetch）→ 不需要。

`is ServiceError` 守衛**只出現在寫入/operate 方法**（update/save/add/delete/enable/disable/ping/traceRoute…），fetch 一律沒有。這是規則，無例外。

- ⚠ **不走此映射的例外**：`apps` service 丟 raw `Exception`（`usp_apps_service.dart`，因是 lighttpd 靜態 JSON 非 USP）；`_shared` 的 polling / PDF service 故意 swallow（有註解說明）。這些不符合上述 ServiceError 契約。

### Provider 層的固定機制
- framework `save()`（`preservable_notifier_mixin.dart`）**透明不 catch**，讓 `ServiceError` 直穿到 View。framework 完全不 import `ServiceError`。這是 save 路徑「Provider 只 rethrow、View 用 try/catch 接」能成立的底層原因。

### PR #953 之前的痛點（為何要做那次重構）

重構前，Service 層雖然已經產出 typed `ServiceError`，但這個型別在上層被丟棄，導致 UI 無法依型別在地化：

- **Provider fetch** 把 `ServiceError` 壓成 `status.errorMessage = '$e'`（型別在此遺失），每個 notifier 手寫複製、無共用 helper。
- **View** 沒有任何 `ServiceError → 訊息` 的 mapper；`showFailedSnackBar(ctx, 'Failed to save: $e')` 在 ~10 個 view 逐字重複，錯誤訊息幾乎不 localize（save 錯誤訊息中只有 1 個有在地化）。

PR #953 把這條線打通：Provider 透傳型別（`ServiceError? error`，不再 `'$e'`）、新增中央 mapper `localizeServiceError()`（`lib/components/localizations/service_error_localizations.dart`）+ 共用空狀態 widget `ServiceErrorView`，View 一律走它們在地化。**怎麼照著寫見 [實作指南](error-handling-implementation-guide.md)。**

### 尚未做的事

- **contract test（TODO）**：用 §2.1/§2.2 固定 Rust client-side 字串契約（transport/auth/protocol 的映射靠對 Rust 字串 substring/regex，Rust 端字串一改就無聲失效）。透傳的 7xxx/9xxx 不在此契約內，由 firmware 決定，需另向 firmware 團隊索取 vendor fault code 表。
- **§2.5 GET 9999→9998 bug（已知，尚未修）**：見該節。

> **本文是「背景知識／全鏈路參考」（回答「為什麼」）。** 實際「怎麼跟著現存 pattern 實作 error handling」（Service／Provider／View 三層寫法、該顯示什麼、注意事項、checklist）見 [實作指南](error-handling-implementation-guide.md)。
> §2.5 的 GET 9999→9998 bug 仍未修——實作 localization 時的已知限制（GET 連線失敗會被在地化成「輸入錯誤」），也記在實作指南 §7。

---

## 檔案索引

**Dart**：`usp_client.dart`(facade)、`web/usp_client_wasm.dart`(WASM 邊界)、`errors/usp_error.dart`(映射)、`errors/service_error.dart`(型別)、`models/usp_operation_result.dart`(envelope 解析)、`providers/usp_mutation_lock.dart`、`bridge_request_throttler.dart`、`framework/preservable_notifier_mixin.dart`、`web/usp_init.js`+`usp_client.js`。
**Rust** (`usp-client/`)：`src/wasm/mod.rs`(邊界+serializer)、`src/client.rs`(編排)、`src/error.rs`(**所有 error 字串**)、`src/protocol/{encode,decode}.rs`、`src/transport/http.rs`、`proto/usp.proto`、`doc/wasm-api-reference.md`(部分漂移)。
