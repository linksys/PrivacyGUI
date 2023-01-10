import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:linksys_core/widgets/base/gap.dart';

class LinksysInputField extends StatefulWidget {
  const LinksysInputField({
    Key? key,
    required this.controller,
    this.headerText = '',
    this.hintText = '',
    this.ctaText = '',
    this.errorText = '',
    this.approvedText = '',
    this.descriptionText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.onCtaTap,
    this.textValidator,
    this.secured = false,
    this.readOnly = false,
    this.enable = true,
    this.useSubHeader = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
  }) : super(key: key);

  const LinksysInputField.small({
    Key? key,
    required this.controller,
    this.headerText = '',
    this.hintText = '',
    this.ctaText = '',
    this.errorText = '',
    this.approvedText = '',
    this.descriptionText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.onCtaTap,
    this.textValidator,
    this.secured = false,
    this.readOnly = false,
    this.enable = true,
    this.prefixIcon,
    this.suffixIcon,
    this.width = 116,
  })  : useSubHeader = true,
        super(key: key);

  final TextEditingController controller;
  final String headerText;
  final String hintText;
  final String ctaText;
  final String errorText;
  final String approvedText;
  final String descriptionText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final void Function(bool hasFocus)? onFocusChanged;
  final void Function()? onCtaTap;
  final bool Function()? textValidator;
  final bool secured;
  final bool readOnly;
  final bool enable;
  final bool useSubHeader;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? width;

  @override
  LinksysInputFieldState createState() => LinksysInputFieldState();
}

class LinksysInputFieldState extends State<LinksysInputField> {
  final FocusNode _focus = FocusNode();
  late Color textColor;
  bool init = false;

  @override
  void initState() {
    super.initState();

    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();

    _focus.removeListener(_onFocusChange);
    _focus.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    if (widget.textValidator != null) {
      _getTextColor();
    }
  }

  void _onFocusChange() {
    widget.onFocusChanged?.call(_focus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    if (init == false) {
      init = true;
      _getTextColor();
    }
    List<Widget> children = [];

    // Header and CTA button
    if (widget.headerText.isNotEmpty || widget.ctaText.isNotEmpty) {
      children.add(Row(
        children: [
          if (widget.headerText.isNotEmpty)
            AppText(
              widget.headerText,
              textLevel: widget.useSubHeader
                  ? AppTextLevel.descriptionSub
                  : AppTextLevel.descriptionMain,
            ),
          const Spacer(),
          if (widget.ctaText.isNotEmpty)
            AppTertiaryButton.noPadding(
              widget.ctaText,
              onTap: widget.onCtaTap,
            ),
        ],
      ));
      children.add(const AppGap.semiSmall());
    }
    // Text field
    children.add(Row(
      children: [
        Flexible(
          child: Container(
            width: widget.descriptionText.isNotEmpty ? 116 : widget.width,
            decoration: BoxDecoration(
              color: widget.enable
                  ? theme.colors.textBoxBox
                  : theme.colors.textBoxBoxDisabled,
            ),
            child: TextField(
              enabled: widget.enable,
              readOnly: widget.readOnly,
              obscureText: widget.secured,
              controller: widget.controller,
              style: theme.typography.inputFieldText.copyWith(
                color: widget.enable
                    ? textColor
                    : theme.colors.textBoxTextDisabled,
              ),
              cursorColor: theme.colors.textBoxText,
              decoration: InputDecoration(
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                hintText: widget.hintText,
                hintStyle: theme.typography.inputFieldText
                    ?.copyWith(color: ConstantColors.textBoxTextGray),
                enabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: ConstantColors.transparent, width: 2),
                    borderRadius: BorderRadius.zero),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: theme.colors.textBoxStrokeHovered, width: 2),
                    borderRadius: BorderRadius.zero),
                disabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: ConstantColors.transparent, width: 2),
                    borderRadius: BorderRadius.zero),
              ),
              onChanged: _onChanged,
              keyboardType: widget.inputType,
              focusNode: _focus,
            ),
          ),
        ),
        if (widget.descriptionText.isNotEmpty) const AppGap.semiSmall(),
        if (widget.descriptionText.isNotEmpty)
          Expanded(child: AppText.descriptionSub(widget.descriptionText)),
      ],
    ));
    // Error text and approved text
    if (widget.errorText.isNotEmpty || widget.approvedText.isNotEmpty) {
      String text = widget.errorText;
      Color color = theme.colors.textBoxTextAlert;
      if (widget.approvedText.isNotEmpty) {
        text = widget.approvedText;
        color = theme.colors.textBoxApproved;
      }
      children.add(const AppGap.semiSmall());
      children.add(AppText.flavorText(
        text,
        color: color,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  _getTextColor() {
    setState(() {
      final theme = AppTheme.of(context);
      textColor = theme.colors.textBoxText;
      final validator = widget.textValidator;
      if (validator != null) {
        if (!validator.call()) {
          textColor = theme.colors.textBoxTextAlert;
        }
      }
    });
  }
}
