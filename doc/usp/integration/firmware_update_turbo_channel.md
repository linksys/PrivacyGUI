# Firmware Update via Turbo Channel — Investigation Report

> **Date:** 2026-03-20
> **Router FW:** 1.0.16.26013014 (M60TB-EU / PINNACLE 2.0)
> **Status:** Router side ready, Client side pending implementation

---

## 1. Overview

This report investigates the router firmware update mechanism, specifically the feasibility and gap analysis of using **Turbo Channel (WebSocket streaming)** as the firmware file transfer channel.

**Conclusion:** The router side has complete Turbo Channel infrastructure and firmware receiving capabilities. The client side needs WebSocket data plane and chunked upload logic.

---

## 2. Turbo Channel Architecture

Turbo Channel is a **mutually exclusive, dedicated WebSocket streaming channel** designed for high-bandwidth, low-latency operations (firmware upgrades, speed tests, etc.).

### 2.1 Dual-Layer Architecture

| Layer | Protocol | Route | Purpose |
|-------|----------|-------|---------|
| **Control Plane** | HTTP REST | Client → lighttpd → usp-bridge (:8083) | Manage channel lifecycle |
| **Data Plane** | WebSocket (binary) | Client → lighttpd (wstunnel) → OBUSPA (:9001) | **Bypasses usp-bridge**, direct to Agent |

### 2.2 Control Plane API

| Method | Path | Description | Response |
|--------|------|-------------|----------|
| `POST` | `/api/v1/turbo/start` | Acquire exclusive channel | `{"status":"granted","session_id":"..."}` |
| `POST` | `/api/v1/turbo/heartbeat` | Keep channel alive (PENDING→IN_USE) | `{"status":"ok"}` |
| `GET` | `/api/v1/turbo/status` | Query channel state | `{"state":"AVAILABLE\|IN_USE"}` |
| `POST` | `/api/v1/turbo/release` | Release channel | `{"status":"released"}` |

### 2.3 State Machine

```
AVAILABLE ──(start)──► PENDING ──(heartbeat)──► IN_USE ──(release)──► AVAILABLE
                          │                       │
                          ▼ timeout(6s)           ▼ idle(60s) / max(300s)
                       AVAILABLE               AVAILABLE
```

### 2.4 UCI Timeout Settings (`/etc/config/usp-bridge`)

```
config streaming 'channel'
    option pending_timeout '6'     # Auto-release if no heartbeat after start
    option idle_timeout '60'       # Auto-release if no heartbeat
    option max_duration '300'      # Maximum occupation: 5 minutes
```

### 2.5 WebSocket Data Plane Configuration

- **OBUSPA** listens on `0.0.0.0:9001` (WebSocket MTP, `EnableEncryption=0`)
- **lighttpd** uses `mod_wstunnel` to proxy `/usp-ws` → `127.0.0.1:9001` (binary frame)
- Connection path: `wss://<router>/usp-ws`

lighttpd config (`/etc/lighttpd/conf.d/30-proxy-bridge.conf`):
```
$HTTP["url"] =~ "^/usp-ws$" {
    wstunnel.server = ( "" => (( "host" => "127.0.0.1", "port" => 9001 )))
    wstunnel.frame-type = "binary"
}
```

OBUSPA UCI config:
```
obuspa.websocket_server=mtp
obuspa.websocket_server.Enable='1'
obuspa.websocket_server.Protocol='WebSocket'
obuspa.websocket_server.Port='9001'
obuspa.websocket_server.Path='/'
obuspa.websocket_server.EnableEncryption='0'
```

---

## 3. Router Firmware Update Mechanisms

### 3.1 Firmware Partition Status (Live Test Results)

The router has a dual-bank firmware layout:

| Partition | Name | Version | Status | Available |
|-----------|------|---------|--------|-----------|
| FirmwareImage.1 | _(empty)_ | _(empty)_ | Available | 1 |
| FirmwareImage.2 | 1.0.16 | 1.0.16.26013014 | **Active** | 1 |

- `ActiveFirmwareImage` → `Device.DeviceInfo.FirmwareImage.2`
- `BootFirmwareImage` → `Device.DeviceInfo.FirmwareImage.2`

