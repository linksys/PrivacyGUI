// The USP navigation invariants, behind linksys/PrivacyGUI#1434.
//
// #1420, #1421 and #1435 were four instances of one mistake: a page's entry verb
// and its declared return address disagreed, and nothing checked. Each was fixed
// by hand at one call site. The two suites that came with those fixes say plainly
// that they cannot guard their own production call sites, and the third mirrors
// the route tree by hand. This file is the check they could not be.
//
// Two things make that possible here, and they are deliberately separated:
//
//   1. THE ROUTE TREE IS THE REAL ONE. `uspDashboardRoute` is walked, not
//      re-declared: nesting, paths and locations all come from `lib/`. Re-nest a
//      route and the register below moves. For the behavioural cases the tree is
//      *mirrored* — same names, same paths, same nesting, stub page bodies — so
//      a real navigator can be pumped without a single USP provider.
//   2. THE VERBS ARE READ FROM SOURCE. `goNamed` versus `pushNamed` leaves no
//      runtime trace, so the entry-verb rules scan `lib/` as text. That is the
//      only honest way to assert "this call site uses the right verb", and it is
//      what makes reverting a production one-word fix turn this file red.
//
// Scanner limitations, stated rather than discovered later: only whole-line `//`
// comments are stripped, and block comments are not handled (`lib/` currently
// uses none in the scanned files). A trailing comment holding a navigation call
// would therefore be counted — a false positive that fails loudly, never a
// silent miss.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/route/router_provider.dart';

// ---------------------------------------------------------------------------
// Facts read out of the real route tree
// ---------------------------------------------------------------------------

class _RouteFact {
  /// Route name, i.e. a `RouteNamed.*` value.
  final String name;

  /// The `path:` argument exactly as declared.
  final String path;

  /// Enclosing route's name, or null for a direct child of the shell. A
  /// `ShellRoute` is transparent here: it contributes no path segment, so its
  /// children are top-level locations.
  final String? parent;

  const _RouteFact({required this.name, required this.path, this.parent});

  bool get isNested => parent != null;
}

List<_RouteFact> _walk(RouteBase route, String? parent) {
  final out = <_RouteFact>[];
  if (route is GoRoute) {
    final name = route.name;
    if (name == null) {
      // Not `expect`: this runs while a top-level final is initialising, which
      // can happen outside a test body.
      throw StateError('an unnamed USP route (\'${route.path}\') cannot be '
          'reached with pushNamed and cannot appear in these registers');
    }
    out.add(_RouteFact(name: name, path: route.path, parent: parent));
    for (final child in route.routes) {
      out.addAll(_walk(child, name));
    }
  } else {
    for (final child in route.routes) {
      out.addAll(_walk(child, parent));
    }
  }
  return out;
}

final List<_RouteFact> _tree = _walk(uspDashboardRoute, null);
final Map<String, _RouteFact> _byName = {for (final r in _tree) r.name: r};

/// A router over the REAL tree. Never pumped — only `namedLocation` is used,
/// which is a pure lookup, so no builder and therefore no provider runs.
final GoRouter _realRouter = GoRouter(
  routes: [uspDashboardRoute],
  initialLocation: RoutePath.uspDashboard,
);

// ---------------------------------------------------------------------------
// Facts read out of the source
// ---------------------------------------------------------------------------

/// File contents with whole-line `//` comments blanked out, line numbers intact.
List<String> _codeLines(File file) => file
    .readAsLinesSync()
    .map((line) => line.trimLeft().startsWith('//') ? '' : line)
    .toList();

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

/// Top-level class name -> the file declaring it.
final Map<String, String> _classFile = () {
  final map = <String, String>{};
  final pattern = RegExp(r'^class (\w+)');
  for (final file in _dartFiles('lib')) {
    for (final line in _codeLines(file)) {
      final m = pattern.firstMatch(line);
      if (m != null) map[m.group(1)!] = file.path;
    }
  }
  return map;
}();

/// File -> the `backFallback:` values it declares. A page declares exactly one;
/// the set shape exists so a second, disagreeing declaration fails loudly.
final Map<String, Set<String>> _fileFallbacks = () {
  final map = <String, Set<String>>{};
  final pattern = RegExp(r'backFallback:\s*RouteNamed\.(\w+)');
  for (final file in _dartFiles('lib')) {
    for (final line in _codeLines(file)) {
      final m = pattern.firstMatch(line);
      if (m != null) {
        (map[file.path] ??= <String>{}).add(m.group(1)!);
      }
    }
  }
  return map;
}();

