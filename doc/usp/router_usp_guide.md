# Router USP 使用指南

**適用機型:** Linksys M60TB-EU (PINNACLE 2.0)
**韌體版本:** 1.0.14.26013014
**最後驗證:** 2026-03-02
**TR-181 版本:** v2.18.1

---

## 目錄

1. [概述](#1-概述)
2. [Router 端架構](#2-router-端架構)
3. [SSH 直連 — bbfdm/ubus 操作](#3-ssh-直連--bbfdmubus-操作)
4. [HTTP API — USP Bridge](#4-http-api--usp-bridge)
5. [Flutter 測試頁面](#5-flutter-測試頁面)
6. [bbfdm 指令完整參考](#6-bbfdm-指令完整參考)
7. [除錯技巧](#7-除錯技巧)
8. [驗證測試清單](#8-驗證測試清單)
9. [已知問題與限制](#9-已知問題與限制)
10. [常用路徑速查表](#10-常用路徑速查表)

---

## 1. 概述

### USP (User Services Platform) 是什麼？

USP (TR-369) 是 Broadband Forum 制定的裝置管理協定，用於取代舊有的 TR-069 (CWMP)。在 PrivacyGUI 專案中，USP 被用來取代 Linksys 專有的 JNAP 協定。

### 通訊流程

```
Flutter App (WASM Client)
    │
    │  HTTP POST (protobuf)
    ▼
lighttpd (HTTPS :443)
    │
    ├── /api/v1/auth/*  ──► usp-auth-cgi (CGI)  ──► JWT token
    │
    └── /api/v1/usp     ──► usp-bridge (daemon)
                                │
                                │  Unix Domain Socket
                                ▼
                            OBUSPA (USP Agent)
                                │
                                │  ubus call
                                ▼
                            bbfdm (Data Model)
                                │
                                ├── bbfdm.wifidmd    → Device.WiFi.*
                                ├── bbfdm.netmngr    → Device.IP.*, Routing.*
                                ├── bbfdm.dhcpmngr   → Device.DHCPv4/v6.*
                                ├── bbfdm.hostmngr   → Device.Hosts.*
                                ├── bbfdm.firewallmngr → Device.Firewall.*, NAT.*
                                └── ... (18 sub-daemons)
```

### 三種存取方式

| 方式 | 用途 | 協定 |
|------|------|------|
| **SSH + ubus** | 直接除錯、驗證資料 | 文字指令 (JSON) |
| **HTTP API** | 生產環境 / WASM client | Protobuf over HTTPS |
| **Flutter 測試頁** | 整合測試 | WASM → Protobuf → HTTPS |

---

## 2. Router 端架構

### 2.1 必要服務

| 服務 | 程式 | 功能 | 自動啟動 |
|------|------|------|----------|
| OBUSPA | `/usr/sbin/obuspa` | USP Agent — 處理 TR-181 data model | ✅ 是 |
| usp-bridge | `/usr/sbin/usp-bridge` | HTTP→UDS 橋接 | ❌ 需手動啟動 |
| usp-auth-cgi | `/www/cgi-bin/usp-auth-cgi` | JWT 認證 | ✅ (隨 lighttpd) |
| lighttpd | `/usr/sbin/lighttpd` | HTTPS 伺服器 | ✅ 是 |
| bbfdm | `/usr/sbin/bbfdmd` | Broadband Forum Data Model | ✅ 是 |

### 2.2 檢查服務狀態

```bash
# SSH 登入
ssh root@192.168.1.1
# 或使用 sshpass 自動登入
sshpass -p '<password>' ssh -o StrictHostKeyChecking=no root@192.168.1.1

# 檢查各服務狀態
ps | grep obuspa          # USP Agent
ps | grep usp-bridge      # HTTP→UDS 橋接
ps | grep lighttpd         # Web 伺服器
ps | grep bbfdmd           # Data Model daemon
```

### 2.3 啟動 usp-bridge（如未運行）

```bash
/etc/init.d/usp-bridge start
```

驗證啟動成功：
```bash
ps | grep usp-bridge
# 應看到: /usr/sbin/usp-bridge
```

### 2.4 OBUSPA 設定檔

路徑: `/etc/config/obuspa`

```
config obuspa 'global'
    option enabled '1'
    option db_file '/etc/obuspa/usp.db'
    option log_dest '/tmp/obuspa.log'
    option ipc_timeout '5000'

config localagent 'localagent'
    option EndpointID 'proto::AgentA'

config uds 'uds_localui'
    option Enable '1'
    option Path '/var/run/usp/broker_agent_path'
    option Mode 'Listen'

config controller 'controller_localui'
    option Enable '1'
    option EndpointID 'controller::local_ui'
    option Protocol 'UDS'
    option assigned_role_name 'Full Access'
```

### 2.5 關鍵路徑

| 路徑 | 用途 |
|------|------|
| `/var/run/usp/broker_agent_path` | OBUSPA UDS socket |
| `/etc/obuspa/usp.db` | OBUSPA 資料庫 |
| `/tmp/obuspa.log` | OBUSPA 日誌 |
| `/etc/config/obuspa` | OBUSPA 配置 |
| `/etc/bbfdm/dmmap/` | bbfdm 動態映射檔 |

---

## 3. SSH 直連 — bbfdm/ubus 操作

### 3.1 連線方式

```bash
# 方式一：互動式 SSH
ssh root@192.168.1.1

# 方式二：單一指令執行（適合腳本）
sshpass -p '<password>' ssh -o StrictHostKeyChecking=no root@192.168.1.1 "<command>"
```

> **安裝 sshpass (macOS):**
> ```bash
> brew install sshpass
> ```

### 3.2 基本 GET 查詢

```bash
# 查詢單一參數
ubus call bbfdm get '{"path":"Device.DeviceInfo.Manufacturer"}'
# 回應: {"Manufacturer":"Linksys"}

# 查詢整個物件（含所有子參數）
ubus call bbfdm get '{"path":"Device.DeviceInfo."}'
# 回應: {"results":[{"path":"...","data":"...","type":"..."},...]}"

# 查詢特定 sub-daemon
ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.Radio."}'
ubus call bbfdm.hostmngr get '{"path":"Device.Hosts.Host."}'
ubus call bbfdm.dhcpmngr get '{"path":"Device.DHCPv4.Server.Pool.1."}'
```

> **注意:** 物件路徑必須以 `.` 結尾（如 `Device.WiFi.Radio.`），參數路徑不需要（如 `Device.DeviceInfo.Manufacturer`）。

### 3.3 查詢注意事項 — daemon 選擇

每個 TR-181 子樹由不同的 bbfdm sub-daemon 處理。用錯 daemon 會得到 fault 9005。

| TR-181 路徑前綴 | 正確的 daemon |
|-----------------|---------------|
| `Device.DeviceInfo.` | `bbfdm` (頂層) 或 `bbfdm.sysmngr` |
| `Device.WiFi.` | `bbfdm.wifidmd` |
| `Device.IP.`, `Device.PPP.`, `Device.Routing.` | `bbfdm.netmngr` |
| `Device.DHCPv4.`, `Device.DHCPv6.` | `bbfdm.dhcpmngr` |
| `Device.DNS.` | `bbfdm.dnsmngr` |
| `Device.Firewall.`, `Device.NAT.` | `bbfdm.firewallmngr` |
| `Device.Hosts.` | `bbfdm.hostmngr` |
| `Device.Ethernet.` | `bbfdm.ethmngr` |
| `Device.Bridging.` | `bbfdm.bridgemngr` |
| `Device.Time.` | `bbfdm.timemngr` |
| `Device.Users.` | `bbfdm.usermngr` |
| `Device.UserInterface.` | `bbfdm.sysmngr` |
| `Device.IP.Diagnostics.` | `bbfdm` (頂層) |
| `Device.Reboot()`, `Device.FactoryReset()` | `bbfdm` (頂層) / `bbfdm.core` |

> **技巧:** 不確定用哪個 daemon？用頂層 `bbfdm` 通常可以查到大部分路徑。如果回傳 fault 9005，嘗試 sub-daemon。查看完整註冊表：`ubus call bbfdm services '{}'`

---

## 4. HTTP API — USP Bridge

### 4.1 認證（取得 JWT Token）

```bash
# 登入取得 token
curl -k -X POST https://192.168.1.1/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"password":"admin"}'
```

回應：
```json
{
  "token": "<JWT>",
  "controller_endpoint": "/api/v1/usp",
  "turbo_controller_endpoint": "/api/v1/turbo/start",
  "agent_endpoint": "/api/v1/llm/query"
}
```

> **注意:**
> - 使用 `-k` 忽略自簽憑證
> - 實際路由器使用 `/api/v1/` 前綴（規格書寫 `/api/`）
> - 預設密碼為 `admin`（非 SSH/WiFi 密碼）

### 4.2 發送 USP 請求

USP bridge 接受 **binary protobuf** 格式（非 JSON）：

```
POST /api/v1/usp HTTP/1.1
Content-Type: application/octet-stream
Authorization: Bearer <JWT>

<binary USP Record (protobuf)>
```

> **無法用 curl 直接測試 USP GET/SET** — 需要 protobuf 編碼。使用 Flutter 測試頁面或 WASM client 進行測試。

### 4.3 登出

```bash
curl -k -X POST https://192.168.1.1/api/v1/auth/logout \
  -H "Authorization: Bearer <JWT>"
```

### 4.4 驗證 API 可達性

```bash
# 檢查 HTTPS 是否可用
curl -k -s -o /dev/null -w "%{http_code}" https://192.168.1.1/
# 應回傳: 200

# 檢查認證端點
curl -k -s -o /dev/null -w "%{http_code}" -X POST \
  https://192.168.1.1/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"password":"wrong"}'
# 應回傳: 401

# 檢查 USP bridge（未認證）
curl -k -s -o /dev/null -w "%{http_code}" \
  https://192.168.1.1/api/v1/usp
# 應回傳: 401 (未認證) 或 503 (bridge 未啟動)
```

---

## 5. Flutter 測試頁面

### 5.1 啟動方式

```bash
flutter run -d chrome \
  -t lib/main_usp_test.dart \
  --web-browser-flag="--disable-web-security" \
  --web-browser-flag="--user-data-dir=/tmp/chrome-usp-test"
```

> **重要前置步驟:**
> 1. 先在瀏覽器開啟 `https://192.168.1.1` 並接受自簽憑證
> 2. 使用 `--disable-web-security` 繞過 CORS
> 3. 使用獨立的 `--user-data-dir` 避免影響正常 Chrome

### 5.2 測試頁面操作

1. **URL 欄位**: 填入 `https://192.168.1.1`（必須用 HTTPS）
2. **Password 欄位**: 填入 `admin`
3. **Connect**: 點擊連線，等待 WASM client 初始化 + JWT 認證
4. **GET 測試**: 輸入 TR-181 路徑（如 `Device.DeviceInfo.Manufacturer`），點擊 GET
5. **SET 測試**: 輸入路徑和值，點擊 SET
6. **OPERATE 測試**: 輸入指令路徑和參數

### 5.3 測試頁面除錯

日誌會顯示在頁面底部。關鍵訊息：

```
[WASM] USP WASM client initialized     ← WASM 載入成功
[Auth] Login successful                  ← JWT 認證成功
[GET] Device.DeviceInfo.Manufacturer     ← 查詢路徑
[GET] Response: {Manufacturer: Linksys}  ← 查詢結果
[GET] Error: Failed to fetch            ← CORS 或網路問題
```

### 5.4 常見問題

| 症狀 | 原因 | 解決方案 |
|------|------|----------|
| `Failed to fetch` | CORS 被擋 | 確認使用 `--disable-web-security` 啟動 Chrome |
| `Failed to fetch` | 自簽憑證未接受 | 先在新分頁開啟 `https://192.168.1.1` 並接受憑證 |
| `WASM init failed` | WASM 檔案未建置 | 執行 `wasm-pack build` 重新建置 `web/usp_client_bg.wasm` |
| `Login failed (503)` | usp-bridge 未啟動 | SSH 登入路由器執行 `/etc/init.d/usp-bridge start` |
| `Login failed (401)` | 密碼錯誤 | USP 密碼為 `admin`（非 WiFi/SSH 密碼） |
| `GET returns null` | 路徑不存在或 bbfdm bug | 用 SSH + ubus 確認路徑是否有資料 |

---

## 6. bbfdm 指令完整參考

### 6.1 可用方法

```bash
ubus -v list bbfdm
# 輸出:
# "get":{"path":"String","value":"String","optional":"Table"}
# "schema":{"path":"String","value":"String","optional":"Table"}
# "instances":{"path":"String","value":"String","optional":"Table"}
# "operate":{"path":"String","value":"String","optional":"Table"}
# "set":{"path":"String","value":"String","optional":"Table"}
# "add":{"path":"String","value":"String","optional":"Table"}
# "del":{"path":"String","value":"String","optional":"Table"}
# "services":{}
```

### 6.2 GET — 讀取參數

```bash
# 讀取單一參數
ubus call bbfdm get '{"path":"Device.DeviceInfo.Manufacturer"}'
# → {"Manufacturer":"Linksys"}

# 讀取整個物件
ubus call bbfdm get '{"path":"Device.DeviceInfo."}'
# → {"results":[{"path":"Device.DeviceInfo.Manufacturer","data":"Linksys","type":"xsd:string"}, ...]}

# 讀取多實例物件
ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.Radio."}'
# → 回傳 Radio.1 + Radio.2 的所有參數

# 讀取特定實例
ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.Radio.1."}'
```

回傳格式：
```json
{
  "results": [
    {
      "path": "Device.WiFi.Radio.1.Channel",
      "data": "13",
      "type": "xsd:unsignedInt"
    },
    {
      "path": "Device.WiFi.Radio.1.Enable",
      "data": "1",
      "type": "xsd:boolean",
      "flags": ["Secure"]
    }
  ]
}
```

### 6.3 SET — 寫入參數

```bash
ubus call bbfdm.timemngr set '{"path":"Device.Time.NTPServer5","value":"3.pool.ntp.org"}'
```

回應：
```json
{
  "results": [{"path": "Device.Time.NTPServer5", "data": "1"}],
  "modified_uci": ["/etc/config/system"]
}
```

- `data: "1"` 表示成功修改 1 個參數
- `modified_uci` 列出被修改的 UCI 設定檔

### 6.4 ADD — 新增實例

```bash
# 新增 DHCP 靜態位址保留
ubus call bbfdm.dhcpmngr add '{"path":"Device.DHCPv4.Server.Pool.1.StaticAddress."}'
```

回應：
```json
{
  "results": [{"path": "Device.DHCPv4.Server.Pool.1.StaticAddress.", "data": "1"}],
  "modified_uci": ["/etc/config/dhcp", "/etc/bbfdm/dmmap/dmmap_dhcp"]
}
```

- `data: "1"` 表示新建的實例編號

### 6.5 DEL — 刪除實例

```bash
ubus call bbfdm.dhcpmngr del '{"path":"Device.DHCPv4.Server.Pool.1.StaticAddress.1."}'
```

回應格式同 ADD。

### 6.6 OPERATE — 執行指令

```bash
# Ping 測試
ubus call bbfdm operate '{"path":"Device.IP.Diagnostics.IPPing()","action":"ping","input":{"Host":"8.8.8.8","NumberOfRepetitions":"3"}}'
```

回應：
```json
{
  "results": [{
    "path": "Device.IP.Diagnostics.IPPing()",
    "output": [
      {"path": "Status", "data": "Complete"},
      {"path": "SuccessCount", "data": "3"},
      {"path": "FailureCount", "data": "0"},
      {"path": "AverageResponseTime", "data": "6"},
      {"path": "MinimumResponseTime", "data": "5"},
      {"path": "MaximumResponseTime", "data": "6"}
    ]
  }]
}
```

```bash
# Traceroute
ubus call bbfdm operate '{"path":"Device.IP.Diagnostics.TraceRoute()","action":"traceroute","input":{"Host":"8.8.8.8","MaxHopCount":"15"}}'
```

### 6.7 SCHEMA — 查詢結構定義

```bash
# 查詢某物件有哪些參數
ubus call bbfdm.wifidmd schema '{"path":"Device.WiFi.SSID."}'
```

回應：
```json
{
  "results": [
    {"path": "Device.WiFi.SSID.{i}.", "type": "xsd:object"},
    {"path": "Device.WiFi.SSID.{i}.Alias", "type": "xsd:string"},
    {"path": "Device.WiFi.SSID.{i}.Enable", "type": "xsd:boolean"},
    {"path": "Device.WiFi.SSID.{i}.Status", "type": "xsd:string"},
    {"path": "Device.WiFi.SSID.{i}.LastChange", "type": "xsd:unsignedInt"}
  ]
}
```

> **用途:** Schema 表示 daemon 知道這個物件結構，但不代表有實例資料。用 `instances` 確認實際有幾個實例。

### 6.8 INSTANCES — 列舉實例

```bash
# 列舉 WiFi AccessPoint 實例
ubus call bbfdm.wifidmd instances '{"path":"Device.WiFi.AccessPoint."}'
```

回應：
```json
{
  "results": [
    {"path": "Device.WiFi.AccessPoint.1"},
    {"path": "Device.WiFi.AccessPoint.1.AC.1"},
    {"path": "Device.WiFi.AccessPoint.2"},
    {"path": "Device.WiFi.AccessPoint.2.AssociatedDevice.1"},
    {"path": "Device.WiFi.AccessPoint.3"},
    {"path": "Device.WiFi.AccessPoint.4"}
  ]
}
```

### 6.9 SERVICES — 查看完整服務註冊表

```bash
ubus call bbfdm services '{}'
```

回傳所有 bbfdm sub-daemon 及其註冊的 TR-181 物件。這是最權威的「什麼路徑歸哪個 daemon」參考。

---

## 7. 除錯技巧

### 7.1 路徑查詢無回應 — 診斷流程

```
查詢 Device.X.Y. 沒有結果？
    │
    ├── 用 bbfdm (頂層) 查 → fault 9005?
    │       │
    │       └── 嘗試專屬 daemon (如 bbfdm.wifidmd)
    │               │
    │               ├── 仍 fault 9005 → 該模組未在韌體中實作
    │               │
    │               └── 回傳 {"results":[]} (空) → 物件存在但無實例
    │                       │
    │                       ├── 用 schema 確認結構有定義 → schema 有 → 可能是韌體 Bug
    │                       │
    │                       └── schema 也空 → 該路徑確實不受支援
    │
    └── 用 services 查 → 路徑未出現在任何 daemon → 韌體未實作
```

### 7.2 確認 bbfdm daemon 健康

```bash
# 列出所有 bbfdm 相關 daemon
ubus list | grep bbfdm

# 預期輸出 (19 個):
# bbfdm
# bbfdm.bridgemngr
# bbfdm.bulkdata
# bbfdm.core
# bbfdm.custommngr
# bbfdm.dhcpmngr
# bbfdm.dnsmngr
# bbfdm.ethmngr
# bbfdm.firewallmngr
# bbfdm.gateway-info
# bbfdm.hostmngr
# bbfdm.icwmp
# bbfdm.lifemotemngr
# bbfdm.netmngr
# bbfdm.obuspa
# bbfdm.sysmngr
# bbfdm.timemngr
# bbfdm.trustdomainmngr
# bbfdm.usermngr
# bbfdm.wifidmd
```

### 7.3 OBUSPA 日誌

```bash
# 即時查看 OBUSPA 日誌
tail -f /tmp/obuspa.log

# 搜尋特定錯誤
grep -i error /tmp/obuspa.log
grep -i "fault" /tmp/obuspa.log
```

### 7.4 usp-bridge 除錯

```bash
# 確認 usp-bridge 正在運行
ps | grep usp-bridge

# 確認 UDS socket 存在
ls -la /var/run/usp/broker_agent_path

# 重啟 usp-bridge
/etc/init.d/usp-bridge stop
/etc/init.d/usp-bridge start
```

### 7.5 lighttpd 除錯

```bash
# 確認 HTTPS 443 在監聽
netstat -tlnp | grep 443

# 查看 lighttpd 日誌
cat /tmp/lighttpd-error.log
```

### 7.6 WiFi 底層驗證（繞過 bbfdm）

```bash
# 直接查詢 wifi daemon（不經過 bbfdm）
ubus call wifi.ap.ath0 status
# → 會顯示 SSID, channel, clients 等原始資料

# 對比 bbfdm 回傳的資料，可辨識是 bbfdm plugin 問題還是底層問題
```

### 7.7 UCI 設定檔確認

```bash
# 查看 WiFi 設定
uci show wireless

# 查看 DHCP 設定
uci show dhcp

# 查看防火牆設定
uci show firewall

# 查看系統設定
uci show system
```

> bbfdm 的 `set` / `add` / `del` 操作會修改 UCI 設定。回傳的 `modified_uci` 欄位告訴你哪些設定檔被修改了。

### 7.8 網路抓包

```bash
# 在路由器上抓取 UDS 通訊（需安裝 tcpdump）
tcpdump -i lo -w /tmp/uds_capture.pcap

# 在開發機上抓取 HTTP 通訊
# 使用 Chrome DevTools Network tab（啟用 --disable-web-security 後）
```

---

## 8. 驗證測試清單

### 8.1 環境準備檢查

```bash
# ✅ SSH 可連線
sshpass -p '<password>' ssh -o StrictHostKeyChecking=no root@192.168.1.1 "echo OK"

# ✅ OBUSPA 正在運行
sshpass -p '<password>' ssh root@192.168.1.1 "ps | grep obuspa"

# ✅ usp-bridge 正在運行
sshpass -p '<password>' ssh root@192.168.1.1 "ps | grep usp-bridge"

# ✅ UDS socket 存在
sshpass -p '<password>' ssh root@192.168.1.1 "ls /var/run/usp/broker_agent_path"

# ✅ HTTPS 443 可連線
curl -k -s -o /dev/null -w "%{http_code}" https://192.168.1.1/

# ✅ USP auth 端點可用
curl -k -s -o /dev/null -w "%{http_code}" -X POST \
  https://192.168.1.1/api/v1/auth/login \
  -H "Content-Type: application/json" -d '{"password":"admin"}'
```

### 8.2 CRUD 操作驗證

#### GET 驗證

```bash
# 基本讀取
ubus call bbfdm get '{"path":"Device.DeviceInfo.Manufacturer"}'
# 預期: {"Manufacturer":"Linksys"}

# 多實例讀取
ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.Radio."}'
# 預期: 回傳 Radio.1 和 Radio.2 的所有參數

# 巢狀物件
ubus call bbfdm.hostmngr get '{"path":"Device.Hosts.Host.1."}'
# 預期: PhysAddress, IPAddress, HostName, Active 等
```

#### SET 驗證

```bash
# 讀取原始值
ubus call bbfdm.timemngr get '{"path":"Device.Time.NTPServer5"}'
# 記錄原始值

# 寫入新值
ubus call bbfdm.timemngr set '{"path":"Device.Time.NTPServer5","value":"test.ntp.org"}'
# 預期: {"results":[...],"modified_uci":[...]}

# 驗證寫入
ubus call bbfdm.timemngr get '{"path":"Device.Time.NTPServer5"}'
# 預期: data = "test.ntp.org"

# ⚠️ 還原原始值！
ubus call bbfdm.timemngr set '{"path":"Device.Time.NTPServer5","value":"<原始值>"}'
```

#### ADD / DEL 驗證

```bash
# 確認初始狀態
ubus call bbfdm.dhcpmngr instances '{"path":"Device.DHCPv4.Server.Pool.1.StaticAddress."}'
# 預期: 空

# 新增實例
ubus call bbfdm.dhcpmngr add '{"path":"Device.DHCPv4.Server.Pool.1.StaticAddress."}'
# 預期: data = "1"

# 確認新增
ubus call bbfdm.dhcpmngr instances '{"path":"Device.DHCPv4.Server.Pool.1.StaticAddress."}'
# 預期: StaticAddress.1

# 刪除實例
ubus call bbfdm.dhcpmngr del '{"path":"Device.DHCPv4.Server.Pool.1.StaticAddress.1."}'

# 確認刪除
ubus call bbfdm.dhcpmngr instances '{"path":"Device.DHCPv4.Server.Pool.1.StaticAddress."}'
# 預期: 空
```

#### OPERATE 驗證

```bash
# Ping 測試
ubus call bbfdm operate '{"path":"Device.IP.Diagnostics.IPPing()","action":"ping","input":{"Host":"8.8.8.8","NumberOfRepetitions":"3"}}'
# 預期: Status=Complete, SuccessCount=3

# Traceroute 測試
ubus call bbfdm operate '{"path":"Device.IP.Diagnostics.TraceRoute()","action":"traceroute","input":{"Host":"8.8.8.8","MaxHopCount":"5"}}'
# 預期: RouteHops 資料
```

### 8.3 核心模組驗證（按 JNAP 對應）

| 測試項目 | 指令 | 預期 |
|----------|------|------|
| Device Info | `ubus call bbfdm get '{"path":"Device.DeviceInfo.Manufacturer"}'` | "Linksys" |
| WiFi Radio | `ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.Radio."}'` | 2 radios 資料 |
| WiFi SSID | `ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.SSID."}'` | ❌ 已知 Bug — 回傳空 |
| WiFi AP | `ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.AccessPoint."}'` | 4 APs 資料 |
| AP Security | `ubus call bbfdm.wifidmd get '{"path":"Device.WiFi.AccessPoint.1.Security."}'` | ModeEnabled, KeyPassphrase |
| WAN IP | `ubus call bbfdm.netmngr get '{"path":"Device.IP.Interface."}'` | 多個 Interface 資料 |
| LAN DHCP | `ubus call bbfdm.dhcpmngr get '{"path":"Device.DHCPv4.Server.Pool.1."}'` | MinAddress, MaxAddress |
| Routing | `ubus call bbfdm.netmngr get '{"path":"Device.Routing.Router.1.IPv4Forwarding."}'` | 路由規則 |
| Hosts | `ubus call bbfdm.hostmngr get '{"path":"Device.Hosts.Host."}'` | 已連線裝置列表 |
| Firewall | `ubus call bbfdm.firewallmngr get '{"path":"Device.Firewall.Chain."}'` | 防火牆規則鏈 |
| NAT | `ubus call bbfdm.firewallmngr get '{"path":"Device.NAT."}'` | NAT 設定 |
| DNS | `ubus call bbfdm.dnsmngr get '{"path":"Device.DNS.Client.Server."}'` | DNS 伺服器 |
| Ethernet | `ubus call bbfdm.ethmngr get '{"path":"Device.Ethernet.Interface."}'` | 有線埠狀態 |
| Time | `ubus call bbfdm.timemngr get '{"path":"Device.Time."}'` | NTP, 時區, 當前時間 |
| Users | `ubus call bbfdm.usermngr get '{"path":"Device.Users."}'` | admin, user 帳戶 |
| Diagnostics | `ubus call bbfdm get '{"path":"Device.IP.Diagnostics."}'` | IPPing, TraceRoute 參數 |

### 8.4 Flutter 端對端測試

1. 啟動 Flutter 測試頁面（見第 5 節）
2. 連線到 `https://192.168.1.1`，密碼 `admin`
3. 依序測試：

| 步驟 | 操作 | 路徑/值 | 預期結果 |
|------|------|---------|----------|
| 1 | GET | `Device.DeviceInfo.Manufacturer` | "Linksys" |
| 2 | GET | `Device.WiFi.Radio.` | Radio.1 + Radio.2 資料 |
| 3 | GET | `Device.Hosts.Host.` | Host 列表（至少 1 筆） |
| 4 | GET | `Device.Time.CurrentLocalTime` | 當前時間 ISO 8601 |
| 5 | SET | Path: `Device.Time.NTPServer5`, Value: `test.ntp.org` | 成功更新 |
| 6 | GET | `Device.Time.NTPServer5` | "test.ntp.org" |
| 7 | SET | Path: `Device.Time.NTPServer5`, Value: `2.openwrt.pool.ntp.org` | 還原成功 |

---

## 9. 已知問題與限制

### 9.1 韌體 Bug

| ID | 嚴重度 | 說明 | 影響 |
|----|--------|------|------|
| BUG-001 | 🔴 Critical | `Device.WiFi.SSID.` 實例列舉回傳空 | 無法讀取 SSID 名稱 |
| BUG-002 | 🟡 Low | `Device.Firewall.` 頂層 GET 回傳空 | 需個別查詢子路徑 |

### 9.2 未實作的模組

以下 TR-181 路徑在此韌體版本中回傳 `fault 9005 (Invalid parameter name)`：

| 路徑 | 說明 | 影響的 JNAP |
|------|------|------------|
| `Device.DynamicDNS.` | 動態 DNS | getDDNSSettings |
| `Device.UPnP.` | UPnP 服務 | getUPnPSettings |
| `Device.QoS.` | 服務品質 | getQoSSettings |
| `Device.IPsec.` | IPsec VPN | getVPNService |
| `Device.SoftwareModules.` | 軟體模組 | getFirmwareUpdateSettings |
| `Device.X_LINKSYS_COM.` | 廠商擴充 | 多個 Linksys 專屬功能 |
| `Device.Firewall.ConnectionTracking.` | ALG 設定 | getALGSettings |
| `Device.LocalAgent.` | USP Agent 設定 | — |

### 9.3 usp-bridge 不會自動啟動

`usp-bridge` daemon 預設未啟用開機自動啟動。每次路由器重啟後需手動啟動：

```bash
/etc/init.d/usp-bridge start
```

設定開機自動啟動：
```bash
/etc/init.d/usp-bridge enable
```

### 9.4 API 路徑與規格不一致

| 規格書 | 實際路由器 |
|--------|-----------|
| `/api/auth/login` | `/api/v1/auth/login` |
| `/api/auth/logout` | `/api/v1/auth/logout` |
| `/api/usp` | `/api/v1/usp` |

### 9.5 CORS 限制

Flutter Web 開發環境（localhost）存取路由器（192.168.1.1）時會被 CORS 擋住。解決方式：

```bash
# 方式一：Chrome 關閉 CORS（開發用）
--disable-web-security --user-data-dir=/tmp/chrome-usp-test

# 方式二：路由器 lighttpd 加 CORS header（需韌體支援）
```

### 9.6 Protobuf 協定

USP bridge 只接受 binary protobuf 格式（`application/octet-stream`），不接受 JSON。這表示：
- 無法用 curl 直接發送 GET/SET 請求
- 必須透過 WASM client 或其他 protobuf 編碼工具
- Proto 定義檔位於：`/Users/austin.chang/linksys/feed_poc/usp-client/proto/usp.proto`

---

## 10. 常用路徑速查表

### 系統資訊

| 用途 | 路徑 |
|------|------|
| 製造商 | `Device.DeviceInfo.Manufacturer` |
| 型號 | `Device.DeviceInfo.ModelName` |
| 序號 | `Device.DeviceInfo.SerialNumber` |
| 韌體版本 | `Device.DeviceInfo.SoftwareVersion` |
| 硬體版本 | `Device.DeviceInfo.HardwareVersion` |
| 運行時間 | `Device.DeviceInfo.UpTime` |
| CPU 使用率 | `Device.DeviceInfo.ProcessStatus.CPUUsage` |
| 記憶體總量 | `Device.DeviceInfo.MemoryStatus.Total` |
| 記憶體可用 | `Device.DeviceInfo.MemoryStatus.Free` |

### WiFi

| 用途 | 路徑 |
|------|------|
| Radio 列表 | `Device.WiFi.Radio.` |
| Radio 1 頻道 | `Device.WiFi.Radio.1.Channel` |
| Radio 1 頻段 | `Device.WiFi.Radio.1.OperatingFrequencyBand` |
| Radio 1 啟用 | `Device.WiFi.Radio.1.Enable` |
| AP 安全模式 | `Device.WiFi.AccessPoint.1.Security.ModeEnabled` |
| AP 密碼 | `Device.WiFi.AccessPoint.1.Security.KeyPassphrase` |
| AP 連線裝置 | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.` |
| WPS 狀態 | `Device.WiFi.AccessPoint.1.WPS.Status` |

### 網路

| 用途 | 路徑 |
|------|------|
| LAN IP | `Device.IP.Interface.1.IPv4Address.1.IPAddress` |
| LAN 子網遮罩 | `Device.IP.Interface.1.IPv4Address.1.SubnetMask` |
| WAN 狀態 | `Device.IP.Interface.{i}.Status` (WAN interface) |
| DHCP 範圍起始 | `Device.DHCPv4.Server.Pool.1.MinAddress` |
| DHCP 範圍結束 | `Device.DHCPv4.Server.Pool.1.MaxAddress` |
| DHCP 租約時間 | `Device.DHCPv4.Server.Pool.1.LeaseTime` |
| DNS 伺服器 | `Device.DNS.Client.Server.` |
| 路由表 | `Device.Routing.Router.1.IPv4Forwarding.` |

### 連線裝置

| 用途 | 路徑 |
|------|------|
| 裝置列表 | `Device.Hosts.Host.` |
| 裝置 MAC | `Device.Hosts.Host.{i}.PhysAddress` |
| 裝置 IP | `Device.Hosts.Host.{i}.IPAddress` |
| 裝置名稱 | `Device.Hosts.Host.{i}.HostName` |
| 裝置在線 | `Device.Hosts.Host.{i}.Active` |
| 連線類型 | `Device.Hosts.Host.{i}.InterfaceType` |

### 防火牆

| 用途 | 路徑 |
|------|------|
| 防火牆啟用 | `Device.Firewall.Enable` |
| Port Forwarding | `Device.NAT.PortMapping.` |
| Port Triggering | `Device.NAT.PortTrigger.` |
| 防火牆規則鏈 | `Device.Firewall.Chain.` |

### 時間

| 用途 | 路徑 |
|------|------|
| 當前時間 | `Device.Time.CurrentLocalTime` |
| NTP 啟用 | `Device.Time.Enable` |
| NTP 伺服器 | `Device.Time.NTPServer1` ~ `NTPServer5` |
| 時區 | `Device.Time.LocalTimeZone` |

### 操作指令

| 用途 | 指令路徑 | 參數 |
|------|----------|------|
| Ping | `Device.IP.Diagnostics.IPPing()` | Host, NumberOfRepetitions, Timeout |
| Traceroute | `Device.IP.Diagnostics.TraceRoute()` | Host, MaxHopCount, Timeout |
| 重啟 | `Device.Reboot()` | (無) |
| 恢復原廠 | `Device.FactoryReset()` | (無) |

---

## 附錄 A: 完整 Python 測試腳本

適用於批次驗證所有 TR-181 路徑：

```bash
# 腳本位置
/tmp/probe_usp.py

# 執行方式（需在開發機上，已安裝 sshpass）
python3 /tmp/probe_usp.py
```

腳本功能：
- 透過 SSH 逐一查詢 42+ 個 TR-181 路徑
- 自動選擇正確的 bbfdm sub-daemon
- 回報每個路徑的資料量和可用性
- 按分類統計覆蓋率

## 附錄 B: 參考資料

| 資源 | 位置 |
|------|------|
| Phase 1 驗證報告 | `doc/usp/integration/phase1_router_datamodel_validation.md` |
| JNAP→TR-181 對應表 | `doc/jnap/jnap_tr181_mapping.md` |
| JNAP 使用清單 (140 actions) | `doc/jnap/jnap_commands_used.md` |
| TR-181 對應狀態 | `doc/usp/integration/tr181_mapping_status.md` |
| USP Bridge 規格 | `doc/usp/Specifications/usp-bridge-spec.md` |
| USP Auth 規格 | `doc/usp/Specifications/usp-auth-cgi-spec.md` |
| USP Protobuf 定義 | `../linksys/feed_poc/usp-client/proto/usp.proto` |
| WASM Client 源碼 | `../linksys/feed_poc/usp-client/src/` |
| Codegen 工具 | `tools/usp-codegen` |
| YAML 定義檔 | `doc/usp/definitions/` |
| Flutter 測試頁面 | `lib/main_usp_test.dart` |
