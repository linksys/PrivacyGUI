import 'package:equatable/equatable.dart';
import 'package:linksys_core/utils/named.dart';

class AppIconsData extends Equatable {
  const AppIconsData({
    required this.fontFamily,
    required this.fontPackage,
    required this.characters,
    required this.sizes,
  });

  /// Icons have been exported with "Export Icon Font" Figma plugin.
  factory AppIconsData.regular() => AppIconsData(
        fontFamily: 'LinksysIcons',
        fontPackage: 'linksys_core',
        characters: AppIconCharactersData.regular(),
        sizes: AppIconSizesData.regular(),
      );

  final String fontFamily;
  final String? fontPackage;
  final AppIconCharactersData characters;
  final AppIconSizesData sizes;

  @override
  List<Object?> get props => [
        fontFamily,
        fontPackage,
        characters,
        sizes,
      ];
}

class AppIconCharactersData extends Equatable {
  const AppIconCharactersData({
    required this.people,
  });

  factory AppIconCharactersData.regular() => AppIconCharactersData(
      people: String.fromCharCodes([57721, 60363]),);

  factory AppIconCharactersData.regularSVG() => AppIconCharactersData(
      people: 'assets/icons/icon_people.svg');

  final String people;

  @override
  List<Object?> get props => [
        people.named('people'),
      ];
}

class AppIconSizesData extends Equatable {
  const AppIconSizesData({
    required this.small,
    required this.regular,
    required this.big,
  });

  factory AppIconSizesData.regular() => const AppIconSizesData(
        small: 16.0,
        regular: 24.0,
        big: 32.0,
      );

  final double small;
  final double regular;
  final double big;

  @override
  List<Object?> get props => [
        small.named('small'),
        regular.named('regular'),
        big.named('big'),
      ];
}
