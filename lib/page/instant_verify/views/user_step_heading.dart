import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

/// A full-width action band using the application's color and type tokens.
class UserStepHeading extends StatelessWidget {
  const UserStepHeading(this.text, {super.key, this.centered = false});
  final String text;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.medium, vertical: Spacing.small3),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          border: Border(left: BorderSide(color: colors.primary, width: 3)),
        ),
        child: AppText.titleSmall(text,
            color: colors.onPrimaryContainer,
            textAlign: centered ? TextAlign.center : TextAlign.start),
      ),
    );
  }
}
