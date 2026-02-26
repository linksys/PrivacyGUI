# USP-Driven UI Project — Package Architecture

## Package Overview

| # | Package | Language | Description |
|---|---------|----------|-------------|
| 1 | `usp-bridge` | C | Router daemon: HTTP/SSE to UDS bridge, session management, turbo channel coordination |
| 2 | `usp-auth-cgi` | C | Authentication CGI: password validation, JWT generation/refresh |
| 3 | `usp-lighttpd-config` | Config | lighttpd configuration: TLS, reverse proxy, WebSocket proxy |
| 4 | `usp-client` | Rust | Core client library with language bindings (Dart, TS) and JSON API |
| 5 | `usp-definitions` | YAML | API definitions (parameters, presets) + optional transforms (formulas, maps, converters) |
| 6 | `usp-codegen` | C | Code generator: translates YAML definitions to Dart/TS/Swift |
| 7 | `usp-llm-proxy` | C | AI chat proxy: MQTT to LLM, JSON validation, retry loop |
| 8 | `usp-ui-flutter` | Flutter | Main UI application |

---

## Architecture Diagrams

### User Experience View

This diagram shows the data flow from the user's perspective, serialized to highlight the different steps.

```mermaid
flowchart LR
    subgraph user["User"]
        ui["usp-ui-flutter"]:::pink
        ai-input["AI Chat Input"]:::green
    end

    subgraph client-side["Client Side"]
        usp-client["usp-client"]:::pink
    end

    subgraph router["Router"]
        lighttpd["lighttpd"]:::darkblue
        auth-cgi["usp-auth-cgi"]:::red
        llm-proxy["usp-llm-proxy"]:::red
        bridge["usp-bridge"]:::red
        obuspa["obuspa"]:::darkblue
    end

    subgraph cloud["Cloud/Local"]
        llm["LLM"]:::darkblue
    end

    %% Authentication flow
    ui -->|"1. Login request"| lighttpd
    lighttpd -->|"2. Auth"| auth-cgi
    auth-cgi -->|"3. JWT token"| lighttpd
    lighttpd -->|"4. Token"| ui

    %% Standard request flow (through usp-client, HTTP)
    ui -->|"5. USP request"| usp-client
    usp-client -->|"6. HTTPS + protobuf"| lighttpd
    lighttpd -->|"7. Forward"| bridge
    bridge -->|"8. UDS"| obuspa
    obuspa -->|"9. Response"| bridge
    bridge -->|"10. Response"| lighttpd
    lighttpd -->|"11. Response"| usp-client
    usp-client -->|"12. Typed data"| ui

    %% Turbo channel flow (WebSocket via usp-client)
    ui -.->|"T1. Acquire channel"| usp-client
    usp-client -.->|"T2. HTTP /api/turbo/start"| bridge
    bridge -.->|"T3. Channel granted"| usp-client
    usp-client -.->|"T4. WebSocket (/usp-ws)"| lighttpd
    lighttpd -.->|"T5. Proxy"| obuspa

    %% AI flow (HTTP JSON, NOT through usp-client)
    ai-input -->|"A1. HTTP JSON (text query)"| lighttpd
    lighttpd -->|"A2. Forward"| llm-proxy
    llm-proxy -->|"A3. MQTT"| llm
    llm -->|"A4. JSON response"| llm-proxy
    llm-proxy -->|"A5. Validate + retry"| llm-proxy
    llm-proxy -->|"A6. Validated JSON"| lighttpd
    lighttpd -->|"A7. HTTP JSON (ready to execute)"| ui
    ui -.->|"A8. Execute via usp-client"| usp-client

    %% Styling
    classDef green fill:#22c55e,stroke:#166534,color:#fff
    classDef orange fill:#f97316,stroke:#c2410c,color:#fff
    classDef pink fill:#f0abfc,stroke:#a21caf,color:#000
    classDef darkblue fill:#1e3a5f,stroke:#0f172a,color:#fff
    classDef red fill:#dc2626,stroke:#991b1b,color:#fff
```

