/* tslint:disable */
/* eslint-disable */

/**
 * WASM-compatible USP client for web browsers
 *
 * # Example (JavaScript)
 * ```javascript
 * import init, { UspClient } from './usp_client.js';
 *
 * await init();
 * const client = new UspClient("https://router.local");
 * await client.login("password123");
 *
 * const value = await client.get("Device.DeviceInfo.Manufacturer");
 * console.log("Manufacturer:", value);
 *
 * await client.set("Device.WiFi.SSID.1.SSID", "MyNetwork");
 * await client.logout();
 * ```
 */
export class UspClient {
    free(): void;
    [Symbol.dispose](): void;
    /**
     * Performs an Add operation for single or multiple object instances (unified API)
     *
     * # Arguments
     * * `items` - Single object {path, params} or array of objects [{path, params}, ...]
     * * `options` - Optional object with {allowPartial: boolean} (defaults to {allowPartial: false})
     *
     * # Returns
     * * Promise that resolves to structured result with detailed operation status
     *
     * # Examples
     * ```javascript
     * // Single instance
     * await client.add({path: "Device.NAT.PortMapping.", params: {"ExternalPort": "8080"}});
     *
     * // Multiple instances with partial mode
     * await client.add([
     *     {path: "Device.NAT.PortMapping.", params: {"ExternalPort": "8080"}},
     *     {path: "Device.NAT.PortMapping.", params: {"ExternalPort": "8443"}}
     * ], {allowPartial: true});
     * ```
     */
    add(items: any, options?: any | null): Promise<any>;
    /**
     * Gets the base URL of the client
     *
     * # Returns
     * * Base URL string
     */
    baseUrl(): string;
    /**
     * Creates an EventSource connection to the bridge's SSE notifications endpoint.
     *
     * Returns the browser `EventSource` object directly — the caller is responsible
     * for attaching event listeners and managing the connection lifecycle.
     *
     * Uses `withCredentials: true` so the browser sends the session cookie
     * automatically. For Bearer-token auth, use `getToken()` and construct
     * the EventSource manually with a query parameter.
     *
     * # Returns
     * * `EventSource` object on success
     * * Throws JavaScript exception on error
     *
     * # Example (JavaScript)
     * ```javascript
     * const es = client.connectNotifications();
     * es.onmessage = (event) => console.log("SSE:", event.data);
     * es.onerror = (err) => console.error("SSE error:", err);
     * // To close: es.close();
     * ```
     */
    connectNotifications(): EventSource;
    /**
     * Performs a Delete operation for single or multiple object instances (unified API)
     *
     * # Arguments
     * * `paths` - Single path (string) or array of paths to delete
     * * `options` - Optional object with {allowPartial: boolean} (defaults to {allowPartial: false})
     *
     * # Returns
     * * Promise that resolves to structured result with detailed operation status
     *
     * # Examples
     * ```javascript
     * // Single path
     * await client.delete("Device.NAT.PortMapping.3.");
     *
     * // Multiple paths with partial mode
     * await client.delete([
     *     "Device.NAT.PortMapping.3.",
     *     "Device.NAT.PortMapping.4."
     * ], {allowPartial: true});
     * ```
     */
    delete(paths: any, options?: any | null): Promise<any>;
    /**
     * Performs a Get operation for single or multiple parameters (unified API)
     *
     * # Arguments
     * * `paths` - Single parameter path (string) or array of parameter paths
     *
     * # Returns
     * * Promise that resolves to JavaScript object with path-value pairs
     *
     * # Examples
     * ```javascript
     * // Single path
     * await client.get("Device.DeviceInfo.Manufacturer");
     *
     * // Multiple paths
     * await client.get(["Device.DeviceInfo.Manufacturer", "Device.WiFi.SSID.1.SSID"]);
     * ```
     */
    get(paths: any): Promise<any>;
    /**
     * Returns the current session token string, if authenticated.
     *
     * Use this to make direct API calls to the bridge (e.g., SSE notifications)
     * that require JWT authentication.
     *
     * # Returns
     * * Token string if authenticated, `undefined` if not
     *
     * # Example (JavaScript)
     * ```javascript
     * const token = client.getToken();
     * if (token) {
     *     const source = new EventSource(`/api/v1/notifications?token=${token}`);
     * }
     * ```
     */
    getToken(): string | undefined;
    /**
     * Checks if the client is authenticated
     *
     * # Returns
     * * `true` if authenticated, `false` otherwise
     */
    isAuthenticated(): boolean;
    /**
     * Lists all active subscriptions for the current session.
     *
     * # Returns
     * * Promise that resolves with an array of subscription objects
     *
     * # Example (JavaScript)
     * ```javascript
     * const subs = await client.listSubscriptions();
     * // [{ subscription_id: "wifi-status", path: "Device.WiFi.", active: true }, ...]
     * ```
     */
    listSubscriptions(): Promise<any>;
    /**
     * Authenticates with the router using password
     *
     * # Arguments
     * * `password` - Router admin password
     *
     * # Returns
     * * Promise that resolves on success, rejects on error
     */
    login(password: string): Promise<any>;
    /**
     * Logs out and invalidates the session
     *
     * # Returns
     * * Promise that resolves on success, rejects on error
     */
    logout(): Promise<any>;
    /**
     * Creates a new USP client instance
     *
     * # Arguments
     * * `base_url` - Base URL of the USP controller (e.g., "https://router.local")
     *
     * # Returns
     * * `UspClient` instance on success
     * * Throws JavaScript exception on error
     *
     * # Example (JavaScript)
     * ```javascript
     * const client = new UspClient("https://192.168.1.1");
     * ```
     */
    constructor(base_url: string);
    /**
     * Returns the full notifications SSE endpoint URL.
     *
     * Useful for constructing a custom EventSource with Bearer token auth.
     *
     * # Returns
     * * Full URL string (e.g., "https://192.168.1.1/api/v1/notifications")
     *
     * # Example (JavaScript)
     * ```javascript
     * const url = client.notificationsUrl();
     * const token = client.getToken();
     * const es = new EventSource(`${url}?token=${token}`);
     * ```
     */
    notificationsUrl(): string;
    /**
     * Performs an Operate command on the USP agent
     *
     * # Arguments
     * * `command` - Command path (e.g., "Device.Reboot()" or "Device.IP.Diagnostics.Ping()")
     * * `args` - JavaScript object with input argument name-value pairs (optional, pass {} for no args)
     *
     * # Returns
     * * Promise that resolves to `{ commandKey: string, outputArgs: Record<string, string> | undefined }`
     *   - `commandKey` — UUID for correlating with OperationComplete notifications
     *   - `outputArgs` — output arguments from the command (undefined if none)
     *
     * # Example (JavaScript)
     * ```javascript
     * // Simple command with no arguments
     * const { commandKey } = await client.operate("Device.Reboot()", {});
     * console.log("Track async result with:", commandKey);
     *
     * // Command with input arguments
     * const result = await client.operate("Device.IP.Diagnostics.Ping()", {
     *     "Host": "8.8.8.8",
     *     "NumberOfRepetitions": "4"
     * });
     * console.log(result.commandKey);   // "a1b2c3d4-..."
     * console.log(result.outputArgs);   // { "SuccessCount": "4", "AverageResponseTime": "12" }
     * ```
     */
    operate(command: string, args: any): Promise<any>;
    /**
     * Refreshes the authentication token, optionally restoring from an external token.
     *
     * This method can be used to:
     * 1. Refresh the current session token (when `token` is `undefined`)
     * 2. Restore and validate a token from external storage (when `token` is provided)
     *
     * When restoring from external storage (e.g., localStorage), the provided token
     * is sent to the server to request a fresh token. This validates that the token
     * is still valid and refreshable.
     *
     * # Arguments
     * * `token` - Optional token to restore. If `undefined`, uses the current session token.
     *
     * # Returns
     * * Promise that resolves on success, rejects on error (token expired, invalid, etc.)
     *
     * # Example (JavaScript)
     * ```javascript
     * // Normal refresh after login
     * await client.refreshToken();
     *
     * // Restore token from localStorage on page load
     * const savedToken = localStorage.getItem('usp_token');
     * if (savedToken) {
     *     try {
     *         await client.refreshToken(savedToken);
     *         console.log('Token restored and validated');
     *     } catch (e) {
     *         console.log('Token expired, need to re-login');
     *         localStorage.removeItem('usp_token');
     *     }
     * }
     * ```
     */
    refreshToken(token?: string | null): Promise<any>;
    /**
     * Performs a Set operation for single or multiple parameters (unified API)
     *
     * # Arguments
     * * `parameters` - JavaScript object with path-value pairs
     * * `options` - Optional object with {allowPartial: boolean} (defaults to {allowPartial: false})
     *
     * # Returns
     * * Promise that resolves to structured result with detailed operation status
     *
     * # Examples
     * ```javascript
     * // Single parameter
     * await client.set({"Device.WiFi.SSID.1.SSID": "NewNetwork"});
     *
     * // Multiple parameters with partial mode
     * await client.set({
     *     "Device.WiFi.SSID.1.SSID": "NewNetwork",
     *     "Device.WiFi.Radio.1.Channel": "6"
     * }, {allowPartial: true});
     * ```
     */
    set(parameters: any, options?: any | null): Promise<any>;
    /**
     * Performs a grouped ordered Set operation preserving priority-based parameter sequence
     *
     * Parameters are organized into priority groups. Within each group, parameters
     * sharing the same object path are merged into a single USP UpdateObject.
     * Groups are sent in order, preserving the priority-based execution sequence.
     *
     * # Arguments
     * * `groups_array` - JavaScript array of arrays: `[[{path, value}, ...], ...]`
     * * `allow_partial` - If true, allows partial success
     *
     * # Returns
     * * Promise that resolves to structured result with detailed operation status
     *
     * # Example (JavaScript)
     * ```javascript
     * const result = await client.setOrdered([
     *     [
     *       { path: "Device.WiFi.Radio.1.Enable", value: "false" }
     *     ],
     *     [
     *       { path: "Device.WiFi.SSID.1.SSID", value: "NewNetwork" },
     *       { path: "Device.WiFi.SSID.1.Enable", value: "true" }
     *     ],
     *     [
     *       { path: "Device.WiFi.Radio.1.Enable", value: "true" }
     *     ]
     * ], true);
     * ```
     */
    setOrdered(groups_array: any, allow_partial: boolean): Promise<any>;
    /**
     * Registers a notification subscription with the bridge.
     *
     * # Arguments
     * * `subscription_id` - Unique subscription identifier
     * * `path` - USP object path to monitor (e.g., "Device.Hosts.Host.")
     * * `notification_type` - USP notification type: 1=ValueChange, 2=ObjectCreation, 3=ObjectDeletion
     *
     * # Returns
     * * Promise that resolves on success, rejects on error
     *
     * # Example (JavaScript)
     * ```javascript
     * await client.subscribe("host-changes", "Device.Hosts.Host.", 1);
     * ```
     */
    subscribe(subscription_id: string, path: string, notification_type: number): Promise<any>;
    /**
     * Removes a notification subscription from the bridge.
     *
     * # Arguments
     * * `subscription_id` - Subscription identifier to remove
     *
     * # Returns
     * * Promise that resolves on success, rejects on error
     *
     * # Example (JavaScript)
     * ```javascript
     * await client.unsubscribe("wifi-status");
     * ```
     */
    unsubscribe(subscription_id: string): Promise<any>;
}

