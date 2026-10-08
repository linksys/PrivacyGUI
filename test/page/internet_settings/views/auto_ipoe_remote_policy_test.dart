import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_state.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_section.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_ipoe_view.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_runtime.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class _PolicyData extends AutoIPoEDataNotifier {
  int resolutions = 0;
  int checks = 0;
  int reads = 0;

  @override
  Future<AutoIPoESnapshot> build() async => AutoIPoETestData.snapshot();

  @override
  Future<void> resolvePending({bool resumePolling = true}) async {
    resolutions++;
  }

  @override
  void continueChecking() => checks++;

  @override
  Future<AutoIPoESnapshot?> refresh() async {
    reads++;
    return state.valueOrNull;
  }
}

class _PolicyPage extends AutoIPoEPageNotifier {
  int saves = 0;

  @override
  AutoIPoEPageState build() => AutoIPoEPageState(
        settings: const Preservable(
          original: AutoIPoETestData.settings,
          current: AutoIPoETestData.settings,
        ),
        status: AutoIPoEPageStatus(snapshot: AutoIPoETestData.snapshot()),
      );

  @override
  Future<AutoIPoEPageState> save() async {
    saves++;
    return state;
  }
}

Finder _button(String id) => find.byWidgetPredicate(
      (widget) => widget is AppButton && widget.identifier == id,
    );

void main() {
  group('Auto-IPoE supported device', _supportedDeviceTests);
}

void _supportedDeviceTests() {
  for (final remote in [false, true]) {
    testWidgets('PnP WAN controls follow the surface policy: remote=$remote',
        (tester) async {
      final data = _PolicyData();
      final page = _PolicyPage();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const PnpIPoEView()),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...commonOverrides(),
          deviceCapabilitiesProvider.overrideWithValue(
              DeviceCapabilities({DeviceCapability.autoIPoE})),
          appModeProfileProvider.overrideWithValue(
            remote ? const RemoteModeProfile() : const LocalModeProfile(),
          ),
          autoIPoEDataProvider.overrideWith(() => data),
          autoIPoEPageProvider.overrideWith(() => page),
        ],
        child: MaterialApp.router(
          theme: AppTheme.create(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pump();
      expect(
          tester
              .widget<AutoIPoESection>(find.byType(AutoIPoESection))
              .isEditing,
          !remote);
      final execute =
          tester.widget<AppButton>(_button('auto-ipoe-pnp-continue'));
      expect(execute.onTap, remote ? isNull : isNotNull);
      expect(page.saves, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'inline recovery only mutates on an editable surface: remote=$remote',
        (tester) async {
      final data = _PolicyData();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...commonOverrides(),
          deviceCapabilitiesProvider.overrideWithValue(
              DeviceCapabilities({DeviceCapability.autoIPoE})),
          appModeProfileProvider.overrideWithValue(
            remote ? const RemoteModeProfile() : const LocalModeProfile(),
          ),
          autoIPoEDataProvider.overrideWith(() => data),
        ],
        child: MaterialApp(
          theme: AppTheme.create(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: Consumer(
                  builder: (context, ref, _) => buildAutoIPoERuntime(
                        context,
                        ref,
                        AutoIPoETestData.snapshot(),
                        AutoIPoEOutcome.pending,
                        const AutoIPoESubmission(AutoIPoETestData.id,
                            reset: false),
                        inline: true,
                      ))),
        ),
      ));
      await tester.pump();
      expect(_button('auto-ipoe-resolve-pending'),
          remote ? findsNothing : findsOneWidget);
      if (!remote) {
        tester.widget<AppButton>(_button('auto-ipoe-resolve-pending')).onTap!();
        await tester.pump();
      }
      expect(data.resolutions, remote ? 0 : 1);
      tester.widget<AppButton>(_button('auto-ipoe-continue-checking')).onTap!();
      await tester.pump();
      expect(data.checks, 1);
      expect(data.reads, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
