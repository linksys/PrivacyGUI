# USP-Driven UI Specification — AI Dynamic Call Extension

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |
| v2 | - | Router-proxied LLM architecture |
| v3 | - | Two-phase workflow (query → execute → interpret) |
| v4 | - | YAML format for LLM output (better for LLM generation) |

---

## Overview

This extension to the UI-side specification defines a mechanism for AI-generated USP operations that bypass the compile-time code generation system. It enables an AI assistant to dynamically construct USP requests at runtime while maintaining security through schema validation and path whitelisting.

**Key architectural decision**: The AI/LLM processing is handled by the router, not the UI. The browser cannot directly connect to an LLM as it requires authentication. Instead, AI chat messages are sent to the router (via lighttpd), which proxies them via MQTT to a cloud or local LLM depending on customer privacy settings. The router validates LLM responses before returning them to the UI.

**Why YAML for LLM output**: LLMs generate YAML more reliably than JSON because:
- No trailing comma issues (a common JSON generation error)
- No escaping issues with quotes in strings
- More readable for debugging and logging
- Better token efficiency (fewer characters for the same structure)

### Design Principles

1. **Separation of concerns**: UI handles user interaction only; AI orchestration is a router-side service
2. **Security-first**: Router-side validation before any dynamic_call reaches the UI; client cannot bypass
3. **Privacy flexibility**: Cloud or local LLM deployment based on customer configuration
4. **Atomicity**: Batch operations are all-or-nothing; partial failures roll back entirely
5. **Consistency**: Dynamic calls use the same transport and error model as generated calls
6. **Retry loop**: Validation failures are sent back to LLM for correction without UI involvement
7. **Extensibility**: Schema designed to accommodate future capabilities without breaking changes
8. **Two-phase workflow**: LLM generates query, UI executes, LLM interprets results for human-readable response

### Relationship to Existing Specification

The dynamic call system operates alongside the generated API classes, but AI processing happens on the router. The workflow has **two phases**: query generation and result interpretation.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              UI (Browser/App)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────┐     ┌─────────────────────────────────┐   │
│   │   Generated API Classes     │     │       AI Chat Interface         │   │
│   │   (99% of operations)       │     │                                 │   │
│   │                             │     │   1. User: "What channel is     │   │
│   │   • WifiSettings.fetch()    │     │      my WiFi using?"            │   │
│   │   • HardwareInfo.fetch()    │     │   2. Receives: dynamic_call YAML│   │
│   │   • ConnectedDevices.fetch()│     │   3. Executes via UspClient     │   │
│   │   • Type-safe, compile-time │     │   4. Sends results for interpret│   │
│   └──────────────┬──────────────┘     │   5. Receives: human-readable   │   │
│                  │                    │      answer for user            │   │
│                  │                    └───────────┬─────────────────────┘   │
│                  │                                │                         │
│                  ▼                                │                         │
│         ┌─────────────────┐                       │                         │
│         │    UspClient    │◄──────────────────────┘                         │
│         └─────────────────┘        (execute dynamic_call)                   │
└─────────────────────────────────────────────────────────────────────────────┘
                   │                                │
                   ▼                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Router (OpenWRT)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────┐      ┌────────────────────────────────────────────┐   │
│   │    lighttpd     │      │           usp-llm-proxy                    │   │
│   │                 │      │                                            │   │
│   │  /api/ai/chat ──┼─────►│  Phase 1 (Query):                          │   │
│   │                 │      │    1. Send query via MQTT to LLM           │   │
│   │                 │◄─────┼    2. Receive dynamic_call YAML            │   │
│   │                 │      │    3. Validate (schema + whitelist)        │   │
│   │                 │      │    4. If invalid → retry with LLM          │   │
│   │                 │      │    5. Return validated YAML to UI          │   │
│   │                 │      │                                            │   │
│   │  /api/ai/      ─┼─────►│  Phase 2 (Interpret):                      │   │
│   │   interpret     │      │    1. Receive results + original query     │   │
│   │                 │◄─────┼    2. Send to LLM for interpretation       │   │
│   │                 │      │    3. Return human-readable answer         │   │
│   └─────────────────┘      └──────────────────┬─────────────────────────┘   │
│                                               │                             │
│                                               │ MQTT                        │
│                                               ▼                             │
│                            ┌────────────────────────────────────────────┐   │
│                            │   LLM (cloud or local per privacy config)  │   │
│                            └────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Two-phase workflow:**
1. **Phase 1 (Query)**: User question → LLM generates `dynamic_call` YAML → UI executes via UspClient
2. **Phase 2 (Interpret)**: Execution results + original question → LLM → human-readable answer

**Key points:**
- UI sends plain text queries, receives validated YAML ready for execution
- After execution, UI sends results back for LLM interpretation
- Router handles LLM communication, validation, and retry logic
- Privacy configuration determines cloud vs local LLM routing
- Validation cannot be bypassed by the client

---

## Schema Definition

The LLM generates YAML output which is parsed and validated against JSON Schema (the industry standard for schema validation). The schema files remain in JSON format since that is the JSON Schema specification.

### Request Schema

