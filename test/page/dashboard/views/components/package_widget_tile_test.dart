/// #1395 AC2 — the second thing 2.3.1's tile-content cache broke: a package
/// card's template arrives after the tile that needs it was built.
///
/// The page used to look the template up with `ref.read` inside `itemBuilder`,
/// with a `ref.watch` at the top of its `build` so the templates landing brought
/// the page back. On 0.9.1 that re-ran `itemBuilder` and the placeholder was
/// replaced. On 2.3.1 it does not: `DashboardItem` caches what `itemBuilder`
/// returned and invalidates the cache only on a content-signature or dimension
/// change (`dashboard_item_widget.dart:487`, `:239`). The templates come over
/// HTTP a moment after the grid is laid out, so the placeholder became permanent
/// — every load, every package card reading "unknown widget" until the user
/// happened to move or resize one.
///
/// [PackageWidgetTile] resolves the template itself, below that cache boundary.
/// These tests pump the tile with nothing above it that reacts to the loader,
/// which is the situation a cached tile is in.
///
/// ## Mutation table
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | package_widget_tile | `ref.read` instead of `ref.watch` (what the page used to do) | 'a template arriving after the tile was built still reaches it' |
/// | 2 | package_widget_tile | render the template without checking for null | 'a card with no template shows the placeholder, not a crash' |
/// | 3 | package_widget_tile | keep the placeholder once shown (cache the first answer in a field) | 'a template arriving after the tile was built still reaches it' |
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/views/components/package_widget_tile.dart';
import 'package:privacy_gui/page/dashboard/widgets/package_widget_renderer.dart';
import 'package:ui_kit_library/ui_kit.dart';

final _theme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// A loader that starts out loading and is completed by the test.
///
/// The real one awaits `appsCapabilityProvider` and then fetches `/api/apps.json`
/// and one URL per widget; what matters here is only *when* the map arrives, so
/// the subclass keeps the provider — and the tile's `select` on it — real.
class _TestLoader extends PackageWidgetLoader {
  @override
  Future<Map<String, PackageWidgetTemplate>> build() async {
    // Never completes on its own: the test decides when the templates land.
    return Completer<Map<String, PackageWidgetTemplate>>().future;
  }

  void land(Map<String, PackageWidgetTemplate> templates) =>
      state = AsyncData(templates);
}

/// The smallest template that renders: no subscription and no data source, so
/// [PackageWidgetRenderer] fetches nothing and shows its loading card.
PackageWidgetTemplate _template(String id) => PackageWidgetTemplate.fromJson({
      'widgetId': id,
      'displayName': 'Test package widget',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpTile(WidgetTester tester, String id) async {
    final container = ProviderContainer(overrides: [
      packageWidgetLoaderProvider.overrideWith(_TestLoader.new),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PackageWidgetTile(itemId: id)),
      ),
    ));
    return container;
  }

  testWidgets('a card with no template shows the placeholder, not a crash',
      (tester) async {
    await pumpTile(tester, 'pkg_absent');

    expect(find.byType(PackageWidgetRenderer), findsNothing);
    expect(find.textContaining('pkg_absent'), findsOneWidget,
        reason: 'the placeholder names the id, which is the only clue a user '
            'has that a card belongs to a package that is gone');
  });

  testWidgets('a template arriving after the tile was built still reaches it',
      (tester) async {
    final container = await pumpTile(tester, 'pkg_late');
    final element = tester.element(find.byType(PackageWidgetTile));

    expect(find.byType(PackageWidgetRenderer), findsNothing,
        reason: 'the premise: the templates have not landed yet, which is the '
            'state every load starts in');

    (container.read(packageWidgetLoaderProvider.notifier) as _TestLoader)
        .land({'pkg_late': _template('pkg_late')});
    await tester.pump();

    expect(find.byType(PackageWidgetRenderer), findsOneWidget,
        reason: 'the tile watches the loader itself');
    expect(find.textContaining('pkg_late'), findsNothing,
        reason: 'and the placeholder is gone with it');
    expect(tester.element(find.byType(PackageWidgetTile)), same(element),
        reason: 'without being remounted — which is what the package cache '
            'leaves a tile in, and what the page rebuild could not fix');
  });

  testWidgets('a template landing for another card leaves this one alone',
      (tester) async {
    final container = await pumpTile(tester, 'pkg_mine');

    (container.read(packageWidgetLoaderProvider.notifier) as _TestLoader)
        .land({'pkg_theirs': _template('pkg_theirs')});
    await tester.pump();

    expect(find.byType(PackageWidgetRenderer), findsNothing);
    expect(find.textContaining('pkg_mine'), findsOneWidget);
  });
}
