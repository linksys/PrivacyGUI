import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/page/advanced_settings/administration/_administration.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/di.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../mocks/_index.dart';
import '../../../../../test_data/_index.dart';

void main() {
  late MockAdministrationSettingsNotifier mockAdministrationSettingsNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I.get<ServiceHelper>();
  setUp(() {
    mockAdministrationSettingsNotifier = MockAdministrationSettingsNotifier();
    when(mockAdministrationSettingsNotifier.build()).thenReturn(
        AdministrationSettingsState.fromMap(administrationSettingsTestState));
    when(mockAdministrationSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return AdministrationSettingsState.fromMap(
          administrationSettingsTestState);
    });
  });
  testLocalizations('Administration settings view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const AdministrationSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          administrationSettingsProvider
              .overrideWith(() => mockAdministrationSettingsNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Administration settings view - no LAN ports',
      (tester, locale) async {
    when(mockAdministrationSettingsNotifier.build()).thenReturn(
        AdministrationSettingsState.fromMap(administrationSettingsTestState)
            .copyWith(
                settings: AdministrationSettingsState.fromMap(
                        administrationSettingsTestState)
                    .settings
                    .copyWith(
                        current: AdministrationSettingsState.fromMap(
                                administrationSettingsTestState)
                            .current
                            .copyWith(
                                canDisAllowLocalMangementWirelessly: false))));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const AdministrationSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          administrationSettingsProvider
              .overrideWith(() => mockAdministrationSettingsNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
