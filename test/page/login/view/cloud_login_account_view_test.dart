import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/login/view/_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../../common/testable_widget.dart';

void main() {
  setUpAll(() async {});
  tearDownAll(() async {});

  // testWidgets('Golden test for login account view', (tester) async {
  //   await tester.pumpWidget(
  //     testableWidget(child: const CloudLoginAccountView()),
  //   );
  //   await tester.pump();
  //   await expectLater(find.byType(CloudLoginAccountView),
  //       matchesGoldenFile('cloudLoginAccountView-1.png'));
  // });
  testWidgets('test cloud login account view', (tester) async {
    await tester.pumpWidget(
      testableWidget(child: const CloudLoginAccountView()),
    );

    assert(globalKey.currentContext != null);
    final currentContext = globalKey.currentContext!;

    final accountViewInput = find.byType(AppTextField);
    final spinnerView = find.byType(AppFullScreenSpinner);
    final continueButton = find.byType(AppFilledButton);

    expect(spinnerView, findsOneWidget);
    expect(accountViewInput, findsNothing);
    // waiting for spinner finish
    await tester.pump();
    expect(spinnerView, findsNothing);
    // email input text field
    expect(accountViewInput, findsOneWidget);
    // log in button
    expect(continueButton, findsOneWidget);
    // cloud login title
    expect(
        find.text(
            getAppLocalizations(currentContext).cloud_account_login_title),
        findsOneWidget);
    // log in with router password
    expect(
        find.text(getAppLocalizations(currentContext)
            .cloud_account_login_with_router_password),
        findsOneWidget);
  });
  testWidgets('test cloud login account view input something', (tester) async {
    await tester.pumpWidget(
      testableWidget(child: const CloudLoginAccountView()),
    );

    final accountViewInput = find.byType(AppTextField);
    final spinnerView = find.byType(AppFullScreenSpinner);
    // try to get specific widget via localized text
    final continueButton =
        find.text(getAppLocalizations(globalKey.currentContext!).login);

    await tester.pump();

    // try to enter something
    await tester.enterText(accountViewInput, 'text');
    // wait for rebuild
    await tester.pump();
    // verify there has a widget include 'text'
    expect(find.text('text'), findsOneWidget);

    // try to click continue button
    await tester.tap(continueButton);
    // wait for rebuild
    await tester.pump();
    expect(find.text('text'), findsOneWidget);
    // verify the error message
    expect(
        find.text(getAppLocalizations(globalKey.currentContext!)
            .error_enter_a_valid_email_format),
        findsOneWidget);
  });

  testWidgets('test cloud login account view with valid input', (tester) async {
    await tester.pumpWidget(
      testableWidget(child: const CloudLoginAccountView()),
    );

    const testAccount = 'abc123@gmail.com';

    final accountViewInput = find.byType(AppTextField);
    final spinnerView = find.byType(AppFullScreenSpinner);
    // try to get specific widget via localized text
    final continueButton =
        find.text(getAppLocalizations(globalKey.currentContext!).login);

    await tester.pump();

    // try to enter something
    await tester.enterText(accountViewInput, testAccount);
    // wait for rebuild
    await tester.pump();
    // verify there has a widget include 'text'
    expect(find.text(testAccount), findsOneWidget);
  });
}
