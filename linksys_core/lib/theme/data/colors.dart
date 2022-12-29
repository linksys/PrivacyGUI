import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';
import 'package:linksys_core/utils/named.dart';

class AppColorsData extends Equatable {
  final Color ctaPrimary;
  final Color ctaPrimaryDisable;
  final Color ctaSecondary;
  final Color ctaSecondaryDisable;
  final Color textBoxApproved;
  final Color textBoxStrokeHovered;
  final Color textBoxText;
  final Color textBoxBox;
  final Color textBoxBoxDisabled;
  final Color textBoxIcon;
  final Color textBoxTextDisabled;
  final Color textBoxTextAlert;
  final Color tertiaryText;
  final Color tertiaryInputTextDisabled;

  const AppColorsData({
    required this.ctaPrimary,
    required this.ctaPrimaryDisable,
    required this.ctaSecondary,
    required this.ctaSecondaryDisable,
    required this.textBoxApproved,
    required this.textBoxStrokeHovered,
    required this.textBoxText,
    required this.textBoxBox,
    required this.textBoxBoxDisabled,
    required this.textBoxIcon,
    required this.textBoxTextDisabled,
    required this.textBoxTextAlert,
    required this.tertiaryText,
    required this.tertiaryInputTextDisabled,
  });

  factory AppColorsData.light() => const AppColorsData(
        ctaPrimary: Color(0xFFFAFAFA),
        ctaPrimaryDisable: Color(0xFF898989),
        ctaSecondary: Color(0xFF5EA8FF),
        ctaSecondaryDisable: Color(0xFF314F72),
        textBoxApproved: Color(0xFF0DEA08),
        textBoxStrokeHovered: Color(0xFFCCCCCC),
        textBoxText: Color(0xFF2C2C2C),
        textBoxBox: Color(0xFFFAFAFA),
        textBoxBoxDisabled: Color(0xFF3B3B3B),
        textBoxIcon: Color(0xFFD9D9D9),
        textBoxTextDisabled: Color(0xFF575757),
        textBoxTextAlert: Color(0xFFFF595E),
        tertiaryText: Color(0xFF2C2C2C),
        tertiaryInputTextDisabled: Color(0xFF2D2D2D),
      );

  factory AppColorsData.dark() => const AppColorsData(
        ctaPrimary: Color(0xFFFAFAFA),
        ctaPrimaryDisable: Color(0xFF898989),
        ctaSecondary: Color(0xFF5EA8FF),
        ctaSecondaryDisable: Color(0xFF314F72),
        textBoxApproved: Color(0xFF0DEA08),
        textBoxStrokeHovered: Color(0xFFCCCCCC),
        textBoxText: Color(0xFFFAFAFA),
        textBoxBox: Color(0xFF272727),
        textBoxBoxDisabled: Color(0xFF3B3B3B),
        textBoxIcon: Color(0xFFD9D9D9),
        textBoxTextDisabled: Color(0xFF575757),
        textBoxTextAlert: Color(0xFFFF595E),
        tertiaryText: Color(0xFFFAFAFA),
        tertiaryInputTextDisabled: Color(0xFF2D2D2D),
      );

  @override
  List<Named<Color>?> get props => [
        ctaPrimary.named('ctaPrimary'),
        ctaPrimaryDisable.named('ctaPrimaryDisable'),
        ctaSecondary.named('ctaSecondary'),
        ctaSecondaryDisable.named('ctaSecondaryDisable'),
        textBoxApproved.named('textBoxApproved'),
        textBoxStrokeHovered.named('textBoxStrokeHovered'),
        textBoxText.named('textBoxText'),
        textBoxBox.named('textBoxBox'),
        textBoxBoxDisabled.named('textBoxBoxDisabled'),
        textBoxIcon.named('textBoxIcon'),
        textBoxTextDisabled.named('textBoxTextDisabled'),
        textBoxTextAlert.named('textBoxTextAlert'),
        tertiaryText.named('tertiaryText'),
        tertiaryInputTextDisabled.named('tertiaryInputTextDisabled'),
      ];
}

