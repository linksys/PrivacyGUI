# USP Full-Chain Reference: Data Format, Error Enumeration, Error Handling Mechanism

> Source: `PrivacyGUI`(Dart) + `usp_framework/usp-client`(Rust/WASM). The firmware-side `usp-bridge` / `OBUSPA` are unreadable, treated as a black box.
> This doc covers three things (background knowledge, answering "why"): **(1) what a request looks like at each layer (2) exhaustive enumeration of every error WASM can throw (3) the rationale behind the existing error handling patterns**.
> For "how to implement it" see the [implementation guide](error-handling-implementation-guide.md).

> **Where in the codebase**
> - **Diagnostic fields**: the `ServiceError` base class carries `code` / `detail`; the 5 subclasses use a unified `detail` (no longer their own `message` each); each `_mapXxx` in `mapUspErrorToServiceError` carries `code`+`detail`; `UspCompleteFailureError`/`UspPartialFailureError` store `List<UspErrorDetail> failures` (`failedPaths` is a derived getter). The fault code / raw message therefore never get lost on the way to ServiceError, usable for both UI and log.
> - **localization**: the View produces a localized message based on the ServiceError type (central mapper `localizeServiceError`), implemented in PR #953. For how to write it see the [implementation guide](error-handling-implementation-guide.md).
> - **§2.5 GET bug (known, not yet fixed)**: a 9999 GET failure is disguised as 9998.

---

## Layer Quick Reference (main line: USP read/write = HTTP POST, not WebSocket)

**Set the full picture straight first**: at the bottom this project talks to the router over only **HTTP / SSE / WebSocket** transports (SSE is essentially a long-lived HTTP connection; Bluetooth is listed in `pubspec.yaml` but is not actually used in `lib/`).
But for the topic "how a USP request goes out, and how errors come back", there is **only one main line, plus two side branches** — they are not equal "pick one of three" options; they are different dimensions:

**Main line (request / response) — almost all of §1–§3 talks about this one:**
Every feature's get/set/add/delete/operate goes through `UspClient`(WASM) → HTTP POST `/api/v1/usp`.
```
1 Notifier/Provider   Dart   mutation lock, ref.listen invalidation
2 Service             Dart   business logic + error mapping (mapUspErrorToServiceError) ◄ error contract boundary
3 Codegen (.g.dart)   Dart   TR-181 type ↔ Dart, assemble full path
4 UspClient facade    Dart   throttler(GET dedup), 401 retry, value stringify, GET coerce
5 UspClientWeb        Dart   Dart↔WASM (jsify/dartify)
6 JS glue             JS     window.UspClient, WASM loading
─────────────────────── WASM boundary ───────────────────────
7 wasm/mod.rs         Rust   exported fn, JS value→struct, two error strategies
8 client.rs           Rust   msg_id, command_key, ResponsePool correlation
9 protocol            Rust   protobuf encode/decode, Record/Msg
10 transport/http.rs  Rust   POST /api/v1/usp (fetch), Bearer token
─────────────────────── readable right edge ───────────────────────
11 usp-bridge (black box) → 12 OBUSPA (black box) → 13 TR-181 data model
```

**Side branch 1 — SSE notifications (push, not request/response)**: invalidation / events **proactively pushed** by firmware,
`UspBridgeClient.notifications()` reads `/api/v1/notifications` with Fetch + ReadableStream, **pure Dart, does not go through WASM**.
It is not "another path for sending a request" but another interaction mode (server→frontend). It is a different story from "error mapping"; just be aware it exists.

**Side branch 2 — WebSocket (special case, separate class)**: used **only** for firmware upload,
`UspWsClientWrapper` connects to `wss://.../usp-ws` (the WASM holds the socket); across the whole codebase only `firmware_ws_upload_strategy.dart` uses it, and it has its own exception handling. The rest of this doc does not touch it.

> In one sentence: **just follow the main line**; SSE is "receive push", WebSocket is "transfer firmware", neither is on the error-mapping topic of §1–§3.

---

# 1. Request Data Format: What Each Layer Looks Like

Take **DMZ** as the example (SET: enable DMZ pointing to `192.168.1.150`).

### Downstream (request going out)

| Layer | Data shape | File |
|---|---|---|
| **2 Service input** | typed object, a null field = "not set this time"<br>`DmzEntryUpdate(instancePath:'Device.Firewall.DMZ.1.', enable:true, destIp:'192.168.1.150', sourcePrefix:'0.0.0.0/0')` | `usp_dmz_service.update` |
| **3 Codegen assembles path** | `Map<String,dynamic>`, key=full TR-181 path, value is still a **native type**<br>`{'Device.Firewall.DMZ.1.Enable': true, '...DestIP': '192.168.1.150', '...SourcePrefix': '0.0.0.0/0'}` | `dmz.g.dart Dmz.update` |
| **4 UspClient stringify** | `Map<String,String>`, all values converted to strings<br>`{'...Enable': 'true', '...DestIP': '192.168.1.150', ...}` | `usp_client.dart _batchSet` |
| **5 → JS** | `parameters.jsify()` → JS object; options `allowPartial:false` → **`undefined`** | `usp_client_wasm.dart UspClientWeb.set` |
| **7 Rust parse** | `Vec<(String,String)>` (⚠ must be stringified first, otherwise `as_string()` returns None → becomes `"JsValue(true)"`) | `wasm/mod.rs UspClient::set` |
| **9 protobuf** | grouped **by parent path** (split at the last `.`) into `UpdateObject`:<br>`Msg{Header{msg_id:uuid, msg_type:SET}, Body{Set{allow_partial:false, update_objs:[{obj_path:'Device.Firewall.DMZ.1.', param_settings:{Enable:'true', DestIP:'192.168.1.150', SourcePrefix:'0.0.0.0/0'}}]}}}` | `encode.rs encode_set_request` / `extract_object_and_param` |
| **10 on the wire** | `POST /api/v1/usp` / `Content-Type: application/octet-stream` / `Authorization: Bearer <jwt>` / body=binary protobuf (**bare Msg, no Record**, Record is added by the bridge) | `http.rs post`(wasm) / `post_protobuf` |