**File**: `lib/api/dynamic/schema/dynamic_call_request.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "dynamic-usp-call-request.v1.schema.json",
  "title": "Dynamic USP Call Request",
  "description": "Schema for AI-generated USP operation requests",
  "type": "object",
  "required": ["version", "operations"],
  "additionalProperties": false,
  "properties": {
    "version": {
      "type": "string",
      "const": "1.0",
      "description": "Schema version for compatibility checking"
    },
    "operations": {
      "type": "array",
      "minItems": 1,
      "maxItems": 20,
      "description": "Ordered list of USP operations to execute atomically",
      "items": {
        "$ref": "#/$defs/operation"
      }
    },
    "options": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "timeout": {
          "type": "integer",
          "minimum": 1000,
          "maximum": 30000,
          "default": 10000,
          "description": "Request timeout in milliseconds"
        }
      }
    }
  },
  "$defs": {
    "operation": {
      "type": "object",
      "required": ["type"],
      "oneOf": [
        { "$ref": "#/$defs/getOperation" },
        { "$ref": "#/$defs/setOperation" },
        { "$ref": "#/$defs/addOperation" },
        { "$ref": "#/$defs/getSupportedDMOperation" }
      ]
    },
    "getOperation": {
      "type": "object",
      "required": ["type", "paths"],
      "additionalProperties": false,
      "properties": {
        "type": { "const": "Get" },
        "paths": {
          "type": "array",
          "minItems": 1,
          "maxItems": 50,
          "items": {
            "type": "string",
            "pattern": "^Device\\.",
            "description": "TR-181 parameter or object path"
          }
        },
        "maxDepth": {
          "type": "integer",
          "minimum": 0,
          "maximum": 5,
          "default": 0,
          "description": "Maximum recursion depth for partial paths"
        }
      }
    },
    "setOperation": {
      "type": "object",
      "required": ["type", "params"],
      "additionalProperties": false,
      "properties": {
        "type": { "const": "Set" },
        "params": {
          "type": "array",
          "minItems": 1,
          "maxItems": 20,
          "items": {
            "type": "object",
            "required": ["path", "value"],
            "additionalProperties": false,
            "properties": {
              "path": {
                "type": "string",
                "pattern": "^Device\\.",
                "description": "Full parameter path"
              },
              "value": {
                "oneOf": [
                  { "type": "string" },
                  { "type": "integer" },
                  { "type": "boolean" }
                ],
                "description": "Value to set (will be string-encoded per USP spec)"
              }
            }
          }
        }
      }
    },
    "addOperation": {
      "type": "object",
      "required": ["type", "objectPath"],
      "additionalProperties": false,
      "properties": {
        "type": { "const": "Add" },
        "objectPath": {
          "type": "string",
          "pattern": "^Device\\.",
          "description": "Multi-instance object path (ending in .)"
        },
        "params": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["path", "value"],
            "properties": {
              "path": {
                "type": "string",
                "description": "Relative parameter path within the new instance"
              },
              "value": {
                "oneOf": [
                  { "type": "string" },
                  { "type": "integer" },
                  { "type": "boolean" }
                ]
              }
            }
          }
        }
      }
    },
    "getSupportedDMOperation": {
      "type": "object",
      "required": ["type", "paths"],
      "additionalProperties": false,
      "properties": {
        "type": { "const": "GetSupportedDM" },
        "paths": {
          "type": "array",
          "minItems": 1,
          "maxItems": 10,
          "items": {
            "type": "string",
            "pattern": "^Device\\."
          }
        },
        "firstLevelOnly": {
          "type": "boolean",
          "default": false
        },
        "returnCommands": {
          "type": "boolean",
          "default": false
        },
        "returnEvents": {
          "type": "boolean",
          "default": false
        },
        "returnParams": {
          "type": "boolean",
          "default": true
        }
      }
    }
  }
}
```

### Response Schema

**File**: `lib/api/dynamic/schema/dynamic_call_response.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "dynamic-usp-call-response.v1.schema.json",
  "title": "Dynamic USP Call Response",
  "description": "Schema for dynamic call results returned to AI",
  "type": "object",
  "required": ["success", "results"],
  "properties": {
    "success": {
      "type": "boolean",
      "description": "True only if ALL operations succeeded"
    },
    "results": {
      "type": "array",
      "description": "Results for each operation, in request order",
      "items": {
        "$ref": "#/$defs/operationResult"
      }
    },
    "errors": {
      "type": "array",
      "description": "Present only if success is false",
      "items": {
        "$ref": "#/$defs/error"
      }
    }
  },
  "$defs": {
    "operationResult": {
      "type": "object",
      "required": ["operationIndex", "type"],
      "properties": {
        "operationIndex": {
          "type": "integer",
          "description": "Zero-based index of the operation in the request"
        },
        "type": {
          "type": "string",
          "enum": ["Get", "Set", "Add", "GetSupportedDM"]
        },
        "data": {
          "type": "object",
          "description": "Operation-specific result data"
        }
      }
    },
    "error": {
      "type": "object",
      "required": ["code", "message"],
      "properties": {
        "operationIndex": {
          "type": "integer",
          "description": "Which operation failed (if applicable)"
        },
        "path": {
          "type": "string",
          "description": "Specific path that caused the error (if applicable)"
        },
        "code": {
          "type": "integer",
          "description": "USP error code (7000-7999) or validation error code (8000-8999)"
        },
        "message": {
          "type": "string",
          "description": "Human-readable error description"
        }
      }
    }
  }
}
```

---

## Validation Rules

### Static Whitelist Configuration

**File**: `lib/api/dynamic/config/path_whitelist.json`

