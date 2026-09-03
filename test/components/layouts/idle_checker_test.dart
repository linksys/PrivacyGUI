/// Coverage for [IdleChecker]'s definition of "user activity" — PrivacyGUI#1454.
///
/// Deliberately NOT tagged `ui`: nothing here asserts how anything looks. Every
/// case pumps a stub child, drives one input path, advances the fake clock and
/// asks a single question — did the countdown reset? That guarantee is worth
/// blocking a PR on and costs a handful of pumps, so it belongs in
/// `run_tests.sh`'s PR-blocking set (which excludes `golden||loc||ui`) rather
/// than the `ui` bucket that set skips.
///
/// ## Why the shape of these tests matters
///
/// The bug this suite locks down was invisible to inspection: the widget *had*
/// listeners and *did* reset a timer, so nothing looked wrong. Three input
/// paths simply never reached `_resetTimer()` — keyboard (no listener at all),
/// scrolling (a pointer *signal*, which is neither a hover nor a down event),
/// and uninterrupted mouse movement (a trailing debounce that rescheduled
/// itself on every event, so a mouse that never paused reset nothing).
///
/// None of those are detectable without advancing time, which is why each case
/// pumps across the idle window rather than asserting on widget structure.
///
/// The negative cases in `countdown expires when it should` carry as much
/// weight as the positive ones: they prove auto-logout still happens at all,
/// and that the app cannot keep its own session alive by scrolling itself. A
/// change that made every positive case pass while breaking either of those
/// would be a regression dressed as a fix.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/layouts/idle_checker.dart';
import 'package:privacy_gui/core/pwa/pwa_install_service.dart';

const _idleTime = Duration(seconds: 10);

/// Half the idle window: long enough that a second wait of the same length
/// crosses it, so a missing reset shows up as a logout.
const _halfWindow = Duration(seconds: 6);

/// Stands in for an installed PWA. [PwaInstallService.isStandalone] is a DOM
/// query that is always false off the web, so the only way to exercise the
/// standalone guard on the VM is to override the notifier. Hand-written rather
/// than a mocktail mock because Riverpod drives the real `Notifier` lifecycle,
/// which a `Mock implements` stub cannot satisfy.
class _StandalonePwaService extends PwaInstallService {
  @override
  PwaMode build() => PwaMode.none;

  @override
  bool get isStandalone => true;
}

/// Pumps an [IdleChecker] around [child] and returns a getter for whether
/// `onIdle` has fired.
Future<bool Function()> _pumpChecker(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
}) async {
  var idled = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: IdleChecker(
          idleTime: _idleTime,
          onIdle: () => idled = true,
          child: child,
        ),
      ),
    ),
  );
  return () => idled;
}

Widget _list([ScrollController? controller]) => ListView.builder(
      controller: controller,
      itemCount: 200,
      itemBuilder: (_, index) =>
          SizedBox(height: 40, child: Text('row $index')),
    );

/// Parks a mouse cursor so later scroll events have a location to report, then
/// burns the first half of the idle window. Scrolling is the thing under test,
/// so the cursor must not move again after this.
Future<TestPointer> _parkCursor(
  WidgetTester tester, {
  PointerDeviceKind kind = PointerDeviceKind.mouse,
}) async {
  final pointer = TestPointer(1, kind);
  await tester.sendEventToBinding(pointer.hover(const Offset(400, 300)));
  await tester.pump(_halfWindow);
  return pointer;
}

