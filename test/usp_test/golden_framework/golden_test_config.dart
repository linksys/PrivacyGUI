import 'package:flutter/material.dart';
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

  /// Phone: 480 x 800
  static const phone480 = GoldenDevice('Device480w', Size(480, 800));

  /// Desktop: 1280 x 800
  static const desktop1280 = GoldenDevice('Device1280w', Size(1280, 800));

  /// Default test devices.
  static const defaults = [phone480, desktop1280];
}

/// Callback to configure provider mocks for a given state.
typedef MockSetup = void Function(MockRegistry mock);

/// An interaction-driven test: set up state, then execute tester steps before
/// taking the screenshot.
class Interaction {
  /// Provider mock setup (same as a state entry).
  final MockSetup setup;

  /// Steps to execute after pumping the widget (tap, scroll, etc.).
  final Future<void> Function(WidgetTester tester) steps;

  const Interaction({required this.setup, required this.steps});
}

/// Declarative configuration for one view's golden tests.
///
/// The runner will iterate every entry in [states] and [interactions],
/// crossed with every device and locale, producing one golden per combination.
class GoldenTestConfig {
  /// View identifier — 3-5 uppercase letters (e.g. 'FWALL').
  final String viewId;

  /// Builder that returns the widget under test.
  final Widget Function() view;

  /// Shell wrapper type.
  final ShellType shell;

  /// State-driven tests: key = state name (snake_case), value = mock setup.
  final Map<String, MockSetup> states;

  /// Interaction-driven tests: key = interaction name, value = setup + steps.
  final Map<String, Interaction>? interactions;

  const GoldenTestConfig({
    required this.viewId,
    required this.view,
    required this.shell,
    required this.states,
    this.interactions,
  });
}

/// Placeholder — real implementation in mock_registry.dart (Task 2).
/// This exists only so golden_test_config.dart compiles standalone.
class MockRegistry {}
