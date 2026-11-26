import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_colors.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  late BuildContext context;

  Future<void> pump(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Builder(builder: (c) {
        context = c;
        return const SizedBox.shrink();
      }),
    ));
  }

  final appTheme = AppTheme.create(
    brightness: Brightness.light,
    seedColor: Colors.blue,
    designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
  );

  testWidgets('busy wins, then in use, then everything else (#1778)',
      (tester) async {
    await pump(tester, appTheme);
    final scheme = Theme.of(context).colorScheme;
    final warning =
        Theme.of(context).extension<AppColorScheme>()!.semanticWarning;

    Color of(int? u, {bool inUse = false}) =>
        channelBusynessColor(context, utilization: u, isInUse: inUse);

    expect(of(128), warning, reason: '50 % is busy');
    expect(of(200, inUse: true), warning, reason: 'busy wins over in use');
    expect(of(127, inUse: true), scheme.primary);
    expect(of(127), scheme.outline);
    expect(of(null, inUse: true), scheme.outline, reason: 'no reading');
  });

  testWidgets('a theme without AppColorScheme falls back to its error colour',
      (tester) async {
    await pump(tester, ThemeData.light());
    expect(channelBusyColor(context), Theme.of(context).colorScheme.error);
  });
}
