### **開發者指引：如何使用 Dirty State 導航守衛框架**

#### **1. 這是什麼？為什麼要用它？**

本框架旨在解決一個常見問題：當使用者在頁面上修改了某些設定但尚未儲存時，意外的導航操作（例如點擊返回按鈕）會導致所有變更遺失。

此框架提供了一個標準化的解決方案，它會：
*   自動偵測頁面狀態是否「dirty」（已修改但未儲存）。
*   在使用者試圖離開 dirty 頁面時，自動彈出對話框提示。
*   提供標準化的 `fetch` 和 `save` 樣板，簡化資料的讀取與儲存流程。

**一句話：任何需要讓使用者修改並儲存設定的頁面，都應該使用此框架。**

#### **2. 如何使用：五步驟指南**

將此框架應用到一個新功能 (Feature) 非常簡單，只需遵循以下五個步驟：

**第一步：定義資料模型 (`Settings` & `Status`)**
*   為你的功能建立兩個 `Equatable` 類別。
*   `Settings` 類別：存放所有**使用者可以修改**的欄位。
*   `Status` 類別：存放所有**唯讀**的系統狀態或從後端讀取後不會被使用者直接修改的資料。
*   為這兩個類別實作 `toMap` 和 `fromMap` 方法以便序列化。

**第二步：定義功能的 `State`**
*   建立一個繼承自 `FeatureState<YourSettings, YourStatus>` 的 `State` 類別。
*   實作必要的 `copyWith` 和 `toMap` 方法。

**第三步：建立 `Notifier`**
*   建立一個繼承自 `Notifier<YourState>` 的 `Notifier` 類別。
*   為其加上 `with PreservableNotifierMixin<YourSettings, YourStatus, YourState>`。

**第四步：實作 `performFetch` 和 `performSave`**
*   在你的 Notifier 中，覆寫並實作由 Mixin 帶來的兩個抽象方法：
    *   `performFetch()`: 撰寫從 API 或資料庫讀取資料的邏輯，最後回傳 `(YourSettings, YourStatus)` 的 Record。
    *   `performSave()`: 撰寫將 `state.settings.current` 中的資料儲存到 API 或資料庫的邏輯。
*   **你不需要手動更新 state**，Mixin 中的 `fetch()` 和 `save()` 樣板方法會自動幫你處理。

**第五步：設定路由 (`LinksysRoute`)**
*   在你的路由設定檔中，找到該頁面的路由定義。
*   確保它使用的是 `LinksysRoute`。
*   傳入 `preservableProvider` 參數（指向你的 Notifier）。
*   設定 `enableDirtyCheck: true`。

#### **3. 程式碼範例**

```dart
// 1. & 2. 定義 Model 和 State
class MyFeatureSettings extends Equatable { ... }
class MyFeatureStatus extends Equatable { ... }
class MyFeatureState extends FeatureState<MyFeatureSettings, MyFeatureStatus> { ... }

// 3. & 4. 建立 Notifier 並實作樣板方法
final myFeatureProvider = NotifierProvider<MyFeatureNotifier, MyFeatureState>(...);
final preservableMyFeatureProvider = Provider<PreservableContract<...>>(...);

class MyFeatureNotifier extends Notifier<MyFeatureState>
    with PreservableNotifierMixin<MyFeatureSettings, MyFeatureStatus, MyFeatureState> {
  
  @override
  MyFeatureState build() {
    fetch(); // 在 build 時呼叫 Mixin 的 fetch
    return MyFeatureState.initial();
  }

  @override
  Future<(MyFeatureSettings?, MyFeatureStatus?)> performFetch({ ... }) async {
    // 撰寫你的 API 呼叫邏輯
    final settings = await repository.getSettings();
    final status = await repository.getStatus();
    return (settings, status);
  }

  @override
  Future<void> performSave() async {
    // 撰寫你的 API 儲存邏輯
    await repository.saveSettings(state.settings.current);
  }
}

// 5. 設定路由
LinksysRoute(
  path: '/my-feature',
  preservableProvider: preservableMyFeatureProvider,
  enableDirtyCheck: true,
  builder: (context, state) => const MyFeatureView(),
),
```
