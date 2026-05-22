import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
            final effectiveHeight = config.height ?? device.size.height;
            final effectiveSize = Size(device.size.width, effectiveHeight);
            final name = _goldenFileName(
              config.viewName,
              stateEntry.key,
              device,
              locale,
              theme,
            );

            goldenTest(
              '${config.viewName} - ${stateEntry.key} - ${device.name} - ${locale.languageCode}${theme == Brightness.dark ? ' - dark' : ''}',
              fileName: name,
              constraints: BoxConstraints.expand(
                width: effectiveSize.width,
                height: effectiveSize.height,
              ),
              pumpBeforeTest: (tester) async {
                for (int i = 0; i < 5; i++) {
                  await tester.pump(const Duration(milliseconds: 50));
                }
              },
              pumpWidget: (tester, widget) async {
                _suppressOverflowErrors();
                await tester.binding.setSurfaceSize(effectiveSize);
                tester.view.physicalSize = effectiveSize;
                tester.view.devicePixelRatio = 1.0;
                await tester.pumpWidget(widget);
              },
              builder: () => _buildGoldenWidget(
                config.view(),
                config.shell,
                stateEntry.value,
                effectiveSize,
                locale,
                theme,
              ),
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
              final effectiveHeight = config.height ?? device.size.height;
              final effectiveSize = Size(device.size.width, effectiveHeight);
              final name = _goldenFileName(
                config.viewName,
                interactionEntry.key,
                device,
                locale,
                theme,
              );

              goldenTest(
                '${config.viewName} - ${interactionEntry.key} - ${device.name} - ${locale.languageCode}${theme == Brightness.dark ? ' - dark' : ''}',
                fileName: name,
                constraints: BoxConstraints.expand(
                  width: effectiveSize.width,
                  height: effectiveSize.height,
                ),
                pumpBeforeTest: (tester) async {
                  for (int i = 0; i < 5; i++) {
                    await tester.pump(const Duration(milliseconds: 50));
                  }
                  await interactionEntry.value.steps(tester);
                  await tester.pump(const Duration(milliseconds: 100));
                },
                pumpWidget: (tester, widget) async {
                  _suppressOverflowErrors();
                  await tester.binding.setSurfaceSize(effectiveSize);
                  tester.view.physicalSize = effectiveSize;
                  tester.view.devicePixelRatio = 1.0;
                  await tester.pumpWidget(widget);
                },
                builder: () => _buildGoldenWidget(
                  config.view(),
                  config.shell,
                  interactionEntry.value.setup,
                  effectiveSize,
                  locale,
                  theme,
                ),
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

Widget _buildGoldenWidget(
  Widget child,
  ShellType shell,
  MockSetup setup,
  Size screenSize,
  Locale locale,
  Brightness brightness,
) {
  final overrides = <Override>[];
  overrides.addAll(commonOverrides());
  setup(overrides);

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

  final themeConfig = ThemeJsonConfig.defaultConfig();

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

  return SizedBox.expand(
    child: _PackageInfoStub(
      child: ProviderScope(
        overrides: overrides,
        child: Portal(
          child: MaterialApp.router(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: themeConfig.createLightTheme(),
            darkTheme: themeConfig.createDarkTheme(),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            routerConfig: router,
          ),
        ),
      ),
    ),
  );
}

/// Suppresses RenderFlex overflow errors during golden tests.
///
/// Flutter test binding captures these as test failures, but overflow
/// in golden tests is cosmetic (visible in the golden image itself).
void _suppressOverflowErrors() {
  final handler = FlutterError.onError;
  FlutterError.onError = (details) {
    final isOverflow = details.exceptionAsString().contains('overflowed');
    if (isOverflow) return;
    handler?.call(details);
  };
}

/// Stubs the package_info platform channel during widget build.
class _PackageInfoStub extends StatefulWidget {
  final Widget child;
  const _PackageInfoStub({required this.child});

  @override
  State<_PackageInfoStub> createState() => _PackageInfoStubState();
}

class _PackageInfoStubState extends State<_PackageInfoStub> {
  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
