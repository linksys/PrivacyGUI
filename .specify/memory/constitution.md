# PrivacyGUI 開發憲章 (v2.0)

**版本**: v2.0 | **有效日期**: 2025-12-05 | **修訂者**: Development Team

---

## 📌 概述

本憲章規定 PrivacyGUI 開發團隊在**開發與測試**過程中應遵循的標準化流程與品質要求。目的是確保所有開發者都能遵循相同的方法論與品質標準，製作一致品質的功能或修改。

---

## 第一部分：核心觀念

### 1. 架構層次與職責分離

**原則**: 嚴格遵守三層架構，依賴方向**永遠向下**，不允許反向依賴。

```
┌─────────────────────────┐
│  Presentation (UI/頁面)  │  ← 只負責顯示和用戶互動
│  lib/page/*/views/      │
└────────────┬────────────┘
             │ 依賴
┌────────────▼────────────┐
│ Application (服務層)    │  ← 業務邏輯、數據轉換、協調
│ lib/page/*/providers/   │
└────────────┬────────────┘
             │ 依賴
┌────────────▼────────────┐
│  Data (Repository/API)  │  ← 數據獲取、本地存儲、解析
│ lib/core/             │
└─────────────────────────┘
```

**每層職責**:
- **Presentation**: UI 呈現、用戶輸入、狀態觀察（只訪問 Provider）
- **Application**: 業務邏輯、錯誤處理、狀態管理（Riverpod Notifier）
- **Data**: API 調用、資料庫訪問、數據模型定義（依賴注入）

---

### 2. 測試金字塔

**結構**:

```
        🔺 E2E 測試 (5%)      ← 完整流程，成本高
       🔺🔺 集成測試 (15%)   ← 跨層協作，中等成本
      🔺🔺🔺 單元測試 (80%)  ← 最小單位，成本低、速快
```

**具體分配**:
- **單元測試** (80%): 每個 function、class 獨立測試（模擬依賴）
- **集成測試** (15%): Provider + Service 協作測試（可模擬 Data 層）
- **E2E/UI 測試** (5%): 完整用戶流程、金截圖測試

---

### 3. 測試驅動 vs 事後測試

**混合模式** (業界標準):
- **複雜業務邏輯** → 建議先寫測試（TDD），更清楚邊界情況
- **簡單 UI 邏輯** → 實務上事後測試更實用（UI 反覆改，測試易失效）

**決策權**: 開發者根據複雜度自行判斷，Code Review 時確認測試充分

---

### 4. 模擬 (Mocking) 策略

**邊界原則**:
- ✅ **模擬外部依賴** (API、Device、Database 等) → 保證測試穩定可重複
- ❌ **不模擬自己的業務邏輯** → 否則測試變成測試 mock，沒意義

**具體應用**:
- JNAP 執行成功 ✅ 模擬
- JNAP 超時、設備不可達 ✅ 模擬（測試錯誤處理）
- API 錯誤回應 ✅ 模擬
- Provider 內的邏輯轉換 ❌ 不模擬

**工具**: 使用 `mocktail` 模擬所有依賴

---

### 5. 代碼評審標準

**審查項目** (必須檢查):
- ✅ 代碼風格一致 (`flutter analyze` 0 errors, `dart format` 無變更)
- ✅ 測試覆蓋充分 (≥80% 整體，Data 層 ≥90%)
- ✅ 沒有明顯的 bug / 安全漏洞
- ✅ 架構層次正確 (不跨層依賴)
- ✅ Public APIs 有 DartDoc 文檔
- ✅ 向後兼容性 (既有測試仍然過)
- ✅ 邊界情況處理 (null 檢查、錯誤處理等)

---

## 第二部分：開發規則 (環節 4)

### 1. 架構層次

**強制規則**:
- ❌ UI 層**禁止**直接調用 API 或 Repository
- ❌ 只有 Application 層可依賴 Data 層
- ❌ 不允許循環依賴

**檢查清單**:
- [ ] 無 UI 層直接引用 JNAP action
- [ ] 所有 API 調用都通過 Service/Repository
- [ ] Provider 只依賴 Service，不依賴底層 API

---

### 2. 數據模型 (Model)

**強制要求**:

所有 Model（Data Model、State 等）**必須**:
1. ✅ 實作 `Equatable` 接口
2. ✅ 提供 `toJson()` 和 `fromJson()` 方法
3. ✅ 可選：使用 `freezed` 或 `json_serializable` 進行代碼生成

