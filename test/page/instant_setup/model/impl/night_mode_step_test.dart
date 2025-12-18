import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/night_mode_step.dart';

import 'package:privacy_gui/page/instant_setup/providers/mock_pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

// A wrapper widget to correctly handle the lifecycle of the onInit call.
class InitOnceWrapper extends ConsumerStatefulWidget {
  final NightModeStep step;
  const InitOnceWrapper({Key? key, required this.step}) : super(key: key);

  @override
  ConsumerState<InitOnceWrapper> createState() => _InitOnceWrapperState();
}

class _InitOnceWrapperState extends ConsumerState<InitOnceWrapper> {
  @override
  void initState() {
    super.initState();
    // Call onInit here. It runs once and has access to a valid ref.
    widget.step.onInit(ref);
  }

  @override
  Widget build(BuildContext context) {
    // The content widget will be rebuilt on state changes, but initState will not be called again.
    return widget.step.content(context: context, ref: ref);
  }
}

void main() {
  group('NightModeStep Widget Tests', () {
    late ProviderContainer container;
    late NightModeStep nightModeStep;
    WidgetRef? capturedRef;

    setUp(() {
      nightModeStep = NightModeStep();
      container = ProviderContainer(
        overrides: [
          pnpProvider.overrideWith(() => BaseMockPnpNotifier()),
        ],
      );
      capturedRef = null; // Reset for each test
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppResponsiveLayout(
              mobile: Scaffold(
                body: Consumer(builder: (context, ref, child) {
                  capturedRef = ref; // Capture the ref
                  return InitOnceWrapper(step: nightModeStep);
                }),
              ),
              desktop: Scaffold(
                body: Consumer(builder: (context, ref, child) {
                  capturedRef = ref; // Capture the ref
                  return InitOnceWrapper(step: nightModeStep);
                }),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('initial state is disabled', (tester) async {
      // Act
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Assert
      final stepState =
          container.read(pnpProvider).stepStateList[nightModeStep.stepId];
      final isEnabled = stepState?.getData<bool>('isEnabled', false) ?? false;
      expect(isEnabled, isFalse);

      final switchWidget = tester.widget<AppSwitch>(find.byType(AppSwitch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('tapping switch toggles isEnabled state and description',
        (tester) async {
      // Arrange
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Get the localization object from the context
      final BuildContext context = tester.element(find.byType(InitOnceWrapper));
      final loc = AppLocalizations.of(context)!;

      final switchWidget = tester.widget<AppSwitch>(find.byType(AppSwitch));

      // Expect switch to be off
      expect(find.byType(AppSwitch).last, findsOneWidget);
      expect(switchWidget.value, isFalse);

      // Assert initial state
      expect(find.text(loc.nightModeOnDesc), findsNothing);
      expect(find.text(loc.nightModeOffDesc), findsOneWidget);

      // Act: Tap the switch to turn it on
      await tester.tap(find.byType(AppSwitch).last);
      await tester.pumpAndSettle();

      // Assert: State is updated
      final validationData = nightModeStep.getValidationData();
      expect(validationData['isEnabled'], isTrue);

      // Assert: UI is updated (description text)
      expect(find.text(loc.nightModeOnDesc), findsOneWidget);
      expect(find.text(loc.nightModeOffDesc), findsNothing);
    });

    testWidgets('onNext returns correct isEnabled state', (tester) async {
      // Arrange
      await pumpWidget(tester);
      await tester.pumpAndSettle();
      expect(capturedRef, isNotNull);

      // Act & Assert for disabled state
      var result = await nightModeStep.onNext(capturedRef!);
      expect(result, {'isEnabled': false});

      // Act: Tap the switch to turn it on
      await tester.tap(find.byType(AppSwitch).last);
      await tester.pumpAndSettle();

      // Act & Assert for enabled state
      result = await nightModeStep.onNext(capturedRef!);
      expect(result, {'isEnabled': true});
    });

    testWidgets('getValidationData returns correct isEnabled state',
        (tester) async {
      // Arrange
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Act & Assert for disabled state
      var data = nightModeStep.getValidationData();
      expect(data, {'isEnabled': false});

      // Act: Tap the switch to turn it on
      await tester.tap(find.byType(AppSwitch).last);
      await tester.pumpAndSettle();

      // Act & Assert for enabled state
      data = nightModeStep.getValidationData();
      expect(data, {'isEnabled': true});
    });
  });
}
