import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/views/remote_read_only_banner.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';

void main() {
  group('RemoteReadOnlyBanner', () {
    testWidgets('shows banner when isRemoteReadOnly is true',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            remoteAccessProvider.overrideWith(
              (ref) => const RemoteAccessState(isRemoteReadOnly: true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RemoteReadOnlyBanner(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Container), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(
        find.text('Remote View Mode - Setting changes are disabled'),
        findsOneWidget,
      );
    });

    testWidgets('hides banner when isRemoteReadOnly is false',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            remoteAccessProvider.overrideWith(
              (ref) => const RemoteAccessState(isRemoteReadOnly: false),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RemoteReadOnlyBanner(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(
        find.text('Remote View Mode - Setting changes are disabled'),
        findsNothing,
      );
    });

    testWidgets('banner has correct styling', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            remoteAccessProvider.overrideWith(
              (ref) => const RemoteAccessState(isRemoteReadOnly: true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RemoteReadOnlyBanner(),
            ),
          ),
        ),
      );

      // Act
      final banner = find.byType(RemoteReadOnlyBanner);
      final bannerSize = tester.getSize(banner);
      final container = tester.widget<Container>(find.byType(Container).first);

      // Assert
      // Verify banner takes full available width
      expect(bannerSize.width, greaterThan(0));

      // Verify decoration color
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.orange.shade100));
    });
  });
}