**正確範例**:
```dart
class UserModel extends Equatable {
  final String id;
  final String name;
  final int age;

  const UserModel({
    required this.id,
    required this.name,
    required this.age,
  });

  @override
  List<Object> get props => [id, name, age];

  // 可選：代碼生成
  factory UserModel.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
}
```

---

### 3. 狀態管理 (Riverpod)

**原則**:
- ✅ 使用 Riverpod 管理所有可變狀態
- ✅ 使用 `Notifier` 進行狀態操作
- ✅ 可選：需要 undo/reset 時使用 `PreservableNotifierMixin`

**Notifier 職責**:
- 只做**業務邏輯協調** (不涉及 API 細節)
- **依賴** Service/Repository (不直接依賴底層 API)
- **不涉及** UI 層決策（如導航、Toast）

**正確範例**:
```dart
class MyFeatureNotifier extends Notifier<MyFeatureState> {
  @override
  MyFeatureState build() => MyFeatureState.initial();

  Future<void> loadData() async {
    final service = ref.read(myFeatureServiceProvider);
    final result = await service.fetchData();

    state = state.copyWith(
      data: result,
      isLoading: false,
    );
  }
}
```

---

### 4. DartDoc 文檔

**強制要求**:
- ✅ 所有 **public** 方法/類/介面必須有 DartDoc
- ✅ Core 層 (`lib/core/`) 必須完整文檔
- ✅ Service 層公開方法必須文檔
- ✅ UI 層可簡化或省略 (private 方法除外)

**範例**:
```dart
/// 根據用戶 ID 獲取設備列表。
///
/// 此方法會連接到 API 並回傳該用戶名下的所有設備。
/// 若設備不可達，會拋出 [DeviceNotFoundException]。
///
/// **參數**:
/// - [userId]: 用戶的唯一識別碼
///
/// **回傳值**: `List<Device>` 列表
Future<List<Device>> getDevices(String userId) async { ... }
```

---

### 5. 硬編碼字符串

**強制規則**:
- ❌ **禁止** UI 層硬編碼用戶可見的字符串
- ✅ 使用 `loc(context).xxx` 從本地化檔案獲取

**正確**:
```dart
Text(loc(context).administrationSettings)
```

**錯誤**:
```dart
Text('Administration Settings')
```

---

### 6. 代碼提交前檢查

**提交前必須執行**:
```bash
dart format lib/ test/          # 格式化
flutter analyze                  # Lint 檢查（必須 0 warnings）
```

---

## 第二部分B：重構與層級提取規則

### 1. 重構前的完整性分析

**時機**: 計畫完成後，編碼開始前

#### a) 依賴映射 (Dependency Mapping)
- [ ] 列出所有應該**移出**的依賴
- [ ] 列出所有應該**保留**的依賴
- [ ] 列出所有**新增**的依賴（Service 層）
- [ ] 確認**沒有遺漏**的提取點

**工具驗證**:
```bash
# 識別提取前的所有依賴
grep -E "^import|^from" old_file.dart | sort | uniq

# 提取後驗證（應該移出）
grep -r "protocol_name\|api_detail" source_file.dart
# 若有結果，代表遺漏了提取
```

#### b) 完成標準定義（Critical！）
- ❌ 模糊："重構 Notifier"
- ✅ 明確:"Notifier 中應該：
  - 只包含業務邏輯協調
  - 不含任何 JNAP imports
  - 不含任何協議細節（Action、Transaction 等）
  - 只依賴 Service 層"

### 2. 三層完整測試框架

**原則**: 重構的完整性取決於所有層級測試的完整性

