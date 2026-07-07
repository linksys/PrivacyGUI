/// Stub for dart:html on non-web platforms.
///
/// Provides no-op implementations so the code compiles on mobile/desktop.

class _Window {
  final _SessionStorage sessionStorage = _SessionStorage();
  final _History history = _History();
}

class _SessionStorage {
  String? operator [](String key) => null;
  void operator []=(String key, String value) {}
  void remove(String key) {}
}

class _History {
  void replaceState(dynamic data, String title, String? url) {}
}

final window = _Window();