### Developer View

This diagram shows the component relationships and what needs to be developed.

```mermaid
flowchart TB
    %% Build-time components (inputs)
    definitions["usp-definitions\n(YAML)"]:::green
    codegen["usp-codegen"]:::pink

    %% AI input
    ai-chat["AI chat\n(user text)"]:::green

    subgraph ui["UI code"]
        subgraph flutter-container["usp-ui-flutter"]
            gen-code["Generated code\n(classes + extensions)"]:::orange
            dart-plugin["Dart plugin (typed API)"]:::pink
            json-plugin["JSON plugin (execute_json)"]:::pink
            gen-json["Generated JSON (from LLM)"]:::orange
        end
    end

    client["usp-client"]:::pink

    subgraph router["Router"]
        lighttpd["lighttpd"]:::darkblue
        lighttpd-config["usp-lighttpd-config"]:::red
        auth-cgi["usp-auth-cgi"]:::red
        llm-proxy["usp-llm-proxy (validation + retry)"]:::red
        bridge["usp-bridge"]:::red
        obuspa["obuspa"]:::darkblue

        subgraph external["External (MQTT)"]
            llm["LLM\n(cloud/local)"]:::darkblue
        end
    end

    %% AI flow (through router, all via lighttpd)
    ai-chat --> lighttpd
    lighttpd --> llm-proxy
    llm-proxy <--> llm
    llm-proxy -->|"validated JSON"| lighttpd
    lighttpd --->|"HTTP response"| gen-json

    %% Build-time flow
    definitions --> codegen
    codegen --> gen-code

    %% Typed path: Generated code → Dart plugin → usp-client
    gen-code --> dart-plugin
    dart-plugin --> client

    %% JSON path: Generated JSON → JSON plugin → usp-client
    json-plugin --> client
    gen-json --> json-plugin
        
    %% Router internal structure
    lighttpd-config ~~~ lighttpd
    lighttpd --> auth-cgi
    lighttpd --> bridge
    bridge --> obuspa

    %% UI to Router (HTTP via usp-client)
    client --> lighttpd
    flutter-container --> lighttpd

    %% UI to Router (Turbo channel: WebSocket via usp-client)
    client -.->|"WebSocket (/usp-ws)"| lighttpd
    lighttpd -.->|"WS proxy"| obuspa

    %% Styling
    classDef green fill:#22c55e,stroke:#166534,color:#fff
    classDef orange fill:#f97316,stroke:#c2410c,color:#fff
    classDef pink fill:#f0abfc,stroke:#a21caf,color:#000
    classDef darkblue fill:#1e3a5f,stroke:#0f172a,color:#fff
    classDef red fill:#dc2626,stroke:#991b1b,color:#fff
```

**Legend:**
- 🟢 **Green**: Inputs (developer-provided definitions, user input)
- 🟠 **Orange**: Build-time or runtime generated 
- 🟣 **Pink**: Framework libraries (to be developed)
- 🔴 **Red**: Router packages (to be developed)
- 🔵 **Dark blue**: Existing/external components (lighttpd, obuspa, LLM)

---

## Workflow: Standard Call

A pre-defined UI operation (e.g., fetching WiFi settings).