#### 測試層級清單
```
📋 Service 層 (Data Transformation Layer)
   ├─ 測試目標: ≥90% 覆蓋
   ├─ Mock: 所有 external dependencies (API, Repository, Device 等)
   ├─ 不 Mock: Service 自身的業務邏輯
   └─ 必測項:
      ├─ ✅ 成功路徑（完整的業務流程）
      ├─ ✅ GET 操作（查詢、列表等）
      ├─ ✅ SET 操作（修改、刪除等） ⚠️ 經常被遺漏
      ├─ ✅ 錯誤處理（API 失敗、超時等）
      └─ ✅ 邊界情況（null、空列表等）

📋 Application 層 (Notifier/Provider)
   ├─ 測試目標: ≥85% 覆蓋
   ├─ Mock: Service 層、其他外部依賴
   ├─ 不 Mock: Notifier 的狀態協調邏輯
   └─ 必測項:
      ├─ ✅ 委派邏輯（是否正確調用 Service）
      ├─ ✅ 狀態更新（成功時的狀態轉換）
      ├─ ✅ 錯誤傳播（Service 異常如何處理）
      └─ ✅ State 管理（Preservable 邏輯等）

📋 Data Model 層 (State/Model)
   ├─ 測試目標: ≥90% 覆蓋
   ├─ Mock: 無需 mock
   ├─ 不 Mock: 無法 mock（這是數據，不是邏輯）
   └─ 必測項:
      ├─ ✅ 構造與初始化（默認值、必需字段）
      ├─ ✅ copyWith() 操作（創建新實例、保留未改字段）
      ├─ ✅ 序列化/反序列化（toMap/fromMap/toJson/fromJson） ⚠️ 常被遺漏
      ├─ ✅ Equatable 相等性（相同數據 == 相等）
      └─ ✅ 邊界值處理（null、空、極限值）
```

### 3. 常見遺漏檢查表（Anti-Pattern Prevention）

**執行時機**: 重構完成，測試通過後

#### ⚠️ 你是否遺漏了這些？
```
在提交前檢查每一項：

□ Service 層測試
  ❌ 只有 GET 操作測試，沒有 SET 操作測試？
  ❌ 沒有錯誤路徑測試（API 失敗、超時等）？
  ❌ 沒有邊界情況測試（null、空列表等）？

□ State 層測試
  ❌ 沒有序列化測試（toMap/fromMap）？ ⚠️ 最常被遺漏
  ❌ 沒有 JSON 序列化測試（toJson/fromJson）？ ⚠️ 最常被遺漏
  ❌ 沒有 copyWith 測試？
  ❌ 沒有相等性測試？

□ 依賴清理
  ❌ 新層中還有對舊層的直接依賴？（應該通過中間層）
  ❌ 舊層中還有對新層的依賴？（循環依賴）
  ❌ 協議層的 imports 仍然在業務層？

□ 代碼品質
  ❌ `flutter analyze` 有警告？
  ❌ `dart format` 有未格式化代碼？
  ❌ Public API 沒有 DartDoc？
```

### 4. 依賴審查檢查清單

**執行時機**: 實現完成，測試前

#### 使用自動化驗證
```bash
# 1️⃣ 檢查舊層是否有新層不該有的依賴
grep -i "protocol\|api\|repository" new_application_layer.dart
# 應該返回 0 結果（只有業務邏輯，零協議細節）

# 2️⃣ 檢查是否有循環依賴
grep -r "import.*new_service" old_service_layer.dart
# 應該返回 0 結果

# 3️⃣ 驗證所有依賴都被提取
grep -E "class.*Dependencies|ref\.read" old_layer.dart | wc -l
# 與新層中的依賴數對比
```

#### 手動審查清單
- [ ] **新層應該 import 什麼**
  - ✅ Service 層：協議層（JNAP、API 等）+ 模型
  - ✅ Notifier 層：Service 層 + 状態模型

- [ ] **新層不應該 import 什麼**
  - ❌ Service 層：不應該 import Notifier
  - ❌ Notifier 層：不應該直接 import 協議層
  - ❌ 循環依賴的任何部分

### 5. 測試優先度編碼

**在計畫中明確標記測試的必要性**:

```
🔴 CRITICAL - 必須有測試，遺漏會導致功能破損
   ├─ 業務邏輯驗證（Service 層核心功能）
   ├─ SET 操作（INSERT/UPDATE/DELETE）
   ├─ 錯誤路徑（API 失敗、超時等）
   └─ State 序列化/反序列化

🟡 IMPORTANT - 應該有測試，遺漏會導致維護困難
   ├─ 邊界情況（null、empty、max values）
   ├─ 狀態轉換邏輯
   ├─ Equatable 相等性
   └─ copyWith 操作

🟢 OPTIONAL - 可選，但推薦
   ├─ 性能測試
   ├─ 集成測試
   └─ 文檔測試
```

---

## 第三部分：測試規則 (環節 5)

### 1. 覆蓋率要求