```json
{
  "version": "1.0",
  "rules": {
    "allowed": [
      {
        "pattern": "Device.DeviceInfo.**",
        "operations": ["Get"],
        "description": "Device information (read-only)"
      },
      {
        "pattern": "Device.WiFi.Radio.*.Channel",
        "operations": ["Get", "Set"],
        "description": "WiFi channel configuration"
      },
      {
        "pattern": "Device.WiFi.Radio.*.OperatingFrequencyBand",
        "operations": ["Get"],
        "description": "WiFi frequency band (read-only)"
      },
      {
        "pattern": "Device.WiFi.SSID.*.SSID",
        "operations": ["Get", "Set"],
        "description": "Network name"
      },
      {
        "pattern": "Device.WiFi.SSID.*.Enable",
        "operations": ["Get", "Set"],
        "description": "Enable/disable SSID"
      },
      {
        "pattern": "Device.WiFi.AccessPoint.*.Security.**",
        "operations": ["Get", "Set"],
        "description": "WiFi security settings"
      },
      {
        "pattern": "Device.Hosts.Host.*.**",
        "operations": ["Get"],
        "description": "Connected devices (read-only)"
      },
      {
        "pattern": "Device.IP.Interface.*.Status",
        "operations": ["Get"],
        "description": "Interface status (read-only)"
      },
      {
        "pattern": "Device.DNS.Client.Server.*.**",
        "operations": ["Get"],
        "description": "DNS configuration (read-only)"
      }
    ],
    "denied": [
      {
        "pattern": "Device.Users.**",
        "reason": "User credentials are never exposed"
      },
      {
        "pattern": "Device.Security.**",
        "reason": "Security configuration requires explicit UI"
      },
      {
        "pattern": "Device.ManagementServer.**",
        "reason": "TR-069/USP controller config is protected"
      },
      {
        "pattern": "Device.DeviceInfo.ProvisioningCode",
        "reason": "Provisioning data is sensitive"
      }
    ]
  },
  "limits": {
    "maxOperationsPerRequest": 20,
    "maxPathsPerGet": 50,
    "maxParamsPerSet": 20,
    "maxDepth": 5
  }
}
```

### Validation Error Codes

Dynamic call validation uses error codes in the 8000-8999 range to distinguish from USP protocol errors:

| Code | Name | Description |
|------|------|-------------|
| 8000 | Schema validation failed | JSON does not conform to schema |
| 8001 | Path not whitelisted | Path is not in the allowed list |
| 8002 | Path explicitly denied | Path matches a deny rule |
| 8003 | Operation not permitted | Operation type not allowed for this path |
| 8004 | Limit exceeded | Request exceeds configured limits |
| 8005 | Invalid path syntax | Path format is invalid |
| 8006 | Unsupported operation type | Operation type not implemented (e.g., Subscribe) |
| 8100 | LLM communication failed | MQTT timeout or LLM service unavailable |
| 8101 | LLM retry limit exceeded | Maximum correction attempts reached |
| 8102 | LLM response malformed | LLM returned non-JSON or unparseable response |

---

## LLM Proxy Architecture

The `usp-llm-proxy` is a router-side daemon that handles AI chat requests from the UI.

### Component Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            usp-llm-proxy                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│   │   HTTP      │    │   MQTT      │    │  Validator  │    │   Config    │  │
│   │   Handler   │───►│   Client    │───►│   Engine    │◄───│   Manager   │  │
│   │             │    │             │    │             │    │             │  │
│   │ /api/ai/chat│    │ pub/sub to  │    │ schema +    │    │ cloud/local │  │
│   │ /api/ai/cfg │    │ LLM broker  │    │ whitelist   │    │ LLM choice  │  │
│   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│          │                  │                  │                            │
│          │                  │                  │                            │
│          ▼                  ▼                  ▼                            │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                        Retry Controller                             │   │
│   │                                                                     │   │
│   │   • Max 3 retry attempts                                            │   │
│   │   • Sends validation errors back to LLM                             │   │
│   │   • Returns validated JSON or final error to UI                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
┌────────┐     ┌──────────┐     ┌──────────────┐     ┌─────────┐     ┌─────┐
│   UI   │────►│ lighttpd │────►│ usp-llm-proxy│────►│  MQTT   │────►│ LLM │
│        │     │          │     │              │     │ Broker  │     │     │
└────────┘     └──────────┘     └──────────────┘     └─────────┘     └─────┘
    ▲                                  │                                 │
    │                                  │◄────────────────────────────────┘
    │                                  │         JSON response
    │                                  ▼
    │                           ┌──────────────┐
    │                           │  Validation  │
    │                           │    Pass?     │
    │                           └──────────────┘
    │                              │        │
    │                           Yes│        │No
    │                              ▼        ▼
    │◄─────────────────── Return JSON    Retry with LLM
    │   (validated, ready               (up to 3 times)
    │    for execution)                      │
    │                                        ▼
    │◄────────────────────────────── Return error 8101
                                    (retry limit exceeded)
