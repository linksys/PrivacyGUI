import 'dart:ui';

class ScreenSize {
  const ScreenSize(this.name, this.width, this.height, this.pixelDensity);
  final String name;
  final double width;
  final double height;
  final double pixelDensity;

  @override
  String toString() => '$name($width, $height, $pixelDensity)';
  String toShort() => name;

  ScreenSize copyWith({
    String? name,
    double? width,
    double? height,
    double? pixelDensity,
  }) {
    return ScreenSize(
      name ?? this.name,
      width ?? this.width,
      height ?? this.height,
      pixelDensity ?? this.pixelDensity,
    );
  }
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