/**
 * Builder for creating a UspClient with custom configuration.
 *
 * # Example (JavaScript)
 * ```javascript
 * import init, { UspClientBuilder } from './usp_client.js';
 *
 * await init();
 *
 * // Create client for remote USP endpoint
 * const client = new UspClientBuilder("https://api.example.com")
 *     .endpoint("/v1/usp")
 *     .authToken("my-token")
 *     .extraHeader("X-Custom-Header", "value")
 *     .build();
 *
 * const result = await client.get("Device.DeviceInfo.");
 * ```
 */
export class UspClientBuilder {
    free(): void;
    [Symbol.dispose](): void;
    /**
     * Sets the authentication token (skips the login flow)
     *
     * # Arguments
     * * `token` - Authentication token (e.g., Bearer token)
     */
    authToken(token: string): UspClientBuilder;
    /**
     * Builds the UspClient
     *
     * # Returns
     * * `UspClient` instance on success
     * * Throws JavaScript exception on error
     */
    build(): UspClient;
    /**
     * Sets the USP endpoint path
     *
     * # Arguments
     * * `endpoint` - Endpoint path (e.g., "/v1/usp")
     */
    endpoint(endpoint: string): UspClientBuilder;
    /**
     * Adds an extra HTTP header to include with every request
     *
     * # Arguments
     * * `name` - Header name
     * * `value` - Header value
     */
    extraHeader(name: string, value: string): UspClientBuilder;
    /**
     * Creates a new builder with the specified base URL
     *
     * # Arguments
     * * `base_url` - Base URL of the USP controller (e.g., "https://api.example.com")
     */
    constructor(base_url: string);
}

