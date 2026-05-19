# USP Golden Test 框架設計規範

## 概述

為 PrivacyGUI 專案中所有 USP 頁面提供的宣告式自動化 Golden Test 框架。基於 FeatureState 架構設計，取代舊有的截圖測試基礎設施。

### 目標

- 每個 USP 頁面的每種視覺狀態都有對應的 Golden 截圖
- 開發者只需撰寫宣告式 config，框架自動處理其餘流程
- 自動化驗證確保不會遺漏任何頁面或狀態
- 命名規範與目錄結構一致且可強制執行

### 不在範圍內

- 商業邏輯測試（由 Notifier unit test 負責）
- 頁面間的導航/路由測試
- 端對端整合測試
- 使用者操作引起的狀態轉換測試（由 states map 處理）

---

## 架構

### 核心原則

USP 頁面是 provider state 的**純函數**（不使用 `setState()`）。因此：

> 窮舉所有有意義的 `FeatureState` 組合 ＝ 窮舉所有可能的 UI 輸出。

每個改變 state 的使用者操作都會產生新的 `FeatureState` 值——以 `states` map 中的獨立項目表示。Interactions 僅保留給不改變 provider state 的 UI 層覆蓋物（overlay）。

### 元件關係

```
GoldenTestConfig  -->  runViewGoldenTests()  -->  golden PNGs
       |                      |
       v                      v
  ProviderOverrides      _buildGoldenWidget()
  (per-feature mocks)   (shell 包裝 + 語系 + 螢幕大小 + 主題)
```

---

## 宣告式 Config API

### GoldenTestConfig

```dart
class GoldenTestConfig {
  final String viewName;              // snake_case 完整名稱（如 'firewall'）
  final Widget Function() view;       // 待測 Widget builder
  final ShellType shell;              // 外殼包裝類型
  final Map<String, MockSetup> states;        // 狀態測試
  final Map<String, Interaction>? interactions; // 互動測試（選填）
  final List<Locale> locales;         // 語系（預設：[Locale('en')]）
  final List<GoldenDevice> devices;   // 螢幕大小（預設：phone480 + desktop1280）
  final List<Brightness> themes;      // 主題模式（預設：[Brightness.light]）
  final double? height;               // 固定高度覆寫（選填）
}
```

| 參數 | 說明 | 預設值 |
|------|------|--------|
| `viewName` | 頁面識別名（snake_case） | 必填 |
| `view` | 回傳待測 Widget 的 builder | 必填 |
| `shell` | `pageView` / `scaffold` / `custom` | 必填 |
| `states` | 狀態名稱 → provider overrides 設定 | 必填（至少一個 entry） |
| `interactions` | 互動名稱 → setup + 操作步驟 | 選填 |
| `locales` | 要測試的語系列表 | `[Locale('en')]` |
| `devices` | 要測試的螢幕大小 | `[phone480, desktop1280]` |
| `themes` | 要測試的主題模式 | `[Brightness.light]` |
| `height` | 固定高度覆寫，設定時所有 device 使用此高度 | `null`（使用 device 預設高度） |

---

## 完整範例（Firewall）

### 測試檔案

`test/usp_test/page/firewall/localizations/usp_firewall_view_test.dart`

```dart
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_firewall.dart';
import '../fixtures/firewall_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'firewall',
      view: () => const UspFirewallView(),
      shell: ShellType.custom,
      states: {
        'loading': (overrides) => overrides.addAll(
          firewallOverrides(FirewallFeatureState.initial()),
        ),
        'error': (overrides) => overrides.addAll(
          firewallOverrides(errorState),
        ),
        'data': (overrides) => overrides.addAll(
          firewallOverrides(dataState(allOnModel)),
        ),
        'data_all_off': (overrides) => overrides.addAll(
          firewallOverrides(dataState(allOffModel)),
        ),
        'edit_dirty': (overrides) => overrides.addAll(
          firewallOverrides(dirtyState()),
        ),
        'saving': (overrides) => overrides.addAll(
          firewallOverrides(dirtyState(isSaving: true)),
        ),
      },
    ),
  );
}
```

