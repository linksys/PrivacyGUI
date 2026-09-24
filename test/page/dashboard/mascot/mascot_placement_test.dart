import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/mascot/linksys_mascot_renderer.dart';
import 'package:privacy_gui/page/dashboard/mascot/widgets/parked_mascot_overlay.dart';
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
        body: ParkedMascotOverlay(
          controller: controller ?? MascotController(),
          dialogProvider: null,
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

  /// Re-lays out at [width] without remounting the harness, the way a browser
  /// window resize does.
  Future<void> resizeTo(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    await tester.pump(const Duration(milliseconds: 16));
  }

  Rect mascotRect(WidgetTester tester) => tester.getRect(mascotFinder.first);

  group('mascot placement', () {
    testWidgets('parks bottom-right, not at a random x', (tester) async {
      const screen = Size(1440, 900);
      await pumpOverlay(tester, screen: screen);

      final rect = mascotRect(tester);
      const inset = ParkedMascotOverlay.edgeInset;
      expect(rect.right, closeTo(screen.width - inset, 1.0),
          reason: 'parked with an inset, not flush against the edge');
      expect(rect.bottom, closeTo(screen.height - inset, 1.0),
          reason: 'the same inset below, so the corner reads as placed');
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
        ),
      );
      final before = mascotRect(tester);

      await tester.drag(mascotFinder.first, const Offset(-400, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(mascotRect(tester).left, closeTo(before.left, 0.5));
    });
  });

  // Resizing the viewport, which is where parking alone was not enough.
  //
  // The overlay stores x as an absolute pixel offset and only clamps it against
  // the current width, so the two directions behave differently: shrinking pulls
  // the mascot back to the right edge (the clamp bites), growing does not (it
  // stops biting and the old offset stands). Measured before the fix, parked
  // bottom-right: 1440→800→320 held a 0px gap at every step, while 1440→1920
  // left a 480px gap and 500→1920 left 1420px — a quarter of the way across the
  // screen for anyone who starts small and maximises.
  group('mascot re-parks on resize', () {
    testWidgets('stays in the corner when the window shrinks', (tester) async {
      await pumpOverlay(tester, screen: const Size(1440, 900));

      for (final width in [800.0, 500.0, 320.0]) {
        await resizeTo(tester, Size(width, 900));
        expect(mascotRect(tester).right,
            closeTo(width - ParkedMascotOverlay.edgeInset, 1.0),
            reason: 'shrinking to $width must keep the same inset');
      }
    });

    testWidgets('re-parks when the window grows', (tester) async {
      await pumpOverlay(tester, screen: const Size(1440, 900));

      await resizeTo(tester, const Size(1920, 900));

      expect(mascotRect(tester).right,
          closeTo(1920 - ParkedMascotOverlay.edgeInset, 1.0),
          reason: 'was stranded 480px from the right edge before the fix');
    });

    testWidgets('re-parks after starting small and maximising', (tester) async {
      await pumpOverlay(tester, screen: const Size(500, 800));

      await resizeTo(tester, const Size(1920, 1080));

      expect(mascotRect(tester).right,
          closeTo(1920 - ParkedMascotOverlay.edgeInset, 1.0),
          reason: 'was stranded 1420px from the right edge before the fix');
    });

    testWidgets('survives a shrink-then-grow round trip', (tester) async {
      await pumpOverlay(tester, screen: const Size(1440, 900));

      await resizeTo(tester, const Size(320, 640));
      await resizeTo(tester, const Size(1440, 900));

      expect(mascotRect(tester).right,
          closeTo(1440 - ParkedMascotOverlay.edgeInset, 1.0));
    });

    // The reason the remount fires on shrink too, which is not about where the
    // mascot appears — after a shrink it already appears in the corner.
    //
    // The clamp is applied to a local and never written back, so `_positionX`
    // keeps the old wide value and a drag has to spend the difference before
    // anything moves. Measured at 1440→800 without the remount: `_positionX`
    // 1392 against a ceiling of 752, so the first 640px of leftward drag were
    // swallowed — a 100px drag moved nothing at all, and 400px hit the left
    // edge. The mascot looked stuck, then leapt.
    //
    // A drag this small is the assertion: it is well inside the old dead zone,
    // so it moves the mascot only if `_positionX` was refreshed.
    testWidgets('a small drag still moves it right after a shrink',
        (tester) async {
      await pumpOverlay(tester, screen: const Size(1440, 900));
      await resizeTo(tester, const Size(800, 900));

      final before = mascotRect(tester).left;
      await tester.drag(mascotFinder.first, const Offset(-100, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(mascotRect(tester).left, lessThan(before - 50),
          reason: 'a 100px drag moved 0px while the stale offset stood');
    });
  });

  group('the parked inset is a gap, not a ratio', () {
    // A single `initialPositionRatio` cannot express a fixed gap: the overlay
    // multiplies it by `width - mascotWidth`, so 0.99 leaves 18.7px at 1920 and
    // 2.7px at 320 — the narrow screens that need the gap most would be the ones
    // that barely get it. The wrapper solves for the ratio per width instead, and
    // this is what pins that.
    testWidgets('is the same number of pixels at every width', (tester) async {
      await pumpOverlay(tester, screen: const Size(1920, 1080));

      for (final width in [1920.0, 1440.0, 800.0, 500.0, 320.0]) {
        await resizeTo(tester, Size(width, 900));
        expect(width - mascotRect(tester).right,
            closeTo(ParkedMascotOverlay.edgeInset, 1.0),
            reason: 'gap at ${width}px');
      }
    });

    // Degenerate widths: there is no room for two insets plus the mascot, and the
    // arithmetic would ask for a negative ratio. Flush right is the right answer,
    // and it must not throw or leave the mascot off-screen.
    testWidgets('degrades to flush right when there is no room',
        (tester) async {
      await pumpOverlay(tester, screen: const Size(60, 400));

      final rect = mascotRect(tester);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(60));
    });

    testWidgets('ratioForInset stays within bounds', (tester) async {
      // Unit-level, because the boundary is arithmetic rather than layout.
      expect(
          ParkedMascotOverlay.ratioForInset(1920, 48), closeTo(0.99145, 1e-4));
      expect(
          ParkedMascotOverlay.ratioForInset(320, 48), closeTo(0.94118, 1e-4));
      expect(ParkedMascotOverlay.ratioForInset(60, 48), 0.0);
      expect(ParkedMascotOverlay.ratioForInset(48, 48), 1.0);
      expect(ParkedMascotOverlay.ratioForInset(20, 48), 1.0);
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

      // 48/320 = 15%, down from the artwork's 80/320 = 25%. Asserted as the
      // measured fraction rather than a round target, so a later size change has
      // to restate what it costs at the floor.
      expect(width / 320, closeTo(0.15, 0.0001));
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
          body: ParkedMascotOverlay(
            controller: MascotController(),
            dialogProvider: null,
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
