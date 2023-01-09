import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/base/icon.dart';
import 'package:linksys_core/widgets/base/padding.dart';

import 'state.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    Key? key,
    this.hint,
    this.padding,
    this.enabled,
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.foregroundColorSet = const AppWidgetStateColorSet(),
  }) : super(key: key);

  final String? hint;
  final bool? enabled;
  final AppEdgeInsets? padding;
  final TextInputType inputType;
  final AppWidgetStateColorSet foregroundColorSet;
  final void Function(String)? onChanged;
  final void Function(bool)? onFocusChanged;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  late final VoidCallback _focusListener;

  @override
  void initState() {
    super.initState();
    _focusListener = () {
      setState(() {});
      widget.onFocusChanged?.call(_focusNode.hasFocus);
    };
    _focusNode.addListener(_focusListener);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final hint = widget.hint;
    final backgroundColor = theme.colors.textBoxBox;
    final borderColor = _focusNode.hasFocus
        ? ConstantColors.primaryLinksysWhite
        : backgroundColor;

    return AppPadding(
      padding: widget.padding ?? const AppEdgeInsets.only(),
      child: AnimatedContainer(
        duration: theme.durations.quick,
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: borderColor),
          color: backgroundColor,
        ),
        child: AppPadding(
          padding:
              const AppEdgeInsets.symmetric(horizontal: AppGapSize.regular),
          child: Row(
            children: [
              AppIcon.regular(
                theme.icons.characters.searchDefault,
                color: ConstantColors.primaryLinksysWhite,
              ),
              const AppGap.regular(),
              Expanded(
                child: TextField(
                  focusNode: _focusNode,
                  controller: _controller,
                  style: theme.typography.inputFieldText
                      .copyWith(color: ConstantColors.primaryLinksysWhite),
                  enabled: widget.enabled,
                  cursorColor: ConstantColors.primaryLinksysWhite,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: theme.typography.inputFieldText
                        .copyWith(color: ConstantColors.baseTertiaryGray),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    widget.onChanged?.call(value);
                  },
                  keyboardType: widget.inputType,
                ),
              ),
              const AppGap.regular(),
              if (_controller.text.isNotEmpty)
                AppIcon.regular(
                  theme.icons.characters.crossDefault,
                  color: ConstantColors.primaryLinksysWhite,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
