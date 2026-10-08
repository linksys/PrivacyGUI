import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

/// An answered workflow question, collapsed to one line above the current
/// step. "Change" reopens the original choices in place.
class AnswerRow extends StatefulWidget {
  const AnswerRow({
    super.key,
    required this.label,
    required this.value,
    required this.changeLabel,
    required this.choices,
    this.detail,
  });

  /// What was asked, e.g. "Device".
  final String label;

  /// The answer, e.g. the device name.
  final String value;

  /// Secondary detail shown after the answer, e.g. "WiFi".
  final String? detail;

  /// Text of the change control, e.g. "Change device".
  final String changeLabel;

  /// The original choices, shown while changing the answer.
  final Widget choices;

  @override
  State<AnswerRow> createState() => _AnswerRowState();
}

class _AnswerRowState extends State<AnswerRow> {
  bool _changing = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.small2),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.medium, vertical: Spacing.small2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            SizedBox(
                width: Spacing.large5 * 2,
                child: AppText.labelMedium(widget.label.toUpperCase(),
                    color: scheme.onSurfaceVariant)),
            Expanded(
                child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Spacing.small2,
                    children: [
                  AppText.labelLarge(widget.value),
                  if (widget.detail != null)
                    AppText.bodySmall(widget.detail!,
                        color: scheme.onSurfaceVariant),
                ])),
            AppTextButton(_changing ? 'Cancel' : widget.changeLabel,
                onTap: () => setState(() => _changing = !_changing)),
          ]),
          if (_changing) ...[
            const AppGap.small2(),
            widget.choices,
          ],
        ]),
      ),
    );
  }
}
