/// Platform-agnostic entry point for UspClientBuilderJS.
///
/// On Web: exports the real JS binding from usp_client_wasm.dart
/// On VM/tests: exports a stub that throws UnsupportedError
export '../stub/usp_client_builder_stub.dart'
    if (dart.library.js_interop) 'usp_client_builder_web.dart';
