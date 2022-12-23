import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';
import 'package:linksys_core/utils/named.dart';

class AppTypographyData extends Equatable {
  final TextStyle roman11;
  final TextStyle roman13;
  final TextStyle roman15;
  final TextStyle roman17;
  final TextStyle roman21;
  final TextStyle roman25;
  final TextStyle roman31;
  final TextStyle bold11;
  final TextStyle bold13;
  final TextStyle bold15;
  final TextStyle bold17;
  final TextStyle bold19;
  final TextStyle bold23;
  final TextStyle bold27;

  const AppTypographyData({
    required this.roman11,
    required this.roman13,
    required this.roman15,
    required this.roman17,
    required this.roman21,
    required this.roman25,
    required this.roman31,
    required this.bold11,
    required this.bold13,
    required this.bold15,
    required this.bold17,
    required this.bold19,
    required this.bold23,
    required this.bold27,
  });

  @override
  List<Object?> get props => [
        roman11.named('roman11'),
        roman13.named('roman13'),
        roman15.named('roman15'),
        roman17.named('roman17'),
        roman21.named('roman21'),
        roman25.named('roman25'),
        roman31.named('roman31'),
        bold11.named('bold11'),
        bold13.named('bold13'),
        bold15.named('bold15'),
        bold17.named('bold17'),
        bold19.named('bold19'),
        bold23.named('bold23'),
        bold27.named('bold27'),
      ];

  factory AppTypographyData.regular() => const AppTypographyData(
        roman11: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontWeight: FontWeight.w400,
          fontSize: 11,
          decoration: TextDecoration.none,
        ),
        roman13: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontWeight: FontWeight.w400,
          fontSize: 13,
          decoration: TextDecoration.none,
        ),
        roman15: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
        roman17: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 17,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
        roman21: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 21,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
        roman25: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 25,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
        roman31: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 31,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
        bold11: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
        bold13: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
        bold15: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
        bold17: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
        bold19: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
        bold23: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 23,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
        bold27: TextStyle(
          fontFamily: 'NeueHaasGrotTextRound',
          package: 'linksys_core',
          fontSize: 27,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
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