```mermaid
sequenceDiagram
    participant UI as usp-ui-flutter
    participant GEN as Generated Dart<br/>(from usp-codegen)
    participant BIND as Dart FFI Binding<br/>(in usp-client)
    participant RUST as Rust Core<br/>(in usp-client)
    participant ROUTER as Router<br/>(/api/usp)
    
    UI->>GEN: WifiSettings.fetch(client)
    Note over GEN: Knows TR-181 paths:<br/>Device.WiFi.SSID.1.SSID<br/>Device.WiFi.SSID.1.Enable
    
    GEN->>BIND: client.get(["Device.WiFi.SSID.1.SSID", ...])
    Note over BIND: Convert Dart types to C types<br/>List of String to char**
    
    BIND->>RUST: usp_client_get(handle, paths_ptr, len)
    Note over RUST: Build USP GetRequest protobuf<br/>Serialize to binary
    
    RUST->>ROUTER: HTTP POST /api/usp<br/>Content-Type: application/x-protobuf<br/>[binary protobuf]
    
    ROUTER-->>RUST: HTTP 200<br/>[binary protobuf response]
    Note over RUST: Deserialize USP GetResponse<br/>Extract parameter values
    
    RUST-->>BIND: Return C string (JSON result)
    Note over BIND: Convert C types to Dart<br/>char* to String to Map
    
    BIND-->>GEN: GetResult with params map
    Note over GEN: Parse into typed object
    
    GEN-->>UI: WifiSettings(ssid: "MyNetwork", ...)
```

### Interfaces — Standard Call

| From | To | Interface | Data Format |
|------|-----|-----------|-------------|
| UI | Generated Code | Dart method call | Typed Dart objects |
| Generated Code | Dart Binding | Dart method call | `List<String>`, `Map<String, String>` |
| Dart Binding | Rust Core | C ABI (FFI) | `char**`, `int` (C types) |
| Rust Core | Router | HTTP POST | Binary protobuf |

---

## Workflow: Dynamic Call (AI-generated)

An AI-generated query for parameters not in the standard UI. The AI processing is router-proxied using a **two-phase workflow**:

1. **Phase 1 (Query)**: User question → LLM generates `dynamic_call` JSON
2. **Phase 2 (Interpret)**: Execution results → LLM generates human-readable answer

```mermaid
sequenceDiagram
    participant USER as User
    participant CHAT as AI Chat Interface<br/>(in usp-ui-flutter)
    participant LIGHT as lighttpd
    participant PROXY as usp-llm-proxy
    participant LLM as LLM<br/>(cloud/local)
    participant BIND as JSON Plugin<br/>(in usp-ui-flutter)
    participant CLIENT as usp-client
    participant ROUTER as Router<br/>(/api/usp)

    USER->>CHAT: "What channel is my WiFi using?"

    Note over CHAT,LLM: Phase 1: Query Generation

    CHAT->>LIGHT: POST /api/ai/chat<br/>{"message": "What channel..."}
    LIGHT->>PROXY: Forward request

    PROXY->>LLM: MQTT: user query + context
    Note over LLM: Generates dynamic_call JSON
    LLM-->>PROXY: JSON: {"dynamic_call":<br/>{"version":"1.0",...}}

    Note over PROXY: 1. Schema validation ✓<br/>2. Whitelist check ✓<br/>3. Limits check ✓

    alt Validation fails
        PROXY->>LLM: MQTT: retry with error details
        LLM-->>PROXY: Corrected JSON
    end

    PROXY-->>LIGHT: Validated response
    LIGHT-->>CHAT: HTTP 200<br/>{"success":true,<br/>"dynamic_call":{...}}

    Note over CHAT: Execute dynamic_call

    CHAT->>BIND: Execute dynamic_call JSON
    BIND->>CLIENT: client.execute_json(json_string)

    CLIENT->>ROUTER: HTTP POST /api/usp<br/>Content-Type: application/x-protobuf
    ROUTER-->>CLIENT: HTTP 200<br/>[protobuf response]

    CLIENT-->>BIND: JSON result
    BIND-->>CHAT: {"Device.WiFi.Radio.1.Channel":"6"}

    Note over CHAT,LLM: Phase 2: Result Interpretation

    CHAT->>LIGHT: POST /api/ai/interpret<br/>{"original_message":"...",<br/>"results":{...}}
    LIGHT->>PROXY: Forward request

    PROXY->>LLM: MQTT: results + original query
    Note over LLM: Generates human-readable<br/>interpretation
    LLM-->>PROXY: {"message":"Your WiFi is<br/>using channel 6..."}

    PROXY-->>LIGHT: Response
    LIGHT-->>CHAT: HTTP 200<br/>{"message":"Your WiFi is using<br/>channel 6..."}

    CHAT-->>USER: "Your WiFi is using channel 6.<br/>This is a good choice..."
```