### Upstream (response coming back) — unified envelope

The return is always the WASM v0.11.0 unified format: `{ success, result: { data, error? } }`. **`error` is omitted entirely when there is no error; on partial failure `success:true` but it carries `error`** — so even with `success===true` you must still check `error`.

```js
// SET success
{ success: true, result: { data: { "Device.Firewall.DMZ.1.Enable": "true", ... } } }

// SET partial(SourcePrefix value invalid)
{ success: true, result: {
    data:  { "Device.Firewall.DMZ.1.Enable": "true", "...DestIP": "192.168.1.150" },
    error: { "Device.Firewall.DMZ.1.SourcePrefix": { errorCode: 7006, errorMessage: "..." } } } }

// transport failure(401/timeout)
{ success: false, result: { error: { "<path>": { errorCode: 9999, errorMessage: "Transport error: ..." } } } }
```

| Layer | Action | File |
|---|---|---|
| **10 dartify** | JS object → `Map<String,dynamic>` (recursive coerce) | `usp_client_wasm.dart UspClientWeb.set` |
| **11 UspClient** | returns as-is (only logs); codegen also returns it as-is to the service | `usp_client.dart` |
| **12 Service parse** | `UspResultParser.parseSetResult(map)` → `UspSuccess` / `UspPartialSuccess` / `UspFailure` | `usp_operation_result.dart _parseGenericResult` |

### get/set is "synchronous HTTP round-trip", only operate uses SSE

- **get / set / add / delete**: `client.rs`'s `send_usp(...).await` directly gets the **complete protobuf body of the same HTTP response** (`post` returns `response.bytes()`), and decodes the data on the spot with `decode_*_response`. **Never touches SSE the whole way; one HTTP round-trip and it's done.**
- **Purpose of `response_pool` (msg_id correlation)**: when **responses of concurrent HTTP requests come back out of order**, it uses msg_id to pair "which body belongs to which request". It is an internal mechanism of synchronous req/resp, unrelated to SSE.
- **operate splits into synchronous/asynchronous**:
  - **Synchronous operate (the majority, e.g. reboot, factory reset)**: the result is directly in the HTTP response's `OperSuccess.output_args`, **same as get/set: one round-trip, no SSE**, calling `UspClient.operate` directly.
  - **Asynchronous operate (the minority, only diagnostics: ping/traceroute/nslookup/download)**: HTTP only returns an **ACK** (protobuf `operate_resp = None`, containing the client-generated commandKey); the real result is obtained by the Dart `SseOperationAwaiter` (`network_diagnostics_executor`) waiting for the SSE `OperationComplete` event (Direct Data Delivery).
  - **SSE waiting applies only to this one category**; get/set/add/delete and all other operate do not apply.

> ⚠ **GET and SET error handling are asymmetric**: SET preserves the envelope and goes through `UspResultParser`; GET, on the other hand, discards the envelope in `UspClientWeb.get` and keeps only the flattened `data`, so a failure only surfaces when WASM itself throws a string. This asymmetry causes a major defect (a 9999 GET failure is disguised as 9998) — **for the full causality see §2.5**.

---

# 2. Error Source and Form (enumeration → ServiceError mapping spec)

### 2.0.0 Core Overview: error "source" and "form" are two independent axes ⚠⚠

To understand the whole error model, the most important thing is to **not tie together "who produces the error" and "what form the error takes"**. They are two independent axes:

**Axis one — source (who produces it) has 3:**
1. **Rust WASM client** (layers 7–10)
2. **firmware** (bbfdm / OBUSPA, Rust only passes through)
3. **Dart codegen** (`lib/generated/*.g.dart`)

**Axis two — form (what it looks like) has 2:**
- **A. throws a string** (Promise reject / Dart throw): `"{Op} failed: {category}: {detail}"`
- **B. structured envelope**: `{success, result:{data, error?{path:{errorCode, errorMessage}}}}`

**Key point: both forms have different sources mixed in — you cannot say "WASM=string, firmware=envelope".** The real correspondence is:

| Source | Form | code / identification | Meaning |
|---|---|---|---|
| **WASM** (lifecycle methods login/logout/subscribe…) | **throws a string** | `"Login failed: ..."` and other prefixes | client-side failure |
| **WASM** (data operations get/set… on failure) | **envelope** | **9999** | request **did not reach firmware** (network/auth/encoding) |
| **firmware** (passed through) | **envelope** (when GET goes through codegen it may also be inside the `(code:)` of a thrown string) | **7xxx / 9xxx** | **reached firmware, but was rejected by it** |
| **firmware** (passed through) | **envelope** | `success:true` | **firmware processed it successfully** |
| **Dart codegen** | **throws a string** | **9998** | GET response is missing a required field |