| 層級 | 目標 |
|:---|:---|
| **Data 層** (Repository, Service) | ≥ 90% |
| **Application 層** (Provider, Notifier) | ≥ 85% |
| **Presentation 層** (UI 元件) | ≥ 60% |
| **整體** | ≥ 80% |

---

### 2. 必須測試的情況

**Error Cases** (必須):
- ❌ API 超時
- ❌ API 返回錯誤
- ❌ 無效輸入
- ❌ 網絡不可達

**Boundary Cases** (必須):
- ❌ 空列表 / null 值
- ❌ 邊界數值 (0, -1, 最大值)
- ❌ 特殊字符 / 長字符串

**Happy Path** (基礎):
- ✅ 正常操作流程

---

### 3. 模擬策略

**在 Unit Test 中**:
- Mock 所有 external dependencies (API, Database, Device)
- 不 mock 自己的業務邏輯

**在 Integration Test 中**:
- 可以測試跨層協作
- 仍然 mock external API

---

### 4. 數據模型 (State/Model) 測試要求

#### 為什麼需要明確要求？
開發實踐表明，State/Model 的測試**經常被遺漏**，因為開發者認為「這只是數據，應該沒問題」。實際上，序列化錯誤、相等性邏輯問題等常常導致細微的 bug。

#### 必須包含的測試項目
所有 State、Model 類都必須包括以下測試：

**1️⃣ 構造與初始化**
- [ ] 基本構造函數測試（所有字段正確設置）
- [ ] 默認值驗證（可選字段的默認值正確）
- [ ] 必需字段驗證（缺少必需字段時編譯失敗）

**2️⃣ 不可變性操作 (copyWith) - 重要**
- [ ] 複製後創建新實例（不是同一個對象）
- [ ] 部分字段更新時其他字段保持不變
- [ ] 原實例不被修改（真正的不可變）

**3️⃣ 序列化/反序列化 - ⚠️ 最常被遺漏的**
- [ ] `toMap()` 包含所有字段
- [ ] `fromMap()` 正確還原所有字段
- [ ] `toJson()` 返回有效的 JSON 字符串
- [ ] `fromJson()` 正確解析 JSON 字符串
- [ ] 往返序列化（對象 → Map → 對象）結果相等

**4️⃣ 相等性比較 (Equatable)**
- [ ] 相同數據的兩個實例相等
- [ ] 不同數據的實例不相等
- [ ] `props` 包含所有相關字段

**5️⃣ 邊界值處理 - 經常被遺漏**
- [ ] null 字段（若字段支持 nullable）
- [ ] 空集合（若字段是集合）
- [ ] 極限數值（0, -1, 最大值）
- [ ] 特殊字符字符串

#### 檢查清單模板
```dart
// 缺少這些測試嗎？請確保都有：

test('AdministrationSettings constructs with all fields') { ... }
test('AdministrationSettings has correct default values') { ... }
test('AdministrationSettings copyWith creates new instance') { ... }
test('AdministrationSettings copyWith preserves unmodified fields') { ... }

// ⚠️ 以下最常被遺漏 - 必須檢查！
test('AdministrationSettings toMap serializes correctly') { ... }
test('AdministrationSettings fromMap deserializes correctly') { ... }
test('AdministrationSettings toJson creates valid JSON') { ... }
test('AdministrationSettings fromJson parses JSON correctly') { ... }
test('AdministrationSettings round-trip serialization') { ... }

test('AdministrationSettings equality when same data') { ... }
test('AdministrationSettings inequality when different data') { ... }

// 邊界情況
test('AdministrationSettings handles null values') { ... }
test('AdministrationSettings handles empty collections') { ... }
```

#### 為什麼序列化測試經常被遺漏？
```
心理偏差：
  開發者想「這只是 getter/setter，應該沒問題」
  但實際上：
    ❌ 字段遺漏了某些屬性
    ❌ 類型轉換不正確
    ❌ null 處理不當
    ❌ 嵌套對象序列化失敗

只有在測試時才會發現！

解決方案：
  ✅ 把序列化測試列為「強制」項目
  ✅ 不是「可有可無」，而是「必須有」
```

---

### 5. 計畫與文檔要求

#### 計畫必須包含的內容

對於涉及**層級提取、重構、新 Service 創建**的計畫，必須包含：

