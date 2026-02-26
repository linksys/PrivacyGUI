# usp-client Specification

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |

---

## Overview

`usp-client` is a Rust library that provides the core client functionality for communicating with USP Agents. It handles protobuf encoding/decoding, HTTP transport, authentication, and provides both typed and JSON-based APIs.

### Purpose

- Encode/decode USP protobuf messages
- Handle HTTP transport to the router
- Manage authentication (JWT tokens, cookies)
- Provide typed API for generated code
- Provide JSON API for dynamic calls
- Support multiple platforms via WASM and native builds

### Language

Rust

### Build Targets

| Target | Output | Use Case |
|--------|--------|----------|
| Native | `libusp_client.so/.dylib/.dll` | FFI from Dart, Swift, etc. |
| WASM | `usp_client.wasm` + JS glue | Web browsers |
| CLI | `usp-cli` | Testing/debugging |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              usp-client                                      │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                           Public API                                    │ │
│  │                                                                         │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐  │ │
│  │  │   Typed API     │  │    JSON API     │  │    Auth API             │  │ │
│  │  │   get/set/add/  │  │  execute_json() │  │  login/logout/refresh   │  │ │
│  │  │   delete/operate│  │                 │  │                         │  │ │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────────────┘  │ │
│  └───────────┼────────────────────┼────────────────────┼────────────────────┘ │
│              │                    │                    │                      │
│              └────────────────────┼────────────────────┘                      │
│                                   │                                           │
│  ┌────────────────────────────────┴────────────────────────────────────────┐  │
│  │                         Core Layer                                      │  │
│  │                                                                         │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐  │  │
│  │  │ USP Message     │  │   HTTP Client   │  │   Token Manager         │  │  │
│  │  │ Builder/Parser  │  │                 │  │                         │  │  │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────────────┘  │  │
│  │           │                    │                    │                   │  │
│  │           └────────────────────┼────────────────────┘                   │  │
│  │                                │                                        │  │
│  │  ┌─────────────────────────────┴─────────────────────────────────────┐  │  │
│  │  │                      Protobuf Codec                               │  │  │
│  │  └───────────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## C ABI (FFI Interface)

### Header File

**File:** `include/usp_client.h`

```c
#ifndef USP_CLIENT_H
#define USP_CLIENT_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque client handle
typedef struct UspClient UspClient;

// ============================================================================
// Lifecycle
// ============================================================================

/**
 * Create a new USP client instance.
 * @param base_url Router URL (e.g., "https://192.168.1.1")
 * @return Client handle or NULL on error
 */
UspClient* usp_client_new(const char* base_url);

/**
 * Free a USP client instance.
 * @param client Client handle
 */
void usp_client_free(UspClient* client);

// ============================================================================
// Authentication
// ============================================================================

/**
 * Login to the router.
 * @param client Client handle
 * @param password User password
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_login(UspClient* client, const char* password);

/**
 * Logout from the router.
 * @param client Client handle
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_logout(UspClient* client);

/**
 * Refresh the authentication token.
 * @param client Client handle
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_refresh(UspClient* client);

/**
 * Check if client is authenticated.
 * @param client Client handle
 * @return true if authenticated
 */
bool usp_client_is_authenticated(const UspClient* client);

// ============================================================================
// Typed API (for generated code)
// ============================================================================

/**
 * USP Get operation.
 * @param client Client handle
 * @param paths Array of TR-181 paths
 * @param path_count Number of paths
 * @param max_depth Maximum depth for partial paths (0 = no limit)
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_get(
    UspClient* client,
    const char** paths,
    int path_count,
    int max_depth
);

/**
 * USP Set operation.
 * @param client Client handle
 * @param keys Array of TR-181 paths
 * @param values Array of values
 * @param count Number of key-value pairs
 * @param allow_partial Allow partial success
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_set(
    UspClient* client,
    const char** keys,
    const char** values,
    int count,
    bool allow_partial
);

/**
 * USP Add operation.
 * @param client Client handle
 * @param path Object path (e.g., "Device.NAT.PortMapping.")
 * @param keys Array of parameter names
 * @param values Array of values
 * @param count Number of parameters
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_add(
    UspClient* client,
    const char* path,
    const char** keys,
    const char** values,
    int count
);

/**
 * USP Delete operation.
 * @param client Client handle
 * @param paths Array of object paths to delete
 * @param path_count Number of paths
 * @param allow_partial Allow partial success
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_delete(
    UspClient* client,
    const char** paths,
    int path_count,
    bool allow_partial
);

/**
 * USP Operate operation.
 * @param client Client handle
 * @param command Command path (e.g., "Device.Reboot()")
 * @param keys Array of input parameter names
 * @param values Array of input values
 * @param count Number of input parameters
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_operate(
    UspClient* client,
    const char* command,
    const char** keys,
    const char** values,
    int count
);

/**
 * USP GetSupportedDM operation.
 * @param client Client handle
 * @param paths Array of paths to query
 * @param path_count Number of paths
 * @param first_level_only Only return immediate children
 * @param return_commands Include commands
 * @param return_events Include events
 * @param return_params Include parameters
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_get_supported_dm(
    UspClient* client,
    const char** paths,
    int path_count,
    bool first_level_only,
    bool return_commands,
    bool return_events,
    bool return_params
);

// ============================================================================
// JSON API (for dynamic calls)
// ============================================================================

/**
 * Execute a dynamic call from JSON.
 * @param client Client handle
 * @param json_request JSON string conforming to dynamic_call schema
 * @return JSON response or error string (must be freed with usp_string_free)
 */
const char* usp_client_execute_json(UspClient* client, const char* json_request);

// ============================================================================
// Memory Management
// ============================================================================

/**
 * Free a string returned by usp_client_* functions.
 * @param s String to free
 */
void usp_string_free(const char* s);

#ifdef __cplusplus
}
#endif

#endif // USP_CLIENT_H
```