> **"Lifecycle methods"** refers to methods that manage "the session/connection itself" rather than reading/writing router data: login/logout/refreshToken/subscribe/unsubscribe.
> They are not called by the UI directly — login/logout are triggered in tandem by `UspAuthCoordinator` along with the **local login flow** (the user entering the router password): after a successful local login it logs USP in with the same password, and on app restart it `restoreSession`s with the stored password. subscribe/unsubscribe are managed internally and automatically by the SSE system (`SseManager`).

---

### 2.0 Boundary Rule: throws a string vs structured envelope —— **split by "which method", not by "error type"** ⚠

This is the most misunderstood part of the whole error model. You have to look at **two handoff points**: **(1) the format WASM returns to Dart** and **(2) the format the Service gets from Dart's layer 5 (`UspClientWeb`)**. The two differ, and GET especially shows it.

**(1) The format WASM returns to Dart** — each method hard-codes its failure form in `wasm/mod.rs`; the boundary is **by "which method"**, not by error type:

| Method group | Failure form WASM returns | Even for network/auth/timeout errors? | Source |
|---|---|---|---|
| **Lifecycle methods**: `login` / `logout` / `refreshToken` / `subscribe` / `unsubscribe` / `listSubscriptions` / constructor | **A. throws a string** (Promise reject) | yes, always throws a string | each method's `Err(e) => Err(JsValue::from_str(...))` |
| **Data operations**: `get` / `set` / `setOrdered` / `add` / `delete` / `operate` | **B. structured envelope** (`{success:false or partial, result:{error}}`, code 9999) | **yes! network/auth errors are also wrapped into an envelope (9999), not thrown as a string** | `set`'s `Err(e) => build_transport_error_unified(...)` |

Evidence (the two branches of `UspClient::set` in `wasm/mod.rs`, get is the same):
```rust
match client.set_with_options(params_vec, ...).await {
    Ok(response) => serialize_set_response_to_js(&response),       // → envelope, code decided by firmware (7xxx/9xxx/success)
    Err(e)       => build_transport_error_unified(&path_list, ...),// → envelope, code hard-coded 9999 (even timeout/401 goes here)
}
```

**(2) The format the Service gets from Dart's layer 5** — Dart's layer 5 (`UspClientWeb`) reprocesses it, making the form the service gets **different from what WASM returned**; this is the root of GET's imprecision:

| Operation | Failure form the service gets from layer 5 |
|---|---|
| `set` / `setOrdered` / `add` / `operate` | **keeps the envelope** (parsed by `UspResultParser`) |
| `delete` | the WASM exception is synthesized into an envelope by layer 5 (still envelope) |
| **`get`** | ⚠ **becomes a string**: layer 5 takes only `result.data` and discards the envelope's `success`/`error`; on failure the service gets the **9998 string thrown by codegen** or a string rethrown by WASM, **not an envelope** (see §2.5) |

> In one sentence: **the GET failure WASM returns to Dart is an envelope, but this envelope is dismantled by layer 5, so the GET failure the service gets is a string.** The §2.0.0 table and §2.5 description both describe the format the service gets (GET=string).

> For reading a structured envelope see §2.3: **`success:false` ≠ firmware processed it successfully**. Only the errorCode tells you whether the request reached firmware.

### 2.1 Unified format of the thrown string (three-level nesting)

Yes, the thrown-string format is **completely unified**, assembled level by level via `write!` by Rust's `Display` impl, with a fixed three-level structure:

```
"{operation prefix}{category}: {detail}"
   └─ §2.1 table  └─ §2.2 one of five   └─ actual error message (may further contain (code: XXXX))
```

