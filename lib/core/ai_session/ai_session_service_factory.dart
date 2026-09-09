import 'ai_session_service.dart';

AiSessionService createAiSessionService() => const _DisabledAiSessionService();

class _DisabledAiSessionService implements AiSessionService {
  const _DisabledAiSessionService();

  @override
  Future<bool> bootstrap(String adminPassword) async => false;

  @override
  Future<void> logout() async {}

  @override
  void close() {}
}
