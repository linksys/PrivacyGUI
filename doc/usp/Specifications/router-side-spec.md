# USP-Driven UI Specification — Router Side

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |

---

## Overview

This specification defines a USP (User Services Platform, TR-369) driven web UI for OpenWRT-based WiFi routers. The architecture uses OBUSPA as the USP Agent and implements a minimal "Controller emulation" to enable browser-based management.

### Design Principles

1. **USP-native**: All configuration read/write operations use USP messages (protobuf-encoded)
2. **Security-first**: TLS-only external communications, JWT-based authentication
3. **Minimal footprint**: Suitable for resource-constrained embedded devices
4. **Stateless backend**: USP Bridge holds only transient session state; OBUSPA is the source of truth for device configuration
5. **Standard-compliant**: No vendor extensions to USP data model; session routing handled at transport layer
6. **Extensible**: Micro-frontend architecture for UI extensions
7. **Developer-friendly**: Backend handles transport complexity; UI works with USP abstractions
8. **Dual-transport**: HTTP/SSE for multi-tab normal operations; WebSocket turbo channel for high-bandwidth streaming

---

## Router Side

### Component Overview

| Component | Type | Purpose |
|-----------|------|---------|
| lighttpd | Daemon | HTTPS server, TLS termination, static files, reverse proxy, JWT validation, WebSocket proxy |
| Auth CGI | Ephemeral | Password validation, JWT token generation and refresh |
| USP Bridge | Daemon | HTTP/SSE to UDS MTP bridge, session management, subscription routing, turbo channel coordination |
| OBUSPA | Daemon | USP Agent implementation, source of truth for device configuration |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              UI/Browser                                     │
│  ┌─────────────────────────────────────┐  ┌──────────────────────────────┐  │
│  │      Normal Transport               │  │      Turbo Channel           │  │
│  │  ┌─────────────┐ ┌───────────────┐  │  │  ┌────────────────────────┐  │  │
│  │  │ USP Protobuf│ │ HTTP + SSE    │  │  │  │ USP Protobuf + WS      │  │  │
│  │  └──────┬──────┘ └───────┬───────┘  │  │  └───────────┬────────────┘  │  │
│  │         └────────┬───────┘          │  │              │               │  │
│  └──────────────────┼──────────────────┘  └──────────────┼───────────────┘  │
│                     │ HTTPS                              │ WSS              │
└─────────────────────┼────────────────────────────────────┼──────────────────┘
                      │                                    │
                      ▼                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                              lighttpd                                                                   │