/**
 * JS-facing WebSocket client. Single-consumer; not cloneable.
 *
 * # Example (JavaScript)
 * ```javascript
 * const ws = await UspWsClient.connect("wss://192.168.1.1/usp-ws");
 * ws.on_record((bytes) => console.log("record:", bytes));
 * await ws.send_record(recordBytes);
 * ws.close();
 * ```
 */
export class UspWsClient {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    /**
     * Close the socket. Subsequent `sendRecord` calls reject.
     */
    close(): void;
    /**
     * Open a connection. Resolves to a `UspWsClient` once the socket
     * is established.
     *
     * `subprotocol` declares the `Sec-WebSocket-Protocol` to send during
     * the upgrade handshake. USP requires `"v1.usp"` (TR-369 §6.4.4);
     * OBUSPA destroys connections that omit it. Pass `None` only when
     * connecting to a non-USP echo server.
     */
    static connect(url: string, subprotocol?: string | null): Promise<any>;
    /**
     * Register the per-record callback. Replaces any previous one.
     * `cb` is called as `cb(Uint8Array)`.
     */
    onRecord(cb: Function): void;
    /**
     * Register the connection-state callback.
     * `cb` is called as `cb(state: string)` with `"open"` or `"closed"`.
     */
    onStateChange(cb: Function): void;
    /**
     * Queue a binary USP Record for delivery. Resolves once enqueued.
     */
    sendRecord(bytes: Uint8Array): Promise<any>;
}

