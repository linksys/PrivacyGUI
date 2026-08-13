# PnP Auto Master — CGI 認證鎖定死結修復設計

> 追蹤：[PrivacyGUI#1180](https://github.com/linksys/PrivacyGUI/issues/1180) ·
> [LinksysWRT#449](https://github.com/linksys/LinksysWRT/issues/449)
> 目標分支：`fix/pnp-pppoe-auto-master-wan-up-1180`（base `dev-1.3.1`）· PR [#1181](https://github.com/linksys/PrivacyGUI/pull/1181)

> **本文件已改寫四次,描述的都是現行設計。**
> ① 初版修法為「poll 收到第一個 401 就終止串流」（commit `371dbbf8`）,在 `05d2529a` 被
> **移除並取代**為「Auto Master 狀態讀取一律不送憑證（`auth: false`）」;被取代的設計
> 及其理由記錄在 §8,以免未來維護者從 git log 讀到 `371dbbf8` 時誤以為它還在。
> ② QA 實機 log 顯示還有第二個放棄得太早的機制:「連續 N 個 null 就判定路由器不見了」。
> 該門檻與其 probe 已**整組移除**,改為有界時間預算 + 單一連線裁判,見 **§2.4**
> （該節原本記錄的 F1 修法建立在門檻之上,已隨之作廢）。
> ③ 同一份 QA log 還顯示 reconnect 後被導到 `localLoginPassword`。該落點屬於
> **已完成**的 PnP(`userAcknowledgedAutoConfiguration == true`),用在未完成的流程上是錯的;
> 三處硬編已改為一律回 PnP,見 **§2.7**（§3.2 原本把此不一致判為「刻意保留」,該判斷已作廢）。
> ④ 第二份 QA log(`PnP-Check-Auto-Master2.txt`)同時**證實 ②③ 在真機上生效**,並暴露下一層:
> gate 讀到 `complete` 卻直接放過（§2.7 寫的「`case completed` 也會接到它」是**錯的前提**）,
> 舊憑證因此被帶進 internet check,其 401 又被讀成「沒網路」而跳 troubleshooter。
> 見 **§2.8**。

---

## 1. 背景與問題

### 1.1 原始症狀（#1180 / #449）

Factory-reset 裝置走 ISP-settings troubleshooter（PPPoE / Static / DHCP）完成首次設定時,
WAN 是在使用者送出 ISP 帳密**之後**才起來。WAN-up 觸發韌體 Auto Master（"make Master"）,
約 1 分鐘後它會**更換 admin 密碼**並重啟服務,使 GUI 的已登入 session 失效,把使用者踢回 PnP。
由於此時使用者已經前進到 WiFi 設定頁,他必須**把 WiFi 填第二次**。

`85f39a74` 把 Auto Master 偵測**提前到 WAN-up 這一點**,讓使用者在既有的等待畫面上等一次,
而不是填一份會被丟掉的 WiFi 表單。

### 1.2 真機驗證中浮現的第二層問題：CGI 認證鎖定

`85f39a74` 在真機（FW `v1.2.3.26072823_CF`）驗證運作正確,但驗證中浮現一層**更底層的死結**,
位於 JNAP CGI 的 5 次認證失敗鎖定計數器（`jnap_auth_failed_attempts`）。

```
11:21:01  console  Auto Master「makes Master」→ 輪替 admin 密碼
11:21:02  console  admin password rotated
11:21:06  GUI      pollAutoMasterStatus 仍用 STALE admin:admin → 401（燒 attempt 1）
11:21:12  GUI      poll → 401（attempt 2）
11:21:17  GUI      poll → 401（attempt 3）
11:21:18  GUI      poll → 401（attempt 4）
11:21:20  GUI      poll → 401（attempt 5 — 額度用盡）
11:21:21  GUI      redirect to login
11:22:07  user     輸入「正確的新密碼」→ CheckAdminPassword2 回 invalid ×5（LED 恆亮白,無法登入）
```

**根因**：`pollAutoMasterStatus` / `pollAutoMasterUntilRunning` 當時走
`scheduledCommand(auth: true, retryDelayInMilliSec: 5000, ...)`。

1. 在 `router_repository.dart` 的 `scheduledCommand` 內,401（`JNAPError`）被 catch 起來
   當成 yielded result（不是 exception）。
2. `condition` 只認 `running/complete/idle/failed`,401 → 回 `false`
   → 每 5 秒**繼續用失效的 `admin:admin` 重打**。
3. `.map()` 又把 401 壓平成 `null`;消費端當時要**累積 3 個 null** 才會 probe
   （該門檻機制後來因另一個原因整組移除,見 §2.4）。

結果:**還沒等使用者輸入任何東西,poll 就燒光 5 次額度**。計數器只在「登入成功」時由 HDK
`AuthFn_Default` 自動清零（Vinh 確認),但鎖定後正確密碼也回 401 →「成功登入」永遠無法發生 →
**死結**。（Auto Master 走 `platform.setAdminPassword` 繞過 JNAP,亦不觸碰計數器。）

### 1.3 修復目標

**讓 Auto Master 狀態查詢完全不參與認證。** 它是一個純狀態讀取,不需要憑證;
一旦不送憑證,它就**不可能**產生認證失敗,也就**不可能**燒 CGI 額度 —— 無論重打幾次。

這比「第一個 401 就終止」更強:後者是把傷害限制在 1 次,前者是把傷害降到 0 次。

---

## 2. 修法

### 2.1 核心改動 — 三處 Auto Master 讀取改為 `auth: false`

`pnp_provider.dart` 的三個方法:

| 方法 | 送法 |
|------|------|
| `checkAutoMasterStatus()` | `send(getAutoMasterStatus, auth: false, ...)` |
| `pollAutoMasterStatus()` | `scheduledCommand(auth: false, maxRetry: 60, ...)` |
| `pollAutoMasterUntilRunning()` | `scheduledCommand(auth: false, maxRetry: 18, ...)` |

前置條件：韌體必須把 `GetAutoMasterStatus` 開放為 no-auth（dennisnltran 的韌體側改動）。
**這是本修法的硬依賴** —— 見 §4 對「韌體尚未包含該改動」的降級行為分析。

### 2.2 `auth: false` 真的會拿掉 header 嗎？—— 只在 local 模式成立（重要）

`_buildCommandHeader`（`router_repository.dart:325`）三個分支中,**只有一個**尊重 `needAuth`：

| `newRouterType` | header 建法 | 尊重 `needAuth`? |
|---|---|---|
| `behindManaged`（L380-395） | `authKey: (needAuth \| isCloudLogin()) ? authValue : ''`（L393),之後 `removeWhere(value.isEmpty)`（L397） | ✅ **會**拿掉 |
| `behind`（L359-379） | `authKey: authValue`（L375）—— 無條件 | ❌ 不看 `needAuth` |
| `others`（L347-358） | cloud token（L352-357）—— 無條件 | ❌ 不看 `needAuth` |

而 `newRouterType` 的決定（L337-345）在 `kIsWeb` 時先過 `checkForce()`。GUI 出貨build
以 `--dart-define=force=local`（`build_web.sh:7` / `.vscode/launch.json:20`）建置,
`checkForce()` → `CommandType.local` → `newRouterType = behindManaged`
→ **落在唯一尊重 `needAuth` 的那個分支**。

> **結論**：在 GUI 實際出貨的 local 模式下,`auth: false` 確實不送
> `X-JNAP-Authorization`,§1.3 的推論成立。
>
> **但這個保證僅限 local 模式。** 若未來有非 local（`behind` / `others`）路徑要重用這三個方法,
> `auth: false` 會被靜默忽略、憑證照送,§1.3 的「不可能燒額度」即不再成立。
> 要讓保證與模式無關,得讓 `behind` / `others` 兩個分支也尊重 `needAuth` —— 那是所有 JNAP
> 命令的共用路徑,blast radius 遠大於 #1180,**刻意不在此 hotfix 分支做**。

### 2.3 401 的語意隨之改變：不再是「密碼被輪替」的訊號

既然請求**不帶憑證**,一個 unauthorized 回應就**不可能**表示「make-Master 輪替了 admin 密碼」。
它只表示一件事:**這台韌體還沒把 `GetAutoMasterStatus` 開放為 no-auth**。

而「韌體要求認證」與「韌體不支援這個 action」對 GUI 而言**無法區分,且降級方式相同**
（都是拿不到狀態）。因此 401 被歸類到與其他失敗相同的處理:

```dart
// checkAutoMasterStatus
} catch (e) {
  // 401 is deliberately in here with the rest. The request carries no
  // credential (auth: false), so an unauthorized result cannot mean
  // make-Master rotated the admin password — it means this firmware still
  // serves GetAutoMasterStatus as auth-required. ...
  return null;
}
```

兩個串流方法的 `.map` 同理:非 `JNAPSuccess`（含 401）→ `null`,串流繼續。
**不需要早期終止器**,因為沒有憑證可燒。

隨之刪除：`ExceptionAutoMasterUnauthorized`（`pnp_exception.dart`)、mixin 兩處
`on ExceptionAutoMasterUnauthorized` 包裝、`pnp_setup_view` 一處 try/catch、
`pnp_admin_view` 四處 `.catchError(test: e is ExceptionAutoMasterUnauthorized)`。