**1️⃣ 完成標準 (Definition of Done)**
```
不要：
  「Refactor service layer」
  「Implement State classes」

要：
  「Service 層應該包含：
    - fetchAdministrationSettings() 方法
    - saveAdministrationSettings() 方法
    - 4 個私有解析方法

   Notifier 中不應該有：
    - 任何 JNAP imports
    - 任何 JNAPTransactionBuilder 使用
    - 直接的 RouterRepository 依賴

   測試應該包含：
    - Service 層 ≥90% 覆蓋
    - Notifier 層 ≥85% 覆蓋
    - State 層 ≥90% 覆蓋（包括序列化）」
```

**2️⃣ 測試清單 (Test Inventory)**
```
計畫必須明確列出：
  ☐ Service 層：7 個測試
    ├─ 3 個成功路徑
    ├─ 2 個錯誤路徑
    └─ 2 個邊界情況

  ☐ Notifier 層：3 個測試
    ├─ 1 個委派邏輯
    ├─ 1 個狀態更新
    └─ 1 個錯誤處理

  ☐ State 層：N 個測試
    ├─ 構造、copyWith
    ├─ 序列化/反序列化 ⚠️ 明確標注
    ├─ 相等性
    └─ 邊界值
```

**3️⃣ 完整性檢查點 (Checkpoints)**
```
計畫應該有明確的里程碑：

✅ Phase X: Service 實現 + ≥90% 測試通過
✅ Phase Y: Notifier 重構 + ≥85% 測試通過
✅ Phase Z: State 測試完成 + 依賴審查通過
✅ Final: 所有層級集成驗證通過
```

#### 計畫審查檢查清單
提交計畫時檢查：
- [ ] 定義了「完成」的具體標準（不只是任務列表）
- [ ] 明確列出了所有測試層級和數量目標
- [ ] 識別了已知的邊界情況和錯誤路徑
- [ ] 有明確的驗證/檢查步驟（不只是「測試通過」）
- [ ] 標記了 CRITICAL 測試項目（特別是序列化、SET 操作等）

---

## 第四部分：狀態管理最佳實踐

### 1. Notifier 依賴結構

**正確**:
```
Notifier → Service → Repository → API
```

**錯誤**:
```
Notifier → API  (✗ 禁止直接依賴)
```

---

### 2. 錯誤處理

**模式**:
```dart
Future<void> saveSettings(Settings settings) async {
  try {
    final service = ref.read(myServiceProvider);
    final result = await service.save(settings);

    state = state.copyWith(
      settings: result,
      errorMessage: null,  // 清除錯誤
    );
  } catch (e) {
    state = state.copyWith(
      errorMessage: e.toString(),  // 記錄錯誤
    );
  }
}
```

**重點**:
- ✅ 成功 vs 失敗要**明確區分**
- ✅ 錯誤訊息必須記錄在 state
- ✅ UI 根據 state 判斷顯示

---

### 3. 使用 Preservable (可選)

**何時使用**:
- 頁面有 undo/reset 需求 → 使用 `Preservable`
- 頁面無此需求 → 自由設計 state

**Preservable 邏輯**:
- `original`: 服務器數據（初始化和成功保存時更新）
- `current`: 本地編輯數據（用戶修改時更新）

---

## 第五部分：UI 元件使用規則

### 1. 元件選擇流程

```
新 UI 畫面開發
    ↓
1️⃣ 優先從 plugins/widgets 選用現成元件
    ↓ 無現成元件
2️⃣ 評估組合方案
    ├─ 可用 lib 元件組合 → 組合使用
    └─ 完全新的需求 → 進行第 3️⃣ 步
    ↓
3️⃣ 決定新元件位置
    ├─ 基礎元件（有潛力跨專案用） → 加入 plugins/widgets
    └─ 專案特定元件 → 直接加到 PrivacyGUI
```

---

### 2. 開發流程

**時機決策**:
- ✅ 發現需要新元件時，**先暫停功能開發**
- ✅ 先實作新元件（包括測試）
- ✅ 再繼續用該元件完成功能開發

**新元件要求**:
- ✅ 必須遵循既有架構層次
- ✅ 必須包含對應測試
- ✅ 必須有清晰的 public API 文檔

---

### 3. 決策參考

**加入 plugins/widgets 的條件** (基礎元件):
- 設計系統中定義的基礎元件
- 有潛力在多個 Linksys 專案中複用
- 符合統一設計語言

**保留在 PrivacyGUI 的條件** (專案特定):
- 業務特定的複雜元件
- 短期內只在本專案用