/// Route name -> the view class its builder constructs.
///
/// Read from the route file rather than guessed from the name, because three
/// routes do not follow the naming (`FirmwareUpdateView`, `InstantPrivacyView`,
/// `RouterAssistantView`) and one is reached through an import alias.
final Map<String, String> _routeViewClass = () {
  const routeFile = 'lib/route/route_usp_dashboard.dart';
  final lines = _codeLines(File(routeFile));
  final namePattern = RegExp(r'name: RouteNamed\.(\w+),');
  // `alias.Foo(` / `const Foo(` / `Foo(` — the first constructor call after the
  // name that is not the route wrapper itself.
  final classPattern = RegExp(r'(?:\w+\.)?\b([A-Z]\w*)\(');
  const notAView = {'LinksysRoute', 'LinksysRouteConfig', 'GlobalKey'};

  final map = <String, String>{};
  for (var i = 0; i < lines.length; i++) {
    final nameMatch = namePattern.firstMatch(lines[i]);
    if (nameMatch == null) continue;
    final name = nameMatch.group(1)!;
    // Scan forward until a constructor call turns up. The window is generous
    // because a builder may open with query-parameter plumbing before the view.
    for (var j = i + 1; j < lines.length && j < i + 25; j++) {
      final hits = classPattern
          .allMatches(lines[j])
          .map((m) => m.group(1)!)
          .where((c) => !notAView.contains(c));
      if (hits.isNotEmpty) {
        map[name] = hits.first;
        break;
      }
    }
  }
  return map;
}();

class _NavSite {
  final String file;
  final int line;
  final String verb;
  final String target;

  const _NavSite(this.file, this.line, this.verb, this.target);

  @override
  String toString() => '$file:$line  $verb($target)';
}

/// Every named-navigation call in `lib/` that targets a literal `RouteNamed.*`.
///
/// Matched across line breaks because the formatter wraps most of them, and the
/// line number is recovered from the offset so a failure names the call site.
final List<_NavSite> _navSites = () {
  final pattern = RegExp(
    r'\.(goNamed|pushNamed|replaceNamed|pushReplacementNamed)\(\s*'
    r'RouteNamed\.(\w+)',
  );
  final sites = <_NavSite>[];
  for (final file in _dartFiles('lib')) {
    if (file.path.startsWith('lib/route/')) continue; // the tree, not a caller
    final lines = _codeLines(file);
    final source = lines.join('\n');
    for (final m in pattern.allMatches(source)) {
      final line = source.substring(0, m.start).split('\n').length;
      sites.add(_NavSite(file.path, line, m.group(1)!, m.group(2)!));
    }
  }
  return sites;
}();

// ---------------------------------------------------------------------------
// The mirrored tree: real structure, stub pages
// ---------------------------------------------------------------------------

class _StubPage extends StatelessWidget {
  final String name;

  /// The `backFallback` the real view declares, or null if it declares none.
  /// Mirrors `UiKitPageView`'s wiring (ui_kit_page_view.dart:549-551).
  final String? backFallback;

  const _StubPage({required this.name, this.backFallback});

  static Key backKey(String name) => Key('back_$name');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('PAGE:$name'),
          leading: backFallback == null
              ? null
              : IconButton(
                  key: backKey(name),
                  icon: const Icon(Icons.arrow_back),
                  // The production extension, not a copy of its logic.
                  onPressed: () => context.navigateBack(fallback: backFallback),
                ),
        ),
      );
}

/// Rebuilds [route] with stub bodies, keeping every name, path and nesting.
RouteBase _mirror(RouteBase route, Map<String, String> fallbacks) {
  if (route is GoRoute) {
    final name = route.name!;
    return GoRoute(
      name: name,
      path: route.path,
      builder: (c, s) => _StubPage(name: name, backFallback: fallbacks[name]),
      routes: [for (final c in route.routes) _mirror(c, fallbacks)],
    );
  }
  // A fresh navigator key: reusing `uspShellNavigatorKey` would collide with
  // the real tree's own key once a widget is actually pumped.
  return ShellRoute(
    builder: (c, s, child) => child,
    routes: [for (final c in route.routes) _mirror(c, fallbacks)],
  );
}