### 測試資料（Fixtures）

`test/usp_test/page/firewall/fixtures/firewall_test_data.dart`

```dart
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

const allOnModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: true,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

const allOffModel = FirewallUIModel(
  isIPv4FirewallEnabled: false,
  isIPv6FirewallEnabled: false,
  blockIPSec: true,
  blockPPTP: true,
  blockL2TP: true,
  blockAnonymousRequests: false,
  blockMulticast: false,
  blockIDENT: false,
);

const dirtyCurrentModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: false,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

FirewallFeatureState dataState(FirewallUIModel model) {
  final settings = FirewallSettings(
    model: model,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const FirewallStatus(isLoading: false),
  );
}

FirewallFeatureState dirtyState({bool isSaving = false}) {
  final original = FirewallSettings(
    model: allOnModel,
    ruleContext: FirewallRuleContext.empty,
  );
  final current = FirewallSettings(
    model: dirtyCurrentModel,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: original, current: current),
    status: FirewallStatus(isLoading: false, isSaving: isSaving),
  );
}

FirewallFeatureState get errorState => FirewallFeatureState(
  settings: Preservable(
    original: FirewallSettings.empty(),
    current: FirewallSettings.empty(),
  ),
  status: const FirewallStatus(
    isLoading: false,
    errorMessage: 'Connection failed',
  ),
);
```

### Mock 檔案

`test/usp_test/golden_framework/mocks/mock_firewall.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';

class FixedFirewallNotifier extends UspFirewallNotifier {
  final FirewallFeatureState _fixedState;

  FixedFirewallNotifier(this._fixedState);

  @override
  FirewallFeatureState build() => _fixedState;

  @override
  Future<(FirewallSettings?, FirewallStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async => (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void updateSetting(FirewallUIModel Function(FirewallUIModel) updater) {}
}

List<Override> firewallOverrides(FirewallFeatureState state) => [
  uspFirewallProvider.overrideWith(() => FixedFirewallNotifier(state)),
];
```

---

## Interaction 範圍定義

Interactions **僅限於**不改變 provider state 的 UI 層操作：

| 適用 | 不適用 |
|------|--------|
| 開啟 Dialog / Bottom Sheet | Toggle 開關（產生新 state） |
| 切換 Tab（Tab bar 視覺狀態） | 儲存操作（產生 saving state） |
| 展開/收合 Dropdown、Accordion | 輸入文字（產生 dirty state） |
| 捲動顯示螢幕外內容 | 任何改變 provider state 的操作 |

**原則**：使用者操作導致的 state 變化，一律以 `states` map 中的獨立項目表示。

---

## Mock 策略

### 設計方式：Per-Feature FixedNotifier + 拆檔

每個 feature 提供一個 `FixedXxxNotifier`，繼承真實的 Notifier，在 `build()` 回傳固定 state，並明確 no-op 所有 mutation 方法。

### 檔案結構

```
test/usp_test/golden_framework/
  mocks/
    mock_common.dart        // commonOverrides() — 所有頁面共用
    mock_firewall.dart      // FixedFirewallNotifier + firewallOverrides()
    mock_wifi_settings.dart // FixedWifiSettingsNotifier + wifiOverrides()
    ...                     // 每個 feature 一個檔案
```

### 為什麼不用 mockito / mocktail？

| 原因 | 說明 |
|------|------|
| **Riverpod 生命週期相容性** | Notifier 依賴 container 注入的 `ref`。Mock implements 不是真正的 subclass，版本升級時可能靜默崩潰 |
| **Golden test 不需要驗證行為** | mockito/mocktail 的核心價值是 `verify()`，但 golden test 只需要 render 固定 state，不需要驗證方法呼叫 |
| **穩定性優先** | 真正的 subclass + 明確 no-op 不會因第三方套件版本升級而壞掉 |
| **明確優於隱含** | `noSuchMethod` 靜默回傳 null 會在 non-nullable method 上 runtime crash |