### 2.4 放棄「數 null」,改用**有界時間預算**（QA log 實測後改寫）

> 本節取代初版的「Phase A null probe 改判 `proceed`（review F1）」。
> 該修法建立在「累積 N 個 null 就 probe 一次」的門檻機制上,而**門檻機制本身已被移除**,
> 因此 F1 的修法連同 `_probe()` 一併刪除。理由如下。

#### 症狀

QA 在 PPPoE 設定完成後看到:internet connected → **Router Not Found** → 重連路由器後
被丟回 login 畫面。前半段（偵測 `running`、進等待畫面）都對,錯在**提早放棄**。

#### 根因：把雜訊當訊號

舊碼在 `_waitForRunning` / `_waitForCompletion` 都用
`consecutiveNullThreshold`（3 個 null）作為「路由器可能不見了」的判準。但 make-Master
**會把路由器的 HTTP 服務整段拿掉**,而這正是 null 的來源。從 QA log 對時間軸:

| 時間點 | 事件 |
|-------|------|
| T+0s | make-Master 開始,HTTP 服務中斷 |
| ~T+50s | 連續 3 個 null 達標 → 舊碼判定 router not found |
| ~T+65s | 路由器 HTTP 服務**才真正回來** |
| ~T+115s | Auto Master 全程結束 |

也就是說,舊碼在服務恢復前約 **15 秒**就宣告失敗。中斷期間路由器可能 timeout、
拒連、或回一個無法解析的東西 —— 全部壓平成 `null`。**數 null 等於數雜訊**,
而且愈是正常的 make-Master,null 愈多。

#### 修法：讓「串流自己的長度」成為唯一的放棄條件

null 一律**繼續等**。放棄與否改由 poll 的**總時長**決定,而總時長靠三個參數釘死
（`pnp_provider.dart`）:

```dart
maxRetry: 24,                  // 24 輪
requestTimeoutOverride: 3000,  // 每次請求最多 3s（local web,3s 已相當寬鬆）
retryDelayInMilliSec: 5000,    // 每輪間隔 5s
```

24 × (3s + 5s) = **192s**,對照上表的 ~65s 中斷與 ~115s 全程,餘裕充足。
關鍵是**上界可預測**：沒有 request timeout 時,單一次慢回應就能讓整段等待失控。

串流耗盡而仍無終局狀態時,才問唯一能被可靠回答的問題 —— **路由器在不在**：

```dart
logger.w('[PnP]: Auto Master polling budget spent, verifying connection');
try {
  await ref.read(pnpProvider.notifier).testConnectionReconnected();
  return AutoMasterFlowResult.budgetExhausted;  // 活著,但 Auto Master 結果未知
} catch (_) {
  return AutoMasterFlowResult.connectionError;  // 真的不見了
}
```

`testConnectionReconnected` 因此成為「router not found」的**唯一裁判**,並強化為
`retries: 2, timeoutMs: 5000` —— 它不該押在單一個封包上,還在重啟收尾的路由器
常常是第二、三次才回應。

#### 新增 `budgetExhausted`：用 IoC 換掉三份重複實作

「時間到了但路由器活著」與「Auto Master 明確沒動作」是**不同的事實**,舊碼把兩者都
壓成 `proceed`,所以每個呼叫端只能自己寫一份 poll loop 來拿到足夠資訊。
`AutoMasterFlowResult` 因此增加第四個值,讓 mixin 只負責**陳述發生了什麼**,
由呼叫端決定意義:

| 呼叫端 | 對 `budgetExhausted` 的處置 | 為什麼 |
|-------|---------------------------|-------|
| `pnp_admin_view` | 當 `proceed` 繼續 | 手上沒有待辦;後續 internet check / `pnpConfig` 都會重讀即時狀態,密碼真被輪替就走既有錯誤路徑 |
| ISP-save pre-save | 照樣存檔 | 已等滿整個預算;若存檔時密碼被輪替,會以 `JNAPError` 落到既有錯誤處理 |
| ISP-save post-WAN-up | 進 PnP,交給 entry precheck | 設定已存好,沒有待辦 |
| `pnp_setup_view` | **從頭重查一次**（上限 2 次） | **唯一有客製流程者**:手上有一個待存的 save,一旦密碼被輪替就會 401 |

`pnp_setup_view` 的計數器語意也隨之改變 —— 一次「等待」現在要價約 192s,
所以必須**在花掉時就記帳**（先加再比),而非事後才檢查:
`_maxAutoMasterSaveAttempts` → `_maxAutoMasterWaits`。

三份 bespoke poll loop（admin_view ~85 行、setup_view ~75 行、mixin 自己一份）
因此收斂為一份實作。

### 2.5 ISP-save pre-save 檢查的 null 早退

`_checkAndWaitForAutoMaster`（`pnp_isp_save_settings_view.dart:65`）原本只判斷
`running` / `complete`。狀態為 `null` 時會落到函式尾端的 `return true`,行為正確但**理由不明**。
補上顯式早退,讓「讀不到狀態 → 沒有東西可等 → 繼續存檔」寫在程式裡而非靠 fall-through:

```dart
if (status == null) {
  logger.d('[PnP]: Troubleshooter - Auto Master status unavailable, continue save');
  return true;
}
```

