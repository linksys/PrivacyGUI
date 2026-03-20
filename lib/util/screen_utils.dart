import 'dart:io';

import 'package:flutter/material.dart';

class MediaQueryUtils {
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getScreenRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  static Size getPhysicalScreenSize(BuildContext context) {
    return getScreenSize(context) * getScreenRatio(context);
  }

  static double getPhysicalScreenWidth(BuildContext context) {
    return getScreenWidth(context) * getScreenRatio(context);
  }

  static double getPhysicalScreenHeight(BuildContext context) {
    return getScreenHeight(context) * getScreenRatio(context);
  }

  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0);
  }

  static double getTopSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static double getBottomSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  static double getSafeAreaHeight(BuildContext context) {
    return getScreenHeight(context) -
        getTopSafeAreaPadding(context) -
        getBottomSafeAreaPadding(context);
  }

  static String getLanguageCode() {
    List<String> localeNames = Platform.localeName.split('_');

    return localeNames.length > 1 ? localeNames.first : Platform.localeName;
  }

  static String getCountryCode() {
    List<String> localeNames = Platform.localeName.split('_');

    return localeNames.length > 1 ? localeNames.last : Platform.localeName;
  }
}
