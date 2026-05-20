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

## DNS 診斷功能 (Device.DNS.*)

| 功能 | 路徑 | 狀態 |
|------|------|------|
| DNS Client 狀態 | `Device.DNS.Client.` | ✅ 可用 |
| DNS Server 列表 | `Device.DNS.Client.Server.{i}.*` | ✅ 可用 |
| DNS Lookup 診斷 | `Device.DNS.Diagnostics.NSLookupDiagnostics()` | ✅ 可用 |

---

## 已完成功能

### Speed Test 模組 (`lib/page/speed_test/`)

獨立的測速模組：
- `SpeedTestState` / `SpeedTestResult` 資料模型
- `speedTestNotifier` — 協調 latency → download 測試
- Speed Test 頁面 + Dashboard card
- 6 個預設公開測速伺服器 (Linode 全球 CDN)
- 手動伺服器選擇（dialog UI）

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
- Subscribe `OperationComplete` on `Device.IP.Diagnostics.`
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
- Subscribe `OperationComplete` on `Device.IP.Diagnostics.`
- Operate `Device.IP.Diagnostics.ServerSelectionDiagnostics()` 
- SSE **永遠收不到** OperationComplete 通知

**對比**:
- bbfdm 直接呼叫 ServerSelectionDiagnostics 可以同步返回結果 ✅

**暫時解法**: 使用手動伺服器選擇（UI dialog）

### 總結

| Operation | Operate Response | OperationComplete via SSE |
|-----------|------------------|---------------------------|
| `IPPing()` | ✅ | ✅ |
| `TraceRoute()` | ✅ | ✅ |
| `DownloadDiagnostics()` | ✅ | ✅ |
| `UploadDiagnostics()` | ✅ | ❌ |
| `ServerSelectionDiagnostics()` | ✅ | ❌ |
| `NSLookupDiagnostics()` | ✅ | ✅ |

---

## 待實作功能

### Phase 2: Auto-Diagnostic Overview

- [ ] 更新 `diagnostic_state.dart` 新增 flow enum
- [ ] Overview tab 自動執行所有檢查
- [ ] DHCP pool 使用率計算
- [ ] Device scoring (訊號強度 + 傳輸速率)
- [ ] VerdictEngine 移植 (from Instant-Troubleshooting)

### Phase 3: Guided Flows

- [ ] Flow 1: No Internet (WAN → Gateway → DNS → Internet)
- [ ] Flow 2: Slow Internet (Speed Test → Traceroute → Device analysis)
- [ ] Flow 3: Device Issues (單一裝置診斷)
- [ ] Flow 4: WiFi Coverage (訊號強度分析)
- [ ] Flow 5: Intermittent (間歇性問題)

### Phase 4: DNS 增強 (需等待 YAML)

- [ ] DNS server 顯示 (`DnsClient`)
- [ ] `NSLookupDiagnostics()` DNS 驗證
- [ ] DNS 失敗時建議替代 DNS

---

## 待新增 YAML Definitions

### 1. `dns_client.yaml` (新增)

```yaml
name: DnsClient
description: DNS client configuration and server list
category: network

instance:
  path: Device.DNS.Client.
  params:
    - path: Enable
      field: enabled
      type: boolean
    - path: Status
      field: status
      type: string
    - path: ServerNumberOfEntries
      field: serverCount
      type: int

multiInstance:
  path: Device.DNS.Client.Server.
  name: DnsServer
  params:
    - path: DNSServer
      field: address
      type: string
      required: true
    - path: Type
      field: type
      type: string
    - path: Enable
      field: enabled
      type: boolean
    - path: Status
      field: status
      type: string
    - path: Alias
      field: alias
      type: string
    - path: Interface
      field: interface
      type: string
```

### 2. `network_diagnostics.yaml` (修改)

新增 nsLookup operation:

```yaml
  - name: nsLookup
    path: Device.DNS.Diagnostics.NSLookupDiagnostics()
    description: Run DNS lookup diagnostic
    inputs:
      - path: HostName
        field: hostName
        type: string
        required: true
      - path: DNSServer
        field: dnsServer
        type: string
        required: false
```

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

**目前狀態與行動方案**：
- **短期防禦**：採取方案 B，擴充 hard-coded 節點清單（加入 Cloudflare 或 AWS 等多供應商），並實作自動 Fallback 機制，避免單一供應商（Linode）失效導致功能停擺。
- **長期目標**：推動方案 A (Remote Config)，透過 Cloud API 根據使用者地理位置動態下發測速節點，從根本解決維護與準確度問題。

---

## 架構改善與技術債 (Architecture & Tech Debt)

基於專案《憲章 (constitution.md)》與近期盤點，需在後續開發中補齊以下架構改善項目：

### 1. 修正 UI Model 命名規範 (Article III)
目前 `lib/page/unified_diagnostics/models/` 中的資料類別（如 `DiagnosticStepResult`, `WanStatusCheckResult`, `DhcpPoolUsageInfo`, `DeviceScore`）主要作為展示層的 UI Model。依據憲章 Sec 3.3.4，必須重構並加上 `UIModel` 後綴，例如改為 `DiagnosticStepUIModel`。

### 2. 修正 Provider 生命週期 (Article IV)
`unifiedDiagnosticsProvider` 負責協調單一頁面的狀態機（Flow 1~5），屬於 L2 Feature Page Provider，依據憲章 Sec 4.1 必須使用 `AutoDisposeNotifierProvider`。目前實作未使用 AutoDispose，離開頁面後狀態未被正確清理，需盡快修正。

### 3. 補齊 Service 單元測試 (Article I)
目前已實作的 `UnifiedDiagnosticsService` 缺乏對應的單元測試，`test/page/unified_diagnostics/services/` 目錄為空。在推進 Phase 2~4 之前，必須補上此 Service 的核心邏輯測試，確保涵蓋率達標。

### 4. Firmware Bugs 同步回應調查
針對 UploadDiagnostics 與 ServerSelectionDiagnostics 收不到 `OperationComplete` 事件的問題（BUG-1, BUG-2），後續將調查這兩個 `Operate` 指令是否已經在同步的 `OperateResponse` 中直接夾帶了結果。若有，將擴充 `SseOperationAwaiter` 的邏輯（若收到同步結果則直接返回，不強制等待 SSE），嘗試繞過 FW Bug 提早解鎖功能。

---

## 參考文件

- **TR-143**: Enabling Network Throughput Performance Tests and Statistical Monitoring
- **TR-181**: Device Data Model (Device.IP.Diagnostics.*, Device.DNS.*)
- **GitHub Issue**: linksys/PrivacyGUI#857