/// The routes whose view declares a `backFallback`, restated as a literal.
///
/// Test cases are collected before `setUpAll` runs, so a generated case cannot
/// read the scanned register. The register test asserts this list and the scan
/// agree, which is what keeps the restatement from drifting.
const _fallbackRoutes = <String>[
  // Shell children — nothing to pop from a cold URL, so the fallback fires.
  RouteNamed.uspTopology,
  RouteNamed.uspFirmwareUpdate,
  RouteNamed.uspSystemLog,
  RouteNamed.uspInstantPrivacy,
  RouteNamed.uspAdmin,
  RouteNamed.uspInstantSafety,
  RouteNamed.uspDhcpDetail,
  RouteNamed.uspStatistics,
  RouteNamed.uspWifiSettings,
  RouteNamed.uspApps,
  RouteNamed.uspDeviceList,
  // Nested — the URL parent is always rebuilt, so the fallback is unreachable.
  RouteNamed.uspNodeDetail,
  RouteNamed.uspLocalNetwork,
  RouteNamed.uspFirewall,
  RouteNamed.uspPortForwardingDetail,
  RouteNamed.uspStaticRouting,
  RouteNamed.uspIpv6PortService,
  RouteNamed.uspDmz,
  RouteNamed.uspDeviceDetail,
];

