import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/safe_browsing_test_state.dart';
import '../../../../mocks/instant_safety_notifier_mocks.dart';

void main() {
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  late InstantSafetyNotifier mockInstantSafetyNotifier;

  setUp(() {
    mockInstantSafetyNotifier = MockInstantSafetyNotifier();
    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState));
    when(mockInstantSafetyNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return InstantSafetyState.fromMap(instantSafetyTestState);
    });
  });

  testLocalizations('Instant safety view - on', (tester, locale) async {
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
}