/**
 * Build a USP Record carrying a `Get` for a single parameter path.
 *
 * The Record is needed for WebSocket-MTP traffic (the HTTP path used
 * by `UspClient` sends bare Msg bytes; the Linksys bridge wraps for HTTP).
 *
 * # JavaScript
 * ```javascript
 * const bytes = buildGetRecord(
 *   "Device.DeviceInfo.SoftwareVersion",
 *   "controller::localui-turbo",
 *   "os::router-001122334455"
 * );
 * await ws.sendRecord(bytes);
 * ```
 */
export function buildGetRecord(path: string, from_id: string, to_id: string): Uint8Array;

/**
 * Build a USP Record carrying an `Operate` command.
 *
 * # JavaScript
 * ```javascript
 * const bytes = buildOperateRecord(
 *   "Device.LocalAgent.X_LINKSYS_Download()",
 *   { "Data": base64chunk, "Offset": "0", "Size": "65535" },
 *   "controller::localui-turbo",
 *   "os::router-001122334455"
 * );
 * await ws.sendRecord(bytes);
 * ```
 */
export function buildOperateRecord(command: string, input_args: any, from_id: string, to_id: string): Uint8Array;

/**
 * Build the mandatory `WebSocketConnectRecord` first frame for USP WS MTP
 * (TR-369 §6.4.5). OBUSPA destroys the connection if this is not the
 * first binary frame after upgrade.
 *
 * # JavaScript
 * ```javascript
 * const handshake = buildWebSocketConnect(
 *   "controller::localui-turbo",
 *   "os::router-001122334455"
 * );
 * await ws.sendRecord(handshake);
 * ```
 */
export function buildWebSocketConnect(from_id: string, to_id: string): Uint8Array;

/**
 * Decode a USP Record received over WebSocket and return a JS object
 * with the parsed response.
 *
 * # JavaScript
 * ```javascript
 * const result = decodeRecord(responseBytes);
 * // result = { from_id, to_id, version, msg_type, msg_id, command?, output_args?, error? }
 * ```
 */
export function decodeRecord(data: Uint8Array): any;

/**
 * Initialize the WASM module
 *
 * # Example (JavaScript)
 * ```javascript
 * import init from './usp_client.js';
 * await init();
 * ```
 */