### 設計摘要

| 考量 | 決定 |
|------|------|
| Riverpod 相容性 | 真正的 subclass，無生命週期問題 |
| 安全性 | 明確 no-op，不會靜默回傳 null |
| 擴展性 | 拆檔，git 衝突機率低 |
| 樣板程式碼 | 每個 feature 10-20 行，寫一次 |
| 第三方依賴 | 無 |

---

## 測試資料（Fixtures）

共用測試資料定義一次，golden test 和 unit test 皆可引用。

### 位置

```
test/usp_test/page/{feature}/
  fixtures/
    {feature}_test_data.dart    // 共用 FeatureState、Model 常數
  localizations/
    usp_{feature}_view_test.dart  // golden test（引用 fixtures）
```

### 原則

- 有意義的 state 組合定義在 `fixtures/` 一次
- Golden test 和 unit test 都從同一份 fixtures 引入
- Fixtures 只包含資料建構，不包含測試邏輯

---

## 命名規範

### 格式

```
{view_name}-{state_key}-{device}-{locale}.png
```

Dark mode 時附加後綴：
```
{view_name}-{state_key}-{device}-{locale}-dark.png
```

| 欄位 | 規則 | 範例 |
|------|------|------|
| view_name | snake_case 完整名稱 | `firewall`, `port_forwarding_detail` |
| state_key | snake_case 狀態描述 | `loading`, `data_all_off`, `edit_dirty` |
| device | 裝置名稱 | `phone480`, `desktop1280` |
| locale | 語言代碼 | `en`, `ja`, `es` |
| dark | 僅 dark mode 時附加 | `-dark` |

### 範例

```
firewall-loading-phone480-en.png
firewall-data-desktop1280-en.png
firewall-data_all_off-phone480-en.png
wifi_settings-tab_guest-desktop1280-en.png
port_forwarding_detail-dialog_add-phone480-en.png
firewall-data-phone480-en-dark.png
```

---

## 狀態覆蓋要求

### 指導原則

> 如果一個 state 會產生視覺上不同的畫面，就需要一張 Golden 截圖。

### 最低要求

每個 view config **必須**至少包含一個 state entry（通常是 `data`）。

### 建議狀態（有狀態的頁面）

有 provider 驅動 async 狀態的頁面（loading / error / data）建議三種都涵蓋。但純靜態頁面（如導覽選單）只需要 `data`。Loading 和 error UI 是共用元件，由單一共用 golden test 覆蓋即可。

### 額外狀態

除了基本狀態，列舉所有產生不同視覺輸出的狀態：

| 情境 | 狀態名稱範例 |
|------|-------------|
| 有儲存功能 | `saving` |
| 有編輯模式 | `edit_dirty` |
| 有欄位驗證 | `validation_error` |
| 條件渲染分支 | `ipv6_enabled`, `ipv6_disabled` |
| 列表型頁面 | `empty_list` |

### 如何判斷需要哪些狀態

檢視 view 的 `build()` 方法。每個改變渲染內容的 `if`、`switch`、三元運算子，都對應一個需要覆蓋的狀態：

```dart
// 這個條件代表需要兩種狀態：ipv6_enabled 和 ipv6_disabled
if (state.isIPv6Enabled)
  Ipv6SettingsSection(...)
else
  Ipv6DisabledBanner(...)
```

---

## 測試矩陣

### 螢幕大小（預設）

| 名稱 | 寬度 | 高度 |
|------|------|------|
| phone480 | 480 | 800 |
| desktop1280 | 1280 | 800 |

### 語系（預設）

| 語系 |
|------|
| en |

### 主題（預設）

| 主題 |
|------|
| light |

### 每個頁面的產出數量

```
產出數量 = 狀態數 × 螢幕大小數 × 語系數 × 主題數
```

