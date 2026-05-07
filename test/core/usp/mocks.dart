import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';

class MockUspBridgeClient extends Mock implements UspBridgeClient {}

class MockUspClient extends Mock implements UspClient {}

class MockSseManager extends Mock implements SseManager {}