### Interfaces — Dynamic Call

| From | To | Interface | Data Format |
|------|-----|-----------|-------------|
| AI Chat | lighttpd | HTTP POST `/api/ai/chat` | JSON (text query) |
| lighttpd | usp-llm-proxy | Internal | JSON |
| usp-llm-proxy | LLM | MQTT | JSON (query + context) |
| LLM | usp-llm-proxy | MQTT | JSON (dynamic_call) |
| usp-llm-proxy | lighttpd | Internal | JSON (validated) |
| lighttpd | AI Chat | HTTP response | JSON (dynamic_call) |
| AI Chat | JSON Plugin | Dart method call | `String` (JSON) |
| JSON Plugin | usp-client | C ABI (FFI) | `char*` (JSON string) |
| usp-client | Router | HTTP POST | Binary protobuf |
| AI Chat | lighttpd | HTTP POST `/api/ai/interpret` | JSON (results + original query) |
| LLM | usp-llm-proxy | MQTT | JSON (human-readable message) |
| lighttpd | AI Chat | HTTP response | JSON (message for user) |

---

## Workflow: Turbo Channel Operation

High-bandwidth streaming operations (e.g., packet capture) use a WebSocket connection managed by `usp-client` and proxied through lighttpd to OBUSPA, bypassing usp-bridge for data transfer. OBUSPA only listens on localhost; lighttpd handles external TLS termination.

**Key design decision:** The WebSocket is initiated by `usp-client` (Rust), not directly by the UI. This keeps all transport logic in one place and ensures consistent behavior across all language bindings (Dart, TypeScript, Swift, etc.).

```mermaid
sequenceDiagram
    participant UI as usp-ui-flutter
    participant CLIENT as usp-client<br/>(Rust)
    participant BRIDGE as usp-bridge
    participant LIGHT as lighttpd
    participant OBUSPA as OBUSPA<br/>(localhost:8443)

    UI->>CLIENT: acquireTurboChannel("packet_capture")
    CLIENT->>BRIDGE: POST /api/turbo/start<br/>{"operation": "packet_capture"}

    alt Channel available
        BRIDGE-->>CLIENT: {"status": "ok",<br/>"websocket_url": "wss://.../usp-ws",<br/>"channel_id": "..."}

        Note over BRIDGE: Channel state: PENDING<br/>(6 second timeout)

        CLIENT->>LIGHT: WebSocket upgrade /usp-ws<br/>Sec-WebSocket-Protocol: v1.usp
        LIGHT->>OBUSPA: Proxy to localhost:8443
        OBUSPA-->>LIGHT: WebSocket handshake OK
        LIGHT-->>CLIENT: WebSocket handshake OK

        CLIENT->>LIGHT: WebSocketConnectRecord
        LIGHT->>OBUSPA: Forward
        OBUSPA-->>LIGHT: WebSocketConnectRecord (agent)
        LIGHT-->>CLIENT: Forward

        CLIENT->>BRIDGE: POST /api/turbo/heartbeat
        Note over BRIDGE: Channel state: IN_USE
        CLIENT-->>UI: TurboChannel handle

        loop Every 60 seconds (background thread in usp-client)
            CLIENT->>BRIDGE: POST /api/turbo/heartbeat
        end

        UI->>CLIENT: operate("PacketCapture()", inputs)
        CLIENT->>LIGHT: USP Operate (protobuf)
        LIGHT->>OBUSPA: Forward

        loop Streaming data
            OBUSPA-->>LIGHT: USP Notify (protobuf)
            LIGHT-->>CLIENT: Forward
            CLIENT-->>UI: Event callback
        end

        UI->>CLIENT: close()
        CLIENT->>LIGHT: WebSocket close
        LIGHT->>OBUSPA: Close
        CLIENT->>BRIDGE: POST /api/turbo/release
        Note over BRIDGE: Channel state: AVAILABLE

    else Channel busy
        BRIDGE-->>CLIENT: {"status": "busy",<br/>"current": {"operation": "...",<br/>"session_id": "..."}}
        CLIENT-->>UI: TurboChannelBusyException
    end
```