典型頁面（6 狀態，預設 config）：`6 × 2 × 1 × 1 = 12 張 golden 截圖`

---

## 測試執行

| 操作 | 指令 |
|------|------|
| 執行所有 golden test | `flutter test test/usp_test/` |
| 執行特定 feature | `flutter test test/usp_test/page/firewall/` |
| 重新產生 baseline | `flutter test --update-goldens test/usp_test/` |
| 重新產生特定 feature | `flutter test --update-goldens test/usp_test/page/firewall/` |

---

## 新增頁面的 Golden Test 流程

```
步驟 1 → 建立 Mock 檔案
         test/usp_test/golden_framework/mocks/mock_{feature}.dart
         • 實作 FixedXxxNotifier subclass
         • 匯出 xxxOverrides(state) helper function

步驟 2 → 建立 Fixtures
         test/usp_test/page/{feature}/fixtures/{feature}_test_data.dart
         • 定義各狀態的測試資料

步驟 3 → 建立測試檔案
         test/usp_test/page/{feature}/localizations/usp_{feature}_view_test.dart
         • 撰寫 GoldenTestConfig

步驟 4 → 產生 baseline
         flutter test --update-goldens test/usp_test/page/{feature}/

步驟 5 → 視覺檢查產生的截圖

步驟 6 → Commit

步驟 7 → CI 自動驗證覆蓋率
```

---

## 目錄結構總覽

```
test/usp_test/
├── flutter_test_config.dart          # Alchemist config + 字型載入（test runner 自動載入）
├── golden_framework/
│   ├── golden_test_config.dart       # GoldenTestConfig, Interaction, ShellType
│   ├── golden_runner.dart            # runViewGoldenTests(), _buildGoldenWidget()
│   └── mocks/
│       ├── mock_common.dart          # commonOverrides()
│       ├── mock_firewall.dart        # FixedFirewallNotifier + firewallOverrides()
│       ├── mock_dashboard.dart       # Dashboard mock + stub widget factory
│       └── mock_xxx.dart             # 每個 feature 一個檔案
└── page/
    ├── firewall/
    │   ├── fixtures/
    │   │   └── firewall_test_data.dart
    │   └── localizations/
    │       ├── usp_firewall_view_test.dart
    │       └── goldens/
    │           ├── firewall-loading-phone480-en.png
    │           ├── firewall-data-desktop1280-en.png
    │           └── ...
    └── wifi_settings/
        ├── fixtures/
        │   └── wifi_settings_test_data.dart
        └── localizations/
            ├── usp_wifi_settings_view_test.dart
            └── goldens/
                └── ...
```

---

## 測試基礎設施

### flutter_test_config.dart

位於 `test/usp_test/flutter_test_config.dart`，由 Flutter test runner 自動載入（適用於 `test/usp_test/` 下所有測試）。負責：

1. **Alchemist 設定** — 停用 CI goldens，啟用 platform goldens 並設定 `diffThreshold: 0.025`
2. **字型載入** — 載入真實字型使文字可讀（非 Ahem 黑色方塊）

### Alchemist 設定

```dart
AlchemistConfig(
  ciGoldensConfig: CiGoldensConfig(enabled: false),
  platformGoldensConfig: PlatformGoldensConfig(
    enabled: true,
    renderShadows: false,
    filePathResolver: (fileName, _) => 'goldens/$fileName.png',
    diffThreshold: 0.025,
  ),
)
```

| 設定 | 說明 |
|------|------|
| `diffThreshold: 0.025` | 允許最多 2.5% 像素差異。因 `JiggleShake` 使用未指定 seed 的 `Random()` 產生非確定性動畫，缺少此容差 edit-mode 測試會不穩定失敗 |
| `renderShadows: false` | 陰影渲染因平台而異，停用可避免跨機器差異 |

### 字型載入

Flutter 測試預設使用 `Ahem` 字型（所有字形渲染為黑色方塊）。為產生可閱讀的 golden 截圖：

