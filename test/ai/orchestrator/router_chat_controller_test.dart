import 'dart:async';

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

  /// Stands in for the live router state. Reassign it mid-test to represent the
  /// network changing under a session that is already open.
  late String routerContext;

  setUpAll(() {
    registerFallbackValue(<ChatMessage>[]);
    registerFallbackValue(<GenTool>[]);
    registerFallbackValue(<SystemPromptPart>[]);
  });

  setUp(() {
    mockGenerator = MockConversationGenerator();
    mockCommandProvider = MockRouterCommandProvider();
    routerContext = '# Test Router Context\nModel: TestRouter';

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
      routerContextBuilder: () => routerContext,
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

    group('router context freshness', () {
      /// The summary used to be captured once in the constructor, so a session
      /// left open kept describing the network as it was when the panel opened —
      /// under a heading that reads `# Current Router State`.
      test('each request carries the summary as it is at that moment',
          () async {
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _textResponse('ok'));

        await controller.sendMessage('how many devices?');

        // The network changes while the session stays open.
        routerContext = '# Current Router State\n- Total connected devices: 9';

        await controller.sendMessage('and now?');

        final sent = verify(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: captureAny(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).captured.cast<List<SystemPromptPart>?>();

        expect(sent.length, 2);
        expect(
          _summaryOf(sent.first),
          contains('Model: TestRouter'),
          reason:
              'first request should carry the summary from before the change',
        );
        expect(
          _summaryOf(sent.last),
          contains('Total connected devices: 9'),
          reason: 'second request should carry the changed summary, not the '
              'one captured when the controller was built',
        );
      });

      /// Guards the property the refresh depends on: the static instructions are
      /// their own cacheable part and come first, so a summary that differs on
      /// every request still leaves the cached prefix untouched.
      test('static instructions stay cacheable and ordered first', () async {
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _textResponse('ok'));

        await controller.sendMessage('hi');

        final sent = verify(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: captureAny(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).captured.cast<List<SystemPromptPart>?>();

        final parts = sent.single!;
        expect(parts.first.cache, isTrue);
        expect(parts.first.text, isNot(contains('TestRouter')),
            reason: 'the cached part must not carry the volatile summary');
        expect(parts.skip(1).every((p) => p.cache == false), isTrue);
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
        expect(controller.currentRound, 0);
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

    // =========================================================================
    // Batched tool results (#1191)
    //
    // The Claude Messages API requires every tool_use block in an assistant
    // message to be answered within the single user message that immediately
    // follows it.
    // =========================================================================

    group('round reporting', () {
      test('is 0 while idle', () {
        expect(controller.currentRound, 0);
      });

      test('reports the round in flight, and clears when the answer arrives',
          () async {
        // Two rounds: the model asks for data, then answers with it. The view
        // shows this so a multi-round wait is distinguishable from a hang.
        final roundsSeen = <int>[];
        controller.addListener(() => roundsSeen.add(controller.currentRound));

        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _toolUseResponse('getSystemInfo', {})
              : _textResponse('Your router is a TestRouter.');
        });
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer((_) async =>
                RouterCommandResult.success(const {'model': 'TestRouter'}));

        await controller.sendMessage('what router is this?');

        expect(roundsSeen, contains(1),
            reason: 'the first round must be published');
        expect(roundsSeen, contains(2),
            reason: 'a second round means the assistant needed data first');
        expect(controller.currentRound, 0,
            reason: 'an idle controller must not claim a round is running, or '
                'the view keeps showing progress after the answer');
      });

      test('reads idle immediately when cleared mid-call', () async {
        // A clear is a forced end. The `finally` also resets, but not until the
        // in-flight call yields — so without an explicit reset the view sees
        // `isLoading == false` next to a non-zero round for a frame.
        final gate = Completer<LLMResponse>();
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
            )).thenAnswer((_) => gate.future);

        final pending = controller.sendMessage('hi');
        await Future<void>.delayed(Duration.zero);
        expect(controller.currentRound, 1, reason: 'a round is in flight');

        controller.clearConversation();

        expect(controller.currentRound, 0,
            reason: 'the view must not report a round after a clear');
        expect(controller.isLoading, isFalse);

        gate.complete(_textResponse('late'));
        await pending;
        expect(controller.currentRound, 0);
      });

      test('clears the round after a confirmation is answered', () async {
        // The confirmation flow re-enters the loop, so it has its own exit paths
        // through the same wrapper. Both outcomes must land back at idle.
        when(() => mockGenerator.generateWithHistory(
                  any(),
                  tools: any(named: 'tools'),
                  systemPromptParts: any(named: 'systemPromptParts'),
                ))
            .thenAnswer((_) async =>
                _toolUseResponse('setWifiPassword', {'password': 'secret123'}));

        await controller.sendMessage('change my wifi password');
        expect(controller.hasPendingConfirmation, isTrue);

        when(() => mockCommandProvider.execute('setWifiPassword', any()))
            .thenAnswer((_) async => RouterCommandResult.success(const {}));
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
            )).thenAnswer((_) async => _textResponse('Done.'));

        await controller.confirmPendingAction();

        expect(controller.currentRound, 0);
      });

      test('clears the round after a confirmation is cancelled', () async {
        when(() => mockGenerator.generateWithHistory(
                  any(),
                  tools: any(named: 'tools'),
                  systemPromptParts: any(named: 'systemPromptParts'),
                ))
            .thenAnswer((_) async =>
                _toolUseResponse('setWifiPassword', {'password': 'secret123'}));

        await controller.sendMessage('change my wifi password');
        expect(controller.hasPendingConfirmation, isTrue);

        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
            )).thenAnswer((_) async => _textResponse('No problem.'));

        await controller.cancelPendingAction();

        expect(controller.currentRound, 0);
      });

      test('clears the round even when the exchange fails', () async {
        // The reset lives in a `finally`, because the body has many exits and
        // a stuck counter would leave the view describing work that has stopped.
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
            )).thenThrow(Exception('network down'));

        await controller.sendMessage('hello');

        expect(controller.currentRound, 0);
      });
    });

    group('tool result batching', () {
      test('answers parallel read tools in one message', () async {
        when(() => mockCommandProvider.execute(any(), any())).thenAnswer(
            (_) async => RouterCommandResult.success(const {'ok': true}));

        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _multiToolUseResponse([
                  ('read-1', 'getSystemInfo', const <String, dynamic>{}),
                  ('read-2', 'getSystemInfo', const <String, dynamic>{}),
                ])
              : _textResponse('done');
        });

        await controller.sendMessage('Check twice');

        final results = _toolResultMessages(controller.messages);
        expect(results, hasLength(1),
            reason: 'both results must share a single message');
        expect(_partsOf(results.single).map((p) => p.toolUseId),
            ['read-1', 'read-2']);
      });

      test('holds sibling results back until a confirmation is answered',
          () async {
        when(() => mockCommandProvider.execute(any(), any())).thenAnswer(
            (_) async => RouterCommandResult.success(const {'ok': true}));

        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _multiToolUseResponse([
                  ('read-1', 'getSystemInfo', const <String, dynamic>{}),
                  ('write-1', 'setWifiPassword', const {'password': 'secret'}),
                ])
              : _textResponse('done');
        });

        await controller.sendMessage('Check and change');

        // Batch stays open while the dialog is showing.
        expect(controller.hasPendingConfirmation, isTrue);
        expect(_toolResultMessages(controller.messages), isEmpty,
            reason: 'nothing may be emitted until the batch is complete');

        await controller.confirmPendingAction();

        final results = _toolResultMessages(controller.messages);
        expect(results, hasLength(1));
        expect(_partsOf(results.single).map((p) => p.toolUseId),
            ['read-1', 'write-1'],
            reason: 'every tool_use in the turn must be answered together');
      });

      test('answers sibling results when a confirmation is cancelled',
          () async {
        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _multiToolUseResponse([
                  ('read-1', 'getSystemInfo', const <String, dynamic>{}),
                  ('write-1', 'setWifiPassword', const {'password': 'secret'}),
                ])
              : _textResponse('ok, cancelled');
        });
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer(
                (_) async => RouterCommandResult.success(const {'ok': true}));

        await controller.sendMessage('Check and change');
        await controller.cancelPendingAction();

        final results = _toolResultMessages(controller.messages);
        expect(results, hasLength(1));
        expect(_partsOf(results.single).map((p) => p.toolUseId),
            ['read-1', 'write-1']);
        verifyNever(
            () => mockCommandProvider.execute('setWifiPassword', any()));
      });

      test('does not drop the first of two confirmation-required tools',
          () async {
        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _multiToolUseResponse([
                  ('write-1', 'setWifiPassword', const {'password': 'one'}),
                  ('write-2', 'setWifiPassword', const {'password': 'two'}),
                ])
              : _textResponse('done');
        });
        when(() => mockCommandProvider.execute(any(), any())).thenAnswer(
            (_) async => RouterCommandResult.success(const {'ok': true}));

        await controller.sendMessage('Change twice');

        // The first one is what the user is asked about.
        expect(controller.pendingConfirmation?.params['password'], 'one');

        await controller.confirmPendingAction();

        final parts = _partsOf(_toolResultMessages(controller.messages).single);
        expect(parts.map((p) => p.toolUseId), ['write-2', 'write-1'],
            reason: 'the deferred tool is still answered, not silently lost');

        // Only the confirmed one ran; the extra is deferred to a later turn.
        verify(() => mockCommandProvider.execute('setWifiPassword', any()))
            .called(1);
      });

      test('confirming cannot re-enter the loop while siblings still run',
          () async {
        // Resolve the read tool only when told to, so the dialog would appear
        // mid-loop if the controller still notified from inside _executeToolUse.
        final gate = Completer<RouterCommandResult>();
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer((_) => gate.future);
        when(() => mockCommandProvider.execute('setWifiPassword', any()))
            .thenAnswer(
                (_) async => RouterCommandResult.success(const {'ok': true}));

        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _multiToolUseResponse([
                  ('write-1', 'setWifiPassword', const {'password': 'secret'}),
                  ('read-1', 'getSystemInfo', const <String, dynamic>{}),
                ])
              : _textResponse('done');
        });

        final pending = controller.sendMessage('Change then check');
        await Future<void>.delayed(Duration.zero);

        // Write came first, but the dialog must not be offered yet because the
        // read tool is still in flight.
        expect(controller.hasPendingConfirmation, isFalse);

        gate.complete(RouterCommandResult.success(const {'ok': true}));
        await pending;

        expect(controller.hasPendingConfirmation, isTrue);
      });

      test('retry keeps tool results and does not duplicate the question',
          () async {
        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          if (call == 1) {
            return _multiToolUseResponse([
              ('read-1', 'getSystemInfo', const <String, dynamic>{}),
            ]);
          }
          // The call right after the flush fails, then the retry succeeds.
          if (call == 2) throw NetworkException('flaky');
          return _textResponse('Your router is MR7500.');
        });
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer((_) async =>
                RouterCommandResult.success(const {'m': 'MR7500'}));

        await controller.sendMessage('What router do I have?');
        expect(controller.hasError, isTrue);

        await controller.retry();

        // The real device result must survive — it answers an earlier tool_use.
        final parts = _partsOf(_toolResultMessages(controller.messages).single);
        expect(parts.single.result['m'], 'MR7500',
            reason: 'retry must not destroy a flushed tool result');
        expect(
          controller.messages.where((m) => m.isUser && !m.isToolResult).length,
          1,
          reason: 'the question must not be asked twice',
        );
        // The command already ran; retry resumes rather than re-executing.
        verify(() => mockCommandProvider.execute('getSystemInfo', any()))
            .called(1);
      });

      test('a stale exchange cannot discard the results of a live one',
          () async {
        // Gen 0's read is parked; the user clears, sends again, and gen 1
        // accumulates its own results. Gen 0 must not touch them when it
        // resumes.
        final firstRead = Completer<RouterCommandResult>();
        var reads = 0;
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer((_) {
          reads++;
          return reads == 1
              ? firstRead.future
              : Future.value(RouterCommandResult.success(const {'gen': 1}));
        });

        // Ask for a read whenever the turn has no results yet, otherwise wrap
        // up — independent of how many times the registry is reloaded.
        var toolId = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((invocation) async {
          final history =
              invocation.positionalArguments[0] as List<ChatMessage>;
          if (history.any((m) => m.isToolResult)) return _textResponse('done');
          toolId++;
          return _multiToolUseResponse([
            ('read-$toolId', 'getSystemInfo', const <String, dynamic>{}),
          ]);
        });

        final genZero = controller.sendMessage('First question');
        await Future<void>.delayed(Duration.zero);

        controller.clearConversation();
        await controller.sendMessage('Second question');

        // Gen 1 finished and emitted its own result.
        final afterGenOne = _toolResultMessages(controller.messages);
        expect(afterGenOne, hasLength(1));
        expect(_partsOf(afterGenOne.single).single.result['gen'], 1);

        // Now let gen 0's device call return.
        firstRead.complete(RouterCommandResult.success(const {'gen': 0}));
        await genZero;

        final afterGenZero = _toolResultMessages(controller.messages);
        expect(afterGenZero, hasLength(1),
            reason: 'the stale exchange must neither emit nor erase anything');
        expect(_partsOf(afterGenZero.single).single.result['gen'], 1,
            reason: "gen 1's real result must survive gen 0 resuming");
      });

      test('discards read results when the conversation is cleared mid-tool',
          () async {
        // The read tool is still in flight when the user hits Clear.
        final gate = Completer<RouterCommandResult>();
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer((_) => gate.future);
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _multiToolUseResponse([
              ('read-1', 'getSystemInfo', const <String, dynamic>{}),
            ]));

        final pending = controller.sendMessage('Check my router');
        await Future<void>.delayed(Duration.zero);

        controller.clearConversation();
        gate.complete(RouterCommandResult.success(const {'ok': true}));
        await pending;

        expect(controller.messages, isEmpty,
            reason: 'a tool_result must never be written into a conversation '
                'that was reset while the tool was running');
      });

      test('keeps a confirmation from re-arming in a cleared conversation',
          () async {
        final gate = Completer<RouterCommandResult>();
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer((_) => gate.future);
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _multiToolUseResponse([
              ('write-1', 'setWifiPassword', const {'password': 'secret'}),
              ('read-1', 'getSystemInfo', const <String, dynamic>{}),
            ]));

        final pending = controller.sendMessage('Change then check');
        await Future<void>.delayed(Duration.zero);

        controller.clearConversation();
        gate.complete(RouterCommandResult.success(const {'ok': true}));
        await pending;

        expect(controller.hasPendingConfirmation, isFalse,
            reason: 'a confirmation belonging to a discarded conversation must '
                'not be presented against the fresh one');
        expect(controller.messages, isEmpty);
      });

      test('preserves real read results when a confirmation is abandoned',
          () async {
        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _multiToolUseResponse([
                  ('read-1', 'getSystemInfo', const <String, dynamic>{}),
                  ('write-1', 'setWifiPassword', const {'password': 'secret'}),
                ])
              : _textResponse('done');
        });
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer((_) async =>
                RouterCommandResult.success(const {'model': 'MR7500'}));

        await controller.sendMessage('Check and change');
        expect(controller.hasPendingConfirmation, isTrue);

        // User types instead of answering the dialog.
        await controller.sendMessage('Never mind');

        final parts = _partsOf(_toolResultMessages(controller.messages).first);
        final byId = {for (final p in parts) p.toolUseId: p.result};

        expect(byId['read-1']?['model'], 'MR7500',
            reason: 'the read genuinely ran — its device data must survive');
        expect(byId['write-1']?['status'], 'not_executed',
            reason: 'the write never ran');
      });

      test('does not report an unexecuted command as rendered without registry',
          () async {
        // No command has been looked up yet, so the registry cache is null.
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _textResponse('hi'));
        await controller.sendMessage('hello');

        expect(
          controller.debugAbandonedToolResultFor('setWifiPassword')['status'],
          'not_executed',
          reason: 'when the registry is unknown the safe answer is '
              'not_executed — claiming success is the harmful direction',
        );
      });

      test('ignores retry while a confirmation is still pending', () async {
        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          if (call == 1) {
            return _multiToolUseResponse([
              ('write-1', 'setWifiPassword', const {'password': 'secret'}),
              ('read-1', 'getSystemInfo', const <String, dynamic>{}),
            ]);
          }
          throw NetworkException('flaky');
        });
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenThrow(StateError('boom'));

        await controller.sendMessage('Change then check');
        expect(controller.hasPendingConfirmation, isTrue);

        await controller.retry();

        expect(controller.hasPendingConfirmation, isTrue,
            reason: 'retry must not discard the pending write request');
      });

      test('discards a confirmation result when the conversation was cleared',
          () async {
        final gate = Completer<RouterCommandResult>();
        when(() => mockCommandProvider.execute('setWifiPassword', any()))
            .thenAnswer((_) => gate.future);
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _multiToolUseResponse([
              ('write-1', 'setWifiPassword', const {'password': 'secret'}),
            ]));

        await controller.sendMessage('Change it');
        final confirming = controller.confirmPendingAction();

        // User clears the chat while the device request is still in flight.
        controller.clearConversation();
        gate.complete(RouterCommandResult.success(const {'ok': true}));
        await confirming;

        expect(controller.messages, isEmpty,
            reason: 'a stale result must not be injected into a fresh '
                'conversation, where it would have no matching tool_use');
      });

      test('answers already-executed tools when the batch fails part-way',
          () async {
        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          if (call == 1) {
            return _multiToolUseResponse([
              ('read-1', 'getSystemInfo', const <String, dynamic>{}),
            ]);
          }
          throw NetworkException('flaky');
        });
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenAnswer(
                (_) async => RouterCommandResult.success(const {'ok': true}));

        await controller.sendMessage('Check');

        expect(controller.hasError, isTrue);
        final results = _toolResultMessages(controller.messages);
        expect(results, hasLength(1),
            reason: 'the executed tool must still be answered so the '
                'assistant turn has no unanswered tool_use');
        expect(_partsOf(results.single).single.toolUseId, 'read-1');
      });

      test('keeps a confirmation that was found before a failure', () async {
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async => _multiToolUseResponse([
              ('write-1', 'setWifiPassword', const {'password': 'secret'}),
              ('read-1', 'getSystemInfo', const <String, dynamic>{}),
            ]));
        // The sibling read blows up after the confirmation was discovered.
        when(() => mockCommandProvider.execute('getSystemInfo', any()))
            .thenThrow(StateError('boom'));

        await controller.sendMessage('Change then check');

        expect(controller.hasPendingConfirmation, isTrue,
            reason: "the user's write request must not evaporate");
        expect(controller.pendingConfirmation!.command.name, 'setWifiPassword');
      });

      test('reports abandoned commands as not executed, not as rendered',
          () async {
        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _multiToolUseResponse([
                  ('write-1', 'setWifiPassword', const {'password': 'secret'}),
                ])
              : _textResponse('done');
        });

        await controller.sendMessage('Change it');
        await controller.sendMessage('Actually, never mind');

        final parts = _partsOf(_toolResultMessages(controller.messages).first);
        expect(parts.single.result['status'], 'not_executed',
            reason: 'the command never ran — saying "rendered" misleads the '
                'model into thinking it succeeded');
      });

      test('fills in unanswered tool_use when the user types instead',
          () async {
        var call = 0;
        when(() => mockGenerator.generateWithHistory(
              any(),
              tools: any(named: 'tools'),
              systemPromptParts: any(named: 'systemPromptParts'),
              forceToolUse: any(named: 'forceToolUse'),
            )).thenAnswer((_) async {
          call++;
          return call == 1
              ? _multiToolUseResponse([
                  ('write-1', 'setWifiPassword', const {'password': 'secret'}),
                ])
              : _textResponse('done');
        });

        await controller.sendMessage('Change it');
        expect(controller.hasPendingConfirmation, isTrue);

        // User ignores the dialog and asks something else instead.
        await controller.sendMessage('Never mind, what is my model?');

        expect(controller.hasPendingConfirmation, isFalse);
        final parts = _partsOf(_toolResultMessages(controller.messages).single);
        expect(parts.map((p) => p.toolUseId), ['write-1'],
            reason: 'the abandoned tool_use must still be answered');
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

/// The parts after the cached static instructions, where the summary lives.
String _summaryOf(List<SystemPromptPart>? parts) =>
    (parts ?? []).skip(1).map((p) => p.text).join();

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

/// Build a response containing several tool_use blocks with fixed ids, so tests
/// can assert on which ids were answered and in what order.
LLMResponse _multiToolUseResponse(
  List<(String id, String name, Map<String, dynamic> input)> tools,
) {
  return LLMResponse(
    id: 'resp-${DateTime.now().millisecondsSinceEpoch}',
    model: 'test-model',
    content: [
      for (final (id, name, input) in tools)
        ToolUseBlock(id: id, name: name, input: input),
    ],
  );
}

/// The tool result messages of a conversation, in order.
List<ChatMessage> _toolResultMessages(List<ChatMessage> messages) =>
    messages.where((m) => m.isToolResult).toList();

/// The tool result parts carried by a single tool result message.
List<ToolResultPart> _partsOf(ChatMessage message) =>
    (message.content as List<ContentPart>).whereType<ToolResultPart>().toList();
