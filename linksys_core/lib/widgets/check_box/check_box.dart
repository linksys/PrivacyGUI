import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/text/app_text.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox(
      {super.key, required this.value, this.text, this.onChanged});

  final bool value;
  final String? text;
  final void Function(bool?)? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final text = this.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          side: BorderSide(color: theme.colors.textBoxText),
          checkColor: onChanged == null
              ? theme.colors.textBoxText.withOpacity(0.48)
              : theme.colors.textBoxText,
          fillColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
            var color = ConstantColors.transparent;
            if (states.contains(MaterialState.selected)) {
              color = ConstantColors.primaryLinksysBlue;
            }
            if (states.contains(MaterialState.disabled) &&
                states.contains(MaterialState.selected)) {
              return theme.colors.ctaSecondaryDisable;
            }
            return color;
          }),
          value: value,
          onChanged: onChanged,
        ),
        ..._buildText(text, onChanged != null),
      ],
    );
  }

  List<Widget> _buildText(String? text, bool enabled) {
    if (text != null) {
      final textWidget = enabled
          ? AppText.textLinkTertiarySmall(text)
          : AppText.descriptionSub(text);
      return [const AppGap.small(), textWidget];
    } else {
      return [];
    }
  }
}
