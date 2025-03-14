import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacy_gui/page/dashboard/views/components/networks.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:super_tooltip/super_tooltip.dart';

import 'base_actions.dart';

class TestDashboardHomeActions extends CommonBaseActions {
  TestDashboardHomeActions(super.tester);

  Finder topologyCardFinder() {
    tester;
    final networkCardFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(AppCard),
    );
    final topologyCard = networkCardFinder.at(1);
    expect(topologyCard, findsOneWidget);
    return topologyCard;
  }

  Finder devicesCardFinder() {
    final networkCardFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(AppCard),
    );
    final devicesCard = networkCardFinder.at(2);
    expect(devicesCard, findsOneWidget);
    return devicesCard;
  }

  Finder masterNodeDetailFinder() {
    final nodeDetailFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(SimpleTreeNodeItem),
    );
    // There may be more than one nodes in the network
    expect(nodeDetailFinder, findsAtLeastNWidgets(1));
    return nodeDetailFinder.first;
  }

  Finder nightModeInfoFinder() {
    final iconFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(Icon),
        )
        .last;
    expect(iconFinder, findsOneWidget);
    return iconFinder;
  }

  Finder nightModeTooltipFinder() {
    return find.byTooltip(
      'When enabled, the LED light will turn off between 8:00 PM and 8:00 AM.',
    );
  }

  Finder nightModeSwitchFinder() {
    final nightModeSwitchFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(AppSwitch),
        )
        .last;
    expect(nightModeSwitchFinder, findsOneWidget);
    return nightModeSwitchFinder;
  }

  Finder instantPrivacyInfoFinder() {
    final iconFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(Icon),
        )
        .first;
    expect(iconFinder, findsOneWidget);
    return iconFinder;
  }

  Finder instantPrivacyTooltipFinder() {
    return find.byTooltip(
      'Enabling Instant-Privacy prevents new devices from connecting to your network. To add a new device, disable Instant-Privacy, then re-enable it for enhanced security.',
    );
  }

  Finder instantPrivacySwitchFinder() {
    final instantPrivacySwitchFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(AppSwitch),
        )
        .first;
    expect(instantPrivacySwitchFinder, findsOneWidget);
    return instantPrivacySwitchFinder;
  }

  Finder instantPrivacyInkWellFinder() {
    final instantPrivacyFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(InkWell),
        )
        .first;
    expect(instantPrivacyFinder, findsOneWidget);
    return instantPrivacyFinder;
  }

  Finder wifi24gTooltipFinder() {
    final tooltipFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(SuperTooltip),
    );
    expect(tooltipFinder, findsNWidgets(3));
    return tooltipFinder.at(0);
  }

  Finder wifi24gSwitchFinder() {
    final switchFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsNWidgets(3));
    return switchFinder.at(0);
  }

  Finder wifi24gCardFinder() {
    final wifiCardFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppCard),
    );
    expect(wifiCardFinder, findsNWidgets(3));
    return wifiCardFinder.at(0);
  }

  Finder wifi5gTooltipFinder() {
    final tooltipFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(SuperTooltip),
    );
    expect(tooltipFinder, findsNWidgets(3));
    return tooltipFinder.at(1);
  }

  Finder wifi5gSwitchFinder() {
    final switchFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsNWidgets(3));
    return switchFinder.at(1);
  }

  Finder wifi5gCardFinder() {
    final wifiCardFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppCard),
    );
    expect(wifiCardFinder, findsNWidgets(3));
    return wifiCardFinder.at(1);
  }

  Finder guestWifiTooltipFinder() {
    final tooltipFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(SuperTooltip),
    );
    expect(tooltipFinder, findsNWidgets(3));
    return tooltipFinder.at(2);
  }

  Finder guestWifiSwitchFinder() {
    final switchFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsNWidgets(3));
    return switchFinder.at(2);
  }

  Finder guestWifiCardFinder() {
    final wifiCardFinder = find.descendant(
      of: find.byType(WiFiCard),
      matching: find.byType(AppCard),
    );
    expect(wifiCardFinder, findsNWidgets(3));
    return wifiCardFinder.at(2);
  }

  Future<void> checkTopologyPage() async {
    // Find topology card
    final topologyCard = topologyCardFinder();
    // Scroll the screen
    await scrollUntil(topologyCard);
    // Tap the card
    await tester.tap(topologyCard);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> checkDeviceListPage() async {
    // Find devices card
    final devicesCard = devicesCardFinder();
    // Tap the card
    await tester.tap(devicesCard);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> checkMasterNodeDetailPage() async {
    // Find tappable area of master node
    final masterFinder = masterNodeDetailFinder();
    // Scroll the screen
    await scrollUntil(masterFinder);
    // Tap the node detail
    await tester.tap(masterFinder);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> hoverToNightModeInfoIcon() async {
    // Find night mode info icon
    final iconFinder = nightModeInfoFinder();
    // scroll the screen
    await scrollUntil(iconFinder);
    await _hoverToCenter(iconFinder);
    expect(nightModeTooltipFinder(), findsOneWidget);
    await tester.pumpFrames(app(), Duration(seconds: 1));
  }

  Future<void> toggleNightMode() async {
    // Find night mode switch
    final switchFinder = nightModeSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hoverToInstantPrivacyInfoIcon() async {
    // Find instant privacy info icon
    final iconFinder = instantPrivacyInfoFinder();
    await _hoverToCenter(iconFinder);
    expect(instantPrivacyTooltipFinder(), findsOneWidget);
    await tester.pumpFrames(app(), Duration(seconds: 1));
  }

  Future<void> toggleInstantPrivacy() async {
    // Find instant privacy switch
    final switchFinder = instantPrivacySwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    // Tap cancel button
    await _tapCancelOnInstantPrivacyDialog();
    // Again, tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    await _tapOkOnInstantPrivacyDialog();
  }

  Future<void> checkInstantPrivacyPage() async {
    // Find tappable area of instant privacy
    final inkWellFinder = instantPrivacyInkWellFinder();
    // Tap the instant privacy
    await tester.tap(inkWellFinder);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> hoverToWifi24gQrIcon() async {
    // Find 2.4G Wifi QR code icon
    final tooltipFinder = wifi24gTooltipFinder();
    // scroll the screen
    await scrollUntil(tooltipFinder);
    await _hoverToCenter(tooltipFinder);
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.pumpAndSettle();
  }

  Future<void> toggle24gWifi() async {
    // Find Wifi 2.4G switch
    final switchFinder = wifi24gSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> checkWifi24gPage() async {
    // Find Wifi 2.4G card
    final wifiCardFinder = wifi24gCardFinder();
    // Tap the card
    await tester.tap(wifiCardFinder);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> hoverToWifi5gQrIcon() async {
    // Find 5G Wifi switch
    final tooltipFinder = wifi5gTooltipFinder();
    // scroll the screen
    await scrollUntil(tooltipFinder);
    await _hoverToCenter(tooltipFinder);
    // If 5g wifi is disabled, there will be no QR code image
    expect(find.byType(QrImageView), findsAtLeastNWidgets(0));
    await tester.pumpAndSettle();
  }

  Future<void> toggle5gWifi() async {
    // Find 5G Wifi switch
    final switchFinder = wifi5gSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> checkWifi5gPage() async {
    // Find 5G Wifi card
    final wifiCardFinder = wifi5gCardFinder();
    // Tap the card
    await tester.tap(wifiCardFinder);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> hoverToGuestWifiQrIcon() async {
    // Find guest Wifi QR code icon
    final tooltipFinder = guestWifiTooltipFinder();
    // scroll the screen
    await scrollUntil(tooltipFinder);
    await _hoverToCenter(tooltipFinder);
    // If guest wifi is disabled, there will be no QR code image
    expect(find.byType(QrImageView), findsAtLeastNWidgets(0));
    await tester.pumpAndSettle();
  }

  Future<void> toggleGuestWifi() async {
    // Find guest Wifi switch
    final switchFinder = guestWifiSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> checkGuestWifiPage() async {
    // Find guest Wifi card
    final wifiCardFinder = guestWifiCardFinder();
    // Tap the card
    await tester.tap(wifiCardFinder);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> _tapCancelOnInstantPrivacyDialog() async {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    // Find the cancel button
    final dialogButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the cancel button
    await tester.tap(dialogButtonFinder.first);
    await tester.pumpAndSettle();
  }

  Future<void> _tapOkOnInstantPrivacyDialog() async {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    // Find the Ok button
    final dialogButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the Ok button
    await tester.tap(dialogButtonFinder.last);
    await tester.pumpAndSettle();
  }

  Future<void> _hoverToCenter(Finder finder) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    // Explicitly remove the pointer after the hover action
    await gesture.removePointer();
  }
}
