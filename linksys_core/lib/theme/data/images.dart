import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_core/utils/named.dart';
import 'package:linksys_core/utils/svg.dart';

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
  });

  factory AppImagesData.regular() =>
      AppImagesData(
        defaultAvatar1: exactAssetPicture('assets/avatars/avatar_default_green_1.svg'),
        defaultAvatar2: exactAssetPicture('assets/avatars/avatar_default_green_2.svg'),
        defaultAvatar3: exactAssetPicture('assets/avatars/avatar_default_green_3.svg'),
        defaultAvatar4: exactAssetPicture('assets/avatars/avatar_default_purple_1.svg'),
        defaultAvatar5: exactAssetPicture('assets/avatars/avatar_default_purple_2.svg'),
        defaultAvatar6: exactAssetPicture('assets/avatars/avatar_default_purple_3.svg'),
        defaultAvatar7: exactAssetPicture('assets/avatars/avatar_default_blue_1.svg'),
        defaultAvatar8: exactAssetPicture('assets/avatars/avatar_default_blue_2.svg'),
        defaultAvatar9: exactAssetPicture('assets/avatars/avatar_default_blue_3.svg'),
        defaultAvatar10: exactAssetPicture('assets/avatars/avatar_default_yellow_1.svg'),
        defaultAvatar11: exactAssetPicture('assets/avatars/avatar_default_yellow_2.svg'),
        defaultAvatar12: exactAssetPicture('assets/avatars/avatar_default_yellow_3.svg'),);


  final PictureProvider defaultAvatar1;
  final PictureProvider defaultAvatar2;
  final PictureProvider defaultAvatar3;
  final PictureProvider defaultAvatar4;
  final PictureProvider defaultAvatar5;
  final PictureProvider defaultAvatar6;
  final PictureProvider defaultAvatar7;
  final PictureProvider defaultAvatar8;
  final PictureProvider defaultAvatar9;
  final PictureProvider defaultAvatar10;
  final PictureProvider defaultAvatar11;
  final PictureProvider defaultAvatar12;

  @override
  List<Object> get props =>
      [
        defaultAvatar1,
        defaultAvatar2,
        defaultAvatar3,
        defaultAvatar4,
        defaultAvatar5,
        defaultAvatar6,
        defaultAvatar7,
        defaultAvatar8,
        defaultAvatar9,
        defaultAvatar10,
        defaultAvatar11,
        defaultAvatar12,
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
