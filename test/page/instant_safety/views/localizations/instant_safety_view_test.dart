import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/safe_browsing_test_state.dart';
import '../../../../mocks/instant_safety_notifier_mocks.dart';

void main() {
  late InstantSafetyNotifier mockInstantSafetyNotifier;

  setUp(() {
    mockInstantSafetyNotifier = MockInstantSafetyNotifier();
    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState));
    when(mockInstantSafetyNotifier.fetchLANSettings())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
    });
  });
  testLocalizations('Instant safety view - off', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantSafetyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant safety view - edit', (tester, locale) async {
    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState1));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantSafetyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant safety view - fortinet', (tester, locale) async {
    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState1));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantSafetyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant safety view - openDNS', (tester, locale) async {
    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState2));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantSafetyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant safety view - not supported fortinet',
      (tester, locale) async {
    when(mockInstantSafetyNotifier.build()).thenReturn(
        InstantSafetyState.fromMap(instantSafetyTestStateNotSupported));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantSafetyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
  testLocalizations('Instant safety view - not supported fortinet - edit',
      (tester, locale) async {
    when(mockInstantSafetyNotifier.build()).thenReturn(
        InstantSafetyState.fromMap(instantSafetyTestStateNotSupported));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const InstantSafetyView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });
}