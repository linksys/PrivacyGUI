# usp-auth-cgi Specification

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |

---

## Overview

`usp-auth-cgi` is a CGI program that handles authentication for the USP-driven UI. It validates passwords, generates JWT tokens, and manages token refresh with grace periods.

### Purpose

- Validate user password against stored hash
- Generate JWT tokens with session information
- Handle token refresh with grace period for expired tokens
- Provide logout functionality

### Language

C (for minimal footprint and fast execution)

### Dependencies

- libjansson (JSON handling)
- OpenSSL or mbedTLS (JWT signing, password hashing)
- libuci (UCI configuration reading)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      lighttpd                               │
│                                                             │
│  /api/auth/* ──► CGI exec ──► usp-auth-cgi                 │
└─────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                     usp-auth-cgi                            │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Password   │  │    JWT      │  │     Session         │  │
│  │  Validator  │  │  Generator  │  │     Generator       │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                    │             │
│         └────────────────┼────────────────────┘             │
│                          │                                  │
│                   ┌──────┴──────┐                           │
│                   │ UCI Config  │                           │
│                   └─────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

---

## HTTP API

### Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/auth/login` | POST | None | Authenticate and get JWT |
| `/api/auth/refresh` | POST | JWT | Refresh JWT token |
| `/api/auth/logout` | POST | JWT | Invalidate session |

### POST /api/auth/login

Authenticate with password and receive JWT token.

**Request:**
```json
{
  "password": "user_password"
}
```

**Response (200 OK):**
```
Set-Cookie: usp_session=<JWT>; HttpOnly; Secure; SameSite=Strict; Path=/api

{
  "controller_endpoint_id": "controller::localui",
  "turbo_controller_endpoint_id": "controller::localui-turbo",
  "agent_endpoint_id": "agent::ABC123456",
  "token": "<JWT>"
}
```

**Response (401 Unauthorized):**
```json
{
  "error": "invalid_password"
}
```

**Response (429 Too Many Requests):**
```json
{
  "error": "rate_limited",
  "retry_after_seconds": 30
}
```

### POST /api/auth/refresh

Refresh an existing JWT token.

**Request:**
```
POST /api/auth/refresh HTTP/1.1
Cookie: usp_session=<JWT>
```

Or for mobile apps:
```
POST /api/auth/refresh HTTP/1.1
Authorization: Bearer <JWT>
```

**Response (200 OK):**
```
Set-Cookie: usp_session=<new JWT>; HttpOnly; Secure; SameSite=Strict; Path=/api

{
  "token": "<new JWT>"
}
```

**Response (401 Unauthorized):**
```json
{
  "error": "token_expired",
  "message": "Token expired beyond grace period"
}
```

### POST /api/auth/logout

Invalidate the current session.

**Request:**
```
POST /api/auth/logout HTTP/1.1
Cookie: usp_session=<JWT>
```

**Response (200 OK):**
```
Set-Cookie: usp_session=; HttpOnly; Secure; SameSite=Strict; Path=/api; Max-Age=0

{
  "status": "ok"
}
```

---

## JWT Structure

### Header

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

### Payload (Claims)

```json
{
  "iat": 1704067200,
  "exp": 1704070800,
  "role": "admin",
  "session_id": "sess_a1b2c3d4e5f67890"
}
```

### Claims Description

| Claim | Type | Description |
|-------|------|-------------|
| `iat` | int | Issued at (Unix timestamp) |
| `exp` | int | Expiration time (Unix timestamp) |
| `role` | string | User role (always "admin" for local UI) |
| `session_id` | string | Unique session identifier |

### Signature

HMAC-SHA256 with secret key from configuration.

---

## Session ID Generation

Session IDs must be globally unique, including across router reboots.

### Format

```
sess_<timestamp_hex><random_hex>
```

Example: `sess_659e1a8037b4c2d1`

### Implementation

```c
void generate_session_id(char *buf, size_t len) {
    uint32_t timestamp = (uint32_t)time(NULL);
    uint32_t random_val;

    // Use getrandom() for cryptographic randomness
    if (getrandom(&random_val, sizeof(random_val), 0) != sizeof(random_val)) {
        // Fallback to /dev/urandom
        FILE *f = fopen("/dev/urandom", "r");
        fread(&random_val, sizeof(random_val), 1, f);
        fclose(f);
    }

    snprintf(buf, len, "sess_%08x%08x", timestamp, random_val);
}
```

---

## Password Handling

### Storage

Password hash is stored in UCI configuration:

```
config auth 'main'
    option password_hash '$argon2id$v=19$m=65536,t=3,p=4$...'
```

### Hash Algorithm

Argon2id (preferred) or bcrypt (fallback).

### Validation

```c
bool validate_password(const char *password, const char *hash) {
    if (strncmp(hash, "$argon2", 7) == 0) {
        return argon2id_verify(hash, password, strlen(password)) == ARGON2_OK;
    } else if (strncmp(hash, "$2", 2) == 0) {
        return bcrypt_checkpw(password, hash) == 0;
    }
    return false;
}
```

### Rate Limiting

To prevent brute-force attacks:

| Failed Attempts | Delay |
|-----------------|-------|
| 1-3 | None |
| 4-6 | 5 seconds |
| 7-10 | 30 seconds |
| 11+ | 60 seconds |

Rate limiting state stored in `/tmp/usp-auth-rate`:

```c
typedef struct {
    char client_ip[64];
    int failed_attempts;
    time_t last_attempt;
} rate_limit_entry_t;
```

---

## Token Refresh

### Grace Period

Expired tokens can be refreshed within a grace period (default: 5 minutes).

```c
bool can_refresh(const jwt_t *token) {
    time_t now = time(NULL);
    time_t exp = jwt_get_exp(token);
    time_t grace = config_get_int("jwt_refresh_grace", 300);

    // Token must be expired but within grace period
    return (now > exp) && (now < exp + grace);
}
```

### Session Continuity

On refresh, the `session_id` is preserved:

```c
jwt_t* refresh_token(const jwt_t *old_token) {
    jwt_t *new_token = jwt_new();

    // Preserve session_id
    jwt_set_claim(new_token, "session_id", jwt_get_claim(old_token, "session_id"));

    // Update timestamps
    time_t now = time(NULL);
    jwt_set_iat(new_token, now);
    jwt_set_exp(new_token, now + config_get_int("jwt_expiry", 3600));

    // Preserve role
    jwt_set_claim(new_token, "role", jwt_get_claim(old_token, "role"));

    return new_token;
}
```

---

## Cookie Configuration

### Attributes

```
Set-Cookie: usp_session=<JWT>; HttpOnly; Secure; SameSite=Strict; Path=/api
```

| Attribute | Value | Purpose |
|-----------|-------|---------|
| `HttpOnly` | Yes | Prevent JavaScript access (XSS protection) |
| `Secure` | Yes | HTTPS only |
| `SameSite` | `Strict` | CSRF protection |
| `Path` | `/api` | Only sent to API endpoints |

### Cookie Name

Configurable via UCI (default: `usp_session`).

---

## Configuration

### UCI: `/etc/config/usp-auth`

```
config auth 'main'
    option password_hash '$argon2id$v=19$m=65536,t=3,p=4$...'
    option jwt_secret_file '/etc/usp-ui/jwt.key'
    option jwt_expiry '3600'
    option jwt_refresh_grace '300'
    option jwt_cookie_name 'usp_session'
    option controller_endpoint_id 'controller::localui'
    option turbo_controller_endpoint_id 'controller::localui-turbo'
    option agent_endpoint_id 'agent::ABC123456'
    option rate_limit_file '/tmp/usp-auth-rate'
```

### Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `password_hash` | string | - | Argon2id or bcrypt hash |
| `jwt_secret_file` | string | `/etc/usp-ui/jwt.key` | Path to JWT signing key |
| `jwt_expiry` | int | `3600` | Token lifetime (seconds) |
| `jwt_refresh_grace` | int | `300` | Grace period for refresh (seconds) |
| `jwt_cookie_name` | string | `usp_session` | Cookie name |
| `controller_endpoint_id` | string | `controller::localui` | Normal controller ID |
| `turbo_controller_endpoint_id` | string | `controller::localui-turbo` | Turbo controller ID |
| `agent_endpoint_id` | string | - | Agent endpoint ID (device serial) |
| `rate_limit_file` | string | `/tmp/usp-auth-rate` | Rate limit state file |

### JWT Secret Key

The JWT signing key should be:
- At least 256 bits (32 bytes) of random data
- Generated on first boot if not present
- Stored with restrictive permissions (0600)

```bash
# Generate key on first boot
if [ ! -f /etc/usp-ui/jwt.key ]; then
    dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 > /etc/usp-ui/jwt.key
    chmod 600 /etc/usp-ui/jwt.key
fi
```

---

## CGI Interface

### Environment Variables

| Variable | Description |
|----------|-------------|
| `REQUEST_METHOD` | HTTP method (GET, POST) |
| `PATH_INFO` | Request path after script |
| `CONTENT_TYPE` | Request content type |
| `CONTENT_LENGTH` | Request body length |
| `HTTP_COOKIE` | Cookie header |
| `HTTP_AUTHORIZATION` | Authorization header |
| `REMOTE_ADDR` | Client IP address |

### Request Parsing

```c
int main(void) {
    const char *method = getenv("REQUEST_METHOD");
    const char *path = getenv("PATH_INFO");

    if (strcmp(method, "POST") != 0) {
        output_error(405, "Method not allowed");
        return 0;
    }

    if (strcmp(path, "/login") == 0) {
        handle_login();
    } else if (strcmp(path, "/refresh") == 0) {
        handle_refresh();
    } else if (strcmp(path, "/logout") == 0) {
        handle_logout();
    } else {
        output_error(404, "Not found");
    }

    return 0;
}
```

### Response Output

```c
void output_json(int status, const char *json) {
    printf("Status: %d\r\n", status);
    printf("Content-Type: application/json\r\n");
    printf("\r\n");
    printf("%s", json);
}

void output_with_cookie(int status, const char *cookie, const char *json) {
    printf("Status: %d\r\n", status);
    printf("Content-Type: application/json\r\n");
    printf("Set-Cookie: %s\r\n", cookie);
    printf("\r\n");
    printf("%s", json);
}
```

---

## Error Handling

### Error Codes

| Status | Error | Description |
|--------|-------|-------------|
| 400 | `invalid_request` | Malformed JSON body |
| 401 | `invalid_password` | Wrong password |
| 401 | `token_expired` | JWT expired beyond grace |
| 401 | `token_invalid` | Invalid JWT signature |
| 405 | `method_not_allowed` | Wrong HTTP method |
| 429 | `rate_limited` | Too many failed attempts |

### Logging

```c
void log_auth_event(const char *event, const char *client_ip, const char *session_id) {
    syslog(LOG_INFO, "usp-auth-cgi: %s from %s session=%s",
           event, client_ip, session_id ? session_id : "none");
}
```

Events logged:
- `login_success`
- `login_failed`
- `token_refreshed`
- `logout`
- `rate_limited`

---

## Security Considerations

### Password Storage

- Never log passwords
- Clear password from memory after validation
- Use constant-time comparison for hash verification

### JWT Security

- Use strong random secret (256+ bits)
- Validate all claims on each request
- Check expiration with clock skew tolerance

### Rate Limiting

- Track by client IP
- Persist state across CGI invocations
- Reset on successful login

### Input Validation

- Validate JSON structure before processing
- Limit password length (prevent DoS)
- Sanitize all inputs for logging

---

## Build & Deployment

### Build Dependencies

- libjansson-dev
- OpenSSL-dev or mbedTLS-dev
- libuci-dev
- libargon2-dev (optional, for Argon2 support)

### Makefile Target

```makefile
define Package/usp-auth-cgi
  SECTION:=net
  CATEGORY:=Network
  TITLE:=USP Authentication CGI
  DEPENDS:=+libjansson +libopenssl +libuci
endef
```

### Installation

- Binary: `/www/cgi-bin/usp-auth`
- Config: `/etc/config/usp-auth`
- Key: `/etc/usp-ui/jwt.key`

### lighttpd Configuration

```
$HTTP["url"] =~ "^/api/auth" {
    cgi.assign = ( "" => "" )
    alias.url = ( "/api/auth" => "/www/cgi-bin/usp-auth" )
}
```

---

## Testing

### Unit Tests

- Password validation (correct, incorrect, various hash formats)
- JWT generation and parsing
- Session ID uniqueness
- Rate limiting logic

### Integration Tests

- Full login flow
- Token refresh (valid, expired, beyond grace)
- Logout
- Rate limiting behavior

### Test Commands

```bash
# Login
curl -X POST -H "Content-Type: application/json" \
     -d '{"password":"secret"}' \
     https://router.local/api/auth/login

# Refresh (with cookie)
curl -X POST -b "usp_session=<JWT>" \
     https://router.local/api/auth/refresh

# Refresh (with header)
curl -X POST -H "Authorization: Bearer <JWT>" \
     https://router.local/api/auth/refresh

# Logout
curl -X POST -b "usp_session=<JWT>" \
     https://router.local/api/auth/logout
```
