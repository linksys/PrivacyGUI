import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'golden_test_config.dart';
import 'mock_registry.dart';

/// Auto-generates golden tests for a view using declarative configuration.
///
/// Usage:
/// ```dart
/// void main() {
///   runViewGoldenTests(GoldenTestConfig(
///     viewId: 'FWALL',
///     view: () => const FirewallView(),
///     shell: ShellType.pageView,
///     states: {
///       'loading': (mock) => mock.firewall(FirewallFeatureState.loading()),
///       'error': (mock) => mock.firewall(FirewallFeatureState.error('...')),
///       'data': (mock) => mock.firewall(FirewallFeatureState.data(...)),
///     },
///     interactions: {
///       'toggle_ipv6': Interaction(
///         setup: (mock) => mock.firewall(FirewallFeatureState.data(...)),
///         steps: (tester) async {
///           await tester.tap(find.text('IPv6'));
///           await tester.pump();
///         },
///       ),
///     },
///   ));
/// }
/// ```
void runViewGoldenTests(GoldenTestConfig config) {
  // Validation section
  _validateConfig(config);

  // Test generation
  group('${config.viewId} Golden Tests', () {
    // State-driven tests: for each state × device × locale
    for (final stateEntry in config.states.entries) {
      final stateName = stateEntry.key;
      final setup = stateEntry.value;

      for (final device in GoldenDevice.defaults) {
        for (final locale in [const Locale('en')]) {
          testGoldens(
            '${config.viewId} - $stateName - ${device.name} - ${locale.languageCode}',
            (tester) async {
              // Setup mocks
              final mockRegistry = MockRegistry();
              mockRegistry.common();
              setup(mockRegistry);

              // Pump widget in shell
              await _pumpWidgetInShell(
                tester,
                config.view(),
                config.shell,
                mockRegistry.build(),
                device.size,
                locale,
              );

              // Capture screenshot
              await screenMatchesGolden(
                tester,
                '${config.viewId}-$stateName-${device.name}-${locale.languageCode}',
              );
            },
          );
        }
      }
    }

    // Interaction-driven tests: for each interaction × device × locale
    if (config.interactions != null) {
      for (final interactionEntry in config.interactions!.entries) {
        final interactionName = interactionEntry.key;
        final interaction = interactionEntry.value;

        for (final device in GoldenDevice.defaults) {
          for (final locale in [const Locale('en')]) {
            testGoldens(
              '${config.viewId} - $interactionName - ${device.name} - ${locale.languageCode}',
              (tester) async {
                // Setup mocks
                final mockRegistry = MockRegistry();
                mockRegistry.common();
                interaction.setup(mockRegistry);

                // Pump widget in shell
                await _pumpWidgetInShell(
                  tester,
                  config.view(),
                  config.shell,
                  mockRegistry.build(),
                  device.size,
                  locale,
                );

                // Execute interaction steps
                await interaction.steps(tester);

                // Capture screenshot after interaction
                await screenMatchesGolden(
                  tester,
                  '${config.viewId}-$interactionName-${device.name}-${locale.languageCode}',
                );
              },
            );
          }
        }
      }
    }
  });
}

/// Validates the configuration and throws helpful error messages.
void _validateConfig(GoldenTestConfig config) {
  // viewId must match ^[A-Z]{3,5}$
  final viewIdPattern = RegExp(r'^[A-Z]{3,5}$');
  if (!viewIdPattern.hasMatch(config.viewId)) {
    throw ArgumentError(
      'viewId must be 3-5 uppercase letters (e.g., "FWALL"). Got: "${config.viewId}"',
    );
  }

  // Must have required states: loading, error, data
  const requiredStates = ['loading', 'error', 'data'];
  for (final requiredState in requiredStates) {
    if (!config.states.containsKey(requiredState)) {
      throw ArgumentError(
        'Missing required state: "$requiredState". All views must define loading, error, and data states.',
      );
    }
  }

  // All state keys must be snake_case: ^[a-z][a-z0-9_]*$
  final snakeCasePattern = RegExp(r'^[a-z][a-z0-9_]*$');
  for (final stateKey in config.states.keys) {
    if (!snakeCasePattern.hasMatch(stateKey)) {
      throw ArgumentError(
        'State key must be snake_case (e.g., "ipv6_enabled"). Got: "$stateKey"',
      );
    }
  }

  // All interaction keys must be snake_case
  if (config.interactions != null) {
    for (final interactionKey in config.interactions!.keys) {
      if (!snakeCasePattern.hasMatch(interactionKey)) {
        throw ArgumentError(
          'Interaction key must be snake_case (e.g., "toggle_ipv6"). Got: "$interactionKey"',
        );
      }
    }
  }
}

/// Pumps the widget wrapped in the appropriate shell and MaterialApp.
///
/// Internal helper that:
/// 1. Wraps the child widget based on ShellType
/// 2. Wraps in ProviderScope with overrides
/// 3. Wraps in MaterialApp with locale and localization delegates
/// 4. Pumps using golden_toolkit's pumpWidgetBuilder
Future<void> _pumpWidgetInShell(
  WidgetTester tester,
  Widget child,
  ShellType shell,
  List<Override> overrides,
  Size screenSize,
  Locale locale,
) async {
  // Step 1: Wrap child based on ShellType
  Widget wrappedChild;
  switch (shell) {
    case ShellType.pageView:
      wrappedChild = UiKitPageView.withSliver(
        scrollable: true,
        child: (_, __) => child,
      );
      break;
    case ShellType.scaffold:
      wrappedChild = Scaffold(body: child);
      break;
    case ShellType.custom:
      wrappedChild = child;
      break;
  }

  // Step 2: Wrap in MaterialApp with locale and localization
  wrappedChild = MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: wrappedChild,
  );

  // Step 3: Wrap in ProviderScope (outermost — providers must be above MaterialApp)
  wrappedChild = ProviderScope(
    overrides: overrides,
    child: wrappedChild,
  );

  // Step 4: Pump using golden_toolkit
  await tester.pumpWidgetBuilder(
    wrappedChild,
    surfaceSize: screenSize,
  );
}
