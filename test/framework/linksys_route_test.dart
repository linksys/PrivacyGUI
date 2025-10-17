import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:equatable/equatable.dart';

import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_notifier.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

// --- Mocks and Stubs ---

class TestSettings extends Equatable {
  final String value;
  const TestSettings(this.value);
  @override
  List<Object?> get props => [value];
}

class TestStatus extends Equatable {
  const TestStatus();
  @override
  List<Object?> get props => [];
}

class TestState extends FeatureState<TestSettings, TestStatus> {
  const TestState({required super.settings, required super.status});

  @override
  TestState copyWith({
    Preservable<TestSettings>? settings,
    TestStatus? status,
  }) {
    return TestState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }
}

class TestNotifier extends Notifier<TestState>
    with PreservableNotifierMixin<TestSettings, TestStatus, TestState> {
  @override
  TestState build() {
    return const TestState(
      settings: Preservable(
          original: TestSettings('initial'), current: TestSettings('initial')),
      status: TestStatus(),
    );
  }

  void makeDirty() {
    state = state.copyWith(
      settings: state.settings.update(const TestSettings('dirty')),
    );
  }
}

final testFeatureProvider =
    NotifierProvider<TestNotifier, TestState>(TestNotifier.new);

// Add this new provider to expose the notifier as the correct contract type
final preservableTestProvider = Provider<PreservableContract>((ref) {
  return ref.watch(testFeatureProvider.notifier);
});

// --- Test Screens ---

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(), body: const Text('Home Page'));
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Is Dirty: ${ref.watch(testFeatureProvider).isDirty}'),
            ElevatedButton(
              key: const Key('make_dirty_button'),
              child: const Text('Make Dirty'),
              onPressed: () =>
                  ref.read(testFeatureProvider.notifier).makeDirty(),
            ),
            ElevatedButton(
              key: const Key('go_home_button'),
              child: const Text('Go Home'),
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  GoRouter createTestRouter() {
    return GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        LinksysRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
          preservableProvider: preservableTestProvider,
          enableDirtyCheck: true,
        ),
      ],
    );
  }

  Widget createTestApp(GoRouter router) {
    return ProviderScope(
      child: CustomTheme(
        data: CustomThemeData.regular(),
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
  }

  group('LinksysRoute Integration Test', () {
    // This function will simulate the user's choice in the dialog.
    Future<bool?> mockShowAlert(bool discard) async {
      return discard;
    }

    testWidgets('allows navigation when state is clean', (tester) async {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          LinksysRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
            preservableProvider: preservableTestProvider,
            enableDirtyCheck: true,
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.tap(find.byKey(const Key('go_home_button')));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    }, tags: 'dirty-guard-framework');

    testWidgets('blocks navigation when state is dirty and user cancels', (tester) async {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          LinksysRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
            preservableProvider: preservableTestProvider,
            enableDirtyCheck: true,
            showAlertForTest: (context) async => false, // Simulate user pressing CANCEL
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));

      await tester.tap(find.byKey(const Key('make_dirty_button')));
      await tester.pump();
      expect(find.text('Is Dirty: true'), findsOneWidget);

      await tester.tap(find.byKey(const Key('go_home_button')));
      await tester.pumpAndSettle();

      // Verify we are still on the settings page
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Home Page'), findsNothing);
    }, tags: 'dirty-guard-framework');

    testWidgets('allows navigation when state is dirty and user confirms', (tester) async {
      final container = ProviderContainer();
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          LinksysRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
            preservableProvider: preservableTestProvider,
            enableDirtyCheck: true,
            showAlertForTest: (context) async => true, // Simulate user pressing DISCARD
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(router),
        ),
      );

      await tester.tap(find.byKey(const Key('make_dirty_button')));
      await tester.pump();
      expect(find.text('Is Dirty: true'), findsOneWidget);

      await tester.tap(find.byKey(const Key('go_home_button')));
      await tester.pumpAndSettle();

      // Verify navigation was successful
      expect(find.text('Home Page'), findsOneWidget);

      // Verify state was reverted using the container reference
      final notifier = container.read(testFeatureProvider.notifier);
      expect(notifier.isDirty(), isFalse);
    }, tags: 'dirty-guard-framework');
  });
}
