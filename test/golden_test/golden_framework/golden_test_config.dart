import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shell wrapper type for pumping the view.
enum ShellType {
  /// Wraps in UiKitPageView.withSliver — used by most settings pages.
  pageView,

  /// Wraps in a bare Scaffold — used by tabbed pages (Wi-Fi, Port Forwarding).
  scaffold,

  /// No wrapping — the view provides its own scaffold/shell.
  custom,
}

/// Device screen definition for golden tests.
class GoldenDevice {
  final String name;
  final Size size;

  const GoldenDevice(this.name, this.size);

  static const phone480 = GoldenDevice('phone480', Size(480, 800));
  static const desktop1280 = GoldenDevice('desktop1280', Size(1280, 800));
  static const defaults = [phone480, desktop1280];
}

/// Callback to configure provider overrides for a given state.
typedef MockSetup = void Function(List<Override> overrides);

/// An interaction-driven test: set up state, then execute tester steps before
/// taking the screenshot. Only for UI overlays that don't change provider state.
class Interaction {
  final MockSetup setup;
  final Future<void> Function(WidgetTester tester) steps;

  const Interaction({required this.setup, required this.steps});
}

/// Declarative configuration for one view's golden tests.
///
/// The runner will iterate every entry in [states] and [interactions],
/// crossed with every device, locale, and theme, producing one golden per combination.
class GoldenTestConfig {
  /// Unique view identifier — snake_case, readable name (e.g. 'firewall').
  final String viewName;

  /// Builder that returns the widget under test.
  final Widget Function() view;

  /// Shell wrapper type.
  final ShellType shell;

  /// State-driven tests: key = state name (snake_case), value = provider overrides setup.
  final Map<String, MockSetup> states;

  /// Interaction-driven tests: key = interaction name, value = setup + steps.
  final Map<String, Interaction>? interactions;

  /// Locales to test.
  final List<Locale> locales;

  /// Screen sizes to test.
  final List<GoldenDevice> devices;

  /// Theme brightness modes to test.
  final List<Brightness> themes;

  /// Custom height override — replaces the device's default height.
  /// Use for long pages that need full-content capture without scrolling.
  final double? height;

  /// Images to precache before taking the screenshot.
  /// Required for views that use Image widgets with AssetImage/package assets,
  /// because image resolution is async and won't complete in a fake async zone.
  final List<ImageProvider> Function()? precacheImages;

  const GoldenTestConfig({
    required this.viewName,
    required this.view,
    required this.shell,
    required this.states,
    this.interactions,
    this.locales = const [Locale('en')],
    this.devices = GoldenDevice.defaults,
    this.themes = const [Brightness.light],
    this.height,
    this.precacheImages,
  });
}
