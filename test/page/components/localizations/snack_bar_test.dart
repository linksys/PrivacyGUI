import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import 'snack_bar_sample_view.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('Snack bar - Success: Saved', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(0);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Success: Changes saved',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(1);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Success: Success!', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(2);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Success: Copied to clipboard!',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(3);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Success: Done', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(4);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Success: Router password updated',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(5);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Failed!', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(6);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid admin password',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(7);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid firmware file!',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(8);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Error manual update failed!',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(9);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - IP address or MAC address overlap',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(10);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations(
      'Snack bar - Oops, something wrong here! Please try again later',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(11);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Unknown error', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(12);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Incorrect password', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(13);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Too many failed attempts',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(14);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid destination MAC address',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(15);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid destination IP address',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(16);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid gateway IP address',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(17);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid IP address', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(18);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid DNS', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(19);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid MAC address.', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(20);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid input', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(21);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - The specified server IP address is not valid.',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(22);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Invalid destination IP address',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(23);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - The rules cannot be created',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(24);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Guest network names must be different',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(25);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Snack bar - Unknown error: _ErrorUnexpected',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    final buttonFinder = find.byType(AppTextButton).at(26);
    await tester.scrollUntilVisible(
      buttonFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }, screens: screens);
}