---

## Rust API

### Public Types

```rust
/// USP Client configuration
pub struct UspClientConfig {
    pub base_url: String,
    pub timeout: Duration,
    pub verify_ssl: bool,
}

/// USP Client
pub struct UspClient {
    config: UspClientConfig,
    http_client: HttpClient,
    token_manager: TokenManager,
}

/// Authentication response
pub struct AuthResponse {
    pub controller_endpoint_id: String,
    pub turbo_controller_endpoint_id: String,
    pub agent_endpoint_id: String,
    pub token: Option<String>,
}

/// Get response
pub struct GetResponse {
    pub params: HashMap<String, Value>,
}

/// Set response
pub struct SetResponse {
    pub updated_params: Vec<String>,
}

/// Add response
pub struct AddResponse {
    pub created_path: String,
    pub unique_keys: HashMap<String, String>,
}

/// Delete response
pub struct DeleteResponse {
    pub deleted_paths: Vec<String>,
}

/// Operate response
pub struct OperateResponse {
    pub output_args: HashMap<String, Value>,
}

/// USP Error
#[derive(Debug)]
pub enum UspError {
    Transport(String),
    Auth(String),
    UspError { code: u32, message: String },
    InvalidResponse(String),
    Timeout,
}
```

### Client Implementation

```rust
impl UspClient {
    /// Create a new USP client
    pub fn new(base_url: &str) -> Result<Self, UspError>;

    /// Login to the router
    pub async fn login(&mut self, password: &str) -> Result<AuthResponse, UspError>;

    /// Logout from the router
    pub async fn logout(&mut self) -> Result<(), UspError>;

    /// Refresh authentication token
    pub async fn refresh(&mut self) -> Result<(), UspError>;

    /// Check if authenticated
    pub fn is_authenticated(&self) -> bool;

    /// USP Get operation
    pub async fn get(
        &self,
        paths: &[&str],
        max_depth: Option<u32>,
    ) -> Result<GetResponse, UspError>;

    /// USP Set operation
    pub async fn set(
        &self,
        params: &HashMap<String, Value>,
        allow_partial: bool,
    ) -> Result<SetResponse, UspError>;

    /// USP Add operation
    pub async fn add(
        &self,
        path: &str,
        params: &HashMap<String, Value>,
    ) -> Result<AddResponse, UspError>;

    /// USP Delete operation
    pub async fn delete(
        &self,
        paths: &[&str],
        allow_partial: bool,
    ) -> Result<DeleteResponse, UspError>;

    /// USP Operate operation
    pub async fn operate(
        &self,
        command: &str,
        input_args: &HashMap<String, Value>,
    ) -> Result<OperateResponse, UspError>;

    /// USP GetSupportedDM operation
    pub async fn get_supported_dm(
        &self,
        paths: &[&str],
        options: GetSupportedDmOptions,
    ) -> Result<GetSupportedDmResponse, UspError>;

    /// Execute dynamic call from JSON
    pub async fn execute_json(&self, json: &str) -> Result<String, UspError>;
}
```

---

## Protobuf Handling

### USP Record Structure

