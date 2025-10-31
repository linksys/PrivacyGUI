# PnP (Plug and Play) 流程重構計畫

本文檔旨在記錄 PnP 流程的重構目標、策略與具體步驟，作為後續代碼實現的指導藍圖。

## 1. 重構目標 (Refactoring Goals)

當前 PnP 流程的狀態管理邏輯較為分散，本次重構的核心目標是：

- **集中化狀態管理:** 將所有與流程相關的狀態統一由 `PnpProvider` 管理，使其成為唯一的“事實來源 (Single Source of Truth)”。
- **UI與邏輯解耦:** 將業務邏輯（流程控制、API請求、錯誤處理）從 UI 組件中剝離，遷移至 `PnpNotifier`。
- **提升代碼質量:** 提高代碼的可讀性、可維護性、可測試性和健壯性。

## 2. 現有實現的核心問題 (Core Problems)

通過分析，我們發現當前實現存在以下問題：

- **狀態分散:** 流程狀態被分散在 `PnpAdminView` 和 `PnpSetupView` 兩個 `StatefulWidget` 的本地變數中。
- **依賴本地旗標:** 大量使用 `_isLoading`, `_processing`, `_needToReconnect` 等布林旗標來控制 UI 的不同變體，使得單一狀態的實際表現難以預測。
- **邏輯耦合:** 狀態轉換邏輯與 UI 代碼高度耦合，並嚴重依賴 `try-catch` 異常捕獲來驅動流程，使得流程不直觀。
- **流程斷裂:** 整體流程被切割成兩個獨立的狀態機，難以從全局視角理解完整的用戶旅程。

## 3. 重構策略與步驟 (Refactoring Strategy)

我們將採用“狀態機”模型，將整個 PnP 流程視為一個統一的、線性的狀態流。所有 UI 表現都應是這個狀態機當前狀態的純粹映射。

### 步驟 1: 建立統一的狀態模型

1.  **定義 `PnpFlowStatus` 枚舉:**
    創建一個新的枚舉 `PnpFlowStatus`，用來顯式定義 PnP 流程中的**每一個**獨立狀態。這個枚舉將取代舊有的 `_PnpAdminStatus`, `_PnpSetupStep` 以及所有流程控制相關的布林旗標。

    ```dart
    enum PnpFlowStatus {
      // Admin Phase
      adminInitializing,
      adminAwaitingPassword,
      adminLoggingIn,
      adminLoginFailed,
      // ... etc.

      // Wizard Phase
      wizardInitializing,
      wizardConfiguring,
      wizardSaving,
      wizardNeedsReconnect,
      // ... etc.
    }
    ```

2.  **擴展 `PnpState`:**
    在 `PnpState` 中，引入 `PnpFlowStatus` 並添加用於 UI 顯示的附加上下文信息。

    ```dart
    class PnpState extends Equatable {
      final PnpFlowStatus status;
      final Object? error; // 用於承載錯誤信息
      final String? loadingMessage; // 用於承載加載提示文本
      // ... 其他數據
    }
    ```

### 步驟 2: 遷移業務邏輯至 `PnpNotifier`

1.  **遷移 `PnpAdminView` 邏輯:**
    - 將 `_runInitialChecks` 和 `_doLogin` 的邏輯移入 `PnpNotifier`，創建如 `startPnpFlow()` 和 `submitPassword(String password)` 等新方法。
    - 在這些方法中，執行異步操作，並根據成功或失敗的結果，更新 `PnpState` 中的 `status` 和 `error` 字段。

2.  **遷移 `PnpSetupView` 邏輯:**
    - 同樣地，將 `_saveChanges`, `_doFwUpdateCheck`, `_goWiFiReady` 等流程控制方法全部移入 `PnpNotifier`。
    - Notifier 現在是唯一有權力改變 `PnpFlowStatus` 的地方。

### 步驟 3: 簡化 UI 組件

1.  **轉為 `ConsumerWidget`:**
    - 將 `PnpAdminView` 和 `PnpSetupView` 從 `ConsumerStatefulWidget` 重構為 `ConsumerWidget`。

2.  **移除本地狀態:**
    - 刪除所有與流程控制相關的本地變數和旗標 (`_status`, `_setupStep`, `_isLoading`, etc.)。

3.  **響應式構建 UI:**
    - 在 `build` 方法中，使用 `ref.watch(pnpProvider)` 來獲取 `PnpState`。
    - 使用 `switch (pnpState.status)` 來構建 UI，確保每個 `PnpFlowStatus` 都對應一個明確的 UI 畫面。
    - 用戶交互（如按鈕點擊）現在只會調用 `ref.read(pnpProvider.notifier)` 上的方法，將意圖（Intent）發送給 Notifier，而不是在 UI 層直接操作狀態。

### 步驟 4 (進一步優化): 移除 `PnpStep` 中的本地狀態

- 將 `GuestWiFiStep` 中的 `isEnabled` 等狀態也移入 `PnpStepState` 中，由 `pnpProvider` 統一管理。
- UI 組件的 `onChanged` 回調調用 `pnp.setStepData(...)` 更新狀態，`build` 方法則從 Provider 中讀取狀態來渲染，從而使 `PnpStep` 類也變為無狀態。

## 4. 預期效益 (Expected Benefits)

- **可維護性:** 當需要修改流程時（例如，增加一個步驟），只需在 `PnpNotifier` 中修改狀態轉換邏輯，而無需改動多個 UI 文件。
- **可測試性:** 可以獨立對 `PnpNotifier` 進行單元測試，驗證所有狀態轉換的正確性，而無需依賴 Flutter 的組件樹。
- **可讀性:** UI 代碼變得極其簡潔和聲明式，其職責單純是“渲染狀態”。業務流程可以在 `PnpNotifier` 中被清晰地閱讀。
- **健壯性:** 消除因 `setState` 異步執行或狀態同步不當而導致的各類 Bug，使應用行為更加穩定和可預測。