### Interfaces — Turbo Channel

| From | To | Interface | Data Format |
|------|-----|-----------|-------------|
| UI | usp-client | FFI call `usp_client_turbo_acquire()` | C ABI |
| usp-client | usp-bridge | HTTP POST `/api/turbo/start` | JSON |
| usp-bridge | usp-client | HTTP response | JSON (WebSocket URL) |
| usp-client | lighttpd | WebSocket `/usp-ws` | Binary protobuf (USP Records) |
| lighttpd | OBUSPA | WebSocket proxy | Binary protobuf (USP Records) |
| usp-client | usp-bridge | HTTP POST `/api/turbo/heartbeat` | (empty) |
| usp-client | usp-bridge | HTTP POST `/api/turbo/release` | (empty) |
| usp-client | UI | Event callback | JSON (via registered callback) |

### Turbo vs Standard Transport

| Aspect | Standard (HTTP/SSE) | Turbo (WebSocket) |
|--------|---------------------|-------------------|
| Connection | Via usp-bridge | Via usp-client → lighttpd → OBUSPA |
| Use case | Normal operations | High-bandwidth streaming |
| Multi-client | Supported (usp-bridge manages) | Single client at a time |
| Examples | Get/Set params, subscriptions | Packet capture, log export |
| WebSocket owner | N/A | usp-client (Rust) |

---

## Component Details

### 1. `usp-bridge` (C)

Router-side daemon that bridges HTTP/SSE to OBUSPA via UDS.

**API Endpoints Exposed:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/usp` | POST | USP Request/Response |
| `/api/events` | GET | SSE notification stream |
| `/api/subscribe` | POST | Register subscription mapping |
| `/api/unsubscribe` | POST | Remove subscription mapping |
| `/api/turbo/status` | GET | Turbo channel availability |
| `/api/turbo/start` | POST | Acquire turbo channel |
| `/api/turbo/heartbeat` | POST | Turbo channel keepalive |
| `/api/turbo/release` | POST | Release turbo channel |
| `/api/health` | GET | Health check |

---

### 2. `usp-auth-cgi` (C)

Authentication CGI for JWT management.

**API Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/auth/login` | POST | Authenticate, return JWT |
| `/api/auth/refresh` | POST | Refresh JWT |
| `/api/auth/logout` | POST | Invalidate session |

---

### 3. `usp-lighttpd-config` (Config)

lighttpd configuration files for routing.

**Routing Rules:**
| Path | Target |
|------|--------|
| `/api/auth/*` | Auth CGI |
| `/api/ai/*` | usp-llm-proxy (localhost:8081) |
| `/api/*` | usp-bridge (localhost:8080) |
| `/usp-ws` | OBUSPA WebSocket (localhost:8443) |
| `/*` | Static files (/www/usp-ui/) |

---

### 4. `usp-client` (Rust)

Core client library with multiple interfaces.

**C ABI (for FFI):**
```c
// Lifecycle
UspClient* usp_client_new(const char* base_url);
void usp_client_free(UspClient* client);

// Authentication
const char* usp_client_login(UspClient* client, const char* password);
const char* usp_client_logout(UspClient* client);

// Typed interface (for standard calls via Dart/TS bindings)
const char* usp_client_get(UspClient* client, const char** paths, int len);
const char* usp_client_set(UspClient* client, const char** keys, const char** vals, int len);
const char* usp_client_add(UspClient* client, const char* path, const char** keys, const char** vals, int len);
const char* usp_client_delete(UspClient* client, const char* path);
const char* usp_client_operate(UspClient* client, const char* command, const char** keys, const char** vals, int len);

// JSON interface (for dynamic calls)
const char* usp_client_execute_json(UspClient* client, const char* json_request);

// Turbo channel (WebSocket managed by usp-client)
const char* usp_client_turbo_status(UspClient* client);
void* usp_client_turbo_acquire(UspClient* client, const char* operation);
const char* usp_client_turbo_operate(void* channel, const char* command, const char* inputs_json);
void usp_client_turbo_set_callback(void* channel, void (*callback)(const char* event_json));
void usp_client_turbo_close(void* channel);

// Memory management
void usp_string_free(const char* s);
```