### 2.6 `autoMasterStatus` 解析不再用 unchecked cast（review W2 / F3）

`AutoMasterStatus.fromValue` 的參數由 `String?` 放寬為 `Object?`：

```dart
static AutoMasterStatus? fromValue(Object? value) {
  return switch (value) {
    'Idle' => AutoMasterStatus.idle,
    'Running' => AutoMasterStatus.running,
    'Complete' => AutoMasterStatus.complete,
    'Failed' => AutoMasterStatus.failed,
    _ => null,
  };
}
```

原本共 5 個呼叫點做 unchecked cast:`pnp_provider.dart` 的 4 處
（2 個 `condition` lambda + 2 個 `.map` body）寫 `result.output['autoMasterStatus'] as String?`,
以及 `GetAutoMasterStatusResponse.fromMap` 的 `map['autoMasterStatus'] as String?`。
兩者的 map 都是解碼後的 JSON,若韌體回了非字串,該 cast 會拋 `TypeError`。

**關鍵在於它會落在哪裡**：`scheduledCommand` 的 try/catch 只接 `JNAPError` 與
`TimeoutException`,而這個 cast 位於**它下游的 `.map` 回呼**內 —— `TypeError` 因此會
**逸出 mapped stream**,消費端 `await for` 未接住 → 等待畫面的 spinner 永遠轉。

放寬型別而非在 5 個點各加一道 guard：一次改動消除全部呼叫點的風險,且非字串值自然
miss 掉所有 case、回 `null` —— 正是呼叫端已經在處理的「狀態無法取得」。

### 2.7 Auto Master 完成後的落點:一律回 PnP,不再去 `localLoginPassword`（QA log 實測後新增）

#### 症狀

QA log(18:29–18:30)在 ISP 重連後出現:

```
18:30:45  [PnP]: Start PNP setup without admin password
18:30:57  [PnP]: Interrupted and go to: localLoginPassword
```

reconnect 後**應該回到 PnP 輸入新密碼**,實際卻被丟到 local login 密碼頁。

#### 根因:把「PnP 沒跑完」當成「PnP 跑完了」

`localLoginPassword` 是 **`userAcknowledgedAutoConfiguration == true`** —— 也就是
**PnP 確實走完**才會到的畫面。Auto Master 完成確實會改密碼、確實需要重新登入,
但在 PnP **還沒走完**的情況下,使用者必須回到 **PnP admin**、用 **PnP 自己的**登入輸入密碼。
硬編去 local login 等於宣告「這輪 setup 已完成」,把使用者留在一個他還沒走完的流程之外。

這個硬編是 #980 時期的慣例,在 §2.4 的 mixin 重構中被原封不動沿用 —— 諷刺的是
`pnp_auto_master_flow.dart` 的檔頭註解**當時就寫對了**設計意圖
（「pnp-vs-login 的決定留給 router 的 `userAcknowledgedAutoConfiguration`,不在此硬編 redirect」),
是呼叫端做了它警告的事。

> **⚠️ 本段原有一個錯誤前提,已於 §2.8 更正。**
> 原文寫「`case completed` 這條分支**也會被剛進入的 view 打到**」—— **這是錯的**。
> `runAutoMasterFlow` 只在狀態為 `running` 時才會被呼叫,所以「進來就看到 `complete`」
> 永遠到不了 `case completed`。第二份 QA log 證實了這點:gate 讀到 `complete`、
> 直接 `return`,`_promptForRotatedPassword` 一次都沒被呼叫。修法見 **§2.8**。

#### 修法

| 位置 | 原本 | 現在 |
|------|------|------|
| `pnp_admin_view.dart` `case completed` | `throw ExceptionInterruptAndExit(route: localLoginPassword)` | `throw ExceptionAutoMasterRotatedPassword()` → `_promptForRotatedPassword()` |
| `pnp_setup_view.dart` `case completed` | `goNamed(localLoginPassword)` | `goNamed(RouteNamed.pnp)` |
| `pnp_setup_view.dart` idle-on-entry → `complete` 邊緣 | `goNamed(localLoginPassword)` | `goNamed(RouteNamed.pnp)` |

新增 `ExceptionAutoMasterRotatedPassword`(`pnp_exception.dart`),
**刻意不是** 帶 route 的 `ExceptionInterruptAndExit` —— 去向不該由拋出點決定。
`pnp_admin_view` 的 4 條 `.catchError` 鏈(initState / `_unconfiguredView` / `_doLogin` /
`_retryAutoMasterCheck`)各加一個分支接它。

`_promptForRotatedPassword()` **不導航**:這裡就是 PnP 的入口 view,提示只差一次 `setState`。
真正關鍵的是**清掉 `_password`** —— 它存的是我們帶進來的憑證（route 參數 `p`,或原廠預設值）,
而輪替剛剛讓它失效。不清掉,下一輪 precheck 會拿它再試一次,白燒一次 CGI 額度
（§3 額度表那唯一的 1 次就是這條;留著會變 2 次）。同時 `pnp.setAttachedPassword(null)`,
避免 provider 端的殘留值繞過這道清除。

`goNamed(RouteNamed.pnp)` 這個落點不是新發明的:`pnp_setup_view.dart` 的
「存檔時 401」handler **本來就**這樣做。這次是把另外三條路徑收斂到同一個既有落點。

#### 順帶查清:log 中重複的 `Auto Master polling status`

同一則 log 出現兩次,**不是**遞迴或重複訂閱:舊版 `pnp_admin_view` 的 bespoke poll loop
在自己的 `await for` 裡也印一次,與 `pnp_provider.dart:814` 的 `.map` 各印一次 ——
一個事件兩個 log 敘述。該 loop 已在 §2.4 隨 mixin 重構刪除,**現行程式碼已無此重複**。

### 2.8 進來就是 `complete` 的落點 + 401 不再等於「沒網路」（第二份 QA log 實測後新增）

#### 這份 log 先證實了兩件事是對的

`PnP-Check-Auto-Master2.txt`(2026-08-13 11:41–11:46)在同一份記錄裡驗證了 §2.4 與 §2.7:

| 證據 | 對應修法 |
|------|----------|
| `11:45:09`→`11:46:06` **連續 8 次** `TimeoutException after 0-00-03-000000`(≈57s),之後恢復並續輪到 `complete` | §2.4 有界預算。舊的 3-null 門檻會在這段誤判 router-not-found;`3s` 也確認 `requestTimeoutOverride` 生效 |
| `11:46:18.829` `polling status: complete` → `11:46:18.832` `[RouteChanged]:<pnp>` | §2.7 落點。**不再**是 `localLoginPassword` |

#### 症狀

```
11:46:22.471  [PnP]: Auto Master status check result: AutoMasterStatus.complete
11:46:22.471  [PnP]: Check internet connections MAX retries <1>, i=0
11:46:22.514  REQUEST GetInternetConnectionStatus ... X-JNAP-Authorization: Basic ************
11:46:23.007  RESPONSE: 200, {"result": "_ErrorUnauthorized",
               "error": "Invalid authorization credentials 'Basic YWRtaW46YWRtaW4='"}
11:46:26.009  [PnP Troubleshooter]: Internet connection failed - initiate the troubleshooter
11:46:26.012  [RouteChanged]:<noInternetConnection>
```

