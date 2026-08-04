# PnP Auto Master — CGI 認證鎖定死結修復設計

> 追蹤：[PrivacyGUI#1180](https://github.com/linksys/PrivacyGUI/issues/1180) ·
> [LinksysWRT#449](https://github.com/linksys/LinksysWRT/issues/449)
> 前置修復：#980 / #1006 / #1180（`85f39a74` — WAN-up 早期偵測）

---

## 1. 背景與問題

#1180 的「WAN-up 早期偵測」在真機（FW `v1.2.3.26072823_CF`）驗證**運作正確**：

- `pollAutoMasterUntilRunning` 正確接手（log：`Auto Master wait-for-running status: running`）
- `_probeUnauthorized` 的 `unauthorized → completed (recover)` 分類正確觸發

但驗證中浮現一層**更底層的死結**，位於 JNAP CGI 的 5 次認證失敗鎖定計數器（`jnap_auth_failed_attempts`）。

### 1.1 失敗時序（QA log 摘錄）

```
11:21:01  console  Auto Master「makes Master」→ 輪替 admin 密碼
11:21:02  console  admin password rotated
11:21:06  GUI      pollAutoMasterStatus 仍用 STALE admin:admin → 401（燒 attempt 1）
11:21:12  GUI      poll → 401（attempt 2）
11:21:17  GUI      poll → 401（attempt 3）
11:21:18  GUI      poll → 401（attempt 4）
11:21:20  GUI      poll → 401（attempt 5 — 額度用盡）
11:21:21  GUI      redirect to login
11:22:07  user     輸入「正確的新密碼」→ CheckAdminPassword2 回 invalid ×5（LED 恆亮白，無法登入）
```

### 1.2 根因

`pollAutoMasterStatus` / `pollAutoMasterUntilRunning` 走
`scheduledCommand(auth: true, retryDelayInMilliSec: 5000, ...)`。

1. 在 `router_repository.dart:259` 401（`JNAPError`）被吞進 yielded result。
2. `condition` 只認 `running/complete/idle/failed`，401 → 回 `false`
   → 每 5 秒**繼續用失效的 `admin:admin` 重打**。
3. `.map()` 又把 401 壓平成 `null`；消費端要**累積 3 個 null** 才會 `_probeUnauthorized`。

結果：**還沒等使用者輸入任何東西，poll 就燒光 5 次額度**。計數器只在「登入成功」時由 HDK
`AuthFn_Default` 自動清零（Vinh 確認），但鎖定後正確密碼也回 401 →「成功登入」永遠無法發生 →
**死結**。（Auto Master 走 `platform.setAdminPassword` 繞過 JNAP，亦不觸碰計數器。）

### 1.3 修復目標

在 poll 串流收到**第一個 401** 時就終止，而不是壓平成 null 繼續重打。
淨效果：make-Master 後 poll **最多只花 1 次 CGI 額度**（原本 4–5 次），把使用者的重登額度完整留住。

---

## 2. 修法

訊號分離其實**早已存在**：`checkAutoMasterStatus`（`pnp_provider.dart:751`）對 401 已丟
`ExceptionAutoMasterUnauthorized`，對不支援/逾時才 `return null`。只是兩個**串流**方法沒這麼做。
本修法讓串流也採用同一套語意。

### 2.1 核心改動 — `pnp_provider.dart`（兩個 poll 方法）

`pollAutoMasterStatus`（L765）與 `pollAutoMasterUntilRunning`（L809）的 `.map` 段：

```dart
.map((result) {
  // NEW: 把 401 當串流錯誤丟出，消費端 await-for 立即中斷（1 次額度）
  if (result is JNAPError && result.result == errorJNAPUnauthorized) {
    throw ExceptionAutoMasterUnauthorized();
  }
  if (result is JNAPSuccess) { /* 既有：running/complete/idle/failed → 回 status */ }
  return null; // 真正的連線失敗/不支援 仍走 null（不受影響）
});
```

> `errorJNAPUnauthorized` 與 `ExceptionAutoMasterUnauthorized` 在此檔已 import（L305 / L752），無需新增依賴。

**為什麼「throw」足以停止重打（不需改 `condition`）— 見 §5.1。** 這是本設計刻意避免 over-design 的關鍵決定。

### 2.2 消費端影響（共用改法 → 3 個消費端全數盤點）

| # | 消費端 | 是否需改 | 401 落點 | 說明 |
|---|--------|---------|---------|------|
| 1 | **ISP-save**（mixin，#449 主路徑）<br>`pnp_auto_master_flow.dart` + `pnp_isp_save_settings_view.dart` | **需改**（mixin 加 try/catch） | **`goNamed(pnp)`** | `_waitForRunning` / `_waitForCompletion` 的 `await for` 包 try/catch → 回 `AutoMasterFlowResult.completed`；view 端 `completed → goNamed(pnp)` **已存在**（L99）。符合「router 決定 pnp-vs-login」的既定原則。 |
| 2 | **pnp_setup_view** `pnp_setup_view.dart:763` | **必須加 try/catch** | `localLoginPassword` | 目前對串流 401 **無 handler** → 拋出會變 unhandled async error，卡在等待畫面（比現況更糟）。落點沿用它自己 L744 / L787 既有的 login 慣例。 |
| 3 | **pnp_admin_view** `pnp_admin_view.dart:556` | **零改動** | `localLoginPassword` | 三個 caller 皆已有 `.catchError(test: ExceptionAutoMasterUnauthorized) → goNamed(localLoginPassword)`（L115 / L366 / L638），拋出自然被接住。 |

**落點原則（回應決策）**：使用者選定「維持 `goNamed(pnp)` 讓 router 決定」——
此決策對應的正是 **#449 的 ISP-save 路徑**，該路徑透過 mixin 的 `completed` 結果**本來就**是
`goNamed(pnp)`。故落點無需改，只讓它「更早在第一個 401 觸發」。
setup / admin 兩條路徑維持既有的 `localLoginPassword`（**不**改成 pnp），以免對無關流程引入未審查的行為變動。

#### 2.2.1 落點不一致——**已知、刻意保留（選項 1）**

同一個「make-Master 401」事件，會依踩到哪條路徑落在**不同地方**，且**去向由不同機制決定**：

| 路徑 | `goNamed(...)` | router redirect 分支 | 實際決定去向者 | 結果 |
|------|---------------|---------------------|--------------|------|
| ISP-save（mixin，#449 主場景） | `pnp` | L129 `startsWith('/pnp')` → `_goPnpPath` | **router 判斷**（`_autoConfigurationLogic` 的 `userAcknowledgedAutoConfiguration`） | pnp-vs-login 由 router 決定 |
| setup / admin（正常 PnP） | `localLoginPassword` | L126 分支：`_autoConfigurationLogic(state)` 被呼叫但**未 `return`**（fire-and-forget，只有副作用），真正 `return` 的是 `_redirectLogic` | **強制停在 local login 密碼頁** | 直接到 login 頁 |

- 此不一致**非本次引入**：mixin 路徑（#1180）刻意「不硬編 redirect、交給 router」；setup/admin（#980）早已硬編去 login。本修法只讓兩條路徑**更早在第一個 401 觸發**。
- **factory-reset 場景殊途同歸**：`userAcknowledgedAutoConfiguration == false` 時，`goNamed(pnp)` 過 router 亦判定「留在 PnP」，而 PnP 首頁（admin view）若 session 已死會被既有防線再導向 login。**最終使用者都到 login 頁重輸新密碼**，差別僅「ISP 路徑多繞一跳 pnp」。
- **決策：維持選項 1**（ISP→pnp/router 判斷；setup/admin→login/強制）。理由：各自沿用該路徑既有且經測試的慣例，回歸面最小；factory-reset 下 UX 等價。未採「強制三者一致都走 pnp」（選項 2），因其會動到 setup/admin 既有硬編行為，超出死結修復範圍。

### 2.3 mixin try/catch 具體形狀

```dart
Future<AutoMasterFlowResult?> _waitForRunning(int threshold) async {
  int consecutiveNulls = 0;
  try {
    await for (final status in ref.read(pnpProvider.notifier).pollAutoMasterUntilRunning()) {
      // ...既有分支不變...
    }
  } on ExceptionAutoMasterUnauthorized {
    // 串流層偵測到 make-Master 輪替密碼 → 視為 Auto Master 已完成 → recover
    logger.i('[PnP]: wait-for-running unauthorized → completed (recover)');
    return AutoMasterFlowResult.completed;
  }
  // ...既有 timeout 收尾不變...
}
```

`_waitForCompletion` 同理包一層 `try / on ExceptionAutoMasterUnauthorized → return completed`。

### 2.4 「零程式改動」≠「零行為改動」——共用改法的真實副作用（重要）

`pnp_setup_view` 與 `pnp_admin_view` 雖為**加法/零程式改動**，但因採「共用改法」，其 poll 路徑在
**「遇到真 401」時的 runtime 行為確實改變**（此前只有 #449 的 PPPoE ISP 路徑會踩到 make-Master 401，
但正常 PnP 也可能在 config 期間遇 Auto Master 完成而 401）：

| | 改動前 | 改動後 |
|---|--------|--------|
| poll 遇真 401 | 壓平成 `null` → 累積 3 次 → **顯示「連線錯誤」畫面**（誤導：401 非連線問題） | 第一個 401 → throw → 被既有 catch 接住 → **導向 login** |

- 這是**嚴格改善**（401 本該去 login，不該顯示連線錯誤，也不該再燒額度）。
- 但它是**超出 #449 ISP 路徑的行為變動**——共用改法讓 setup / admin 的正常 PnP poll 路徑一併受惠。
- **此新 runtime 路徑目前無測試覆蓋** → §6 需為 setup / admin 各補一個「stream 拋 401 → login」回歸測試（非可選）。

> 傳播已驗證：admin_view 的 `await for`（L556）在 `async` 方法內、**無內層 try**，throw 沿
> `.then(...).catchError(test: ExceptionAutoMasterUnauthorized → login)` 傳到三個 caller
> （L115 / L366 / L638）**全部接得住**，故程式零改動成立；setup_view 的 `await for`（L763）
> **不在** L738 的 try 範圍內（該 try 於 L747 已閉合），故**必須**新增 try/catch（E7）。

---

## 3. 再次死結的安全性驗證（`goNamed(pnp)` 不會 re-burn）

追過 `_autoConfigurationLogic`（`router_provider.dart:158`）+ PnP 進入路徑，確認 make-Master 後
`goNamed(pnp)` **不會**再燒 CGI 額度：

| 步驟 | 呼叫 | auth? | 額度 |
|------|------|-------|------|
| 路由決策 | `fetchDeviceInfo` / `autoConfigurationCheck` | **unauthed** | 0 |
| 路由決策 | factory-reset 時 `userAcknowledgedAutoConfiguration == false` 在 L190 **短路** | — | 0（不呼叫 authed 的 `isRouterPasswordSet`） |
| 登出 | `logout()`（L214）**清掉** stale `pLocalPassword` | — | 0 |
| PnP entry | `checkRouterConfigured` → `getDeviceMode` | **unauthed** | 0 |
| PnP entry | 無密碼時 `checkAdminPassword(null)` **本地拋錯不打網路**（L294） | — | 0 |
| 使用者輸入 | 正確新密碼 → 額度第 **2** 次 → 成功 → HDK 自動清零 | auth | 1 |

**總計最多 2 次 < 5**，死結解除。
> 此安全性**完全依賴**「第一個 401 就終止」——正是 §2.1 的修法核心。若仍沿用舊的 4–5 次 poll，
> 光 poll 就逼近上限，`goNamed(pnp)` 落點無論如何都救不了。

---

## 4. Edge Cases 盤點

| # | 情境 | 修法後行為 | 判斷 |
|---|------|-----------|------|
| E1 | **真連線中斷**（非 401） | 仍走 `null` 路徑 → null-threshold → `_probeUnauthorized` → probe 也失敗 → `connectionError` | ✅ 不受影響，與 401 訊號完全分離 |
| E2 | **make-Master 極快，錯過 running 邊緣** | `condition` 仍認 `complete/failed` → 提早停 | ✅ 既有行為保留 |
| E3 | **401 發生在 `_waitForRunning`（Phase A）** | 串流 throw → try/catch → `completed`（QA 的 11:20–11:21 情境） | ✅ 正是主修復場景 |
| E4 | **401 發生在 `_waitForCompletion`（Phase B）** | 同 E3 | ✅ |
| E5 | **ISP-save 的 pre-save 檢查（`_checkAndWaitForAutoMaster` L65）** | 該處呼叫 `checkAutoMasterStatus()`（Future 版，**本來就** throw 401）→ L69 `goNamed(pnp)` | ✅ 已一致，無需改 |
| E6 | **admin_view 拋出後 `_isWaitingForAutoMaster` 未 reset** | view 隨即被導航替換，spinner state moot | ✅ 可接受（無殘留 spinner） |
| E7 | **setup_view 拋出但未加 try/catch** | unhandled async error → 卡等待畫面 | ⚠️ **必須修**（§2.2 #2），否則比現況更糟 |
| E8 | **401 以外的 auth 問題（罕見 glitch）** | PnP 期間 session 剛被 internet check 證明有效，唯一會中途輪替 admin 憑證的就是 make-Master → 歸類 recover 合理 | ✅ 與既有註解一致 |
| E9 | **`_probeUnauthorized` 的 unauthorized 分支是否變 dead code？** | 主 401 偵測移到串流層後，此分支僅在「session 死但 poll 回 null 非 401」的極罕見 timing 才觸發 | ⚠️ 見 §5.2 |
| E10 | **老韌體不支援 GetAutoMasterStatus** | 回 `null`（非 401）→ 走既有 null/timeout 收尾 | ✅ 不受影響 |
| E11 | **`condition` 回 true 造成 `exceedMaxRetry=false → onCompleted(false)`** | onCompleted 僅 log，無行為影響 | ✅（且見 §5.1，建議**不**改 condition） |

---

## 5. Over-Design 檢視（回應「是否過度設計」）

### 5.1 **建議：只改 `.map` throw，不改 `condition`** ← 避免 over-design

一個直覺是「同時在 `condition` 回 `true`（讓 `scheduledCommand` break）+ 在 `.map` throw」雙保險。
**但經 Dart async* 取消語意分析，`condition` 改動是多餘的**：

`scheduledCommand` 是 `async*`，在 `yield result` 處**因背壓而暫停**。當：
1. `.map` 回呼 throw → mapped stream 發出 error event；
2. 消費端 `await for` 收到 error → 迴圈體 rethrow → 退出迴圈 → **cancel subscription**；
3. cancel 往上游傳遞 → async* 在 `yield` 暫停點被終止（**不會**執行 yield 之後的 `if(condition) / await Future.delayed`）。

因此 generator 不會進入下一輪 delay+poll，**單靠 `.map` throw 就達成「1 次額度」**。
`condition` 回 true 只有在「消費端吞掉 error 又繼續 listen」時才有意義——現有 3 個消費端**皆無**此行為。

> **結論**：改 `condition` 屬 YAGNI 防禦，hotfix 上**不採用**。修法收斂為單一機制（`.map` throw），
> 語意清晰、blast radius 最小。（若未來有以 `.listen` 手動消費且不 cancel-on-error 的新消費端，再議。）

### 5.2 **既有 null-threshold + probe 機制：保留，不拆**

#1180 引入的「3 連 null → probe」機制，當初正是為了繞過「401 被壓平成 null」。
本修法讓 401 直接 throw 後，該機制的**角色縮小**為：僅處理**真正的連線失敗**（transient timeout / 老韌體 / 網路斷）
以決定 `connectionError` vs 繼續等待。`_probeUnauthorized` 的 `ExceptionAutoMasterUnauthorized`
分支（L189）雖大幅冷卻（E9），但仍是「session 由非 poll 路徑死亡」的 defense-in-depth，成本極低。

> **結論**：**保留**。在 hotfix 分支上拆除運作中的防禦機制風險 > 收益。標記為未來可簡化項，但不在本次範圍。

### 5.3 未採用的替代方案（記錄理由）

| 方案 | 為何不採用 |
|------|-----------|
| mixin 層把 null-threshold 降為 1、首個 null 就 probe | probe 本身是 authed call（再燒 1 次）；且對 transient null 過度反應；且**不涵蓋** setup/admin（未用 mixin）。串流層修法一次覆蓋 3 個消費端，且只花 1 次額度。 |
| 新增 `AutoMasterStatus.unauthorized` enum 值用 yield sentinel 取代 throw | 比 throw 更侵入（改 enum + 全 switch）；且無法自然被 admin_view 既有的 `.catchError` 接住。throw 復用既有 exception，friction 最低。 |
| poll 方法加 `terminateOnUnauthorized` 參數（限縮只 ISP 路徑） | 使用者已選「共用改法」；且 setup_view 現況對串流 401 無防護，本就是隱性 bug，一併修較一致。 |

---

## 6. 測試影響

**回歸基準（已對照全部現存測試確認）**：現存測試**無任何一個**注入「會 throw 的 stream」——
全部是 `Stream.value(status)` / `Stream.fromIterable([null,...])` / `Stream.empty()`。
本修法只在「stream **真的** throw 401」時改變行為，而該事件過去被壓平成 null，
**現存測試與現存正常流程皆不依賴它**（它產生的正是死結本身）。故現存測試**全數維持綠燈**。

| 測試檔 | 動作 | 結果 |
|--------|------|--------|
| `pnp_auto_master_flow_test.dart` | 現存 13 案例全綠（尤其 L177 的 `[null,null,null]+probe→completed`：stream 不 throw，新 catch 不觸發，結果不變）。**新增** Phase A / Phase B / Phase A-Running-then-B「stream throw 401 → `completed`」共 3 案例 | ✅ **+16 全綠**（純 logic，無 loc flag） |
| `pnp_setup_view_test.dart` | 現存 running / null×3 案例不變。**新增**「stream throw 401 → 導向 `localLoginPassword`」（§2.2 #2 try/catch 的唯一覆蓋，此前無測試） | ✅ **+36 全綠**（`--tags=loc`） |
| `pnp_admin_view_test.dart` | 現存 L297 的 `checkAutoMasterStatus` throw（Future 版）案例仍綠。**新增**「**stream**（`pollAutoMasterStatus`）throw 401 → 導向 login」（§2.4 的零程式改動、真行為改動路徑，此前無測試） | ✅ **+20 全綠**（`--tags=loc`） |
| `test/common/testable_router.dart` | **新增** `extraRoutes`（預設 `const []` → 對全部現存呼叫零影響）。見下方「測試 harness」 | ✅ 附加式，無回歸 |
| `test/mocks/pnp_notifier_mocks.dart` / spec mocks | 簽名不變，**無需重生** | — |

> 補測試手法：`when(mock.pollAutoMasterStatus()).thenAnswer((_) => Stream.error(ExceptionAutoMasterUnauthorized()))`。
>
> **測試 harness（實作時發現的必要調整）**：這批是 `--tags=loc` 的 **localization / screenshot** 測試（用 `--update-goldens` 跑；**非** golden 斷言測試），非純 golden。`testableSingleRoute` 原本只註冊 `/` 這一條 route，因此新測試觸發的 `context.goNamed(RouteNamed.localLoginPassword)` 會拋 `unknown route name`——
> - `setup_view`：直接把 exception 冒出來 → 測試紅燈；
> - `admin_view`：exception 被 `initState` 鏈末端的 `.onError` 吞掉，但 `_isWaitingForAutoMaster` 停在 `true`，spinner 永遠轉 → `pumpAndSettle` timeout。
>
> 兩者都**只是 harness 缺目的地 route**（正式環境兩條 route 都在，log 也證實 redirect 有觸發），非 production 邏輯 bug。修法：`testableSingleRoute` 加一個附加式 `extraRoutes` 參數（預設空 → 全部現存測試零影響），新測試各塞一個 `localLoginPassword` stub route（`Key('loginStub')`），再 `expect(find.byKey('loginStub'), findsOneWidget)` 斷言 401 確實落到 login。

---

## 7. 變更檔案清單

| 檔案 | 改動 |
|------|------|
| `lib/page/instant_setup/data/pnp_provider.dart` | 兩個 poll 方法 `.map` 段：401 → throw `ExceptionAutoMasterUnauthorized`（§2.1） |
| `lib/page/instant_setup/widgets/pnp_auto_master_flow.dart` | `_waitForRunning` / `_waitForCompletion` 各包一層 `try / on ExceptionAutoMasterUnauthorized → return completed`（§2.3） |
| `lib/page/instant_setup/pnp_setup_view.dart` | L763 `await for` 外層加 try/catch → `goNamed(localLoginPassword)`（§2.2 #2） |
| `lib/page/instant_setup/pnp_admin_view.dart` | **零程式改動**（既有 catchError 接住；行為改動見 §2.4） |
| `test/common/testable_router.dart` | 新增附加式 `extraRoutes` 參數（預設 `const []`），供測試註冊 redirect 目的地 route（見 §6） |
| 測試 3 檔 | 見 §6 |

> firmware 側維持不變（Jianrong / Vinh 已確認兩項皆 GUI-side）。
> 目標分支：`fix/pnp-pppoe-auto-master-wan-up-1180`（尚未合入 release 1.3.0.700533）。
