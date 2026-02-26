# usp-llm-proxy Specification

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |
| v2 | - | YAML format for LLM output |

---

## Overview

`usp-llm-proxy` is a router-side daemon that proxies AI chat requests between the UI and an LLM (cloud or local). It handles query generation, validation, retry logic, and result interpretation using a two-phase workflow.

### Purpose

- Receive user text queries from UI via HTTP
- Send queries to LLM via MQTT (Phase 1: Query Generation)
- Parse LLM YAML responses and validate against schema and whitelist
- Retry with LLM if validation fails (up to 3 times)
- Interpret execution results via LLM (Phase 2: Result Interpretation)
- Return validated dynamic_call (as JSON in HTTP response) and human-readable messages to UI

**Note**: The LLM generates YAML output for better reliability (no trailing comma issues, simpler escaping). The router parses the YAML, validates it, and returns the result as JSON in the standard REST API response.

### Language

C (for minimal footprint on embedded devices)

### Dependencies

- libmosquitto (MQTT client)
- libyaml (YAML parsing for LLM responses)
- libjansson (JSON for HTTP API responses)
- libevent (event loop)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            usp-llm-proxy                                     │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐   │
│  │  HTTP Server    │  │  MQTT Client    │  │  Validator                  │   │
│  │  (localhost)    │  │                 │  │                             │   │
│  │                 │  │  Cloud or Local │  │  - Schema validation        │   │
│  │  /api/ai/chat   │  │  LLM broker     │  │  - Path whitelist           │   │
│  │  /api/ai/       │  │                 │  │  - Path denylist            │   │
│  │    interpret    │  │                 │  │  - Operation limits         │   │
│  │  /api/ai/config │  │                 │  │                             │   │
│  └────────┬────────┘  └────────┬────────┘  └──────────────┬──────────────┘   │
│           │                    │                          │                  │
│           └────────────────────┼──────────────────────────┘                  │
│                                │                                             │
│                         ┌──────┴──────┐                                      │
│                         │  Request    │                                      │
│                         │  Manager    │                                      │
│                         └─────────────┘                                      │
└──────────────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ MQTT
                                 ▼
                    ┌────────────────────────┐
                    │   LLM                  │
                    │   (cloud or local)     │
                    └────────────────────────┘
```

---

## Two-Phase Workflow

### Phase 1: Query Generation

```
UI ──► /api/ai/chat ──► MQTT request ──► LLM
                               │
                               ▼
                    LLM generates dynamic_call YAML
                               │
                               ▼
                    Validation (schema + whitelist)
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
              Valid YAML            Invalid YAML
                    │                     │
                    │                     ▼
                    │              Retry with LLM
                    │              (up to 3 times)
                    │                     │
                    ▼                     ▼
              Return to UI          Return error
```

### Phase 2: Result Interpretation

```
UI executes dynamic_call
              │
              ▼
UI ──► /api/ai/interpret ──► MQTT request ──► LLM
                                    │
                                    ▼
                        LLM generates human message
                                    │
                                    ▼
                              Return to UI
```

---

## HTTP API

### Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/ai/chat` | POST | JWT | Phase 1: Submit query, receive dynamic_call |
| `/api/ai/interpret` | POST | JWT | Phase 2: Submit results, receive message |
| `/api/ai/config` | GET | JWT | Get AI configuration |
| `/api/ai/config` | PUT | JWT (admin) | Update AI configuration |

### POST /api/ai/chat (Phase 1)

**Request:**
```json
{
  "session_id": "abc123",
  "message": "What channel is my WiFi using?",
  "context": {
    "conversation_history": [
      {"role": "user", "content": "Show me my WiFi settings"},
      {"role": "assistant", "content": "Your WiFi SSID is 'MyNetwork'..."}
    ]
  }
}
```

