import 'package:flutter_test/flutter_test.dart';

import '../common/config.dart';
import '../common/screen.dart';
import 'layout_cases.dart';

void main() {
  group('measuringScreensFor', () {
    List<(double, double)> sizes(List<ScreenSize> screens) =>
        [for (final s in screens) (s.width, s.height)];

    test('measures each width at the height of the nearest case size', () {
      // 1080 (720) is the nearest desktop size to 905, 480 (932) the nearest
      // mobile size to 601 and 360, and 1440 (900) the nearest to 1920.
      final measured = measuringScreensFor(responsiveAllScreens, [
        (width: 905, height: null),
        (width: 601, height: null),
        (width: 360, height: null),
        (width: 1920, height: null),
      ]);

      expect(sizes(measured),
          [(905, 720), (601, 932), (360, 932), (1920, 900)]);
    });

    test('names each size after the request it answers', () {
      // Cases bring their own heights, so a report grouped by the measured
      // height would split one requested width into many rows.
      final measured = measuringScreensFor(responsiveAllScreens, [
        (width: 905, height: null),
        (width: 1280, height: 420),
      ]);

      expect(measured.map((s) => s.name), ['905', '1280x420']);
    });

    test('skips a width in a layout the case does not render', () {
      // 904 is the widest mobile layout and 905 the narrowest desktop one.
      final measured = measuringScreensFor(responsiveMobileScreens, [
        (width: 904, height: null),
        (width: 905, height: null),
      ]);

      expect(sizes(measured), [(904, 1133)]);
    });

    test('uses a requested height over the case height', () {
      final request = [(width: 1280.0, height: 420.0)];

      expect(sizes(measuringScreensFor(responsiveAllScreens, request)),
          [(1280, 420)]);
      expect(measuringScreensFor(responsiveMobileScreens, request), isEmpty);
    });

    test("keeps a case's own height", () {
      // The apps-and-gaming cases render mobile 1280px tall to fit the page.
      final tall = [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)),
        ...responsiveDesktopScreens,
      ];

      expect(sizes(measuringScreensFor(tall, [(width: 601, height: null)])),
          [(601, 1280)]);
    });
  });
}
