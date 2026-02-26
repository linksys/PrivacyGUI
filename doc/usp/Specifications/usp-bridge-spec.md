# usp-bridge Specification

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |

---

## Overview

`usp-bridge` is a router-side daemon that bridges HTTP/SSE traffic from the UI to OBUSPA via Unix Domain Socket (UDS). It handles session management, subscription routing, request correlation, and turbo channel coordination.

### Purpose

- Bridge HTTP requests to OBUSPA's UDS MTP interface
- Provide SSE endpoint for USP notifications
- Manage session-to-subscription mappings
- Coordinate exclusive turbo channel access
- Handle request/response correlation

### Language

C (for minimal footprint on embedded devices)

### Dependencies

- libevent (event loop)
- libjansson (JSON parsing)
- OpenSSL (JWT validation, optional if lighttpd handles it)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        usp-bridge                           │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ HTTP Server │  │ SSE Manager │  │ Turbo Coordinator   │  │
│  │ (localhost) │  │             │  │                     │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                    │             │
│         └────────────────┼────────────────────┘             │
│                          │                                  │
│                   ┌──────┴──────┐                           │
│                   │ Session     │                           │
│                   │ Manager     │                           │
│                   └──────┬──────┘                           │
│                          │                                  │
│                   ┌──────┴──────┐                           │
│                   │ UDS Client  │                           │
│                   └──────┬──────┘                           │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   OBUSPA    │
                    │ (UDS MTP)   │
                    └─────────────┘
```

---

## HTTP API

### Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/usp` | POST | JWT | USP Request/Response |
| `/api/events` | GET | JWT | SSE notification stream |
| `/api/subscribe` | POST | JWT | Register subscription mapping |
| `/api/unsubscribe` | POST | JWT | Remove subscription mapping |
| `/api/turbo/status` | GET | JWT | Turbo channel availability |
| `/api/turbo/start` | POST | JWT | Acquire turbo channel |
| `/api/turbo/heartbeat` | POST | JWT | Turbo channel keepalive |
| `/api/turbo/release` | POST | JWT | Release turbo channel |
| `/api/health` | GET | None | Health check |

### POST /api/usp

Send a USP request to OBUSPA and receive the response.

**Request:**
```
POST /api/usp HTTP/1.1
Content-Type: application/x-protobuf
Cookie: usp_session=<JWT>

<binary USP Record>
```

**Response (200 OK):**
```
Content-Type: application/x-protobuf

<binary USP Record>
```

**Response (504 Gateway Timeout):**
```json
{
  "error": "timeout",
  "message": "Request timed out after 30 seconds"
}
```

### GET /api/events

Establish SSE connection for notifications.

**Request:**
```
GET /api/events HTTP/1.1
Cookie: usp_session=<JWT>
Accept: text/event-stream
```

**Response:**
```
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

event: connected
data: {"session_id": "sess_a1b2c3d4e5f67890"}

event: heartbeat
data: {}

event: notification
data: {"subscription_id": "sess_xxx-wifi", "record": "<base64>"}

event: turbo_channel
data: {"available": false, "state": "in_use", "session_id": "sess_xxx"}
```

### POST /api/subscribe

Register a subscription-to-session mapping.

**Request:**
```json
{
  "subscription_id": "sess_a1b2c3d4-wifi-status"
}
```

**Response:**
```json
{
  "status": "ok",
  "subscription_id": "sess_a1b2c3d4-wifi-status",
  "session_id": "sess_a1b2c3d4"
}
```

### POST /api/unsubscribe

Remove a subscription mapping.

**Request:**
```json
{
  "subscription_id": "sess_a1b2c3d4-wifi-status"
}
```

**Response:**
```json
{
  "status": "ok"
}
```

### GET /api/turbo/status

Check turbo channel availability.

**Response (available):**
```json
{
  "available": true
}
```

**Response (busy):**
```json
{
  "available": false,
  "state": "in_use",
  "current": {
    "operation": "packet_capture",
    "session_id": "sess_a1b2c3d4",
    "started_at": "2025-01-15T10:30:00Z"
  }
}
```

### POST /api/turbo/start

Acquire the turbo channel.

**Request:**
```json
{
  "operation": "packet_capture"
}
```