```rust
/// Build a USP Record wrapping a USP Message
fn build_usp_record(
    from_id: &str,
    to_id: &str,
    message: &UspMessage,
) -> Vec<u8> {
    let record = UspRecord {
        version: "1.3".to_string(),
        to_id: to_id.to_string(),
        from_id: from_id.to_string(),
        payload_security: PayloadSecurity::Plaintext as i32,
        record_type: Some(RecordType::NoSessionContext(
            NoSessionContextRecord {
                payload: message.encode_to_vec(),
            }
        )),
        ..Default::default()
    };
    record.encode_to_vec()
}
```

### Message ID Generation

```rust
/// Generate unique message ID
fn generate_msg_id() -> String {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64;

    let counter = COUNTER.fetch_add(1, Ordering::SeqCst);

    format!("{:x}-{:x}", timestamp, counter)
}
```

---

## HTTP Transport

### Request Handling

```rust
async fn send_usp_request(
    &self,
    record: &[u8],
) -> Result<Vec<u8>, UspError> {
    let response = self.http_client
        .post(&format!("{}/api/usp", self.config.base_url))
        .header("Content-Type", "application/x-protobuf")
        .header("Cookie", self.token_manager.get_cookie())
        .body(record.to_vec())
        .timeout(self.config.timeout)
        .send()
        .await
        .map_err(|e| UspError::Transport(e.to_string()))?;

    match response.status().as_u16() {
        200 => Ok(response.bytes().await?.to_vec()),
        401 => Err(UspError::Auth("Unauthorized".to_string())),
        504 => Err(UspError::Timeout),
        status => Err(UspError::Transport(format!("HTTP {}", status))),
    }
}
```

### Token Management

```rust
struct TokenManager {
    token: Option<String>,
    cookie_name: String,
    expires_at: Option<SystemTime>,
}

impl TokenManager {
    fn set_from_response(&mut self, response: &AuthResponse) {
        self.token = response.token.clone();
        // Parse expiry from JWT if available
    }

    fn get_cookie(&self) -> String {
        match &self.token {
            Some(t) => format!("{}={}", self.cookie_name, t),
            None => String::new(),
        }
    }

    fn get_header(&self) -> Option<String> {
        self.token.as_ref().map(|t| format!("Bearer {}", t))
    }

    fn is_valid(&self) -> bool {
        match self.expires_at {
            Some(exp) => SystemTime::now() < exp,
            None => self.token.is_some(),
        }
    }
}
```

---

## JSON API Implementation

### Dynamic Call Execution

```rust
pub async fn execute_json(&self, json: &str) -> Result<String, UspError> {
    // Parse JSON request
    let request: DynamicCallRequest = serde_json::from_str(json)
        .map_err(|e| UspError::InvalidResponse(e.to_string()))?;

    // Execute operations
    let mut results = Vec::new();

    for (index, op) in request.operations.iter().enumerate() {
        let result = match op.op_type.as_str() {
            "Get" => self.execute_get_op(op).await?,
            "Set" => self.execute_set_op(op).await?,
            "Add" => self.execute_add_op(op).await?,
            "Delete" => self.execute_delete_op(op).await?,
            "Operate" => self.execute_operate_op(op).await?,
            _ => return Err(UspError::InvalidResponse(
                format!("Unknown operation type: {}", op.op_type)
            )),
        };

        results.push(DynamicOperationResult {
            operation_index: index,
            op_type: op.op_type.clone(),
            success: true,
            data: Some(result),
            error: None,
        });
    }

    // Build response
    let response = DynamicCallResponse {
        success: true,
        results,
    };

    serde_json::to_string(&response)
        .map_err(|e| UspError::InvalidResponse(e.to_string()))
}
```

---

## WASM Build

### Cargo.toml Configuration

```toml
[lib]
crate-type = ["cdylib", "rlib"]

[target.'cfg(target_arch = "wasm32")'.dependencies]
wasm-bindgen = "0.2"
wasm-bindgen-futures = "0.4"
js-sys = "0.3"
web-sys = { version = "0.3", features = ["Window", "Request", "Response", "Headers"] }

[profile.release]
opt-level = "z"
lto = true
```

### WASM Bindings

