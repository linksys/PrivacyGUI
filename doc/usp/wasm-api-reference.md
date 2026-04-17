# WASM Client API Reference

USP Client WASM bindings — JavaScript API for all USP TR-369 operations.

## Unified Response Format

All operations return the same top-level structure:

```typescript
interface UnifiedResponse {
  success: boolean;           // true if at least one operation succeeded
  result: {
    data: Record<string, any>;   // operation-specific success data
    error?: Record<string, {     // per-path error details (optional — absent when no errors)
      errorCode: number;
      errorMessage: string;
    }>;
  };
}
```

### Three States

| State | Condition | Meaning |
|-------|-----------|---------|
| All success | `success === true && !result.error` | Every requested path succeeded |
| Partial success | `success === true && result.error` | At least one succeeded, but some failed |
| All failure | `success === false` | No path succeeded |

> **Note:** `result.error` is **optional** — it is only present when there are errors. On all-success responses, the `error` field is omitted entirely to reduce payload size.

---

## Error Codes

### USP Agent Errors (7xxx) — TR-369 Spec

| Code | Name | Description |
|------|------|-------------|
| 7000 | Message failed | General message processing failure |
| 7001 | Message not understood | Malformed or unsupported message |
| 7004 | Invalid arguments | Bad input arguments to command |
| 7010 | Unsupported parameter | Parameter not supported by agent |
| 7012 | Invalid type | Value type does not match schema |
| 7013 | Read-only parameter | Per-parameter error: parameter is not writable (returned inside OperSuccess as ParameterError) |
| 7016 | Invalid value | Value outside allowed range |
| 7020 | Parameter not writable | Object-level SET failure: attempted write on read-only path |
| 7021 | Value conflict | Conflicting parameter values |
| 7022 | Value change not allowed | Parameter cannot be modified in current state |
| 7024 | Resources exceeded | Agent resource limit reached |
| 7026 | Path not found | Requested path does not exist in schema |
| 7027 | Object not creatable | Cannot create instance at this path |
| 7028 | Object not deletable | Cannot delete instance at this path |
| 7029 | Command failure | Operate command execution failed |

> Agent error codes are defined by the device firmware. The list above covers common codes; specific devices may return additional codes in the 7xxx range.

### Client-Side Errors (9xxx)

| Code | Name | Description |
|------|------|-------------|
| 9999 | Transport error | Network/connection failure (e.g., device unreachable, timeout) |
| 9998 | Data format error | Response protobuf decode failure or unexpected structure |
| 9997 | Parameter validation error | Client-side input validation failure |

---

## Operations

### GET — Read Parameters

#### `client.get(path: string): Promise<UnifiedResponse>`

Read a single parameter or object path.

**Request:**
```javascript
const result = await client.get("Device.DeviceInfo.Manufacturer");
```

**Response — `result.data`:** `{ "full.param.path": "value", ... }`

```json
{
  "success": true,
  "result": {
    "data": {
      "Device.DeviceInfo.Manufacturer": "Linksys"
    }
  }
}
```

#### `client.getMultiple(paths: string[]): Promise<UnifiedResponse>`

Read multiple parameters in a single request.

**Request:**
```javascript
const result = await client.getMultiple([
  "Device.DeviceInfo.Manufacturer",
  "Device.DeviceInfo.ModelName",
  "Device.NonExistent.Path"
]);
```

**Response — Partial success:**

```json
{
  "success": true,
  "result": {
    "data": {
      "Device.DeviceInfo.Manufacturer": "Linksys",
      "Device.DeviceInfo.ModelName": "MR7500"
    },
    "error": {
      "Device.NonExistent.Path": {
        "errorCode": 7026,
        "errorMessage": "Path does not exist in the schema"
      }
    }
  }
}
```

> **Note:** Wildcard paths (e.g., `Device.Hosts.Host.*`) are query markers. The agent expands them to concrete instance paths in the response data.

---

### SET — Write Parameters

#### `client.set(path: string, value: string): Promise<UnifiedResponse>`

Set a single parameter value.

**Request:**
```javascript
const result = await client.set("Device.WiFi.SSID.1.SSID", "MyNetwork");
```

**Response — `result.data`:** Echo back updated parameters as `{ "affectedPath.paramKey": "newValue", ... }`

```json
{
  "success": true,
  "result": {
    "data": {
      "Device.WiFi.SSID.1.SSID": "MyNetwork"
    }
  }
}
```

#### `client.setMultiple(parameters: object, allowPartial: boolean): Promise<UnifiedResponse>`

Set multiple parameters. `allowPartial: false` = atomic mode (all-or-nothing).

**Request:**
```javascript
const result = await client.setMultiple({
  "Device.WiFi.SSID.1.SSID": "MyNetwork",
  "Device.WiFi.SSID.1.Enable": "true"
}, true);
```

**Response — All success:**

```json
{
  "success": true,
  "result": {
    "data": {
      "Device.WiFi.SSID.1.SSID": "MyNetwork",
      "Device.WiFi.SSID.1.Enable": "true"
    }
  }
}
```

**Response — Read-only parameter error (per-parameter ParameterError):**

When SET targets a read-only parameter, the agent returns `OperSuccess` with a `ParameterError` entry (not `OperationFailure`). The client surfaces this as `success: false` with the per-parameter error:

```javascript
const result = await client.set("Device.DeviceInfo.Manufacturer", "TestValue");
```