**Response (granted):**
```json
{
  "status": "granted",
  "channel_id": "tc_a1b2c3",
  "websocket_url": "wss://192.168.1.1/usp-ws?eid=controller%3A%3Alocalui-turbo",
  "controller_endpoint_id": "controller::localui-turbo",
  "pending_timeout_seconds": 6,
  "heartbeat_interval_seconds": 60
}
```

**Response (busy):**
```json
{
  "status": "busy",
  "current": {
    "operation": "packet_capture",
    "session_id": "sess_xxx",
    "started_at": "2025-01-15T10:30:00Z"
  }
}
```

### POST /api/turbo/heartbeat

Signal ongoing turbo channel activity.

**Response:**
```json
{
  "status": "ok",
  "remaining_seconds": 1500
}
```

### POST /api/turbo/release

Release the turbo channel.

**Response:**
```json
{
  "status": "released"
}
```

### GET /api/health

Health check endpoint.

**Response (200 OK):**
```json
{
  "status": "ok",
  "obuspa": "connected"
}
```

**Response (503 Service Unavailable):**
```json
{
  "status": "degraded",
  "obuspa": "disconnected"
}
```

---

## Internal Data Structures

### Session State

```c
typedef struct {
    char session_id[64];
    time_t created_at;
    time_t last_activity;
    int sse_fd_count;
    int sse_fds[MAX_SSE_PER_SESSION];
} session_t;

// Hash table: session_id -> session_t
```

### Subscription Mapping

```c
typedef struct {
    char subscription_id[128];
    char session_id[64];
} subscription_mapping_t;

// Hash table: subscription_id -> session_id
// Hash table: session_id -> list of subscription_ids
```

### Request Correlation

```c
typedef struct {
    char msg_id[64];
    int response_fd;
    time_t sent_at;
    bool is_operate;  // For extended timeout
} pending_request_t;

// Hash table: msg_id -> pending_request_t
```

### Turbo Channel State

```c
typedef enum {
    TURBO_AVAILABLE,
    TURBO_PENDING,
    TURBO_IN_USE
} turbo_state_t;

typedef struct {
    turbo_state_t state;
    char session_id[64];
    char operation[128];
    char channel_id[32];
    time_t started_at;
    time_t pending_since;
    time_t last_heartbeat;
} turbo_channel_t;
```

---

## UDS MTP Protocol

Communication with OBUSPA uses the USP UDS MTP frame format.

### Frame Format

```
┌─────────────────────────────────────┐
│ Sync: "_USP" (4 bytes)              │
├─────────────────────────────────────┤
│ Payload Length (4 bytes, big-endian)│
├─────────────────────────────────────┤
│ TLV Fields (variable)               │
└─────────────────────────────────────┘
```

### TLV Types

| Type | Value | Description |
|------|-------|-------------|
| Handshake | 0x01 | Endpoint ID (UTF-8 string) |
| Error | 0x02 | Error message (UTF-8 string) |
| USP Record | 0x03 | Protobuf-encoded USP Record |

### Connection Lifecycle

1. Connect to UDS socket
2. Send Handshake TLV with Controller Endpoint ID
3. Receive Handshake TLV with Agent Endpoint ID
4. Exchange USP Record TLVs

---

## Notification Routing

When OBUSPA sends a notification:

1. Parse USP Record to extract subscription ID
2. Look up session_id from subscription mapping
3. Look up active SSE connections for session
4. Fan-out: send to ALL SSE connections for that session
5. If no mapping or no connections, log and discard

### SSE Event Format

```c
void send_sse_notification(int fd, const char* sub_id, const uint8_t* record, size_t len) {
    char* b64 = base64_encode(record, len);
    fprintf(fd, "event: notification\n");
    fprintf(fd, "data: {\"subscription_id\":\"%s\",\"record\":\"%s\"}\n\n", sub_id, b64);
    fflush(fd);
    free(b64);
}
```

---

## Turbo Channel Coordination

### State Transitions

```
AVAILABLE ──► PENDING ──► IN_USE ──► AVAILABLE
     ▲            │           │          │
     │            │           │          │
     │            ▼           ▼          │
     └────── (timeout) ◄─────────────────┘
```

### Timeout Handling

| Timeout | Duration | Action |
|---------|----------|--------|
| Pending timeout | 6 seconds | Release if no heartbeat |
| Idle timeout | 5 minutes | Release if no heartbeat |
| Max duration | 30 minutes | Force release |

### Health Check

Periodic query to OBUSPA to verify WebSocket connection status:

```
GET Device.LocalAgent.Controller.[EndpointID=="controller::localui-turbo"].MTP.*.Status
```

