/* @ts-self-types="./usp_client.d.ts" */

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
    static __wrap(ptr) {
        const obj = Object.create(UspClient.prototype);
        obj.__wbg_ptr = ptr;
        UspClientFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        UspClientFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_uspclient_free(ptr, 0);
    }
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
     * @param {any} items
     * @param {any | null} [options]
     * @returns {Promise<any>}
     */
    add(items, options) {
        const ret = wasm.uspclient_add(this.__wbg_ptr, addHeapObject(items), isLikeNone(options) ? 0 : addHeapObject(options));
        return takeObject(ret);
    }
    /**
     * Gets the base URL of the client
     *
     * # Returns
     * * Base URL string
     * @returns {string}
     */
    baseUrl() {
        let deferred1_0;
        let deferred1_1;
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.uspclient_baseUrl(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            deferred1_0 = r0;
            deferred1_1 = r1;
            return getStringFromWasm0(r0, r1);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
            wasm.__wbindgen_export4(deferred1_0, deferred1_1, 1);
        }
    }
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
     * @returns {EventSource}
     */
    connectNotifications() {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.uspclient_connectNotifications(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            var r2 = getDataViewMemory0().getInt32(retptr + 4 * 2, true);
            if (r2) {
                throw takeObject(r1);
            }
            return takeObject(r0);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }
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
     * @param {any} paths
     * @param {any | null} [options]
     * @returns {Promise<any>}
     */
    delete(paths, options) {
        const ret = wasm.uspclient_delete(this.__wbg_ptr, addHeapObject(paths), isLikeNone(options) ? 0 : addHeapObject(options));
        return takeObject(ret);
    }
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
     * @param {any} paths
     * @returns {Promise<any>}
     */
    get(paths) {
        const ret = wasm.uspclient_get(this.__wbg_ptr, addHeapObject(paths));
        return takeObject(ret);
    }
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
     * @returns {string | undefined}
     */
    getToken() {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.uspclient_getToken(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            let v1;
            if (r0 !== 0) {
                v1 = getStringFromWasm0(r0, r1).slice();
                wasm.__wbindgen_export4(r0, r1 * 1, 1);
            }
            return v1;
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }
    /**
     * Checks if the client is authenticated
     *
     * # Returns
     * * `true` if authenticated, `false` otherwise
     * @returns {boolean}
     */
    isAuthenticated() {
        const ret = wasm.uspclient_isAuthenticated(this.__wbg_ptr);
        return ret !== 0;
    }
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
     * @returns {Promise<any>}
     */
    listSubscriptions() {
        const ret = wasm.uspclient_listSubscriptions(this.__wbg_ptr);
        return takeObject(ret);
    }
    /**
     * Authenticates with the router using password
     *
     * # Arguments
     * * `password` - Router admin password
     *
     * # Returns
     * * Promise that resolves on success, rejects on error
     * @param {string} password
     * @returns {Promise<any>}
     */
    login(password) {
        const ptr0 = passStringToWasm0(password, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.uspclient_login(this.__wbg_ptr, ptr0, len0);
        return takeObject(ret);
    }
    /**
     * Logs out and invalidates the session
     *
     * # Returns
     * * Promise that resolves on success, rejects on error
     * @returns {Promise<any>}
     */
    logout() {
        const ret = wasm.uspclient_logout(this.__wbg_ptr);
        return takeObject(ret);
    }
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
     * @param {string} base_url
     */
    constructor(base_url) {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            const ptr0 = passStringToWasm0(base_url, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len0 = WASM_VECTOR_LEN;
            wasm.uspclient_new(retptr, ptr0, len0);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            var r2 = getDataViewMemory0().getInt32(retptr + 4 * 2, true);
            if (r2) {
                throw takeObject(r1);
            }
            this.__wbg_ptr = r0;
            UspClientFinalization.register(this, this.__wbg_ptr, this);
            return this;
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }
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
     * @returns {string}
     */
    notificationsUrl() {
        let deferred1_0;
        let deferred1_1;
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.uspclient_notificationsUrl(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            deferred1_0 = r0;
            deferred1_1 = r1;
            return getStringFromWasm0(r0, r1);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
            wasm.__wbindgen_export4(deferred1_0, deferred1_1, 1);
        }
    }
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
     * @param {string} command
     * @param {any} args
     * @returns {Promise<any>}
     */
    operate(command, args) {
        const ptr0 = passStringToWasm0(command, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.uspclient_operate(this.__wbg_ptr, ptr0, len0, addHeapObject(args));
        return takeObject(ret);
    }
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
     * @param {string | null} [token]
     * @returns {Promise<any>}
     */
    refreshToken(token) {
        var ptr0 = isLikeNone(token) ? 0 : passStringToWasm0(token, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        var len0 = WASM_VECTOR_LEN;
        const ret = wasm.uspclient_refreshToken(this.__wbg_ptr, ptr0, len0);
        return takeObject(ret);
    }
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
     * @param {any} parameters
     * @param {any | null} [options]
     * @returns {Promise<any>}
     */
    set(parameters, options) {
        const ret = wasm.uspclient_set(this.__wbg_ptr, addHeapObject(parameters), isLikeNone(options) ? 0 : addHeapObject(options));
        return takeObject(ret);
    }
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
     * @param {any} groups_array
     * @param {boolean} allow_partial
     * @returns {Promise<any>}
     */
    setOrdered(groups_array, allow_partial) {
        const ret = wasm.uspclient_setOrdered(this.__wbg_ptr, addHeapObject(groups_array), allow_partial);
        return takeObject(ret);
    }
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
     * @param {string} subscription_id
     * @param {string} path
     * @param {number} notification_type
     * @returns {Promise<any>}
     */
    subscribe(subscription_id, path, notification_type) {
        const ptr0 = passStringToWasm0(subscription_id, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(path, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.uspclient_subscribe(this.__wbg_ptr, ptr0, len0, ptr1, len1, notification_type);
        return takeObject(ret);
    }
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
     * @param {string} subscription_id
     * @returns {Promise<any>}
     */
    unsubscribe(subscription_id) {
        const ptr0 = passStringToWasm0(subscription_id, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.uspclient_unsubscribe(this.__wbg_ptr, ptr0, len0);
        return takeObject(ret);
    }
}
if (Symbol.dispose) UspClient.prototype[Symbol.dispose] = UspClient.prototype.free;

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
    static __wrap(ptr) {
        const obj = Object.create(UspClientBuilder.prototype);
        obj.__wbg_ptr = ptr;
        UspClientBuilderFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        UspClientBuilderFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_uspclientbuilder_free(ptr, 0);
    }
    /**
     * Sets the authentication token (skips the login flow)
     *
     * # Arguments
     * * `token` - Authentication token (e.g., Bearer token)
     * @param {string} token
     * @returns {UspClientBuilder}
     */
    authToken(token) {
        const ptr = this.__destroy_into_raw();
        const ptr0 = passStringToWasm0(token, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.uspclientbuilder_authToken(ptr, ptr0, len0);
        return UspClientBuilder.__wrap(ret);
    }
    /**
     * Builds the UspClient
     *
     * # Returns
     * * `UspClient` instance on success
     * * Throws JavaScript exception on error
     * @returns {UspClient}
     */
    build() {
        try {
            const ptr = this.__destroy_into_raw();
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.uspclientbuilder_build(retptr, ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            var r2 = getDataViewMemory0().getInt32(retptr + 4 * 2, true);
            if (r2) {
                throw takeObject(r1);
            }
            return UspClient.__wrap(r0);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }
    /**
     * Sets the USP endpoint path
     *
     * # Arguments
     * * `endpoint` - Endpoint path (e.g., "/v1/usp")
     * @param {string} endpoint
     * @returns {UspClientBuilder}
     */
    endpoint(endpoint) {
        const ptr = this.__destroy_into_raw();
        const ptr0 = passStringToWasm0(endpoint, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.uspclientbuilder_endpoint(ptr, ptr0, len0);
        return UspClientBuilder.__wrap(ret);
    }
    /**
     * Adds an extra HTTP header to include with every request
     *
     * # Arguments
     * * `name` - Header name
     * * `value` - Header value
     * @param {string} name
     * @param {string} value
     * @returns {UspClientBuilder}
     */
    extraHeader(name, value) {
        const ptr = this.__destroy_into_raw();
        const ptr0 = passStringToWasm0(name, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(value, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.uspclientbuilder_extraHeader(ptr, ptr0, len0, ptr1, len1);
        return UspClientBuilder.__wrap(ret);
    }
    /**
     * Creates a new builder with the specified base URL
     *
     * # Arguments
     * * `base_url` - Base URL of the USP controller (e.g., "https://api.example.com")
     * @param {string} base_url
     */
    constructor(base_url) {
        const ptr0 = passStringToWasm0(base_url, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.uspclientbuilder_new(ptr0, len0);
        this.__wbg_ptr = ret;
        UspClientBuilderFinalization.register(this, this.__wbg_ptr, this);
        return this;
    }
}
if (Symbol.dispose) UspClientBuilder.prototype[Symbol.dispose] = UspClientBuilder.prototype.free;

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
    static __wrap(ptr) {
        const obj = Object.create(UspWsClient.prototype);
        obj.__wbg_ptr = ptr;
        UspWsClientFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        UspWsClientFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_uspwsclient_free(ptr, 0);
    }
    /**
     * Close the socket. Subsequent `sendRecord` calls reject.
     */
    close() {
        wasm.uspwsclient_close(this.__wbg_ptr);
    }
    /**
     * Open a connection. Resolves to a `UspWsClient` once the socket
     * is established.
     *
     * `subprotocol` declares the `Sec-WebSocket-Protocol` to send during
     * the upgrade handshake. USP requires `"v1.usp"` (TR-369 §6.4.4);
     * OBUSPA destroys connections that omit it. Pass `None` only when
     * connecting to a non-USP echo server.
     * @param {string} url
     * @param {string | null} [subprotocol]
     * @returns {Promise<any>}
     */
    static connect(url, subprotocol) {
        const ptr0 = passStringToWasm0(url, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        var ptr1 = isLikeNone(subprotocol) ? 0 : passStringToWasm0(subprotocol, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        var len1 = WASM_VECTOR_LEN;
        const ret = wasm.uspwsclient_connect(ptr0, len0, ptr1, len1);
        return takeObject(ret);
    }
    /**
     * Register the per-record callback. Replaces any previous one.
     * `cb` is called as `cb(Uint8Array)`.
     * @param {Function} cb
     */
    onRecord(cb) {
        wasm.uspwsclient_onRecord(this.__wbg_ptr, addHeapObject(cb));
    }
    /**
     * Register the connection-state callback.
     * `cb` is called as `cb(state: string)` with `"open"` or `"closed"`.
     * @param {Function} cb
     */
    onStateChange(cb) {
        wasm.uspwsclient_onStateChange(this.__wbg_ptr, addHeapObject(cb));
    }
    /**
     * Queue a binary USP Record for delivery. Resolves once enqueued.
     * @param {Uint8Array} bytes
     * @returns {Promise<any>}
     */
    sendRecord(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_export);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.uspwsclient_sendRecord(this.__wbg_ptr, ptr0, len0);
        return takeObject(ret);
    }
}
if (Symbol.dispose) UspWsClient.prototype[Symbol.dispose] = UspWsClient.prototype.free;

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
 * @param {string} path
 * @param {string} from_id
 * @param {string} to_id
 * @returns {Uint8Array}
 */
export function buildGetRecord(path, from_id, to_id) {
    try {
        const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
        const ptr0 = passStringToWasm0(path, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(from_id, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passStringToWasm0(to_id, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len2 = WASM_VECTOR_LEN;
        wasm.buildGetRecord(retptr, ptr0, len0, ptr1, len1, ptr2, len2);
        var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
        var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
        var r2 = getDataViewMemory0().getInt32(retptr + 4 * 2, true);
        var r3 = getDataViewMemory0().getInt32(retptr + 4 * 3, true);
        if (r3) {
            throw takeObject(r2);
        }
        var v4 = getArrayU8FromWasm0(r0, r1).slice();
        wasm.__wbindgen_export4(r0, r1 * 1, 1);
        return v4;
    } finally {
        wasm.__wbindgen_add_to_stack_pointer(16);
    }
}

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
 * @param {string} command
 * @param {any} input_args
 * @param {string} from_id
 * @param {string} to_id
 * @returns {Uint8Array}
 */
export function buildOperateRecord(command, input_args, from_id, to_id) {
    try {
        const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
        const ptr0 = passStringToWasm0(command, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(from_id, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passStringToWasm0(to_id, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len2 = WASM_VECTOR_LEN;
        wasm.buildOperateRecord(retptr, ptr0, len0, addHeapObject(input_args), ptr1, len1, ptr2, len2);
        var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
        var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
        var r2 = getDataViewMemory0().getInt32(retptr + 4 * 2, true);
        var r3 = getDataViewMemory0().getInt32(retptr + 4 * 3, true);
        if (r3) {
            throw takeObject(r2);
        }
        var v4 = getArrayU8FromWasm0(r0, r1).slice();
        wasm.__wbindgen_export4(r0, r1 * 1, 1);
        return v4;
    } finally {
        wasm.__wbindgen_add_to_stack_pointer(16);
    }
}

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
 * @param {string} from_id
 * @param {string} to_id
 * @returns {Uint8Array}
 */
export function buildWebSocketConnect(from_id, to_id) {
    try {
        const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
        const ptr0 = passStringToWasm0(from_id, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(to_id, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len1 = WASM_VECTOR_LEN;
        wasm.buildWebSocketConnect(retptr, ptr0, len0, ptr1, len1);
        var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
        var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
        var r2 = getDataViewMemory0().getInt32(retptr + 4 * 2, true);
        var r3 = getDataViewMemory0().getInt32(retptr + 4 * 3, true);
        if (r3) {
            throw takeObject(r2);
        }
        var v3 = getArrayU8FromWasm0(r0, r1).slice();
        wasm.__wbindgen_export4(r0, r1 * 1, 1);
        return v3;
    } finally {
        wasm.__wbindgen_add_to_stack_pointer(16);
    }
}

/**
 * Decode a USP Record received over WebSocket and return a JS object
 * with the parsed response.
 *
 * # JavaScript
 * ```javascript
 * const result = decodeRecord(responseBytes);
 * // result = { from_id, to_id, version, msg_type, msg_id, command?, output_args?, error? }
 * ```
 * @param {Uint8Array} data
 * @returns {any}
 */
export function decodeRecord(data) {
    try {
        const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
        const ptr0 = passArray8ToWasm0(data, wasm.__wbindgen_export);
        const len0 = WASM_VECTOR_LEN;
        wasm.decodeRecord(retptr, ptr0, len0);
        var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
        var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
        var r2 = getDataViewMemory0().getInt32(retptr + 4 * 2, true);
        if (r2) {
            throw takeObject(r1);
        }
        return takeObject(r0);
    } finally {
        wasm.__wbindgen_add_to_stack_pointer(16);
    }
}

/**
 * Initialize the WASM module
 *
 * # Example (JavaScript)
 * ```javascript
 * import init from './usp_client.js';
 * await init();
 * ```
 */
export function init() {
    wasm.init();
}
function __wbg_get_imports() {
    const import0 = {
        __proto__: null,
        __wbg___wbindgen_boolean_get_2304fb8c853028c8: function(arg0) {
            const v = getObject(arg0);
            const ret = typeof(v) === 'boolean' ? v : undefined;
            return isLikeNone(ret) ? 0xFFFFFF : ret ? 1 : 0;
        },
        __wbg___wbindgen_debug_string_edece8177ad01481: function(arg0, arg1) {
            const ret = debugString(getObject(arg1));
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg___wbindgen_is_function_5cd60d5cf78b4eef: function(arg0) {
            const ret = typeof(getObject(arg0)) === 'function';
            return ret;
        },
        __wbg___wbindgen_is_null_2042690d351e14f0: function(arg0) {
            const ret = getObject(arg0) === null;
            return ret;
        },
        __wbg___wbindgen_is_object_b4593df85baada48: function(arg0) {
            const val = getObject(arg0);
            const ret = typeof(val) === 'object' && val !== null;
            return ret;
        },
        __wbg___wbindgen_is_string_dde0fd9020db4434: function(arg0) {
            const ret = typeof(getObject(arg0)) === 'string';
            return ret;
        },
        __wbg___wbindgen_is_undefined_35bb9f4c7fd651d5: function(arg0) {
            const ret = getObject(arg0) === undefined;
            return ret;
        },
        __wbg___wbindgen_string_get_d109740c0d18f4d7: function(arg0, arg1) {
            const obj = getObject(arg1);
            const ret = typeof(obj) === 'string' ? obj : undefined;
            var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            var len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg___wbindgen_throw_9c31b086c2b26051: function(arg0, arg1) {
            throw new Error(getStringFromWasm0(arg0, arg1));
        },
        __wbg__wbg_cb_unref_3fa391f3fcdb55f8: function(arg0) {
            getObject(arg0)._wbg_cb_unref();
        },
        __wbg_abort_b363e6285472a358: function(arg0) {
            getObject(arg0).abort();
        },
        __wbg_addEventListener_737cdb55f09bc146: function() { return handleError(function (arg0, arg1, arg2, arg3, arg4) {
            getObject(arg0).addEventListener(getStringFromWasm0(arg1, arg2), getObject(arg3), getObject(arg4));
        }, arguments); },
        __wbg_addEventListener_aedacff123afaebd: function() { return handleError(function (arg0, arg1, arg2, arg3) {
            getObject(arg0).addEventListener(getStringFromWasm0(arg1, arg2), getObject(arg3));
        }, arguments); },
        __wbg_append_263958599fd198c1: function() { return handleError(function (arg0, arg1, arg2, arg3, arg4) {
            getObject(arg0).append(getStringFromWasm0(arg1, arg2), getStringFromWasm0(arg3, arg4));
        }, arguments); },
        __wbg_arrayBuffer_cb5d4748b5f3cad5: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).arrayBuffer();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_call_13665d9f14390edc: function() { return handleError(function (arg0, arg1) {
            const ret = getObject(arg0).call(getObject(arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_call_dfde26266607c996: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = getObject(arg0).call(getObject(arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_close_e323e9eee669c291: function() { return handleError(function (arg0) {
            getObject(arg0).close();
        }, arguments); },
        __wbg_code_98ceeaa5ff83fb0b: function(arg0) {
            const ret = getObject(arg0).code;
            return ret;
        },
        __wbg_data_5fc79a19e47d1531: function(arg0) {
            const ret = getObject(arg0).data;
            return addHeapObject(ret);
        },
        __wbg_dispatchEvent_29c919cea8d37995: function() { return handleError(function (arg0, arg1) {
            const ret = getObject(arg0).dispatchEvent(getObject(arg1));
            return ret;
        }, arguments); },
        __wbg_done_54b8da57023b7ed2: function(arg0) {
            const ret = getObject(arg0).done;
            return ret;
        },
        __wbg_entries_564a7e8b1e54ede5: function(arg0) {
            const ret = Object.entries(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_error_a6fa202b58aa1cd3: function(arg0, arg1) {
            let deferred0_0;
            let deferred0_1;
            try {
                deferred0_0 = arg0;
                deferred0_1 = arg1;
                console.error(getStringFromWasm0(arg0, arg1));
            } finally {
                wasm.__wbindgen_export4(deferred0_0, deferred0_1, 1);
            }
        },
        __wbg_fetch_2998af8c54e0997c: function(arg0, arg1) {
            const ret = getObject(arg0).fetch(getObject(arg1));
            return addHeapObject(ret);
        },
        __wbg_fetch_fda7bc27c982b1f3: function(arg0) {
            const ret = fetch(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_from_fa561fa561dc8031: function(arg0) {
            const ret = Array.from(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_getRandomValues_ef8a9e8b447216e2: function() { return handleError(function (arg0, arg1) {
            globalThis.crypto.getRandomValues(getArrayU8FromWasm0(arg0, arg1));
        }, arguments); },
        __wbg_get_3e9a707ab7d352eb: function() { return handleError(function (arg0, arg1) {
            const ret = Reflect.get(getObject(arg0), getObject(arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_get_98fdf51d029a75eb: function(arg0, arg1) {
            const ret = getObject(arg0)[arg1 >>> 0];
            return addHeapObject(ret);
        },
        __wbg_get_dcf82ab8aad1a593: function() { return handleError(function (arg0, arg1) {
            const ret = Reflect.get(getObject(arg0), getObject(arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_has_ef192b1f278770eb: function() { return handleError(function (arg0, arg1) {
            const ret = Reflect.has(getObject(arg0), getObject(arg1));
            return ret;
        }, arguments); },
        __wbg_headers_18f39f24d3837dc1: function(arg0) {
            const ret = getObject(arg0).headers;
            return addHeapObject(ret);
        },
        __wbg_instanceof_ArrayBuffer_53db37b06f6b9afe: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof ArrayBuffer;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_Error_b3f7e146d654031a: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof Error;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_Object_03924e0dbda74bd8: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof Object;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_Response_ecfc823e8fb354e2: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof Response;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_isArray_94898ed3aad6947b: function(arg0) {
            const ret = Array.isArray(getObject(arg0));
            return ret;
        },
        __wbg_iterator_1441b47f341dc34f: function() {
            const ret = Symbol.iterator;
            return addHeapObject(ret);
        },
        __wbg_keys_682010b680c9b1f8: function(arg0) {
            const ret = Object.keys(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_length_2591a0f4f659a55c: function(arg0) {
            const ret = getObject(arg0).length;
            return ret;
        },
        __wbg_length_56fcd3e2b7e0299d: function(arg0) {
            const ret = getObject(arg0).length;
            return ret;
        },
        __wbg_message_324ac511aeaf710e: function(arg0) {
            const ret = getObject(arg0).message;
            return addHeapObject(ret);
        },
        __wbg_name_d09e9b472d8320d3: function(arg0) {
            const ret = getObject(arg0).name;
            return addHeapObject(ret);
        },
        __wbg_new_02d162bc6cf02f60: function() {
            const ret = new Object();
            return addHeapObject(ret);
        },
        __wbg_new_227d7c05414eb861: function() {
            const ret = new Error();
            return addHeapObject(ret);
        },
        __wbg_new_310879b66b6e95e1: function() {
            const ret = new Array();
            return addHeapObject(ret);
        },
        __wbg_new_7ddec6de44ff8f5d: function(arg0) {
            const ret = new Uint8Array(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_new_af86d8f14640f1f3: function() { return handleError(function () {
            const ret = new AbortController();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_b1280f836646084c: function() { return handleError(function (arg0, arg1) {
            const ret = new WebSocket(getStringFromWasm0(arg0, arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_ee0be486d8f01282: function() { return handleError(function () {
            const ret = new Headers();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_from_slice_269e35316ed2d061: function(arg0, arg1) {
            const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
            return addHeapObject(ret);
        },
        __wbg_new_typed_c072c4ce9a2a0cdf: function(arg0, arg1) {
            try {
                var state0 = {a: arg0, b: arg1};
                var cb0 = (arg0, arg1) => {
                    const a = state0.a;
                    state0.a = 0;
                    try {
                        return __wasm_bindgen_func_elem_3063(a, state0.b, arg0, arg1);
                    } finally {
                        state0.a = a;
                    }
                };
                const ret = new Promise(cb0);
                return addHeapObject(ret);
            } finally {
                state0.a = 0;
            }
        },
        __wbg_new_with_event_init_dict_6e3c4558031bcc74: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = new CloseEvent(getStringFromWasm0(arg0, arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_with_event_source_init_dict_b9ea67d613b2ba60: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = new EventSource(getStringFromWasm0(arg0, arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_with_str_138892eed4310532: function() { return handleError(function (arg0, arg1, arg2, arg3) {
            const ret = new WebSocket(getStringFromWasm0(arg0, arg1), getStringFromWasm0(arg2, arg3));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_with_str_and_init_ffe9977c986ea039: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = new Request(getStringFromWasm0(arg0, arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_with_u8_array_sequence_13bd79c99f2fc3b0: function() { return handleError(function (arg0) {
            const ret = new Blob(getObject(arg0));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_next_2a4e19f4f5083b0f: function(arg0) {
            const ret = getObject(arg0).next;
            return addHeapObject(ret);
        },
        __wbg_next_6429a146bf756f93: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).next();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_now_81363d44c96dd239: function() {
            const ret = Date.now();
            return ret;
        },
        __wbg_of_d694dacacb7afa7f: function(arg0) {
            const ret = Array.of(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_prototypesetcall_5f9bdc8d75e07276: function(arg0, arg1, arg2) {
            Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), getObject(arg2));
        },
        __wbg_push_b77c476b01548d0a: function(arg0, arg1) {
            const ret = getObject(arg0).push(getObject(arg1));
            return ret;
        },
        __wbg_queueMicrotask_78d584b53af520f5: function(arg0) {
            const ret = getObject(arg0).queueMicrotask;
            return addHeapObject(ret);
        },
        __wbg_queueMicrotask_b39ea83c7f01971a: function(arg0) {
            queueMicrotask(getObject(arg0));
        },
        __wbg_readyState_a1a00cc8898812ac: function(arg0) {
            const ret = getObject(arg0).readyState;
            return ret;
        },
        __wbg_reason_48e6f2ed86d09534: function(arg0, arg1) {
            const ret = getObject(arg1).reason;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_removeEventListener_3d948197bcd2a229: function() { return handleError(function (arg0, arg1, arg2, arg3) {
            getObject(arg0).removeEventListener(getStringFromWasm0(arg1, arg2), getObject(arg3));
        }, arguments); },
        __wbg_resolve_d17db9352f5a220e: function(arg0) {
            const ret = Promise.resolve(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_send_c79e8d29e09cc7b4: function() { return handleError(function (arg0, arg1) {
            getObject(arg0).send(getObject(arg1));
        }, arguments); },
        __wbg_send_e1d2f71ce4473d1e: function() { return handleError(function (arg0, arg1, arg2) {
            getObject(arg0).send(getStringFromWasm0(arg1, arg2));
        }, arguments); },
        __wbg_set_a0e911be3da02782: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = Reflect.set(getObject(arg0), getObject(arg1), getObject(arg2));
            return ret;
        }, arguments); },
        __wbg_set_binaryType_5c0002dfcf194934: function(arg0, arg1) {
            getObject(arg0).binaryType = __wbindgen_enum_BinaryType[arg1];
        },
        __wbg_set_body_7f56457720e81672: function(arg0, arg1) {
            getObject(arg0).body = getObject(arg1);
        },
        __wbg_set_code_a4411690b706ca41: function(arg0, arg1) {
            getObject(arg0).code = arg1;
        },
        __wbg_set_credentials_55b92faec8dcc6a4: function(arg0, arg1) {
            getObject(arg0).credentials = __wbindgen_enum_RequestCredentials[arg1];
        },
        __wbg_set_headers_97ed66619adb1e3e: function(arg0, arg1) {
            getObject(arg0).headers = getObject(arg1);
        },
        __wbg_set_method_4d69a1a7e34c0aca: function(arg0, arg1, arg2) {
            getObject(arg0).method = getStringFromWasm0(arg1, arg2);
        },
        __wbg_set_mode_dfc59bbbe25b1d14: function(arg0, arg1) {
            getObject(arg0).mode = __wbindgen_enum_RequestMode[arg1];
        },
        __wbg_set_once_1f7d97545d570128: function(arg0, arg1) {
            getObject(arg0).once = arg1 !== 0;
        },
        __wbg_set_reason_5270e60cd15986eb: function(arg0, arg1, arg2) {
            getObject(arg0).reason = getStringFromWasm0(arg1, arg2);
        },
        __wbg_set_signal_2a5bd3615938edbc: function(arg0, arg1) {
            getObject(arg0).signal = getObject(arg1);
        },
        __wbg_set_with_credentials_6816efbf91c8d8f8: function(arg0, arg1) {
            getObject(arg0).withCredentials = arg1 !== 0;
        },
        __wbg_signal_304beac95c8c5ea0: function(arg0) {
            const ret = getObject(arg0).signal;
            return addHeapObject(ret);
        },
        __wbg_stack_3b0d974bbf31e44f: function(arg0, arg1) {
            const ret = getObject(arg1).stack;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_static_accessor_GLOBAL_THIS_02344c9b09eb08a9: function() {
            const ret = typeof globalThis === 'undefined' ? null : globalThis;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_GLOBAL_ac6d4ac874d5cd54: function() {
            const ret = typeof global === 'undefined' ? null : global;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_SELF_9b2406c23aeb2023: function() {
            const ret = typeof self === 'undefined' ? null : self;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_WINDOW_b34d2126934e16ba: function() {
            const ret = typeof window === 'undefined' ? null : window;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_status_0853c9f5752c7ee2: function(arg0) {
            const ret = getObject(arg0).status;
            return ret;
        },
        __wbg_stringify_ef0c105b1ccc3849: function() { return handleError(function (arg0) {
            const ret = JSON.stringify(getObject(arg0));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_text_99930d92d5f1b540: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).text();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_then_837494e384b37459: function(arg0, arg1) {
            const ret = getObject(arg0).then(getObject(arg1));
            return addHeapObject(ret);
        },
        __wbg_then_bd927500e8905df2: function(arg0, arg1, arg2) {
            const ret = getObject(arg0).then(getObject(arg1), getObject(arg2));
            return addHeapObject(ret);
        },
        __wbg_toString_a5ee42947b978082: function(arg0) {
            const ret = getObject(arg0).toString();
            return addHeapObject(ret);
        },
        __wbg_url_1a5ea6a8a7f22ff8: function(arg0, arg1) {
            const ret = getObject(arg1).url;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_uspwsclient_new: function(arg0) {
            const ret = UspWsClient.__wrap(arg0);
            return addHeapObject(ret);
        },
        __wbg_value_9cc0518af87a489c: function(arg0) {
            const ret = getObject(arg0).value;
            return addHeapObject(ret);
        },
        __wbg_wasClean_aa6a78fa841a6301: function(arg0) {
            const ret = getObject(arg0).wasClean;
            return ret;
        },
        __wbindgen_cast_0000000000000001: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [Externref], shim_idx: 268, ret: Result(Unit), inner_ret: Some(Result(Unit)) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, __wasm_bindgen_func_elem_3061);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000002: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [NamedExternref("CloseEvent")], shim_idx: 247, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, __wasm_bindgen_func_elem_2386);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000003: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [NamedExternref("Event")], shim_idx: 247, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, __wasm_bindgen_func_elem_2386_2);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000004: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [NamedExternref("MessageEvent")], shim_idx: 247, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, __wasm_bindgen_func_elem_2386_3);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000005: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [], shim_idx: 246, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, __wasm_bindgen_func_elem_2385);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000006: function(arg0) {
            // Cast intrinsic for `F64 -> Externref`.
            const ret = arg0;
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000007: function(arg0, arg1) {
            // Cast intrinsic for `Ref(String) -> Externref`.
            const ret = getStringFromWasm0(arg0, arg1);
            return addHeapObject(ret);
        },
        __wbindgen_object_clone_ref: function(arg0) {
            const ret = getObject(arg0);
            return addHeapObject(ret);
        },
        __wbindgen_object_drop_ref: function(arg0) {
            takeObject(arg0);
        },
    };
    return {
        __proto__: null,
        "./usp_client_bg.js": import0,
    };
}

function __wasm_bindgen_func_elem_2385(arg0, arg1) {
    wasm.__wasm_bindgen_func_elem_2385(arg0, arg1);
}

function __wasm_bindgen_func_elem_2386(arg0, arg1, arg2) {
    wasm.__wasm_bindgen_func_elem_2386(arg0, arg1, addHeapObject(arg2));
}

function __wasm_bindgen_func_elem_2386_2(arg0, arg1, arg2) {
    wasm.__wasm_bindgen_func_elem_2386_2(arg0, arg1, addHeapObject(arg2));
}

function __wasm_bindgen_func_elem_2386_3(arg0, arg1, arg2) {
    wasm.__wasm_bindgen_func_elem_2386_3(arg0, arg1, addHeapObject(arg2));
}

function __wasm_bindgen_func_elem_3061(arg0, arg1, arg2) {
    try {
        const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
        wasm.__wasm_bindgen_func_elem_3061(retptr, arg0, arg1, addHeapObject(arg2));
        var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
        var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
        if (r1) {
            throw takeObject(r0);
        }
    } finally {
        wasm.__wbindgen_add_to_stack_pointer(16);
    }
}

function __wasm_bindgen_func_elem_3063(arg0, arg1, arg2, arg3) {
    wasm.__wasm_bindgen_func_elem_3063(arg0, arg1, addHeapObject(arg2), addHeapObject(arg3));
}


const __wbindgen_enum_BinaryType = ["blob", "arraybuffer"];


const __wbindgen_enum_RequestCredentials = ["omit", "same-origin", "include"];


const __wbindgen_enum_RequestMode = ["same-origin", "no-cors", "cors", "navigate"];
const UspClientFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_uspclient_free(ptr, 1));
const UspClientBuilderFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_uspclientbuilder_free(ptr, 1));
const UspWsClientFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_uspwsclient_free(ptr, 1));

function addHeapObject(obj) {
    if (heap_next === heap.length) heap.push(heap.length + 1);
    const idx = heap_next;
    heap_next = heap[idx];

    heap[idx] = obj;
    return idx;
}

const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(state => wasm.__wbindgen_export5(state.a, state.b));

function debugString(val) {
    // primitive types
    const type = typeof val;
    if (type == 'number' || type == 'boolean' || val == null) {
        return  `${val}`;
    }
    if (type == 'string') {
        return `"${val}"`;
    }
    if (type == 'symbol') {
        const description = val.description;
        if (description == null) {
            return 'Symbol';
        } else {
            return `Symbol(${description})`;
        }
    }
    if (type == 'function') {
        const name = val.name;
        if (typeof name == 'string' && name.length > 0) {
            return `Function(${name})`;
        } else {
            return 'Function';
        }
    }
    // objects
    if (Array.isArray(val)) {
        const length = val.length;
        let debug = '[';
        if (length > 0) {
            debug += debugString(val[0]);
        }
        for(let i = 1; i < length; i++) {
            debug += ', ' + debugString(val[i]);
        }
        debug += ']';
        return debug;
    }
    // Test for built-in
    const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
    let className;
    if (builtInMatches && builtInMatches.length > 1) {
        className = builtInMatches[1];
    } else {
        // Failed to match the standard '[object ClassName]'
        return toString.call(val);
    }
    if (className == 'Object') {
        // we're a user defined class or Object
        // JSON.stringify avoids problems with cycles, and is generally much
        // easier than looping through ownProperties of `val`.
        try {
            return 'Object(' + JSON.stringify(val) + ')';
        } catch (_) {
            return 'Object';
        }
    }
    // errors
    if (val instanceof Error) {
        return `${val.name}: ${val.message}\n${val.stack}`;
    }
    // TODO we could test for more things here, like `Set`s and `Map`s.
    return className;
}

function dropObject(idx) {
    if (idx < 1028) return;
    heap[idx] = heap_next;
    heap_next = idx;
}

function getArrayU8FromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
}

let cachedDataViewMemory0 = null;
function getDataViewMemory0() {
    if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || (cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer)) {
        cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
    }
    return cachedDataViewMemory0;
}

function getStringFromWasm0(ptr, len) {
    return decodeText(ptr >>> 0, len);
}

let cachedUint8ArrayMemory0 = null;
function getUint8ArrayMemory0() {
    if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
        cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
    }
    return cachedUint8ArrayMemory0;
}

function getObject(idx) { return heap[idx]; }

function handleError(f, args) {
    try {
        return f.apply(this, args);
    } catch (e) {
        wasm.__wbindgen_export3(addHeapObject(e));
    }
}

let heap = new Array(1024).fill(undefined);
heap.push(undefined, null, true, false);

let heap_next = heap.length;

function isLikeNone(x) {
    return x === undefined || x === null;
}

function makeMutClosure(arg0, arg1, f) {
    const state = { a: arg0, b: arg1, cnt: 1 };
    const real = (...args) => {

        // First up with a closure we increment the internal reference
        // count. This ensures that the Rust closure environment won't
        // be deallocated while we're invoking it.
        state.cnt++;
        const a = state.a;
        state.a = 0;
        try {
            return f(a, state.b, ...args);
        } finally {
            state.a = a;
            real._wbg_cb_unref();
        }
    };
    real._wbg_cb_unref = () => {
        if (--state.cnt === 0) {
            wasm.__wbindgen_export5(state.a, state.b);
            state.a = 0;
            CLOSURE_DTORS.unregister(state);
        }
    };
    CLOSURE_DTORS.register(real, state, state);
    return real;
}

function passArray8ToWasm0(arg, malloc) {
    const ptr = malloc(arg.length * 1, 1) >>> 0;
    getUint8ArrayMemory0().set(arg, ptr / 1);
    WASM_VECTOR_LEN = arg.length;
    return ptr;
}

function passStringToWasm0(arg, malloc, realloc) {
    if (realloc === undefined) {
        const buf = cachedTextEncoder.encode(arg);
        const ptr = malloc(buf.length, 1) >>> 0;
        getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
        WASM_VECTOR_LEN = buf.length;
        return ptr;
    }

    let len = arg.length;
    let ptr = malloc(len, 1) >>> 0;

    const mem = getUint8ArrayMemory0();

    let offset = 0;

    for (; offset < len; offset++) {
        const code = arg.charCodeAt(offset);
        if (code > 0x7F) break;
        mem[ptr + offset] = code;
    }
    if (offset !== len) {
        if (offset !== 0) {
            arg = arg.slice(offset);
        }
        ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
        const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
        const ret = cachedTextEncoder.encodeInto(arg, view);

        offset += ret.written;
        ptr = realloc(ptr, len, offset, 1) >>> 0;
    }

    WASM_VECTOR_LEN = offset;
    return ptr;
}

function takeObject(idx) {
    const ret = getObject(idx);
    dropObject(idx);
    return ret;
}

let cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
cachedTextDecoder.decode();
const MAX_SAFARI_DECODE_BYTES = 2146435072;
let numBytesDecoded = 0;
function decodeText(ptr, len) {
    numBytesDecoded += len;
    if (numBytesDecoded >= MAX_SAFARI_DECODE_BYTES) {
        cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
        cachedTextDecoder.decode();
        numBytesDecoded = len;
    }
    return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
}

const cachedTextEncoder = new TextEncoder();

if (!('encodeInto' in cachedTextEncoder)) {
    cachedTextEncoder.encodeInto = function (arg, view) {
        const buf = cachedTextEncoder.encode(arg);
        view.set(buf);
        return {
            read: arg.length,
            written: buf.length
        };
    };
}

let WASM_VECTOR_LEN = 0;

let wasmModule, wasmInstance, wasm;
function __wbg_finalize_init(instance, module) {
    wasmInstance = instance;
    wasm = instance.exports;
    wasmModule = module;
    cachedDataViewMemory0 = null;
    cachedUint8ArrayMemory0 = null;
    wasm.__wbindgen_start();
    return wasm;
}

async function __wbg_load(module, imports) {
    if (typeof Response === 'function' && module instanceof Response) {
        if (typeof WebAssembly.instantiateStreaming === 'function') {
            try {
                return await WebAssembly.instantiateStreaming(module, imports);
            } catch (e) {
                const validResponse = module.ok && expectedResponseType(module.type);

                if (validResponse && module.headers.get('Content-Type') !== 'application/wasm') {
                    console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                } else { throw e; }
            }
        }

        const bytes = await module.arrayBuffer();
        return await WebAssembly.instantiate(bytes, imports);
    } else {
        const instance = await WebAssembly.instantiate(module, imports);

        if (instance instanceof WebAssembly.Instance) {
            return { instance, module };
        } else {
            return instance;
        }
    }

    function expectedResponseType(type) {
        switch (type) {
            case 'basic': case 'cors': case 'default': return true;
        }
        return false;
    }
}

function initSync(module) {
    if (wasm !== undefined) return wasm;


    if (module !== undefined) {
        if (Object.getPrototypeOf(module) === Object.prototype) {
            ({module} = module)
        } else {
            console.warn('using deprecated parameters for `initSync()`; pass a single object instead')
        }
    }

    const imports = __wbg_get_imports();
    if (!(module instanceof WebAssembly.Module)) {
        module = new WebAssembly.Module(module);
    }
    const instance = new WebAssembly.Instance(module, imports);
    return __wbg_finalize_init(instance, module);
}

async function __wbg_init(module_or_path) {
    if (wasm !== undefined) return wasm;


    if (module_or_path !== undefined) {
        if (Object.getPrototypeOf(module_or_path) === Object.prototype) {
            ({module_or_path} = module_or_path)
        } else {
            console.warn('using deprecated parameters for the initialization function; pass a single object instead')
        }
    }

    if (module_or_path === undefined) {
        module_or_path = new URL('usp_client_bg.wasm', import.meta.url);
    }
    const imports = __wbg_get_imports();

    if (typeof module_or_path === 'string' || (typeof Request === 'function' && module_or_path instanceof Request) || (typeof URL === 'function' && module_or_path instanceof URL)) {
        module_or_path = fetch(module_or_path);
    }

    const { instance, module } = await __wbg_load(await module_or_path, imports);

    return __wbg_finalize_init(instance, module);
}

export { initSync, __wbg_init as default };