回到 PnP 之後,**仍用舊憑證**(`admin:admin`,make-Master 輪替前的原廠預設)去打 internet check,
401 被讀成「沒網路」,於是使用者在 ISP 設定**成功之後**被丟進 troubleshooter。

#### 三個獨立根因

**① gate 漏接 `complete`。** `_checkAutoMasterStatus()` 原本是:

```dart
if (status != AutoMasterStatus.running) return;   // complete 從這裡直接 return
```

`complete` 被認出來、印進 log,然後當成「沒事」放過去。§2.7 的 `case completed` 接不到它 ——
`runAutoMasterFlow` 只在 `running` 時才被呼叫。log 中 `_promptForRotatedPassword` 的
訊息出現 **0 次**,實證了這條路徑從未被走到。

那行 `Check internet connections` 夾在兩行 Auto Master log 中間只是 logger 的 `[D]`/`[I]`
緩衝順序（`[D]` 時戳 `470`、`[I]` 是 `471`）,不是兩條並行的 chain。

**② 401 被壓成「沒網路」。** `checkInternetConnection` 原本 `onError` 吞掉一切 →
`isConnected = false` → `throw ExceptionNoInternetConnection()`。這是同一個主題第三次出現:
**憑證輪替後被重用,它的 401 被誤讀**。

**③ auth header 不看 pnp state。** header 由 `router_repository.dart:373` 從 auth session 的
`getLocalPassword()` 組出,`loginType == none` 時 fallback 到 `defaultAdminPassword`。
`_promptForRotatedPassword()` 清的 `_password` / `setAttachedPassword(null)` **都不影響它**。
更關鍵的是殘留的 `LoginType.local` 讓 `isLoggedIn()` 回 true,於是 initState 的
`_examineAdminPassword` 被**整段跳過** —— log 中 `11:46` 期間確實沒有任何 `CheckAdminPassword`。

#### 修法

| # | 位置 | 修法 |
|---|------|------|
| ① | `pnp_admin_view.dart` `_checkAutoMasterStatus` | 在 `!= running` 早退**之前**加 `if (status == complete) throw ExceptionAutoMasterRotatedPassword();`。既有的 4 條 `.catchError` 鏈已能接住 |
| ② | `pnp_provider.dart` `checkInternetConnection` | 改用 `try/catch`:401 → `ExceptionInvalidAdminPassword` 並**立即中止**（不重試,見下）;其餘錯誤照舊進重試迴圈 |
| ② | `pnp_admin_view.dart` `_checkInternetConnection` | 新增一條 `ExceptionInvalidAdminPassword` 分支:清 spinner 後 rethrow,交給呼叫端的密碼提示,**不去 troubleshooter** |
| ② | `pnp_isp_save_settings_view.dart` / `pnp_waiting_modem_view.dart` | 同一個例外會逃出這兩處（原本只 catch `ExceptionNoInternetConnection`）。兩處都改為 `goNamed(pnp)` —— 這兩個呼叫是 `checkInternetConnection(30)`(≈90s 視窗),Auto Master 從 WAN-up 起算約 115s,輪替落在視窗內是**成功**而非設定失敗 |
| ② | `pnp_admin_view.dart` `_retryAutoMasterCheck` | 該鏈**只有**這條沒有 catch-all,新例外會逃逸成 unhandled error。其 `ExceptionAutoMasterRotatedPassword` 分支的 `test` 改為同時接 `ExceptionInvalidAdminPassword` —— 兩者落點相同 |
| ③ | `pnp_admin_view.dart` `_promptForRotatedPassword` | 加 `ref.read(authProvider.notifier).logout()` |

**為何另外三條鏈不比照併入:** initState / `_unconfiguredView` / `_doLogin` 都先呼叫
`_examineAdminPassword`,而它在**密碼真的錯**時也拋 `ExceptionInvalidAdminPassword`。
把兩者併在同一個 `test` 裡,會讓真正的密碼錯誤跳過「顯示密碼錯誤」而靜靜地重置輸入框。
這三條鏈的 catch-all 已經是正確處置。`_retryAutoMasterCheck` 不呼叫
`_examineAdminPassword`,所以那裡併入是安全的。

**為何 401 不重試:** 密碼不會因為再送一次就變正確,而每一輪都燒掉路由器 5 次 CGI 額度中的一次
—— 正是 §2.3 在別處修掉的那個鎖定。第一個 401 必須是終局。

**為何 `logout()` 從這裡呼叫是安全的（已查證）:** `/pnp*` 走 `router_provider.dart` 的
`_goPnpPath`,該分支**不 watch `authProvider`**,且 `deviceInfo != null` 時回傳原 URI（原地不動）;
`logout()` 也不清 `pnpProvider`,所以 `deviceInfo` 還在。這正是 §2.7 header 註解裡
「`localLoginPassword` 分支刻意不重跑 `_autoConfigurationLogic`」所防的那個 redirect 迴圈 ——
這裡不觸發它。

**`logout()` 並不會讓 header 消失。** `loginType == none` 時 header fallback 到
`defaultAdminPassword` = `'admin'`,恰好就是 log 中那個失效憑證。所以 ③ 的價值不是
「停止送舊 header」,而是讓 `isLoggedIn()` 回 false,使下一輪 precheck **真的會驗密碼**。
真正的安全網是 ②:任何路徑帶著死憑證走到 authed 呼叫,401 都會被正確歸類。

---

## 3. 死結解除的驗證（額度收支）

修法後 Auto Master 相關請求**完全不參與認證**,因此:

| 步驟 | 呼叫 | auth? | 額度 |
|------|------|-------|------|
| Auto Master 偵測（全程,任意次數） | `getAutoMasterStatus` | **unauthed** | **0** |
| 路由決策 | `fetchDeviceInfo` / `autoConfigurationCheck` | unauthed | 0 |
| PnP entry | `checkRouterConfigured` → `getDeviceMode` | unauthed | 0 |
| PnP entry | `PnpAdminView._examineAdminPassword` 用 stale `pLocalPassword` 重試一次 | auth | **1**（見下） |
| 使用者輸入 | 正確新密碼 → 成功 → HDK 自動清零 | auth | 1 |

**總計最多 2 次 < 5**,死結解除。

### 3.1 `logout()` 不會執行,stale 密碼不會被清（review F2 修正）

初版文件在此處寫了一條**錯誤的因果鏈**:聲稱 ISP-save 完成後 `goNamed(pnp)` 會經
`_autoConfigurationLogic`,並在其中 `logout()` 清掉 stale `pLocalPassword`。**該路徑不會執行。**

`router_provider.dart:124-143` 的 redirect 分派是（行號為 L125 / L127 / L139）:

```dart
if (state.matchedLocation == '/') {
  return router._autoConfigurationLogic(state);
} else if (state.matchedLocation == RoutePath.localLoginPassword) {
  return router._redirectLogic(state);
} else if (state.matchedLocation.startsWith('/pnp')) {
  return router._goPnpPath(state);      // ← ISP-save 的 goNamed(pnp) 走這裡
}
```

