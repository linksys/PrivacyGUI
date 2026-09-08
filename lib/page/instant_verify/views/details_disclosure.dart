import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Optional information stays out of the reading and focus order until opened.
class DetailsDisclosure extends StatefulWidget {
  const DetailsDisclosure(
      {super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  State<DetailsDisclosure> createState() => _DetailsDisclosureState();
}

class _DetailsDisclosureState extends State<DetailsDisclosure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppTextButton(
                _expanded
                    ? 'Hide ${widget.label.replaceFirst(RegExp(r'^View '), '').toLowerCase()}'
                    : widget.label,
                onTap: () => setState(() => _expanded = !_expanded),
                icon: _expanded
                    ? LinksysIcons.arrowDropUp
                    : LinksysIcons.arrowDropDown),
          ),
          if (_expanded) widget.child,
        ],
      );
}

/// Presents manual advice one step at a time; advancing never performs an action.
class GuidedSteps extends StatefulWidget {
  const GuidedSteps({super.key, required this.steps});
  final List<String> steps;

  @override
  State<GuidedSteps> createState() => _GuidedStepsState();
}

class _GuidedStepsState extends State<GuidedSteps> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant GuidedSteps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.steps, widget.steps)) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _index.clamp(0, widget.steps.length - 1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Step ${index + 1} of ${widget.steps.length}',
          style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      Text(widget.steps[index]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        if (index > 0)
          AppTextButton('Previous step',
              onTap: () => setState(() => _index = index - 1)),
        if (index < widget.steps.length - 1)
          AppOutlinedButton('Try the next step',
              onTap: () => setState(() => _index = index + 1)),
      ]),
    ]);
  }
}
