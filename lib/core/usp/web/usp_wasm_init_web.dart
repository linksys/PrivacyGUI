import 'dart:js_interop';

/// Promise stored by web/usp_init.js after WASM client finishes loading.
@JS('__uspClientReady')
external JSPromise<JSBoolean>? get _uspClientReady;

/// Awaits the WASM client initialization that was kicked off by usp_init.js.
/// Must be called (and awaited) before constructing [UspClientWeb] / [UspClient].
Future<bool> ensureUspWasmInitialized() async {
  final promise = _uspClientReady;
  if (promise == null) return false;
  final result = await promise.toDart;
  return result.toDart;
}