```dart
// 從 ui_kit_library 套件載入（路徑透過 .dart_tool/package_config.json 解析）
final mainFont = FontLoader('packages/ui_kit_library/NeueHaasGrotTextRound');
// 從解析出的套件路徑載入 .otf 檔案
```

`packages/` 前綴是必要的，因為應用程式透過 `ui_kit_library` 套件引用字型。`AppText` widget 會正確繼承 theme 的字型；原生 `Text()` widget 則不會（除非明確指定 style）。

### Portal 包裝

`flutter_portal`（`Portal` widget）在 `_buildGoldenWidget()` 中包裹 `MaterialApp.router`。這是 UI Kit overlay 元件（tooltips、dropdowns）使用 `PortalTarget`/`PortalFollower` 所必要的。

### 相依套件

```yaml
dev_dependencies:
  alchemist: ^0.14.0        # Golden test 框架（取代 golden_toolkit）
  flutter_portal: ^1.1.4    # UI Kit overlay widget 所需
```

---

## Auto Runner 實作細節

### runViewGoldenTests()

使用 `alchemist` 套件的 `goldenTest` API 進行 golden 渲染與比對。

```dart
void runViewGoldenTests(GoldenTestConfig config) {
  _validateConfig(config);

  group('${config.viewName} golden tests', () {
    for (final stateEntry in config.states.entries) {
      for (final device in config.devices) {
        for (final locale in config.locales) {
          for (final theme in config.themes) {
            final effectiveHeight = config.height ?? device.size.height;
            final effectiveSize = Size(device.size.width, effectiveHeight);

            goldenTest(
              '...',
              fileName: name,
              constraints: BoxConstraints.expand(
                width: effectiveSize.width,
                height: effectiveSize.height,
              ),
              pumpBeforeTest: (tester) async {
                // 多次 pump 用於 async provider 初始化
                for (int i = 0; i < 5; i++) {
                  await tester.pump(const Duration(milliseconds: 50));
                }
              },
              pumpWidget: (tester, widget) async {
                _suppressOverflowErrors();
                await tester.binding.setSurfaceSize(effectiveSize);
                tester.view.physicalSize = effectiveSize;
                tester.view.devicePixelRatio = 1.0;
                await tester.pumpWidget(widget);
              },
              builder: () => _buildGoldenWidget(...),
            );
          }
        }
      }
    }
  });
}
```

### 關鍵實作細節

| 機制 | 說明 |
|------|------|
| `physicalSize` + `devicePixelRatio` | 兩者都必須設定，`MediaQuery.sizeOf` 才能回報正確的 viewport 寬度。單獨設定 `setSurfaceSize` 只控制截圖擷取面，不影響 widget 看到的邏輯大小 |
| 多次 pump 循環 | Async provider（尤其是讀取 SharedPreferences 或使用 post-frame callback 的）需要多個 frame 完成初始化。5×50ms pump 涵蓋典型的 async 初始化 |
| Interaction post-pump | 執行互動步驟後，`pump(Duration(milliseconds: 100))` 觸發所有待處理的延遲 timer（如動畫 callback） |
| Overflow 抑制 | `_suppressOverflowErrors()` 防止 golden test 因外觀性 overflow 失敗——overflow 在 golden 截圖中可見即可 |

---

## 未來考量

- **CI 環境標準化**：Golden 截圖在 macOS 上產生，使用特定字型渲染。Linux CI runner 可能產生不同像素結果。如跨平台差異成為問題，可考慮固定字型渲染的 Docker image。
- **動畫確定性**：`JiggleShake` 使用未指定 seed 的 `Random()`，需要 `diffThreshold` 容差。如果新增更多動畫，考慮對 random source 指定 seed 或在 golden 擷取時停用動畫。
- **Loading/Error 共用 baseline**：Loading 和 error UI 是跨頁面共用的。單一共用 golden test 即可覆蓋這些元件，減少每個 feature 的狀態要求。