│                                                                                                         │
│  TLS termination, static files, reverse proxy, JWT validation                                           │
│                                                                                                         │
│  /api/*  ──────────────────────────> USP Bridge via HTTP (:8080)                                        │
│  /usp-ws ──────────────────────────> OBUSPA via WebSocket (:8443)                                       │
│  /*      ──────────────────────────> Static files (/www/usp-ui/)                                        │
└───────────────────────┬─────────────────────────────┬───────────────────────────────────────┬───────────┘
                        │ HTTP (localhost)            │ HTTP (localhost)                      │
                        ▼                             ▼                                       │
┌─────────────────────────────────────┐    ┌──────────────────────────────────┐               │
│          Auth CGI                   │    │         USP Bridge Daemon        │               │
│                                     │    │                                  │               │
│  Validate password via UCI          │    │  HTTP server on 127.0.0.1:8080   │               │
│  Generate JWT (includes             │    │                                  │               │
│   session_id, endpoint IDs)         │    │  Endpoints:                      │               │
│                                     │    │    POST /api/usp   (USP req)     │               │
└─────────────────────────────────────┘    │    GET  /api/events (SSE)        │               │
                                           │    POST /api/subscribe           │               │
                                           │    POST /api/unsubscribe         │               │
                                           │    GET  /api/turbo/status        │               │
                                           │    POST /api/turbo/start         │               │
                                           │    GET  /api/health              │               │
                                           │                                  │               │
                                           │  Internal state (in-memory):     │               │
                                           │    - Session → SSE connections   │               │
                                           │    - Session → Subscription IDs  │               │
                                           │    - Subscription → Session      │               │
                                           │    - Request correlation         │               │
                                           │    - Turbo channel state         │               │
                                           │                                  │               │
                                           │  Persistent state: None          │               │
                                           └─────────────────┬────────────────┘               │
                                                             │                                |
                                                             │ UDS MTP                        |
                                                             ▼                                |
                                           ┌──────────────────────────────────┐               |
                                           │            OBUSPA                │               |
                                           │         (USP Agent)              │<──────────────┘
                                           │                                  │ Websocket (localhost)
                                           │  Controllers:                    │
                                           │    - controller::localui (UDS)   │
                                           │    - controller::localui-turbo   │
                                           │        (WebSocket)               │
                                           │                                  │
                                           │  MTPs:                           │
                                           │    - UDS on /var/run/obuspa/     │
                                           │        uds.sock                  │
                                           │    - WebSocket on 127.0.0.1:8443 │
                                           │                                  │
                                           │  Source of truth for:            │
                                           │    - Device configuration        │
                                           │    - Subscriptions               │
                                           │    - Data model state            │
                                           └──────────────────────────────────┘
```

### Endpoint Identifiers

| Identifier | Format | Storage | Purpose |
|------------|--------|---------|---------|
| Agent Endpoint ID | `agent::<serial>` | Derived from device | Identifies USP Agent |
| Controller Endpoint ID | `controller::localui` | UCI config | Identifies local UI controller (normal transport) |
| Turbo Controller Endpoint ID | `controller::localui-turbo` | UCI config | Identifies local UI controller (turbo channel) |

The Controller Endpoint IDs are fixed per router and returned to the UI upon successful authentication.

---

## Authentication

### Login Flow

```
Browser                              lighttpd                      Auth CGI
   │                                     │                            │
   │── POST /api/auth/login ────────────>│                            │
   │   {password}                        │── CGI exec ───────────────>│
   │                                     │                            │
   │                                     │   Validate password        │
   │                                     │   Generate session_id      │
   │                                     │   Generate JWT             │
   │                                     │                            │
   │                                     │<── Response ───────────────│
   │<── 200 OK ──────────────────────────│                            │
   │   Set-Cookie: usp_session=<JWT>     │                            │
   │   {                                 │                            │
   │     controller_endpoint_id,         │                            │
   │     turbo_controller_endpoint_id,   │                            │
   │     agent_endpoint_id               │                            │
   │   }                                 │                            │
```

### JWT Cookie Configuration

The JWT is delivered as an HttpOnly cookie for automatic multi-tab session sharing:

```
Set-Cookie: usp_session=<JWT>; HttpOnly; Secure; SameSite=Strict; Path=/api
```

| Attribute | Value | Purpose |
|-----------|-------|---------|
| `HttpOnly` | Yes | Prevents JavaScript access (XSS protection) |
| `Secure` | Yes | HTTPS only |
| `SameSite` | `Strict` | CSRF protection |
| `Path` | `/api` | Cookie sent only to API endpoints |

**Multi-tab behavior**: All browser tabs on the same origin automatically share the cookie. No explicit token coordination is needed.

**Mobile apps**: Do not use cookies. Instead, extract the JWT from the login response body and use the `Authorization: Bearer <JWT>` header for all requests.

### Login Response

**Success (200 OK)**:
```json
{
  "controller_endpoint_id": "controller::localui",
  "turbo_controller_endpoint_id": "controller::localui-turbo",
  "agent_endpoint_id": "agent::ABC123456",
  "token": "<JWT>"
}
```

**Note**: The `token` field is included in the response body for mobile apps. Browser-based UIs should ignore this field and rely on the cookie.

**Failure (401 Unauthorized)**:
```json
{
  "error": "invalid_password"
}
```

### JWT Refresh

JWTs have a limited lifetime (default: 1 hour). The UI must refresh before expiry.

**Endpoint**: `POST /api/auth/refresh`

**Request**: No body required. JWT is read from cookie (browsers) or Authorization header (mobile).

**Response (200 OK)**:
```
Set-Cookie: usp_session=<new JWT>; HttpOnly; Secure; SameSite=Strict; Path=/api

{
  "token": "<new JWT>"
}
```

**Grace period**: The Auth CGI accepts expired JWTs within `jwt_refresh_grace` seconds (default: 300) for refresh operations only. This prevents lockout due to clock skew or brief network interruptions.

**Session continuity**: The `session_id` is preserved across refreshes. Only `iat` and `exp` claims change.

---

## Session Management

### Session Identity

Each authenticated UI session is assigned a unique `session_id`. This identifier correlates HTTP requests with SSE connections and subscription ownership.

**Session ID Generation**:

The `session_id` must be globally unique, including across router reboots. It must include a random component to prevent collisions with sessions from before a reboot.

**Format**: `sess_<timestamp_hex><random_hex>`

**Implementation** (Auth CGI):
```c
void generate_session_id(char *buf, size_t len) {
    uint32_t timestamp = (uint32_t)time(NULL);
    uint32_t random_val;
    getrandom(&random_val, sizeof(random_val), 0);
    snprintf(buf, len, "sess_%08x%08x", timestamp, random_val);
}
```

**Session lifecycle**:
1. User authenticates → Auth CGI generates `session_id`, embeds in JWT, sets cookie
2. Browser tabs automatically share cookie (and thus `session_id`)
3. UI establishes SSE connection(s); USP Bridge extracts `session_id` from cookie
4. UI learns `session_id` from SSE `connected` event
5. UI creates subscriptions with TTL, registers mappings via `/api/subscribe`
6. USP Bridge routes notifications by looking up subscription→session→SSE connections
7. UI periodically refreshes subscription TTL
8. UI periodically refreshes JWT before expiry (cookie updated automatically)
9. On disconnect, subscriptions auto-expire via TTL

**JWT Claims**:
```json
{
  "iat": 1704067200,
  "exp": 1704070800,
  "role": "admin",
  "session_id": "sess_a1b2c3d4e5f67890"
}
```

### Session-Per-Device Model

Each login creates a new, independent session. This is by design:

- **Multiple devices**: A user on their phone and laptop will have separate sessions (separate `session_id` values)
- **Multiple browser tabs**: Share the same session (same cookie, same `session_id`)
- **No session sharing across devices**: Each device authenticates independently

This model ensures:
- Clear session ownership for subscriptions and turbo channel
- No cross-device notification deduplication complexity
- Simple session cleanup on device disconnect

**Note**: The Auth CGI always generates a fresh `session_id` on login. There is no mechanism to "resume" a session from another device.

### Multiple Connections per Session

A single session may have multiple SSE connections (e.g., multiple browser tabs). The USP Bridge maintains:

```
session_id → Set<SSE connection fd>
```

When a notification arrives, it is delivered to **all** SSE connections for that session (fan-out). This ensures all tabs remain synchronized. See [Multi-Tab Notification Handling](#multi-tab-notification-handling) for UI-side deduplication guidance.

### Session Timeout

Session liveness is determined by SSE connection state:

- At least one SSE connection open → session alive
- All SSE connections closed → session dead (after grace period)
- Grace period: 60 seconds (allows for reconnection attempts)

The server sends SSE heartbeats every 30 seconds. These serve as TCP keepalives and allow clients to detect server-side failures.

**Timing note**: `session_grace_period` should be at least 2× `heartbeat_interval` to account for network latency and reconnection attempts.

### Session Recovery

On session loss (browser refresh, network interruption, USP Bridge restart):

1. UI detects SSE connection closed
2. UI reconnects SSE (cookie is automatically included)
3. USP Bridge validates JWT from cookie, extracts `session_id`
4. UI receives `connected` event with `session_id`
5. UI recreates all subscriptions (check existence, Add if needed, register mapping)
6. UI issues `Get` operations to refresh any cached state
7. Normal operation resumes

**Design principle**: Treat reconnection identically to initial connection. The UI should not attempt to "recover" existing subscriptions—instead, verify and recreate them.

---

## USP Operations Endpoint

### Overview

The primary endpoint for USP request/response operations. All standard USP messages (Get, Set, Add, Delete, Operate, GetSupportedDM) are sent through this endpoint.

### Endpoint

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/usp` | POST | JWT (cookie or header) | Send USP Request, receive USP Response |

### Request

```
POST /api/usp
Cookie: usp_session=<JWT>
Content-Type: application/x-protobuf

<binary USP Record>
```

Or for mobile apps:
```
POST /api/usp
Authorization: Bearer <JWT>
Content-Type: application/x-protobuf

<binary USP Record>
```

The request body contains a protobuf-encoded USP Record wrapping a USP Message.

### Response

**Success (200 OK)**:
```
Content-Type: application/x-protobuf

<binary USP Record>
```

The response body contains the protobuf-encoded USP Response.

**Timeout (504 Gateway Timeout)**:
```json
{
  "error": "timeout",
  "message": "Request timed out after 30 seconds"
}
```

### Timeouts

| Operation Type | Timeout | Configuration |
|----------------|---------|---------------|
| Get, Set, Add, Delete | 30s | `request_timeout` |
| Operate | 300s | `operate_timeout` |

The USP Bridge detects Operate messages and applies the extended timeout automatically.

### Message Flow

```
Browser                              USP Bridge                    OBUSPA
   │                                     │                            │
   │── POST /api/usp ───────────────────>│                            │
   │   (USP Record with Get request)     │                            │
   │                                     │── UDS frame ──────────────>│
   │                                     │   (USP Record)             │
   │                                     │                            │
   │                                     │<── UDS frame ──────────────│
   │                                     │   (USP Response)           │
   │<── 200 OK ──────────────────────────│                            │
   │   (USP Record with Get response)    │                            │
```

### Request Correlation

The USP Bridge correlates requests and responses using the `msg_id` field in the USP Message header. Each request must have a unique `msg_id` within the session.

### Search Expressions

The USP Bridge accepts standard USP search expressions in path names, as defined in TR-369 Section 3.5. This enables queries and modifications targeting specific object instances.

**Supported patterns**:

| Pattern | Example | Description |
|---------|---------|-------------|
| Unique key search | `[ID=="value"]` | Match by unique key parameter |
| Wildcard | `*` | Match all instances |
| Instance number | `.1.`, `.2.` | Specific instance by number |

**Examples**:

```
# Get specific subscription by ID
Device.LocalAgent.Subscription.[ID=="sess_abc123-wifi"].TimeToLive

# Get all WiFi SSIDs
Device.WiFi.SSID.*.SSID

# Set specific instance
Device.WiFi.Radio.1.Enable
```

**TTL Refresh example**:

To refresh a subscription's TTL without knowing its instance number:

```
Set Device.LocalAgent.Subscription.[ID=="sess_abc123-wifi"].TimeToLive = 3600
```

The USP Bridge forwards these expressions unchanged to OBUSPA, which resolves them per TR-369 requirements.

---

## Subscriptions

### Overview

USP subscriptions enable the UI to receive notifications when data model values change or events occur. This section describes the subscription lifecycle, session mapping, and automatic cleanup via TTL.

### Subscription Requirements

All subscriptions created by the UI **must** include:

1. **Unique ID**: Identifies the subscription for mapping and management
2. **TimeToLive**: Non-zero value for automatic cleanup (see TTL Management)

### Subscription ID Format

The UI prefixes all subscription IDs with the `session_id` to ensure uniqueness across sessions. For example:
- UI requests subscription with ID: `wifi-status`
- Actual ID stored in OBUSPA: `sess_a1b2c3d4e5f67890-wifi-status`

This prevents collisions when:
- Multiple browser sessions create subscriptions with the same logical ID
- Sessions from before a router reboot have subscriptions that haven't expired yet

### Subscription-to-Session Mapping

**Design principle**: USP messages remain pure and standard-compliant. Session routing is handled entirely within the USP Bridge via a separate registration API.

**Storage**: Mappings are held in USP Bridge memory:

```
subscription_id → session_id
session_id → Set<subscription_id>
```

### Subscription Registration Endpoint

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/subscribe` | POST | Register subscription-to-session mapping |
| `/api/unsubscribe` | POST | Remove mapping |

**Register Request**:
```json
{
  "subscription_id": "sess_a1b2c3d4e5f67890-wifi-status"
}
```

Session ID is extracted from the JWT (cookie or header).

**Register Response**:
```json
{
  "status": "ok",
  "subscription_id": "sess_a1b2c3d4e5f67890-wifi-status",
  "session_id": "sess_a1b2c3d4e5f67890"
}
```

### Subscription Creation Flow

Subscription creation follows a check-then-create pattern to handle reconnection gracefully:

```
Browser                              USP Bridge                    OBUSPA
   │                                     │                            │
   │  Step 1: Check if subscription exists                            │
   │                                     │                            │
   │── GET subscription ────────────────>│                            │
   │   Device.LocalAgent.Subscription.   │                            │
   │     [ID=="sess_xxx-wifi-status"].ID │                            │
   │                                     │── UDS Get ────────────────>│
   │                                     │<── Response ───────────────│
   │<── Response (exists or not) ────────│                            │
   │                                     │                            │
   │  Step 2: Create if not exists                                    │
   │                                     │                            │
   │── Add subscription ────────────────>│                            │
   │   (only if Step 1 returned empty)   │── UDS Add ────────────────>│
   │                                     │<── Response ───────────────│
   │<── Response ────────────────────────│                            │
   │                                     │                            │
   │  Step 3: Register mapping (always)                               │
   │                                     │                            │
   │── POST /api/subscribe ─────────────>│                            │
   │   {"subscription_id": "..."}        │ (USP Bridge stores mapping)│
   │<── 200 OK ──────────────────────────│                            │
```

**Why check first?** On reconnection with the same session, subscriptions may still exist in OBUSPA (TTL not expired). Creating duplicates would waste resources. The check ensures idempotent subscription setup.

### TTL Management

Subscriptions use the USP `TimeToLive` parameter for automatic cleanup.

**Parameters**:

| Parameter | Recommended Value | Purpose |
|-----------|-------------------|---------|
| `TimeToLive` | 3600 (1 hour) | Auto-delete subscription if not refreshed |
| Refresh interval | 1800 (30 min) | UI refreshes TTL before expiration |

**Cleanup scenarios**:

| Scenario | Cleanup Mechanism |
|----------|-------------------|
| Graceful disconnect | UI deletes subscriptions explicitly |
| Browser crash | TTL expires, OBUSPA auto-deletes |
| Network failure | TTL expires, OBUSPA auto-deletes |
| USP Bridge restart | UI recreates subscriptions on reconnect |

### Subscription Deletion

**Automatic deletion** (TTL expiration):

1. OBUSPA deletes subscription when TTL reaches zero
2. USP Bridge mapping becomes orphaned (subscription_id no longer exists)
3. Next notification lookup fails silently (subscription gone)
4. Orphaned mappings are harmless and cleaned up lazily or on session close

**Orphaned mapping handling**: Log at debug level when a notification arrives for an unmapped or orphaned subscription. This is expected behavior, not an error.

---

## Notifications (SSE)

### Overview

OBUSPA sends notifications for subscribed events. The USP Bridge receives these via UDS MTP and routes them to the appropriate browser session(s) via SSE.

### SSE Connection

**Endpoint**: `GET /api/events`

**Authentication**:
- Browsers: `Cookie: usp_session=<JWT>` (automatic)
- Mobile apps: `Authorization: Bearer <JWT>`

**Response**: Server-Sent Events stream

### SSE Event Types

| Event | Purpose | Data Format |
|-------|---------|-------------|
| `connected` | Confirms SSE established | `{"session_id": "xxx"}` |
| `heartbeat` | Keepalive (every 30s) | `{}` |
| `notification` | USP Notify from OBUSPA | `{"subscription_id": "xxx", "record": "<base64>"}` |
| `turbo_channel` | Turbo channel state changed | `{"available": bool, "state": "...", ...}` |

### Session ID Discovery

Since the JWT is HttpOnly (not readable by JavaScript), the UI discovers its `session_id` from the SSE `connected` event:

```
event: connected
data: {"session_id": "sess_a1b2c3d4e5f67890"}
```

The UI must store this `session_id` for use in subscription ID prefixing and turbo channel ownership checks.

### Multi-Tab Notification Handling

When multiple browser tabs share a session, each receives a copy of every notification (fan-out). The UI is responsible for handling this appropriately.

**For state updates** (ValueChange, ObjectCreation, ObjectDeletion):
- Each tab independently applies the state change
- No deduplication needed—applying the same state multiple times is idempotent

**For event-driven side effects** (user-visible alerts, sounds, logging):
- UI should deduplicate to avoid duplicate toasts/alerts across tabs
- Recommended pattern: Use `BroadcastChannel` API or `localStorage` events for cross-tab coordination
- Deduplication key: `subscription_id + ":" + hash(notification_payload)` or use a timestamp if included in the notification

### Undeliverable Notifications

If a notification arrives for a subscription with no mapping or no active SSE connections:

1. Log the event (debug level)
2. Discard the notification

This is acceptable because subscriptions have TTL and will auto-delete.

---

## Turbo Channel

### Overview

Certain high-bandwidth streaming operations require a dedicated WebSocket channel directly to OBUSPA, bypassing the USP Bridge. This "turbo channel" provides direct streaming capability while normal HTTP/SSE operations continue in parallel.

### Characteristics

- **Exclusive**: Only one turbo channel active at a time (device-wide)
- **Operation-scoped**: Channel exists for duration of specific operation
- **Parallel**: Does not disrupt normal HTTP/SSE transport
- **Automatic cleanup**: Channel released when operation completes or WebSocket closes
- **Direct path**: WebSocket connects directly to OBUSPA via lighttpd proxy
- **TR-369 compliant**: Uses standard USP WebSocket MTP protocol

### TR-369 WebSocket MTP Compliance

The turbo channel WebSocket connection MUST comply with TR-369 WebSocket MTP requirements:

**Client Requirements (UI)**:
- Include `Sec-WebSocket-Protocol: v1.usp` header in handshake (R-WS.9, R-WS.10)
- Include endpoint ID in request URI query: `?eid=controller::localui-turbo` (R-WS.10b)
- Endpoint ID must be URI-encoded with percent characters escaped as `%25` (R-WS.10c)
- Send `WebSocketConnectRecord` after connection established (R-WS.8)
- Wait for OBUSPA's `WebSocketConnectRecord` before sending USP Records

**Server Requirements (lighttpd/OBUSPA)**:
- Respond with `Sec-WebSocket-Protocol: v1.usp` header (R-WS.11)
- Reject connections missing the required protocol header (R-WS.12a)

**lighttpd WebSocket Proxy Configuration**:

lighttpd proxies WebSocket connections to OBUSPA's WebSocket MTP endpoint. The proxy must preserve protocol headers:

```
# /etc/lighttpd/conf.d/usp-ws.conf
server.modules += ("mod_proxy", "mod_wstunnel")

$HTTP["url"] =~ "^/usp-ws" {
    proxy.server = ("" => (("host" => "127.0.0.1", "port" => "5683")))
    proxy.header = (
        "upgrade" => "enable"
    )
}
```

**Note**: OBUSPA must be configured to listen for WebSocket MTP connections on the specified port. See OBUSPA configuration section.

### Turbo Channel State

USP Bridge maintains turbo channel state in memory:
```c
struct turbo_channel {
    enum { AVAILABLE, PENDING, IN_USE } state;
    char session_id[64];
    char operation[128];
    time_t started_at;
    time_t pending_since;      // When PENDING state began
    time_t last_heartbeat;     // Last heartbeat from UI
};
```

**State transitions**:
- `AVAILABLE` → `PENDING`: On `/api/turbo/start` request
- `PENDING` → `IN_USE`: When first `/api/turbo/heartbeat` received from owning session
- `PENDING` → `AVAILABLE`: If no heartbeat received within `turbo_pending_timeout` (6s)
- `IN_USE` → `AVAILABLE`: When `/api/turbo/release` called
- `IN_USE` → `AVAILABLE`: When WebSocket closes (detected via health check)
- `IN_USE` → `AVAILABLE`: When no heartbeat received within `turbo_idle_timeout` (5 min)
- `IN_USE` → `AVAILABLE`: When `turbo_max_duration` exceeded (30 min)

**Note**: The USP Bridge cannot observe WebSocket traffic directly (lighttpd proxies to OBUSPA), so UI heartbeats via `/api/turbo/heartbeat` are required to detect idle channels and confirm the WebSocket connection is established.

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/turbo/status` | GET | Check turbo channel availability |
| `/api/turbo/start` | POST | Request turbo channel for operation |
| `/api/turbo/heartbeat` | POST | Signal ongoing turbo channel activity |
| `/api/turbo/release` | POST | Explicitly release turbo channel |
| `/usp-ws` | GET (Upgrade) | WebSocket endpoint to OBUSPA (via lighttpd) |

### Status Request

```
GET /api/turbo/status
Cookie: usp_session=<JWT>
```

**Response (available)**:
```json
{
  "available": true
}
```

**Response (pending)**:
```json
{
  "available": false,
  "state": "pending",
  "current": {
    "operation": "packet_capture",
    "session_id": "sess_a1b2c3d4",
    "started_at": "2025-01-15T10:30:00Z"
  }
}
```

**Response (in use)**:
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

### Start Request

```
POST /api/turbo/start
Cookie: usp_session=<JWT>
Content-Type: application/json

{
  "operation": "packet_capture"
}
```

**Response (granted)**:
```json
{
  "status": "granted",
  "channel_id": "tc_a1b2c3",
  "websocket_url": "wss://192.168.1.1/usp-ws?eid=controller%3A%3Alocalui-turbo",
  "controller_endpoint_id": "controller::localui-turbo",
  "operation": "packet_capture",
  "pending_timeout_seconds": 6,
  "heartbeat_interval_seconds": 60
}
```

**Note**: The `websocket_url` includes the properly URI-encoded endpoint ID in the query string per TR-369 R-WS.10b.

**Response (busy)**:
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

### Heartbeat Request

The UI MUST send periodic heartbeats while the turbo channel is in use. The USP Bridge cannot observe WebSocket traffic directly (lighttpd proxies to OBUSPA), so heartbeats serve two purposes:
1. **PENDING → IN_USE transition**: The first heartbeat confirms the WebSocket connection is established
2. **Idle detection**: Ongoing heartbeats prevent idle timeout

```
POST /api/turbo/heartbeat
Cookie: usp_session=<JWT>
```

**Response**:
```json
{
  "status": "ok",
  "remaining_seconds": 1500
}
```

**Error (not owner)**:
```json
{
  "status": "error",
  "error": "not_owner",
  "message": "Turbo channel owned by different session"
}
```

**Heartbeat requirements**:
- The recommended heartbeat interval is returned in the `/api/turbo/start` response as `heartbeat_interval_seconds`
- This value is calculated server-side as `turbo_idle_timeout / 5` (default: 300/5 = 60 seconds)
- UI MUST send the first heartbeat immediately after WebSocket handshake completes
- UI MUST send heartbeats at least every `heartbeat_interval_seconds` to prevent idle timeout
- Only the session that acquired the channel may send heartbeats

### Release Request

Explicitly releases the turbo channel when the operation completes. This provides immediate channel availability without waiting for health check detection.

```
POST /api/turbo/release
Cookie: usp_session=<JWT>
```

**Response (success)**:
```json
{
  "status": "released"
}
```

**Error (not owner)**:
```json
{
  "status": "error",
  "error": "not_owner",
  "message": "Turbo channel owned by different session"
}
```

**Error (no channel)**:
```json
{
  "status": "error",
  "error": "no_channel",
  "message": "No active turbo channel"
}
```

**Behavior**:
- Only the session that acquired the channel may release it
- On success, immediately transitions state to `AVAILABLE`
- Sends SSE event to all clients: `event: turbo_channel`, `data: {"available": true}`
- The WebSocket connection to OBUSPA may still be open; this endpoint only releases the reservation

**Note**: Explicit release is preferred over relying on heartbeat timeout or health check detection, as it makes the channel immediately available for other sessions.

### Channel Release Detection

The USP Bridge is not in the WebSocket data path, so it detects channel release through multiple mechanisms:

**1. Explicit release**: UI calls `/api/turbo/release` for immediate channel availability.

**2. Heartbeat timeout**: If no heartbeat received within `turbo_idle_timeout` (5 minutes), mark channel as available. This handles:
- UI completed operation but forgot to close WebSocket
- UI crashed or lost network connectivity
- Buggy clients that don't properly release channels

**3. OBUSPA health check**: Periodic query (every `turbo_health_check_interval` seconds):
- Query: `Device.LocalAgent.Controller.[EndpointID=="controller::localui-turbo"].MTP.*.Status`
- If no MTP shows "Up" status, the WebSocket has closed

**4. Maximum duration**: After `turbo_max_duration` (30 minutes), channel is forcibly released regardless of heartbeat or connection state.

**On release**:
1. Mark `turbo_channel.state = AVAILABLE`
2. Clear session_id, operation, timestamps
3. Send SSE event to all clients: `event: turbo_channel`, `data: {"available": true}`

### SSE Notifications

When turbo channel state changes, USP Bridge notifies all SSE clients:

**Channel acquired (pending)**:
```
event: turbo_channel
data: {"available": false, "state": "pending", "operation": "packet_capture", "session_id": "sess_xxx"}
```

**Channel active (in use)**:
```
event: turbo_channel
data: {"available": false, "state": "in_use", "operation": "packet_capture", "session_id": "sess_xxx"}
```

**Channel released**:
```
event: turbo_channel
data: {"available": true}
```

### Health Check

A simple endpoint for load balancers and monitoring systems.

**Endpoint**: `GET /api/health`

**Authentication**: None required

**Response** (200 OK):
```json
{
  "status": "ok",
  "obuspa": "connected"
}
```

**Response** (503 Service Unavailable):
```json
{
  "status": "degraded",
  "obuspa": "disconnected"
}
```

The health endpoint checks:
1. USP Bridge is running
2. UDS connection to OBUSPA is established

---

## Cookie and CORS Configuration

### Browser Authentication

Browsers use the `usp_session` cookie for authentication. The cookie is set by Auth CGI on login and automatically included in all requests to `/api/*`.

**SSE Connection**: The browser's `EventSource` API requires `withCredentials: true` to send cookies for cross-origin requests:

```javascript
const eventSource = new EventSource('/api/events', { withCredentials: true });
```

**Same-origin deployment** (recommended): If the Flutter web app is served from the same origin as the API (same host/port), no special CORS configuration is needed.

**Cross-origin deployment**: If the UI is served from a different origin:

```
# /etc/lighttpd/conf.d/cors.conf
setenv.add-response-header = (
    "Access-Control-Allow-Origin" => "https://router.local",
    "Access-Control-Allow-Credentials" => "true"
)
```

### Mobile App Authentication

Mobile apps use the `Authorization: Bearer <JWT>` header directly. Native HTTP clients handle this without cookie restrictions.

**Token storage**: Mobile apps must securely store the JWT (e.g., iOS Keychain, Android Keystore) and include it in all API requests.

**Token refresh**: Mobile apps must proactively refresh the JWT before expiry by calling `/api/auth/refresh` with the current token in the Authorization header.

---

## Recovery Scenarios

### USP Bridge Restart

| Component | State | Recovery Action |
|-----------|-------|-----------------|
| SSE connections | Lost | Clients detect disconnect, reconnect |
| Session mappings | Lost | Clients recreate subscriptions |
| Subscriptions | Preserved (in OBUSPA) | Check existence, skip creation if exists |
| Request correlation | Lost | In-flight requests timeout, clients retry |
| Turbo channel state | Lost | Rebuilt on next health check or heartbeat |

### OBUSPA Restart

| Component | State | Recovery Action |
|-----------|-------|-----------------|
| SSE connections | Preserved | No action needed |
| Session mappings | Preserved | No action needed |
| Subscriptions | Lost | UI must recreate subscriptions |
| Device config | Reloaded from UCI | UI should refresh state |
| Turbo channel | Closed | UI detects WebSocket close, USP Bridge detects on health check |

### Browser Crash / Network Failure

| Component | State | Recovery Action |
|-----------|-------|-----------------|
| SSE connections | Closed | USP Bridge removes from session |
| Session mappings | Preserved (briefly) | Cleared after session timeout |
| Subscriptions | Preserved (with TTL) | Auto-expire via TTL |
| Turbo channel | WebSocket closed | Released on next health check or via heartbeat timeout |

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

| Option | Default | Description |
|--------|---------|-------------|
| `listen_addr` | `127.0.0.1` | Bind address (localhost only) |
| `listen_port` | `8080` | HTTP port for lighttpd proxy |
| `obuspa_socket` | `/var/run/obuspa/uds.sock` | OBUSPA UDS socket path |
| `controller_endpoint_id` | `controller::localui` | USP Controller ID (normal) |
| `turbo_controller_endpoint_id` | `controller::localui-turbo` | USP Controller ID (turbo) |
| `request_timeout` | `30` | Normal request timeout (seconds) |
| `operate_timeout` | `300` | Operate command timeout (seconds) |
| `heartbeat_interval` | `30` | SSE heartbeat interval (seconds) |
| `session_grace_period` | `60` | Time before session cleanup (≥2× heartbeat) |
| `max_sse_connections` | `10` | Maximum concurrent SSE connections |
| `turbo_health_check_interval` | `10` | Turbo channel health check interval (seconds) |
| `turbo_pending_timeout` | `6` | Max time in PENDING state before auto-release (seconds) |
| `turbo_idle_timeout` | `300` | Idle time before turbo channel force-close (seconds) |
| `turbo_max_duration` | `1800` | Maximum turbo channel duration (seconds) |

**Note**: The `turbo_idle_timeout` is measured from the last `/api/turbo/heartbeat` call, not from WebSocket traffic (which USP Bridge cannot observe). The recommended heartbeat interval returned to clients is `turbo_idle_timeout / 5`.

### UCI: `/etc/config/usp-auth`

```
config auth 'main'
    option password_hash '$argon2id$...'
    option jwt_secret_file '/etc/usp-ui/jwt.key'
    option jwt_expiry '3600'
    option jwt_refresh_grace '300'
    option jwt_cookie_name 'usp_session'
    option controller_endpoint_id 'controller::localui'
    option turbo_controller_endpoint_id 'controller::localui-turbo'
    option agent_endpoint_id 'agent::ABC123456'
```

---

## Appendix A: UDS MTP Frame Format

Per USP TR-369 specification:

**Header** (8 bytes):
- Sync: `_USP` (4 bytes, ASCII: 0x5f 0x55 0x53 0x50)
- Payload Length: 4 bytes, big-endian, total length of all TLV fields

**TLV Field**:
- Type: 1 byte
  - `0x01`: Handshake (contains Endpoint ID as UTF-8 string)
  - `0x02`: Error (contains error message as UTF-8 string)
  - `0x03`: USP Record (contains protobuf-encoded USP Record)
- Length: 4 bytes, big-endian
- Value: Variable length

---

## Appendix B: Error Codes

### HTTP-Level Errors

| Status | Meaning | When Used |
|--------|---------|-----------|
| 400 | Bad Request | Malformed USP Record |
| 401 | Unauthorized | Invalid or expired JWT (beyond grace period) |
| 503 | Service Unavailable | OBUSPA connection down |
| 504 | Gateway Timeout | Request timeout |

### USP-Level Errors

USP error codes (7000-7999) are returned within the USP Response message. See TR-369 for complete definitions.

Common codes:

| Code | Meaning |
|------|---------|
| 7000 | Message failed |
| 7001 | Message not supported |
| 7004 | Invalid arguments |
| 7010 | Request denied |
| 7012 | Invalid path |
| 7022 | Command failure |
| 7026 | Invalid value |