**Outputs:**
| Target | File | Use |
|--------|------|-----|
| Native lib | `libusp_client.so/.dylib/.dll` | FFI from Dart, Swift, etc. |
| WASM | `usp_client.wasm` + JS glue | Web browsers |
| CLI | `usp-cli` | Testing/debugging |

---

### 5. `usp-definitions` (YAML)

YAML files defining USP parameter groupings, presets, and optional transforms.

**Structure:**
```
usp-definitions/
├── definitions/
│   ├── core/
│   │   ├── hardware_info.yaml
│   │   ├── wifi_settings.yaml
│   │   ├── dns_settings.yaml        ← includes presets
│   │   └── ...
│   ├── extensions/
│   │   ├── parental_controls.yaml
│   │   └── ...
│   └── vendor/
│       └── linksys/
│           └── velop_nodes.yaml
└── transforms/                       ← optional
    ├── core/
    │   ├── download_diagnostics.yaml
    │   └── wan_status.yaml
    └── vendor/
```

**Key principle:** Transforms are optional. If a definition doesn't need derived values, no transform file is required.

**Definition content:**
- Parameters (TR-181 path mappings)
- Presets (configuration templates for user selection)
- Subscriptions (real-time notifications)

**Transform content (optional):**
- Formulas (multi-input calculations)
- Maps (status code → i18n key)
- Converters (single-value format conversion)

---

### 6. `usp-codegen` (C)

Code generator that translates YAML definitions to typed source code.

**Usage:**
```bash
# Definitions only (raw parameters + presets)
usp-codegen --definitions ./definitions --output ./lib/generated --lang dart

# With transforms (raw parameters + presets + derived values)
usp-codegen --definitions ./definitions --transforms ./transforms --output ./lib/generated --lang dart
```

**Supported outputs:**
- Dart (for Flutter)
- TypeScript (for web)
- Swift (for iOS)

---

### 7. `usp-llm-proxy` (C)

Router-side daemon that proxies AI chat requests to an LLM and validates responses.

**Responsibilities:**
1. Receive user text queries from UI via HTTP
2. Send queries to LLM via MQTT (cloud or local)
3. Validate LLM JSON responses against schema and whitelist
4. Retry with LLM if validation fails (up to 3 times)
5. Return validated JSON to UI