```json
{
  "success": false,
  "result": {
    "data": {},
    "error": {
      "Device.DeviceInfo.Manufacturer": {
        "errorCode": 7013,
        "errorMessage": "Parameter is not writable"
      }
    }
  }
}
```

> **Note:** Error code `7013` is a per-parameter error inside `OperSuccess.UpdatedInstanceResult.ParameterError`, distinct from `7020` which is an object-level `OperationFailure`. Both indicate a read-only parameter, but they come from different levels of the USP protobuf response.

---

### ADD — Create Object Instances

#### `client.add(objectPath: string, parameters?: object): Promise<UnifiedResponse>`

Create a new object instance with optional initial parameters.

**Request:**
```javascript
const result = await client.add("Device.NAT.PortMapping.", {
  "ExternalPort": "8080",
  "InternalPort": "80",
  "Protocol": "TCP"
});
```

**Response — `result.data`:** `{ affectedCount: number, instances: string[] }`

```json
{
  "success": true,
  "result": {
    "data": {
      "affectedCount": 1,
      "instances": ["Device.NAT.PortMapping.3."]
    }
  }
}
```

#### `client.addMultiple(objects: Array<{path, parameters}>, allowPartial: boolean): Promise<UnifiedResponse>`

Create multiple object instances.

**Request:**
```javascript
const result = await client.addMultiple([
  { path: "Device.NAT.PortMapping.", parameters: { "ExternalPort": "8080" } },
  { path: "Device.NAT.PortMapping.", parameters: { "ExternalPort": "8443" } }
], true);
```

**Response — Partial success:**

```json
{
  "success": true,
  "result": {
    "data": {
      "affectedCount": 1,
      "instances": ["Device.NAT.PortMapping.3."]
    },
    "error": {
      "Device.NAT.PortMapping.": {
        "errorCode": 7024,
        "errorMessage": "Resources exceeded"
      }
    }
  }
}
```

---

### DELETE — Remove Object Instances

#### `client.delete(path: string): Promise<UnifiedResponse>`

Delete a single object instance.

**Request:**
```javascript
const result = await client.delete("Device.NAT.PortMapping.3.");
```

**Response — `result.data`:** `{ affectedCount: number, instances: string[] }`

```json
{
  "success": true,
  "result": {
    "data": {
      "affectedCount": 1,
      "instances": ["Device.NAT.PortMapping.3."]
    }
  }
}
```

#### `client.deleteMultiple(paths: string[], allowPartial: boolean): Promise<UnifiedResponse>`

Delete multiple object instances.

**Request:**
```javascript
const result = await client.deleteMultiple([
  "Device.NAT.PortMapping.3.",
  "Device.NAT.PortMapping.4."
], false);
```

---

### OPERATE — Execute Commands

#### `client.operate(command: string, args: object): Promise<UnifiedResponse>`

Execute a USP command (synchronous or asynchronous).

**Request:**
```javascript
const result = await client.operate("Device.IP.Diagnostics.Ping()", {
  "Host": "8.8.8.8",
  "NumberOfRepetitions": "4"
});
```

**Response — `result.data`:** `{ commandKey: string, outputArgs: object }`

Synchronous command (output available immediately):
```json
{
  "success": true,
  "result": {
    "data": {
      "commandKey": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "outputArgs": {
        "Status": "Complete",
        "SuccessCount": "4",
        "AverageResponseTime": "12"
      }
    }
  }
}
```

Asynchronous command (result delivered via notification):
```json
{
  "success": true,
  "result": {
    "data": {
      "commandKey": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "outputArgs": {}
    }
  }
}
```

Command failure:
```json
{
  "success": false,
  "result": {
    "data": {},
    "error": {
      "Device.IP.Diagnostics.Ping()": {
        "errorCode": 7029,
        "errorMessage": "Command failure"
      }
    }
  }
}
```

---

## Transport Error Format

When the device is unreachable or the connection fails, all operations return:

```json
{
  "success": false,
  "result": {
    "data": {},
    "error": {
      "<requested-path>": {
        "errorCode": 9999,
        "errorMessage": "Transport error: <details>"
      }
    }
  }
}
```

This format is identical across GET, SET, ADD, DELETE, and OPERATE.

---

## Authentication

Authentication methods do **not** use the unified response format.

#### `client.login(password: string): Promise<void>`

Authenticate with the device. Stores session token internally.

```javascript
await client.login("mypassword");
```

#### `client.logout(): Promise<void>`

Clear authentication state.

```javascript
await client.logout();
```

#### `client.isAuthenticated(): boolean`

Check if client has a valid session.

#### `client.getToken(): string | undefined`

Get the current session JWT token (for direct API calls like SSE).

---

## Subscription API

#### `client.subscribe(id: string, path: string, type: number): Promise<void>`

Register a USP notification subscription.

| Type | Value | Description |
|------|-------|-------------|
| ValueChange | 1 | Parameter value changed |
| ObjectCreation | 2 | New object instance created |
| ObjectDeletion | 3 | Object instance deleted |

```javascript
await client.subscribe("sub-1", "Device.WiFi.SSID.1.SSID", 1);
```

#### `client.unsubscribe(id: string): Promise<void>`

Remove a notification subscription.

#### `client.notificationsUrl(): string`

Returns the full SSE endpoint URL for manual Bearer token auth.
