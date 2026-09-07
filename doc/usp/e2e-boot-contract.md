# PrivacyGUI ↔ E2E Boot Contract

The surface the PrivacyGUI web build exposes to the browser, and the HTTP
surface it calls. The E2E suite (`linksys/PrivacyGUI-USP-E2E`) targets this
contract — whether it stubs the surface (fast JS-mock) or drives the real
compiled WASM against a backend (high-fidelity gate). Keep this doc in sync
when the JS-interop surface, bridge endpoints, or `E2E_MOCK` behavior change.

> **Contract source of truth:** the USP wire/JS-API contract lives in
> `linksys/usp_framework` — `usp-client/proto/usp.proto` (wire),
> `usp-client/doc/wasm-api-reference.md` (UnifiedResponse + methods). Pin the
> snapshot via the `e2e-contract-v0.12.0` tag (matches this app's vendored
> `web/usp_client_bg.wasm`). See `doc/usp/vendored-artifacts.md`.

## 1. Boot handshake (JS globals)

`web/usp_init.js` loads the WASM module and, when ready, sets:

```js
window.__uspClientReady = Promise<true>   // Dart awaits this before using UspClient
window.UspClient           = <class>       // constructable USP client
window.UspClientBuilder    = <class>       // remote-assistance builder
window.UspWsClient         = <class>       // firmware-upload WebSocket client
window.buildGetRecord / buildOperateRecord / buildWebSocketConnect / decodeRecord
window.sendWebSocketConnectNative = async fn
```

An E2E harness that replaces the client MUST define `window.UspClient`
(constructable) **and** resolve `window.__uspClientReady`, or the Flutter app
never finishes booting. If it also intercepts `web/usp_init.js`, it must not
leave `__uspClientReady` unresolved.

## 2. `window.UspClient` method surface

From `lib/core/usp/web/usp_client_wasm.dart` (`@JS('UspClient')`). All data
methods return the **UnifiedResponse** shape `{ success: bool, result: { data,
error? } }` (see wasm-api-reference.md).

| Method | Signature | Notes |
|--------|-----------|-------|
| `constructor(baseUrl)` | `new UspClient(string)` | baseUrl = `Uri.base.origin` |
| `get(paths)` | `Promise` | paths: string or string[]; supports wildcard `.*.` and trailing-dot prefix fetch |
| `set(parameters, options?)` | `Promise` | |
| `setOrdered(groupsArray, allowPartial)` | `Promise` | **must be implemented** — used by static-IP WAN save |
| `add(items, options?)` | `Promise` | |
| `delete(paths, options?)` | `Promise` | |
| `operate(command, args)` | `Promise` | |
| `login(password)` | `Promise` | |
| `logout()` | `Promise` | |
| `refreshToken(token?)` | `Promise` | |
| `subscribe(id)` / `unsubscribe(id)` | `Promise` | |
| `listSubscriptions()` | `Promise` | |
| `isAuthenticated()` | `bool` (sync) | |
| `getToken()` | `string?` (sync) | |
| `free()` | `void` (sync) | |

`UspClientBuilder` (remote assistance): `new UspClientBuilder(baseUrl)
.endpoint(str).authToken(str).extraHeader(k,v).build()`.

## 3. Bridge HTTP surface (local mode)

The bridge client (`usp_bridge_client_web.dart`, paths in
`bridge_endpoints.dart`) calls, relative to `Uri.base.origin`:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/health` | GET | health check |
| `/api/v1/notifications` | GET | SSE stream (`text/event-stream`) |
| `/api/v1/subscription` | POST/GET | register/unregister/list subscriptions |
| `/api/v1/turbo/{start,heartbeat,release}` | POST | turbo channel lock |
| `/api/v1/turbo/status` | GET | turbo status |
| `/api/v1/auth/login` | POST | login (mints session token) |
| `POST /api/v1/usp` | POST | (WASM-internal) USP protobuf request → response |

Remote-assistance mode rewrites these under
`/v1/guardians/remote-assistances/sessions/{id}/usp/*`.

## 4. `E2E_MOCK` build flag

Build the app for E2E with `--dart-define=E2E_MOCK=true`
(`BuildConfig.e2eMock`). Behavior gated (production default false, unchanged):

- **P0-1 — SSE skipped, treated as online.** `SseConnectionManager.connect()`
  sets state to `connected` and skips stream setup, so the
  connecting/reconnecting/suspended banner never renders and downstream UI
  reads "online". (The real SSE stream cannot establish under a mocked bridge.)
- **P0-2 — onboarding preset dialog auto-popup suppressed.** The dashboard
  first-run preset dialog does not auto-open; open it explicitly in tests that
  need it.
- **P0-3 (planned, ui_kit) — TextEditingController readback.** Input widgets
  (`AppTextField` / `AppPasswordInput`) mirror controller text into
  `Semantics(value:)` → `aria-valuenow`, so tests can verify typed values.
  Shipped via the ui_kit package (bundled with the `semanticLabel` change).

## 5. Semantics labels (E2E selectors)

E2E locates widgets by kebab-case semantic labels (`{page}-{element}`).
Interactive widgets already thread `semanticLabel` through the ui_kit layer
(`AppButton` / `AppSwitch` / `AppListTile` / `AppMenuCard`) and the app's
`SettingBlock`. Current labels include: `login-password-input`,
`login-submit-button`, `menu-*` (wifi-settings, topology, devices, …),
`wifi-enable-{band}`, `unsaved-discard`, `unsaved-go-back`.
See the E2E charter (`e2e/CLAUDE.md`) for the authoritative list.
