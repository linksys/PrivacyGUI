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
  final Color textBoxTextGray;
  final Color textBoxTextDisabled;
  final Color textBoxTextAlert;
  final Color primaryLinksysBlue;
  final Color primaryLinksysBlack;
  final Color primaryLinksysWhite;
  final Color secondaryBoostedGold;
  final Color secondaryElectricGreen;
  final Color secondaryCyberPurple;
  final Color secondaryClearBlue;
  final Color secondaryBoostedGoldDisabled;
  final Color secondaryElectricGreenDisabled;
  final Color secondaryCyberPurpleDisabled;
  final Color secondaryClearBlueDisabled;
  final Color tertiaryText;
  final Color tertiaryTextGray;
  final Color tertiaryInputTextDisabled;
  final Color tertiaryRed;
  final Color tertiaryGreen;
  final Color tertiaryYellow;
  final Color tertiaryRedDisabled;
  final Color tertiaryGreenDisabled;
  final Color tertiaryYellowDisabled;
  final Color baseTextBoxWhiteDisabled;
  final Color baseTextBoxBlueDisabled;
  final Color baseTextBoxWhite;
  final Color basePrimaryGray;
  final Color baseSecondaryGray;
  final Color baseTertiaryGray;

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
    required this.textBoxTextGray,
    required this.textBoxTextDisabled,
    required this.textBoxTextAlert,
    required this.primaryLinksysBlue,
    required this.primaryLinksysBlack,
    required this.primaryLinksysWhite,
    required this.secondaryBoostedGold,
    required this.secondaryElectricGreen,
    required this.secondaryCyberPurple,
    required this.secondaryClearBlue,
    required this.secondaryBoostedGoldDisabled,
    required this.secondaryElectricGreenDisabled,
    required this.secondaryCyberPurpleDisabled,
    required this.secondaryClearBlueDisabled,
    required this.tertiaryText,
    required this.tertiaryTextGray,
    required this.tertiaryInputTextDisabled,
    required this.tertiaryRed,
    required this.tertiaryGreen,
    required this.tertiaryYellow,
    required this.tertiaryRedDisabled,
    required this.tertiaryGreenDisabled,
    required this.tertiaryYellowDisabled,
    required this.baseTextBoxWhiteDisabled,
    required this.baseTextBoxBlueDisabled,
    required this.baseTextBoxWhite,
    required this.basePrimaryGray,
    required this.baseSecondaryGray,
    required this.baseTertiaryGray,
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
        textBoxTextGray: Color(0xFFC0C0C0),
        textBoxTextDisabled: Color(0xFF575757),
        textBoxTextAlert: Color(0xFFFF595E),
        primaryLinksysBlue: Color(0xFF0870EA),
        primaryLinksysBlack: Color(0xFF000000),
        primaryLinksysWhite: Color(0xFFFFFFFF),
        secondaryBoostedGold: Color(0xFFFCC225),
        secondaryElectricGreen: Color(0xFF64ED73),
        secondaryCyberPurple: Color(0xFFD382FF),
        secondaryClearBlue: Color(0xFF88DAFF),
        secondaryBoostedGoldDisabled: Color(0xFF715A1B),
        secondaryElectricGreenDisabled: Color(0xFF346B3A),
        secondaryCyberPurpleDisabled: Color(0xFF604072),
        secondaryClearBlueDisabled: Color(0xFF426372),
        tertiaryText: Color(0xFF2C2C2C),
        tertiaryTextGray: Color(0xFF898989),
        tertiaryInputTextDisabled: Color(0xFF2D2D2D),
        tertiaryRed: Color(0xFFEA0808),
        tertiaryGreen: Color(0xFF0DEA08),
        tertiaryYellow: Color(0xFFEAD308),
        tertiaryRedDisabled: Color(0xFF6A0F0F),
        tertiaryGreenDisabled: Color(0xFF116A0F),
        tertiaryYellowDisabled: Color(0xFF6A600F),
        baseTextBoxWhiteDisabled: Color(0xFF3B3B3B),
        baseTextBoxBlueDisabled: Color(0xFF0F396A),
        baseTextBoxWhite: Color(0xFFE0E0E0),
        basePrimaryGray: Color(0xFF141414),
        baseSecondaryGray: Color(0xFF292929),
        baseTertiaryGray: Color(0xFF757575),
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
        textBoxTextGray: Color(0xFF666666),
        textBoxTextDisabled: Color(0xFF575757),
        textBoxTextAlert: Color(0xFFFF595E),
        primaryLinksysBlue: Color(0xFF0870EA),
        primaryLinksysBlack: Color(0xFF000000),
        primaryLinksysWhite: Color(0xFFFFFFFF),
        secondaryBoostedGold: Color(0xFFFCC225),
        secondaryElectricGreen: Color(0xFF64ED73),
        secondaryCyberPurple: Color(0xFFD382FF),
        secondaryClearBlue: Color(0xFF88DAFF),
        secondaryBoostedGoldDisabled: Color(0xFF715A1B),
        secondaryElectricGreenDisabled: Color(0xFF346B3A),
        secondaryCyberPurpleDisabled: Color(0xFF604072),
        secondaryClearBlueDisabled: Color(0xFF426372),
        tertiaryText: Color(0xFFFAFAFA),
        tertiaryTextGray: Color(0xFF898989),
        tertiaryInputTextDisabled: Color(0xFF2D2D2D),
        tertiaryRed: Color(0xFFEA0808),
        tertiaryGreen: Color(0xFF0DEA08),
        tertiaryYellow: Color(0xFFEAD308),
        tertiaryRedDisabled: Color(0xFF6A0F0F),
        tertiaryGreenDisabled: Color(0xFF116A0F),
        tertiaryYellowDisabled: Color(0xFF6A600F),
        baseTextBoxWhiteDisabled: Color(0xFF3B3B3B),
        baseTextBoxBlueDisabled: Color(0xFF0F396A),
        baseTextBoxWhite: Color(0xFFE0E0E0),
        basePrimaryGray: Color(0xFF141414),
        baseSecondaryGray: Color(0xFF292929),
        baseTertiaryGray: Color(0xFF757575),
      );

  @override
  List<Object?> get props => [
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
        textBoxTextGray.named('textBoxTextGray'),
        textBoxTextDisabled.named('textBoxTextDisabled'),
        textBoxTextAlert.named('textBoxTextAlert'),
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
        tertiaryText.named('tertiaryText'),
        tertiaryTextGray.named('tertiaryTextGray'),
        tertiaryInputTextDisabled.named('tertiaryInputTextDisabled'),
        tertiaryRed.named('tertiaryRed'),
        tertiaryGreen.named('tertiaryGreen'),
        tertiaryYellow.named('tertiaryYellow'),
        tertiaryRedDisabled.named('tertiaryRedDisabled'),
        tertiaryGreenDisabled.named('tertiaryGreenDisabled'),
        tertiaryYellowDisabled.named('tertiaryYellowDisabled'),
        baseTextBoxWhiteDisabled.named('baseTextBoxWhiteDisabled'),
        baseTextBoxBlueDisabled.named('baseTextBoxBlueDisabled'),
        baseTextBoxWhite.named('baseTextBoxWhite'),
        basePrimaryGray.named('basePrimaryGray'),
        baseSecondaryGray.named('baseSecondaryGray'),
        baseTertiaryGray.named('baseTertiaryGray'),
      ];
}
