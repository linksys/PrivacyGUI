import 'usp_token_storage.dart';

/// Creates a stub token storage for non-Web platforms (VM/tests).
UspTokenStorage createUspTokenStorage() => _StubTokenStorageImpl();

class _StubTokenStorageImpl implements UspTokenStorage {
  @override
  void save(String token) {}

  @override
  String? load() => null;

  @override
  void clear() {}
}