> FirmwareImage.1 is currently empty and can serve as the write target for new firmware.

### 3.2 Path A: Standard `FirmwareImage.{i}.Download()` — URL Pull Model

```
Device.DeviceInfo.FirmwareImage.{i}.Download()

Input parameters:
  URL                  string    Router actively downloads firmware from this URL
  Username             string    HTTP Basic Auth username (optional)
  Password             string    HTTP Basic Auth password (optional)
  AutoActivate         bool      Auto-activate and reboot after download
  FileSize             uint      Expected file size (bytes)
  CheckSum             string    Checksum value
  CheckSumAlgorithm    string    Checksum algorithm (SHA-256, etc.)
  X_LINKSYS_KeepConfig bool      Preserve user settings after firmware update
```

**Characteristics:**
- Router actively downloads firmware from the specified URL (pull model)
- Asynchronous operation; completion notified via `OperationComplete`
- Requires an HTTP file server accessible to the router
- **Does NOT need Turbo Channel**

**Use case:** Firmware hosted on a cloud server or LAN HTTP server

### 3.3 Path B: `X_LINKSYS_Download()` — Direct Push with Chunked Transfer

```
Device.LocalAgent.X_LINKSYS_Download()

Input parameters:
  Content          string    base64-encoded firmware chunk
  Filename         string    File name
  Filesize         uint      Total file size (bytes)
  Checksum         string    File checksum
  CommandKey       string    Operation identifier
  SequenceNumber   uint      Current chunk index (1-based)
  TotalFragment    uint      Total number of chunks

Output:
  Result           string    Operation result
  Error            string    Error message if failed
```

**Characteristics:**
- Client slices firmware into chunks, base64-encodes each, and pushes via USP Operate (push model)
- OBUSPA temporarily stores and reassembles fragments at `/tmp/obuspa/dw.fragment.*`
- Supports base64 encode/decode (`TEXT_UTILS_Base64StringToBinary`)
- Has SAR (Segmentation and Reassembly) support
- **This is the true purpose of Turbo Channel**

**Use case:** Upload firmware directly from the browser to the router without an intermediate server

### 3.4 Path C: `FirmwareImage.{i}.Activate()` — Activate Firmware

```
Device.DeviceInfo.FirmwareImage.{i}.Activate()

Input parameters:
  TimeWindow.{i}.Start       uint      Activation window start (seconds)
  TimeWindow.{i}.End         uint      Activation window end (seconds)
  TimeWindow.{i}.Mode        string    Mode (AnyTime, Immediately, etc.)
  TimeWindow.{i}.MaxRetries  uint      Max retry count
  TimeWindow.{i}.UserMessage string    User-facing message
  X_LINKSYS_KeepConfig       bool      Preserve user settings
```

**Purpose:** After firmware download completes, activate the specified partition's firmware and reboot.

---

## 4. Router-Side Live Verification

### 4.1 Turbo Channel Control Plane — All Passed

```bash
# Execute after SSH into router
TOKEN=$(curl -sk -X POST https://127.0.0.1/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"password":"admin"}' | jsonfilter -e '@.token')

# ✅ Initial state
curl -s http://127.0.0.1:8083/api/v1/turbo/status -H "Authorization: Bearer $TOKEN"
# → {"state":"AVAILABLE"}

# ✅ Acquire channel
curl -s -X POST http://127.0.0.1:8083/api/v1/turbo/start -H "Authorization: Bearer $TOKEN"
# → {"status":"granted","session_id":"066c03..."}

# ✅ Heartbeat (PENDING → IN_USE)
curl -s -X POST http://127.0.0.1:8083/api/v1/turbo/heartbeat -H "Authorization: Bearer $TOKEN"
# → {"status":"ok"}

# ✅ Confirm in use
curl -s http://127.0.0.1:8083/api/v1/turbo/status -H "Authorization: Bearer $TOKEN"
# → {"state":"IN_USE","owner":"066c03...","acquired_at":11259,"last_heartbeat":11259}

# ✅ Release
curl -s -X POST http://127.0.0.1:8083/api/v1/turbo/release -H "Authorization: Bearer $TOKEN"
# → {"status":"released"}

# ✅ Restored to available
curl -s http://127.0.0.1:8083/api/v1/turbo/status -H "Authorization: Bearer $TOKEN"
# → {"state":"AVAILABLE"}
```

