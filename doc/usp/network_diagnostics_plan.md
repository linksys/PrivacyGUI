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
| 伺服器選擇 | `Device.IP.Diagnostics.ServerSelectionDiagnostics()` | ✅ 可用 |

---

## 已完成功能

### Network Diagnostics 頁面 (`lib/page/network_diagnostics/`)

三個分頁：
1. **Ping** — 測試連線延遲
2. **Traceroute** — 追蹤路由路徑
3. **Speed Test** — 測速（含 Latency + Download）

### Speed Test 流程

1. **Latency 測試** — Ping 8.8.8.8，取得平均延遲
2. **Download 測試** — DownloadDiagnostics，計算下載速度
3. **Upload 測試** — 暫時跳過（Firmware Bug）

---

## Firmware Bug

### BUG: UploadDiagnostics 沒有發送 OperationComplete

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

---

## 待實作功能

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

**實作流程**:
1. 定義各區域測速伺服器清單（hostname → download URL 映射）
2. 執行 `ServerSelectionDiagnostics()` 找出 `FastestHost`
3. 用對應的 download URL 執行 `DownloadDiagnostics()`

**伺服器清單 (待確認)**:
```dart
final speedTestServers = {
  'speedtest.singapore.linode.com': 'http://speedtest.singapore.linode.com/100MB-singapore.bin',
  'speedtest.tele2.net': 'http://speedtest.tele2.net/100MB.zip',
  'proof.ovh.net': 'http://proof.ovh.net/files/100Mb.dat',
  'speedtest.newark.linode.com': 'http://speedtest.newark.linode.com/100MB-newark.bin',
};
```

### 2. 等待 Firmware 修復 UploadDiagnostics

修復後啟用 Upload 測速。

---

## 相關檔案

### Models
- `lib/page/network_diagnostics/models/network_diagnostics_ui_model.dart`
  - `DiagnosticType` — ping, traceroute, speedtest
  - `DiagnosticStatus` — idle, running, completed, error
  - `SpeedTestResult` — latencyMs, downloadBps, uploadBps, etc.
  - `PingResult`, `TracerouteResult` (from `sse_operation_awaiter.dart`)

### Providers
- `lib/page/network_diagnostics/providers/usp_network_diagnostics_notifier.dart`
  - `runPing()`, `runTraceroute()`, `runSpeedTest()`

### Views
- `lib/page/network_diagnostics/views/usp_network_diagnostics_view.dart`

### Core
- `lib/core/usp/services/sse_operation_awaiter.dart` — 執行 Operate 並等待 SSE OperationComplete

---

## 參考文件

- **TR-143**: Enabling Network Throughput Performance Tests and Statistical Monitoring
- **TR-181**: Device Data Model (Device.IP.Diagnostics.*)
