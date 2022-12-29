import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';
import 'package:linksys_core/utils/named.dart';

class AppTypographyData extends Equatable {
  final TextStyle mainTitle;
  final TextStyle screenName;
  final TextStyle subhead;
  final TextStyle inputFieldText;
  final TextStyle flavorText;
  final TextStyle label;
  final TextStyle tags;
  final TextStyle navLabel;
  final TextStyle textLinkLarge;
  final TextStyle textLinkSmall;
  final TextStyle textLinkSecondaryLarge;
  final TextStyle textLinkTertiarySmall;
  final TextStyle descriptionMain;
  final TextStyle descriptionSub;

  const AppTypographyData({
    required this.mainTitle,
    required this.screenName,
    required this.subhead,
    required this.inputFieldText,
    required this.flavorText,
    required this.label,
    required this.tags,
    required this.navLabel,
    required this.textLinkLarge,
    required this.textLinkSmall,
    required this.textLinkSecondaryLarge,
    required this.textLinkTertiarySmall,
    required this.descriptionMain,
    required this.descriptionSub,
  });

  @override
  List<Named<TextStyle>?> get props => [
        mainTitle.named('mainTitle'),
        screenName.named('screenName'),
        subhead.named('subhead'),
        inputFieldText.named('inputFieldText'),
        flavorText.named('flavorText'),
        label.named('label'),
        tags.named('tags'),
        navLabel.named('navLabel'),
        textLinkLarge.named('textLinkLarge'),
        textLinkSmall.named('textLinkSmall'),
        textLinkSecondaryLarge.named('textLinkSecondaryLarge'),
        textLinkTertiarySmall.named('textLinkTertiarySmall'),
        descriptionMain.named('descriptionMain'),
        descriptionSub.named('descriptionSub'),
      ];

  factory AppTypographyData.regular() => const AppTypographyData(
        mainTitle: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontWeight: FontWeight.w700,
          fontSize: 32,
          decoration: TextDecoration.none,
          height: 1.5,
        ),
        screenName: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontWeight: FontWeight.w700,
          fontSize: 24,
          decoration: TextDecoration.none,
        ),
        subhead: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          height: 1.5,
        ),
        inputFieldText: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
          height: 1.5,
        ),
        flavorText: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
          height: 1.5,
          letterSpacing: 0.02,
        ),
        label: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
          height: 1.5,
          letterSpacing: 0.01,
        ),
        tags: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          height: 1.5,
          letterSpacing: 0.02,
        ),
        navLabel: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          height: 1.5,
          letterSpacing: 0.02,
        ),
        textLinkLarge: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          height: 1.5,
        ),
        textLinkSmall: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          height: 1.5,
          letterSpacing: 0.02,
        ),
        textLinkSecondaryLarge: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          height: 1.5,
          letterSpacing: 0.01,
        ),
        textLinkTertiarySmall: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
          height: 1.5,
          letterSpacing: 0.02,
        ),
        descriptionMain: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
          height: 1.5,
        ),
        descriptionSub: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
          height: 1.5,
          letterSpacing: 0.02,
        ),
      );

  // factory AppTypographyData.small() => const AppTypographyData(
  //       paragraph1: TextStyle(
  //         fontFamily: 'Poppins',
  //         package: 'asgard_core',
  //         fontWeight: FontWeight.w400,
  //         fontSize: 10,
  //         decoration: TextDecoration.none,
  //       ),
  //       paragraph2: TextStyle(
  //         fontFamily: 'Poppins',
  //         package: 'asgard_core',
  //         fontWeight: FontWeight.w400,
  //         fontSize: 9,
  //         decoration: TextDecoration.none,
  //       ),
  //       title1: TextStyle(
  //         fontFamily: 'Poppins',
  //         package: 'asgard_core',
  //         fontSize: 20,
  //         fontWeight: FontWeight.bold,
  //         decoration: TextDecoration.none,
  //       ),
  //       title2: TextStyle(
  //         fontFamily: 'Poppins',
  //         package: 'asgard_core',
  //         fontSize: 14,
  //         fontWeight: FontWeight.bold,
  //         decoration: TextDecoration.none,
  //       ),
  //       title3: TextStyle(
  //         fontFamily: 'Poppins',
  //         package: 'asgard_core',
  //         fontSize: 12,
  //         fontWeight: FontWeight.bold,
  //         decoration: TextDecoration.none,
  //       ),
  //     );

}
