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
  final Color progressBackground;
  final Color progressForeground;

  const AppColorsData({
    required this.mainText,
    required this.firstButtonBackground,
    required this.secondButtonBackground,
    required this.secondButtonText,
    required this.textButton,
    required this.descriptionText,
    required this.errorText,
    required this.progressBackground,
    required this.progressForeground,
  });

  factory AppColorsData.light() => const AppColorsData(
        mainText: Color(0xFF000000),
        firstButtonBackground: Color(0xFFFFFFFF),
        secondButtonBackground: Color(0xFFB5B5B5),
        secondButtonText: Color(0xFFFFFFFF),
        textButton: Color(0xFF0870EA),
        descriptionText: Color(0xFF666666),
        errorText: Color(0xFFCF1A1A),
        progressBackground: Color(0xFF005CE6),
        progressForeground: Color(0xFF63EA71),
      );

  factory AppColorsData.dark() => const AppColorsData(
        mainText: Color(0xFFFFFFFF),
        firstButtonBackground: Color(0xFF7244DB),
        secondButtonBackground: Color(0xFF29A82B),
        secondButtonText: Color(0xFFE30342),
        textButton: Color(0xFF13E4EA),
        descriptionText: Color(0xFFEFE571),
        errorText: Color(0xFFEE07AC),
        progressBackground: Color(0xFF7A9CD7),
        progressForeground: Color(0xFFCFF8D4),
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
        progressBackground.named('progressBackground'),
        progressForeground.named('progressForeground'),
      ];
}
