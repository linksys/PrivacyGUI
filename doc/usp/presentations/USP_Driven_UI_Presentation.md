# USP-Driven UI Architecture
## Technical Presentation for Architects

---

<!-- SLIDE 1 -->
# USP-Driven UI Architecture
### A Standards-Based, Open Source-Friendly Approach for OpenWRT Routers

**Agenda:**

1. **Design Drivers** — Why this architecture?
2. **USP Standard Compliance** — TR-369 adherence
3. **Router-Side Components** — lighttpd, USP Bridge, Auth CGI, OBUSPA
4. **UI-Side Architecture** — Rust client, code generation
5. **Dual Transport** — HTTP/SSE + Turbo Channel (WebSocket)
6. **Package Isolation** — 8 independent packages
7. **AI-Powered Management** — Dynamic calls, LLM integration
8. **Key Takeaways**

---

<!-- SLIDE 2 -->
## Design Drivers

### Why This Architecture?

| Driver | Rationale |
|--------|-----------|
| **Open Source Compatible** | UI layer is replaceable; Flutter today, any framework tomorrow |
| ↳ *Developer-Friendly* | Hide TR-181 complexity; work with typed abstractions |
| ↳ *OpenWRT-Oriented* | Minimal footprint for resource-constrained embedded devices |
| **USP Standard (TR-369)** | No vendor lock-in; industry-standard device management |
| **Turbo Channel** | High-bandwidth streaming without blocking normal operations |

---

<!-- SLIDE 3 -->
## Open Source Friendliness

### Replaceable UI Layer

```
┌─────────────────────────────────────┐
│  Flutter UI  │  TypeScript UI  │ ?  │  ← Swappable
├─────────────────────────────────────┤
│         usp-client (Rust)           │  ← Single codebase
│    Native FFI  │  WASM (browsers)   │
├─────────────────────────────────────┤
│         USP Bridge (C)              │  ← Standard interface
└─────────────────────────────────────┘
```

**Key patterns:**
- **Rust for usp-client**: Compiles to native libs (iOS/Android FFI) AND WASM (browsers)
- **JSON API definitions**: Language-agnostic; generate Dart, TypeScript, Swift
- **Standard HTTP/SSE**: Any HTTP client can talk to the router
- **Extensible**: Vendor data model extensions supported when needed

---

<!-- SLIDE 4 -->
## The usp-client Framework

### Not Just a Library — A Complete Framework

```
┌─────────────────────────────────────────────────────────────────┐
│                     usp-client Framework                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │   usp-codegen   │    │         Language Plugins            │ │
│  │                 │    │  ┌───────┐ ┌────┐ ┌───────┐ ┌───┐   │ │
│  │  JSON → Code    │    │  │ Dart  │ │ TS │ │ Swift │ │...│   │ │
│  │  definitions    │    │  │ FFI   │ │WASM│ │  FFI  │ │   │   │ │
│  └────────┬────────┘    │  └───┬───┘ └─┬──┘ └───┬───┘ └─┬─┘   │ │
│           │             └──────┼───────┼────────┼───────┼─────┘ │
│           │                    │       │        │       │       │
│           ▼                    ▼       ▼        ▼       ▼       │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │              usp-client Core (Rust)                         ││
│  │   Protobuf encoding │ HTTP/SSE │ WebSocket │ JWT mgmt       ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

| Component | Purpose |
|-----------|---------|
| **usp-client Core** | Rust library: protobuf, transport, session management |
| **Language Plugins** | Bindings to invoke usp-client from any UI language |
| **usp-codegen** | Generates typed API libraries from JSON definitions |

**Today:** Dart plugin for Flutter
**Tomorrow:** TypeScript, Swift, or any other language — the framework supports it

---

<!-- SLIDE 5 -->
## USP Standard Compliance (TR-369)

### What is USP?

- **User Services Platform** — Broadband Forum TR-369
- Successor to TR-069 (CWMP)
- Protocol for device management: Get, Set, Add, Delete, Operate, Notify

### Our Compliance Strategy

| Principle | Implementation |
|-----------|----------------|
| **Standard wire format** | Protobuf-encoded USP Records |
| **Vendor extensions supported** | Architecture allows extending the data model when needed |
| **UDS MTP (primary)** | Unix Domain Socket for USP Bridge ↔ OBUSPA communication |
| **WebSocket MTP (turbo only)** | UI ↔ lighttpd (wstunnel proxy) ↔ OBUSPA (:8443 localhost) for high-bandwidth streaming |
| **Standard subscriptions** | TimeToLive, NotifType, ReferenceList per spec |

**Result:** Any USP-compliant agent (not just OBUSPA) can be used.

---

<!-- SLIDE 6 -->
## OpenWRT-Oriented Design

### Constraints we design for

- **Limited RAM/Flash** — Minimal daemon footprint
- **Protobuf offloaded to UI** — USP Bridge is a thin proxy (~50KB); all protobuf encoding done by usp-client (Rust)
- **No persistent state in bridge** — OBUSPA is source of truth
- **UCI configuration** — Standard OpenWRT config files
- **lighttpd** — Lightweight, proven web server
- **C for router daemons** — Native performance, small binaries

### Package Integration

```
/etc/config/usp-bridge     # UCI configuration
/etc/config/usp-auth       # JWT settings
/usr/sbin/usp-bridge       # ~50KB daemon
/usr/lib/cgi-bin/usp-auth  # ~30KB CGI
```

All packages follow OpenWRT packaging conventions (`Makefile`, `init.d` scripts).

---

<!-- SLIDE 7 -->
## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI / Browser                            │
│   ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│   │  Auth (login) │  │ Normal (HTTP) │  │ Turbo (WebSocket) │   │
│   └───────┬───────┘  └───────┬───────┘  └─────────┬─────────┘   │
└───────────┼──────────────────┼────────────────────┼─────────────┘
            │                  │ HTTPS              │ WSS
            ▼                  ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                         lighttpd                                │
│         TLS termination │ JWT validation │ Reverse proxy        │
└─────┬─────────────────────────┬─────────────────────┬───────────┘
      │                         │                     │ WS (turbo)
      ▼                         ▼                     ▼
┌──────────────┐          ┌──────────────┐      ┌──────────────┐
│   Auth CGI   │          │  USP Bridge  │─UDS─▶│   OBUSPA     │
│  (ephemeral) │          └──────────────┘      └──────────────┘
└──────────────┘
   JWT generation
```

