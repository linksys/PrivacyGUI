// Bootstrap the USP WASM client.
// This is a regular (non-module) script so it executes synchronously,
// but the actual WASM loading is async. The resulting Promise is stored
// on window.__uspClientReady so Dart code can await it before using UspClient.
window.__uspClientReady = (async function () {
  try {
    const module = await import('./usp_client.js');
    await module.default(); // init() — loads and instantiates the WASM binary
    window.UspClient = module.UspClient;
    // WebSocket client and record builders for firmware upload (Method 2)
    window.UspWsClient = module.UspWsClient;
    window.buildGetRecord = module.buildGetRecord;
    window.buildOperateRecord = module.buildOperateRecord;
    window.buildWebSocketConnect = module.buildWebSocketConnect;
    window.decodeRecord = module.decodeRecord;

    // Helper: Copy WASM Uint8Array to JS heap to avoid memory detach issues
    // WASM memory can grow during malloc, detaching previous ArrayBuffer views
    function copyToJsHeap(wasmBytes) {
      const copy = new Uint8Array(wasmBytes.length);
      copy.set(wasmBytes);
      return copy;
    }

    // Helper: Send WebSocketConnect using native JS (bypasses Dart interop issues)
    window.sendWebSocketConnectNative = async function(wsClient, fromId, toId) {
      const bytes = module.buildWebSocketConnect(fromId, toId);
      const copy = copyToJsHeap(bytes);
      const clean = new Uint8Array(copy);
      console.log('[USPWsClient] WS-CONNECT sending', clean.length, 'bytes');
      await wsClient.sendRecord(clean);
    };

    // Helper: Send Operate record using native JS
    window.sendOperateRecordNative = async function(wsClient, command, inputArgs, fromId, toId) {
      const bytes = module.buildOperateRecord(command, inputArgs, fromId, toId);
      const copy = copyToJsHeap(bytes);
      const clean = new Uint8Array(copy);
      console.log('[USPWsClient] OPERATE sending', clean.length, 'bytes for', command);
      await wsClient.sendRecord(clean);
    };

    console.log('USP WASM client initialized');
    return true;
  } catch (e) {
    console.warn('USP WASM client init failed:', e);
    return false;
  }
})();