`_goPnpPath`（L330-337）在 `pnpProvider.deviceInfo != null` 時**直接** `return state.uri.toString()`,
完全繞過 `_autoConfigurationLogic`。而 `pnpProvider` 是非 autoDispose 的 `NotifierProvider`,
ISP-save 導航時 `deviceInfo` 早已填好 —— **被走的就是這個繞過分支**。

兩個後果:

- §3 表中 `fetchDeviceInfo` / `autoConfigurationCheck` 那兩列**根本不會跑**。
  額度上這比初版文件寫的**更好**（是 0 次呼叫,不是「呼叫但 unauthed 所以 0」）。
- 但 `logout()` **也不會跑** → stale `pLocalPassword` **不會被清除**
  → `PnpAdminView._examineAdminPassword` 會用它試一次,燒掉 1 次額度。
  這就是 §3 表中那一列的來源。實際總計約 **2**,仍 < 5,死結結論不變,只是餘裕比初版所述少一格。

### 3.2 落點已收斂 —— 全部回 PnP

Auto Master 完成後,**四條路徑落在同一個地方**（§2.7）:

| 路徑 | `goNamed(...)` | redirect 分支 | 實際決定去向者 |
|------|---------------|--------------|--------------|
| ISP-save（mixin,#449 主場景） | `pnp` | L139 `startsWith('/pnp')` → `_goPnpPath` | **`_goPnpPath` 自己**:`deviceInfo != null` → 原路放行,直接落在 `PnpAdminView`,由該 view 自己的 precheck 鏈決定後續 |
| setup view（`completed` / idle-on-entry 邊緣） | `pnp` | 同上 | 同上 |
| setup view（存檔時 401） | `pnp` | 同上 | 同上（此路徑**本來就**如此,是收斂的目標） |
| admin view | **不導航** | — | 就地 `setState` 回到 PnP 自己的密碼提示（§2.7） |

- 前一版此節記載 setup / admin 兩條路徑硬編去 `localLoginPassword`,並判斷為
  「已知、刻意保留」的不一致 —— **該判斷是錯的,已於 §2.7 修掉**。
  那個落點屬於 `userAcknowledgedAutoConfiguration == true`(PnP 已完成)的情境,
  用在未完成的 PnP 上會把使用者留在流程之外,正是 QA 回報的症狀。
- 「pnp-vs-login 由 router 依 `userAcknowledgedAutoConfiguration` 判斷」這句話,
  現在對四條路徑**都成立**:呼叫端一律回 PnP,不自行判讀 ack 旗標。
  （注意這與 §3.1 不衝突:`_goPnpPath` 繞過 `_autoConfigurationLogic` 而原路放行,
  最終仍是落進 `PnpAdminView` 由它的 precheck 鏈決定,而非呼叫端硬編。)
- `grep localLoginPassword lib/page/instant_setup/` 現在**只剩註解**,無任何硬編 redirect。

> 註:`10b7881e` 已修掉 `localLoginPassword` 分支原本 fire-and-forget 呼叫
> `_autoConfigurationLogic` 造成的 pnp ↔ login 迴圈。該分支現在只走 `_redirectLogic`,
> 原因見 `router_provider.dart:128-137` 的註解。本次修法讓 PnP 不再進入該分支。

---

## 4. Edge Cases 盤點

| # | 情境 | 修法後行為 | 判斷 |
|---|------|-----------|------|
| E1 | **韌體已開放 no-auth**（目標狀態) | 全程 unauthed 讀到真實狀態;`running` → 等待畫面 → `complete` → 回 PnP 要新密碼（§2.7) | ✅ 主要場景 |
| E2 | **韌體尚未開放 no-auth** | 每次 poll 都回 401 → 全部壓平成 `null` → 等滿預算 → 連線測試通過 → `budgetExhausted` → 各呼叫端繼續（見 §2.4 表）→ Auto Master 偵測**完全失效但不擋路** | ⚠️ **見 §4.1** |
| E3 | **老韌體不支援 GetAutoMasterStatus** | 同 E2（`_ErrorUnknownAction` → `null`) | ⚠️ 同 §4.1 |
| E4 | **真連線中斷** | poll 全程 `null` → 等滿 192s 預算 → `testConnectionReconnected` 失敗 → `connectionError` | ✅ 唯一裁判是連線測試,不是 null 的個數（§2.4） |
| E4b | **make-Master 期間的正常中斷** | 同樣全程 `null`,但預算耗盡時服務已恢復 → 連線測試通過 → `budgetExhausted` | ✅ **這正是 #1180 的回歸點**:舊碼在此判 `connectionError` |
| E4c | **路由器卡在 `running` 不動** | 等滿預算 → 活著 → `budgetExhausted`;`setup_view` 最多重查 2 次後顯示錯誤畫面 | ✅ 有界,不會無限迴圈 |
| E5 | **make-Master 極快,錯過 running 邊緣** | `condition` 仍認 `complete/failed` → 提早停;Phase A 直接看到 `complete` → `completed` | ✅ 既有行為保留 |
| E6 | **make-Master 在等待期間輪替密碼** | poll 不帶憑證,**不受影響**;狀態照常走到 `Complete` | ✅ 這正是本修法要達成的 |
| E7 | **非字串 `autoMasterStatus` payload** | `fromValue(Object?)` → `null`,串流存活 | ✅ §2.6 |
| E8 | **view 在 make-Master 期間被 dispose** | mixin 每個 `await` 後都檢查 `mounted`;`_checkAutoMasterStatus` 每個 `setState` 都有 guard（`c4b7acc4`) | ✅ |
| E9 | **非 local 模式重用這三個方法** | `auth: false` 被靜默忽略,憑證照送,§1.3 的保證失效 | ⚠️ **見 §2.2**;目前無此呼叫端 |
| E10 | **reconnect 後剛進 view,Auto Master 已是 `complete`** | **gate 自己**拋 `ExceptionAutoMasterRotatedPassword` → 回 PnP 密碼提示,`_password` 清空 + `logout()`;poll 完全不啟動 | ✅ §2.8 ①。本列原寫「走 `case completed`」是**錯的**:該分支只在 `running → complete` 時走到,第二份 QA log 證實 gate 讀到 `complete` 後直接放過 |
| E11 | **使用者輸入舊密碼的瞬間 Auto Master 完成** | `_doLogin` 的 gate 攔下 → 剛打的密碼已作廢 → 同樣回密碼提示,不落進 WiFi 表單 | ✅ 否則會落到 catch-all 顯示假的「密碼錯誤」 |
| E12 | **authed 呼叫拿到 401,但 WAN 其實正常** | `checkInternetConnection` 區分兩者:401 → `ExceptionInvalidAdminPassword`(**不重試**,不燒 CGI 額度);非 401 → 照舊重試,耗盡才判 `ExceptionNoInternetConnection` | ✅ §2.8 ②。舊碼把兩者壓平成「沒網路」,在 ISP 設定**成功後**把使用者丟進 troubleshooter |
| E13 | **輪替發生在 troubleshooter 的 90s 檢查視窗內** | ISP-save / waiting-modem 兩處接住 `ExceptionInvalidAdminPassword` → `goNamed(pnp)`,而非 pop ISP 錯誤 / 跳無網路頁 | ✅ §2.8 ②。Auto Master 從 WAN-up 起算 ≈115s,`checkInternetConnection(30)` ≈90s,重疊是常態 |
| E14 | **輪替後殘留的 `LoginType.local` 讓 `isLoggedIn()` 回 true** | `_promptForRotatedPassword` 內 `logout()`,下一輪 precheck 會真的驗密碼 | ✅ §2.8 ③。log 中 `11:46` 全程**沒有** `CheckAdminPassword`,驗證被整段跳過 |

