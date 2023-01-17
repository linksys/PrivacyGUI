import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:linksys_core/utils/named.dart';

class AppImagesData extends Equatable {

  const AppImagesData({
    required this.defaultAvatar1,
    required this.defaultAvatar2,
    required this.defaultAvatar3,
    required this.defaultAvatar4,
    required this.defaultAvatar5,
    required this.defaultAvatar6,
    required this.defaultAvatar7,
    required this.defaultAvatar8,
    required this.defaultAvatar9,
    required this.defaultAvatar10,
    required this.defaultAvatar11,
    required this.defaultAvatar12,
    required this.tempIllustration,
    required this.dashboardBg1,
    required this.dashboardBg2,
    required this.dashboardBg3,
    required this.brandTinder,
    required this.deviceSmartPhone,
    required this.deviceLaptop,
    required this.signalExcellent,
    required this.signalGood,
  });

  factory AppImagesData.dark() =>
      const AppImagesData(
        defaultAvatar1: AssetImage('assets/avatars/green_a_80px.png', package: 'linksys_core'),
        defaultAvatar2: AssetImage('assets/avatars/green_b_80px.png', package: 'linksys_core'),
        defaultAvatar3: AssetImage('assets/avatars/green_c_80px.png', package: 'linksys_core'),
        defaultAvatar4: AssetImage('assets/avatars/violet_a_80px.png', package: 'linksys_core'),
        defaultAvatar5: AssetImage('assets/avatars/violet_b_80px.png', package: 'linksys_core'),
        defaultAvatar6: AssetImage('assets/avatars/violet_c_80px.png', package: 'linksys_core'),
        defaultAvatar7: AssetImage('assets/avatars/blue_a_80px.png', package: 'linksys_core'),
        defaultAvatar8: AssetImage('assets/avatars/blue_b_80px.png', package: 'linksys_core'),
        defaultAvatar9: AssetImage('assets/avatars/blue_c_80px.png', package: 'linksys_core'),
        defaultAvatar10: AssetImage('assets/avatars/yellow_a_80px.png', package: 'linksys_core'),
        defaultAvatar11: AssetImage('assets/avatars/yellow_b_80px.png', package: 'linksys_core'),
        defaultAvatar12: AssetImage('assets/avatars/yellow_c_80px.png', package: 'linksys_core'),
        tempIllustration: AssetImage('assets/images/temp_illustration.png', package: 'linksys_core'),
        dashboardBg1: AssetImage('assets/images/bg_dashboard_dark_01.png', package: 'linksys_core'),
        dashboardBg2: AssetImage('assets/images/bg_dashboard_dark_02.png', package: 'linksys_core'),
        dashboardBg3: AssetImage('assets/images/bg_dashboard_dark_03.png', package: 'linksys_core'),
        brandTinder: AssetImage('assets/images/brand_tinder.png', package: 'linksys_core'),
        deviceSmartPhone: AssetImage('assets/images/device_smart_phone.png', package: 'linksys_core'),
        deviceLaptop: AssetImage('assets/images/device_laptop.png', package: 'linksys_core'),
        signalExcellent: AssetImage('assets/images/signal_excellent.png', package: 'linksys_core'),
        signalGood: AssetImage('assets/images/signal_good.png', package: 'linksys_core'),
      );