void main() {
  // A plain `test` may run before any `testWidgets`, and building a GoRouter
  // reads the platform dispatcher.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Route name -> declared backFallback, joined through the view class so that
  // neither half is hand-written here.
  final fallbackByRoute = <String, String>{};
  final fallbackFilesWithoutRoute = <String, String>{};

  setUpAll(() {
    final classToRoute = {
      for (final e in _routeViewClass.entries) e.value: e.key
    };
    for (final entry in _fileFallbacks.entries) {
      expect(entry.value, hasLength(1),
          reason: '${entry.key} declares more than one backFallback: '
              '${entry.value} — a page has exactly one return address');
      final fallback = entry.value.single;
      final owner = _classFile.entries
          .where((c) => c.value == entry.key && classToRoute.containsKey(c.key))
          .map((c) => classToRoute[c.key]!);
      if (owner.isEmpty) {
        fallbackFilesWithoutRoute[entry.key] = fallback;
      } else {
        fallbackByRoute[owner.single] = fallback;
      }
    }
  });

  group('#1434 path family: one convention for the path argument', () {
    test('the slash on a path agrees with the route\'s nesting', () {
      final wrong = <String>[];
      for (final route in _tree) {
        final absolute = route.path.startsWith('/');
        if (route.isNested && absolute) {
          wrong.add('${route.name}: nested under ${route.parent} but declared '
              'absolute (\'${route.path}\') — go_router drops the empty segment, '
              'so the declaration reads root-level while the real location is '
              'not');
        }
        if (!route.isNested && !absolute) {
          wrong.add('${route.name}: a shell child declared relative '
              '(\'${route.path}\')');
        }
      }
      expect(wrong, isEmpty, reason: wrong.join('\n'));
    });

    test('the route tree takes its path from RoutePath, never RouteNamed', () {
      // A name and a path are different families with different rules, and
      // conflating them is what made four root-level constants look like valid
      // locations (#1434, #1435). After the fix the two strings are equal for a
      // nested route, so only the source can tell them apart.
      final offenders = <String>[];
      final lines = _codeLines(File('lib/route/route_usp_dashboard.dart'));
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'path: RouteNamed\.').hasMatch(lines[i])) {
          offenders.add('route_usp_dashboard.dart:${i + 1}');
        }
      }
      expect(offenders, isEmpty,
          reason: 'use RoutePath for a path: ${offenders.join(', ')}');
    });
  });

  group('#1434 location register', () {
    test('every route resolves to the location pinned here', () {
      // go_router computes these, so a re-nesting or a changed path shows up as
      // a diff instead of as a back arrow landing somewhere unexpected.
      const expected = <String, String>{
        RouteNamed.uspDashboard: '/uspDashboard',
        RouteNamed.uspMenu: '/uspMenu',
        RouteNamed.uspUnifiedDiagnostics: '/uspMenu/uspUnifiedDiagnostics',
        RouteNamed.uspSupport: '/uspSupport',
        RouteNamed.uspDeviceList: '/uspDeviceList',
        RouteNamed.uspDeviceDetail: '/uspDeviceList/uspDeviceDetail',
        RouteNamed.uspTopology: '/uspTopology',
        RouteNamed.uspNodeDetail: '/uspTopology/uspNodeDetail',
        RouteNamed.uspInstantSafety: '/uspInstantSafety',
        RouteNamed.uspInstantPrivacy: '/uspInstantPrivacy',
        RouteNamed.uspAdmin: '/uspAdmin',
        RouteNamed.uspFirmwareUpdate: '/uspFirmwareUpdate',
        RouteNamed.uspDhcpDetail: '/uspDhcpDetail',
        RouteNamed.uspSystemLog: '/uspSystemLog',
        RouteNamed.uspStatistics: '/uspStatistics',
        RouteNamed.uspAdvancedSettings: '/uspAdvancedSettings',
        RouteNamed.uspInternetSettings:
            '/uspAdvancedSettings/uspInternetSettings',
        RouteNamed.uspLocalNetwork: '/uspAdvancedSettings/uspLocalNetwork',
        RouteNamed.uspFirewall: '/uspAdvancedSettings/uspFirewall',
        RouteNamed.uspDmz: '/uspAdvancedSettings/uspDmz',
        RouteNamed.uspPortForwardingDetail:
            '/uspAdvancedSettings/uspPortForwardingDetail',
        RouteNamed.uspStaticRouting: '/uspAdvancedSettings/uspStaticRouting',
        RouteNamed.uspIpv6PortService:
            '/uspAdvancedSettings/uspIpv6PortService',
        // Debug-only, and tests always run in debug.
        RouteNamed.uspTestConsole: '/uspTestConsole',
        RouteNamed.uspWifiSettings: '/uspWifiSettings',
        RouteNamed.uspApps: '/uspApps',
        RouteNamed.uspAiAssistant: '/uspAiAssistant',
      };

      expect(_byName.keys.toSet(), expected.keys.toSet(),
          reason: 'a route was added or removed — pin its location here');
      final actual = {
        for (final name in expected.keys) name: _realRouter.namedLocation(name),
      };
      expect(actual, expected);
    });
  });

  group('#1434 backFallback register', () {
    test('every declaration belongs to a route that exists', () {
      // `speed_test_view.dart` declares one for a route commented out of the
      // tree (#857, blocked on firmware). Pinned rather than deleted: the value
      // is right and becomes live the day the route comes back.
      expect(
          fallbackFilesWithoutRoute,
          {
            'lib/page/unified_diagnostics/views/speed_test_view.dart':
                RouteNamed.uspMenu,
          },
          reason:
              'a backFallback names a page with no route — either the route '
              'was removed or the view is unreachable');
    });

    test('the declarations are exactly these, and each is classified', () {
      // Reachability is a property of the NESTING, not of the value: a nested
      // route always rebuilds its URL parent, so canPop() is true and
      // navigateBack never reads the fallback. The behavioural group below
      // proves both halves rather than asserting them from this table.
      expect(fallbackByRoute.keys.toSet(), _fallbackRoutes.toSet(),
          reason: 'the scanned register and the generated behavioural cases '
              'must cover the same routes');

      final fires = <String, String>{};
      final dead = <String, String>{};
      for (final entry in fallbackByRoute.entries) {
        (_byName[entry.key]!.isNested ? dead : fires)[entry.key] = entry.value;
      }

      expect(
          fires,
          {
            RouteNamed.uspTopology: RouteNamed.uspMenu,
            RouteNamed.uspFirmwareUpdate: RouteNamed.uspAdmin,
            RouteNamed.uspSystemLog: RouteNamed.uspMenu,
            RouteNamed.uspInstantPrivacy: RouteNamed.uspMenu,
            RouteNamed.uspAdmin: RouteNamed.uspMenu,
            RouteNamed.uspInstantSafety: RouteNamed.uspMenu,
            RouteNamed.uspDhcpDetail: RouteNamed.uspLocalNetwork,
            RouteNamed.uspStatistics: RouteNamed.uspMenu,
            RouteNamed.uspWifiSettings: RouteNamed.uspMenu,
            RouteNamed.uspApps: RouteNamed.uspMenu,
            RouteNamed.uspDeviceList: RouteNamed.uspMenu,
          },
          reason: 'these are shell children, so on a cold URL there is nothing '
              'to pop and the value below IS where back goes');

      expect(
          dead,
          {
            RouteNamed.uspNodeDetail: RouteNamed.uspTopology,
            RouteNamed.uspLocalNetwork: RouteNamed.uspAdvancedSettings,
            RouteNamed.uspFirewall: RouteNamed.uspAdvancedSettings,
            RouteNamed.uspPortForwardingDetail: RouteNamed.uspAdvancedSettings,
            RouteNamed.uspStaticRouting: RouteNamed.uspAdvancedSettings,
            RouteNamed.uspIpv6PortService: RouteNamed.uspFirewall,
            RouteNamed.uspDmz: RouteNamed.uspAdvancedSettings,
            RouteNamed.uspDeviceDetail: RouteNamed.uspDeviceList,
          },
          reason: 'these are nested, so the value is unreachable. Kept, not '
              'deleted: promoting one of them to a shell child makes it live '
              'again, and this table is what forces that to be a decision');
    });
  });

  /// Pumps the mirrored tree starting at [location]. With a nested location this
  /// models a bookmark, a shared link or an F5 — the only situation in which a
  /// fallback can fire at all.
  Future<GoRouter> pumpMirror(WidgetTester t, String location) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [_mirror(uspDashboardRoute, fallbackByRoute)],
    );
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    return router;
  }

  Future<void> tapBack(WidgetTester t, String name) async {
    final button = find.byKey(_StubPage.backKey(name));
    expect(button, findsOneWidget,
        reason: 'PAGE:$name should show a back arrow — it declares a '
            'backFallback');
    await t.tap(button);
    await t.pumpAndSettle();
  }

  group('#1434 backFallback reachability, on a pumped navigator', () {
    Future<GoRouter> coldStart(WidgetTester t, String location) =>
        pumpMirror(t, location);

    // One case per declaration. Every landing below is measured on a real
    // navigator rather than derived from the nesting a second time.
    for (final name in _fallbackRoutes) {
      testWidgets('cold URL onto $name, back lands where its nesting says',
          (t) async {
        final route = _byName[name]!;
        final expectedLanding = route.isNested
            ? route.parent!
            : fallbackByRoute[name]!; // the fallback, which now has to fire

        final router = await coldStart(t, _realRouter.namedLocation(name));
        expect(find.text('PAGE:$name'), findsOneWidget,
            reason: 'the cold URL must land on $name itself');

        await tapBack(t, name);
        expect(find.text('PAGE:$expectedLanding'), findsOneWidget,
            reason: route.isNested
                ? '$name is nested, so the URL parent is in the rebuilt stack, '
                    'canPop() is true and the fallback must NOT fire'
                : '$name is a shell child, so there is nothing to pop and the '
                    'declared fallback must fire');
        expect(router.state.uri.toString(),
            _realRouter.namedLocation(expectedLanding));
      });
    }
  });

  // The source rules below catch the wrong verb. These four say what the wrong
  // verb DID, so the reason for each one-word change is pinned rather than
  // described — and reverting either change turns both halves of its pair red.
  group('#1434 the two entries this fixes, and what they used to do', () {
    testWidgets(
        'Dashboard > Unified Diagnostics > back returns to the Dashboard',
        (t) async {
      final router = await pumpMirror(t, RoutePath.uspDashboard);

      // usp_sliver_dashboard_view.dart's offline banner, post-fix.
      router.pushNamed(RouteNamed.uspUnifiedDiagnostics);
      await t.pumpAndSettle();
      expect(find.text('PAGE:${RouteNamed.uspUnifiedDiagnostics}'),
          findsOneWidget);

      // Diagnostics declares no backFallback; its view hand-rolls
      // `canPop() ? pop() : goNamed(uspMenu)` (unified_diagnostics_view.dart),
      // and this is that first branch.
      router.pop();
      await t.pumpAndSettle();
      expect(find.text('PAGE:${RouteNamed.uspDashboard}'), findsOneWidget,
          reason: 'pushing keeps the Dashboard underneath');
    });

    testWidgets('with goNamed it landed on the Menu, which was never visited',
        (t) async {
      final router = await pumpMirror(t, RoutePath.uspDashboard);

      // The pre-fix call, verbatim.
      router.goNamed(RouteNamed.uspUnifiedDiagnostics);
      await t.pumpAndSettle();
      expect(
          find.text('PAGE:${RouteNamed.uspUnifiedDiagnostics}'), findsOneWidget,
          reason:
              'the page itself was always reachable — that is why this went '
              'unnoticed');

      router.pop();
      await t.pumpAndSettle();
      expect(find.text('PAGE:${RouteNamed.uspMenu}'), findsOneWidget,
          reason: 'Diagnostics is nested under /uspMenu, so `go` rebuilt the '
              'stack as [Menu, Diagnostics] and the Dashboard was gone');
    });

    testWidgets('Dashboard > Apps > back returns to the Dashboard', (t) async {
      final router = await pumpMirror(t, RoutePath.uspDashboard);

      // usp_top_bar.dart's Apps button, post-fix. The top bar is global, so the
      // Dashboard here stands for "wherever the user happened to be".
      router.pushNamed(RouteNamed.uspApps);
      await t.pumpAndSettle();
      expect(find.text('PAGE:${RouteNamed.uspApps}'), findsOneWidget);

      await tapBack(t, RouteNamed.uspApps);
      expect(find.text('PAGE:${RouteNamed.uspDashboard}'), findsOneWidget,
          reason: 'canPop() is now true, so the fallback never fires');
    });

    testWidgets('with goNamed it landed on the Menu instead', (t) async {
      final router = await pumpMirror(t, RoutePath.uspDashboard);

      router.goNamed(RouteNamed.uspApps);
      await t.pumpAndSettle();
      expect(find.text('PAGE:${RouteNamed.uspApps}'), findsOneWidget);

      await tapBack(t, RouteNamed.uspApps);
      expect(find.text('PAGE:${RouteNamed.uspMenu}'), findsOneWidget,
          reason: 'Apps is a shell child, so `go` left nothing to pop and back '
              'fell through to backFallback: uspMenu — from every page');
    });
  });

  group('#1434 entry verb', () {
    /// The one legitimate `goNamed` into a page that declares a return address:
    /// its own declared hub. `goNamed` from the hub replaces the location, so on
    /// the detail page canPop() is false and the fallback fires — landing back
    /// on that same hub. The pair is coherent, which is why the Menu's entries
    /// are not converted; anywhere else, `goNamed` throws the entry point away
    /// and back silently goes to the hub instead (#1420, #1421).
    String? hubFileFor(String routeName) {
      final fallback = fallbackByRoute[routeName];
      if (fallback == null) return null;
      final viewClass = _routeViewClass[fallback];
      return viewClass == null ? null : _classFile[viewClass];
    }

    test('a page with a return address is only replaced-into from its own hub',
        () {
      final offenders = <String>[];
      for (final site in _navSites) {
        if (site.verb == 'pushNamed') continue;
        if (!fallbackByRoute.containsKey(site.target)) continue;
        final hub = hubFileFor(site.target);
        if (site.file == hub) continue;
        offenders.add('$site — ${site.target} declares '
            'backFallback: ${fallbackByRoute[site.target]}, whose page is '
            '${hub ?? '(unresolved)'}');
      }
      expect(offenders, isEmpty,
          reason: 'use pushNamed so back returns to the caller:\n'
              '${offenders.join('\n')}');
    });

    test('nothing is entered from the Dashboard with a replacing verb', () {
      // The Dashboard is the hub of nothing: no page declares a fallback naming
      // it, so a `goNamed` from a dashboard card or the dashboard view always
      // loses the entry point. This is #1421's exact shape.
      final offenders = _navSites
          .where((s) =>
              s.verb != 'pushNamed' &&
              (s.file.startsWith('lib/page/dashboard/') ||
                  s.file.contains('/cards/')) &&
              _byName.containsKey(s.target))
          .map((s) => s.toString())
          .toList();
      expect(offenders, isEmpty,
          reason: 'a dashboard entry must push:\n${offenders.join('\n')}');
    });

    test('no page declares the Dashboard as its return address', () {
      // The premise of the rule above. If one ever did, `goNamed` from the
      // Dashboard would become legitimate for it and the rule would need the
      // same hub exemption.
      expect(fallbackByRoute.values, isNot(contains(RouteNamed.uspDashboard)));
    });

    test('the scanners found the call sites they are supposed to guard', () {
      // A silent scanner regression would make every rule above vacuous, so the
      // shape of the harvest is asserted too.
      expect(_navSites.length, greaterThanOrEqualTo(40),
          reason: 'the navigation scanner found almost nothing — check that '
              'lib/ is on the test working directory');
      expect(_fileFallbacks, hasLength(20),
          reason:
              'the backFallback scanner should see one declaration per page '
              'plus the disabled speed-test view');
      expect(fallbackByRoute, hasLength(19));
      expect(_routeViewClass.keys.toSet(), _byName.keys.toSet(),
          reason:
              'every route in the tree must resolve to a view class, or the '
              'hub exemption cannot be computed');
    });
  });
}