```

### HTTP API

The AI chat uses a two-phase workflow with two endpoints:

#### Phase 1: Query Generation

**Endpoint**: `POST /api/ai/chat`

Sends the user's question to the LLM, which generates a `dynamic_call` in YAML format. The router parses the YAML, validates it, and returns the result as JSON in the HTTP response (standard REST API format).

**Request**:
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

**Response (success)**:
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

**Response (no dynamic_call needed)**:
```json
{
  "success": true,
  "request_id": "req-uuid-124",
  "message": "I can help you with router configuration questions. What would you like to know?",
  "dynamic_call": null
}
```

**Response (validation failed after retries)**:
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

#### Phase 2: Result Interpretation

**Endpoint**: `POST /api/ai/interpret`

After executing the `dynamic_call`, sends the results back to the LLM for human-readable interpretation.

**Request**:
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

**Response (success)**:
```json
{
  "success": true,
  "message": "Your WiFi is currently using channel 6. This is a good choice for the 2.4GHz band as it's one of the non-overlapping channels."
}
```

**Response (execution failed)**:

If the `dynamic_call` execution failed, the UI still sends the error to the LLM for interpretation:

```json
{
  "session_id": "abc123",
  "request_id": "req-uuid-123",
  "original_message": "What channel is my WiFi using?",
  "dynamic_call": { ... },
  "results": {
    "success": false,
    "errors": [
      {
        "code": 7012,
        "message": "Invalid path",
        "path": "Device.WiFi.Radio.1.Channel"
      }
    ]
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "I wasn't able to retrieve the WiFi channel information. This parameter may not be available on your router model."
}
```

### MQTT Topics

| Topic | Direction | Purpose |
|-------|-----------|---------|
| `linksys/{device_id}/ai/request` | Router → Broker | Send user query to LLM (Phase 1) |
| `linksys/{device_id}/ai/response` | Broker → Router | Receive LLM response |
| `linksys/{device_id}/ai/retry` | Router → Broker | Send correction request (Phase 1 retry) |
| `linksys/{device_id}/ai/interpret` | Router → Broker | Send results for interpretation (Phase 2) |

### MQTT Message Format

MQTT messages between router and LLM use JSON for the envelope structure. However, when the LLM generates a `dynamic_call`, it outputs YAML which is embedded as a string or parsed object within the JSON envelope.

#### Phase 1: Query Generation

**Request to LLM** (`type: "query"`):
```json
{
  "request_id": "req-uuid-123",
  "device_id": "device-serial",
  "timestamp": "2025-01-12T10:30:00Z",
  "type": "query",
  "payload": {
    "user_message": "What channel is my WiFi using?",
    "system_context": {
      "available_paths": ["Device.WiFi.Radio.*", "Device.DeviceInfo.*"],
      "schema_version": "1.0",
      "max_operations": 20
    },
    "conversation_history": []
  }
}
```

**Retry request** (`type: "retry"`, after validation failure):
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
    "instruction": "Please correct the YAML. The path 'Device.Users.Password' is not allowed. Use only paths from the available_paths list."
  }
}
```

#### Phase 2: Result Interpretation

**Interpret request** (`type: "interpret"`):
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
      "operations": [
        {"type": "Get", "paths": ["Device.WiFi.Radio.1.Channel"]}
      ]
    },
    "execution_results": {
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
    },
    "conversation_history": []
  }
}
```

**LLM response for interpretation**:
```json
{
  "request_id": "req-uuid-123",
  "timestamp": "2025-01-12T10:30:03Z",
  "type": "interpret_response",
  "payload": {
    "message": "Your WiFi is currently using channel 6. This is a good choice for the 2.4GHz band as it's one of the non-overlapping channels."
  }
}
```

### Privacy Configuration

**File**: `/etc/usp-llm-proxy/config.json`

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

**Privacy modes**:
| Mode | Description | Use Case |
|------|-------------|----------|
| `cloud` | Queries sent to Linksys cloud LLM | Default, best quality |
| `local` | Queries processed by on-device LLM | Privacy-sensitive customers |
| `disabled` | AI features completely disabled | Enterprise policy |

---

## Dart Implementation

### Core Types

**File**: `lib/api/dynamic/types.dart`

```dart
/// Represents a validated dynamic call request
class DynamicCallRequest {
  final String version;
  final List<DynamicOperation> operations;
  final DynamicCallOptions options;

  const DynamicCallRequest({
    required this.version,
    required this.operations,
    this.options = const DynamicCallOptions(),
  });

  /// Parse and validate from JSON string
  /// Throws [DynamicCallValidationException] on invalid input
  factory DynamicCallRequest.fromJson(String json) {
    return DynamicCallParser.parse(json);
  }
}

/// Options for dynamic call execution
class DynamicCallOptions {
  final Duration timeout;

  const DynamicCallOptions({
    this.timeout = const Duration(seconds: 10),
  });
}

/// Base class for all dynamic operations
sealed class DynamicOperation {
  const DynamicOperation();
}

class DynamicGetOperation extends DynamicOperation {
  final List<String> paths;
  final int maxDepth;

  const DynamicGetOperation({
    required this.paths,
    this.maxDepth = 0,
  });
}

class DynamicSetOperation extends DynamicOperation {
  final List<DynamicSetParam> params;

  const DynamicSetOperation({required this.params});
}

class DynamicSetParam {
  final String path;
  final String value; // Always string-encoded per USP spec

  const DynamicSetParam({
    required this.path,
    required this.value,
  });
}

class DynamicAddOperation extends DynamicOperation {
  final String objectPath;
  final List<DynamicSetParam> params;

  const DynamicAddOperation({
    required this.objectPath,
    this.params = const [],
  });
}

class DynamicGetSupportedDMOperation extends DynamicOperation {
  final List<String> paths;
  final bool firstLevelOnly;
  final bool returnCommands;
  final bool returnEvents;
  final bool returnParams;

  const DynamicGetSupportedDMOperation({
    required this.paths,
    this.firstLevelOnly = false,
    this.returnCommands = false,
    this.returnEvents = false,
    this.returnParams = true,
  });
}
```

### Response Types

**File**: `lib/api/dynamic/response.dart`

```dart
/// Result of a dynamic call execution
class DynamicCallResponse {
  final bool success;
  final List<DynamicOperationResult> results;
  final List<DynamicCallError>? errors;

  const DynamicCallResponse({
    required this.success,
    required this.results,
    this.errors,
  });

  /// Convert to JSON for AI consumption
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'results': results.map((r) => r.toJson()).toList(),
      if (errors != null) 'errors': errors!.map((e) => e.toJson()).toList(),
    };
  }
}

/// Result of a single operation within the batch
class DynamicOperationResult {
  final int operationIndex;
  final String type;
  final Map<String, dynamic>? data;

  const DynamicOperationResult({
    required this.operationIndex,
    required this.type,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'operationIndex': operationIndex,
    'type': type,
    if (data != null) 'data': data,
  };
}

/// Error information for failed operations
class DynamicCallError {
  final int? operationIndex;
  final String? path;
  final int code;
  final String message;

