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
            this.__wbg_ptr = r0 >>> 0;
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
     * Refreshes the authentication token before expiration
     *
     * # Returns
     * * Promise that resolves on success, rejects on error
     * @returns {Promise<any>}
     */
    refreshToken() {
        const ret = wasm.uspclient_refreshToken(this.__wbg_ptr);
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
        __wbg___wbindgen_boolean_get_bbbb1c18aa2f5e25: function(arg0) {
            const v = getObject(arg0);
            const ret = typeof(v) === 'boolean' ? v : undefined;
            return isLikeNone(ret) ? 0xFFFFFF : ret ? 1 : 0;
        },
        __wbg___wbindgen_debug_string_0bc8482c6e3508ae: function(arg0, arg1) {
            const ret = debugString(getObject(arg1));
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg___wbindgen_is_function_0095a73b8b156f76: function(arg0) {
            const ret = typeof(getObject(arg0)) === 'function';
            return ret;
        },
        __wbg___wbindgen_is_null_ac34f5003991759a: function(arg0) {
            const ret = getObject(arg0) === null;
            return ret;
        },
        __wbg___wbindgen_is_object_5ae8e5880f2c1fbd: function(arg0) {
            const val = getObject(arg0);
            const ret = typeof(val) === 'object' && val !== null;
            return ret;
        },
        __wbg___wbindgen_is_string_cd444516edc5b180: function(arg0) {
            const ret = typeof(getObject(arg0)) === 'string';
            return ret;
        },
        __wbg___wbindgen_is_undefined_9e4d92534c42d778: function(arg0) {
            const ret = getObject(arg0) === undefined;
            return ret;
        },
        __wbg___wbindgen_string_get_72fb696202c56729: function(arg0, arg1) {
            const obj = getObject(arg1);
            const ret = typeof(obj) === 'string' ? obj : undefined;
            var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            var len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg___wbindgen_throw_be289d5034ed271b: function(arg0, arg1) {
            throw new Error(getStringFromWasm0(arg0, arg1));
        },
        __wbg__wbg_cb_unref_d9b87ff7982e3b21: function(arg0) {
            getObject(arg0)._wbg_cb_unref();
        },
        __wbg_abort_2f0584e03e8e3950: function(arg0) {
            getObject(arg0).abort();
        },
        __wbg_append_a992ccc37aa62dc4: function() { return handleError(function (arg0, arg1, arg2, arg3, arg4) {
            getObject(arg0).append(getStringFromWasm0(arg1, arg2), getStringFromWasm0(arg3, arg4));
        }, arguments); },
        __wbg_arrayBuffer_bb54076166006c39: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).arrayBuffer();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_call_389efe28435a9388: function() { return handleError(function (arg0, arg1) {
            const ret = getObject(arg0).call(getObject(arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_call_4708e0c13bdc8e95: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = getObject(arg0).call(getObject(arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_done_57b39ecd9addfe81: function(arg0) {
            const ret = getObject(arg0).done;
            return ret;
        },
        __wbg_error_7534b8e9a36f1ab4: function(arg0, arg1) {
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
        __wbg_fetch_afb6a4b6cacf876d: function(arg0, arg1) {
            const ret = getObject(arg0).fetch(getObject(arg1));
            return addHeapObject(ret);
        },
        __wbg_fetch_f1856afdb49415d1: function(arg0) {
            const ret = fetch(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_from_bddd64e7d5ff6941: function(arg0) {
            const ret = Array.from(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_getRandomValues_9c5c1b115e142bb8: function() { return handleError(function (arg0, arg1) {
            globalThis.crypto.getRandomValues(getArrayU8FromWasm0(arg0, arg1));
        }, arguments); },
        __wbg_get_9b94d73e6221f75c: function(arg0, arg1) {
            const ret = getObject(arg0)[arg1 >>> 0];
            return addHeapObject(ret);
        },
        __wbg_get_b3ed3ad4be2bc8ac: function() { return handleError(function (arg0, arg1) {
            const ret = Reflect.get(getObject(arg0), getObject(arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_has_d4e53238966c12b6: function() { return handleError(function (arg0, arg1) {
            const ret = Reflect.has(getObject(arg0), getObject(arg1));
            return ret;
        }, arguments); },
        __wbg_headers_59a2938db9f80985: function(arg0) {
            const ret = getObject(arg0).headers;
            return addHeapObject(ret);
        },
        __wbg_instanceof_Object_1c6af87502b733ed: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof Object;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_Response_ee1d54d79ae41977: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof Response;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_isArray_d314bb98fcf08331: function(arg0) {
            const ret = Array.isArray(getObject(arg0));
            return ret;
        },
        __wbg_iterator_6ff6560ca1568e55: function() {
            const ret = Symbol.iterator;
            return addHeapObject(ret);
        },
        __wbg_keys_b50a709a76add04e: function(arg0) {
            const ret = Object.keys(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_length_32ed9a279acd054c: function(arg0) {
            const ret = getObject(arg0).length;
            return ret;
        },
        __wbg_length_35a7bace40f36eac: function(arg0) {
            const ret = getObject(arg0).length;
            return ret;
        },
        __wbg_new_361308b2356cecd0: function() {
            const ret = new Object();
            return addHeapObject(ret);
        },
        __wbg_new_3eb36ae241fe6f44: function() {
            const ret = new Array();
            return addHeapObject(ret);
        },
        __wbg_new_64284bd487f9d239: function() { return handleError(function () {
            const ret = new Headers();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_8a6f238a6ece86ea: function() {
            const ret = new Error();
            return addHeapObject(ret);
        },
        __wbg_new_b5d9e2fb389fef91: function(arg0, arg1) {
            try {
                var state0 = {a: arg0, b: arg1};
                var cb0 = (arg0, arg1) => {
                    const a = state0.a;
                    state0.a = 0;
                    try {
                        return __wasm_bindgen_func_elem_2218(a, state0.b, arg0, arg1);
                    } finally {
                        state0.a = a;
                    }
                };
                const ret = new Promise(cb0);
                return addHeapObject(ret);
            } finally {
                state0.a = state0.b = 0;
            }
        },
        __wbg_new_b949e7f56150a5d1: function() { return handleError(function () {
            const ret = new AbortController();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_dd2b680c8bf6ae29: function(arg0) {
            const ret = new Uint8Array(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_new_from_slice_a3d2629dc1826784: function(arg0, arg1) {
            const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
            return addHeapObject(ret);
        },
        __wbg_new_no_args_1c7c842f08d00ebb: function(arg0, arg1) {
            const ret = new Function(getStringFromWasm0(arg0, arg1));
            return addHeapObject(ret);
        },
        __wbg_new_with_event_source_init_dict_534a8e0be92bef3c: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = new EventSource(getStringFromWasm0(arg0, arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_with_str_and_init_a61cbc6bdef21614: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = new Request(getStringFromWasm0(arg0, arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_next_3482f54c49e8af19: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).next();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_next_418f80d8f5303233: function(arg0) {
            const ret = getObject(arg0).next;
            return addHeapObject(ret);
        },
        __wbg_now_a3af9a2f4bbaa4d1: function() {
            const ret = Date.now();
            return ret;
        },
        __wbg_prototypesetcall_bdcdcc5842e4d77d: function(arg0, arg1, arg2) {
            Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), getObject(arg2));
        },
        __wbg_push_8ffdcb2063340ba5: function(arg0, arg1) {
            const ret = getObject(arg0).push(getObject(arg1));
            return ret;
        },
        __wbg_queueMicrotask_0aa0a927f78f5d98: function(arg0) {
            const ret = getObject(arg0).queueMicrotask;
            return addHeapObject(ret);
        },
        __wbg_queueMicrotask_5bb536982f78a56f: function(arg0) {
            queueMicrotask(getObject(arg0));
        },
        __wbg_resolve_002c4b7d9d8f6b64: function(arg0) {
            const ret = Promise.resolve(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_set_6cb8631f80447a67: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = Reflect.set(getObject(arg0), getObject(arg1), getObject(arg2));
            return ret;
        }, arguments); },
        __wbg_set_body_9a7e00afe3cfe244: function(arg0, arg1) {
            getObject(arg0).body = getObject(arg1);
        },
        __wbg_set_credentials_c4a58d2e05ef24fb: function(arg0, arg1) {
            getObject(arg0).credentials = __wbindgen_enum_RequestCredentials[arg1];
        },
        __wbg_set_headers_cfc5f4b2c1f20549: function(arg0, arg1) {
            getObject(arg0).headers = getObject(arg1);
        },
        __wbg_set_method_c3e20375f5ae7fac: function(arg0, arg1, arg2) {
            getObject(arg0).method = getStringFromWasm0(arg1, arg2);
        },
        __wbg_set_mode_b13642c312648202: function(arg0, arg1) {
            getObject(arg0).mode = __wbindgen_enum_RequestMode[arg1];
        },
        __wbg_set_signal_f2d3f8599248896d: function(arg0, arg1) {
            getObject(arg0).signal = getObject(arg1);
        },
        __wbg_set_with_credentials_077b2ededd8e5d55: function(arg0, arg1) {
            getObject(arg0).withCredentials = arg1 !== 0;
        },
        __wbg_signal_d1285ecab4ebc5ad: function(arg0) {
            const ret = getObject(arg0).signal;
            return addHeapObject(ret);
        },
        __wbg_stack_0ed75d68575b0f3c: function(arg0, arg1) {
            const ret = getObject(arg1).stack;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_static_accessor_GLOBAL_12837167ad935116: function() {
            const ret = typeof global === 'undefined' ? null : global;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_GLOBAL_THIS_e628e89ab3b1c95f: function() {
            const ret = typeof globalThis === 'undefined' ? null : globalThis;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_SELF_a621d3dfbb60d0ce: function() {
            const ret = typeof self === 'undefined' ? null : self;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_WINDOW_f8727f0cf888e0bd: function() {
            const ret = typeof window === 'undefined' ? null : window;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_status_89d7e803db911ee7: function(arg0) {
            const ret = getObject(arg0).status;
            return ret;
        },
        __wbg_stringify_8d1cc6ff383e8bae: function() { return handleError(function (arg0) {
            const ret = JSON.stringify(getObject(arg0));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_text_083b8727c990c8c0: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).text();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_then_0d9fe2c7b1857d32: function(arg0, arg1, arg2) {
            const ret = getObject(arg0).then(getObject(arg1), getObject(arg2));
            return addHeapObject(ret);
        },
        __wbg_then_b9e7b3b5f1a9e1b5: function(arg0, arg1) {
            const ret = getObject(arg0).then(getObject(arg1));
            return addHeapObject(ret);
        },
        __wbg_url_c484c26b1fbf5126: function(arg0, arg1) {
            const ret = getObject(arg1).url;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_value_0546255b415e96c1: function(arg0) {
            const ret = getObject(arg0).value;
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000001: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { dtor_idx: 143, function: Function { arguments: [Externref], shim_idx: 144, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_1354, __wasm_bindgen_func_elem_1369);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000002: function(arg0) {
            // Cast intrinsic for `F64 -> Externref`.
            const ret = arg0;
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000003: function(arg0, arg1) {
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
        __wbindgen_object_is_undefined: function(arg0) {
            const ret = getObject(arg0) === undefined;
            return ret;
        },
    };
    return {
        __proto__: null,
        "./usp_client_bg.js": import0,
    };
}

function __wasm_bindgen_func_elem_1369(arg0, arg1, arg2) {
    wasm.__wasm_bindgen_func_elem_1369(arg0, arg1, addHeapObject(arg2));
}

function __wasm_bindgen_func_elem_2218(arg0, arg1, arg2, arg3) {
    wasm.__wasm_bindgen_func_elem_2218(arg0, arg1, addHeapObject(arg2), addHeapObject(arg3));
}


const __wbindgen_enum_RequestCredentials = ["omit", "same-origin", "include"];


const __wbindgen_enum_RequestMode = ["same-origin", "no-cors", "cors", "navigate"];
const UspClientFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_uspclient_free(ptr >>> 0, 1));

function addHeapObject(obj) {
    if (heap_next === heap.length) heap.push(heap.length + 1);
    const idx = heap_next;
    heap_next = heap[idx];

    heap[idx] = obj;
    return idx;
}

const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(state => state.dtor(state.a, state.b));

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
    if (idx < 132) return;
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
    ptr = ptr >>> 0;
    return decodeText(ptr, len);
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

let heap = new Array(128).fill(undefined);
heap.push(undefined, null, true, false);

let heap_next = heap.length;

function isLikeNone(x) {
    return x === undefined || x === null;
}

function makeMutClosure(arg0, arg1, dtor, f) {
    const state = { a: arg0, b: arg1, cnt: 1, dtor };
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
            state.dtor(state.a, state.b);
            state.a = 0;
            CLOSURE_DTORS.unregister(state);
        }
    };
    CLOSURE_DTORS.register(real, state, state);
    return real;
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

let wasmModule, wasm;
function __wbg_finalize_init(instance, module) {
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