### 4.1 韌體未開放 no-auth 時的降級行為（必須與 FW/QA 對齊）

E2 / E3 下,Auto Master 偵測**靜默失效**,PnP 退回它原本的**兩趟流程**:
使用者填 WiFi → 被 make-Master 踢出 → 重新進 PnP → 再填一次。

這一點必須事先講清楚,否則 QA 會把它讀成「偵測壞了」:

- 這是**已知且可接受**的降級（Jamie 已認可兩趟流程作為 fallback),不是回歸。
- 但**它與修法前的症狀長得一樣** —— 差別在於現在**不會**再燒 CGI 額度、不會鎖死登入。
  也就是說:**#1180 的死結解除了,#449 的「填兩次」在這種韌體上仍會出現。**
- 因此 §2.4 的「null 不作為判準」是必要的:沒有它,這種韌體上每一次 poll 都是 null,
  使用者會在 ISP 設定成功後看到「找不到路由器」,比兩趟流程更糟。
  現在這種韌體只會安靜地等滿預算、連線測試通過、以 `budgetExhausted` 放行 ——
  代價是多等一段時間,而非一個假的錯誤畫面。

> **待確認項**：測試韌體 `FW_Pinnacle2.0_v1.2.4.26080716_PW` 是否包含 dennisnltran 的
> `GetAutoMasterStatus` no-auth 改動。若否,這一輪 QA 會落在 E2,量測到的行為即為上述降級。

---

## 5. 測試

### 5.1 `test/page/instant_setup/data/pnp_provider_auto_master_test.dart`（28 案例,全綠）

以 `ProviderContainer` + `MockRouterRepository` 驅動**真的** `PnpNotifier`,
是唯一直接驗證「JNAP result → status」映射的地方。

新增/改動的關鍵案例:

| 案例 | 鎖住什麼 |
|------|---------|
| `sends the request unauthed` / `polls unauthed` ×2 | 用 `captureAnyNamed('auth')` 斷言**實際送出**的值是 `false` —— 這是 §1.3 全部推論的基礎 |
| `401 maps to null` / `401 flattens to null and the stream keeps going` | 401 不再是特例;串流不終止 |
| `a Running before a 401 keeps both in the stream` | 401 不會吃掉先前已 yield 的狀態 |
| `non-String status payload maps to null instead of throwing` | §2.6,payload 餵 `42` |
| `non-String status payload flattens to null, stream survives` | §2.6 的**真正後果**:`[42, 'Complete']` → `[null, complete]`,串流沒有被 TypeError 打斷 |
| `bounds its own duration: 24 rounds of 3s request + 5s delay` | **§2.4 的三個數字**。門檻機制拿掉之後,這串流的長度**就是**放棄條件,任一參數被改小就會重現 #1180 |
| `bounds its own duration, shorter than the wait-for-completion poll` | `pollAutoMasterUntilRunning` 的 `maxRetry: 18` + 同樣的 3s/5s 上限 |
| `retries before condemning the connection` | `testConnectionReconnected` 送 `retries: 2, timeoutMs: 5000` —— 它是 router-not-found 的唯一裁判,不能押在單一封包上 |
| `checkInternetConnection unauthorized -> ExceptionInvalidAdminPassword, not NoInternet` | **§2.8 ② 的核心**:401 與「WAN 真的斷了」不再同義 |
| `checkInternetConnection unauthorized does not retry` | 401 是終局。斷言只送了 **1** 次(`retries` 傳 30) —— 每輪重試都燒一次 CGI 額度,正是 §2.3 修掉的鎖定 |
| `checkInternetConnection a transient failure still retries` | 只有 401 終局:timeout 照舊重試（第 3 次成功) |
| `checkInternetConnection InternetConnected -> completes` / `a non-connected status -> ExceptionNoInternetConnection` | 原有語意未被新分支破壞 |

> 這三個參數斷言改用**讀取 mock 收到的 `Invocation` 具名引數**（`lastScheduled` / `lastSend`
> 搭配 `sendArg` / `scheduledArg`),而非 `captureAnyNamed`。原因:`captured` 的順序跟著
> **呼叫端實際的具名引數順序**跑,對這種「數字本身就是設計」的斷言太隱晦 ——
> 參數順序一改,斷言會靜靜地比錯對象。

### 5.2 `test/page/instant_setup/widgets/pnp_auto_master_flow_test.dart`（14 案例,全綠）

以最小 `_FlowHost` 混入 mixin 直接驅動狀態機,不啟動任何 view。

| 案例 | 鎖住什麼 |
|------|---------|
| `nulls during the make-Master outage`（3 案例) | **§2.4 的核心**:①nulls 後 `Complete` → `completed`;②nulls 到底 + 路由器活著 → `budgetExhausted`（**#1180 的回歸鎖**);③nulls 到底 + 路由器不見 → `connectionError` |
| `Budget spent with router alive -> budgetExhausted` / `Budget spent with reconnect failure -> connectionError` | 預算耗盡後的分岔,唯一裁判是連線測試 |
| `Phase A: nulls only then stream closes (budget spent) -> proceed` | Phase A 就地解決,`verifyNever(pollAutoMasterStatus())` + `verifyNever(checkAutoMasterStatus())` |
| `Phase A Running, then rotation mid-completion -> completed` | 取代舊的 3 個「stream 拋 401」案例:輪替現在是**普通路徑**（狀態走到 `Complete`),不再是 exception |

**刪除**的案例及理由:

- 舊有 3 個 `Stream.error(ExceptionAutoMasterUnauthorized())` 案例與 1 個
  `probe unauthorized -> completed`:前提（poll 會因輪替而 error）在 `auth: false`
  之後**不可能發生**,該 exception 型別亦已刪除。
- 4 個 null-threshold / probe 案例（`3 nulls then probe Complete -> completed`、
  `Phase B: 3 nulls then probe null -> connectionError`、
  `Phase A: 3 nulls then probe null -> proceed`、
  `probe Running resets counter, then Complete -> completed`）：
  門檻與 `_probe()` 皆已移除（§2.4),前提消失。

### 5.3 View 層 loc 測試

`pnp_admin_view_test.dart` / `pnp_setup_view_test.dart` 中的兩個「狀態 `null`」案例
從「阻擋」反轉為「不阻擋」,並各加 `verifyNever(pollAutoMasterStatus())`
釘住「`null` 不等於 `running`」:

- admin view：`Tap Login with Auto Master status unavailable enters config` —— 進入 config,不卡住。
- setup view：`Auto Master status unavailable before save continues to save` —— 繼續存檔,不去 login。

同樣刪除 3 個 `unauthorized → login` 的 golden 案例（前提已不存在）。
`test/**/goldens/*` 在 `.gitignore:89`,無 orphan golden 需清理。

§2.4 之後另有三處調整:

- 兩個 `Auto Master connection error` 案例改 stub `testConnectionReconnected` 拋
  `ExceptionNeedToReconnect`。3 個 null 不再能產生那個畫面 —— 連線測試失敗才行。
