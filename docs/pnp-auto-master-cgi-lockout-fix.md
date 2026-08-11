# PnP Auto Master — CGI 認證鎖定死結修復設計

> 追蹤：[PrivacyGUI#1180](https://github.com/linksys/PrivacyGUI/issues/1180) ·
> [LinksysWRT#449](https://github.com/linksys/LinksysWRT/issues/449)
> 目標分支：`fix/pnp-pppoe-auto-master-wan-up-1180`（base `dev-1.3.1`）· PR [#1181](https://github.com/linksys/PrivacyGUI/pull/1181)

> **本文件已於 review 後改寫。** 初版的修法是「poll 收到第一個 401 就終止串流」
> （commit `371dbbf8`）。該機制在 `05d2529a` 被**移除並取代**為「Auto Master 狀態讀取一律
> 不送憑證（`auth: false`）」。本文件描述的是**現行**設計；被取代的設計及其理由記錄在 §8,
> 以免未來維護者從 git log 讀到 `371dbbf8` 時誤以為它還在。

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
3. `.map()` 又把 401 壓平成 `null`;消費端要**累積 3 個 null** 才會 probe。

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

### 2.4 Phase A 的 null probe 改判 `proceed`（review F1）

mixin 的 `_waitForRunning`（Phase A）累積 3 個 null 後會 `_probe()` 一次。
probe 回 `null`（狀態無法判定）時,舊碼一律映射成 `connectionError`。

在**不支援 no-auth 的韌體**上,每一次 poll 與 probe 都會落在 null,
於是 Phase A 必然回 `connectionError` → 使用者在「ISP 設定剛存成功、internet check 剛通過」
之後,看到「找不到路由器」。

Phase A 的前提是**session 剛被 internet check 證明活著**,所以「狀態讀不到」不該解讀為連線問題:

```dart
if (probe == AutoMasterFlowResult.connectionError) {
  logger.w('[PnP]: Auto Master wait-for-running undetermined, proceed');
  return AutoMasterFlowResult.proceed;
}
```

Phase B（`_waitForCompletion`）**維持** `connectionError`：它的前提不同 —— 已經觀察到
`running`,狀態突然讀不到確實可能是路由器不見了,且該路徑末端還有
`testConnectionReconnected()` 收尾。因此 `_probe()` 自身回傳「未判定」,由各 phase 決定意義。

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

### 3.2 落點不一致 —— 已知、刻意保留

Auto Master 完成後三條路徑落在不同地方,且**去向由不同機制決定**:

| 路徑 | `goNamed(...)` | redirect 分支 | 實際決定去向者 |
|------|---------------|--------------|--------------|
| ISP-save（mixin,#449 主場景） | `pnp` | L139 `startsWith('/pnp')` → `_goPnpPath` | **`_goPnpPath` 自己**:`deviceInfo != null` → 原路放行,直接落在 `PnpAdminView`,由該 view 自己的 precheck 鏈決定後續 |
| setup view | `localLoginPassword` | L127 → `_redirectLogic`（L138） | 停在 local login 密碼頁 |
| admin view | `localLoginPassword` | 同上 | 停在 local login 密碼頁 |

- 初版文件在此處寫 ISP-save 的 pnp-vs-login「由 router 依
  `userAcknowledgedAutoConfiguration` 判斷」—— **對這條路徑不成立**（同 §3.1,
  `_autoConfigurationLogic` 不會被呼叫)。實際是落進 `PnpAdminView`,由 view 自己判斷。
- 此不一致**非本次引入**：mixin 路徑（#1180）刻意不硬編 redirect;setup/admin（#980）
  早已硬編去 login。
- **維持現狀**。理由:各自沿用該路徑既有且經測試的慣例,回歸面最小;
  三條路徑最終都讓使用者回到「用新密碼登入」,差別僅中間多繞一跳。

> 註:`10b7881e` 已修掉 `localLoginPassword` 分支原本 fire-and-forget 呼叫
> `_autoConfigurationLogic` 造成的 pnp ↔ login 迴圈。該分支現在只走 `_redirectLogic`,
> 原因見 `router_provider.dart:128-137` 的註解。

---

## 4. Edge Cases 盤點

| # | 情境 | 修法後行為 | 判斷 |
|---|------|-----------|------|
| E1 | **韌體已開放 no-auth**（目標狀態) | 全程 unauthed 讀到真實狀態;`running` → 等待畫面 → `complete` → 依路徑導向 | ✅ 主要場景 |
| E2 | **韌體尚未開放 no-auth** | 每次 poll 與 probe 都回 401 → 全部壓平成 `null` → Auto Master 偵測**完全失效** | ⚠️ **見 §4.1** |
| E3 | **老韌體不支援 GetAutoMasterStatus** | 同 E2（`_ErrorUnknownAction` → `null`) | ⚠️ 同 §4.1 |
| E4 | **真連線中斷** | poll 回 `null` → null-threshold → probe 也 `null` → Phase A `proceed`、Phase B `connectionError` | ✅ Phase B 末端另有 `testConnectionReconnected()` 把關 |
| E5 | **make-Master 極快,錯過 running 邊緣** | `condition` 仍認 `complete/failed` → 提早停;Phase A 直接看到 `complete` → `completed` | ✅ 既有行為保留 |
| E6 | **make-Master 在等待期間輪替密碼** | poll 不帶憑證,**不受影響**;狀態照常走到 `Complete` | ✅ 這正是本修法要達成的 |
| E7 | **非字串 `autoMasterStatus` payload** | `fromValue(Object?)` → `null`,串流存活 | ✅ §2.6 |
| E8 | **view 在 make-Master 期間被 dispose** | mixin 每個 `await` 後都檢查 `mounted`;`_checkAutoMasterStatus` 每個 `setState` 都有 guard（`c4b7acc4`) | ✅ |
| E9 | **非 local 模式重用這三個方法** | `auth: false` 被靜默忽略,憑證照送,§1.3 的保證失效 | ⚠️ **見 §2.2**;目前無此呼叫端 |