  const DynamicCallError({
    this.operationIndex,
    this.path,
    required this.code,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    if (operationIndex != null) 'operationIndex': operationIndex,
    if (path != null) 'path': path,
    'code': code,
    'message': message,
  };
}
```

### Validation Engine

**File**: `lib/api/dynamic/validator.dart`

```dart
/// Validates dynamic call requests against schema and whitelist
class DynamicCallValidator {
  final PathWhitelist _whitelist;

  DynamicCallValidator(this._whitelist);

  /// Validate a parsed request
  /// Throws [DynamicCallValidationException] on failure
  void validate(DynamicCallRequest request) {
    _validateOperationCount(request);
    
    for (var i = 0; i < request.operations.length; i++) {
      _validateOperation(request.operations[i], i);
    }
  }

  void _validateOperationCount(DynamicCallRequest request) {
    if (request.operations.length > _whitelist.limits.maxOperationsPerRequest) {
      throw DynamicCallValidationException(
        code: 8004,
        message: 'Request exceeds maximum operations limit '
            '(${_whitelist.limits.maxOperationsPerRequest})',
      );
    }
  }

  void _validateOperation(DynamicOperation operation, int index) {
    switch (operation) {
      case DynamicGetOperation op:
        _validateGetOperation(op, index);
      case DynamicSetOperation op:
        _validateSetOperation(op, index);
      case DynamicAddOperation op:
        _validateAddOperation(op, index);
      case DynamicGetSupportedDMOperation op:
        _validateGetSupportedDMOperation(op, index);
    }
  }

  void _validateGetOperation(DynamicGetOperation op, int index) {
    if (op.paths.length > _whitelist.limits.maxPathsPerGet) {
      throw DynamicCallValidationException(
        code: 8004,
        message: 'Get operation $index exceeds path limit',
        operationIndex: index,
      );
    }

    for (final path in op.paths) {
      _validatePath(path, 'Get', index);
    }
  }

  void _validateSetOperation(DynamicSetOperation op, int index) {
    if (op.params.length > _whitelist.limits.maxParamsPerSet) {
      throw DynamicCallValidationException(
        code: 8004,
        message: 'Set operation $index exceeds param limit',
        operationIndex: index,
      );
    }

    for (final param in op.params) {
      _validatePath(param.path, 'Set', index);
    }
  }

  void _validateAddOperation(DynamicAddOperation op, int index) {
    _validatePath(op.objectPath, 'Add', index);
  }

  void _validateGetSupportedDMOperation(
    DynamicGetSupportedDMOperation op,
    int index,
  ) {
    for (final path in op.paths) {
      _validatePath(path, 'GetSupportedDM', index);
    }
  }

  void _validatePath(String path, String operation, int operationIndex) {
    // Check deny list first (takes precedence)
    final denyRule = _whitelist.findDenyRule(path);
    if (denyRule != null) {
      throw DynamicCallValidationException(
        code: 8002,
        message: 'Path denied: ${denyRule.reason}',
        operationIndex: operationIndex,
        path: path,
      );
    }

    // Check allow list
    final allowRule = _whitelist.findAllowRule(path);
    if (allowRule == null) {
      throw DynamicCallValidationException(
        code: 8001,
        message: 'Path not in whitelist',
        operationIndex: operationIndex,
        path: path,
      );
    }

    // Check operation is permitted
    if (!allowRule.operations.contains(operation)) {
      throw DynamicCallValidationException(
        code: 8003,
        message: '$operation not permitted for this path',
        operationIndex: operationIndex,
        path: path,
      );
    }
  }
}

/// Exception thrown when validation fails
class DynamicCallValidationException implements Exception {
  final int code;
  final String message;
  final int? operationIndex;
  final String? path;

  DynamicCallValidationException({
    required this.code,
    required this.message,
    this.operationIndex,
    this.path,
  });

  DynamicCallError toError() => DynamicCallError(
    code: code,
    message: message,
    operationIndex: operationIndex,
    path: path,
  );
}
```

### Dynamic Call Interpreter

**File**: `lib/api/dynamic/interpreter.dart`

```dart
/// Interprets validated dynamic calls and executes them via UspClient
class DynamicCallInterpreter {
  final UspClient _client;
  final DynamicCallValidator _validator;

  DynamicCallInterpreter(this._client, this._validator);

  /// Execute a dynamic call from JSON
  /// 
  /// This is the main entry point for AI-generated calls.
  /// Returns a [DynamicCallResponse] that can be serialized to JSON.
  Future<DynamicCallResponse> execute(String json) async {
    // Parse and validate
    final DynamicCallRequest request;
    try {
      request = DynamicCallRequest.fromJson(json);
      _validator.validate(request);
    } on DynamicCallValidationException catch (e) {
      return DynamicCallResponse(
        success: false,
        results: [],
        errors: [e.toError()],
      );
    }

    // Execute with atomicity guarantee
    return _executeAtomic(request);
  }

  Future<DynamicCallResponse> _executeAtomic(DynamicCallRequest request) async {
    final results = <DynamicOperationResult>[];
    final errors = <DynamicCallError>[];

    for (var i = 0; i < request.operations.length; i++) {
      final op = request.operations[i];
      
      try {
        final result = await _executeOperation(op, i);
        results.add(result);
      } on UspErrorException catch (e) {
        // USP-level error - fail the entire batch
        errors.add(DynamicCallError(
          operationIndex: i,
          path: e.path,
          code: e.code,
          message: e.message,
        ));
        
        // Atomicity: return failure, discard partial results
        return DynamicCallResponse(
          success: false,
          results: [], // No partial results on atomic failure
          errors: errors,
        );
      }
    }

    return DynamicCallResponse(
      success: true,
      results: results,
    );
  }

