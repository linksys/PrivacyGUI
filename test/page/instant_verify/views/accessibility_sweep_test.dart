import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import 'instant_test_harness.dart';

// Accessibility sweep: every Instant-Test screen, opened through its real
// route at desktop and phone width, is checked for
//  1. Flutter's labeled-tap-target and text-contrast guidelines;
//  2. a label and an interactive role on every tappable control;
//  3. no control exposed twice (a tappable inside a tappable with the same
//     label, or two Tab stops on one control);
//  4. Tab from the top reaching every tappable control, with no trap.
//
// The shared TopBar (logo, general settings) is not Instant-Test's and is
// left out of checks 2-4. Its logo is tappable with no role and is not a Tab
// stop; its general-settings icon is a Tab stop with no button role.
//
// Not asserted: androidTapTargetGuideline / iOSTapTargetGuideline. The kit's
// own controls miss them on every page (the page back arrow is 32x32,
// AppTextButton is 40 high, AppTextButton.noPadding and
// AppIconButton.noPadding are 16-24 high, the TopBar settings icon is
// 24x24), and SelectionArea text is reported as a long-press target.

/// A fixed result for the results page.
class _ResultNotifier extends InstantVerifyPivotNotifier {
  _ResultNotifier(this.result);
  final InstantVerifyPivotState result;
  @override
  InstantVerifyPivotState build() => result;
  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {}
}

/// A visible semantics node with its rect in global coordinates.
class _Node {
  _Node(this.node, this.data, this.rect);
  final SemanticsNode node;
  final SemanticsData data;
  final Rect rect;
  bool get tappable => data.hasAction(SemanticsAction.tap);
  String get label => data.label.trim();
  bool flag(SemanticsFlag f) => data.hasFlag(f);
  @override
  String toString() =>
      '"${label.replaceAll('\n', ' | ')}" at ${rect.topLeft} '
      '[${SemanticsFlag.values.where(flag).map((f) => f.name).join(', ')}]';
}

/// Every visible semantics node; merged nodes are folded into their parent.
List<_Node> _nodes(WidgetTester tester) {
  final out = <_Node>[];
  void visit(SemanticsNode node, Matrix4 parentTransform) {
    if (node.isMergedIntoParent) return;
    final transform = parentTransform.clone();
    if (node.transform != null) transform.multiply(node.transform!);
    final data = node.getSemanticsData();
    if (!data.hasFlag(SemanticsFlag.isHidden)) {
      out.add(
          _Node(node, data, MatrixUtils.transformRect(transform, node.rect)));
    }
    if (node.mergeAllDescendantsIntoThisNode) return;
    node.visitChildren((child) {
      visit(child, transform);
      return true;
    });
  }

  for (final view in tester.binding.renderViews) {
    visit(view.owner!.semanticsOwner!.rootSemanticsNode!, Matrix4.identity());
  }
  return out;
}

/// Instant-Test's tappable controls: everything tappable outside the shared
/// TopBar.
List<_Node> _tappable(WidgetTester tester) {
  final shell = find.byType(TopBar).evaluate().isEmpty
      ? Rect.zero
      : tester.getRect(find.byType(TopBar));
  return _nodes(tester)
      .where((n) => n.tappable && !shell.contains(n.rect.center))
      .toList();
}

bool _interactiveRole(_Node n) =>
    n.flag(SemanticsFlag.isButton) ||
    n.flag(SemanticsFlag.isLink) ||
    n.flag(SemanticsFlag.isTextField) ||
    n.flag(SemanticsFlag.hasCheckedState) ||
    n.flag(SemanticsFlag.isInMutuallyExclusiveGroup) ||
    n.flag(SemanticsFlag.hasToggledState);

/// Check 2: each tappable control has a label and an interactive role.
List<String> _roleIssues(List<_Node> tappable) => [
      for (final n in tappable) ...[
        if (n.label.isEmpty) 'no label: $n',
        if (!_interactiveRole(n)) 'no interactive role: $n',
      ]
    ];