### 4.2 WebSocket Data Plane — Infrastructure Ready

| Check Item | Result |
|------------|--------|
| OBUSPA listening on :9001 | ✅ `tcp 0.0.0.0:9001 LISTEN 17272/obuspa` |
| lighttpd wstunnel config | ✅ `/usp-ws` → `127.0.0.1:9001` (binary) |
| WebSocket MTP.3 Status | ✅ `Up` |
| WebSocket MTP.3 Port | ✅ `9001` |
| WebSocket MTP.3 Encryption | ✅ `0` (unencrypted; TLS handled by lighttpd) |

### 4.3 FirmwareImage Data Model — Readable

```
Device.DeviceInfo.FirmwareImage.1.Status    = Available  (empty partition)
Device.DeviceInfo.FirmwareImage.2.Status    = Active     (1.0.16.26013014)
Device.DeviceInfo.ActiveFirmwareImage       = Device.DeviceInfo.FirmwareImage.2
Device.DeviceInfo.BootFirmwareImage         = Device.DeviceInfo.FirmwareImage.2
Device.DeviceInfo.SoftwareVersion           = 1.0.16.26013014
```

### 4.4 System Resources

| Resource | Size | Available |
|----------|------|-----------|
| /tmp (tmpfs) | 206MB | ~200MB |
| /overlay | 70MB | ~65MB |
| RAM | 422MB | ~143MB |

> Firmware images are typically 30–80MB; /tmp space is sufficient.

---

## 5. Client-Side Current Implementation

### 5.1 Completed

| Component | Location | Description |
|-----------|----------|-------------|
| Turbo control plane API | `lib/core/usp/services/usp_bridge_client_web.dart:341-373` | `turboStart()`, `turboHeartbeat()`, `turboStatus()`, `turboRelease()` |
| FirmwareImage data model | `lib/generated/firmware_images.g.dart` | `FirmwareImages.fetch()` static method |
| FirmwareImage YAML definition | `definitions/core/firmware_images.yaml` | Multi-instance model |
| FirmwareImage UI Model | `lib/page/_shared/models/system_info_ui_model.dart` | `FirmwareImageUIModel` |
| FirmwareImage Service | `lib/page/_shared/services/usp_device_service.dart` | `buildFirmwareImageUIModels()` |
| SystemInfo Provider | `lib/page/admin/providers/system_info_data_provider.dart` | `_fetchFirmwareImages()` |
| SSE turbo_channel event routing | `lib/core/usp/services/sse_event_router.dart:63` | Currently log-only, not processed |
| TR-181 path registration | `lib/generated/tr181_paths.g.dart` | Download/Activate paths known |

### 5.2 Gaps

| # | Gap | Priority | Description |
|---|-----|----------|-------------|
| 1 | **WebSocket connection capability** | **P0** | WASM client (`web/usp_client.js`) has no WebSocket API. Need to add `wss://<router>/usp-ws` connection for sending/receiving binary protobuf |
| 2 | **USP protobuf over WebSocket** | **P0** | Protobuf encode/decode currently only goes through HTTP→bridge→UDS path. Need to enable WebSocket direct-to-OBUSPA path |
| 3 | **File chunking + base64 encoding** | **P1** | Split firmware binary into appropriately sized chunks, base64-encode each as `Content` parameter |
| 4 | **`X_LINKSYS_Download()` Operate wrapper** | **P1** | Sequentially send N Operate calls with `SequenceNumber=1..N`, `TotalFragment=N` |
| 5 | **`FirmwareImage.Activate()` wrapper** | **P1** | Trigger activation + reboot after download completes |
| 6 | **Turbo lifecycle manager** | **P1** | Complete Dart-layer manager for start → heartbeat timer → transfer → release (Dart `UspBridgeClient` already has control plane methods) |
| 7 | **Progress tracking** | **P2** | `SequenceNumber / TotalFragment` provides percentage; needs UI callback |
| 8 | **File Picker UI** | **P2** | Browser file input → read binary → feed into chunking pipeline |
| 9 | **Error handling & retry** | **P2** | Chunk failure retry, Turbo timeout handling, Checksum verification |
| 10 | **Firmware file validation** | **P3** | Client-side pre-check (magic bytes, size, format) |

