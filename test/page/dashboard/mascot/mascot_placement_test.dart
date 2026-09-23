import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/mascot/linksys_mascot_renderer.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Where the mascot sits, and how much of the screen it takes.
///
/// The first tests of any kind to render `MascotOverlay`: the layout gate and the
/// goldens both sweep pages, and the shell's own chrome — the SSE banner, the
/// bottom `MenuHolder`, this overlay, the theme-studio panel — is swept by
/// neither (see `page_surface_cases.dart`, `kSliverDashboardPageCase`). So the
/// mascot's placement had no coverage in either direction before #1531.
///
/// These mount the overlay directly with the spec the shell passes, rather than
/// the shell itself: the shell pulls in SSE bootstrap, the dashboard
/// orchestrator and the remote-assistance guard, none of which decide where the
/// mascot stands. What the shell contributes is the spec, and that is asserted
/// here as a literal.
void main() {
  /// The behaviour the shell hands to `MascotOverlay`, kept in one place so a
  /// change to `usp_dashboard_shell.dart` has to be made here too.
  const shellBehavior = MascotBehaviorConfig(
    autoWalk: false,
    allowDrag: true,
    initialPositionRatio: 1.0,
  );

  Future<void> pumpOverlay(
    WidgetTester tester, {
    required Size screen,
    MascotBehaviorConfig behavior = shellBehavior,
    MascotController? controller,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MascotOverlay(
          controller: controller,
          spec: MascotSpec(
            renderer: const LinksysMascotRenderer(),
            behavior: behavior,
          ),
          child: const IgnorePointer(child: SizedBox.shrink()),
        ),
      ),
    ));
    // `pump`, never `pumpAndSettle`: the idle bob is a repeating animation, so
    // the tree never reaches a settled frame and `pumpAndSettle` times out. One
    // frame past `didChangeDependencies` is all the initial placement needs.
    await tester.pump(const Duration(milliseconds: 16));
  }

  /// The mascot's own rect.
  ///
  /// Anchored on the overlay's `GestureDetector`, which is the node that owns
  /// `onTap`/`onPan*` and sits directly around the renderer's output — so this
  /// measures the box the user can actually touch, which is the whole point of
  /// the footprint assertions.
  ///
  /// Not `find.byType(CustomPaint)`: the first match in this tree is a
  /// full-screen one from `Scaffold`/`MaterialApp`, so it silently reports the
  /// window size and every footprint test passes or fails for the wrong reason.
  final mascotFinder = find.descendant(
    of: find.byType(MascotOverlay),
    matching: find.byType(GestureDetector),
  );

  Rect mascotRect(WidgetTester tester) => tester.getRect(mascotFinder.first);

  group('mascot placement', () {
    testWidgets('parks bottom-right, not at a random x', (tester) async {
      const screen = Size(1440, 900);
      await pumpOverlay(tester, screen: screen);

      final rect = mascotRect(tester);
      expect(rect.right, closeTo(screen.width, 1.0),
          reason: 'initialPositionRatio: 1.0 means flush with the right edge');
      expect(rect.bottom, closeTo(screen.height - 8, 1.0),
          reason: 'the default bottomOffset is 8');
    });

    // The defect this fixes: with the default behaviour the mascot starts at a
    // random x and re-picks a random target every 2-5 seconds, across all 29
    // routes under the ShellRoute. Elapsing well past `walkIntervalMax` must
    // leave it exactly where it was parked.
    testWidgets('stays put — no walking after the interval elapses',
        (tester) async {
      await pumpOverlay(tester, screen: const Size(1440, 900));
      final before = mascotRect(tester);

      // Well past `walkIntervalMax` (5s) and any hop's 3s ceiling.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(mascotRect(tester).left, closeTo(before.left, 0.5));
    });

    // Parking it is only safe because the user can still move it off whatever it
    // covers. Dragging is horizontal only in this version of the overlay, which
    // is why parking is the fix and dragging is the escape hatch, not the other
    // way round.
    testWidgets('can still be dragged off the corner', (tester) async {
      await pumpOverlay(tester, screen: const Size(1440, 900));
      final before = mascotRect(tester);

      await tester.drag(mascotFinder.first, const Offset(-400, 0));
      await tester.pump();

      expect(mascotRect(tester).left, lessThan(before.left - 300));

      // `_onDragEnd` schedules a 2s `Future.delayed` before it would resume
      // wandering. Draining it keeps the binding's pending-timer check quiet —
      // and the position assertion after it is the proof that `autoWalk: false`
      // still holds once that callback has run.
      await tester.pump(const Duration(seconds: 3));
      expect(mascotRect(tester).left, lessThan(before.left - 300));
    });

    testWidgets('a dragless spec cannot be moved', (tester) async {
      await pumpOverlay(
        tester,
        screen: const Size(1440, 900),
        behavior: const MascotBehaviorConfig(
          autoWalk: false,
          allowDrag: false,
          initialPositionRatio: 1.0,
        ),
      );
      final before = mascotRect(tester);

      await tester.drag(mascotFinder.first, const Offset(-400, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(mascotRect(tester).left, closeTo(before.left, 0.5));
    });
  });

  group('mascot footprint', () {
    // 320px is the narrowest width the app claims to support, and the width the
    // layout gate uses as its floor. The mascot is a hit-testing
    // GestureDetector, so its width is width the page underneath cannot be
    // reached through.
    testWidgets('takes under a fifth of the 320px floor', (tester) async {
      await pumpOverlay(tester, screen: const Size(320, 640));

      final width = mascotRect(tester).width;
      expect(width, LinksysMascotRenderer.defaultSize.width);

      // 68/320 = 21.25%, down from the artwork's 80/320 = 25%. Both numbers are
      // asserted rather than a round target, because the honest claim here is
      // "less of the floor than before", not a fraction chosen after the fact.
      expect(width / 320, closeTo(0.2125, 0.0001));
      expect(
          width / 320, lessThan(LinksysMascotRenderer.artworkSize.width / 320));
    });

    // The renderer's `size` is what the overlay clamps against; the artwork is
    // drawn in its own coordinate space and scaled into that box. They were the
    // same number before, and the painter ignored the box entirely — so a
    // smaller `size` would have clipped rather than scaled.
    testWidgets('the drawn box follows size, not the artwork constant',
        (tester) async {
      await pumpOverlay(tester, screen: const Size(1440, 900));

      final rect = mascotRect(tester);
      expect(rect.size, LinksysMascotRenderer.defaultSize);
      expect(rect.size, isNot(LinksysMascotRenderer.artworkSize));
    });

    testWidgets('a custom size is honoured end to end', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MascotOverlay(
            spec: const MascotSpec(
              renderer: LinksysMascotRenderer(size: Size(40, 55)),
              behavior: shellBehavior,
            ),
            child: const IgnorePointer(child: SizedBox.shrink()),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 16));

      expect(mascotRect(tester).size, const Size(40, 55));
    });
  });
}