- `Auto Master poll complete before save redirects to pnp` 的收尾從 `pumpAndSettle()`
  改為 `runAsync(Future.delayed(100ms))` + 兩次 `pump()`。這類測試同時存在**兩個時鐘**:
  mock 的 future/stream 在**真** microtask 上解析,動畫與 delay 在 fake timer 上;
  串流訂閱的取消只在真事件迴圈的 turn 上完成,`pumpAndSettle` 推不動它。
- 三個 retry 分支案例改以預算機制與 `_maxAutoMasterWaits` 命名
  （`Auto Master budget spent then reconnect re-checks and saves` 等)。

**修掉一個既有的 golden 檔名衝突。** `pnp_admin_view_test.dart` 與
`pnp_setup_view_test.dart` 都叫 `Instant Setup - PnP: Auto Master connection error` ——
而 golden 路徑**只由描述字串決定**,兩者共用 `localizations/goldens/`。
兩個同名案例會互相覆蓋截圖,後跑的那個必定比對失敗(130 個 variant 全滅,
差異僅頁面底色 `#FFFFFF` vs `#F9F9F9`)。setup 的那個依同檔慣例改名為
`... connection error before save`。此衝突由本分支自己引入（兩案例都是本分支新增的)。

§2.7 之後的落點測試改動（4 個案例、2 個 helper）:

| 案例 | 改為鎖住什麼 |
|------|------------|
| admin view `Tap Login with Auto Master complete asks for the new password`（原 `... redirects to login`) | **不導航**:`PnpAdminView` + `AppPasswordField` 仍在、`PnpAutoMasterWaitingView` 已離開、沒進 `pnpConfigStub`,且 `verify(setAttachedPassword(null))` 釘住輪替憑證被丟棄 |
| setup view `Auto Master poll complete before save redirects to pnp`（原 `... to login`) | 落在 `pnpStub` |
| setup view `Auto Master idle on entry but complete during config redirects to pnp`（原 `... to login`) | 同上 |
| setup view `Auto Master status unavailable before save continues to save` | `findsNothing` 的對象由 `loginStub` 改為 `pnpStub` |

兩檔的 `_loginStubRoute()` helper 一併處理:admin 檔**整個刪除**(已無任何路徑導向 login),
setup 檔改名為 `_pnpStubRoute()`,並吸收原本「存檔時 401」案例裡**行內重複**的同一份 stub。

admin view 那個案例特意保留 `expect(find.byKey(Key('pnpConfigStub')), findsNothing)` 之外
**不再註冊 login stub** —— 若未來有人把 redirect 加回去,harness 會直接拋
"unknown route name" 而不是安靜地通過。

§2.8 之後新增 2 個 admin view 案例:

| 案例 | 鎖住什麼 |
|------|---------|
| `Auto Master already complete on entry asks for the new password` | **§2.8 ① 的回歸鎖**。與既有的 `Tap Login with Auto Master complete ...` 是**不同分支**:那個先看到 `running` 再輪到 `complete`,這個進來就是 `complete` —— 故 `verifyNever(pollAutoMasterStatus())`,並且 `verifyNever(checkInternetConnection())` 釘住「不再帶著死憑證去打 internet check」 |
| `Unauthorized internet check does not go to the troubleshooter` | **§2.8 ② 的 view 層安全網**。`checkInternetConnection` 拋 `ExceptionInvalidAdminPassword` 時停在 PnP;此案例**刻意不註冊** troubleshooter 路由,導過去就會拋 "unknown route name" |

### 5.4 測試結果

| 範圍 | 結果 |
|------|------|
| `pnp_provider_auto_master_test.dart` | **28/28**（原 23 + §2.8 新增 5) |
| `pnp_auto_master_flow_test.dart` | **14/14** |
| `test/page/instant_setup/ --exclude-tags loc` | **52/52**（原 50 + §2.8 新增 2) |
| 全專案 `--exclude-tags loc` | **570 passed / 0 failed**（baseline 557;以 `--reporter json` 逐案清點:635 個 testDone、0 失敗) |
| `flutter analyze lib/ test/` | **564**,對 §2.7 的 563 淨增 **1**:`pnp_waiting_modem_view.dart:132` 新增的 `goNamed` 帶一個 `use_build_context_synchronously` info。已加 `if (mounted)` 保護,但 `context` 是跨 `Future.delayed().then()` 從外層 closure 捕獲,分析器追不到（同檔既有的 119 / 123 兩行是同一情形)|
| loc 兩檔 `--tags loc --update-goldens` | **3247 passed / 3 failed（既有,已查清 — 見下）** |

> **前一版記錄的「3 個失敗未查清」已查清,與本修法無關。**
> 用 `--reporter json` 取代 compact reporter（後者以 `\r` 覆蓋同一行,失敗案例名會遺失)
> 後可定位到:`Instant Setup - PnP: Wifi ready (split SSID)` 在 da / de 三個 variant 失敗,
> 原因是 `pnp_setup_view.dart:538` 的 `Row`(Print / Download QR 兩顆按鈕)
> `RenderFlex overflowed by 16 pixels` —— 長字語系在窄版面下擠不下。
> 該 `Row` 不在本分支的 diff 內（本分支只動 27 / 67 / 730+ 行),屬既有版面問題,**未處理**。
>
> 另外釘住一項判讀準則:此 loc suite **沒有 baseline** ——
> `test/**/goldens/*` 在 `.gitignore`,repo 內不存在任何 golden 圖檔,
> 這套測試實際用途是**產生截圖**。因此在乾淨 checkout 上首跑必定全綠(檔案不存在即寫入),
> 而本機殘留的舊截圖會讓比對失敗看起來像回歸。判斷有無回歸要看**例外內容**
> （layout / assertion）而非 pixel diff 百分比。

---

## 6. 變更檔案清單

