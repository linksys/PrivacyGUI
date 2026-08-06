import 'dart:convert';
import 'dart:io';

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
import 'golden_interactions.dart';
import 'golden_test_config.dart';
import 'mocks/mock_common.dart';
import 'overflow_diagnostics.dart';

// Re-export so every test file that imports golden_runner.dart gets the shared
// interaction helpers (switchToTab, settleWithTimeout) without a separate line.
export 'golden_interactions.dart';

/// Reads --dart-define=locales and overrides the config's locale list.
/// Returns config locales if no dart-define is provided.
List<Locale> _resolveLocales(GoldenTestConfig config) {
  const envLocales = String.fromEnvironment('locales');
  if (envLocales.isEmpty) return config.locales;
  return envLocales.split(',').map((s) {
    final parts = s.trim().split('_');
    // Normalize the country code to uppercase so it forms a standard locale
    // (e.g. 'es_ar' -> Locale('es', 'AR')). Flutter's localizations assert on
    // non-standard forms like 'es_ar', and this matches the generated
    // supportedLocales (Locale('es', 'AR'), Locale('zh', 'TW'), ...).
    return parts.length > 1
        ? Locale(parts[0], parts[1].toUpperCase())
        : Locale(parts[0]);
  }).toList();
}

/// Reads --dart-define=screens and overrides the config's device list.
/// Returns config devices if no dart-define is provided.
List<GoldenDevice> _resolveDevices(GoldenTestConfig config) {
  const envScreens = String.fromEnvironment('screens');
  if (envScreens.isEmpty) return config.devices;

  // Don't override configs with custom (non-default) devices —
  // they have specific sizes tailored to their content (e.g., cards).
  final usesCustomDevices = config.devices.any(
    (d) => !GoldenDevice.defaults.any((def) => def.name == d.name),
  );
  if (usesCustomDevices) return config.devices;

  const allDevices = GoldenDevice.defaults;
  return envScreens.split(',').map((s) {
    final width = int.parse(s.trim());
    return allDevices.firstWhere(
      (d) => d.size.width.toInt() == width,
      orElse: () => GoldenDevice('screen$width', Size(width.toDouble(), 800)),
    );
  }).toList();
}

