import 'package:flutter/material.dart';

/// A compact cue for a question or action the customer can act on.
class UserStepHeading extends StatelessWidget {
  const UserStepHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      header: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            border: Border(left: BorderSide(color: colors.primary, width: 3)),
          ),
          child: Text(text,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }
}
