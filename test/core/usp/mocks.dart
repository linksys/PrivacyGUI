import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';

class MockUspBridgeClient extends Mock implements UspBridgeClient {}

class MockUspService extends Mock implements UspService {}

class MockSseManager extends Mock implements SseManager {}