---

<!-- SLIDE 8 -->
## Router-Side Components

| Component | Type | Responsibility |
|-----------|------|----------------|
| **lighttpd** | Daemon | TLS termination, static files, reverse proxy, JWT validation |
| **Auth CGI** | CGI | Password validation, JWT generation/refresh |
| **USP Bridge** | Daemon | HTTP/SSE ↔ UDS MTP bridge, session management |
| **OBUSPA** | Daemon | USP Agent — source of truth for device configuration |

### Why This Split?

- **Separation of concerns** — Each component does one thing well
- **Security** — Auth CGI is ephemeral; no long-running auth state
- **Testability** — Each component can be tested in isolation
- **Replaceability** — Swap OBUSPA for another USP agent if needed

---

<!-- SLIDE 9 -->
## lighttpd Configuration

### Routing Rules

| Path | Target | Purpose |
|------|--------|---------|
| `/api/auth/*` | Auth CGI | Login, refresh, logout |
| `/api/*` | USP Bridge (:8080) | USP operations, SSE, subscriptions |
| `/usp-ws` | OBUSPA (:8443) | Turbo channel (WebSocket proxy) |
| `/*` | Static files | UI bundle |

### Security Features

- **TLS termination** — All external traffic is HTTPS
- **JWT validation** — lighttpd validates before proxying
- **localhost binding** — USP Bridge and OBUSPA only listen on 127.0.0.1

---

<!-- SLIDE 10 -->
## USP Bridge

### Endpoints Exposed

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/usp` | POST | USP Request/Response (protobuf) |
| `/api/events` | GET | SSE notification stream |
| `/api/subscribe` | POST | Register subscription→session mapping |
| `/api/turbo/start` | POST | Acquire turbo channel |
| `/api/turbo/heartbeat` | POST | Keep turbo channel alive |
| `/api/turbo/release` | POST | Release turbo channel |

### Internal State (In-Memory Only)

- Session → SSE connections (fan-out)
- Subscription → Session mapping
- Request correlation (msg_id)
- Turbo channel ownership

**No persistent state** — survives restart by re-registration.

---

<!-- SLIDE 11 -->
## Authentication Flow

```
Browser                    lighttpd              Auth CGI
   │                          │                      │
   │── POST /api/auth/login ─▶│                      │
   │   {password}             │── CGI exec ─────────▶│
   │                          │                      │
   │                          │   Validate password  │
   │                          │   Generate session_id│
   │                          │   Sign JWT           │
   │                          │                      │
   │                          │◀── Response ─────────│
   │◀── 200 OK ───────────────│                      │
   │   Set-Cookie: usp_session=<JWT>                 │
   │   {controller_endpoint_id, agent_endpoint_id}   │