### 4.1 韌體未開放 no-auth 時的降級行為（必須與 FW/QA 對齊）

E2 / E3 下,Auto Master 偵測**靜默失效**,PnP 退回它原本的**兩趟流程**:
使用者填 WiFi → 被 make-Master 踢出 → 重新進 PnP → 再填一次。

這一點必須事先講清楚,否則 QA 會把它讀成「偵測壞了」:

- 這是**已知且可接受**的降級（Jamie 已認可兩趟流程作為 fallback),不是回歸。
- 但**它與修法前的症狀長得一樣** —— 差別在於現在**不會**再燒 CGI 額度、不會鎖死登入。
  也就是說:**#1180 的死結解除了,#449 的「填兩次」在這種韌體上仍會出現。**
- 因此 §2.4 的 Phase A `proceed` 是必要的:沒有它,這種韌體上使用者會在 ISP 設定成功後
  看到「找不到路由器」,比兩趟流程更糟。

> **待確認項**：測試韌體 `FW_Pinnacle2.0_v1.2.4.26080716_PW` 是否包含 dennisnltran 的
> `GetAutoMasterStatus` no-auth 改動。若否,這一輪 QA 會落在 E2,量測到的行為即為上述降級。

---

## 5. 測試

### 5.1 `test/page/instant_setup/data/pnp_provider_auto_master_test.dart`（20 案例,全綠）

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

### 5.2 `test/page/instant_setup/widgets/pnp_auto_master_flow_test.dart`（14 案例,全綠）

以最小 `_FlowHost` 混入 mixin 直接驅動狀態機,不啟動任何 view。

| 案例 | 鎖住什麼 |
|------|---------|
| `Phase A: 3 nulls then probe null (undetermined) -> proceed` | **§2.4 的 F1 修正**;同時 `verifyNever(pollAutoMasterStatus())` 確認 Phase A 就地解決 |
| `Phase B: 3 nulls then probe null (undetermined) -> connectionError` | Phase B **不**跟著改,兩者前提不同 |
| `Phase A Running, then rotation mid-completion -> completed` | 取代舊的 3 個「stream 拋 401」案例:輪替現在是**普通路徑**（狀態走到 `Complete`),不再是 exception |

**刪除**的案例及理由:舊有 3 個 `Stream.error(ExceptionAutoMasterUnauthorized())` 案例
與 1 個 `probe unauthorized -> completed` 案例,其前提（poll 會因輪替而 error）
在 `auth: false` 之後**不可能發生**,該 exception 型別亦已刪除。

### 5.3 View 層 loc 測試

`pnp_admin_view_test.dart` / `pnp_setup_view_test.dart` 中的兩個「狀態 `null`」案例
從「阻擋」反轉為「不阻擋」,並各加 `verifyNever(pollAutoMasterStatus())`
釘住「`null` 不等於 `running`」:

- admin view：`Tap Login with Auto Master status unavailable enters config` —— 進入 config,不卡住。
- setup view：`Auto Master status unavailable before save continues to save` —— 繼續存檔,不去 login。

同樣刪除 3 個 `unauthorized → login` 的 golden 案例（前提已不存在）。
`test/**/goldens/*` 在 `.gitignore:89`,無 orphan golden 需清理。

### 5.4 測試結果

| 範圍 | 結果 |
|------|------|
| `pnp_provider_auto_master_test.dart` | **20/20** |
| `pnp_auto_master_flow_test.dart` | **14/14** |
| `test/page/instant_setup/ --exclude-tags loc` | **47/47** |
| 全專案 `--exclude-tags loc` | **560 passed**（baseline 557,新增 3) |
| `fvm flutter analyze` | 淨新增 **0** 個 issue（stash 前後對照皆 60） |
| `test/page/instant_setup/ --tags loc --update-goldens` | **6107 passed / 3 failed — 未查清** |