  Future<DynamicOperationResult> _executeOperation(
    DynamicOperation op,
    int index,
  ) async {
    switch (op) {
      case DynamicGetOperation getOp:
        return _executeGet(getOp, index);
      case DynamicSetOperation setOp:
        return _executeSet(setOp, index);
      case DynamicAddOperation addOp:
        return _executeAdd(addOp, index);
      case DynamicGetSupportedDMOperation gsdmOp:
        return _executeGetSupportedDM(gsdmOp, index);
    }
  }

  Future<DynamicOperationResult> _executeGet(
    DynamicGetOperation op,
    int index,
  ) async {
    final response = await _client.get(
      op.paths,
      maxDepth: op.maxDepth,
    );

    return DynamicOperationResult(
      operationIndex: index,
      type: 'Get',
      data: _convertGetResponse(response),
    );
  }

  Future<DynamicOperationResult> _executeSet(
    DynamicSetOperation op,
    int index,
  ) async {
    // Build parameter map
    final params = <String, String>{};
    for (final p in op.params) {
      params[p.path] = p.value;
    }

    // Execute with allow_partial = false for atomicity
    await _client.set(params, allowPartial: false);

    return DynamicOperationResult(
      operationIndex: index,
      type: 'Set',
      data: {'updated': params.keys.toList()},
    );
  }

  Future<DynamicOperationResult> _executeAdd(
    DynamicAddOperation op,
    int index,
  ) async {
    final params = <String, String>{};
    for (final p in op.params) {
      params[p.path] = p.value;
    }

    final instancePath = await _client.add(op.objectPath, params);

    return DynamicOperationResult(
      operationIndex: index,
      type: 'Add',
      data: {'instancePath': instancePath},
    );
  }

  Future<DynamicOperationResult> _executeGetSupportedDM(
    DynamicGetSupportedDMOperation op,
    int index,
  ) async {
    final response = await _client.getSupportedDM(
      op.paths,
      firstLevelOnly: op.firstLevelOnly,
      returnCommands: op.returnCommands,
      returnEvents: op.returnEvents,
      returnParams: op.returnParams,
    );

    return DynamicOperationResult(
      operationIndex: index,
      type: 'GetSupportedDM',
      data: _convertSupportedDMResponse(response),
    );
  }

  Map<String, dynamic> _convertGetResponse(GetResponse response) {
    // Convert protobuf response to simple key-value map
    final data = <String, dynamic>{};
    for (final result in response.reqPathResults) {
      for (final resolvedPath in result.resolvedPathResults) {
        for (final param in resolvedPath.resultParams) {
          data['${resolvedPath.resolvedPath}${param.key}'] = param.value;
        }
      }
    }
    return {'params': data};
  }

  Map<String, dynamic> _convertSupportedDMResponse(
    GetSupportedDMResponse response,
  ) {
    // Convert to structured JSON for AI consumption
    final objects = <Map<String, dynamic>>[];
    
    for (final result in response.reqObjResults) {
      for (final supportedObj in result.supportedObjs) {
        objects.add({
          'path': supportedObj.supportedObjPath,
          'isMultiInstance': supportedObj.isMultiInstance,
          if (supportedObj.supportedParams.isNotEmpty)
            'params': supportedObj.supportedParams
                .map((p) => {
                      'name': p.paramName,
                      'access': p.access.name,
                    })
                .toList(),
          if (supportedObj.supportedCommands.isNotEmpty)
            'commands': supportedObj.supportedCommands
                .map((c) => c.commandName)
                .toList(),
        });
      }
    }
    
    return {'supportedObjects': objects};
  }
}
```

### Schema Cache Manager

**File**: `lib/api/dynamic/schema_cache.dart`

```dart
/// Caches GetSupportedDM results for the session duration
class SupportedDMCache {
  final UspClient _client;
  Map<String, SupportedObjectInfo>? _cache;
  DateTime? _cacheTime;

  SupportedDMCache(this._client);

  /// Get cached schema or fetch if not available
  Future<Map<String, SupportedObjectInfo>> getSchema() async {
    if (_cache != null) {
      return _cache!;
    }

    // Fetch full data model schema
    final response = await _client.getSupportedDM(
      ['Device.'],
      firstLevelOnly: false,
      returnParams: true,
      returnCommands: false,
      returnEvents: false,
    );

    _cache = _buildCache(response);
    _cacheTime = DateTime.now();
    
    return _cache!;
  }

  /// Invalidate cache (call on session end)
  void invalidate() {
    _cache = null;
    _cacheTime = null;
  }

  /// Check if a path exists in the data model
  Future<bool> pathExists(String path) async {
    final schema = await getSchema();
    
    // Handle parameter paths (remove leaf parameter name)
    final objectPath = _extractObjectPath(path);
    
    return schema.containsKey(objectPath);
  }

  Map<String, SupportedObjectInfo> _buildCache(GetSupportedDMResponse response) {
    final cache = <String, SupportedObjectInfo>{};
    
    for (final result in response.reqObjResults) {
      for (final obj in result.supportedObjs) {
        cache[obj.supportedObjPath] = SupportedObjectInfo(
          path: obj.supportedObjPath,
          isMultiInstance: obj.isMultiInstance,
          params: obj.supportedParams.map((p) => p.paramName).toSet(),
        );
      }
    }
    
    return cache;
  }