**HTTP Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/ai/chat` | POST | Phase 1: Submit query, receive validated dynamic_call JSON |
| `/api/ai/interpret` | POST | Phase 2: Submit results, receive human-readable message |
| `/api/ai/config` | GET | Get current AI configuration |
| `/api/ai/config` | PUT | Update AI configuration (admin only) |

**Configuration** (`/etc/usp-llm-proxy/config.json`):
```json
{
  "llm_mode": "cloud",
  "cloud": {
    "mqtt_broker": "mqtts://ai.linksys.com:8883"
  },
  "local": {
    "mqtt_broker": "mqtt://localhost:1883"
  },
  "validation": {
    "max_retries": 3,
    "schema_path": "/etc/usp-llm-proxy/dynamic_call_request.schema.json",
    "whitelist_path": "/etc/usp-llm-proxy/path_whitelist.json"
  }
}
```

**Error codes (8000-8999):**
| Code | Description |
|------|-------------|
| 8000 | Schema validation failed |
| 8001 | Path not whitelisted |
| 8002 | Path explicitly denied |
| 8003 | Operation not permitted for path |
| 8004 | Limit exceeded |
| 8005 | Invalid path syntax |
| 8006 | Unsupported operation type |
| 8100 | LLM communication failed |
| 8101 | LLM retry limit exceeded |
| 8102 | LLM response malformed |

---

### 8. `usp-ui-flutter` (Flutter)

Main UI application.

**Dependencies:**
- `usp-client` (via Dart binding)
- Generated code from `usp-codegen`

**AI Chat Integration (two-phase workflow):**
1. Phase 1: Sends plain text query to `/api/ai/chat`, receives validated `dynamic_call` JSON
2. Executes `dynamic_call` via `usp-client`
3. Phase 2: Sends results to `/api/ai/interpret`, receives human-readable message for user
- UI has no LLM or validation logic

**Platforms:**
- Flutter Web (uses WASM build of usp-client)
- Flutter iOS (uses static lib via FFI)
- Flutter Android (uses shared lib via FFI)

---

## Summary: Three Paths to the Router

```
STANDARD CALLS              DYNAMIC CALLS (AI)           TURBO CHANNEL
(HTTP, type-safe)           (two-phase, router-proxied)  (WebSocket, streaming)

usp-definitions             User text query              UI requests channel
(YAML + transforms)               │                             │
        │                         │                             │
        ▼                         ▼                             │
   usp-codegen              ┌─────────────────────┐             │
        │                   │ Phase 1: Query      │             │
        ▼                   │ /api/ai/chat        │             │
 Generated Dart/TS          │      │              │             │
 (class + extension)        │      ▼              │             │
        │                   │ usp-llm-proxy       │             │
        │                   │ ├──► MQTT ──► LLM   │             │
        │                   │ │◄── JSON ◄──┘      │             │
        │                   │ Validate + Retry    │             │
        │                   │      │              │             │
        │                   │      ▼              │             │
        │                   │ dynamic_call JSON   │             │
        │                   └──────┬──────────────┘             │
        │                          │                            │
        ▼                          ▼                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            usp-client (Rust)                            │
│                                                                         │
│  Typed API     │      JSON API            │      Turbo API              │
│  get(paths[])  │  execute_json(string)    │  turbo_acquire(operation)   │
│       │        │          │               │          │                  │
│       └────────┴──────────┘               │          │                  │
│                │                          │          ▼                  │
│                ▼                          │   WebSocket /usp-ws         │
│        Protobuf encode                    │   (managed internally)      │
│                │                          │          │                  │
│                ▼                          │          │                  │
│        HTTP POST /api/usp                 │          │                  │
└────────────────┬──────────────────────────┴──────────┼──────────────────┘
                 │                                     │
                 │◄─────────────────────────┐          │
                 │          Results         │          │
                 ▼                          │          │
┌───────────────────────────────────────────┤          │
│ Phase 2: Interpret                        │          │
│ /api/ai/interpret                         │          │
│      │                                    │          │
│      ▼                                    │          │
│ usp-llm-proxy ──► LLM ──► Human message   │          │
└───────────────────────────────────────────┘          │
                 │                                     │
                 ▼                                     ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                              Router                                       │
│                                                                           │
│    lighttpd ──► usp-bridge ──► OBUSPA ◄── lighttpd (WS proxy, turbo)     │
│        │            │             ▲                     ▲                 │
│        │            └─────────────┘                     │                 │
│        │                UDS                             │                 │
│        └────────────────────────────────────────────────┘                 │
│                        WebSocket proxy to localhost:8443                  │
└───────────────────────────────────────────────────────────────────────────┘
```

**Key differences**:
- **Standard**: HTTP/SSE via usp-bridge, supports multiple clients
- **Dynamic (AI)**: Two-phase router-proxied LLM (query → execute → interpret), validation and retry on router
- **Turbo**: WebSocket via **usp-client** → lighttpd proxy → OBUSPA, single client, high-bandwidth streaming
