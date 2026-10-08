import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/components/widgets/write_guard.dart';

import '../../../common/testable_widget.dart';

const _readOnly = AccessPolicy(canWrite: false);
const _message = 'This feature is unavailable in remote mode';

void main() {
  late int taps;
  late FocusNode focus;

  setUp(() {
    taps = 0;
    focus = FocusNode(debugLabel: 'guarded');
  });
  tearDown(() => focus.dispose());

  Widget guarded({bool localOnly = false}) => WriteGuard(
        localOnly: localOnly,
        child: TextButton(
          focusNode: focus,
          onPressed: () => taps++,
          child: const Text('change'),
        ),
      );

  Future<void> pumpGuard(
    WidgetTester tester, {
    AccessPolicy policy = AccessPolicy.full,
    bool isRemote = false,
    bool localOnly = false,
  }) async {
    await tester.pumpWidget(testableWidget(
      overrides: [
        accessPolicyProvider.overrideWithValue(policy),
        isRemoteLoginProvider.overrideWithValue(isRemote),
      ],
      child: guarded(localOnly: localOnly),
    ));
  }

  Future<void> tap(WidgetTester tester) async {
    await tester.tap(find.text('change'), warnIfMissed: false);
    await tester.pump();
  }

  /// Focuses the control the way a keyboard user would, then activates it.
  Future<void> pressEnter(WidgetTester tester) async {
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
  }

  bool isGuarded() => find.byTooltip(_message).evaluate().isNotEmpty;

  group('with full access', () {
    testWidgets('lets a tap through', (tester) async {
      await pumpGuard(tester);
      await tap(tester);
      expect(taps, 1);
    });

    testWidgets('lets the keyboard through', (tester) async {
      await pumpGuard(tester);
      await pressEnter(tester);
      expect(taps, 1);
    });

    testWidgets('adds nothing to the tree', (tester) async {
      await pumpGuard(tester);
      expect(find.byType(Tooltip), findsNothing);
      expect(find.byType(Opacity), findsNothing);
      expect(
          find.descendant(
              of: find.byType(WriteGuard),
              matching: find.byType(AbsorbPointer)),
          findsNothing);
    });
  });

  group('in read-only mode', () {
    testWidgets('blocks a tap', (tester) async {
      await pumpGuard(tester, policy: _readOnly, isRemote: true);
      await tap(tester);
      expect(taps, 0);
    });

    // AbsorbPointer stops pointer events only. Without a focus block a
    // keyboard user can Tab to the control and press Enter.
    testWidgets('blocks the keyboard', (tester) async {
      await pumpGuard(tester, policy: _readOnly, isRemote: true);
      await pressEnter(tester);
      expect(taps, 0);
      expect(focus.hasFocus, isFalse, reason: 'the control cannot take focus');
    });

    testWidgets('dims the control and says why', (tester) async {
      await pumpGuard(tester, policy: _readOnly, isRemote: true);
      expect(isGuarded(), isTrue);
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
    });

    testWidgets('explains itself on a long press, for touch screens',
        (tester) async {
      await pumpGuard(tester, policy: _readOnly, isRemote: true);
      await tester.longPress(find.text('change'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_message), findsOneWidget);
      expect(taps, 0);
    });

    testWidgets('lifts as soon as writing is allowed again', (tester) async {
      final policy = StateProvider<AccessPolicy>((ref) => _readOnly);
      await tester.pumpWidget(testableWidget(
        overrides: [
          accessPolicyProvider.overrideWith((ref) => ref.watch(policy)),
          isRemoteLoginProvider.overrideWithValue(true),
        ],
        child: guarded(),
      ));
      expect(isGuarded(), isTrue);

      ProviderScope.containerOf(tester.element(find.byType(WriteGuard)))
          .read(policy.notifier)
          .state = AccessPolicy.full;
      await tester.pump();

      expect(isGuarded(), isFalse);
      await tap(tester);
      expect(taps, 1);
    });
  });

  // Manual firmware upload and WAN editing cannot work over a remote session
  // at all, whether or not the build asks for read-only.
  group('localOnly', () {
    testWidgets('blocks a remote login that may otherwise write',
        (tester) async {
      await pumpGuard(tester, isRemote: true, localOnly: true);
      await tap(tester);
      await pressEnter(tester);
      expect(taps, 0);
      expect(isGuarded(), isTrue);
    });

    testWidgets('lets a local login through', (tester) async {
      await pumpGuard(tester, localOnly: true);
      await tap(tester);
      expect(taps, 1);
      expect(isGuarded(), isFalse);
    });

    testWidgets('does not block a remote login that may write', (tester) async {
      await pumpGuard(tester, isRemote: true);
      await tap(tester);
      expect(taps, 1);
    });
  });
}