**Response (success with dynamic_call):**
```json
{
  "success": true,
  "request_id": "req-uuid-123",
  "dynamic_call": {
    "version": "1.0",
    "operations": [
      {"type": "Get", "paths": ["Device.WiFi.Radio.1.Channel"]}
    ]
  },
  "validation": {
    "valid": true,
    "attempts": 1
  }
}
```

**Response (conversational, no dynamic_call):**
```json
{
  "success": true,
  "request_id": "req-uuid-124",
  "message": "I can help you with router configuration. What would you like to know?",
  "dynamic_call": null
}
```

**Response (validation failed):**
```json
{
  "success": false,
  "message": "I was unable to generate a valid request for that query.",
  "error": {
    "code": 8101,
    "message": "LLM retry limit exceeded",
    "details": "Validation failed: Path 'Device.Users.Password' is denied"
  }
}
```

### POST /api/ai/interpret (Phase 2)

**Request:**
```json
{
  "session_id": "abc123",
  "request_id": "req-uuid-123",
  "original_message": "What channel is my WiFi using?",
  "dynamic_call": {
    "version": "1.0",
    "operations": [
      {"type": "Get", "paths": ["Device.WiFi.Radio.1.Channel"]}
    ]
  },
  "results": {
    "success": true,
    "results": [
      {
        "operationIndex": 0,
        "type": "Get",
        "data": {
          "params": {
            "Device.WiFi.Radio.1.Channel": "6"
          }
        }
      }
    ]
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Your WiFi is currently using channel 6. This is a good choice for the 2.4GHz band as it's one of the non-overlapping channels."
}
```

### GET /api/ai/config

**Response:**
```json
{
  "llm_mode": "cloud",
  "enabled": true,
  "max_retries": 3
}
```

### PUT /api/ai/config

**Request:**
```json
{
  "llm_mode": "local",
  "enabled": true
}
```

**Response:**
```json
{
  "status": "ok"
}
```

---

## MQTT Communication

### Topics

| Topic | Direction | Purpose |
|-------|-----------|---------|
| `linksys/{device_id}/ai/request` | Router → Broker | Query and interpret requests |
| `linksys/{device_id}/ai/response` | Broker → Router | LLM responses |
| `linksys/{device_id}/ai/retry` | Router → Broker | Retry requests |

### Message Formats

#### Query Request (Phase 1)

```json
{
  "request_id": "req-uuid-123",
  "device_id": "device-serial",
  "timestamp": "2025-01-12T10:30:00Z",
  "type": "query",
  "payload": {
    "user_message": "What channel is my WiFi using?",
    "system_context": {
      "available_paths": ["Device.WiFi.*", "Device.DeviceInfo.*"],
      "schema_version": "1.0",
      "max_operations": 20
    },
    "conversation_history": []
  }
}
```

#### Retry Request

```json
{
  "request_id": "req-uuid-123",
  "device_id": "device-serial",
  "timestamp": "2025-01-12T10:30:01Z",
  "type": "retry",
  "payload": {
    "original_query": "What channel is my WiFi using?",
    "previous_response": {
      "version": "1.0",
      "operations": [{"type": "Get", "paths": ["Device.Users.Password"]}]
    },
    "validation_errors": [
      {
        "code": 8002,
        "message": "Path denied: User credentials are never exposed",
        "path": "Device.Users.Password"
      }
    ],
    "instruction": "Please correct the JSON. The path 'Device.Users.Password' is not allowed."
  }
}
```

#### Interpret Request (Phase 2)

```json
{
  "request_id": "req-uuid-123",
  "device_id": "device-serial",
  "timestamp": "2025-01-12T10:30:02Z",
  "type": "interpret",
  "payload": {
    "original_message": "What channel is my WiFi using?",
    "dynamic_call": {
      "version": "1.0",
      "operations": [{"type": "Get", "paths": ["Device.WiFi.Radio.1.Channel"]}]
    },
    "execution_results": {
      "success": true,
      "results": [{"operationIndex": 0, "data": {"params": {"Device.WiFi.Radio.1.Channel": "6"}}}]
    }
  }
}
```

