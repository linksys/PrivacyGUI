import 'package:flutter_test/flutter_test.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/ai/abstraction/_abstraction.dart';
import 'package:privacy_gui/ai/orchestrator/router_chat_controller.dart';

class MockConversationGenerator extends Mock
    implements IConversationGenerator {}

class MockRouterCommandProvider extends Mock
    implements IRouterCommandProvider {}

void main() {
  late MockConversationGenerator mockGenerator;
  late MockRouterCommandProvider mockCommandProvider;
  late RouterChatController controller;

  setUpAll(() {
    registerFallbackValue(<ChatMessage>[]);
    registerFallbackValue(<GenTool>[]);
    registerFallbackValue(<SystemPromptPart>[]);
  });

  setUp(() {
    mockGenerator = MockConversationGenerator();
    mockCommandProvider = MockRouterCommandProvider();

    when(() => mockCommandProvider.listCommands()).thenAnswer(
      (_) async => [
        const RouterCommand(
          name: 'getSystemInfo',
          description: 'Get system info',
          inputSchema: {'type': 'object', 'properties': {}},
          accessLevel: AccessLevel.read,
        ),
        const RouterCommand(
          name: 'setWifiPassword',
          description: 'Set WiFi password',
          inputSchema: {
            'type': 'object',
            'properties': {
              'password': {'type': 'string'},
            },
          },
          accessLevel: AccessLevel.write,
          requiresConfirmation: true,
        ),
      ],
    );

    controller = RouterChatController(
      generator: mockGenerator,
      commandProvider: mockCommandProvider,
      routerContext: '# Test Router Context\nModel: TestRouter',
    );
  });

  group('RouterChatController', () {
    group('initialization', () {
      test('starts with empty messages', () {
        expect(controller.messages, isEmpty);
      });

      test('starts with welcome view state', () {
        expect(controller.viewState, ChatViewState.welcome);
      });

      test('has no pending confirmation initially', () {
        expect(controller.hasPendingConfirmation, isFalse);
        expect(controller.pendingConfirmation, isNull);
      });

      test('is not loading initially', () {
        expect(controller.isLoading, isFalse);
      });

      test('has no error initially', () {
        expect(controller.hasError, isFalse);
        expect(controller.errorMessage, isNull);
      });
    });

    group('sendMessage', () {
      test('adds user message to conversation', () async {
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _textResponse('Hello!'));

        await controller.sendMessage('Hi');

        expect(controller.messages.length, greaterThanOrEqualTo(1));
        final userMessage =
            controller.messages.where((m) => m.role == ChatRole.user).first;
        expect(userMessage.content, 'Hi');
      });

      test('gets response from generator', () async {
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _textResponse('Hello there!'));

        await controller.sendMessage('Hi');

        final assistantMessages =
            controller.messages.where((m) => m.role == ChatRole.assistant);
        expect(assistantMessages, isNotEmpty);
      });

      test('handles read command tool use automatically', () async {
        // First response: LLM wants to use getSystemInfo tool
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((invocation) async {
          final messages =
              invocation.positionalArguments[0] as List<ChatMessage>;
          // If there's already a tool_result, return final response
          if (messages.any((m) => m.isToolResult)) {
            return _textResponse('Your router is MR7500.');
          }
          // Otherwise, request tool use
          return _toolUseResponse('getSystemInfo', {});
        });

        when(() => mockCommandProvider.execute('getSystemInfo', {}))
            .thenAnswer((_) async => RouterCommandResult.success({
                  'modelName': 'MR7500',
                }));

        await controller.sendMessage('What router do I have?');

        // Read command should be executed automatically (no confirmation needed)
        verify(() => mockCommandProvider.execute('getSystemInfo', {}))
            .called(1);
      });

      test('write command with confirmation creates pending confirmation',
          () async {
        when(() => mockGenerator.generateWithHistory(
                  any(),
                  tools: any(named: 'tools'),
                  systemPromptParts: any(named: 'systemPromptParts'),
                  forceToolUse: any(named: 'forceToolUse'),
                ))
            .thenAnswer((_) async => _toolUseResponse(
                'setWifiPassword', {'password': 'newpass123'}));

        await controller.sendMessage('Change my WiFi password');

        expect(controller.hasPendingConfirmation, isTrue);
        expect(controller.pendingConfirmation!.command.name, 'setWifiPassword');
        expect(
            controller.pendingConfirmation!.params['password'], 'newpass123');
      });
    });

    group('confirmation flow', () {
      setUp(() async {
        when(() => mockGenerator.generateWithHistory(
                  any(),
                  tools: any(named: 'tools'),
                  systemPromptParts: any(named: 'systemPromptParts'),
                  forceToolUse: any(named: 'forceToolUse'),
                ))
            .thenAnswer((_) async => _toolUseResponse(
                'setWifiPassword', {'password': 'newpass123'}));

        await controller.sendMessage('Change my WiFi password');
      });

      test('confirmPendingAction executes the command', () async {
        when(() => mockCommandProvider
                .execute('setWifiPassword', {'password': 'newpass123'}))
            .thenAnswer((_) async => RouterCommandResult.success({}));

        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _textResponse('Password changed!'));

        await controller.confirmPendingAction();

        verify(() => mockCommandProvider
            .execute('setWifiPassword', {'password': 'newpass123'})).called(1);
        expect(controller.hasPendingConfirmation, isFalse);
      });

      test('cancelPendingAction clears pending without executing', () async {
        when(() => mockGenerator.generateWithHistory(
                  any(),
                  tools: any(named: 'tools'),
                  systemPromptParts: any(named: 'systemPromptParts'),
                  forceToolUse: any(named: 'forceToolUse'),
                ))
            .thenAnswer((_) async =>
                _textResponse('OK, I won\'t change the password.'));

        await controller.cancelPendingAction();

        verifyNever(
            () => mockCommandProvider.execute('setWifiPassword', any()));
        expect(controller.hasPendingConfirmation, isFalse);
      });
    });

    group('clearConversation', () {
      test('resets all state', () async {
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _textResponse('Hello!'));

        await controller.sendMessage('Hi');
        expect(controller.messages, isNotEmpty);

        controller.clearConversation();

        expect(controller.messages, isEmpty);
        expect(controller.hasPendingConfirmation, isFalse);
        expect(controller.hasError, isFalse);
      });
    });

    group('error handling', () {
      test('handles generator errors gracefully', () async {
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenThrow(Exception('Network error'));

        await controller.sendMessage('Hi');

        expect(controller.hasError, isTrue);
        expect(controller.errorMessage, contains('error'));
      });

      test('retry resends the last message', () async {
        var callCount = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('Network error');
          }
          return _textResponse('Hello!');
        });

        await controller.sendMessage('Hi');
        expect(controller.hasError, isTrue);

        await controller.retry();

        expect(controller.hasError, isFalse);
        expect(callCount, 2);
      });
    });

    group('handleToolAction', () {
      test('handles A2UI component actions', () async {
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _textResponse('Action handled!'));

        await controller.handleToolAction(ToolActionOutput(
          toolUseId: 'tool-123',
          componentName: 'DeviceListView',
          actionType: 'deviceSelected',
          data: {'deviceMac': 'AA:BB:CC:DD:EE:FF'},
        ));

        // Should send action to generator and get response
        verify(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).called(1);
      });
    });
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

LLMResponse _textResponse(String text) {
  return LLMResponse(
    id: 'resp-${DateTime.now().millisecondsSinceEpoch}',
    model: 'test-model',
    content: [TextBlock(text: text)],
  );
}

LLMResponse _toolUseResponse(String toolName, Map<String, dynamic> input) {
  return LLMResponse(
    id: 'resp-${DateTime.now().millisecondsSinceEpoch}',
    model: 'test-model',
    content: [
      ToolUseBlock(
        id: 'tool-${DateTime.now().millisecondsSinceEpoch}',
        name: toolName,
        input: input,
      ),
    ],
  );
}