Assembly source (Rust `error.rs`'s `Display` impl): the outer `UspError::Display` writes `"{category} error: {sub error}"`, then each WASM method prepends the operation prefix in front of it. Example breakdown:

```
"Set failed: Protocol error: Decoding error: Received error response: ... (code: 7026)"
 ─────┬────  ──────┬───────  ───────────────────────┬──────────────────────────────
 op prefix      category(protocol)          detail (contains passed-through firmware code 7026)

"Login failed: Authentication error: Invalid credentials"
 ──────┬─────  ─────────┬───────────  ────────┬─────────
 op prefix         category(auth)          detail

"Get failed: Validation error: Required fields missing from response: DestIP (code: 9998)"
 ─────┬────  ───────┬─────────  ──────────────────┬─────────────────────────────────────
 op prefix   category(validation)    detail (the missing-field error thrown by Dart codegen, code 9998)
```

The Dart-side `parseUspError` (`usp_error.dart`) relies on this fixed structure to break it apart:
- `_opPrefix = ^(\w+) failed: (.+)$` splits out the operation and the rest
- `_parseCategoryAndMessage` matches the 5 category prefixes (§2.2)
- `_faultCode = \(code:\s*(\d+)\)` grabs the fault code from the end of detail
- `_httpStatus = HTTP error: HTTP (\d+)` grabs the HTTP status code

⚠ Exception: a few strings that don't match `"{X} failed:"` (e.g. WS's `"UspWsClient is closed"`, SSE's `StateError`) can't be parsed → `parseUspError` returns null → mapped to `UnexpectedError`.

### 2.1.1 Thrown-string prefixes

Dart error mapping **only needs to handle these 7** (main line, the everyday USP request path):

(all in each method's `Err(e) => Err(JsValue::from_str(...))` in `wasm/mod.rs`)

| Operation | prefix |
|---|---|
| constructor | `"Failed to create client: "` |
| login | `"Login failed: "` |
| logout | `"Logout failed: "` |
| refreshToken | `"Token refresh failed: "` |
| subscribe | `"Subscribe failed: "` |
| unsubscribe | `"Unsubscribe failed: "` |
| listSubscriptions | `"List subscriptions failed: "` |

**There are 7 more WebSocket strings that can be ignored** (`"encode Msg failed: "`, `"wrap Record failed: "`, `"unwrap Record failed: "`, `"decode Msg failed: "`, `"encode Operate failed: "`, `"build WSConnect failed: "`, `"UspWsClient is closed"`). Reasons:
- They belong to **side branch 2 (WebSocket firmware upload)**, not on the everyday GET/SET/notification path.
- The whole section is wrapped by `#[cfg(feature = "websocket")]` (the `ws_binding` module in `wasm/mod.rs`), and `Cargo.toml`'s `default = ["native"]` **does not include the websocket feature** — unless build explicitly passes `--features websocket`, these 7 functions along with their error strings **are not compiled into the WASM binary at all**.
- Conclusion: `mapUspErrorToServiceError` does not need to handle them.

### 2.2 category (5 kinds) + nested sub-strings (error.rs; this is the string that follows the prefix, and also appears inside the 9999 errorMessage)

| category prefix | sub-variant Display string (detail) |
|---|---|
| `Transport error: ` | `Network error: {m}`/`HTTP error: {m}` (m can be `HTTP 500`/`HTTP 404`/`WASM not yet implemented`)/`Request timeout`/`Connection refused`/`TLS error: {m}`/`Invalid URL: {m}`/`Response correlation timeout for msg_id: {id}` |
| `Protocol error: ` | `Encoding error: {m}`/`Decoding error: {m}` (contains `Received error response: {msg} (code: {code})`)/`Malformed message: {m}`/`Unsupported version: {m}`/`Missing field: {m}` |
| `Authentication error: ` | `Invalid credentials`/`Session expired`/`Invalid token: {m}` (`No token in response`/`No token in refresh response`)/`Permission denied`/`Authentication required` |
| `Operation error: ` | `Get/Set/Add/Delete failed for '{path}': {reason}`/`Operate failed for '{command}': {reason}`/`Path not found: {path}`/`Parameter is read-only: {path}`/`Invalid value '{value}' for '{path}': {reason}` ⚠ this group is only constructed in Rust **native ffi** (`ffi/mod.rs`, `#[cfg(not(target_arch="wasm32"))]`), **not included in the WASM build → unreachable in production**. The corresponding `_mapOperationError` is dead code (see the comment on that function in `usp_error.dart`) |
| `Validation error: ` | client-side: `Delete paths cannot be empty`/`Invalid JSON: ...`/`... not yet implemented` etc. |

There are also 3 input-validation strings packed directly into 9999: `"Invalid path format: all paths must be strings"`, `"Invalid input: paths must be string or array of strings"`, `"Invalid input: items must be object or array of objects with {path, params}"`.

### 2.3 Numeric error codes

> ⚠ **fault codes come from two source categories**, and **only the client-side 9999 can be exhaustively enumerated from Rust**;
> firmware fault codes (7xxx / 9xxx) are the **open set on the router-side bbfdm**, which the Rust client only **passes through, does not enumerate, does not hard-code**.
> Therefore "exhaustively enumerate all error codes from the usp-client source" **does not hold** for passed-through codes — they are not in the Rust source.
> The real fault-code list is on the firmware (bbfdm/OBUSPA) side; you need to request the vendor fault-code table from the firmware team.

| code | When | Source | Handling for Dart |
|---|---|---|---|
| **9999** | any transport/auth/protocol/validation failure (including input validation). message = `"Transport error: " + UspError Display` | **generated by the Rust client itself** (`wasm/mod.rs build_transport_error_unified`, the only hard-coded code) | parse the category/detail inside message, then map |
| **7xxx** (TR-369 standard range) | per-path/per-param failure returned by firmware. message = firmware's original text | **passed through by firmware** (copied verbatim, Rust does not synthesize) | semanticize: 7004/7005/7006→InvalidInput, 7026/7027→ResourceNotFound; the rest go to agent error |
| **9xxx** (bbfdm vendor range) | SET/GET rejected by the bbfdm backend (e.g. `9001` rejected, `9005` unimplemented parameter, `9008` read-only) | **passed through by firmware(bbfdm)** | 9001→Unauthorized, 9005/9007→ResourceNotFound, 9008→InvalidInput |
| **9998** | GET response is **missing a required field** (router did not return some param). **Not emitted by Rust, thrown by Dart codegen**: `'Get failed: Validation error: Required fields missing from response: ... (code: 9998)'` (34 `lib/generated/*.g.dart`) | **Dart codegen** | goes through `category=validation` → `InvalidInputError` |
| 9997 | — | none of Rust / lib / test have this code | does not exist, no need to handle |
| 0 | success sentinel, does not appear in the error block | — | — |

> Evidence (9xxx really is router behavior, not dead code): `usp_test_console_view.dart` marks "expect fault 9005/9008";
> `usp_ipv4_section.dart` + `usp_internet_settings_service.dart` comment "bbfdm rejects SET (fault 9001)";
> `test/core/usp/errors/usp_error_test.dart` has verified the 9001/9005/9008 mappings.

#### 9999 vs 7xxx/9xxx —— essential difference: **whether the request reached firmware**

This is the core of reading a structured envelope. Both look like `{success:false, error:{path:{errorCode, errorMessage}}}`, but their meanings are opposite:

| | **9999** | **7xxx / 9xxx** |
|---|---|---|
| Who produces it | **the Rust client itself** (`build_transport_error_unified`, the only hard-coded code) | **firmware** (OBUSPA/bbfdm), Rust only passes through |
| From which branch | the `Err(e)` branch of `set/get/...` | the `Ok(response)` branch, reading `err_code` from the successfully decoded response (`serialize_*_response_to_js` in `wasm/mod.rs`) |
| Did the request reach firmware | **no** — it failed on the client side, never (successfully) connected to the router | **yes** — firmware received it, processed it, and proactively rejected it |
| Underlying errors it covers | **one code packs five categories**: ① transport (timeout / connection refused / HTTP 5xx / TLS) ② auth (401 / session expired) ③ protocol (protobuf encode/decode failure, correlation timeout) ④ client validation (path format wrong) ⑤ wrong input shape | a single clear semantic: parameter read-only / value invalid / path not found / bbfdm rejected… |
| errorMessage | `"Transport error: " + UspError Display` (all detail hidden inside the string, must be parsed again) | firmware's original text |
| Meaning for the UI | "**not sent out**, please check connection / re-login / retry" | "**sent but rejected**, please change your input" |

**In one sentence**:
- `errorCode == 9999` → this is not firmware's fault; the problem is **between the client and the router** (network, authentication, encoding). The same 9999 covers **five major categories** — timeout, 401, TLS, protobuf error, etc. — and you only learn the real type by further parsing the `"Transport error: {category}: ..."` inside `errorMessage`.
- `errorCode` is 7xxx or 9xxx → the request **did reach firmware and was processed by it**; firmware proactively returned this fault code (7xxx=TR-369 standard, 9xxx=bbfdm vendor). The code itself is clear semantics; just map it directly.

> Corollary: seeing `success:false` **cannot** be taken to mean "firmware processed it successfully". **Only `success:true` (full success or partial) guarantees firmware processed it.**
> For `success:false` you must first look at the code: 9999=did not reach firmware; 7xxx/9xxx=reached and was rejected.

#### "Information completeness" of each source: are code and message always present?

What each source stuffs in when building the error determines whether Dart can trust that code / message always exists:

| Source | errorCode | errorMessage | Note |
|---|---|---|---|
| lifecycle string (login…) | ⚠ **not guaranteed** | ✅ always present | string = prefix + category + detail; only when the underlying is protocol (passed-through firmware) does detail carry `(code:)`. **auth-category errors have no code to begin with** → `parseUspError` can't grab it → faultCode=null |
| 9999 envelope | ✅ always 9999 | ✅ always present | `errorMessage` is at least `"Transport error: ..."`, but may be short (e.g. `Request timeout`) |
| firmware passed-through envelope (7xxx/9xxx) | ✅ field always present | ⚠ **field always present, value may be empty string** | `serialize_*_response_to_js` unconditionally stuffs both fields; but `err_msg` is a protobuf `string`, and when firmware doesn't fill it, it is `""` (not null) |
| codegen 9998 string | ✅ always 9998 | ✅ always present | the message contains the list of missing fields, and is only thrown when `missing.isNotEmpty` |

**Dart model-layer fallback** (`UspErrorDetail.fromMap`): `errorCode` missing→`-1`, `errorMessage` missing/null→`'Unknown error'`. So by the Dart model layer, **both are always non-null**.

> In one sentence: the **fields** of the envelope categories (9999/firmware/9998) are all guaranteed to exist (the Dart layer adds `-1`/`'Unknown error'` as a further fallback); the only two not guaranteed are — **lifecycle strings often lack a code** (auth errors have no code), and **the firmware message value may be an empty string** (the field is still there).

### 2.4 Dart mapping rules (`mapUspErrorToServiceError` in `usp_error.dart`) cross-reference

The existing fault-code map (`_mapProtocolError` in `usp_error.dart`):
`7004/7005/7006→InvalidInput`, `7026/7027→ResourceNotFound`, `9001→Unauthorized`, `9005/9007→ResourceNotFound`, `9008→InvalidInput`.
At this point the semantics are already aligned with `UspErrorDetail` (`usp_operation_result.dart`, which recognizes 7004/7005/7006/7026/7027).

> **Diagnostic fields**: when each `_mapXxx` produces a ServiceError it carries `code` (faultCode / httpStatus) + `detail` (raw message). Even when the type information is coarser (e.g. `ResourceNotFoundError`), the underlying code/detail is still on the ServiceError for log and View use.

Behavioral characteristics and limitations:
1. **Semanticization of the envelope path is consumed in the View**: batch SET/ADD/DELETE failures go through `UspResultParser` → service throws `Usp{Partial,Complete}FailureError`.
   - These two types store `List<UspErrorDetail> failures` (full path+code+message), so fault codes are not lost; helpers like `UspErrorDetail`'s `isObjectNotFound`/`isInvalidParameterValue` are available.
   - Path 2 only produces the two **container types** `UspPartial/CompleteFailureError`; unlike path 1, it does not subdivide into `ResourceNotFoundError`/`InvalidInputError` by code. This is **by design** — a batch may have multiple entries each with a different code, which cannot be stuffed into a single semantic type. Semanticization happens in the **View**: iterate over `failures`, judge the code with a helper per entry to decide what to display (for how, see [implementation guide](error-handling-implementation-guide.md) §4.2).
2. **9999 has no dedicated mapping**: it is the most common client-side code, but the mapping only looks at the category string inside message, not at code 9999 itself (it currently works fine, because the string is sufficient).
3. **WS / SSE `StateError`** (e.g. `'WebSocket connection timeout'`) does not match the `"{Op} failed:"` format, so by the time it reaches `mapUspErrorToServiceError` it just becomes a generic `UnexpectedError`.
4. **The string contract is fragile** (the "Error Contract" self-comment table at the top of `usp_error.dart`): the transport/auth/protocol mappings rely on substring/regex against Rust strings; **the moment the Rust-side string changes, it silently fails**. §2.1/§2.2 are the complete client-side output contract of the current Rust, and can be turned into a contract test to pin it down (note: the passed-through 7xxx/9xxx are not in this contract; they are decided by firmware).

### 2.5 ⚠⚠ Major defect: a GET-failure 9999 is disguised as 9998, a network error misjudged as an input error

This is the entry with **the most severe semantic misplacement** in the error model, and is an **unfixed bug**.

**Symmetry break**: SET/ADD/DELETE preserve the envelope → go through `UspResultParser.parseSetResult` → semantically correct;
but **GET dismantles the envelope already at layer 5 (`UspClientWeb.get` in `usp_client_wasm.dart`), takes only `result.data`, and discards `success`/`error`**.
Therefore the corresponding `UspResultParser.parseGetResult` (`usp_operation_result.dart`) is **dead code, called by no one** (only a definition + a unit test exist).

**Consequence — the actual flow of a 9999 GET failure**:
```
WASM returns {success:false, error:{path:{errorCode:9999}}}   ← network down / did not reach firmware
   ↓ UspClientWeb.get takes only data (success/error discarded)
data = {}                                                 ← the failure envelope has no data → empty map
   ↓ codegen _fromResponse checks required fields (dmz.g.dart)
all required fields missing → throw 'Get failed: Validation error: ... (code: 9998)'
   ↓ service catch → mapUspErrorToServiceError
→ category=validation → InvalidInputError
```
**A 9999 (cannot connect to router, should be `NetworkError` "please retry") is silently turned into 9998 (missing field) → `InvalidInputError` ("there's a problem with your input").** The error semantics are completely misplaced, and the user receives a misleading message.

**The only case that is not affected**: if WASM's GET is a whole Promise **reject** (throws a string instead of returning an envelope), `UspClientWeb.get`'s `catch → rethrow` lets the string bubble up as-is and be mapped correctly. But §2.0 has already confirmed that a GET failure mostly goes through `build_transport_error_unified` returning an envelope → affected.

**Cross-reference table**:

| | Design intent | Actual code |
|---|---|---|
| GET failure envelope | hand it to `parseGetResult` to judge success/error | the envelope is dismantled at layer 5, only data left |
| 9999 GET failure | → `NetworkError` (cannot connect) | disguised as 9998 → `InvalidInputError` (input wrong) |
| `parseGetResult` | the parser for the GET path | **dead code, called by no one** |

**Fix directions** (not done, for future evaluation):
- **Direction A (treats the symptom, small)**: when `success==false`, instead of silently returning empty data, `UspClientWeb.get` should throw a string carrying 9999 → correctly mapped to `NetworkError`. Small blast radius.
- **Direction B (treats the root cause, large)**: have GET also preserve the envelope and go through `parseGetResult`, symmetric with SET. But this requires changing the return type of all codegen `fetch`; large blast radius.

> This echoes the last ⚠ item of §1 "GET's special transform" (GET discards the envelope, and a failure only surfaces when WASM itself throws a string) — this section is the full consequence and root cause of that note.

### 2.6 Convergence chart: two paths → ServiceError → View

All errors finally converge into a `ServiceError` in the **service's `catch (e)`**. The real basis for the split is **fetch (GET) vs write (SET/ADD/DELETE/operate)** — exactly corresponding to §3's fetch/save pattern.

> ⚠ Not in this chart: **lifecycle errors** (login/logout/refreshToken failures) are digested internally by `UspAuthCoordinator`; the **raw string never becomes a `ServiceError` and never flows into this chart**. But the app still learns the result in the form of "authentication state", just not as an error object:
> - `syncAfterLocalLogin`: after catch only logs and swallows (local login succeeds as usual, USP failure has no impact, falls back to JNAP)
> - `tryUspLogin` / `restoreSession`: catch → `return false` (the app gets a boolean, not a string)
> - `ensureAuth` (refreshToken): 401 → triggers the `onForceLogout` callback (forced logout)
>
> Design intent: USP is a second authentication channel attached alongside local login; on failure it degrades into an "is it usable" state, and should not make the app blow up with a `ServiceError`.

```
        Path 1: fetch (GET)                    Path 2: write (SET/ADD/DELETE/operate)
   receives a "string"                      receives an "envelope" {success,result:{data,error?}}
   ┌────────────────────────────┐         ┌────────────────────────────────────┐
   │ GET-failure string, two sources:│      │ the envelope's error contains a code:│
   │ • codegen missing required → 9998│     │ • 9999  (WASM didn't reach firmware)│
   │ • string WASM get rethrows itself│     │ • 7xxx/9xxx (firmware passthru, reject)│
   └────────────────────────────┘         └────────────────────────────────────┘
                  │                                          │
                  │                          UspResultParser.parseSetResult/Add/Delete
                  │                                → _parseGenericResult
                  │                                          │
                  │                       ┌──────────────────┼──────────────────┐
                  │                       ▼                  ▼                  ▼
                  │                  success & no error  success & has error  success=false
                  │                       │                  │                  │
                  │                       ▼                  ▼                  ▼
                  │                  UspSuccess       UspPartialSuccess     UspFailure
                  │                  (no throw)             │                  │
                  │                                        ▼                  ▼
                  │                               service switch → throw
                  │                       UspPartialFailureError / UspCompleteFailureError
                  │                              (which is itself a ServiceError)
                  │                                          │
                  ▼                                          ▼
        ╔═══════════════════════════════════════════════════════════════╗
        ║      service's  catch (e) { ... }   ← the two paths converge here ║
        ║   if (e is ServiceError) rethrow;    // path 2 self-thrown passes ║
        ║   else throw mapUspErrorToServiceError(e);  // only path 1 strings map ║
        ║        └ parseUspError splits string → UspError{category,faultCode} ║
        ║        → NetworkError / InvalidInputError / ResourceNotFound /   ║
        ║          Unauthorized / UnexpectedError                         ║
        ╚═══════════════════════════════════════════════════════════════╝
                                  │
                                  ▼   throw ServiceError
                          ┌──────────────┐
                          │   provider    │  save : rethrow
                          │               │  fetch: state.error = e (type passed through, not flattened to string)
                          └──────────────┘
                                  │
                                  ▼   ServiceError (type preserved)
                          ┌──────────────┐
                          │     View      │  localizeServiceError(ctx, e) → localized message
                          └──────────────┘
```

**Two-path cross-reference**:

| | Path 1: fetch (GET) | Path 2: write (SET/ADD/DELETE/operate) |
|---|---|---|
| Form the service receives | **string** (the envelope has already been dismantled by layer 5 `UspClientWeb.get`, only data left) | **envelope** `{success,result:{data,error?}}` |
| Source of string/code on failure | codegen throws 9998 for missing fields, or a string rethrown by WASM | `errorCode` inside error: 9999 (WASM) or 7xxx/9xxx (firmware) |
| Gate method | `mapUspErrorToServiceError` → `parseUspError` | `UspResultParser.parseXxxResult` → `_parseGenericResult` |
| Intermediate type | `UspError` (temporary, purely for splitting the string) | `UspSuccess` / `UspPartialSuccess` / `UspFailure` + `UspErrorDetail` |
| ServiceError produced | `NetworkError` / `InvalidInputError` / `ResourceNotFoundError` / `Unauthorized` / `UnexpectedError` | `UspPartialFailureError` / `UspCompleteFailureError` |
| How they converge | service catch receives a string → `mapUspErrorToServiceError` | service itself `throw Usp*FailureError` (already a ServiceError) → `if (e is ServiceError) rethrow` lets it pass, **does not map again** |

**Split decision point** (`_parseGenericResult`, path 2 only):
- `success && error==null` → `UspSuccess` (no throw, normal return)
- `success && error!=null` → `UspPartialSuccess` → service converts to `UspPartialFailureError`
- `success==false` → `UspFailure` → service converts to `UspCompleteFailureError`

> ⚠ Note 9999's classification: it is produced by WASM and represents "did not reach firmware" (§2.3), but **in form it is an errorCode inside an envelope**, so it goes through **path 2** (parser), not path 1. "Who produces it" and "which path it goes" are two different things.

> In one sentence: **strings go through `mapUspErrorToServiceError`, envelopes go through `UspResultParser`, and both converge into a `ServiceError` in the service `catch`**; afterward the provider passes the type through (save rethrow / fetch stores `state.error`), and the view localizes with `localizeServiceError` — for that see §3 and the [implementation guide](error-handling-implementation-guide.md).

---

# 3. The Rationale Behind the Error Handling Pattern (Service-layer mechanism)

> This section explains **why** the Service layer's fetch and save are written differently (fetch has no guard, save has a guard) — this is the most easily misunderstood core mechanism of the whole pipeline, and one that does not change over time.
> The **current practice** of the Provider / View layers (how the type is passed through, how it is localized for display) is in the [implementation guide](error-handling-implementation-guide.md); the end of this section only explains the pain points before PR #953, as background for "why that refactor was done".

The Service layer's error convergence (both fetch and save turn errors into `ServiceError`, relying on `mapUspErrorToServiceError` + `UspResultParser`) preserves the typed `ServiceError` and carries `code`/`detail` (path 1) or a `failures` list (path 2) diagnostic info.

### Service-layer detail: fetch and save are two different patterns —— the difference is "whether it self-throws a ServiceError"

The only structural difference between the two is **the `if (e is ServiceError) rethrow` guard**. To understand it, look at "whether anyone throws a ServiceError before the catch":

**fetch pattern (GET, no guard)** — e.g. `usp_dmz_service.fetch`:
```dart
try {
  final data = await Dmz.fetch(_usp);   // codegen / WASM failure → always throws a "raw string"
  return _toModel(data);                 // pure data assembly, does not throw ServiceError
} catch (e) {
  throw mapUspErrorToServiceError(e);    // map directly, no guard needed
}
```
**Why fetch needs no guard**: inside fetch's try block, the only thing that can be thrown is codegen / WASM's **raw string** (e.g. `'Get failed: ... (code: 9998)'`), plus pure data assembly (which does not throw ServiceError). **The `e` the catch receives can never be a ServiceError**, so `if (e is ServiceError)` is always false; adding it is useless → standard fetch never adds it.

**save pattern (SET/ADD/DELETE, with guard)** — e.g. `usp_dmz_service.add` / `.update`:
```dart
try {
  final result = await Dmz.update(...);
  switch (UspResultParser.parseSetResult(result)) {
    case UspSuccess(): break;
    case UspPartialSuccess(...): throw UspPartialFailureError(...);  // ← service itself throws a ServiceError
    case UspFailure(...):        throw UspCompleteFailureError(...); // ← same as above
  }
} catch (e) {
  if (e is ServiceError) rethrow;       // guard: don't re-wrap the Usp*FailureError I just threw
  throw mapUspErrorToServiceError(e);    // only the remaining raw strings get mapped
}
```
**Why save needs the guard**: save first parses the batch envelope and **proactively `throw UspPartialFailureError` / `UspCompleteFailureError` (these are already ServiceError)**. Without the guard, these self-thrown ServiceErrors would be caught by the outer catch and thrown into `mapUspErrorToServiceError` again, and because they don't match the `"{Op} failed:"` format, they would be mis-wrapped into `UnexpectedError`, losing all semantics. The guard is what lets "the ServiceError I threw myself bubble up as-is".

> **In one sentence**: the guard = an indicator of "whether the try block self-throws a ServiceError". Yes (save) → needs a guard; no (fetch) → does not.

The `is ServiceError` guard **only appears in write/operate methods** (update/save/add/delete/enable/disable/ping/traceRoute…); fetch never has it. This is the rule, no exceptions.

- ⚠ **Exceptions that do not go through this mapping**: the `apps` service throws a raw `Exception` (`usp_apps_service.dart`, because it is lighttpd static JSON, not USP); `_shared`'s polling / PDF service deliberately swallows (with comments explaining). These do not conform to the ServiceError contract above.

### Provider-layer fixed mechanism
- the framework `save()` (`preservable_notifier_mixin.dart`) is **transparent and does not catch**, letting the `ServiceError` pass straight through to the View. The framework does not import `ServiceError` at all. This is the underlying reason the save path's "Provider only rethrows, View catches with try/catch" can hold.

### Pain points before PR #953 (why that refactor was done)

Before the refactor, the Service layer already produced a typed `ServiceError`, but this type was discarded in the upper layers, so the UI could not localize by type:

- **Provider fetch** flattened the `ServiceError` into `status.errorMessage = '$e'` (the type was lost here), and each notifier hand-wrote a copy, with no shared helper.
- **View** had no `ServiceError → message` mapper at all; `showFailedSnackBar(ctx, 'Failed to save: $e')` was repeated verbatim across ~10 views, and error messages were barely localized (only 1 of the save error messages was localized).

PR #953 wired this line through: the Provider passes the type through (`ServiceError? error`, no longer `'$e'`), added a central mapper `localizeServiceError()` (`lib/components/localizations/service_error_localizations.dart`) + a shared empty-state widget `ServiceErrorView`, and the View always goes through them to localize. **For how to write it see the [implementation guide](error-handling-implementation-guide.md).**

### Things not yet done

- **contract test (TODO)**: use §2.1/§2.2 to pin down the Rust client-side string contract (the transport/auth/protocol mappings rely on substring/regex against Rust strings, and the moment the Rust-side string changes it silently fails). The passed-through 7xxx/9xxx are not in this contract; they are decided by firmware, and you need to request the vendor fault-code table from the firmware team separately.
- **§2.5 GET 9999→9998 bug (known, not yet fixed)**: see that section.

> **This doc is "background knowledge / full-chain reference" (answering "why").** The actual "how to implement error handling following the existing pattern" (the Service/Provider/View three-layer way of writing, what to display, things to note, checklist) is in the [implementation guide](error-handling-implementation-guide.md).
> The §2.5 GET 9999→9998 bug is still unfixed — this is a known limitation when implementing localization (a GET connection failure will be localized as "input error"), also noted in the implementation guide §7.

---

## File Index

**Dart**: `usp_client.dart`(facade), `web/usp_client_wasm.dart`(WASM boundary), `errors/usp_error.dart`(mapping), `errors/service_error.dart`(types), `models/usp_operation_result.dart`(envelope parsing), `providers/usp_mutation_lock.dart`, `bridge_request_throttler.dart`, `framework/preservable_notifier_mixin.dart`, `web/usp_init.js`+`usp_client.js`.
**Rust** (`usp-client/`): `src/wasm/mod.rs`(boundary+serializer), `src/client.rs`(orchestration), `src/error.rs`(**all error strings**), `src/protocol/{encode,decode}.rs`, `src/transport/http.rs`, `proto/usp.proto`, `doc/wasm-api-reference.md`(partial drift).