---

## Validation

### Schema Validation

The `dynamic_call` YAML from the LLM is first parsed into an internal structure, then validated against the schema defined in `dynamic_call_spec.md`.

```c
bool validate_schema(const json_t* dynamic_call) {
    // Check required fields
    if (!json_object_get(dynamic_call, "version")) return false;
    if (!json_object_get(dynamic_call, "operations")) return false;

    // Validate operations array
    json_t* ops = json_object_get(dynamic_call, "operations");
    if (!json_is_array(ops)) return false;

    size_t index;
    json_t* op;
    json_array_foreach(ops, index, op) {
        if (!validate_operation(op)) return false;
    }

    return true;
}
```

### Path Whitelist

Only paths matching the whitelist patterns are allowed.

**File:** `/etc/usp-llm-proxy/path_whitelist.json`

```json
{
  "allowed_patterns": [
    "Device.DeviceInfo.*",
    "Device.WiFi.*",
    "Device.Hosts.*",
    "Device.IP.Interface.*",
    "Device.Ethernet.*",
    "Device.NAT.PortMapping.*"
  ],
  "denied_patterns": [
    "Device.Users.*",
    "Device.Security.*",
    "Device.*.Password",
    "Device.*.Passphrase",
    "Device.*.Key",
    "Device.*.Secret"
  ]
}
```

### Validation Logic

```c
validation_result_t validate_dynamic_call(const json_t* dynamic_call) {
    validation_result_t result = {.valid = true, .error_count = 0};

    // 1. Schema validation
    if (!validate_schema(dynamic_call)) {
        add_error(&result, 8000, "Schema validation failed", NULL);
        return result;
    }

    // 2. Path validation
    json_t* ops = json_object_get(dynamic_call, "operations");
    size_t index;
    json_t* op;

    json_array_foreach(ops, index, op) {
        const char* type = json_string_value(json_object_get(op, "type"));
        json_t* paths = json_object_get(op, "paths");

        if (paths) {
            size_t path_index;
            json_t* path;
            json_array_foreach(paths, path_index, path) {
                const char* path_str = json_string_value(path);
                if (!is_path_allowed(path_str)) {
                    add_error(&result, 8001, "Path not whitelisted", path_str);
                }
                if (is_path_denied(path_str)) {
                    add_error(&result, 8002, "Path explicitly denied", path_str);
                }
            }
        }

        // 3. Operation-specific validation
        if (!is_operation_allowed_for_paths(type, paths)) {
            add_error(&result, 8003, "Operation not permitted", NULL);
        }
    }

    // 4. Limits check
    if (json_array_size(ops) > config.max_operations) {
        add_error(&result, 8004, "Too many operations", NULL);
    }

    return result;
}
```

---

## Error Codes

| Code | Description |
|------|-------------|
| 8000 | Schema validation failed |
| 8001 | Path not whitelisted |
| 8002 | Path explicitly denied |
| 8003 | Operation not permitted for path |
| 8004 | Limit exceeded (operations, depth, etc.) |
| 8005 | Invalid path syntax |
| 8006 | Unsupported operation type |
| 8100 | LLM communication failed |
| 8101 | LLM retry limit exceeded |
| 8102 | LLM response malformed |

---

## Configuration

### UCI: `/etc/config/usp-llm-proxy`

```
config llm_proxy 'main'
    option listen_addr '127.0.0.1'
    option listen_port '8081'
    option enabled '1'
    option llm_mode 'cloud'
    option max_retries '3'
    option retry_timeout_ms '5000'
    option request_timeout_ms '30000'
```

### JSON Configuration

**File:** `/etc/usp-llm-proxy/config.json`

