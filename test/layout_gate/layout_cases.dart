/// Layout tests declared from the same cases as the screenshot tests (#1802).
///
/// `testLocalizations` declares each case's screenshot tests and hands the
/// same case to [declareLayoutCases]. The screenshot tests are unchanged; the
/// tests declared here pump the same case, make no golden check, and collect
/// overflows instead: the gate's tests always (P3), and the measuring tests
/// when [layoutMeasure] is on (P2).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import '../common/config.dart';
import '../common/screen.dart';
import '../common/test_responsive_widget.dart';
import '../common/theme_data.dart';
import 'collector.dart';
import 'gate.dart';
import 'incident.dart';
import 'measure_record.dart';

/// `--dart-define=layoutMeasure=true` declares the measuring tests (#1802 P2).
/// Without it, which is every ordinary run, nothing is declared here.
const bool layoutMeasure = bool.fromEnvironment('layoutMeasure');

/// Declares the layout tests for one case: its gate tests ([_declareGate]), and
/// its measuring tests when [layoutMeasure] is on.
///
/// The measuring tests: one per locale in [locales] and size from
/// [measuringScreensFor]: the
/// case's own sizes, or the sizes `--dart-define=screens=` asks for. Each is
/// tagged `layout-measure`, not `loc`, so a run that leaves out `golden` and
/// `loc` (constitution 3.1) can select it. Each prints a [MeasureRecord]. An
/// overflow does not fail the test; anything else still does.
@isTest
void declareLayoutCases(
  String name,
  FutureOr<void> Function(WidgetTester, Locale) testMain, {
  required List<Locale> locales,
  List<ScreenSize>? screens,
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  Future<void> Function(WidgetTester tester)? onCompleted,
}) {
  _declareGate(
    name,
    testMain,
    locales: locales,
    screens: screens,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    onCompleted: onCompleted,
  );
  if (!layoutMeasure) return;
  final caseScreens = screens ?? responsiveAllScreens;
  final requested = requestedScreens;
  final sizes = requested == null
      ? [
          for (final s in caseScreens)
            _measuringScreen(_sizeName(s.width, s.height), s.width, s.height),
        ]
      : measuringScreensFor(caseScreens, requested);
  if (locales.isEmpty || sizes.isEmpty) return;

  final variants = ValueVariant({
    for (final locale in locales)
      for (final size in sizes)
        LocalizedScreen.fromScreenSize(locale: locale, screen: size),
  });
  testWidgets(
    name,
    (tester) async {
      final current = variants.currentValue!;
      await loadTestFonts();
      await tester.setScreenSize(current);
      var incidents = <OverflowIncident>[];
      var threw = true;
      try {
        await runWithOverflowCollection((sink) async {
          incidents = sink;
          await testMain(tester, current.locale);
          if (onCompleted != null) {
            await onCompleted(tester);
          } else {
            // The same settling pump the screenshot tests end with.
            await tester.pump(const Duration(seconds: 5));
          }
        });
        threw = false;
      } finally {
        final record = MeasureRecord(
          caseName: name,
          locale: current.locale.toLanguageTag(),
          size: current.name,
          width: current.width,
          height: current.height,
          threw: threw,
          incidents: incidents,
        );
        // The record is the test's output; the JSON reporter keeps it.
        // ignore: avoid_print
        print('$measureRecordPrefix${jsonEncode(record.toJson())}');
      }
    },
    variant: variants,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: ['layout-measure'],
  );
}

/// Declares the gate's tests for one case (#1802 P3): one per locale from
/// [gateLocalesFor] and size from [gateScreensFor], tagged `layout-gate`, not
/// `loc`, so the runs in constitution 3.1 select them. A test fails when the
/// case overflows by more than the tolerance ([gateFailures]), and on anything
/// else that fails the case.
void _declareGate(
  String name,
  FutureOr<void> Function(WidgetTester, Locale) testMain, {
  required List<Locale> locales,
  List<ScreenSize>? screens,
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  Future<void> Function(WidgetTester tester)? onCompleted,
}) {
  final sizes = gateScreensFor(name, screens ?? responsiveAllScreens);
  final caseGateLocales =
      gateLocalesFor(locales, localesDefined: hasLocaleConfig);
  if (sizes.isEmpty || caseGateLocales.isEmpty) return;

  final variants = ValueVariant({
    for (final locale in caseGateLocales)
      for (final size in sizes)
        LocalizedScreen.fromScreenSize(locale: locale, screen: size),
  });
  testWidgets(
    name,
    (tester) async {
      final current = variants.currentValue!;
      await loadTestFonts();
      await tester.setScreenSize(current);
      final incidents = await runWithOverflowCollection((sink) async {
        await testMain(tester, current.locale);
        if (onCompleted != null) {
          await onCompleted(tester);
        } else {
          // The same settling pump the screenshot tests end with.
          await tester.pump(const Duration(seconds: 5));
        }
        return sink;
      });
      final failures = gateFailures(incidents);
      if (failures.isNotEmpty) {
        fail(describeGateFailures(
          failures,
          caseName: name,
          size: current.name,
          locale: current.locale.toLanguageTag(),
        ));
      }
    },
    variant: variants,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: ['layout-gate'],
  );
}

/// The sizes to measure a case at, one per [requested] size whose layout the
/// case renders.
///
/// A case lists the sizes it renders in [caseScreens]: mobile ones, desktop
/// ones, or both, sometimes with a height of its own. A requested width is
/// measured only if the case renders that layout, desktop from
/// [ResponsiveLayout.medium] up, at the height of the case size nearest in
/// width, or at the requested height when there is one.
List<ScreenSize> measuringScreensFor(
  List<ScreenSize> caseScreens,
  List<RequestedScreen> requested,
) {
  bool isDesktop(double width) => width >= ResponsiveLayout.medium;

  return [
    for (final request in requested)
      if (_nearest(
        caseScreens.where((s) => isDesktop(s.width) == isDesktop(request.width)),
        request.width,
      )
          case final nearest?)
        _measuringScreen(
          _sizeName(request.width, request.height),
          request.width,
          request.height ?? nearest.height,
        ),
  ];
}

/// `905`, or `1280x420` when there is a height.
String _sizeName(double width, double? height) =>
    height == null ? '${width.round()}' : '${width.round()}x${height.round()}';

ScreenSize? _nearest(Iterable<ScreenSize> screens, double width) {
  ScreenSize? nearest;
  for (final screen in screens) {
    if (nearest == null ||
        (screen.width - width).abs() < (nearest.width - width).abs()) {
      nearest = screen;
    }
  }
  return nearest;
}

/// A size named after the request it answers, `905` or `1280x420`: cases
/// bring their own heights, so a report grouped by measured height would
/// split one requested width into many rows.
ScreenSize _measuringScreen(String name, double width, double height) =>
    ScreenSize(name, width, height, 1);
