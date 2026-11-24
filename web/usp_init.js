// Bootstrap the USP WASM client.
// This is a regular (non-module) script so it executes synchronously,
// but the actual WASM loading is async. The resulting Promise is stored
// on window.__uspClientReady so Dart code can await it before using UspClient.
window.__uspClientReady = (async function () {
  try {
    const module = await import('./usp_client.js');
    await module.default();
    window.UspClient = module.UspClient;
    window.UspClientBuilder = module.UspClientBuilder;

    console.log('USP WASM client initialized');
    return true;
  } catch (e) {
    console.warn('USP WASM client init failed:', e);
    return false;
  }
})();
