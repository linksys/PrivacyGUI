import 'package:equatable/equatable.dart';
import 'package:linksys_core/icons/linksys_icons.dart';
import 'package:linksys_core/utils/named.dart';

class AppIconsData extends Equatable {
  const AppIconsData({
    required this.characters,
    required this.sizes,
  });

  /// Icons have been exported with "Export Icon Font" Figma plugin.
  factory AppIconsData.regular() => AppIconsData(
        characters: LinksysIconsCharactersData.regular(),
        sizes: AppIconSizesData.regular(),
      );

  final LinksysIconsCharactersData characters;
  final AppIconSizesData sizes;

  @override
  List<Object?> get props => [
        characters,
        sizes,
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
