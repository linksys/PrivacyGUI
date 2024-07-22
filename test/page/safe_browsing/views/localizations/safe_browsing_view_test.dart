import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/safe_browsing/providers/_providers.dart';
import 'package:privacy_gui/page/safe_browsing/views/safe_browsing_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/safe_browsing_test_state.dart';
import '../../safe_browsing_view_test_mocks.dart';

@GenerateNiceMocks([MockSpec<SafeBrowsingNotifier>()])
void main() {
  late SafeBrowsingNotifier mockSafeBrowsingNotifier;

  setUp(() {
    mockSafeBrowsingNotifier = MockSafeBrowsingNotifier();
    when(mockSafeBrowsingNotifier.build())
        .thenReturn(SafeBrowsingState.fromMap(safeBrowsingTestState));
    when(mockSafeBrowsingNotifier.fetchLANSettings())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
    });
  });
  testLocalizations('Safe browsing view - off', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SafeBrowsingView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          safeBrowsingProvider.overrideWith(() => mockSafeBrowsingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Safe browsing view - edit', (tester, locale) async {
    when(mockSafeBrowsingNotifier.build())
        .thenReturn(SafeBrowsingState.fromMap(safeBrowsingTestState1));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SafeBrowsingView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          safeBrowsingProvider.overrideWith(() => mockSafeBrowsingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Safe browsing view - fortinet', (tester, locale) async {
    when(mockSafeBrowsingNotifier.build())
        .thenReturn(SafeBrowsingState.fromMap(safeBrowsingTestState1));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SafeBrowsingView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          safeBrowsingProvider.overrideWith(() => mockSafeBrowsingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Safe browsing view - openDNS', (tester, locale) async {
    when(mockSafeBrowsingNotifier.build())
        .thenReturn(SafeBrowsingState.fromMap(safeBrowsingTestState2));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SafeBrowsingView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          safeBrowsingProvider.overrideWith(() => mockSafeBrowsingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Safe browsing view - not supported fortinet',
      (tester, locale) async {
    when(mockSafeBrowsingNotifier.build()).thenReturn(
        SafeBrowsingState.fromMap(safeBrowsingTestStateNotSupported));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SafeBrowsingView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          safeBrowsingProvider.overrideWith(() => mockSafeBrowsingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
  testLocalizations('Safe browsing view - not supported fortinet - edit',
      (tester, locale) async {
    when(mockSafeBrowsingNotifier.build()).thenReturn(
        SafeBrowsingState.fromMap(safeBrowsingTestStateNotSupported));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const SafeBrowsingView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
        locale: locale,
        overrides: [
          safeBrowsingProvider.overrideWith(() => mockSafeBrowsingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });
}