---

## 第五部分B：測試範圍限制

### 1. 測試覆蓋範圍

**只測試當前項目相關代碼**，不無限上綱到整個專案：

- ✅ 測試當前重構/功能的 Service、Provider、State 層
- ✅ 測試直接依賴的外部模型（如 ManagementSettings）
- ❌ 不測試整個 `lib/` 目錄
- ❌ 不測試整個 `test/` 目錄
- ❌ 不修復其他無關的 lint warnings

**原則**：測試範圍 = 當前任務的業務邊界，不包括其他功能。

### 2. Lint 警告處理

- ✅ 修復當前代碼引入的新 warnings
- ❌ 不修復既存的 warnings（這是 technical debt，另行處理）
- ✅ 確保 `flutter analyze` 在當前改動上 0 warnings

**原則**：責任清晰，不會因為修一個功能而背上整個項目的 technical debt。

---

## 第六部分：測試資料建構模式 (Test Data Builder Pattern)

### 1. 適用範圍

**強制規則**：當同一型別的 Mock 資料在 **3 個以上單元測試中使用**時，必須提取到專用的 TestData 建構者類。

### 2. 檔案組織

```
test/page/[feature]/services/
├── [service]_test.dart           # 服務層測試（使用 TestData）
└── [service]_test_data.dart      # Mock 資料建構者（集中管理）
```

**命名規則**:
- 測試檔案: `[feature]_[layer]_test.dart`
- 資料檔案: `[feature]_[layer]_test_data.dart`

### 3. TestData 建構者設計

#### 基本結構

```dart
/// Test data builder for [FeatureName]Service tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class [FeatureName]TestData {
  /// Create default [SettingType]Success response
  static JNAPSuccess create[SettingType]Success({
    bool field1 = false,
    bool field2 = false,
    // ... 其他字段
  }) => JNAPSuccess(
    result: 'ok',
    output: {
      'field1': field1,
      'field2': field2,
      // ...
    },
  );

  /// Create a complete successful JNAP transaction response
  ///
  /// 支持部分覆蓋(partial override)設計：只指定需要改變的字段，其他字段使用預設值
  static JNAPTransactionSuccessWrap createSuccessfulTransaction({
    Map<String, dynamic>? setting1,
    Map<String, dynamic>? setting2,
  }) {
    // 定義預設值
    final defaultSetting1 = { /* ... */ };
    final defaultSetting2 = { /* ... */ };

    // 合併預設值和覆蓋值
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.getSetting1,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultSetting1, ...?setting1},
          ),
        ),
        MapEntry(
          JNAPAction.getSetting2,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultSetting2, ...?setting2},
          ),
        ),
      ],
    );
  }

  /// Create a partial error response (for error handling tests)
  static JNAPTransactionSuccessWrap createPartialErrorTransaction({
    required JNAPAction errorAction,
    String errorMessage = 'Operation failed',
  }) {
    // ... 返回包含錯誤的交易
  }

  // Private helpers for default values
  static JNAPSuccess _createDefault[SettingType]() => JNAPSuccess(...);
}
```

#### 使用範例

**之前**（重複代碼，50-80 行）:
```dart
test('parses UPnPSettings correctly', () async {
  final mockResponse = JNAPTransactionSuccessWrap(
    result: 'ok',
    data: [
      MapEntry(JNAPAction.getManagementSettings, JNAPSuccess(...)), // 8 行
      MapEntry(JNAPAction.getUPnPSettings, JNAPSuccess(...)),       // 6 行
      // ...
    ],
  );
  // ...
});
```

**之後**（清晰意圖，10-15 行）:
```dart
test('parses UPnPSettings correctly', () async {
  final mockResponse = AdministrationSettingsTestData.createSuccessfulTransaction(
    upnpSettings: {
      'isUPnPEnabled': true,
      'canUsersConfigure': false,
      'canUsersDisableWANAccess': true,
    },
  );
  // ...
});
```

### 4. 預設值管理

#### 原則

- **明確定義預設值含義**: 預設值應代表"典型設備"或"正常狀態"
- **記錄在代碼註解中**: 說明為什麼選擇這些預設值

