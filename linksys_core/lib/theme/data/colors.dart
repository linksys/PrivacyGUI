import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';
import 'package:linksys_core/utils/named.dart';

class AppColorsData extends Equatable {
  final Color mainText;
  final Color firstButtonBackground;
  final Color secondButtonBackground;
  final Color secondButtonText;
  final Color textButton;
  final Color descriptionText;
  final Color errorText;
  // final Color accent;
  // final Color accentHighlight;
  // final Color accentHighlight2;
  // final Color foreground;
  // final Color accentOpposite;
  // final Color background;
  // final Color actionBarForeground;
  // final Color actionBarBackground;
  // final Color primaryBlue;
  // final Color disabled;

  const AppColorsData({
    required this.mainText,
    required this.firstButtonBackground,
    required this.secondButtonBackground,
    required this.secondButtonText,
    required this.textButton,
    required this.descriptionText,
    required this.errorText,
    // required this.accent,
    // required this.accentHighlight,
    // required this.accentHighlight2,
    // required this.foreground,
    // required this.background,
    // required this.actionBarBackground,
    // required this.actionBarForeground,
    // required this.accentOpposite,
    // required this.primaryBlue,
    // required this.disabled,
  });

  factory AppColorsData.light() => const AppColorsData(
    mainText: Color(0xFF000000),
    firstButtonBackground: Color(0xFFFFFFFF),
    secondButtonBackground: Color(0xFFB5B5B5),
    secondButtonText: Color(0xFFFFFFFF),
    textButton: Color(0xFF0870EA),
    descriptionText: Color(0xFF666666),
    errorText: Color(0xFFCF1A1A),


        // accent: Color(0xFF454CFF),
        // accentOpposite: Color(0xFFFFFFFF),
        // accentHighlight: Color(0xFF2D33B9),
        // accentHighlight2: Color(0xFF272C9A),
        // foreground: Color(0xFF000000),
        // background: Color(0xFFFFFFFF),
        // actionBarBackground: Color(0xFF000000),
        // actionBarForeground: Color(0xFFFFFFFF),
        // primaryBlue: Color(0xff0870EA),
        // disabled: Color(0x80cbcbcb),
  );

  factory AppColorsData.dark() => const AppColorsData(
    mainText: Color(0xFFFFFFFF),
    firstButtonBackground: Color(0xFF7244DB),
    secondButtonBackground: Color(0xFF29A82B),
    secondButtonText: Color(0xFFE30342),
    textButton: Color(0xFF13E4EA),
    descriptionText: Color(0xFFEFE571),
    errorText: Color(0xFFEE07AC),
        // accent: Color(0xFF454CFF),
        // accentOpposite: Color(0xFFFFFFFF),
        // accentHighlight: Color(0xFF2D33B9),
        // accentHighlight2: Color(0xFF272C9A),
        // foreground: Color(0xFFFFFFFF),
        // background: Color(0xFF111111),
        // actionBarBackground: Color(0xFF000000),
        // actionBarForeground: Color(0xFFFFFFFF),
        // primaryBlue: Color(0xff0870EA),
        // disabled: Color(0x80cbcbcb),
  );

  @override
  List<Object?> get props => [
    mainText.named('mainContext'),
    firstButtonBackground.named('firstButtonBackground'),
    secondButtonBackground.named('secondButtonBackground'),
    secondButtonText.named('secondButtonText'),
    textButton.named('textButton'),
    descriptionText.named('descriptionText'),
    errorText.named('errorText'),
        // accent.named('accent'),
        // accentHighlight.named('accentHighlight'),
        // accentHighlight2.named('accentHighlight2'),
        // foreground.named('foreground'),
        // accentOpposite.named('accentOpposite'),
        // background.named('background'),
        // actionBarForeground.named('actionBarForeground'),
        // actionBarBackground.named('actionBarBackground'),
        // primaryBlue.named('primaryBlue'),
    ];
}