If no MTP shows "Up", the WebSocket has closed.

---

## Configuration

### UCI: `/etc/config/usp-bridge`

```
config usp_bridge 'main'
    option listen_addr '127.0.0.1'
    option listen_port '8080'
    option obuspa_socket '/var/run/obuspa/uds.sock'
    option controller_endpoint_id 'controller::localui'
    option turbo_controller_endpoint_id 'controller::localui-turbo'
    option request_timeout '30'
    option operate_timeout '300'
    option heartbeat_interval '30'
    option session_grace_period '60'
    option max_sse_connections '10'
    option turbo_health_check_interval '10'
    option turbo_pending_timeout '6'
    option turbo_idle_timeout '300'
    option turbo_max_duration '1800'
```

### Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `listen_addr` | string | `127.0.0.1` | Bind address |
| `listen_port` | int | `8080` | HTTP port |
| `obuspa_socket` | string | `/var/run/obuspa/uds.sock` | OBUSPA UDS path |
| `controller_endpoint_id` | string | `controller::localui` | Normal controller ID |
| `turbo_controller_endpoint_id` | string | `controller::localui-turbo` | Turbo controller ID |
| `request_timeout` | int | `30` | Normal request timeout (seconds) |
| `operate_timeout` | int | `300` | Operate command timeout (seconds) |
| `heartbeat_interval` | int | `30` | SSE heartbeat interval (seconds) |
| `session_grace_period` | int | `60` | Session cleanup delay (seconds) |
| `max_sse_connections` | int | `10` | Max concurrent SSE connections |
| `turbo_health_check_interval` | int | `10` | Turbo health check interval (seconds) |
| `turbo_pending_timeout` | int | `6` | Pending state timeout (seconds) |
| `turbo_idle_timeout` | int | `300` | Idle timeout (seconds) |
| `turbo_max_duration` | int | `1800` | Max turbo duration (seconds) |

---

## Error Handling

### HTTP Error Codes

| Status | Meaning | When Used |
|--------|---------|-----------|
| 400 | Bad Request | Malformed request body |
| 401 | Unauthorized | Invalid or missing JWT |
| 404 | Not Found | Unknown endpoint |
| 503 | Service Unavailable | OBUSPA disconnected |
| 504 | Gateway Timeout | Request timeout |

### Logging

```c
#define LOG_ERR(fmt, ...)   syslog(LOG_ERR, "usp-bridge: " fmt, ##__VA_ARGS__)
#define LOG_WARN(fmt, ...)  syslog(LOG_WARNING, "usp-bridge: " fmt, ##__VA_ARGS__)
#define LOG_INFO(fmt, ...)  syslog(LOG_INFO, "usp-bridge: " fmt, ##__VA_ARGS__)
#define LOG_DEBUG(fmt, ...) syslog(LOG_DEBUG, "usp-bridge: " fmt, ##__VA_ARGS__)
```

---

## Build & Deployment

### Build Dependencies

- libevent-dev
- libjansson-dev
- OpenWRT SDK

### Makefile Target

```makefile
define Package/usp-bridge
  SECTION:=net
  CATEGORY:=Network
  TITLE:=USP HTTP/SSE to UDS Bridge
  DEPENDS:=+libevent2 +libjansson
endef
```

### Installation

- Binary: `/usr/bin/usp-bridge`
- Config: `/etc/config/usp-bridge`
- Init script: `/etc/init.d/usp-bridge`

### Service Management

```bash
# Start
/etc/init.d/usp-bridge start

# Stop
/etc/init.d/usp-bridge stop

# Enable at boot
/etc/init.d/usp-bridge enable
```

---

## Testing

### Unit Tests

- Session management (create, lookup, cleanup)
- Subscription mapping (add, remove, lookup)
- Request correlation (add, match, timeout)
- Turbo state machine (transitions, timeouts)

### Integration Tests

- End-to-end USP Get/Set via HTTP
- SSE notification delivery
- Turbo channel acquisition and release
- Multi-session handling

### Test Tools

```bash
# Health check
curl http://localhost:8080/api/health

# USP request (with test protobuf)
curl -X POST -H "Content-Type: application/x-protobuf" \
     --data-binary @test_get.pb \
     http://localhost:8080/api/usp

# SSE connection
curl -N -H "Accept: text/event-stream" \
     http://localhost:8080/api/events
```