```dart
/// 代表"典型設備"的預設值
/// - ManagementSettings: 所有管理方式都禁用（嚴格配置）
/// - UPnPSettings: UPnP 禁用，用戶配置禁用
/// - ALGSettings: SIP 禁用
/// - ExpressForwarding: 不支持
static JNAPSuccess _createDefaultManagement() => JNAPSuccess(
  result: 'ok',
  output: const <String, dynamic>{
    'canManageUsingHTTP': false,
    'canManageUsingHTTPS': false,
    'isManageWirelesslySupported': false,
    'canManageRemotely': false,
  },
);
```

#### 風險警告

**⚠️ 預設值變更可能導致隱默失敗**

如果未來需要改變預設值：

1. ✅ 在 git commit 中明確說明預設值變更的原因
2. ✅ 檢查所有依賴該預設值的測試
3. ✅ 確保新的預設值對所有現有測試仍然適用
4. 🔍 Code Review 時特別檢查預設值變更的影響

### 5. 最佳實踐

✅ **使用 TestData Builder 的好處**:
- 降低代碼重複（~70% 代碼行數減少）
- 集中管理 mock 資料，維護成本低
- 測試代碼更易閱讀（業務邏輯清晰可見）
- 未來改動只需修改一處

❌ **常見陷阱**:
- 過度優化：將所有 mock 資料都提取（即使只用 1-2 次也要提取）→ 只在 3+ 使用時提取
- 預設值不清晰：沒有註解解釋為什麼選擇這些預設值 → 必須記錄含義
- 過度複用：不同場景強行使用同一個預設值 → 為不同場景創建不同建構者

---

## 第七部分：三層測試實踐指南

### 1. 三層測試架構概覽

```
┌─────────────────────────────────────────┐
│  Service 層測試 (Data Transformation)   │  ← ≥90% 覆蓋
│  目標: 驗證資料轉換、錯誤處理、邊界     │
│  Mock: 所有外部依賴                     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Provider 層測試 (Business Logic)       │  ← ≥85% 覆蓋
│  目標: 驗證業務協調、狀態管理          │
│  Mock: Service 層及其他外部依賴        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  State 層測試 (Data Model)              │  ← ≥90% 覆蓋
│  目標: 驗證序列化、不可變性、相等性    │
│  Mock: 無（這是純資料層）              │
└─────────────────────────────────────────┘
```

### 2. Service 層單元測試

**目標**: ≥90% 覆蓋率

**測試職責**:
- ✅ 驗證資料解析/轉換邏輯
- ✅ 驗證錯誤處理（API 失敗、超時等）
- ✅ 驗證邊界情況（null、空列表等）

**使用 mocktail**:
```dart
class MockRouterRepository extends Mock implements RouterRepository {}

late MockRouterRepository mockRepository;

setUp(() {
  mockRepository = MockRouterRepository();
});

test('fetches data successfully', () async {
  final mockRef = UnitTestHelper.createMockRef(
    routerRepository: mockRepository,
  );

  when(() => mockRepository.transaction(any()))
      .thenAnswer((_) async => mockResponse);

  final service = MyFeatureService();
  final result = await service.fetchData(mockRef);

  expect(result.isValid, true);
});
```

**使用 TestData Builder**:
```dart
final mockResponse = MyFeatureTestData.createSuccessfulTransaction(
  setting1: {'field1': true},
  setting2: {'field2': false},
);
```

### 3. Provider 層整合測試

**目標**: ≥85% 覆蓋率

**測試職責**:
- ✅ 驗證 Provider 是否正確委派給 Service
- ✅ 驗證狀態更新是否正確
- ✅ 驗證錯誤傳播是否適當

**使用 ProviderContainer**:
```dart
test('delegates to service on fetch', () async {
  final container = ProviderContainer();
  final notifier = container.read(myFeatureProvider.notifier);

  // 驗證初始狀態
  expect(notifier.state.data, isNull);

  // 驗證方法呼叫
  expect(notifier.performFetch, isA<Function>());
});
```

### 4. State 層資料測試

**目標**: ≥90% 覆蓋率

**必測項目** (⚠️ 最常被遺漏):

| 項目 | 測試項 | 備註 |
|:---|:---|:---|
| 構造 | 基本構造、預設值、必需字段 | 基礎 |
| copyWith | 建立新實例、保留未改字段、原實例不變 | 重要 |
| 序列化 | toMap/fromMap、toJson/fromJson、往返一致 | ⚠️ 最常遺漏 |
| 相等性 | 相同資料相等、不同資料不相等 | 重要 |
| 邊界值 | null、empty、特殊字符、極限值 | 容易遺漏 |

