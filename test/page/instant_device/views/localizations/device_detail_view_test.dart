import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/_index.dart';
import '../../../../test_data/device_details_test_state.dart';
import '../../../../test_data/local_network_settings_state.dart';

void main() {
  late ExternalDeviceDetailNotifier mockExternalDeviceDetailNotifier;
  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;

  setUp(() {
    mockExternalDeviceDetailNotifier = MockExternalDeviceDetailNotifier();
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
  });
  testLocalizations('Instant-Device - Device detail view ',
      (tester, locale) async {
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1080)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Instant-Device - Device detail view - signal good ',
      (tester, locale) async {
    final externalState =
        ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
    final goodSignalItem = externalState.item.copyWith(signalStrength: -68);
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(externalState.copyWith(item: goodSignalItem));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1080)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Instant-Device - Device detail view - signal fair ',
      (tester, locale) async {
    final externalState =
        ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
    final goodSignalItem = externalState.item.copyWith(signalStrength: -74);
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(externalState.copyWith(item: goodSignalItem));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1080)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Instant-Device - Device detail view - signal poor ',
      (tester, locale) async {
    final externalState =
        ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
    final goodSignalItem = externalState.item.copyWith(signalStrength: -81);
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(externalState.copyWith(item: goodSignalItem));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1080)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Instant-Device - Device detail view - ethernet',
      (tester, locale) async {
    final externalState =
        ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
    final goodSignalItem = externalState.item.copyWith(isWired: true);
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(externalState.copyWith(item: goodSignalItem));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1080)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Instant-Device - Device detail view - edit modal ',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Instant-Device - Device detail view - edit modal - invalid name error',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
    final inputFinder = find.byType(AppTextField);
    await tester.enterText(inputFinder.first, '');
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Instant-Device - Device detail view - edit modal - max length error',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
    final inputFinder = find.byType(AppTextField);
    await tester.enterText(inputFinder.first,
        'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz');
    await tester.pumpAndSettle();
  });

  testLocalizations(
    'Instant-Device - Device detail view - reserve IP confirm ',
    (tester, locale) async {
      when(mockLocalNetworkSettingsNotifier.saveSettings(any))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
      });
      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          externalDeviceDetailProvider
              .overrideWith(() => mockExternalDeviceDetailNotifier),
        ],
        locale: locale,
        child: const DeviceDetailView(),
      );
      await tester.pumpWidget(widget);

      final btnFinder = find.byType(AppTextButton).first;
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations('Instant-Device - Device detail view - release IP ',
      (tester, locale) async {
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState)
            .copyWith(dhcpReservationList: [
      DHCPReservation(
        macAddress: '3C:22:FB:E4:4F:18',
        ipAddress: '192.168.1.30',
        description: 'My laptop',
      )
    ]));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations(
    'Instant-Device - Device detail view - release IP confirm ',
    (tester, locale) async {
      when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState)
              .copyWith(dhcpReservationList: [
        DHCPReservation(
          macAddress: '3C:22:FB:E4:4F:18',
          ipAddress: '192.168.1.30',
          description: 'My laptop',
        )
      ]));
      when(mockLocalNetworkSettingsNotifier.saveSettings(any))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
      });
      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          externalDeviceDetailProvider
              .overrideWith(() => mockExternalDeviceDetailNotifier),
        ],
        locale: locale,
        child: const DeviceDetailView(),
      );
      await tester.pumpWidget(widget);

      final btnFinder = find.byType(AppTextButton).first;
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations('Instant-Device - Device detail view - MLO label ',
      (tester, locale) async {
    final externalState =
        ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
    final mloItem = externalState.item.copyWith(isMLO: true);
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(externalState.copyWith(item: mloItem));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('Instant-Device - Device detail view - MLO modal ',
      (tester, locale) async {
    final externalState =
        ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
    final mloItem = externalState.item.copyWith(isMLO: true);
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(externalState.copyWith(item: mloItem));
    final widget = testableSingleRoute(
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
      ],
      locale: locale,
      child: const DeviceDetailView(),
    );
    await tester.pumpWidget(widget);
    final mloBtnFinder = find.byType(AppTextButton).first;
    await tester.tap(mloBtnFinder);
    await tester.pumpAndSettle();
  });
}