/// Check 3: no tappable control holds a tappable node with the same label
/// (a decorative Radio, Checkbox or button inside a tappable row).
List<String> _duplicateIssues(List<_Node> tappable) {
  final issues = <String>[];
  for (final n in tappable) {
    void visit(SemanticsNode child) {
      if (!child.isMergedIntoParent) {
        final data = child.getSemanticsData();
        if (data.hasAction(SemanticsAction.tap) &&
            data.label.trim() == n.label) {
          issues.add('exposed twice: $n');
        }
      }
      child.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    n.node.visitChildren((c) {
      visit(c);
      return true;
    });
  }
  return issues;
}

/// Check 4: Tab from the top of the page reaches every tappable control,
/// every Tab stop is a control a screen reader can name, and focus keeps
/// moving until it wraps around (no trap).
Future<List<String>> _keyboardIssues(
    WidgetTester tester, List<_Node> tappable) async {
  final targets = {for (final n in tappable) n.node.id: n};
  final issues = <String>[];
  final stops = <FocusNode>[];
  final reached = <int>{};
  var wrapped = false;
  for (var i = 0; i < targets.length * 2 + 10 && !wrapped; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = FocusManager.instance.primaryFocus;
    if (stop == null) continue;
    if (stops.isNotEmpty && stops.last == stop) {
      issues.add('focus trap: Tab stays on ${_describeStop(stop)}');
      break;
    }
    wrapped = stops.contains(stop);
    stops.add(stop);
    final focused =
        _nodes(tester).where((n) => n.flag(SemanticsFlag.isFocused));
    if (focused.isEmpty) {
      if (!wrapped) {
        issues.add('Tab stops on something with no accessible node: '
            '${_describeStop(stop)}');
      }
      continue;
    }
    // Check 3 for focus: one control, one Tab stop (a decorative Radio
    // inside a row would be a second stop on the row's node).
    if (!wrapped && !reached.add(focused.last.node.id)) {
      issues.add('exposed twice: second Tab stop on ${focused.last}');
    }
  }
  if (!wrapped && issues.isEmpty) issues.add('Tab never wraps around');
  return [
    ...issues,
    for (final target in targets.entries)
      if (!reached.contains(target.key)) 'Tab never reaches ${target.value}',
  ];
}

/// The public widgets around a focus node, nearest first.
String _describeStop(FocusNode stop) {
  final names = <String>[];
  stop.context?.visitAncestorElements((element) {
    final name = element.widget.runtimeType.toString();
    if (!name.startsWith('_') && !names.contains(name)) names.add(name);
    return names.length < 6;
  });
  return names.join(' < ');
}

class _Screen {
  const _Screen(this.name,
      {this.location = instantTestHome, this.pivot, this.then, this.overflowsOnPhone = false});
  final String name;
  final String location;
  final InstantVerifyPivotNotifier Function()? pivot;

  /// One answer or disclosure after the page opens.
  final Future<void> Function(WidgetTester tester)? then;

  /// Known layout issue under the test font, not an accessibility check.
  final bool overflowsOnPhone;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

String _help(int flow) => '$instantTestHome/help?flow=$flow';

final _screens = <_Screen>[
  // Results page.
  _Screen('results: router busy, found list open',
      then: (t) => _tap(t, find.textContaining('more things we found'))),
  _Screen('results: all clear',
      pivot: () => _ResultNotifier(const InstantVerifyPivotState(
          phase: PivotLoadPhase.complete,
          verdictIsPreliminary: false,
          verdict: Verdict(findings: [], checksRun: 8)))),
  _Screen('results: no internet',
      pivot: () => MockInstantVerifyPivotNotifier(overviewScenario: 0),
      overflowsOnPhone: true),
  _Screen("results: couldn't finish",
      pivot: () => _ResultNotifier(const InstantVerifyPivotState(
          phase: PivotLoadPhase.complete,
          browserTestStep: 'error',
          errorMessage: 'Connection unavailable'))),
  // Help flows, first state and after one answer.
  for (final flow in [1, 2, 3, 31, 32, 4, 5, 6])
    _Screen('help flow $flow', location: _help(flow)),
  _Screen('help flow 1: test details open',
      location: _help(1), then: (t) => _tap(t, find.text('View test details'))),
  _Screen('help flow 2: speed checked',
      location: _help(2), then: (t) => _tap(t, find.text('Check my speed'))),
  _Screen('help flow 3: device not listed',
      location: _help(3),
      then: (t) => _tap(t, find.text("I don't see my device"))),
  _Screen('help flow 31: device chosen',
      location: _help(31), then: (t) => _tap(t, find.text('Devens-MacBook'))),
  _Screen('help flow 32: device chosen',
      location: _help(32), then: (t) => _tap(t, find.text('Devens-MacBook'))),
  _Screen('help flow 4: placement chosen',
      location: _help(4),
      then: (t) => _tap(t, find.text('Near a wall, door, or in a corner'))),
  _Screen('help flow 5: frequency chosen',
      location: _help(5), then: (t) => _tap(t, find.text('Every few minutes'))),
  _Screen('help flow 6: option chosen',
      location: _help(6),
      then: (t) =>
          _tap(t, find.text('Enable bridge mode on the ISP gateway'))),
  // Details pages.
  const _Screen('device details', location: '$instantTestHome/devices'),
  const _Screen('network details', location: '$instantTestHome/network'),
];

void main() {
  mockDependencyRegister();

  // The checks themselves catch the mistakes they are for.
  testWidgets('sweep checks catch a nested duplicate and an unnamed control',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(MaterialApp(
          home: Column(children: [
        Semantics(
          button: true,
          label: 'Pick',
          onTap: () {},
          child: Semantics(
              container: true,
              button: true,
              label: 'Pick',
              onTap: () {},
              child: const SizedBox(width: 48, height: 48)),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
      ])));
      final tappable = _tappable(tester);
      expect(_duplicateIssues(tappable), [contains('"Pick"')]);
      expect(_roleIssues(tappable), [startsWith('no label:')]);
    } finally {
      semantics.dispose();
    }
  });

  for (final width in [1280.0, 390.0]) {
    group('${width.toInt()} wide', () {
      for (final screen in _screens) {
        testWidgets(screen.name, (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await _sweep(tester, screen, width);
          } finally {
            semantics.dispose();
          }
        });
      }
    });
  }
}