---

## 6. End-to-End Target Architecture

### 6.1 Recommended Flow (Turbo Channel + X_LINKSYS_Download)

```
Browser                    lighttpd              usp-bridge           OBUSPA
  │                           │                      │                  │
  │  1. POST /turbo/start ────┼─────────────────────►│ acquire channel   │
  │◄── {"status":"granted"} ──┼──────────────────────┤                  │
  │                           │                      │                  │
  │  2. POST /turbo/heartbeat ┼─────────────────────►│ PENDING→IN_USE   │
  │◄── {"status":"ok"} ───────┼──────────────────────┤                  │
  │                           │                      │                  │
  │  3. WSS /usp-ws ──────────┼► wstunnel ──────────────────────────────►│
  │◄── WebSocket connected ───┤                      │                  │
  │                           │                      │                  │
  │  4. USP Operate X_LINKSYS_Download               │                  │
  │     (Content=base64, Seq=1, Total=N) ──────────────────────────────►│
  │◄── OperateResp ────────────────────────────────────────────────────┤
  │     ...                   │                      │                  │
  │  N+3. USP Operate         │                      │                  │
  │     (Content=base64, Seq=N, Total=N) ──────────────────────────────►│
  │◄── OperateResp (Result=success) ───────────────────────────────────┤
  │                           │                      │  reassemble →    │
  │                           │                      │  /tmp/obuspa/    │
  │                           │                      │  dw.fragment.*   │
  │                           │                      │  → flash         │
  │                           │                      │                  │
  │  5. POST /turbo/release ──┼─────────────────────►│ release channel  │
  │                           │                      │                  │
  │  6. USP Operate (via HTTP/bridge, non-Turbo)     │                  │
  │     FirmwareImage.1.Activate(KeepConfig=true) ─────────────────────►│
  │◄── OperateResp ────────────────────────────────────────────────────┤
  │                           │                      │  reboot...       │
```

### 6.2 Alternative Flow (URL Pull, no Turbo needed)

```
Browser                    lighttpd              usp-bridge           OBUSPA
  │                           │                      │                  │
  │  1. Upload firmware to /tmp (or external HTTP server)               │
  │                           │                      │                  │
  │  2. USP Operate (via HTTP/bridge)                │                  │
  │     FirmwareImage.1.Download(                    │                  │
  │       URL="http://192.168.1.x/firmware.bin",     │                  │
  │       AutoActivate=true,                         │                  │
  │       X_LINKSYS_KeepConfig=true                  │                  │
  │     ) ─────────────────────────────────────────────────────────────►│
  │◄── OperateResp (async started) ────────────────────────────────────┤
  │                           │                      │                  │
  │  3. SSE OperationComplete notification           │                  │
  │◄── event: notification ───┤                      │                  │
  │                           │                      │  reboot...       │
```

---

## 7. Items Pending Verification

| # | Item | Verification Method | Risk |
|---|------|---------------------|------|
| 1 | `X_LINKSYS_Download()` actual chunk size limit | Send a small base64 chunk for testing | USP Record may have a size ceiling |
| 2 | `MaxUSPRecordSize=0` — does it mean unlimited? | Consult TR-369 specification | 0 might represent a default limit |
| 3 | WebSocket connection from browser to OBUSPA end-to-end | Test WS connection in browser DevTools | wstunnel may require specific subprotocol |
| 4 | Whether flash is auto-triggered after fragment reassembly | Observe router behavior after sending last fragment | May need an explicit Activate call |
| 5 | `X_LINKSYS_Download` Checksum algorithm | Test with MD5/SHA-256 | Not documented |
| 6 | Whether Turbo `max_duration` (300s) is sufficient for firmware upload | Estimate transfer time (80MB / WebSocket bandwidth) | May need to adjust UCI setting |
| 7 | `FirmwareImage.1.Download()` URL mode functional | Set up LAN HTTP server and test | Alternative approach validation |

---

