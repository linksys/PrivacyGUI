import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:get_it/get_it.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../common/di.dart';
import '../../../../../test_data/administration_settings_test_state.dart';
import '../../../../../mocks/administration_setting_notifier_mocks.dart';

void main() {
  late AdministrationSettingsNotifier mockAdministrationSettingsNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I.get<ServiceHelper>();
  setUp(() {
    mockAdministrationSettingsNotifier = MockAdministrationSettingsNotifier();
    when(mockAdministrationSettingsNotifier.build()).thenReturn(
        AdministrationSettingsState.fromMap(administrationSettingsTestState));
    when(mockAdministrationSettingsNotifier.fetch())
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
            .copyWith(canDisAllowLocalMangementWirelessly: false));
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