> **`--tags loc` 的 3 個失敗未查清。** compact reporter 以 `\r` 覆蓋同一行,輸出檔僅存
> 1153 bytes,失敗案例名與斷言訊息均已遺失。已排除 `pnp_waiting_modem_view_test.dart`
> （單獨跑全綠）。尚未逐檔確認的候選為本分支動過的 3 個 loc 檔:
> `pnp_admin_view_test.dart`、`pnp_setup_view_test.dart`、
> `troubleshooter/localizations/pnp_auto_master_waiting_view_test.dart`。
>
> 判讀準則（供後續查證）：`testLocalizations` 每案例跑遍 device × locale 矩陣,
> 因此**邏輯壞掉會讓同一案例的整組 variant（20+）一起失敗**。只有 3 個更像是少數 variant
> 的 timing 抖動 —— 這類測試同時存在兩個時鐘（mock future 走 `runAsync` 的真 microtask、
> 內部 1 秒動畫走 fake timer),特定尺寸/語系下容易差一個 pump。此推論**尚未驗證**。

---

## 6. 變更檔案清單

| 檔案 | 改動 |
|------|------|
| `lib/page/instant_setup/data/pnp_provider.dart` | 三處 `auth: true` → `false`;兩處 `.map` 的 401→throw 刪除;`checkAutoMasterStatus` 的 401 分支併入通用 catch;4 處解析改用 `fromValue`（§2.1 / §2.3 / §2.6） |
| `lib/core/jnap/models/auto_master_status.dart` | `fromValue` 參數 `String?` → `Object?`（§2.6） |
| `lib/page/instant_setup/widgets/pnp_auto_master_flow.dart` | 移除兩處 `on ExceptionAutoMasterUnauthorized`;`_probeUnauthorized` → `_probe`（去掉 unauthorized 分支);Phase A 的 undetermined → `proceed`（§2.4） |
| `lib/page/instant_setup/pnp_admin_view.dart` | 移除 4 處 `.catchError(test: e is ExceptionAutoMasterUnauthorized)`（§2.3） |
| `lib/page/instant_setup/pnp_setup_view.dart` | 移除 pre-check 與 `await for` 外層的 `on ExceptionAutoMasterUnauthorized`（§2.3） |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_save_settings_view.dart` | `_checkAndWaitForAutoMaster` 增加 `status == null` 顯式早退（§2.5） |
| `lib/page/instant_setup/data/pnp_exception.dart` | 刪除 `ExceptionAutoMasterUnauthorized`（§2.3） |
| 測試 4 檔 | 見 §5 |

> 韌體側:`GetAutoMasterStatus` 需開放 no-auth（dennisnltran)。**這是本修法的前置依賴**,
> 未包含時的降級行為見 §4.1。

---

## 7. 尚未處理（刻意延後）

以下為 review 中提出、經確認**不在本次範圍**的項目:

| 項目 | 為何延後 |
|------|---------|
| `pollAutoMasterStatus` / `pollAutoMasterUntilRunning` 高度重複 | 兩者僅 `condition` 與 `maxRetry` 不同,可合併。屬重構,不在 hotfix 範圍 |
| `fromValue(result.output['autoMasterStatus'])` 在 4 處重複 | 同上 |
| mixin 放在 `widgets/` 目錄 | 它不是 widget。搬移會動到 import 面,延後 |
| `_autoMasterPostWanUp` 這個暫態欄位 | 可用參數傳遞取代。延後 |
| `PnpIspSaveSettingsView` 無測試覆蓋 | 該 view 的 Auto Master 分支目前只靠 mixin 的單元測試間接覆蓋 |
| `_isAuthFailure` / `_isRouterTemporarilyUnreachable` 缺單元測試 | 純 predicate,可加 `@visibleForTesting` 直接測。另開 issue |
| `behind` / `others` 分支不尊重 `needAuth` | 見 §2.2:共用路徑,blast radius 遠大於 #1180 |
| `docs/` 與 `doc/` 兩個目錄並存 | 與本議題無關 |

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
| null-threshold 降為 1,首個 null 就 probe | probe 當時是 authed call（再燒 1 次);且對 transient null 過度反應 |
| 新增 `AutoMasterStatus.unauthorized` enum 值,用 yield sentinel 取代 throw | 比 throw 更侵入（改 enum + 全 switch);且無法被 admin_view 既有的 `.catchError` 接住 |
| poll 加 `terminateOnUnauthorized` 參數（只限 ISP 路徑) | 已選共用改法;setup_view 當時對串流 401 無防護,本就是隱性 bug |

> 三者在現行設計下均已無意義:probe 現在是 unauthed;已無 unauthorized 訊號需要表達。