**序列化測試範例**:
```dart
test('toMap/fromMap round-trip serialization', () {
  const original = MySettings(
    field1: true,
    field2: 'test',
  );

  // 序列化 → 反序列化
  final map = original.toMap();
  final restored = MySettings.fromMap(map);

  // 驗證往返一致
  expect(restored, equals(original));
});
```

### 5. 檔案組織規範

```
test/page/[feature]/
├── services/
│   ├── [service]_test.dart          # 7-10 個測試
│   ├── [service]_test_data.dart     # Mock 資料建構者
│   └── [other_service]_test.dart
│
├── providers/
│   ├── [provider]_test.dart         # 3-5 個測試
│   ├── [state]_test.dart            # 20-30 個測試（包括序列化）
│   └── [other_provider]_test.dart
│
└── views/
    ├── [view]_test.dart             # UI 測試（可選）
    └── localizations/
        └── [view]_test.dart         # 金截圖測試（可選）
```

### 6. 預期覆蓋率

| 層級 | 覆蓋率 | 說明 |
|:---|:---|:---|
| Service 層 | ≥90% | 資料層最關鍵 |
| Provider 層 | ≥85% | 業務邏輯協調 |
| State 層 | ≥90% | 資料模型必須完整 |
| **整體** | **≥80%** | 加權平均 |

### 7. 測試優先度

在計畫中明確標記各測試的必要性：

```
🔴 CRITICAL - 必須有測試
   ├─ Service 層：所有 GET/SET 操作
   ├─ State 層：序列化/反序列化
   └─ Provider 層：委派邏輯

🟡 IMPORTANT - 應該有測試
   ├─ 邊界情況（null、empty）
   ├─ 錯誤路徑（API 失敗）
   └─ 狀態轉換

🟢 OPTIONAL - 推薦但非必須
   ├─ 性能測試
   ├─ 集成測試
   └─ 文檔示例
```

---

## 第六部分（原）：流程新增機制

### 如何加入新的最佳實踐

當開發者在重構或開發中發現尚未列入憲章的問題時：

1. ✅ **完成整個功能** (開發 → 測試 → Code Review 通過)
2. ✅ **確認是好實踐** (可重複、有價值、經過驗證)
3. ✅ **記錄下來** (PR 討論或 note)
4. ✅ **提議加入憲章** (可在 Code Review 或完成後)
5. ✅ **團隊審視批准** (若共識一致，直接更新憲章)

### 修訂方式

- **直接修改**本憲章檔案 (`.specify/memory/constitution.md`)
- 採用語義化版本：MAJOR (向後不兼容) / MINOR (新增原則) / PATCH (澄清)
- 更新 Last Amended 時間

---

## 檢查清單

### 提交前 Checklist

- [ ] `dart format` 已執行
- [ ] `flutter analyze` 通過（0 errors, 0 warnings）
- [ ] 新代碼有對應測試
- [ ] 測試覆蓋率 ≥80% (整體) / ≥90% (Data 層)
- [ ] Model 都用 `Equatable` + `toJson/fromJson`
- [ ] Public API 有 DartDoc
- [ ] 沒有硬編碼字符串
- [ ] 架構層次正確（無跨層依賴）
- [ ] 既有測試仍然通過

### Code Review Checklist

- [ ] 測試充分且有意義
- [ ] 代碼風格一致
- [ ] 沒有明顯 bug / 安全漏洞
- [ ] 架構層次正確
- [ ] DartDoc 完整
- [ ] 沒有硬編碼字符串
- [ ] 邊界情況處理完善
- [ ] 向後兼容性維持

---

## 版本紀錄

| 版本 | 日期 | 主要內容 |
|:---|:---|:---|
| v2.2 | 2025-12-08 | 新增：第六部分 Test Data Builder Pattern + 第七部分 三層測試實踐指南 (基於 AdministrationSettingsService 重構經驗驗證) |
| v2.1 | 2025-12-06 | 增強：重構與層級提取規則 + 三層測試框架 + 常見遺漏檢查表 + 計畫文檔要求 (基於 AdministrationSettingsService 重構經驗) |
| v2.0 | 2025-12-05 | 全新撰寫：核心觀念 + 開發規則 + 測試規則 + 狀態管理 + UI 元件規則 + 流程新增機制 |

---

**Last Amended**: 2025-12-08