/// Opens [screen] through its route at [width] and runs every check.
Future<void> _sweep(WidgetTester tester, _Screen screen, double width) async {
  // Tall enough that every control is on screen without scrolling.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 6000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = instantTestRouter(initialLocation: screen.location);
  addTearDown(router.dispose);
  await tester.pumpWidget(testableRouter(router: router, overrides: [
    instantVerifyPivotProvider
        .overrideWith(screen.pivot ?? MockInstantVerifyPivotNotifier.new),
    browserDiagnosticServiceProvider
        .overrideWithValue(MockBrowserDiagnosticService()),
  ]));
  await tester.pumpAndSettle();
  if (screen.overflowsOnPhone && width < 600) {
    // The WAN-down callout's trailing "What does my light mean?" button does
    // not wrap; under the wide test font it overflows the card at phone
    // width. Reported separately; not one of the checks here.
    expect(tester.takeException().toString(),
        contains('A RenderFlex overflowed'));
  }
  if (screen.then != null) await screen.then!(tester);

  // Check 1, before Tab moves focus highlights around.
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));

  final tappable = _tappable(tester);
  expect(tappable, isNotEmpty);
  // Checks 2-4 together, so one run lists every finding.
  expect([
    ..._roleIssues(tappable),
    ..._duplicateIssues(tappable),
    ...await _keyboardIssues(tester, tappable),
  ], isEmpty);
}
