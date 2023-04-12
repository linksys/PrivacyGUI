import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/mac_form_field.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';

class MACInputField extends StatelessWidget {
  const MACInputField({
    super.key,
    required this.titleText,
    this.isError = false,
    this.errorText = '',
    this.controller,
    this.onChanged,
  });

  final String titleText;
  final bool isError;
  final String errorText;
  final TextEditingController? controller;
  final void Function(String value)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText.isEmpty
            ? const Center()
            : AppPadding(
                padding:
                    const LinksysEdgeInsets.only(bottom: AppGapSize.semiSmall),
                child: LinksysText.mainTitle(
                  titleText,
                ),
              ),
        MACFormField(
          controller: controller,
          onChanged: onChanged,
          hasBorder: true,
        ),
        Visibility(
          visible: isError && errorText.isNotEmpty,
          child: Column(
            children: [
              const SizedBox(
                height: 8,
              ),
              Text(
                errorText,
                style: Theme.of(context).textTheme.bodyText1?.copyWith(
                      color: Colors.red,
                    ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
