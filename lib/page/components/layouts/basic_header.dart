import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/text/description_text.dart';
import 'package:linksys_moab/page/components/base_components/text/title_text.dart';

class BasicHeader extends StatelessWidget {
  const BasicHeader(
      {Key? key, this.title, this.description, this.spacing, this.alignment, this.titleTextStyle})
      : super(key: key);

  final String? title;
  final String? description;
  final double? spacing;
  final CrossAxisAlignment? alignment;
  final TextStyle? titleTextStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment ?? CrossAxisAlignment.start,
      children: [
        TitleText(text: title ?? '', style: titleTextStyle,),
        SizedBox(
          height: spacing ?? 15,
        ),
        DescriptionText(text: description ?? ''),
      ],
    );
  }
}