export function init(): void;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
    readonly memory: WebAssembly.Memory;
    readonly __wbg_uspclient_free: (a: number, b: number) => void;
    readonly __wbg_uspclientbuilder_free: (a: number, b: number) => void;
    readonly __wbg_uspwsclient_free: (a: number, b: number) => void;
    readonly buildGetRecord: (a: number, b: number, c: number, d: number, e: number, f: number, g: number) => void;
    readonly buildOperateRecord: (a: number, b: number, c: number, d: number, e: number, f: number, g: number, h: number) => void;
    readonly buildWebSocketConnect: (a: number, b: number, c: number, d: number, e: number) => void;
    readonly decodeRecord: (a: number, b: number, c: number) => void;
    readonly init: () => void;
    readonly uspclient_add: (a: number, b: number, c: number) => number;
    readonly uspclient_baseUrl: (a: number, b: number) => void;
    readonly uspclient_connectNotifications: (a: number, b: number) => void;
    readonly uspclient_delete: (a: number, b: number, c: number) => number;
    readonly uspclient_get: (a: number, b: number) => number;
    readonly uspclient_getToken: (a: number, b: number) => void;
    readonly uspclient_isAuthenticated: (a: number) => number;
    readonly uspclient_listSubscriptions: (a: number) => number;
    readonly uspclient_login: (a: number, b: number, c: number) => number;
    readonly uspclient_logout: (a: number) => number;
    readonly uspclient_new: (a: number, b: number, c: number) => void;
    readonly uspclient_notificationsUrl: (a: number, b: number) => void;
    readonly uspclient_operate: (a: number, b: number, c: number, d: number) => number;
    readonly uspclient_refreshToken: (a: number, b: number, c: number) => number;
    readonly uspclient_set: (a: number, b: number, c: number) => number;
    readonly uspclient_setOrdered: (a: number, b: number, c: number) => number;
    readonly uspclient_subscribe: (a: number, b: number, c: number, d: number, e: number, f: number) => number;
    readonly uspclient_unsubscribe: (a: number, b: number, c: number) => number;
    readonly uspclientbuilder_authToken: (a: number, b: number, c: number) => number;
    readonly uspclientbuilder_build: (a: number, b: number) => void;
    readonly uspclientbuilder_endpoint: (a: number, b: number, c: number) => number;
    readonly uspclientbuilder_extraHeader: (a: number, b: number, c: number, d: number, e: number) => number;
    readonly uspclientbuilder_new: (a: number, b: number) => number;
    readonly uspwsclient_close: (a: number) => void;
    readonly uspwsclient_connect: (a: number, b: number, c: number, d: number) => number;
    readonly uspwsclient_onRecord: (a: number, b: number) => void;
    readonly uspwsclient_onStateChange: (a: number, b: number) => void;
    readonly uspwsclient_sendRecord: (a: number, b: number, c: number) => number;
    readonly __wasm_bindgen_func_elem_3024: (a: number, b: number, c: number, d: number) => void;
    readonly __wasm_bindgen_func_elem_3026: (a: number, b: number, c: number, d: number) => void;
    readonly __wasm_bindgen_func_elem_2348: (a: number, b: number, c: number) => void;
    readonly __wasm_bindgen_func_elem_2348_2: (a: number, b: number, c: number) => void;
    readonly __wasm_bindgen_func_elem_2348_3: (a: number, b: number, c: number) => void;
    readonly __wasm_bindgen_func_elem_2347: (a: number, b: number) => void;
    readonly __wbindgen_export: (a: number, b: number) => number;
    readonly __wbindgen_export2: (a: number, b: number, c: number, d: number) => number;
    readonly __wbindgen_export3: (a: number) => void;
    readonly __wbindgen_export4: (a: number, b: number, c: number) => void;
    readonly __wbindgen_export5: (a: number, b: number) => void;
    readonly __wbindgen_add_to_stack_pointer: (a: number) => number;
    readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;

/**
 * Instantiates the given `module`, which can either be bytes or
 * a precompiled `WebAssembly.Module`.
 *
 * @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
 *
 * @returns {InitOutput}
 */
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
 * If `module_or_path` is {RequestInfo} or {URL}, makes a request and
 * for everything else, calls `WebAssembly.instantiate` directly.
 *
 * @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
 *
 * @returns {Promise<InitOutput>}
 */
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
