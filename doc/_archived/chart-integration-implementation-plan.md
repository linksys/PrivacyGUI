# UI Kit 圖表整合實作計劃

## 現狀分析

### ✅ 現有功能
- UI Kit 提供 5 種完整的圖表組件 (AppLineChart, AppBarChart, AppPieChart, AppRadarChart, AppHeatmapChart)
- 基於 fl_chart 的高品質圖表實現
- 支援主題化样式系統
- 內建觸摸互動和工具提示

### ❌ 缺少的整合
1. **UiKitCatalog 註冊** - 無法在 JSON 模板中使用
2. **標準動作處理** - 沒有整合到 onAction 系統
3. **JSON 數據格式** - 複雜數據結構需要轉換

## 實作方案

### Phase 1: UiKitCatalog 圖表建構器

為每個圖表組件實作 JSON 建構器：

```dart
// 在 UiKitCatalog.standardBuilders 中添加：

'AppLineChart': (context, props, {onAction, children}) {
  // 解析 JSON 數據為 AppChartSeries
  final seriesData = props['series'] as List<dynamic>? ?? [];
  final series = seriesData.map((s) => _parseChartSeries(s)).toList();

  // 解析軸配置
  final yAxis = _parseChartAxis(props['yAxis']);
  final xAxis = _parseChartAxis(props['xAxis']);

  return AppLineChart(
    series: series,
    yAxis: yAxis,
    xAxis: xAxis,
    showGrid: props['showGrid'] as bool? ?? true,
    showTooltip: props['showTooltip'] as bool? ?? true,
    enableZoom: props['enableZoom'] as bool? ?? false,
    onTouch: (event) => _handleChartTouch(event, onAction),
  );
}
```

### Phase 2: 數據格式標準化

#### JSON 模板格式設計

**線圖範例：**
```json
{
  "type": "AppLineChart",
  "props": {
    "series": [
      {
        "label": "CPU Usage",
        "data": [10, 25, 40, 30, 50],
        "color": "#2196F3",
        "filled": true
      },
      {
        "label": "Memory Usage",
        "data": [20, 35, 30, 45, 40],
        "color": "#FF9800",
        "useSecondaryAxis": true
      }
    ],
    "xLabels": ["00:00", "06:00", "12:00", "18:00", "24:00"],
    "yAxis": {
      "min": 0,
      "max": 100,
      "interval": 25
    },
    "secondaryYAxis": {
      "min": 0,
      "max": 8,
      "interval": 2
    },
    "showGrid": true,
    "showTooltip": true,
    "enableZoom": true,
    "onPointTap": {
      "$action": "chart_point_selected",
      "chartType": "line"
    }
  }
}
```

**長條圖範例：**
```json
{
  "type": "AppBarChart",
  "props": {
    "series": [
      {
        "label": "Download",
        "data": [100, 150, 200, 175, 220],
        "color": "#4CAF50"
      },
      {
        "label": "Upload",
        "data": [50, 75, 100, 85, 110],
        "color": "#FF5722"
      }
    ],
    "xLabels": ["Jan", "Feb", "Mar", "Apr", "May"],
    "horizontal": false,
    "stacked": false,
    "showValueLabels": true,
    "onBarTap": {
      "$action": "chart_bar_selected",
      "chartType": "bar"
    }
  }
}
```

### Phase 3: 動作處理整合

#### 圖表專用動作類型

```dart
void _handleChartTouch(AppChartTouchEvent event, onAction?) {
  if (onAction == null) return;

  switch (event.type) {
    case AppChartTouchType.tapUp:
      // 將圖表觸摸事件轉換為標準動作格式
      onAction({
        'action': 'chart_point_selected',
        'touchType': 'tap',
        'points': event.touchedPoints.map((p) => {
          'seriesIndex': p.seriesIndex,
          'dataIndex': p.dataIndex,
          'value': p.value,
          'position': {'x': p.localPosition.dx, 'y': p.localPosition.dy},
        }).toList(),
      });
      break;

    case AppChartTouchType.longPressStart:
      onAction({
        'action': 'chart_point_long_pressed',
        'touchType': 'longPress',
        'points': event.touchedPoints.map(/* ... */).toList(),
      });
      break;
  }
}
```

#### PackageWidgetRenderer 動作處理擴展

```dart
// 在 _handleWidgetAction 中添加圖表動作支援：

case 'chart_point_selected':
  _handleChartPointSelected(actionData);
  break;
case 'chart_bar_selected':
  _handleChartBarSelected(actionData);
  break;

void _handleChartPointSelected(Map<String, dynamic> actionData) {
  final points = actionData['points'] as List<dynamic>?;
  if (points?.isNotEmpty == true) {
    final point = points!.first as Map<String, dynamic>;
    final seriesIndex = point['seriesIndex'] as int;
    final value = point['value'] as double;

    logger.d('[PkgWidget] Chart point selected: series=$seriesIndex, value=$value');

    // 可以觸發資料詳細視圖、更新其他 widget 等
  }
}
```

### Phase 4: 數據綁定整合

#### 支援動態數據更新

```json
{
  "type": "AppLineChart",
  "props": {
    "series": [
      {
        "label": "Network Traffic",
        "data": {"$bind": "networkStats.trafficData"},
        "color": "#2196F3"
      }
    ],
    "xLabels": {"$bind": "networkStats.timeLabels"}
  }
}
```

## 實作檢查清單

### ✅ 準備工作
- [x] 分析現有圖表組件功能
- [x] 設計 JSON 模板格式
- [x] 規劃動作處理整合

### ✅ 已完成功能

#### Phase 1: 基礎整合 ✅ COMPLETE
- [x] 實作 `_parseChartSeries` 輔助函數
- [x] 實作 `_parseRadarSeries` 輔助函數
- [x] 實作 `_parsePieSection` 輔助函數
- [x] 實作 `_parseChartAxis` 輔助函數
- [x] 為每個圖表組件添加 UiKitCatalog 建構器
- [x] 實作圖表觸摸事件轉換器 `_handleChartTouch`

#### Phase 2: 動作系統 ✅ COMPLETE
- [x] 整合標準動作處理系統
- [x] 添加圖表專用動作類型支援
- [x] 實作圖表互動回調機制

#### Phase 3: 測試驗證 ✅ COMPLETE
- [x] 創建圖表 JSON 模板範例 (`chart_integration_demo.json`)
- [x] 撰寫圖表整合測試 (`chart_integration_test.dart`)
- [x] 驗證動作處理功能
- [x] 所有測試通過

#### Phase 4: 文件更新 ✅ COMPLETE
- [x] 更新 Package Widget 系統文件
- [x] 添加圖表使用指南
- [x] 創建圖表範例檔案
- [x] 完整實作文件 (`chart-integration-complete.md`)

## 預期效果

完成整合後，開發者可以在 JSON 模板中使用豐富的圖表功能：

1. **完整的圖表類型支援** - 線圖、長條圖、圓餅圖、雷達圖、熱力圖
2. **動態數據綁定** - 通過 `$bind` 綁定實時數據
3. **互動式圖表** - 點擊、長按、懸停等用戶互動
4. **統一動作處理** - 圖表事件整合到標準動作系統
5. **視覺編輯器支援** - 為 Phase 3 視覺編輯器準備圖表組件

這將使 Package Widget 系統成為功能完整的 Dashboard 解決方案，支援豐富的數據可視化需求。