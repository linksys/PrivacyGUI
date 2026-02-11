import 'dart:ui';

import 'theme_config.dart';

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
      '$name-${locale.toLanguageTag()}($width, $height, $pixelDensity)';
  @override
  String toShort() => '$name-${locale.toLanguageTag()}';
}

/// A screen variant that includes locale and theme information.
///
/// Used for generating screenshot test variants across locale x screen x theme combinations.
class ThemedScreen extends LocalizedScreen {
  final ThemeVariant theme;

  ThemedScreen(
    super.name, {
    required super.locale,
    required this.theme,
    required super.width,
    required super.height,
    super.pixelDensity = 1.0,
  });

  factory ThemedScreen.fromLocalizedScreen({
    required LocalizedScreen screen,
    required ThemeVariant theme,
  }) =>
      ThemedScreen(
        screen.name,
        locale: screen.locale,
        theme: theme,
        width: screen.width,
        height: screen.height,
        pixelDensity: screen.pixelDensity,
      );

  @override
  String toString() =>
      '$name-${locale.toLanguageTag()}-${theme.name}($width, $height, $pixelDensity)';

  @override
  String toShort() => '$name-${locale.toLanguageTag()}-${theme.name}';
}
