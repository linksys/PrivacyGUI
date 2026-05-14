import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'golden_test_config.dart';
import 'mocks/mock_common.dart';

/// Auto-generates golden tests for a view using declarative configuration.
void runViewGoldenTests(GoldenTestConfig config) {
  _validateConfig(config);

  group('${config.viewName} golden tests', () {
    for (final stateEntry in config.states.entries) {
      for (final device in config.devices) {
        for (final locale in config.locales) {
          for (final theme in config.themes) {
            final name = _goldenFileName(
              config.viewName,
              stateEntry.key,
              device,
              locale,
              theme,
            );

            testGoldens(
              '${config.viewName} - ${stateEntry.key} - ${device.name} - ${locale.languageCode}${theme == Brightness.dark ? ' - dark' : ''}',
              (tester) async {
                final overrides = <Override>[];
                overrides.addAll(commonOverrides());
                stateEntry.value(overrides);

                await _pumpWidgetInShell(
                  tester,
                  config.view(),
                  config.shell,
                  overrides,
                  device.size,
                  locale,
                  theme,
                );

                await screenMatchesGolden(
                  tester,
                  name,
                  customPump: (tester) async {
                    await tester.pump(const Duration(milliseconds: 100));
                  },
                );
              },
            );
          }
        }
      }
    }

    if (config.interactions != null) {
      for (final interactionEntry in config.interactions!.entries) {
        for (final device in config.devices) {
          for (final locale in config.locales) {
            for (final theme in config.themes) {
              final name = _goldenFileName(
                config.viewName,
                interactionEntry.key,
                device,
                locale,
                theme,
              );

              testGoldens(
                '${config.viewName} - ${interactionEntry.key} - ${device.name} - ${locale.languageCode}${theme == Brightness.dark ? ' - dark' : ''}',
                (tester) async {
                  final overrides = <Override>[];
                  overrides.addAll(commonOverrides());
                  interactionEntry.value.setup(overrides);

                  await _pumpWidgetInShell(
                    tester,
                    config.view(),
                    config.shell,
                    overrides,
                    device.size,
                    locale,
                    theme,
                  );

                  await interactionEntry.value.steps(tester);

                  await screenMatchesGolden(
                    tester,
                    name,
                    customPump: (tester) async {
                      await tester.pump(const Duration(milliseconds: 100));
                    },
                  );
                },
              );
            }
          }
        }
      }
    }
  });
}

/// Generates the golden file name.
///
/// Format: {viewName}-{stateKey}-{device}-{locale}.png
/// Dark mode appends '-dark' suffix.
String _goldenFileName(
  String viewName,
  String stateKey,
  GoldenDevice device,
  Locale locale,
  Brightness theme,
) {
  final base = '$viewName-$stateKey-${device.name}-${locale.languageCode}';
  if (theme == Brightness.dark) {
    return '$base-dark';
  }
  return base;
}

void _validateConfig(GoldenTestConfig config) {
  final snakeCasePattern = RegExp(r'^[a-z][a-z0-9_]*$');

  if (!snakeCasePattern.hasMatch(config.viewName)) {
    throw ArgumentError(
      'viewName must be snake_case (e.g., "firewall"). Got: "${config.viewName}"',
    );
  }

  if (config.states.isEmpty) {
    throw ArgumentError(
      'states must contain at least one entry (e.g., "data").',
    );
  }

  for (final stateKey in config.states.keys) {
    if (!snakeCasePattern.hasMatch(stateKey)) {
      throw ArgumentError(
        'State key must be snake_case (e.g., "ipv6_enabled"). Got: "$stateKey"',
      );
    }
  }

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

Future<void> _pumpWidgetInShell(
  WidgetTester tester,
  Widget child,
  ShellType shell,
  List<Override> overrides,
  Size screenSize,
  Locale locale,
  Brightness brightness,
) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'PrivacyGUI',
          'packageName': 'com.linksys.privacygui',
          'version': '0.0.0',
          'buildNumber': '0',
        };
      }
      return null;
    },
  );

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

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      LinksysRoute(
        path: '/',
        name: 'test_root',
        builder: (context, state) => wrappedChild,
      ),
    ],
  );

  final themeConfig = ThemeJsonConfig.defaultConfig();
  Widget app = MaterialApp.router(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: themeConfig.createLightTheme(),
    darkTheme: themeConfig.createDarkTheme(),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    routerConfig: router,
  );

  app = ProviderScope(
    overrides: overrides,
    child: app,
  );

  await tester.pumpWidgetBuilder(
    app,
    wrapper: (child) => child,
    surfaceSize: screenSize,
  );
}
