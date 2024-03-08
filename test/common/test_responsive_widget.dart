import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

final responsiveAllVariants = ValueVariant<ScreenSize>({
  ...responsiveMobileVariants.values,
  ...responsiveDesktopVariants.values,
});
final responsiveMobileVariants = ValueVariant<ScreenSize>({
  device320w,
  device480w,
  device744w,
});
final responsiveDesktopVariants = ValueVariant<ScreenSize>({
  device1280w,
  device1440w,
});

class ScreenSize {
  const ScreenSize(this.name, this.width, this.height, this.pixelDensity);
  final String name;
  final double width, height, pixelDensity;

  @override
  String toString() => '$name($width, $height, $pixelDensity)';
}

const device320w = ScreenSize('Device320w', 320, 568, 1);
const device480w = ScreenSize('Device480w', 480, 932, 1);
const device744w = ScreenSize('Device744w', 744, 1133, 1);
const device1280w = ScreenSize('Device1280w', 1280, 720, 1);
const device1440w = ScreenSize('Device1440w', 1440, 900, 1);

extension ScreenSizeManager on WidgetTester {
  Future<void> setScreenSize(ScreenSize screenSize) async {
    return _setScreenSize(
      width: screenSize.width,
      height: screenSize.height,
      pixelDensity: screenSize.pixelDensity,
    );
  }

  Future<void> _setScreenSize({
    required double width,
    required double height,
    required double pixelDensity,
  }) async {
    final size = Size(width, height);
    await binding.setSurfaceSize(size);
    view.physicalSize = size;
    view.devicePixelRatio = pixelDensity;
  }
}

@isTest
void testResponsiveWidgets(
  String description,
  WidgetTesterCallback callback, {
  Future<void> Function(String sizeName, WidgetTester tester)? goldenCallback,
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  ValueVariant<ScreenSize>? breakpoints,
  dynamic tags,
}) {
  final variant = breakpoints ?? responsiveAllVariants;
  testWidgets(
    description,
    (tester) async {
      await tester.setScreenSize(variant.currentValue!);
      await callback(tester);
      if (goldenCallback != null) {
        await goldenCallback(variant.currentValue!.name, tester);
      }
    },
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
  );
}
