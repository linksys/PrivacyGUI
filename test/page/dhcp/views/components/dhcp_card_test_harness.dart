import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../golden_test/golden_framework/golden_test_config.dart';

/// Shared harness for the DHCP card layout tests (#1140).
///
/// Both card tests pump a single card at the golden suite's mobile viewport, so
/// the theme, viewport and scaffold setup live here instead of being duplicated.

final dhcpCardTestTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Mobile viewport, shared with the golden suite so both agree on "mobile".
final phoneSize = GoldenDevice.phone480.size;

/// Content width the page grid hands a card at [phoneSize]: the screen width
/// minus `AppLayoutConfig.marginMobile` (16) on both sides.
final phoneContentWidth = phoneSize.width - 16 * 2;

/// A single line of `bodyMedium`/`bodySmall` is 20dp/16dp tall. 40dp leaves
/// room for the type scale to change while still failing if the text wraps.
const singleLineMaxHeight = 40.0;

/// Pumps [card] inside a mobile-width scaffold and settles.
///
/// [width] defaults to [phoneContentWidth]; pass a narrower value to model the
/// desktop two-column split, where the card gets `context.colWidth(6)`.
Future<void> pumpDhcpCard(
  WidgetTester tester,
  Widget card, {
  List<Override> overrides = const [],
  double? width,
  Size? surfaceSize,
}) async {
  final surface = surfaceSize ?? phoneSize;
  await tester.binding.setSurfaceSize(surface);
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: dhcpCardTestTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: width ?? phoneContentWidth, child: card),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
