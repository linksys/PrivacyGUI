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

  Finder bandSwitchFider() {
    final switchFider = find.descendant(
      of: wifiBandCardFinder(),
      matching: find.byType(AppSwitch),
    );
    expect(switchFider, findsOneWidget);
    return switchFider;
  }

  Future tapBandSwitch() async {
    final finder = bandSwitchFider();
    await scrollAndTap(finder);
  }

  // Wifi name card

  Finder wifiNameCardFinder() {
    final context = getContext();
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).wifiName),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
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
    final wifiNameFinder = find.descendant(
      of: wifiNameCardFinder(),
      matching: find.text(wifiName),
    );
    expect(wifiNameFinder, findsOneWidget);
  }

  Future tapWifiNameCard() async {
    final finder = wifiNameCardFinder();
    await scrollAndTap(finder);
  }

  Future<void> inputWifiName(String wifiName) async {
    final finder = wifiNameFieldFinder();
    await tester.tap(finder);
    await tester.enterText(finder, wifiName);
    await tester.pumpAndSettle();
  }

  Finder guestWifiNameCardFinder() {
    final context = getContext();
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).guestWiFiName),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
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
    final wifiNameFinder = find.descendant(
      of: guestWifiNameCardFinder(),
      matching: find.text(wifiName),
    );
    expect(wifiNameFinder, findsOneWidget);
  }

  Future tapGuestWifiNameCard() async {
    final finder = guestWifiNameCardFinder();
    await scrollAndTap(finder);
  }

  Future<void> inputGuestWifiName(String guestWifiName) async {
    final finder = guestWifiNameFieldFinder();
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.enterText(finder, guestWifiName);
    await tester.pumpAndSettle();
  }

  // Wifi password card

  Finder wifiPasswordCardFinder() {
    final context = getContext();
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).wifiPassword),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
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
    final wifiNameFinder = find.descendant(
      of: wifiPasswordCardFinder(),
      matching: find.text(password),
    );
    expect(wifiNameFinder, findsOneWidget);
  }

  Future tapWifiPasswordCard() async {
    final finder = wifiPasswordCardFinder();
    await scrollAndTap(finder);
  }

  Future<void> inputWifiPassword(String wifiPassword) async {
    final finder = wifiPasswordFieldFinder();
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.enterText(finder, wifiPassword);
    await tester.pumpAndSettle();
  }

  Finder guestWifiPasswordCardFinder() {
    final context = getContext();
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).guestWiFiPassword),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
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
    final wifiNameFinder = find.descendant(
      of: guestWifiPasswordCardFinder(),
      matching: find.text(password),
    );
    expect(wifiNameFinder, findsOneWidget);
  }

  Future tapGuestWifiPasswordCard() async {
    final finder = guestWifiPasswordCardFinder();
    await scrollAndTap(finder);
  }

  Future<void> inputGuestWifiPassword(String wifiPassword) async {
    final finder = guestWifiPasswordFieldFinder();
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.enterText(finder, wifiPassword);
    await tester.pumpAndSettle();
  }

  Finder passwordValidatorInfoIconFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.byIcon(LinksysIcons.infoCircle),
    );
    expect(finder, findsExactly(3));
    return finder;
  }

  Finder passwordValidatorCloseIconFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.byIcon(LinksysIcons.close),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapPasswordVisibility() async {
    final finder = visibilityFinder(wifiPasswordCardFinder());
    await scrollAndTap(finder);
  }

  Future tapPasswordVisibilityOff() async {
    final finder = visibilityOffFinder(wifiPasswordCardFinder());
    await scrollAndTap(finder);
  }

  Future tapGuestPasswordVisibility() async {
    final finder = visibilityFinder(guestWifiPasswordCardFinder());
    await scrollAndTap(finder);
  }

  Future tapGuestPasswordVisibilityOff() async {
    final finder = visibilityOffFinder(guestWifiPasswordCardFinder());
    await scrollAndTap(finder);
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
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).securityMode),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(AppListCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Finder enhancedOpenOnlyFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(getWifiSecurityTypeTitle(
          getContext(), WifiSecurityType.enhancedOpenOnly)),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapSecurityModeCard() async {
    final finder = securityModeCardFinder();
    await scrollAndTap(finder);
  }

  Future tapEnhancedOpenOnlyOption() async {
    final finder = enhancedOpenOnlyFinder();
    await scrollAndTap(finder);
  }

  void checkSecurityMode(String mode) {
    final finder = find.descendant(
      of: securityModeCardFinder(),
      matching: find.text(mode),
    );
    expect(finder, findsOneWidget);
  }

  // Wifi mode

  Finder wifiModeCardFinder() {
    final context = getContext();
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).wifiMode),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Finder mode80211bgnOnlyFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(getWifiWirelessModeTitle(
        getContext(),
        WifiWirelessMode.bgn,
        null,
      )),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder mode80211anacOnlyFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(getWifiWirelessModeTitle(
        getContext(),
        WifiWirelessMode.anac,
        null,
      )),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder mode80211axOnlyFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(getWifiWirelessModeTitle(
        getContext(),
        WifiWirelessMode.ax,
        null,
      )),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapWifiModeCard() async {
    final finder = wifiModeCardFinder();
    await scrollAndTap(finder);
  }

  Future tap80211bgnOnlyOption() async {
    final finder = mode80211bgnOnlyFinder();
    await scrollAndTap(finder);
  }

  Future tap80211anacOnlyOption() async {
    final finder = mode80211anacOnlyFinder();
    await scrollAndTap(finder);
  }

  Future tap80211axOnlyOption() async {
    final finder = mode80211axOnlyFinder();
    await scrollAndTap(finder);
  }

  void checkWifiMode(String mode) {
    final finder = find.descendant(
      of: wifiModeCardFinder(),
      matching: find.text(mode),
    );
    expect(finder, findsOneWidget);
  }

  // Broadcast SSID

  Finder broadcastSSIDCardFinder() {
    final context = getContext();
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).broadcastSSID),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
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

  void checkBroadcastSSIDDisable() {
    final finder = checkboxFinder(broadcastSSIDCardFinder());
    final checkbox = tester.widget<AppCheckbox>(finder);
    expect(false, checkbox.value);
  }

  void checkBroadcastSSIDEnable() {
    final finder = checkboxFinder(broadcastSSIDCardFinder());
    final checkbox = tester.widget<AppCheckbox>(finder);
    expect(true, checkbox.value);
  }

  // Channel width

  Finder channelWidthCardFinder() {
    final context = getContext();
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).channelWidth),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Finder channelWidth20MHzOnlyFinder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(
          getWifiChannelWidthTitle(getContext(), WifiChannelWidth.wide20)),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapChannelWidthCard() async {
    final finder = channelWidthCardFinder();
    await scrollAndTap(finder);
  }

  Future tap20MHzOnlyOption() async {
    final finder = channelWidth20MHzOnlyFinder();
    await scrollAndTap(finder);
  }

  void checkChannelWidth(String channelWidth) {
    final finder = find.descendant(
      of: channelWidthCardFinder(),
      matching: find.text(channelWidth),
    );
    expect(finder, findsOneWidget);
  }

  // Channel

  Finder channelCardFinder() {
    final context = getContext();
    final titleFinder = find.descendant(
      of: _wifiCardFinder(),
      matching: find.text(loc(context).channel),
    );
    expect(titleFinder, findsOneWidget);
    final cardFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    editIconFinder(cardFinder); // Check the edit icon exist
    return cardFinder;
  }

  Finder channel6Finder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(getWifiChannelTitle(getContext(), 6, _getRadio())),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder channel40Finder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(getWifiChannelTitle(getContext(), 40, _getRadio())),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder channel29Finder() {
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(getWifiChannelTitle(getContext(), 29, _getRadio())),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapChannelCard() async {
    final finder = channelCardFinder();
    await scrollAndTap(finder);
  }

  Future tap6ChannelOption() async {
    final finder = channel6Finder();
    await scrollAndTap(finder);
  }

  Future tap40ChannelOption() async {
    final finder = channel40Finder();
    await scrollAndTap(finder);
  }

  Future tap29ChannelOption() async {
    final finder = channel29Finder();
    await scrollAndTap(finder);
  }

  void checkChannel(String channel) {
    final finder = find.descendant(
      of: channelCardFinder(),
      matching: find.text(channel),
    );
    expect(finder, findsOneWidget);
  }

  // Advanced

  Finder clientSteeringCardFinder() {
    final finder = find.byKey(Key('clientSteering'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder nodeSteeringCardFinder() {
    final finder = find.byKey(Key('nodeSteering'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder dfsCardFinder() {
    final finder = find.byKey(Key('dfs'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder iptvCardFinder() {
    final finder = find.byKey(Key('iptv'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder mloCardFinder() {
    final finder = find.byKey(Key('mlo'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder clientSteeringSwitchFinder() {
    final finder = find.descendant(
      of: clientSteeringCardFinder(),
      matching: find.byType(AppSwitch),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder nodeSteeringSwitchFinder() {
    final finder = find.descendant(
      of: nodeSteeringCardFinder(),
      matching: find.byType(AppSwitch),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder dfsSwitchFinder() {
    final finder = find.descendant(
      of: dfsCardFinder(),
      matching: find.byType(AppSwitch),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder iptvSwitchFinder() {
    final finder = find.descendant(
      of: iptvCardFinder(),
      matching: find.byType(AppSwitch),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder mloSwitchFinder() {
    final finder = find.descendant(
      of: mloCardFinder(),
      matching: find.byType(AppSwitch),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapClientSteeringSwitch() async {
    final finder = clientSteeringSwitchFinder();
    await scrollAndTap(finder);
  }

  Future tapNodeSteeringSwitch() async {
    final finder = nodeSteeringSwitchFinder();
    await scrollAndTap(finder);
  }

  Future tapDFSSwitch() async {
    final finder = dfsSwitchFinder();
    await scrollAndTap(finder);
  }

  Future tapIptvSwitch() async {
    final finder = iptvSwitchFinder();
    await scrollAndTap(finder);
  }

  Future tapMloSwitch() async {
    final finder = mloSwitchFinder();
    await scrollAndTap(finder);
  }

  void checkDFSAlert() {
    final context = getContext();
    final finder = find.text(loc(context).modalDFSDesc);
    expect(finder, findsOneWidget);
  }

  void checkMLOAlert() {
    final context = getContext();
    final finder = find.text(loc(context).mloWarning);
    expect(finder, findsOneWidget);
  }

  // Mac Filtering

  Finder macFilteringSwitchFinder() {
    final finder = find.byType(AppSwitch);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder selectDeviceFinder() {
    final context = getContext();
    final finder = find.text(loc(context).selectFromMyDeviceList);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder manuallyAddDeviceFinder() {
    final context = getContext();
    final finder = find.text(loc(context).manuallyAddDevice);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder macAddressInputFinder() {
    final finder = find.byType(AppTextField);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder filteredDeviceFinder(String macAddress) {
    final finder = find.text(macAddress);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder doneButtonFinder() {
    final context = getContext();
    final finder = find.text(loc(context).done);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder editButtonFinder() {
    final finder = find.byIcon(LinksysIcons.edit);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder removeButtonFinder() {
    final context = getContext();
    final finder = find.text(loc(context).remove);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder turnOnButtonFinder() {
    final context = getContext();
    final finder = find.text(loc(context).turnOn);
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapMacFilteringSwitch() async {
    final finder = macFilteringSwitchFinder();
    await scrollAndTap(finder);
  }

  Future goToFilteredDevices() async {
    final finder = find.byType(AppInfoCard);
    expect(finder, findsOneWidget);
    await scrollAndTap(finder);
    final context = getContext();
    final titleFinder = find.text(loc(context).filteredDevices);
    expect(titleFinder, findsWidgets);
  }

  Future tapSelectDevice() async {
    final finder = selectDeviceFinder();
    await scrollAndTap(finder);
  }

  Future tapManuallyAddDevice() async {
    final finder = manuallyAddDeviceFinder();
    await scrollAndTap(finder);
  }

  Future tapFilteredDevice(String macAddress) async {
    final finder = filteredDeviceFinder(macAddress);
    await scrollAndTap(finder);
  }

  Future tapDoneButton() async {
    final finder = doneButtonFinder();
    await scrollAndTap(finder);
  }

  Future tapEditButton() async {
    final finder = editButtonFinder();
    await scrollAndTap(finder);
  }

  Future tapRemoveButton() async {
    final finder = removeButtonFinder();
    await scrollAndTap(finder);
  }

  Future tapTurnOnButton() async {
    final finder = turnOnButtonFinder();
    await scrollAndTap(finder);
  }

  Future inputMacAddress(String macAddress) async {
    final finder = macAddressInputFinder();
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.enterText(finder, macAddress);
    await tester.pumpAndSettle();
  }

  void checkSelectDevicesTitle() {
    final context = getContext();
    final finder = find.text(loc(context).selectDevices);
    expect(finder, findsOneWidget);
  }

  void checkDeviceCount(int count) {
    final context = getContext();
    final finder = find.text(loc(context).nDevices(count).capitalizeWords());
    expect(finder, findsOneWidget);
  }

  void checkNoFilteredDevice() {
    final context = getContext();
    final finder = find.text(loc(context).noFilteredDevices);
    expect(finder, findsOneWidget);
  }

  void checkFilteredDevice(String macAddress) {
    final finder = find.text(macAddress);
    expect(finder, findsOneWidget);
  }

  void checkInstantPrivacyWarning() {
    final context = getContext();
    final finder = find.text(loc(context).instantPrivacyDisableWarning);
    expect(finder, findsOneWidget);
  }

  // Tabs

  Finder wifiTabFinder() {
    final context = getContext();
    final finder = find.text(loc(context).wifi);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder advancedTabFinder() {
    final context = getContext();
    final finder = find.text(loc(context).advanced);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder macFilteringTabFinder() {
    final context = getContext();
    final finder = find.text(loc(context).macFiltering);
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapWifiTab() async {
    final finder = wifiTabFinder();
    await scrollAndTap(finder);
  }

  Future tapAdvancedTab() async {
    final finder = advancedTabFinder();
    await scrollAndTap(finder);
  }

  Future tapMacFilteringTab() async {
    final finder = macFilteringTabFinder();
    await scrollAndTap(finder);
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

  Finder alertSaveBtnFinder() {
    final context = getContext();
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(loc(context).save),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder alertCancelBtnFinder() {
    final context = getContext();
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(loc(context).cancel),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder alertOkBtnFinder() {
    final context = getContext();
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(loc(context).ok),
    );
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

  Finder checkNewSettingSecurityMode(String mode) {
    final context = getContext();
    final finder = find.descendant(
      of: newSettingColumnFinder(),
      matching: find.text('${loc(context).securityMode}: $mode'),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder checkNewSettingGuestWarning(WifiRadioBand radio) {
    final context = getContext();
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(loc(context)
          .disableBandWarning(getWifiRadioBandTitle(context, radio))),
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

  Future tapAlertCancelBtn() async {
    await tester.tap(alertCancelBtnFinder());
    await tester.pumpAndSettle();
  }

  Future tapAlertSaveBtn() async {
    await tester.tap(alertSaveBtnFinder());
    await tester.pumpAndSettle();
  }

  Future tapAlertOkBtn() async {
    await tester.tap(alertOkBtnFinder());
    await tester.pumpAndSettle();
  }

  Future tapOkButton() async {
    await tester.tap(okButtonFinder());
    await tester.pumpAndSettle();
  }

  _getRadio() {
    return switch (wifiBand) {
      '2.4' => WifiRadioBand.radio_24,
      '5' => WifiRadioBand.radio_5_1,
      '6' => WifiRadioBand.radio_6,
      'guest' => WifiRadioBand.radio_24,
      _ => WifiRadioBand.radio_24,
    };
  }

}