```

### JWT Cookie Properties

`HttpOnly; Secure; SameSite=Strict; Path=/api`

- **HttpOnly** — XSS protection (JS can't read)
- **Multi-tab sharing** — All tabs share same session automatically

---

<!-- SLIDE 12 -->
## UI-Side Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                            │
│         (UI screens, business logic, state management)          │
└───────────────────────────────┬─────────────────────────────────┘
                                │ High-level API calls
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Definition-Driven Layer                         │
│         (Generated from JSON definition files)                  │
│    WifiSettings.get(), DeviceInfo.fetch(), subscribe()          │
└───────────────────────────────┬─────────────────────────────────┘
                                │ USP operations
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    USP Client Layer (Rust)                      │
│    Protobuf encoding │ HTTP/SSE │ WebSocket │ JWT refresh       │
└─────────────────────────────────────────────────────────────────┘
```

**Design Goal:** Developers never work with TR-181 paths or protobuf directly.

---

<!-- SLIDE 13 -->
## Why Rust for usp-client?

### The Goal: UI Technology Independence

We want to **swap the UI framework** without rewriting the client library.

| UI Technology | How it consumes usp-client |
|---------------|---------------------------|
| Flutter (iOS/Android) | Native lib via FFI |
| Flutter Web | WASM module |
| TypeScript/React | WASM module |
| Swift (native iOS) | Native lib via FFI |
| Any future framework | FFI or WASM |

### Why Not Write It in the UI's Language?

| Approach | Problem |
|----------|---------|
| **Pure Dart** | Locked to Flutter; rewrite needed for TypeScript UI |
| **Pure TypeScript** | Locked to web; rewrite needed for native apps |
| **Separate implementations** | Maintenance burden; behavior drift |

### Why Rust?

| Capability | Benefit |
|------------|---------|
| **C ABI exports** | Universal FFI — any language can call it |
| **First-class WASM** | Runs in any browser, no emscripten hacks |
| **Memory safe** | No manual allocation bugs |
| **Single codebase** | One implementation for all platforms |

---

<!-- SLIDE 14 -->
## Definition-Driven Development

### JSON Definition Example

```json
{
  "name": "hardwareInfo",
  "type": "get",
  "parameters": [
    {"path": "Device.DeviceInfo.ModelName", "field": "modelName", "type": "string"},
    {"path": "Device.DeviceInfo.SerialNumber", "field": "serialNumber", "type": "string"}
  ]
}
```

### Generated Dart Code

```dart
class HardwareInfo {
  final String modelName;
  final String serialNumber;

  static Future<HardwareInfo> fetch(UspClient client) async {
    final response = await client.get([
      'Device.DeviceInfo.ModelName',
      'Device.DeviceInfo.SerialNumber',
    ]);
    return HardwareInfo._fromResponse(response);
  }
}
```

**Benefit:** API layer is defined declaratively in JSON — no manual protobuf or TR-181 path handling. JSON definitions can be created by AI or non-experts; UI development focuses purely on presentation.

---

<!-- SLIDE 15 -->
## Code Generation Benefits

### Security

- TR-181 paths baked into compiled binary
- No runtime JSON files that attackers could modify
- Behavior is immutable without replacing signed binary

### Developer Experience

- **Type safety** — Compile-time checking, IDE autocomplete
- **No TR-181 knowledge required** — Call `WifiSettings.fetch()`, not `Device.WiFi.SSID.1.`
- **Multi-language** — Same JSON definitions generate Dart, TypeScript, etc.

### Build Integration

```bash
# Generate API classes from definitions
flutter pub run build_runner build
```

Output: `lib/api/generated/core.dart`, `lib/api/generated/extensions.dart`

---

<!-- SLIDE 16 -->
## Dual Transport Strategy

### Why Two Transports?

| Transport | Use Case | Characteristics |
|-----------|----------|-----------------|
| **HTTP/SSE** (Normal) | Get, Set, Add, Delete, subscriptions | Multi-client, via USP Bridge |
| **WebSocket** (Turbo) | Packet capture, log streaming | Single-client, via usp-client |

### Normal Transport Flow

```
UI → usp-client → HTTP POST /api/usp → USP Bridge → UDS → OBUSPA
                  SSE /api/events ← notifications (fan-out to all tabs)
```

### Turbo Channel Flow

```
UI → usp-client → POST /api/turbo/start → USP Bridge (reserves channel)
     usp-client → WebSocket /usp-ws → lighttpd → OBUSPA (streaming)
```

