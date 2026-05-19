# Network Diagnostics / Speed Test 功能計劃

## 概述

利用 TR-143 定義的診斷功能實作網路測速與診斷工具。

## TR-143 診斷功能 (Device.IP.Diagnostics.*)

| 功能 | Operate Command | 狀態 |
|------|-----------------|------|
| Ping | `Device.IP.Diagnostics.IPPing()` | ✅ 可用 |
| Traceroute | `Device.IP.Diagnostics.TraceRoute()` | ✅ 可用 |
| Download 測速 | `Device.IP.Diagnostics.DownloadDiagnostics()` | ✅ 可用 |
| Upload 測速 | `Device.IP.Diagnostics.UploadDiagnostics()` | ⚠️ Firmware Bug |
| 伺服器選擇 | `Device.IP.Diagnostics.ServerSelectionDiagnostics()` | ⚠️ Firmware Bug |

---

## 已完成功能

### Speed Test 模組 (`lib/page/speed_test/`)

獨立的測速模組：
- `SpeedTestState` / `SpeedTestResult` 資料模型
- `speedTestNotifier` — 協調 latency → download 測試
- Speed Test 頁面 + Dashboard card
- 6 個預設公開測速伺服器 (Linode 全球 CDN)
- 手動伺服器選擇（自動選擇因 FW bug 延後）

### Network Diagnostics 頁面 (`lib/page/network_diagnostics/`)

兩個分頁：
1. **Ping** — 測試連線延遲
2. **Traceroute** — 追蹤路由路徑

### Unified Diagnostics (`lib/page/unified_diagnostics/`)

引導式診斷流程：
- **No Internet** — WAN 狀態檢查、Gateway/DNS/Internet Ping
- **Slow Network** — Speed Test、WiFi 訊號、連線裝置分析

### Speed Test 流程

1. **Latency 測試** — Ping 選定伺服器，取得平均延遲
2. **Download 測試** — DownloadDiagnostics，計算下載速度
3. **Upload 測試** — 跳過（Firmware Bug，標記為 NotSupported）

---

## Firmware Bugs

### BUG-1: UploadDiagnostics 沒有發送 OperationComplete

**確認日期**: 2026-05-19  
**Firmware 版本**: 1.0.18.26051322

**現象**:
- Subscribe `OperationComplete` on `Device.IP.Diagnostics.UploadDiagnostics.`
- Operate `Device.IP.Diagnostics.UploadDiagnostics()` 
- SSE **永遠收不到** OperationComplete 通知

**對比**:
- DownloadDiagnostics 正常發送 OperationComplete ✅
- bbfdm 直接呼叫 UploadDiagnostics 可以同步返回結果 ✅

**暫時解法**: Speed Test 跳過 Upload，標記為 "NotSupported"

### BUG-2: ServerSelectionDiagnostics 沒有發送 OperationComplete

**確認日期**: 2026-05-19  
**Firmware 版本**: 1.0.18.26051322

**現象**:
- Subscribe `OperationComplete` on `Device.IP.Diagnostics.ServerSelectionDiagnostics.`
- Operate `Device.IP.Diagnostics.ServerSelectionDiagnostics()` 
- SSE **永遠收不到** OperationComplete 通知

**對比**:
- bbfdm 直接呼叫 ServerSelectionDiagnostics 可以同步返回結果 ✅

**暫時解法**: 使用手動伺服器選擇（UI dropdown）

### 總結

| Operation | Operate Response | OperationComplete via SSE |
|-----------|------------------|---------------------------|
| `IPPing()` | ✅ | ✅ |
| `TraceRoute()` | ✅ | ✅ |
| `DownloadDiagnostics()` | ✅ | ✅ |
| `UploadDiagnostics()` | ✅ | ❌ |
| `ServerSelectionDiagnostics()` | ✅ | ❌ |

---

## 待實作功能（需等待 FW 修復）

### 1. 自動選擇最近伺服器 (ServerSelectionDiagnostics)

利用 TR-143 的 `ServerSelectionDiagnostics` 自動選擇延遲最低的測速伺服器。

**Operate Command**:
```
Device.IP.Diagnostics.ServerSelectionDiagnostics()
```

**Input Args**:
```json
{
  "HostList": "speedtest.tele2.net,speedtest.singapore.linode.com,proof.ovh.net",
  "NumberOfRepetitions": "3"
}
```

**Output Args**:
| 參數 | 說明 |
|------|------|
| `Status` | Complete / Error |
| `FastestHost` | 最快的伺服器 hostname |
| `AverageResponseTime` | 平均回應時間 (μs) |
| `MinimumResponseTime` | 最小回應時間 (μs) |
| `MaximumResponseTime` | 最大回應時間 (μs) |

### 2. Upload 測速

修復 UploadDiagnostics 的 OperationComplete 後啟用。

---

## 相關檔案

### Speed Test
- `lib/page/speed_test/models/speed_test_state.dart`
- `lib/page/speed_test/providers/speed_test_notifier.dart`
- `lib/page/speed_test/views/speed_test_view.dart`
- `lib/page/speed_test/cards/usp_speed_test_card.dart`

### Unified Diagnostics
- `lib/page/unified_diagnostics/models/diagnostic_state.dart`
- `lib/page/unified_diagnostics/models/diagnostic_result.dart`
- `lib/page/unified_diagnostics/providers/unified_diagnostics_notifier.dart`
- `lib/page/unified_diagnostics/views/unified_diagnostics_view.dart`

### Network Diagnostics (Ping/Traceroute)
- `lib/page/network_diagnostics/models/network_diagnostics_ui_model.dart`
- `lib/page/network_diagnostics/providers/usp_network_diagnostics_notifier.dart`
- `lib/page/network_diagnostics/views/usp_network_diagnostics_view.dart`

### Core
- `lib/core/usp/services/sse_operation_awaiter.dart` — 執行 Operate 並等待 SSE OperationComplete

---

## Open Questions

### Speed Test Server List 維護策略

目前伺服器清單 hard-coded 在 `SpeedTestServer.all`（6 個 Linode 伺服器）。

**問題**：
- 單一供應商風險（Linode 變更 URL 或下線會全部失效）
- 無法動態更新（需發版）
- 區域覆蓋不足（缺少台灣、香港、韓國、南美、澳洲）

**可能方案**：
| 方案 | 說明 | 需要支援 |
|------|------|----------|
| A. Remote Config | Cloud API 提供 JSON 清單 | Cloud 團隊 |
| B. 多供應商 Hard-code | 增加 Tele2/OVH/Hetzner 備援 | 無（但仍需發版） |
| C. Router 端提供 | FW 提供 `Device.X_LINKSYS.SpeedTest.ServerList` | FW 團隊 |

**目前狀態**：維持 hard-coded，待決定長期策略

---

## 參考文件

- **TR-143**: Enabling Network Throughput Performance Tests and Statistical Monitoring
- **TR-181**: Device Data Model (Device.IP.Diagnostics.*)
- **GitHub Issue**: linksys/PrivacyGUI#857
