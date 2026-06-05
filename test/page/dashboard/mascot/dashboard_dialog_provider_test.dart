import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/dashboard/mascot/dashboard_dialog_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class MockMascotController extends Mock implements MascotController {}

class FakeMascotDialogNode extends Fake implements MascotDialogNode {}

void main() {
  late DashboardDialogProvider provider;
  late MockMascotController mockController;

  setUpAll(() {
    registerFallbackValue(FakeMascotDialogNode());
  });

  setUp(() {
    mockController = MockMascotController();

    provider = DashboardDialogProvider(
      controller: mockController,
      onRunFullDiagnostics: () async => const DiagnosticsResult(
        message: 'All checks passed!',
        hasIssues: false,
      ),
      onRunFlowDiagnostics: (flow) async => const DiagnosticsResult(
        message: 'Check complete',
        hasIssues: false,
      ),
      onPrintReport: () async {},
      onOpenThemeStudio: () {},
      getLocale: () => const Locale('en'),
      getFaqCategoryTitle: (category) => 'Category',
      getFaqItemTitle: (item) => 'Item',
      isThemeStudioEnabled: false,
      getRouterTime: () => null,
    );
  });

  group('DashboardDialogProvider - getInitialDialog', () {
    test('returns main menu with FAQ, diagnostics, and print options',
        () async {
      final dialog = await provider.getInitialDialog();

      expect(dialog.id, 'main');
      expect(dialog.options.length, 3);
      expect(dialog.options.map((o) => o.id),
          containsAll(['faq', 'diagnostics', 'print']));
    });

    test('includes theme studio option when enabled', () async {
      final providerWithThemeStudio = DashboardDialogProvider(
        controller: mockController,
        onRunFullDiagnostics: () async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onRunFlowDiagnostics: (flow) async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onPrintReport: () async {},
        onOpenThemeStudio: () {},
        getLocale: () => const Locale('en'),
        getFaqCategoryTitle: (category) => 'Category',
        getFaqItemTitle: (item) => 'Item',
        isThemeStudioEnabled: true,
        getRouterTime: () => null,
      );

      final dialog = await providerWithThemeStudio.getInitialDialog();

      expect(dialog.options.length, 4);
      expect(dialog.options.map((o) => o.id), contains('theme_studio'));
    });
  });

  group('DashboardDialogProvider - greeting time periods', () {
    test('returns morning greeting between 5-12', () async {
      final morningProvider = DashboardDialogProvider(
        controller: mockController,
        onRunFullDiagnostics: () async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onRunFlowDiagnostics: (flow) async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onPrintReport: () async {},
        onOpenThemeStudio: () {},
        getLocale: () => const Locale('en'),
        getFaqCategoryTitle: (category) => 'Category',
        getFaqItemTitle: (item) => 'Item',
        isThemeStudioEnabled: false,
        getRouterTime: () => DateTime(2024, 1, 1, 8, 0), // 8 AM
      );

      final dialog = await morningProvider.getInitialDialog();

      expect(
        dialog.text,
        anyOf(
          contains('Good morning'),
          contains('Rise and shine'),
          contains('Morning!'),
        ),
      );
    });

    test('returns afternoon greeting between 12-17', () async {
      final afternoonProvider = DashboardDialogProvider(
        controller: mockController,
        onRunFullDiagnostics: () async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onRunFlowDiagnostics: (flow) async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onPrintReport: () async {},
        onOpenThemeStudio: () {},
        getLocale: () => const Locale('en'),
        getFaqCategoryTitle: (category) => 'Category',
        getFaqItemTitle: (item) => 'Item',
        isThemeStudioEnabled: false,
        getRouterTime: () => DateTime(2024, 1, 1, 14, 0), // 2 PM
      );

      final dialog = await afternoonProvider.getInitialDialog();

      expect(
        dialog.text,
        anyOf(
          contains('Good afternoon'),
          contains('Hey there'),
          contains('Afternoon!'),
        ),
      );
    });

    test('returns evening greeting between 17-21', () async {
      final eveningProvider = DashboardDialogProvider(
        controller: mockController,
        onRunFullDiagnostics: () async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onRunFlowDiagnostics: (flow) async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onPrintReport: () async {},
        onOpenThemeStudio: () {},
        getLocale: () => const Locale('en'),
        getFaqCategoryTitle: (category) => 'Category',
        getFaqItemTitle: (item) => 'Item',
        isThemeStudioEnabled: false,
        getRouterTime: () => DateTime(2024, 1, 1, 19, 0), // 7 PM
      );

      final dialog = await eveningProvider.getInitialDialog();

      expect(
        dialog.text,
        anyOf(
          contains('Good evening'),
          contains('Evening!'),
          contains('Hey!'),
        ),
      );
    });

    test('returns night greeting between 21-5', () async {
      final nightProvider = DashboardDialogProvider(
        controller: mockController,
        onRunFullDiagnostics: () async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onRunFlowDiagnostics: (flow) async => const DiagnosticsResult(
          message: 'OK',
          hasIssues: false,
        ),
        onPrintReport: () async {},
        onOpenThemeStudio: () {},
        getLocale: () => const Locale('en'),
        getFaqCategoryTitle: (category) => 'Category',
        getFaqItemTitle: (item) => 'Item',
        isThemeStudioEnabled: false,
        getRouterTime: () => DateTime(2024, 1, 1, 23, 0), // 11 PM
      );

      final dialog = await nightProvider.getInitialDialog();

      expect(
        dialog.text,
        anyOf(
          contains('night owl'),
          contains('midnight'),
          contains('Late night'),
          contains('sleep'),
        ),
      );
    });
  });

  group('DashboardDialogProvider - handleSelection', () {
    test('FAQ selection returns FAQ categories menu', () async {
      final result = await provider.handleSelection('main', 'faq');

      expect(result, isNotNull);
      expect(result!.id, 'faq_categories');
      expect(result.options.any((o) => o.id == 'back'), isTrue);
    });

    test('diagnostics selection returns diagnostics menu', () async {
      final result = await provider.handleSelection('main', 'diagnostics');

      expect(result, isNotNull);
      expect(result!.id, 'diagnostics_menu');
      expect(result.options.any((o) => o.id == 'full'), isTrue);
    });

    test('back from FAQ categories returns main menu', () async {
      final result = await provider.handleSelection('faq_categories', 'back');

      expect(result, isNotNull);
      expect(result!.id, 'main');
    });

    test('back from diagnostics menu returns main menu', () async {
      final result = await provider.handleSelection('diagnostics_menu', 'back');

      expect(result, isNotNull);
      expect(result!.id, 'main');
    });

    test('unknown option returns null', () async {
      final result = await provider.handleSelection('main', 'unknown');

      expect(result, isNull);
    });
  });

  group('DashboardDialogProvider - diagnostics flow', () {
    test('full diagnostics shows loading then result', () async {
      when(() => mockController.showDialog(any<MascotDialogNode>()))
          .thenReturn(null);

      final result = await provider.handleSelection('diagnostics_menu', 'full');

      verify(() => mockController.showDialog(any<MascotDialogNode>()))
          .called(1);
      expect(result, isNotNull);
      expect(result!.id, 'diagnostics_result');
      expect(result.type, MascotDialogType.success);
    });

    test('diagnostics with issues returns error type', () async {
      final providerWithIssues = DashboardDialogProvider(
        controller: mockController,
        onRunFullDiagnostics: () async => const DiagnosticsResult(
          message: 'Found 2 issues.',
          hasIssues: true,
        ),
        onRunFlowDiagnostics: (flow) async => const DiagnosticsResult(
          message: 'Issue found',
          hasIssues: true,
        ),
        onPrintReport: () async {},
        onOpenThemeStudio: () {},
        getLocale: () => const Locale('en'),
        getFaqCategoryTitle: (category) => 'Category',
        getFaqItemTitle: (item) => 'Item',
        isThemeStudioEnabled: false,
        getRouterTime: () => null,
      );

      when(() => mockController.showDialog(any<MascotDialogNode>()))
          .thenReturn(null);

      final result =
          await providerWithIssues.handleSelection('diagnostics_menu', 'full');

      expect(result, isNotNull);
      expect(result!.type, MascotDialogType.error);
      expect(result.suggestedAnimation, MascotAnimationKey.sad);
    });
  });
}