## 8. Implementation Recommendations

### Phase 1: Verification Layer (Confirm Behavior via Router SSH)

1. Call `X_LINKSYS_Download()` via `obuspa` CLI with a small file to verify chunking logic
2. Confirm WebSocket subprotocol requirement (`Sec-WebSocket-Protocol: v1.usp`)
3. Confirm chunk size limits and base64 overhead

### Phase 2: WASM WebSocket Layer

1. Add WebSocket connection management to `web/usp_client.js`
2. Implement binary protobuf encode/decode over WebSocket
3. Dart binding layer (`UspService` or new `UspTurboService`)

### Phase 3: Firmware Transfer Logic

1. File chunking + base64 encoder
2. Sequential `X_LINKSYS_Download()` Operate caller
3. Turbo lifecycle manager (start → heartbeat timer → transfer → release)
4. Progress reporting callback

### Phase 4: UI Integration

1. Firmware update page (select file → validate → upload → progress → complete/reboot)
2. Integrate into Admin/Support page
3. Error handling and user notifications

---

## Appendix A: Router-Side Component Status Summary

| Component | Status | Verified | Notes |
|-----------|--------|----------|-------|
| Turbo control plane API (4 endpoints) | ✅ Tested | 2026-03-20 | State machine works correctly |
| WebSocket MTP.3 (:9001) | ✅ Status=Up | 2026-03-20 | lighttpd wstunnel configured |
| `FirmwareImage.{i}.Download()` | ✅ Path exists | 2026-03-20 | URL pull model, async |
| `FirmwareImage.{i}.Activate()` | ✅ Path exists | 2026-03-20 | Supports TimeWindow + KeepConfig |
| `X_LINKSYS_Download()` | ✅ Path exists | 2026-03-20 | Chunked push, base64 Content |
| OBUSPA SAR support | ✅ Present | 2026-03-20 | Segment/reassembly logic |
| Fragment temp storage | ✅ `/tmp/obuspa/dw.fragment.*` | 2026-03-20 | Confirmed via strings analysis |
| /tmp space | ✅ ~200MB | 2026-03-20 | Sufficient for firmware images |
| sysupgrade | ✅ `/sbin/sysupgrade` | 2026-03-20 | Standard OpenWrt flash tool |
| cgi-upload | ❌ Binary missing | 2026-03-20 | lighttpd has config but no actual CGI |

## Appendix B: `X_LINKSYS_Download()` Parameter Quick Reference

```yaml
operate: Device.LocalAgent.X_LINKSYS_Download()
inputs:
  Content:         # base64-encoded firmware chunk
  Filename:        # e.g. "firmware-1.0.17.bin"
  Filesize:        # total file size in bytes
  Checksum:        # file checksum (algorithm TBD)
  CommandKey:      # unique operation identifier
  SequenceNumber:  # current chunk index (1-based)
  TotalFragment:   # total number of chunks
outputs:
  Result:          # operation result
  Error:           # error message if failed
```

## Appendix C: `FirmwareImage.{i}.Download()` Parameter Quick Reference

```yaml
operate: Device.DeviceInfo.FirmwareImage.{i}.Download()
inputs:
  URL:                  # firmware download URL
  AutoActivate:         # auto activate after download (bool)
  Username:             # HTTP basic auth username
  Password:             # HTTP basic auth password
  FileSize:             # expected file size (bytes)
  CheckSum:             # expected checksum
  CheckSumAlgorithm:    # checksum algorithm (e.g. SHA-256)
  X_LINKSYS_KeepConfig: # preserve user config (bool)
```

## Appendix D: `FirmwareImage.{i}.Activate()` Parameter Quick Reference

```yaml
operate: Device.DeviceInfo.FirmwareImage.{i}.Activate()
inputs:
  TimeWindow.{i}.Start:       # activation window start (seconds)
  TimeWindow.{i}.End:         # activation window end (seconds)
  TimeWindow.{i}.Mode:        # AnyTime, Immediately, etc.
  TimeWindow.{i}.MaxRetries:  # max retry count
  TimeWindow.{i}.UserMessage: # user-facing message
  X_LINKSYS_KeepConfig:       # preserve user config (bool)
```