void main() {
  group('countdown expires when it should', () {
    testWidgets('no input at all logs out', (tester) async {
      final idled = await _pumpChecker(tester, child: const SizedBox.expand());
      await tester.pump(const Duration(seconds: 11));
      expect(idled(), isTrue);
    });

    testWidgets('logs out once a burst of every kind of activity stops',
        (tester) async {
      final idled = await _pumpChecker(tester, child: const SizedBox.expand());
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      for (var i = 0; i < 20; i++) {
        await tester.sendEventToBinding(pointer.hover(Offset(10 + i * 2, 10)));
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 20)));
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(idled(), isFalse, reason: 'still active during the burst');

      await tester.pump(const Duration(seconds: 11));
      expect(idled(), isTrue,
          reason: 'the countdown must still expire after activity stops');
    });

    testWidgets('scrolling the app itself does not count as activity',
        (tester) async {
      final controller = ScrollController();
      final idled = await _pumpChecker(tester, child: _list(controller));
      await _parkCursor(tester);

      // No user input whatsoever - the app scrolls itself.
      controller.jumpTo(500);
      await tester.pump();
      await tester.pump(_halfWindow);

      expect(idled(), isTrue);
    });
  });

  group('keyboard counts as activity', () {
    testWidgets('typing resets the countdown', (tester) async {
      final idled = await _pumpChecker(tester, child: const SizedBox.expand());
      await tester.pump(_halfWindow);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });

    testWidgets('typing counts while a TextField holds focus', (tester) async {
      final idled = await _pumpChecker(
        tester,
        child: const Material(child: TextField(autofocus: true)),
      );
      await tester.pump();
      expect(tester.testTextInput.isRegistered, isTrue,
          reason: 'the field must own the keyboard for this to mean anything');

      await tester.pump(_halfWindow);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });
  });

  group('scrolling counts as activity', () {
    testWidgets('mouse wheel resets the countdown with the cursor still',
        (tester) async {
      final idled = await _pumpChecker(tester, child: const SizedBox.expand());
      final pointer = await _parkCursor(tester);

      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });

    testWidgets('a trackpad scroll signal resets the countdown',
        (tester) async {
      // The shape web reports a two-finger scroll as: a scroll signal that is
      // merely tagged `trackpad`. Distinct from the pan-zoom case below.
      final idled = await _pumpChecker(tester, child: _list());
      final pointer = await _parkCursor(
        tester,
        kind: PointerDeviceKind.trackpad,
      );

      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 200)));
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });

    testWidgets('a native trackpad pan gesture resets the countdown',
        (tester) async {
      // The shape embedders with native trackpad gestures report: pan-zoom
      // events, which are not PointerSignalEvents and so bypass
      // onPointerSignal entirely. Web never sends these, so without a hook of
      // their own this suite would go green while trackpad-only scrolling on
      // any other embedder still timed out.
      final idled = await _pumpChecker(tester, child: _list());
      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester
          .sendEventToBinding(pointer.panZoomStart(const Offset(400, 300)));
      await tester.pump(_halfWindow);

      await tester.sendEventToBinding(
        pointer.panZoomUpdate(const Offset(400, 300),
            pan: const Offset(0, -80)),
      );
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });

    testWidgets('wheel over a Scrollable that consumes the signal still counts',
        (tester) async {
      final idled = await _pumpChecker(tester, child: _list());
      final pointer = await _parkCursor(tester);

      // The Scrollable registers with the PointerSignalResolver and consumes
      // the scroll; the wrapper must observe it regardless.
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 200)));
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });
  });

  group('pointer activity keeps working', () {
    testWidgets('tap resets the countdown', (tester) async {
      final idled = await _pumpChecker(tester, child: const SizedBox.expand());
      await tester.pump(_halfWindow);

      await tester.tap(find.byType(SizedBox), warnIfMissed: false);
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });

    testWidgets('drag-scrolling a list resets the countdown', (tester) async {
      final idled = await _pumpChecker(tester, child: _list());
      await tester.pump(_halfWindow);

      await tester.drag(find.text('row 0'), const Offset(0, -300));
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });

    testWidgets('hovering then pausing resets the countdown', (tester) async {
      final idled = await _pumpChecker(tester, child: const SizedBox.expand());
      await tester.pump(_halfWindow);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(const Offset(10, 10)));
      await tester.sendEventToBinding(pointer.hover(const Offset(20, 20)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(_halfWindow);

      expect(idled(), isFalse);
    });

    testWidgets('a mouse that never pauses resets the countdown',
        (tester) async {
      final idled = await _pumpChecker(tester, child: const SizedBox.expand());
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(const Offset(10, 10)));

      // Move for longer than the whole idle window, never leaving a gap wide
      // enough for the debounce this replaces to have fired.
      for (var i = 0; i < 120; i++) {
        await tester.sendEventToBinding(
          pointer.hover(Offset(10 + (i % 50).toDouble(), 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(idled(), isFalse);
    });
  });

  group('binding-level key handler is cleaned up', () {
    testWidgets('key events after dispose do not throw', (tester) async {
      await _pumpChecker(tester, child: const SizedBox.expand());

      // Replace the whole tree so the checker is disposed.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.expand()));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('remounting leaves no stale handler behind', (tester) async {
      var firstIdled = false;
      var secondIdled = false;

      Widget wrap(Key key, VoidCallback onIdle) => ProviderScope(
            child: MaterialApp(
              home: IdleChecker(
                key: key,
                idleTime: _idleTime,
                onIdle: onIdle,
                child: const SizedBox.expand(),
              ),
            ),
          );

      await tester
          .pumpWidget(wrap(const ValueKey('a'), () => firstIdled = true));
      await tester
          .pumpWidget(wrap(const ValueKey('b'), () => secondIdled = true));

      await tester.pump(_halfWindow);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump(_halfWindow);

      expect(secondIdled, isFalse, reason: 'the live checker must reset');
      expect(firstIdled, isFalse, reason: 'the disposed one must stay silent');
      expect(tester.takeException(), isNull);
    });
  });

  group('PWA standalone mode', () {
    testWidgets('never logs out, however long it sits idle', (tester) async {
      final idled = await _pumpChecker(
        tester,
        child: const SizedBox.expand(),
        overrides: [
          pwaInstallServiceProvider.overrideWith(_StandalonePwaService.new),
        ],
      );

      await tester.pump(const Duration(minutes: 30));

      expect(idled(), isFalse);
    });

    testWidgets('activity does not start a countdown either', (tester) async {
      final idled = await _pumpChecker(
        tester,
        child: const SizedBox.expand(),
        overrides: [
          pwaInstallServiceProvider.overrideWith(_StandalonePwaService.new),
        ],
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump(const Duration(minutes: 30));

      expect(idled(), isFalse);
    });
  });
}