```json
{
  "llm_mode": "cloud",
  "cloud": {
    "mqtt_broker": "mqtts://ai.linksys.com:8883",
    "client_cert": "/etc/ssl/device.crt",
    "client_key": "/etc/ssl/device.key"
  },
  "local": {
    "mqtt_broker": "mqtt://localhost:1883",
    "model": "llama-3-8b",
    "endpoint": "http://localhost:11434/api/generate"
  },
  "validation": {
    "max_retries": 3,
    "retry_timeout_ms": 5000,
    "schema_path": "/etc/usp-llm-proxy/dynamic_call_request.schema.json",
    "whitelist_path": "/etc/usp-llm-proxy/path_whitelist.json"
  }
}
```

### Privacy Modes

| Mode | Description |
|------|-------------|
| `cloud` | Queries sent to cloud LLM (default, best quality) |
| `local` | Queries processed by on-device LLM (privacy-sensitive) |
| `disabled` | AI features completely disabled |

---

## System Prompt

The LLM receives a system prompt with context:

```
You are a router configuration assistant. Generate YAML commands to query or modify router settings.

Available paths:
- Device.DeviceInfo.* (read-only)
- Device.WiFi.* (read/write)
- Device.Hosts.* (read-only)
...

Response format (YAML):
message: Your explanation here
dynamic_call:
  version: "1.0"
  operations:
    - type: Get
      paths:
        - Device.WiFi.Radio.1.Channel

If the user asks a conversational question, respond with:
message: Your response here
dynamic_call: null

NEVER access paths containing: Password, Passphrase, Key, Secret, Users, Security
```

---

## Internal Data Structures

### Request State

```c
typedef struct {
    char request_id[64];
    char session_id[64];
    char original_message[4096];
    int retry_count;
    time_t started_at;
    json_t* last_response;
    json_t* validation_errors;
    http_connection_t* http_conn;
} pending_request_t;
```

### Configuration

```c
typedef struct {
    char listen_addr[64];
    int listen_port;
    bool enabled;
    char llm_mode[32];  // "cloud", "local", "disabled"
    int max_retries;
    int retry_timeout_ms;
    int request_timeout_ms;
    char mqtt_broker[256];
    char whitelist_path[256];
    char schema_path[256];
} llm_proxy_config_t;
```

---

## Build & Deployment

### Build Dependencies

- libmosquitto-dev (MQTT)
- libyaml-dev (YAML parsing for LLM responses)
- libjansson-dev (JSON for HTTP API)
- libevent-dev (event loop)
- OpenSSL-dev (TLS for MQTT)

### Makefile

```makefile
define Package/usp-llm-proxy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=USP LLM Proxy
  DEPENDS:=+libmosquitto +libyaml +libjansson +libevent2 +libopenssl
endef
```

### Installation

- Binary: `/usr/bin/usp-llm-proxy`
- Config: `/etc/config/usp-llm-proxy`
- JSON Config: `/etc/usp-llm-proxy/config.json`
- Schema: `/etc/usp-llm-proxy/dynamic_call_request.schema.json`
- Whitelist: `/etc/usp-llm-proxy/path_whitelist.json`
- Init script: `/etc/init.d/usp-llm-proxy`

---

## Testing

### Unit Tests

- Schema validation
- Path whitelist matching
- MQTT message formatting
- HTTP request/response handling

### Integration Tests

- End-to-end query flow
- Retry behavior
- Timeout handling
- Error responses

### Test Commands

```bash
# Test Phase 1 (query)
curl -X POST -H "Content-Type: application/json" \
     -d '{"session_id":"test","message":"What is my WiFi channel?"}' \
     http://localhost:8081/api/ai/chat

# Test Phase 2 (interpret)
curl -X POST -H "Content-Type: application/json" \
     -d '{"session_id":"test","request_id":"req-123","original_message":"...","results":{...}}' \
     http://localhost:8081/api/ai/interpret

# Test config
curl http://localhost:8081/api/ai/config
```