```rust
#[cfg(target_arch = "wasm32")]
use wasm_bindgen::prelude::*;

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
pub struct WasmUspClient {
    inner: UspClient,
}

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
impl WasmUspClient {
    #[wasm_bindgen(constructor)]
    pub fn new(base_url: &str) -> Result<WasmUspClient, JsValue> {
        let inner = UspClient::new(base_url)
            .map_err(|e| JsValue::from_str(&e.to_string()))?;
        Ok(WasmUspClient { inner })
    }

    #[wasm_bindgen]
    pub async fn login(&mut self, password: &str) -> Result<JsValue, JsValue> {
        let result = self.inner.login(password).await
            .map_err(|e| JsValue::from_str(&e.to_string()))?;
        serde_wasm_bindgen::to_value(&result)
            .map_err(|e| JsValue::from_str(&e.to_string()))
    }

    #[wasm_bindgen]
    pub async fn get(&self, paths: Vec<JsValue>) -> Result<JsValue, JsValue> {
        let paths: Vec<String> = paths.into_iter()
            .filter_map(|v| v.as_string())
            .collect();
        let paths_ref: Vec<&str> = paths.iter().map(|s| s.as_str()).collect();

        let result = self.inner.get(&paths_ref, None).await
            .map_err(|e| JsValue::from_str(&e.to_string()))?;
        serde_wasm_bindgen::to_value(&result)
            .map_err(|e| JsValue::from_str(&e.to_string()))
    }

    #[wasm_bindgen]
    pub async fn execute_json(&self, json: &str) -> Result<String, JsValue> {
        self.inner.execute_json(json).await
            .map_err(|e| JsValue::from_str(&e.to_string()))
    }
}
```

---

## CLI Tool

### Usage

```bash
# Login
usp-cli --url https://192.168.1.1 login

# Get parameters
usp-cli get Device.DeviceInfo.ModelName Device.DeviceInfo.SerialNumber

# Set parameter
usp-cli set Device.WiFi.SSID.1.SSID="NewNetwork"

# Add object
usp-cli add Device.NAT.PortMapping. Protocol=TCP ExternalPort=8080 InternalPort=80

# Delete object
usp-cli delete Device.NAT.PortMapping.3.

# Operate
usp-cli operate Device.Reboot()

# Execute JSON
usp-cli execute-json '{"version":"1.0","operations":[{"type":"Get","paths":["Device.DeviceInfo.ModelName"]}]}'
```

### Implementation

```rust
#[derive(Parser)]
#[command(name = "usp-cli")]
struct Cli {
    #[arg(long, default_value = "https://192.168.1.1")]
    url: String,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Login,
    Get { paths: Vec<String> },
    Set { params: Vec<String> },
    Add { path: String, params: Vec<String> },
    Delete { paths: Vec<String> },
    Operate { command: String, params: Vec<String> },
    ExecuteJson { json: String },
}
```

---

## Error Handling

### USP Error Codes

| Code Range | Category |
|------------|----------|
| 7000-7099 | General message errors |
| 7100-7199 | Get errors |
| 7200-7299 | Set errors |
| 7300-7399 | Add errors |
| 7400-7499 | Delete errors |
| 7500-7599 | Operate errors |

### Error Response Format

```rust
#[derive(Serialize, Deserialize)]
struct ErrorResponse {
    success: bool,
    error: ErrorDetail,
}

#[derive(Serialize, Deserialize)]
struct ErrorDetail {
    code: u32,
    message: String,
    path: Option<String>,
}
```

---

## Build & Deployment

### Build Commands

```bash
# Native library
cargo build --release

# WASM
wasm-pack build --target web --release

# CLI
cargo build --release --bin usp-cli
```

### Output Files

| Build | Output |
|-------|--------|
| Linux | `target/release/libusp_client.so` |
| macOS | `target/release/libusp_client.dylib` |
| Windows | `target/release/usp_client.dll` |
| WASM | `pkg/usp_client.wasm`, `pkg/usp_client.js` |
| CLI | `target/release/usp-cli` |

### Dart FFI Integration

```dart
// Load native library
final lib = Platform.isAndroid
    ? DynamicLibrary.open('libusp_client.so')
    : Platform.isIOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open('libusp_client.dylib');

// Bind functions
typedef UspClientNewNative = Pointer<Void> Function(Pointer<Utf8>);
typedef UspClientNew = Pointer<Void> Function(Pointer<Utf8>);

final uspClientNew = lib.lookupFunction<UspClientNewNative, UspClientNew>('usp_client_new');
```

---

## Testing

### Unit Tests

```bash
cargo test
```

### Integration Tests

```bash
# With mock server
cargo test --features integration-tests

# Against real router
USP_TEST_URL=https://192.168.1.1 USP_TEST_PASSWORD=secret cargo test --features live-tests
```

### WASM Tests

```bash
wasm-pack test --headless --chrome
```