**Key:** WebSocket is managed by usp-client (Rust), not the UI directly.

---

<!-- SLIDE 17 -->
## Turbo Channel Deep Dive

### Characteristics

- **Exclusive** — Only one turbo channel active device-wide
- **Operation-scoped** — Acquired for specific operation (e.g., packet capture)
- **Parallel** — Normal HTTP/SSE continues to work
- **Automatic cleanup** — Released on WebSocket close or timeout

### State Machine

```
AVAILABLE → PENDING → IN_USE → AVAILABLE
              │                    ▲
              │ (6s timeout)       │
              └────────────────────┘
```

### Heartbeat Requirement

usp-client sends `/api/turbo/heartbeat` every 60 seconds (background thread).
USP Bridge cannot observe WebSocket traffic (proxied by lighttpd).

---

<!-- SLIDE 18 -->
## Session & Subscription Management

### Session Model

- **One session per device** — Phone and laptop have separate sessions
- **Multiple tabs share session** — Same cookie, same `session_id`
- **Notifications fan-out** — All tabs receive all notifications

### Subscription Lifecycle

1. **Check existence** — `Device.LocalAgent.Subscription.[ID=="..."].ID`
2. **Create if needed** — USP Add with TimeToLive (TTL)
3. **Register mapping** — POST `/api/subscribe` (session→subscription)
4. **Refresh TTL** — Every 30 minutes, Set TimeToLive = 3600
5. **Auto-cleanup** — TTL expires if browser crashes

**Benefit:** No orphaned subscriptions; no manual cleanup needed.

---

<!-- SLIDE 19 -->
## Package Architecture (8 Packages)

| # | Package | Language | Purpose |
|---|---------|----------|---------|
| 1 | `usp-bridge` | C | HTTP/SSE ↔ UDS bridge daemon |
| 2 | `usp-auth-cgi` | C | JWT authentication CGI |
| 3 | `usp-lighttpd-config` | Config | Routing, TLS, proxy rules |
| 4 | `usp-client` | Rust | Client library (FFI + WASM) |
| 5 | `usp-api-definitions` | JSON | Static API definition files |
| 6 | `usp-codegen` | C | JSON → Dart/TS generator |
| 7 | `usp-llm-proxy` | C | AI chat proxy, validation, LLM orchestration |
| 8 | `usp-ui-flutter` | Flutter | Cross-platform UI app |

### Isolation Benefits

- Independent versioning and testing
- Clear dependency graph
- Replace any package without affecting others

---

<!-- SLIDE 20 -->
## AI-Powered Router Management

### Two Data Paths

| Path | Use Case | Characteristics |
|------|----------|-----------------|
| **Static (Generated)** | 99% of operations | Type-safe, compile-time checked |
| **Dynamic (AI)** | Natural language queries | Runtime YAML, router-validated |

### Why AI on the Router?

- **Browser cannot connect directly to LLM** — requires authentication
- **Security** — Router validates all AI-generated YAML before execution
- **Privacy** — Customer controls cloud vs local LLM via settings
- **Retry logic** — Validation failures sent back to LLM without UI involvement

```
User: "What channel is my WiFi using?"
         ↓
    UI sends plain text
         ↓
    Router → LLM → YAML
         ↓
    Router validates YAML
         ↓
    UI executes via UspClient
         ↓
    Router interprets results → human answer
```

---

<!-- SLIDE 21 -->
## Two-Phase AI Workflow

### Phase 1: Query Generation

```
UI                         Router (usp-llm-proxy)              LLM
│                                    │                          │
│── POST /api/ai/chat ──────────────▶│                          │
│   "What channel is my WiFi?"       │── MQTT ─────────────────▶│
│                                    │                          │
│                                    │◀── dynamic_call YAML ────│
│                                    │                          │
│                                    │ Validate (schema +       │
│                                    │   whitelist)             │
│                                    │                          │
│◀── validated YAML ─────────────────│                          │
│                                    │                          │
│── Execute via UspClient ──────────▶│                          │
```

### Phase 2: Result Interpretation

```
│── POST /api/ai/interpret ─────────▶│                          │
│   {results + original question}    │── MQTT ─────────────────▶│
│                                    │                          │
│                                    │◀── human-readable ───────│
│◀── "Your WiFi is on channel 6" ────│                          │
```

---

<!-- SLIDE 22 -->
## AI Security: Validation & Whitelisting

### Router-Side Validation

