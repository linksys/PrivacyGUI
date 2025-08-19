part of 'base_actions.dart';

class TestSpeedTestActions extends CommonBaseActions {
  TestSpeedTestActions(super.tester);

  Finder goButtonFinder() {
    final goButtonFinder = find.byKey(const Key('goBtn'));
    expect(goButtonFinder, findsOneWidget);
    return goButtonFinder;
  }

  Finder tryAgainButtonFinder() {
    final tryAgainButtonFinder = find.byType(AppFilledButton);
    expect(tryAgainButtonFinder, findsOneWidget);
    return tryAgainButtonFinder;
  }

  Finder downloadBandWidthFinder() {
    final downloadBandWidthFinder = find.byKey(const Key('downloadBandWidth'));
    expect(downloadBandWidthFinder, findsOneWidget);
    return downloadBandWidthFinder;
  }

  Finder uploadBandWidthFinder() {
    final uploadBandWidthFinder = find.byKey(const Key('uploadBandWidth'));
    expect(uploadBandWidthFinder, findsOneWidget);
    return uploadBandWidthFinder;
  }

  Future<void> tapGoButton() async {
    final finder = goButtonFinder();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  void checkDownloadBandWidth() {
    final finder = downloadBandWidthFinder();
    final textElement = tester.element(finder);
    final textWidget = textElement.widget as AppText;
    final textValue = textWidget.text;
    expect(textValue, isNot('-'));
  }

  void checkUploadBandWidth() {
    final finder = uploadBandWidthFinder();
    final textElement = tester.element(finder);
    final textWidget = textElement.widget as AppText;
    final textValue = textWidget.text;
    expect(textValue, isNot('-'));
  }
}