  factory AppImagesData.light() =>
      const AppImagesData(
        defaultAvatar1: AssetImage('assets/avatars/green_a_80px.png', package: 'linksys_core'),
        defaultAvatar2: AssetImage('assets/avatars/green_b_80px.png', package: 'linksys_core'),
        defaultAvatar3: AssetImage('assets/avatars/green_c_80px.png', package: 'linksys_core'),
        defaultAvatar4: AssetImage('assets/avatars/violet_a_80px.png', package: 'linksys_core'),
        defaultAvatar5: AssetImage('assets/avatars/violet_b_80px.png', package: 'linksys_core'),
        defaultAvatar6: AssetImage('assets/avatars/violet_c_80px.png', package: 'linksys_core'),
        defaultAvatar7: AssetImage('assets/avatars/blue_a_80px.png', package: 'linksys_core'),
        defaultAvatar8: AssetImage('assets/avatars/blue_b_80px.png', package: 'linksys_core'),
        defaultAvatar9: AssetImage('assets/avatars/blue_c_80px.png', package: 'linksys_core'),
        defaultAvatar10: AssetImage('assets/avatars/yellow_a_80px.png', package: 'linksys_core'),
        defaultAvatar11: AssetImage('assets/avatars/yellow_b_80px.png', package: 'linksys_core'),
        defaultAvatar12: AssetImage('assets/avatars/yellow_c_80px.png', package: 'linksys_core'),
        tempIllustration: AssetImage('assets/images/temp_illustration.png', package: 'linksys_core'),
        dashboardBg1: AssetImage('assets/images/bg_dashboard_light_01.png', package: 'linksys_core'),
        dashboardBg2: AssetImage('assets/images/bg_dashboard_light_02.png', package: 'linksys_core'),
        dashboardBg3: AssetImage('assets/images/bg_dashboard_light_03.png', package: 'linksys_core'),
        brandTinder: AssetImage('assets/images/brand_tinder.png', package: 'linksys_core'),
        deviceSmartPhone: AssetImage('assets/images/device_smart_phone.png', package: 'linksys_core'),
        deviceLaptop: AssetImage('assets/images/device_laptop.png', package: 'linksys_core'),
        signalExcellent: AssetImage('assets/images/signal_excellent.png', package: 'linksys_core'),
        signalGood: AssetImage('assets/images/signal_good.png', package: 'linksys_core'),
      );

  final ImageProvider defaultAvatar1;
  final ImageProvider defaultAvatar2;
  final ImageProvider defaultAvatar3;
  final ImageProvider defaultAvatar4;
  final ImageProvider defaultAvatar5;
  final ImageProvider defaultAvatar6;
  final ImageProvider defaultAvatar7;
  final ImageProvider defaultAvatar8;
  final ImageProvider defaultAvatar9;
  final ImageProvider defaultAvatar10;
  final ImageProvider defaultAvatar11;
  final ImageProvider defaultAvatar12;
  final ImageProvider tempIllustration;
  final ImageProvider dashboardBg1;
  final ImageProvider dashboardBg2;
  final ImageProvider dashboardBg3;
  final ImageProvider brandTinder;
  final ImageProvider deviceSmartPhone;
  final ImageProvider deviceLaptop;
  final ImageProvider signalExcellent;
  final ImageProvider signalGood;

  @override
  List<Named<dynamic>> get props =>
      [
        defaultAvatar1.named('defaultAvatar1'),
        defaultAvatar2.named('defaultAvatar2'),
        defaultAvatar3.named('defaultAvatar3'),
        defaultAvatar4.named('defaultAvatar4'),
        defaultAvatar5.named('defaultAvatar5'),
        defaultAvatar6.named('defaultAvatar6'),
        defaultAvatar7.named('defaultAvatar7'),
        defaultAvatar8.named('defaultAvatar8'),
        defaultAvatar9.named('defaultAvatar9'),
        defaultAvatar10.named('defaultAvatar10'),
        defaultAvatar11.named('defaultAvatar11'),
        defaultAvatar12.named('defaultAvatar12'),
        tempIllustration.named('tempIllustration'),
        dashboardBg1.named('dashboardBg1'),
        dashboardBg2.named('dashboardBg2'),
        dashboardBg3.named('dashboardBg3'),
        brandTinder.named('brandTinder'),
        deviceSmartPhone.named('deviceSmartPhone'),
        deviceLaptop.named('deviceLaptop'),
        signalExcellent.named('signalExcellent'),
        signalGood.named('signalGood'),
      ];

}

final kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
]);
