import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/views/remote_aware_switch.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
import 'package:ui_kit_library/ui_kit.dart';

// Test helper to create AuthNotifier with specific state
class TestAuthNotifier extends AuthNotifier {
  final AsyncValue<AuthState> testState;

  TestAuthNotifier(this.testState);

  @override
  Future<AuthState> build() async {
    state = testState;
    return testState.when(
      data: (data) => data,
      loading: () => AuthState.empty(),
      error: (_, __) => AuthState.empty(),
    );
  }
}

void main() {
  group('RemoteAwareSwitch', () {
    testWidgets('is enabled in local mode', (WidgetTester tester) async {
      bool? callbackValue;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => TestAuthNotifier(
                  const AsyncValue.data(
                    AuthState(loginType: LoginType.local),
                  ),
                )),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                GlassDesignTheme.light(),
              ],
            ),
            home: Scaffold(
              body: RemoteAwareSwitch(
                value: false,
                onChanged: (value) {
                  callbackValue = value;
                },
              ),
            ),
          ),
        ),
      );

      // Find the switch
      final switchFinder = find.byType(AppSwitch);
      expect(switchFinder, findsOneWidget);

      // Get the switch widget
      final appSwitch = tester.widget<AppSwitch>(switchFinder);

      // Verify onChanged is not null (enabled)
      expect(appSwitch.onChanged, isNotNull);

      // Trigger the callback
      appSwitch.onChanged?.call(true);

      // Verify callback was invoked
      expect(callbackValue, true);
    });

    testWidgets('is disabled in remote mode', (WidgetTester tester) async {
      bool? callbackValue;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => TestAuthNotifier(
                  const AsyncValue.data(
                    AuthState(loginType: LoginType.remote),
                  ),
                )),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                GlassDesignTheme.light(),
              ],
            ),
            home: Scaffold(
              body: RemoteAwareSwitch(
                value: false,
                onChanged: (value) {
                  callbackValue = value;
                },
              ),
            ),
          ),
        ),
      );

      // Find the switch
      final switchFinder = find.byType(AppSwitch);
      expect(switchFinder, findsOneWidget);

      // Get the switch widget
      final appSwitch = tester.widget<AppSwitch>(switchFinder);

      // Verify onChanged is null (disabled)
      expect(appSwitch.onChanged, isNull);
    });
  });
}
