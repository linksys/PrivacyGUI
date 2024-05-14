import 'dart:ui';

class ScreenSize {
  const ScreenSize(this.name, this.width, this.height, this.pixelDensity);
  final String name;
  final double width, height, pixelDensity;

  @override
  String toString() => '$name($width, $height, $pixelDensity)';
  String toShort() => name;
}

class LocalizedScreen extends ScreenSize {
  final Locale locale;

  LocalizedScreen(
    String name, {
    required this.locale,
    required double width,
    required double height,
    double pixelDensity = 1.0,
  }) : super(
          name,
          width,
          height,
          pixelDensity,
        );
  factory LocalizedScreen.fromScreenSize(
          {required Locale locale, required ScreenSize screen}) =>
      LocalizedScreen(
        screen.name,
        locale: locale,
        width: screen.width,
        height: screen.height,
      );

  @override
  String toString() =>
      '$name-${locale.languageCode}_${locale.countryCode ?? ''}($width, $height, $pixelDensity)';
  @override
  String toShort() => '$name-${locale.toLanguageTag()}';
}