  String _extractObjectPath(String fullPath) {
    // "Device.WiFi.Radio.1.Channel" → "Device.WiFi.Radio.{i}."
    // This is a simplified version; real implementation needs proper parsing
    final parts = fullPath.split('.');
    final objectParts = <String>[];
    
    for (final part in parts) {
      if (int.tryParse(part) != null) {
        objectParts.add('{i}');
      } else {
        objectParts.add(part);
      }
    }
    
    // Remove last part if it's a parameter (not ending in .)
    if (!fullPath.endsWith('.')) {
      objectParts.removeLast();
    }
    
    return '${objectParts.join('.')}.';
  }
}

class SupportedObjectInfo {
  final String path;
  final bool isMultiInstance;
  final Set<String> params;

  const SupportedObjectInfo({
    required this.path,
    required this.isMultiInstance,
    required this.params,
  });
}
```

---

## Integration with UspClient

### Simplified UI Role

With the router-proxied architecture, the UI's role is greatly simplified:

1. **Send** plain text user query to `/api/ai/chat`
2. **Receive** validated JSON ready for execution
3. **Execute** the JSON via `UspClient.dynamicCall()`
4. **Display** results to user

The UI does **not** handle:
- LLM communication
- Prompt engineering
- JSON validation
- Retry logic

### Public API Extension

**File**: `lib/api/usp_client_dynamic.dart`

```dart
extension DynamicCallExtension on UspClient {
  /// Execute a pre-validated dynamic call JSON from the router's AI proxy
  ///
  /// The JSON has already been validated by usp-llm-proxy on the router.
  /// This method simply executes the operations and returns results.
  ///
  /// Example:
  /// ```dart
  /// // 1. Send user query to router AI proxy
  /// final aiResponse = await http.post(
  ///   Uri.parse('https://router.local/api/ai/chat'),
  ///   body: jsonEncode({'message': 'What channel is my WiFi using?'}),
  /// );
  ///
  /// // 2. Extract pre-validated JSON from response
  /// final responseData = jsonDecode(aiResponse.body);
  /// if (responseData['success'] && responseData['dynamic_call'] != null) {
  ///   // 3. Execute the validated JSON
  ///   final result = await client.dynamicCall(
  ///     jsonEncode(responseData['dynamic_call']),
  ///   );
  ///
  ///   // 4. Display results alongside AI message
  ///   print(responseData['message']); // "Your WiFi is using channel 6"
  ///   print(result.results.first.data); // {"Device.WiFi.Radio.1.Channel": "6"}
  /// }
  /// ```
  Future<DynamicCallResponse> dynamicCall(String json) {
    return _dynamicInterpreter.execute(json);
  }
}
```

### AI Chat Service (UI-side)

**File**: `lib/services/ai_chat_service.dart`

```dart
/// Service for interacting with the router's AI chat proxy
class AiChatService {
  final UspClient _client;
  final String _baseUrl;

  AiChatService(this._client, this._baseUrl);

  /// Send a chat message and execute any resulting dynamic call
  Future<AiChatResult> chat(String userMessage) async {
    // 1. Send to router's AI proxy
    final response = await http.post(
      Uri.parse('$_baseUrl/api/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': userMessage,
        'session_id': _client.sessionId,
      }),
    );

    final data = jsonDecode(response.body);

    // 2. Check for AI proxy errors
    if (!data['success']) {
      return AiChatResult.error(
        message: data['message'],
        errorCode: data['error']?['code'],
      );
    }

    // 3. If there's a dynamic call, execute it
    DynamicCallResponse? uspResult;
    if (data['dynamic_call'] != null) {
      uspResult = await _client.dynamicCall(
        jsonEncode(data['dynamic_call']),
      );
    }

    return AiChatResult.success(
      message: data['message'],
      dynamicCallResult: uspResult,
    );
  }
}

/// Result of an AI chat interaction
class AiChatResult {
  final bool success;
  final String message;
  final DynamicCallResponse? dynamicCallResult;
  final int? errorCode;

  AiChatResult._({
    required this.success,
    required this.message,
    this.dynamicCallResult,
    this.errorCode,
  });

  factory AiChatResult.success({
    required String message,
    DynamicCallResponse? dynamicCallResult,
  }) => AiChatResult._(
    success: true,
    message: message,
    dynamicCallResult: dynamicCallResult,
  );

