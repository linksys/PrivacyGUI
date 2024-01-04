import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_app/page/login/view/_view.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../../common/testable_widget.dart';

void main() {
  setUpAll(() async {});
  tearDownAll(() async {});

  // testWidgets('Golden test for login password view', (tester) async {
  //   await tester.pumpWidget(
  //     testableWidget(child: const CloudLoginPasswordView(
  //       args: {
  //         'username': 'test@gmail.com',
  //       },
  //     )),
  //   );
  //   await tester.pump();
  //   await expectLater(find.byType(CloudLoginPasswordView),
  //       matchesGoldenFile('cloudLoginPasswordView-1.png'));
  // });
  testWidgets('test cloud login password view', (tester) async {
    await tester.pumpWidget(
      testableWidget(
          child: const CloudLoginPasswordView(
        args: {
          'username': 'test@gmail.com',
        },
      )),
    );

    assert(globalKey.currentContext != null);
    final currentContext = globalKey.currentContext!;

    final passwordViewInput = find.byType(AppTextField);
    final spinnerView = find.byType(AppFullScreenSpinner);
    final continueButton = find.byType(AppFilledButton);

    final iconData = AppIconsData.regular().characters;

    expect(spinnerView, findsOneWidget);
    expect(passwordViewInput, findsNothing);
    // waiting for spinner finish
    await tester.pump();
    // spinner should be gone
    expect(spinnerView, findsNothing);
    // password input field should display
    expect(passwordViewInput, findsOneWidget);
    // continue button should display
    expect(continueButton, findsOneWidget);
    // email should display
    expect(find.text('test@gmail.com'), findsOneWidget);
    // show password icon
    expect(find.byIcon(iconData.showDefault), findsOneWidget);
    // verify secure property is true
    expect(tester.widget<AppTextField>(passwordViewInput).secured, isTrue);
    // verify the button is disable
    expect(tester.widget<AppFilledButton>(continueButton).onTap, isNull);
  });

  testWidgets('test cloud login password view - click hide/show password',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
          child: const CloudLoginPasswordView(
        args: {
          'username': 'test@gmail.com',
        },
      )),
    );

    assert(globalKey.currentContext != null);

    final passwordViewInput = find.byType(AppTextField);
    final spinnerView = find.byType(AppFullScreenSpinner);

    final iconData = AppIconsData.regular().characters;

    // waiting for spinner finish
    await tester.pump();
    // spinner should be gone
    expect(spinnerView, findsNothing);
    // show password icon
    expect(find.byIcon(iconData.showDefault), findsOneWidget);
    // verify secure property is true
    expect(tester.widget<AppTextField>(passwordViewInput).secured, isTrue);
    // tap show password icon
    await tester.tap(find.byIcon(iconData.showDefault));
    // wait for rebuild
    await tester.pump();
    // hide password icon should display
    expect(find.byIcon(iconData.hideDefault), findsOneWidget);
    // verify secure proporty is false
    expect(tester.widget<AppTextField>(passwordViewInput).secured, isFalse);
    // tap hide password icon
    await tester.tap(find.byIcon(iconData.hideDefault));

    // wait for rebuild
    await tester.pump();
    // hide password icon should display
    expect(find.byIcon(iconData.showDefault), findsOneWidget);
    // verify secure proporty is true
    expect(tester.widget<AppTextField>(passwordViewInput).secured, isTrue);
  });

  testWidgets('test cloud login password view - click input invalid password',
      (tester) async {
    await tester.pumpWidget(
      testableWidget(
          child: const CloudLoginPasswordView(
        args: {
          'username': 'test@gmail.com',
        },
      )),
    );

    assert(globalKey.currentContext != null);

    final passwordViewInput = find.byType(AppTextField);
    final spinnerView = find.byType(AppFullScreenSpinner);

    await tester.pump();
    expect(passwordViewInput, findsOneWidget);
  });
}
