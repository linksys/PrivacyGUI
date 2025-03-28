part of 'base_actions.dart';

class TestIncredibleWifiActions extends CommonBaseActions {
  final String wifiBand;

  TestIncredibleWifiActions(super.tester, {this.wifiBand = '2.4'});

  Finder _wifiCardFinder() {
    final wifiCardFinder = find.ancestor(
      of: wifiBandCardFinder(),
      matching: find.byType(AppCard),
    );
    expect(wifiCardFinder, findsOneWidget);
    return wifiCardFinder;
  }

  // Wifi band card

  Finder wifiBandCardFinder() {
    final context = getContext();
    String wifiBandText = switch (wifiBand) {
      '2.4' => '2.4 GHz band',
      '5' => '5 GHz band',
      '6' => '6 GHz band',
      'guest' => loc(context).guest,
      _ => throw Exception('Unknown band: $wifiBand'),
    };
    final wifiBandCardFinder = find.ancestor(
      of: find.text(wifiBandText),
      matching: find.byType(AppListCard),
    );
    expect(wifiBandCardFinder, findsOneWidget);
    return wifiBandCardFinder;
  }

  Finder switchFider() {
    final switchFider = find.descendant(
      of: wifiBandCardFinder(),
      matching: find.byType(AppSwitch),
    );
    expect(switchFider, findsOneWidget);
    return switchFider;
  }