class ConstantColors extends Equatable  {
  static const transparent = Color(0x00000000);
  static const primaryLinksysBlue = Color(0xFF0870EA);
  static const primaryLinksysBlack = Color(0xFF000000);
  static const primaryLinksysWhite = Color(0xFFFFFFFF);
  static const secondaryBoostedGold = Color(0xFFFCC225);
  static const secondaryElectricGreen = Color(0xFF64ED73);
  static const secondaryCyberPurple = Color(0xFFD382FF);
  static const secondaryClearBlue = Color(0xFF88DAFF);
  static const secondaryBoostedGoldDisabled = Color(0xFF715A1B);
  static const secondaryElectricGreenDisabled = Color(0xFF346B3A);
  static const secondaryCyberPurpleDisabled = Color(0xFF604072);
  static const secondaryClearBlueDisabled = Color(0xFF426372);
  static const textBoxTextGray = Color(0xFFC0C0C0);
  static const tertiaryRed = Color(0xFFEA0808);
  static const tertiaryGreen = Color(0xFF0DEA08);
  static const tertiaryYellow = Color(0xFFEAD308);
  static const tertiaryRedDisabled = Color(0xFF6A0F0F);
  static const tertiaryGreenDisabled = Color(0xFF116A0F);
  static const tertiaryYellowDisabled = Color(0xFF6A600F);
  static const tertiaryTextGray = Color(0xFF898989);
  static const baseTextBoxWhiteDisabled = Color(0xFF3B3B3B);
  static const baseTextBoxBlueDisabled = Color(0xFF0F396A);
  static const baseTextBoxWhite = Color(0xFFE0E0E0);
  static const basePrimaryGray = Color(0xFF141414);
  static const baseSecondaryGray = Color(0xFF292929);
  static const baseTertiaryGray = Color(0xFF757575);

  @override
  List<Named<Color>?> get props => [
    transparent.named('transparent'),
    primaryLinksysBlue.named('primaryLinksysBlue'),
    primaryLinksysBlack.named('primaryLinksysBlack'),
    primaryLinksysWhite.named('primaryLinksysWhite'),
    secondaryBoostedGold.named('secondaryBoostedGold'),
    secondaryElectricGreen.named('secondaryElectricGreen'),
    secondaryCyberPurple.named('secondaryCyberPurple'),
    secondaryClearBlue.named('secondaryClearBlue'),
    secondaryBoostedGoldDisabled.named('secondaryBoostedGoldDisabled'),
    secondaryElectricGreenDisabled.named('secondaryElectricGreenDisabled'),
    secondaryCyberPurpleDisabled.named('secondaryCyberPurpleDisabled'),
    secondaryClearBlueDisabled.named('secondaryClearBlueDisabled'),
    textBoxTextGray.named('textBoxTextGray'),
    tertiaryRed.named('tertiaryRed'),
    tertiaryGreen.named('tertiaryGreen'),
    tertiaryYellow.named('tertiaryYellow'),
    tertiaryRedDisabled.named('tertiaryRedDisabled'),
    tertiaryGreenDisabled.named('tertiaryGreenDisabled'),
    tertiaryYellowDisabled.named('tertiaryYellowDisabled'),
    tertiaryTextGray.named('tertiaryTextGray'),
    baseTextBoxWhiteDisabled.named('baseTextBoxWhiteDisabled'),
    baseTextBoxBlueDisabled.named('baseTextBoxBlueDisabled'),
    baseTextBoxWhite.named('baseTextBoxWhite'),
    basePrimaryGray.named('basePrimaryGray'),
    baseSecondaryGray.named('baseSecondaryGray'),
    baseTertiaryGray.named('baseTertiaryGray'),
  ];
}