```
┌─────────────────────────────────────────────────────────────────┐
│                      usp-llm-proxy                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────────┐    │
│  │   Schema    │   │  Whitelist  │   │   Retry Controller  │    │
│  │  Validator  │   │   Checker   │   │   (max 3 attempts)  │    │
│  └──────┬──────┘   └──────┬──────┘   └──────────┬──────────┘    │
│         │                 │                     │               │
│         └────────────────►├─────────────────────┘               │
│                           ▼                                     │
│                   Pass? ─── No ───► Send error to LLM           │
│                     │               for correction              │
│                    Yes                                          │
│                     ▼                                           │
│              Return to UI                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Whitelist Examples

| Path Pattern | Operations | Description |
|--------------|------------|-------------|
| `Device.DeviceInfo.**` | Get | Device info (read-only) |
| `Device.WiFi.Radio.*.Channel` | Get, Set | WiFi channel config |
| `Device.Hosts.Host.*.**` | Get | Connected devices |
| `Device.Users.**` | **DENIED** | Credentials never exposed |
| `Device.Security.**` | **DENIED** | Requires explicit UI |

---

<!-- SLIDE 23 -->
## AI Privacy & Deployment Options

### Privacy Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Cloud** | Queries sent to Linksys cloud LLM | Default, best quality |
| **Local** | On-device LLM (e.g., Llama) | Privacy-sensitive customers |
| **Disabled** | AI features completely off | Enterprise policy |

### Dynamic Call YAML Example

```yaml
version: "1.0"
operations:
  - type: Get
    paths:
      - Device.WiFi.Radio.1.Channel
      - Device.WiFi.Radio.1.OperatingFrequencyBand
```

**Key security property:** The UI only executes pre-validated YAML from the router. Validation cannot be bypassed.

---

<!-- SLIDE 24 -->
## Future: Dynamic Module Extensibility

### Goal: Replace LuCI with Modular Architecture

Like LuCI, allow OpenWRT packages to install their own UI modules on the fly.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Main Flutter UI                              │
│  ┌─────────────────────┐  ┌───────────────────────────────────┐ │
│  │   Core Features     │  │   Module Frame / App Launcher     │ │
│  │   (pre-built APIs)  │  │   - Reads app_db.json             │ │
│  │                     │  │   - Embeds dynamic modules        │ │
│  └─────────────────────┘  └───────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              ▼                         ▼                         ▼
       ┌────────────┐            ┌────────────┐            ┌────────────┐
       │  Module A  │            │  Module B  │            │  Module C  │
       │  (opkg)    │            │  (opkg)    │            │  (opkg)    │
       └────────────┘            └────────────┘            └────────────┘
```

### How It Works

| Step | Description |
|------|-------------|
| **Build time** | Module developer creates JSON definitions → usp-codegen → typed APIs |
| **Package** | Module web app + postinst script (registers in `app_db.json`) |
| **Install** | `opkg install module-x` → module available in UI immediately |

**Key insight:** Each module runs usp-codegen at its own build time — no TR-181 burden for module developers, no rebuild of main UI required.

---

<!-- SLIDE 25 -->
## Key Takeaways

### Open Source Friendly
- UI is replaceable (Flutter, TypeScript, or future frameworks)
- Single Rust client serves all platforms (native + WASM)
- JSON definitions are language-agnostic

### Standards-Based
- Pure USP (TR-369) on the wire — vendor extensions supported when needed
- OBUSPA (or any USP agent) is the source of truth
- WebSocket MTP compliant for turbo channel

### OpenWRT-Optimized
- Minimal memory footprint (~50KB daemons)
- No persistent state in bridge
- UCI configuration files

### Developer Experience
- Hide TR-181 complexity behind typed APIs
- Code generation from JSON definitions
- Multi-tab/multi-device handled transparently

### AI-Powered
- Natural language router management via chat interface
- Router-side validation ensures security (whitelist + schema)
- Privacy-flexible: cloud, local, or disabled LLM options
- Two-phase workflow: query generation → result interpretation

### Future-Ready
- Architecture supports dynamic module loading (LuCI replacement)
- Modules built independently with their own JSON definitions
- No main UI rebuild required to add new features

---

<!-- END OF PRESENTATION -->

## Appendix: References

- **TR-369**: Broadband Forum USP specification
- **TR-181**: Device:2 Data Model
- **OBUSPA**: https://github.com/BroadbandForum/obuspa
- **Protobuf**: USP wire encoding format

## Appendix: Specification Documents

- `router-side-spec.md` — Full router architecture details
- `ui-side-spec.md` — Full UI architecture details
- `components-isolation.md` — Package boundaries and interfaces