  factory AiChatResult.error({
    required String message,
    int? errorCode,
  }) => AiChatResult._(
    success: false,
    message: message,
    errorCode: errorCode,
  );
}
```

---

## AI Integration Context (Router-Side)

The `usp-llm-proxy` daemon is responsible for building the LLM context. This happens entirely on the router — the UI has no involvement in prompt engineering.

### System Prompt (configured in usp-llm-proxy)

**File**: `/etc/usp-llm-proxy/system_prompt.txt`

```
You are a router configuration assistant. Generate YAML conforming to the
dynamic-usp-call-request schema to answer user queries about their router.

IMPORTANT: You must ONLY use paths from the available_paths provided in the
system_context. If a path is not listed, it is not accessible.

Available operations:
- Get: Read parameter values
- Set: Update parameter values
- Add: Create new object instances
- GetSupportedDM: Discover available data model paths

Constraints:
- Maximum 20 operations per request
- Maximum 50 paths per Get operation
- Maximum 20 parameters per Set operation
- All paths must start with "Device."
- Operations are atomic: if one fails, all fail

Always respond with BOTH:
1. A natural language message explaining what you're doing
2. The YAML dynamic_call block

Example response format:
message: I'll check your WiFi channel for you.
dynamic_call:
  version: "1.0"
  operations:
    - type: Get
      paths:
        - Device.WiFi.Radio.1.Channel

If the user's request cannot be fulfilled with the available paths, respond with:
message: I'm sorry, I cannot access that information.
dynamic_call: null
```

### Runtime Context Builder (C implementation in usp-llm-proxy)

The proxy builds context by querying `GetSupportedDM` and filtering to whitelisted paths:

```c
// In usp-llm-proxy/src/context_builder.c

char* build_llm_context(usp_client_t* client, path_whitelist_t* whitelist) {
    // 1. Get supported data model from OBUSPA
    get_supported_dm_response_t* dm = usp_client_get_supported_dm(
        client,
        "Device.",
        false,  // not first_level_only
        true,   // return_params
        false,  // return_commands
        false   // return_events
    );

    // 2. Filter to whitelisted paths only
    json_t* available_paths = json_array();
    for (int i = 0; i < dm->num_objects; i++) {
        if (whitelist_allows(whitelist, dm->objects[i].path)) {
            json_t* obj = json_object();
            json_object_set(obj, "path", json_string(dm->objects[i].path));
            json_object_set(obj, "params", params_to_json(dm->objects[i].params));
            json_object_set(obj, "multi_instance", json_boolean(dm->objects[i].multi));
            json_array_append(available_paths, obj);
        }
    }

    // 3. Build final context JSON
    json_t* context = json_object();
    json_object_set(context, "available_paths", available_paths);
    json_object_set(context, "schema_version", json_string("1.0"));
    json_object_set(context, "limits", build_limits_json(whitelist));

    return json_dumps(context, JSON_COMPACT);
}
```

### Context Caching

The `usp-llm-proxy` caches the data model context to avoid repeated `GetSupportedDM` calls:

| Cache Behavior | Value |
|----------------|-------|
| Cache duration | Session lifetime or 1 hour |
| Invalidation | On explicit refresh or config change |
| Storage | In-memory (RAM) |

---

## Future Extensibility: Subscriptions

The schema reserves space for subscription operations, but they are not implemented in v1:

```json
{
  "type": "Subscribe",
  "subscription": {
    "id": "ai-monitor-1",
    "paths": ["Device.WiFi.Radio.*.Channel"],
    "notifyType": "ValueChange"
  }
}
```

When received, the validator returns:

```json
{
  "success": false,
  "errors": [{
    "code": 8006,
    "message": "Operation type 'Subscribe' not yet supported"
  }]
}
```

This allows future implementation without schema changes.

---

## Security Considerations

### Audit Logging

All dynamic calls should be logged:

```dart
class DynamicCallAuditLog {
  void log(DynamicCallAuditEntry entry);
}

class DynamicCallAuditEntry {
  final DateTime timestamp;
  final String sessionId;
  final String requestJson;
  final bool success;
  final List<String> pathsAccessed;
  final List<String> pathsModified;
  final String? errorMessage;
}
```

### Rate Limiting

Implement per-session rate limiting for dynamic calls:

```dart
class DynamicCallRateLimiter {
  final int maxCallsPerMinute;
  final int maxCallsPerHour;
  
  bool shouldAllow(String sessionId);
  void recordCall(String sessionId);
}
```

### Recommended Limits

| Limit | Value | Rationale |
|-------|-------|-----------|
| Calls per minute | 10 | Prevent rapid-fire abuse |
| Calls per hour | 100 | Allow normal AI interaction |
| Max batch size | 20 | Limit complexity per call |
| Max total paths | 100 | Prevent data exfiltration |

---

## Error Handling Examples

### Validation Failure

**Request**:
```json
{
  "version": "1.0",
  "operations": [
    {"type": "Get", "paths": ["Device.Users.User.1.Password"]}
  ]
}
```

**Response**:
```json
{
  "success": false,
  "results": [],
  "errors": [{
    "operationIndex": 0,
    "path": "Device.Users.User.1.Password",
    "code": 8002,
    "message": "Path denied: User credentials are never exposed"
  }]
}
```

### USP Error (Atomic Failure)

**Request**:
```json
{
  "version": "1.0",
  "operations": [
    {"type": "Set", "params": [
      {"path": "Device.WiFi.Radio.1.Channel", "value": 6}
    ]},
    {"type": "Set", "params": [
      {"path": "Device.WiFi.Radio.1.Channel", "value": 999}
    ]}
  ]
}
```

**Response**:
```json
{
  "success": false,
  "results": [],
  "errors": [{
    "operationIndex": 1,
    "path": "Device.WiFi.Radio.1.Channel",
    "code": 7012,
    "message": "Invalid value"
  }]
}
```

Note: Even though operation 0 would have succeeded, no results are returned because the batch failed atomically.

---

## Testing

### Unit Test Examples

```dart
void main() {
  group('DynamicCallValidator', () {
    late DynamicCallValidator validator;
    
    setUp(() {
      validator = DynamicCallValidator(PathWhitelist.fromAsset());
    });

    test('allows whitelisted Get paths', () {
      final request = DynamicCallRequest.fromJson('''
        {
          "version": "1.0",
          "operations": [
            {"type": "Get", "paths": ["Device.DeviceInfo.ModelName"]}
          ]
        }
      ''');
      
      expect(() => validator.validate(request), returnsNormally);
    });

    test('rejects denied paths', () {
      final request = DynamicCallRequest.fromJson('''
        {
          "version": "1.0",
          "operations": [
            {"type": "Get", "paths": ["Device.Users.User.1.Password"]}
          ]
        }
      ''');
      
      expect(
        () => validator.validate(request),
        throwsA(isA<DynamicCallValidationException>()
          .having((e) => e.code, 'code', 8002)),
      );
    });

    test('rejects Set on read-only paths', () {
      final request = DynamicCallRequest.fromJson('''
        {
          "version": "1.0",
          "operations": [
            {"type": "Set", "params": [
              {"path": "Device.DeviceInfo.ModelName", "value": "Hacked"}
            ]}
          ]
        }
      ''');
      
      expect(
        () => validator.validate(request),
        throwsA(isA<DynamicCallValidationException>()
          .having((e) => e.code, 'code', 8003)),
      );
    });
  });
}
```