/// Auto-generates golden tests for a view using declarative configuration.
void runViewGoldenTests(GoldenTestConfig config) {
  _validateConfig(config);

  final locales = _resolveLocales(config);
  final devices = _resolveDevices(config);

  group('${config.viewName} golden tests', () {
    tearDownAll(() => _writeOverflowReport());

    for (final stateEntry in config.states.entries) {
      for (final device in devices) {
        for (final locale in locales) {
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
              '${config.viewName} - ${stateEntry.key} - ${device.name} - ${_localeTag(locale)}${theme == Brightness.dark ? ' - dark' : ''}',
              fileName: name,
              constraints: BoxConstraints.expand(
                width: effectiveSize.width,
                height: effectiveSize.height,
              ),
              pumpBeforeTest: (tester) async {
                await _precacheIfNeeded(tester, config);
                await settleWithTimeout(tester);
              },
              pumpWidget: (tester, widget) async {
                _suppressOverflowErrors();
                _currentGoldenName = name;
                await tester.binding.setSurfaceSize(effectiveSize);
                tester.view.physicalSize = effectiveSize;
                tester.view.devicePixelRatio = 1.0;
                // Wrap with Localizations so dialogs using root navigator
                // (showGeneralDialog with useRootNavigator: true) can access
                // AppLocalizations. The widget tree from alchemist's wrapper
                // doesn't include our app's Localizations.
                await tester.pumpWidget(
                  Localizations(
                    locale: locale,
                    delegates: AppLocalizations.localizationsDelegates,
                    child: widget,
                  ),
                );
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
        for (final device in devices) {
          for (final locale in locales) {
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
                '${config.viewName} - ${interactionEntry.key} - ${device.name} - ${_localeTag(locale)}${theme == Brightness.dark ? ' - dark' : ''}',
                fileName: name,
                constraints: BoxConstraints.expand(
                  width: effectiveSize.width,
                  height: effectiveSize.height,
                ),
                pumpBeforeTest: (tester) async {
                  await _precacheIfNeeded(tester, config);
                  await settleWithTimeout(tester);
                  await interactionEntry.value.steps(tester);
                  await settleWithTimeout(tester);
                },
                pumpWidget: (tester, widget) async {
                  _suppressOverflowErrors();
                  _currentGoldenName = name;
                  await tester.binding.setSurfaceSize(effectiveSize);
                  tester.view.physicalSize = effectiveSize;
                  tester.view.devicePixelRatio = 1.0;
                  // Wrap with Localizations so dialogs using root navigator
                  // (showGeneralDialog with useRootNavigator: true) can access
                  // AppLocalizations.
                  await tester.pumpWidget(
                    Localizations(
                      locale: locale,
                      delegates: AppLocalizations.localizationsDelegates,
                      child: widget,
                    ),
                  );
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

/// Precaches images in a real async zone so asset resolution completes.
Future<void> _precacheIfNeeded(
    WidgetTester tester, GoldenTestConfig config) async {
  if (config.precacheImages == null) return;
  await tester.runAsync(() async {
    final element = tester.element(find.byType(MaterialApp));
    for (final image in config.precacheImages!()) {
      await precacheImage(image, element);
    }
  });
}

/// Builds the locale tag used in golden file names and test descriptions.
///
/// Regional variants keep their country code so they don't collide with the
/// base language (e.g. 'es' vs 'es_AR', 'zh' vs 'zh_TW'). The country code is
/// joined with '_' — never '-' — because the report parser splits file names
/// on '-'. This matches Flutter's `Locale.toString()` and the ARB naming.
String _localeTag(Locale locale) {
  final country = locale.countryCode;
  return country == null || country.isEmpty
      ? locale.languageCode
      : '${locale.languageCode}_$country';
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
  final base = '$viewName-$stateKey-${device.name}-${_localeTag(locale)}';
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
            // Force "reduce motion" for every golden so non-deterministic /
            // looping animations (e.g. dashboard JiggleShake) render at a
            // fixed, static frame. Applied inside the app via builder so the
            // views under test actually observe disableAnimations: true
            // (a MediaQuery wrapped outside MaterialApp would be overridden).
            // This does NOT touch the global diffThreshold; it only removes the
            // animation source of flakiness.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            ),
            routerConfig: router,
          ),
        ),
      ),
    ),
  );
}

/// Tracks which golden file is currently being rendered.
String _currentGoldenName = '';

/// Collected overflow records, one per reported error.
///
/// Shape is defined by [buildOverflowRecord]: the golden name, the raw message,
/// and the parsed side/pixels/widget/file/line. Flutter reports overflow per
/// RenderObject, so sibling rows built from a list produce duplicate records;
/// the report generators collapse them.
final List<Map<String, String>> _overflowWarnings = [];

/// Suppresses RenderFlex overflow errors during golden tests but records them.
///
/// Flutter test binding captures these as test failures, but overflow
/// in golden tests is cosmetic (visible in the golden image itself).
/// Must be called per-test because the framework resets FlutterError.onError
/// between tests.
void _suppressOverflowErrors() {
  final originalHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    final isOverflow = details.exceptionAsString().contains('overflowed');
    if (isOverflow) {
      // Record the direction, amount and source location alongside the raw
      // message so the reports can say where and by how much, not just that it
      // happened (#1197). The test process runs from the app root, which is why
      // the relative paths in _writeOverflowReport resolve.
      _overflowWarnings.add(buildOverflowRecord(
        goldenName: _currentGoldenName,
        details: details,
        runDirectory: Directory.current.path,
      ));
      return;
    }
    originalHandler?.call(details);
  };
}

/// Writes collected overflow warnings to JSON for report consumption.
void _writeOverflowReport() {
  if (_overflowWarnings.isEmpty) return;
  final dir = Directory('goldens');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File('goldens/overflow_warnings.json');
  final existing = file.existsSync()
      ? List<Map<String, dynamic>>.from(
          jsonDecode(file.readAsStringSync()) as List)
      : <Map<String, dynamic>>[];
  existing.addAll(_overflowWarnings);
  file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(existing));
  _overflowWarnings.clear();
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