| 檔案 | 改動 |
|------|------|
| `lib/page/instant_setup/data/pnp_provider.dart` | 三處 `auth: true` → `false`;兩處 `.map` 的 401→throw 刪除;`checkAutoMasterStatus` 的 401 分支併入通用 catch;4 處解析改用 `fromValue`（§2.1 / §2.3 / §2.6）;兩個 poll 加上有界預算參數、`testConnectionReconnected` 改 `retries: 2, timeoutMs: 5000`（§2.4）;`checkInternetConnection` 改 `try/catch`,401 → `ExceptionInvalidAdminPassword` 且不重試（§2.8 ②) |
| `lib/core/jnap/models/auto_master_status.dart` | `fromValue` 參數 `String?` → `Object?`（§2.6） |
| `lib/page/instant_setup/widgets/pnp_auto_master_flow.dart` | 移除兩處 `on ExceptionAutoMasterUnauthorized`;**刪除 `consecutiveNullThreshold` 與 `_probe()`**;新增 `AutoMasterFlowResult.budgetExhausted`（§2.4) |
| `lib/page/instant_setup/pnp_admin_view.dart` | 移除 4 處 `.catchError(test: e is ExceptionAutoMasterUnauthorized)`（§2.3);**改用 mixin**,~85 行 bespoke poll loop 刪除（§2.4);`case completed` 改拋 `ExceptionAutoMasterRotatedPassword`,新增 `_promptForRotatedPassword()`,4 條 `.catchError` 鏈各加一個分支（§2.7);gate 加 `complete` 分支、`_promptForRotatedPassword` 加 `logout()`、`_checkInternetConnection` 加 `ExceptionInvalidAdminPassword` 分支（§2.8) |
| `lib/page/instant_setup/pnp_setup_view.dart` | 移除 pre-check 與 `await for` 外層的 `on ExceptionAutoMasterUnauthorized`（§2.3);**改用 mixin**,~75 行 bespoke poll loop 刪除;計數器改為 `_maxAutoMasterWaits`(先加再比)（§2.4);兩處 `localLoginPassword` → `RouteNamed.pnp`（§2.7) |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_save_settings_view.dart` | `_checkAndWaitForAutoMaster` 增加 `status == null` 顯式早退（§2.5);兩處呼叫點處理 `budgetExhausted`（§2.4);接住 `ExceptionInvalidAdminPassword` → `goNamed(pnp)`（§2.8 ②) |
| `lib/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart` | 接住 `ExceptionInvalidAdminPassword` → `goNamed(pnp)`（§2.8 ②) |
| `lib/page/instant_setup/data/pnp_exception.dart` | 刪除 `ExceptionAutoMasterUnauthorized`（§2.3);新增 `ExceptionAutoMasterRotatedPassword`（§2.7） |
| 測試 4 檔 | 見 §5 |

> 韌體側:`GetAutoMasterStatus` 需開放 no-auth（dennisnltran)。**這是本修法的前置依賴**,
> 未包含時的降級行為見 §4.1。

---

## 7. 尚未處理（刻意延後）

以下為 review 中提出、經確認**不在本次範圍**的項目:

| 項目 | 為何延後 |
|------|---------|
| `pollAutoMasterStatus` / `pollAutoMasterUntilRunning` 高度重複 | 兩者僅 `condition` 與 `maxRetry` 不同,可合併。屬重構,不在 hotfix 範圍 |
| `pnp_setup_view.dart:538` 的 `Row` 在 da / de 窄版面 overflow 16px | 既有版面問題,與 Auto Master 無關（見 §5.4） |
| 三個 view 的呼叫端各自的 `budgetExhausted` 處置 | §2.4 表中四種處置**刻意不同**,是 IoC 的目的而非重複。不需再收斂 |
| `fromValue(result.output['autoMasterStatus'])` 在 4 處重複 | 同上 |
| mixin 放在 `widgets/` 目錄 | 它不是 widget。搬移會動到 import 面,延後 |
| `_autoMasterPostWanUp` 這個暫態欄位 | 可用參數傳遞取代。延後 |
| `PnpIspSaveSettingsView` 無測試覆蓋 | 該 view 的 Auto Master 分支目前只靠 mixin 的單元測試間接覆蓋 |
| `_isAuthFailure` / `_isRouterTemporarilyUnreachable` 缺單元測試 | 純 predicate,可加 `@visibleForTesting` 直接測。另開 issue |
| `behind` / `others` 分支不尊重 `needAuth` | 見 §2.2:共用路徑,blast radius 遠大於 #1180 |
| `docs/` 與 `doc/` 兩個目錄並存 | 與本議題無關 |
| **PnP 之外**的 authed 呼叫在 make-Master 視窗內帶著 stale 憑證 | §2.8 只處理了 PnP 流程內的 `checkInternetConnection`(②)與 session 殘留(③)。核心 polling 已由 `polling_provider.dart` 的「只有憑證被拒才登出」擋住最糟的後果,但**其他** authed 呼叫仍可能在該視窗吃到 401。要普遍解決需在 `router_repository` 層區辨,blast radius 遠大於 #1180 |

---

## 8. 被取代的設計：「第一個 401 就終止」（commit `371dbbf8`）

保留此節,是因為 `371dbbf8` 仍在 git 歷史中,且它的分析（尤其 §8.2）曾被獨立驗證為正確 ——
未來若 `auth: false` 這條路走不通（例如韌體無法開放 no-auth),它是現成的 fallback。

### 8.1 原設計

poll 的 `.map` 在遇到 401 時 throw `ExceptionAutoMasterUnauthorized`,
消費端 `await for` 立即中斷,把 make-Master 後的額度消耗從 4–5 次壓到 **1 次**。
三個消費端各自把該 exception 對應到「Auto Master 已完成 → 導向重登」。

### 8.2 為何單靠 `.map` throw 就足以停止重打（不需改 `condition`）

`scheduledCommand` 是 `async*`,在 `yield result` 處因背壓而暫停。當:

1. `.map` 回呼 throw → mapped stream 發出 error event;
2. 消費端 `await for` 收到 error → 迴圈體 rethrow → 退出迴圈 → **cancel subscription**;
3. cancel 往上游傳遞 → async\* 在 `yield` 暫停點被終止（**不會**執行 yield 之後的
   `if(condition)` 與 `await Future.delayed`)。

因此 generator 不會進入下一輪 delay+poll。此分析在 review 中被以獨立的最小重現程式驗證:

```
.map throws on 401       → 2 polls total  (stops at the first 401)
.map flattens to null    → 5 polls total  (old behaviour, budget exhausted)
```

當時的決定是**不加** `condition` 的「雙保險」（YAGNI),該決定在 review 中被確認正確。

### 8.3 為何被取代

`c4b7acc4` 的 QA 再驗證（FW `v1.2.3.26080322_CF`）顯示:make-Master 輪替憑證的時間點
比 Auto Master 回報 `complete` **早約 75 秒**。於是「第一個 401 就終止」會在這 75 秒的空窗中
把使用者丟進 `pnpConfig` —— 他填完 WiFi,pre-save 檢查才輪到 `complete`,再把他踢第二次。
**原始的「填兩次」症狀在死結修好之後依然存在。**

根本原因是:401 被當成「Auto Master 完成」的**代理訊號**,而它其實只代表「憑證變了」,
兩者相差 75 秒。`auth: false` 的做法從源頭移除這個代理:不送憑證 → 沒有 401 →
只讀真正的狀態,等到它真的變成 `Complete` 才動作。

副帶好處:額度消耗由 1 次進一步降到 0 次;`ExceptionAutoMasterUnauthorized` 這個
穿過三個消費端的例外路徑整條消失。

### 8.4 當時記錄、現已不適用的替代方案

| 方案 | 當時不採用的理由 |
|------|-----------|
| null-threshold 降為 1,首個 null 就 probe | probe 當時是 authed call（再燒 1 次);且對 transient null 過度反應 —— 後者正是 §2.4 最終把整個門檻機制移除的原因,只是當時低估了它的嚴重性 |
| 新增 `AutoMasterStatus.unauthorized` enum 值,用 yield sentinel 取代 throw | 比 throw 更侵入（改 enum + 全 switch);且無法被 admin_view 既有的 `.catchError` 接住 |
| poll 加 `terminateOnUnauthorized` 參數（只限 ISP 路徑) | 已選共用改法;setup_view 當時對串流 401 無防護,本就是隱性 bug |

> 三者在現行設計下均已無意義:`_probe()` 與 null-threshold 已整組移除（§2.4);
> 已無 unauthorized 訊號需要表達。
