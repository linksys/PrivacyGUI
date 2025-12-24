import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/guest_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/mock_pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';

import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_password_widget.dart'; // NEW IMPORT
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart'; // NEW IMPORT
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/_index.dart';

// A wrapper widget to correctly handle the lifecycle of the onInit call.
class InitOnceWrapper extends ConsumerStatefulWidget {
  final GuestWiFiStep step;
  const InitOnceWrapper({Key? key, required this.step}) : super(key: key);

  @override
  ConsumerState<InitOnceWrapper> createState() => _InitOnceWrapperState();
}

class _InitOnceWrapperState extends ConsumerState<InitOnceWrapper> {
  @override
  void initState() {
    super.initState();
    widget.step.onInit(ref);
  }

  @override
  Widget build(BuildContext context) {
    return widget.step.content(context: context, ref: ref);
  }
}

void main() {
  group('GuestWiFiStep Robust Tests', () {
    late BaseMockPnpNotifier testPnpNotifier;
    late ProviderContainer container;
    late GuestWiFiStep guestWiFiStep;
    WidgetRef? capturedRef;

    setUp(() {
      guestWiFiStep = GuestWiFiStep();
      testPnpNotifier = BaseMockPnpNotifier();
      container = ProviderContainer(
        overrides: [
          pnpProvider.overrideWith(() => testPnpNotifier),
        ],
      );
      capturedRef = null;
    });

    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: mockLightThemeData,
            home: Scaffold(
              body: Consumer(builder: (context, ref, child) {
                capturedRef = ref;
                return InitOnceWrapper(step: guestWiFiStep);
              }),
            ),
          ),
        ),
      );
    }

    PnpStepState getGuestWifiStepState() {
      final pnpState = container.read(pnpProvider);
      final stepState = pnpState.stepStateList[guestWiFiStep.stepId];
      expect(stepState, isNotNull,
          reason: 'PnpStepState for guestWiFiStep should not be null');
      return stepState!;
    }

    // --- Conditional UI Rendering Tests ---
    testWidgets('defaults to disabled and fields are hidden', (tester) async {
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Assert switch is off
      final appSwitch = tester.widget<AppSwitch>(find.byType(AppSwitch));
      expect(appSwitch.value, isFalse);

      // Assert TextFields are not found
      expect(
          find.byType(WiFiSSIDField), findsNothing); // Use specific widget type
      expect(find.byType(WiFiPasswordField),
          findsNothing); // Use specific widget type
    });

    testWidgets('shows fields when enabled and becomes invalid',
        (tester) async {
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Act: tap the switch to enable
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      // NEW: Clear the text fields to make them truly empty for validation
      await tester.enterText(find.byType(WiFiSSIDField), '');
      await tester.enterText(find.byType(WiFiPasswordField), '');
      await tester.pumpAndSettle(); // trigger changed events and validation

      // Assert: TextFields are now visible
      expect(find.byType(WiFiSSIDField), findsOneWidget);
      expect(find.byType(WiFiPasswordField), findsOneWidget);

      // Assert: Step becomes invalid because new fields are empty
      final stepState = getGuestWifiStepState();
      expect(stepState.status, StepViewStatus.error);
    });

    testWidgets('hides fields when disabled and becomes valid', (tester) async {
      // Arrange: start with the switch enabled and fields cleared to make it invalid
      await pumpWidget(tester);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(WiFiSSIDField), '');
      await tester.enterText(find.byType(WiFiPasswordField), '');
      await tester.pumpAndSettle(); // trigger changed events and validation

      expect(getGuestWifiStepState().status,
          StepViewStatus.error); // Verify it's invalid

      // Act: tap the switch to disable
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      // Assert: TextFields are hidden again
      expect(find.byType(WiFiSSIDField), findsNothing);
      expect(find.byType(WiFiPasswordField), findsNothing);

      // Assert: Step becomes valid as there are no fields to validate
      final stepState = getGuestWifiStepState();
      expect(stepState.status, StepViewStatus.data);
    });

    // --- State Preservation Test ---
    testWidgets('preserves input values when toggling off and on',
        (tester) async {
      // Arrange: enable and enter text
      await pumpWidget(tester);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(WiFiSSIDField), 'MyGuestSSID');
      await tester.enterText(
          find.byType(WiFiPasswordField), 'MyGuestPassword123');
      await tester.pumpAndSettle();

      // Act: toggle off and on again
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      // Assert: the text is still there
      expect(find.text('MyGuestSSID'), findsOneWidget);
      expect(find.text('MyGuestPassword123'), findsOneWidget);
    });

    // --- onNext Data Structure Tests ---
    testWidgets('onNext returns only isEnabled:false when disabled',
        (tester) async {
      // Arrange: ensure switch is off
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Act: call onNext
      expect(capturedRef, isNotNull);
      final result = await guestWiFiStep.onNext(capturedRef!);

      // Assert
      expect(result, {'isEnabled': false});
    });

    testWidgets('onNext returns all data when enabled', (tester) async {
      // Arrange: enable and enter valid data
      await pumpWidget(tester);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(WiFiSSIDField), 'MyGuestSSID');
      await tester.enterText(
          find.byType(WiFiPasswordField), 'MyGuestPassword123');
      await tester.pumpAndSettle();

      // Act: call onNext
      expect(capturedRef, isNotNull);
      final result = await guestWiFiStep.onNext(capturedRef!);

      // Assert
      expect(result, {
        'isEnabled': true,
        'ssid': 'MyGuestSSID',
        'password': 'MyGuestPassword123',
      });
    });
  });
}
