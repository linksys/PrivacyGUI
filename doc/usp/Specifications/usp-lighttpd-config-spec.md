# usp-lighttpd-config Specification

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |

---

## Overview

`usp-lighttpd-config` is a configuration package that provides lighttpd configuration files for the USP-driven UI. It handles TLS termination, reverse proxy routing, WebSocket proxy, static file serving, and JWT-based authentication.

### Purpose

- Configure TLS termination for HTTPS
- Route API requests to appropriate backends
- Proxy WebSocket connections for turbo channel
- Serve static UI files
- Validate JWT tokens at the reverse proxy level

### Type

Configuration files (no compiled code)

### Dependencies

- lighttpd with required modules:
  - mod_proxy
  - mod_wstunnel
  - mod_cgi
  - mod_setenv
  - mod_openssl

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              lighttpd                                        │
│                                                                              │
│  Port 443 (HTTPS)                                                            │
│         │                                                                    │
│         ▼                                                                    │
│  ┌─────────────────┐                                                         │
│  │ TLS Termination │                                                         │
│  └────────┬────────┘                                                         │
│           │                                                                  │
│           ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         Routing Rules                                   │ │
│  │                                                                         │ │
│  │  /api/auth/*  ──────────────────────────► Auth CGI                     │ │
│  │  /api/ai/*    ──────────────────────────► usp-llm-proxy (:8081)        │ │
│  │  /api/*       ──────────────────────────► usp-bridge (:8080)           │ │
│  │  /usp-ws      ──────────────────────────► OBUSPA WebSocket (:8443)     │ │
│  │  /*           ──────────────────────────► Static files (/www/usp-ui/)  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Routing Rules

### Route Priority

Routes are evaluated in order; first match wins:

| Priority | Path Pattern | Target | Description |
|----------|--------------|--------|-------------|
| 1 | `/api/auth/*` | CGI | Authentication endpoints |
| 2 | `/api/ai/*` | Proxy (8081) | AI/LLM proxy |
| 3 | `/api/*` | Proxy (8080) | USP Bridge |
| 4 | `/usp-ws` | WebSocket Proxy (8443) | Turbo channel |
| 5 | `/*` | Static | UI files |

### Route Details

#### Authentication (`/api/auth/*`)

```
/api/auth/login   → CGI exec → /www/cgi-bin/usp-auth
/api/auth/refresh → CGI exec → /www/cgi-bin/usp-auth
/api/auth/logout  → CGI exec → /www/cgi-bin/usp-auth
```

#### AI/LLM Proxy (`/api/ai/*`)

```
/api/ai/chat      → HTTP Proxy → localhost:8081
/api/ai/interpret → HTTP Proxy → localhost:8081
/api/ai/config    → HTTP Proxy → localhost:8081
```

#### USP Bridge (`/api/*`)

```
/api/usp          → HTTP Proxy → localhost:8080
/api/events       → HTTP Proxy → localhost:8080 (SSE)
/api/subscribe    → HTTP Proxy → localhost:8080
/api/unsubscribe  → HTTP Proxy → localhost:8080
/api/turbo/*      → HTTP Proxy → localhost:8080
/api/health       → HTTP Proxy → localhost:8080
```

#### WebSocket Turbo Channel (`/usp-ws`)

```
/usp-ws → WebSocket Proxy → localhost:8443 (OBUSPA)
```

#### Static Files (`/*`)

```
/*  → /www/usp-ui/
```

---

## Configuration Files

### Main Configuration

**File:** `/etc/lighttpd/lighttpd.conf`

```
# Global settings
server.port = 443
server.bind = "0.0.0.0"
server.document-root = "/www/usp-ui"
server.username = "www-data"
server.groupname = "www-data"

# Required modules
server.modules = (
    "mod_openssl",
    "mod_proxy",
    "mod_wstunnel",
    "mod_cgi",
    "mod_setenv",
    "mod_access",
    "mod_alias"
)

# Include additional configurations
include "/etc/lighttpd/conf.d/*.conf"
```

### TLS Configuration

**File:** `/etc/lighttpd/conf.d/10-ssl.conf`

```
# TLS/SSL configuration
ssl.engine = "enable"
ssl.pemfile = "/etc/ssl/private/router.pem"
ssl.ca-file = "/etc/ssl/certs/ca-bundle.crt"

# Modern TLS settings
ssl.openssl.ssl-conf-cmd = (
    "MinProtocol" => "TLSv1.2",
    "CipherString" => "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"
)

# HSTS header
setenv.add-response-header = (
    "Strict-Transport-Security" => "max-age=31536000; includeSubDomains"
)
```

### Authentication CGI Configuration

**File:** `/etc/lighttpd/conf.d/20-auth-cgi.conf`

```
# Authentication CGI routing
$HTTP["url"] =~ "^/api/auth" {
    cgi.assign = ( "" => "" )
    alias.url = ( "/api/auth" => "/www/cgi-bin/usp-auth" )
}
```

### AI/LLM Proxy Configuration

**File:** `/etc/lighttpd/conf.d/30-ai-proxy.conf`

```
# AI/LLM proxy routing
$HTTP["url"] =~ "^/api/ai" {
    proxy.server = ( "" => (
        ( "host" => "127.0.0.1", "port" => 8081 )
    ))
    proxy.header = (
        "map-urlpath" => ( "/api/ai" => "/api/ai" )
    )
}
```

### USP Bridge Proxy Configuration

**File:** `/etc/lighttpd/conf.d/40-usp-bridge.conf`

```
# USP Bridge proxy routing (excluding /api/auth and /api/ai)
$HTTP["url"] =~ "^/api/(?!auth|ai)" {
    proxy.server = ( "" => (
        ( "host" => "127.0.0.1", "port" => 8080 )
    ))
    proxy.header = (
        "map-urlpath" => ( "/api" => "/api" )
    )
}
```

### WebSocket Proxy Configuration

**File:** `/etc/lighttpd/conf.d/50-websocket.conf`

```
# WebSocket proxy for turbo channel
$HTTP["url"] =~ "^/usp-ws" {
    wstunnel.server = ( "" => (
        ( "host" => "127.0.0.1", "port" => 8443 )
    ))
    wstunnel.frame-type = "binary"
    wstunnel.ping-interval = 30
}
```

### Static Files Configuration

**File:** `/etc/lighttpd/conf.d/60-static.conf`

```
# Static file serving
server.document-root = "/www/usp-ui"
index-file.names = ( "index.html" )

# MIME types
mimetype.assign = (
    ".html" => "text/html",
    ".css" => "text/css",
    ".js" => "application/javascript",
    ".json" => "application/json",
    ".wasm" => "application/wasm",
    ".png" => "image/png",
    ".jpg" => "image/jpeg",
    ".svg" => "image/svg+xml",
    ".woff" => "font/woff",
    ".woff2" => "font/woff2"
)

# Cache control for static assets
$HTTP["url"] =~ "\.(css|js|wasm|png|jpg|svg|woff|woff2)$" {
    setenv.add-response-header = (
        "Cache-Control" => "public, max-age=31536000, immutable"
    )
}

# No cache for HTML (SPA routing)
$HTTP["url"] =~ "\.html$" {
    setenv.add-response-header = (
        "Cache-Control" => "no-cache"
    )
}

# SPA fallback - serve index.html for client-side routes
server.error-handler-404 = "/index.html"
```

### Security Headers Configuration

**File:** `/etc/lighttpd/conf.d/70-security.conf`

```
# Security headers
setenv.add-response-header += (
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "DENY",
    "X-XSS-Protection" => "1; mode=block",
    "Referrer-Policy" => "strict-origin-when-cross-origin",
    "Content-Security-Policy" => "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; connect-src 'self' wss://*; img-src 'self' data:; font-src 'self'"
)
```

### CORS Configuration (Optional)

**File:** `/etc/lighttpd/conf.d/80-cors.conf`

For development or cross-origin deployments:

```
# CORS headers (enable only if needed)
# $HTTP["url"] =~ "^/api" {
#     setenv.add-response-header += (
#         "Access-Control-Allow-Origin" => "https://router.local",
#         "Access-Control-Allow-Credentials" => "true",
#         "Access-Control-Allow-Methods" => "GET, POST, OPTIONS",
#         "Access-Control-Allow-Headers" => "Content-Type, Authorization"
#     )
# }
```

---

## SSE Configuration

Server-Sent Events require special proxy configuration to prevent buffering:

**In `/etc/lighttpd/conf.d/40-usp-bridge.conf`:**

```
# SSE-specific settings for /api/events
$HTTP["url"] == "/api/events" {
    proxy.server = ( "" => (
        ( "host" => "127.0.0.1", "port" => 8080 )
    ))
    # Disable response buffering for SSE
    server.stream-response-body = 2
}
```

---

## TLS Certificate Management

### Certificate Location

| File | Path | Description |
|------|------|-------------|
| Combined PEM | `/etc/ssl/private/router.pem` | Certificate + private key |
| CA Bundle | `/etc/ssl/certs/ca-bundle.crt` | CA certificates |

### Certificate Format

The `router.pem` file should contain:
1. Private key
2. Server certificate
3. Intermediate certificates (if any)

```
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```

### Self-Signed Certificate Generation

For initial setup:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/router.key \
    -out /etc/ssl/private/router.crt \
    -subj "/CN=router.local"

cat /etc/ssl/private/router.key /etc/ssl/private/router.crt \
    > /etc/ssl/private/router.pem

chmod 600 /etc/ssl/private/router.pem
```

---

## Logging Configuration

**File:** `/etc/lighttpd/conf.d/90-logging.conf`

```
# Access logging
accesslog.filename = "/var/log/lighttpd/access.log"
accesslog.format = "%h %V %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""

# Error logging
server.errorlog = "/var/log/lighttpd/error.log"

# Log level (0=error, 1=warning, 2=info, 3=debug)
debug.log-request-handling = "disable"
debug.log-request-header = "disable"
debug.log-response-header = "disable"
```

---

## Performance Tuning

**File:** `/etc/lighttpd/conf.d/05-performance.conf`

```
# Connection handling
server.max-connections = 256
server.max-fds = 512
server.max-keep-alive-requests = 100
server.max-keep-alive-idle = 30

# Network buffer
server.network-backend = "writev"

# Stat cache
server.stat-cache-engine = "simple"

# Upload limit (for future file upload features)
server.max-request-size = 10485760  # 10MB
```

---

## Package Structure

```
usp-lighttpd-config/
├── files/
│   └── etc/
│       └── lighttpd/
│           ├── lighttpd.conf
│           └── conf.d/
│               ├── 05-performance.conf
│               ├── 10-ssl.conf
│               ├── 20-auth-cgi.conf
│               ├── 30-ai-proxy.conf
│               ├── 40-usp-bridge.conf
│               ├── 50-websocket.conf
│               ├── 60-static.conf
│               ├── 70-security.conf
│               └── 90-logging.conf
└── Makefile
```

---

## Installation

### Package Dependencies

```makefile
define Package/usp-lighttpd-config
  SECTION:=net
  CATEGORY:=Network
  TITLE:=USP UI lighttpd Configuration
  DEPENDS:=+lighttpd +lighttpd-mod-proxy +lighttpd-mod-wstunnel \
           +lighttpd-mod-cgi +lighttpd-mod-setenv +lighttpd-mod-openssl
endef
```

### Post-Install Script

```bash
#!/bin/sh

# Create log directory
mkdir -p /var/log/lighttpd
chown www-data:www-data /var/log/lighttpd

# Create SSL directory if needed
mkdir -p /etc/ssl/private
chmod 700 /etc/ssl/private

# Generate self-signed cert if none exists
if [ ! -f /etc/ssl/private/router.pem ]; then
    /usr/bin/generate-router-cert.sh
fi

# Restart lighttpd
/etc/init.d/lighttpd restart
```

---

## Validation

### Configuration Test

```bash
lighttpd -t -f /etc/lighttpd/lighttpd.conf
```

### Runtime Verification

```bash
# Check TLS
openssl s_client -connect localhost:443 -servername router.local

# Check routing
curl -v https://localhost/api/health
curl -v https://localhost/api/auth/login -d '{"password":"test"}'

# Check WebSocket
wscat -c wss://localhost/usp-ws
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| 502 Bad Gateway | Backend not running | Start usp-bridge or usp-llm-proxy |
| SSL handshake failure | Certificate issue | Check /etc/ssl/private/router.pem |
| WebSocket connection refused | wstunnel module missing | Install lighttpd-mod-wstunnel |
| SSE not streaming | Response buffering | Check stream-response-body setting |

### Debug Mode

Enable debug logging temporarily:

```bash
# In /etc/lighttpd/conf.d/90-logging.conf
debug.log-request-handling = "enable"
debug.log-request-header = "enable"

# Restart and check logs
/etc/init.d/lighttpd restart
tail -f /var/log/lighttpd/error.log
```
