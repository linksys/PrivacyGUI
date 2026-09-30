import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/read_only/read_only_banner.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';

import '../../../common/testable_router.dart';

void main() {
  const message = 'Read-only mode. Settings can be viewed but not changed.';

  testWidgets('renders nothing in a writable build', (tester) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [readOnlyModeProvider.overrideWithValue(false)],
      child: const ReadOnlyBanner(),
    ));
    expect(find.text(message), findsNothing);
  });

  testWidgets('tells the viewer nothing can be saved', (tester) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [readOnlyModeProvider.overrideWithValue(true)],
      child: const ReadOnlyBanner(),
    ));
    expect(find.text(message), findsOneWidget);
  });
}