  Future tapSwitch() async {
    final finder = switchFider();
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Wifi name card

  Finder wifiNameCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).wifiName),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Finder wifiNameFieldFinder() {
    final finder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(AppTextField),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  void checkWifiName(String wifiName) {
    final wifiNameFider = find.descendant(
      of: wifiNameCardFinder(),
      matching: find.text(wifiName),
    );
    expect(wifiNameFider, findsOneWidget);
  }

  Future tapWifiNameCard() async {
    final finder = wifiNameCardFinder();
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> inputWifiName(String wifiName) async {
    final finder = wifiNameFieldFinder();
    await tester.tap(finder);
    await tester.enterText(finder, wifiName);
    await tester.pumpAndSettle();
  }

  Finder guestWifiNameCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).guestWiFiName),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Finder guestWifiNameFieldFinder() {
    final finder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(AppTextField),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  void checkGuestWifiName(String wifiName) {
    final wifiNameFider = find.descendant(
      of: guestWifiNameCardFinder(),
      matching: find.text(wifiName),
    );
    expect(wifiNameFider, findsOneWidget);
  }

  Future tapGuestWifiNameCard() async {
    final finder = guestWifiNameCardFinder();
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> inputGuestWifiName(String guestWifiName) async {
    final finder = guestWifiNameFieldFinder();
    await tester.tap(finder);
    await tester.enterText(finder, guestWifiName);
    await tester.pumpAndSettle();
  }

  // Wifi password card

  Finder wifiPasswordCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).wifiPassword),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppListCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Finder wifiPasswordFieldFinder() {
    final finder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(AppTextField),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  void checkWifiPassword(String password) {
    final wifiNameFider = find.descendant(
      of: wifiPasswordCardFinder(),
      matching: find.text(password),
    );
    expect(wifiNameFider, findsOneWidget);
  }

  Future tapWifiPasswordCard() async {
    await tester.tap(wifiPasswordCardFinder());
    await tester.pumpAndSettle();
  }

  Future<void> inputWifiPassword(String wifiPassword) async {
    final finder = wifiPasswordFieldFinder();
    await tester.tap(finder);
    await tester.enterText(finder, wifiPassword);
    await tester.pumpAndSettle();
  }

  Finder guestWifiPasswordCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).guestWiFiPassword),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppListCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Finder guestWifiPasswordFieldFinder() {
    final finder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(AppTextField),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  void checkGuestWifiPassword(String password) {
    final wifiNameFider = find.descendant(
      of: guestWifiPasswordCardFinder(),
      matching: find.text(password),
    );
    expect(wifiNameFider, findsOneWidget);
  }

  Future tapGuestWifiPasswordCard() async {
    await tester.tap(guestWifiPasswordCardFinder());
    await tester.pumpAndSettle();
  }

  Future<void> inputGuestWifiPassword(String wifiPassword) async {
    final finder = guestWifiPasswordFieldFinder();
    await tester.tap(finder);
    await tester.enterText(finder, wifiPassword);
    await tester.pumpAndSettle();
  }

  Finder infoIconFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.byIcon(LinksysIcons.infoCircle),
    );
    expect(finder, findsExactly(3));
    return finder;
  }

  Finder closeIconFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.byIcon(LinksysIcons.close),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapPasswordVisibility() async {
    final finder = visibilityFinder(wifiPasswordCardFinder());
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future tapPasswordVisibilityOff() async {
    final finder = visibilityOffFinder(wifiPasswordCardFinder());
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future tapGuestPasswordVisibility() async {
    final finder = visibilityFinder(guestWifiPasswordCardFinder());
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future tapGuestPasswordVisibilityOff() async {
    final finder = visibilityOffFinder(guestWifiPasswordCardFinder());
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future tapPasswordVisibilityOnAlert() async {
    await tester.tap(visibilityFinder(alertDialogFinder()));
    await tester.pumpAndSettle();
  }

  Future tapPasswordVisibilityOffOnAlert() async {
    await tester.tap(visibilityOffFinder(alertDialogFinder()));
    await tester.pumpAndSettle();
  }

  // Security mode

  Finder securityModeCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).securityMode),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppListCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Future tapSecurityModeCard() async {
    await tester.tap(securityModeCardFinder());
    await tester.pumpAndSettle();
  }

  // Wifi mode

  Finder wifiModeCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).wifiMode),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Future tapWifiModeCard() async {
    await tester.tap(wifiModeCardFinder());
    await tester.pumpAndSettle();
  }

  // Broadcast SSID

  Finder broadcastSSIDCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).broadcastSSID),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppListCard),
    );
    expect(cardFinder, findsOneWidget);
    checkboxFinder(cardFinder); // Check the checkbox exist
    return cardFinder;
  }

  Future tapBroadcastSSIDCard() async {
    await tester.tap(broadcastSSIDCardFinder());
    await tester.pumpAndSettle();
  }

  // Channel width

  Finder channelWidthCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).channelWidth),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Future tapChannelWidthCard() async {
    await tester.tap(channelWidthCardFinder());
    await tester.pumpAndSettle();
  }

  // Channel width

  Finder channelCardFinder() {
    final context = getContext();
    final titleFider = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).channel),
    );
    expect(titleFider, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFider,
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Future tapChannelCard() async {
    await tester.tap(channelCardFinder());
    await tester.pumpAndSettle();
  }

  // Additional widgets

  Finder editIconFinder(Finder cardFinder) {
    final finder = find.descendant(
      of: cardFinder,
      matching: find.byIcon(LinksysIcons.edit),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder visibilityFinder(Finder cardFinder) {
    final finder = find.descendant(
      of: cardFinder,
      matching: find.byIcon(LinksysIcons.visibility),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder visibilityOffFinder(Finder cardFinder) {
    final finder = find.descendant(
      of: cardFinder,
      matching: find.byIcon(LinksysIcons.visibilityOff),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder textSaveBtnFinder() {
    final finder = find.byType(AppTextButton).last;
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder textCancelBtnFinder() {
    final finder = find.byType(AppTextButton).first;
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder saveBtnFinder() {
    final finder = find.byType(AppFilledButton);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder checkboxFinder(Finder cardFinder) {
    final finder = find.descendant(
      of: cardFinder,
      matching: find.byType(AppCheckbox),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder checkErrorMessage(String errorMessage) {
    final finder = find.text(errorMessage);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder alertDialogFinder() {
    final finder = find.byType(AlertDialog);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder newSettingColumnFinder() {
    String key = switch (wifiBand) {
      '2.4' => 'RADIO_2.4GHz',
      '5' => 'RADIO_5GHz',
      '6' => 'RADIO_6GHz',
      'guest' => 'guest',
      _ => throw Exception('Unknown band: $wifiBand'),
    };
    final finder = find.byKey(ValueKey(key));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder checkNewSettingWifiName(String wifiName) {
    final context = getContext();
    final finder = find.descendant(
      of: newSettingColumnFinder(),
      matching: find.text('${loc(context).wifiName}: $wifiName'),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder checkNewSettingWifiPassword(String wifiPassword) {
    final context = getContext();
    final finder = find.descendant(
      of: newSettingColumnFinder(),
      matching: find.text('${loc(context).wifiPassword}: $wifiPassword'),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder okButtonFinder() {
    final context = getContext();
    final finder = find.text(loc(context).ok);
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapCheckbox() async {
    await tester.tap(checkboxFinder(broadcastSSIDCardFinder()));
    await tester.pumpAndSettle();
  }

  Future tapSaveBtn() async {
    await tester.tap(saveBtnFinder());
    await tester.pumpAndSettle();
  }

  Future tapTextCancelBtn() async {
    await tester.tap(textCancelBtnFinder());
    await tester.pumpAndSettle();
  }

  Future tapTextSaveBtn() async {
    await tester.tap(textSaveBtnFinder());
    await tester.pumpAndSettle();
  }

  Future tapOkButton() async {
    await tester.tap(okButtonFinder());
    await tester.pumpAndSettle();
  }
}
