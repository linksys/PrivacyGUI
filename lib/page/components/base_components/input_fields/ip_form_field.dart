import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';

class IPFormField extends ConsumerStatefulWidget {
  const IPFormField({
    super.key,
    this.header,
    this.onChanged,
    this.onFocusChanged,
    this.controller,
    this.isError = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onFocusChanged;
  final Widget? header;
  final bool isError;

  @override
  ConsumerState<IPFormField> createState() => _IPFormFieldState();
}

class _IPFormFieldState extends ConsumerState<IPFormField> {
  final _octet1Controller = TextEditingController();
  final _octet2Controller = TextEditingController();
  final _octet3Controller = TextEditingController();
  final _octet4Controller = TextEditingController();

  final _octet1Focus = FocusNode();
  final _octet2Focus = FocusNode();
  final _octet3Focus = FocusNode();
  final _octet4Focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTextChanged);
    _octet1Focus.addListener(_onFocusChange);
    _octet2Focus.addListener(_onFocusChange);
    _octet3Focus.addListener(_onFocusChange);
    _octet4Focus.addListener(_onFocusChange);

    _octet1Controller.text = '0';
    _octet2Controller.text = '0';
    _octet3Controller.text = '0';
    _octet4Controller.text = '0';
  }

  @override
  void dispose() {
    _octet1Focus.removeListener(_onFocusChange);
    _octet2Focus.removeListener(_onFocusChange);
    _octet3Focus.removeListener(_onFocusChange);
    _octet4Focus.removeListener(_onFocusChange);
    widget.controller?.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    widget.onFocusChanged?.call(
      _octet1Focus.hasFocus ||
          _octet2Focus.hasFocus ||
          _octet3Focus.hasFocus ||
          _octet4Focus.hasFocus,
    );
  }

  void _onTextChanged() {
    final controller = widget.controller!;
    final value = controller.text;
    if (value.isNotEmpty) {
      final isValid = IpAddressValidator().validate(value);
      if (isValid) {
        final token = value.split('.');
        _octet1Controller.text = token[0];
        _octet2Controller.text = token[1];
        _octet3Controller.text = token[2];
        _octet4Controller.text = token[3];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.header != null) ...[
          widget.header!,
          const AppGap.semiSmall(),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildOctetInputForm(_octet1Focus, _octet2Focus, _octet1Controller),
            _buildDotWidget(),
            _buildOctetInputForm(_octet2Focus, _octet3Focus, _octet2Controller),
            _buildDotWidget(),
            _buildOctetInputForm(_octet3Focus, _octet4Focus, _octet3Controller),
            _buildDotWidget(),
            _buildOctetInputForm(_octet4Focus, _octet4Focus, _octet4Controller,
                isLast: true),
          ],
        ),
      ],
    );
  }

  _buildDotWidget() => const AppPadding(
        padding: AppEdgeInsets.symmetric(horizontal: AppGapSize.semiSmall),
        child: AppText.screenName(
          '.',
        ),
      );

  _buildOctetInputForm(
    FocusNode focus,
    FocusNode nextFocus,
    TextEditingController controller, {
    bool isLast = false,
    ValueChanged<String>? onChanged,
  }) {
    final theme = AppTheme.of(context);
    return Expanded(
      child: TextFormField(
        controller: controller,
        focusNode: focus,
        decoration: InputDecoration(
          hintStyle: theme.typography.inputFieldText
              .copyWith(color: ConstantColors.textBoxTextGray),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: theme.colors.textBoxStrokeHovered, width: 2),
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
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          // allow only  digits
          IPOctetsFormatter(),
          // custom class to format entered data from textField
          LengthLimitingTextInputFormatter(3)
          // restrict user to enter max 16 characters
        ],
        keyboardType: TextInputType.number,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onChanged: (value) {
          if (value.length >= 3) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
          widget.controller?.text = _combineOctets();
          widget.onChanged?.call(_combineOctets());
        },
        onFieldSubmitted: (value) {
          FocusScope.of(context).requestFocus(nextFocus);
        },
      ),
    );
  }

  String _combineOctets() {
    return '${_octet1Controller.text}.${_octet2Controller.text}.${_octet3Controller.text}.${_octet4Controller.text}';
  }
}

// this class will be called, when their is change in textField
class IPOctetsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return const TextEditingValue(
          text: '0', // final generated credit card number
          selection: TextSelection.collapsed(
              offset: '0'.length) // keep the cursor at end
          );
    }
    String enteredData = newValue.text; // get data enter by used in textField
    StringBuffer buffer = StringBuffer();

    final intValue = int.tryParse(enteredData);
    if ((intValue ?? 256) > 255) {
      buffer.clear();
      buffer.write(0);
    } else {
      buffer.write(intValue);
    }
    return TextEditingValue(
        text: buffer.toString(), // final generated credit card number
        selection: TextSelection.collapsed(
            offset: buffer.toString().length) // keep the cursor at end
        );
  }
}
