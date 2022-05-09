import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/base_components/text/title_text.dart';

class BasicHeader extends StatelessWidget {
  const BasicHeader({
    Key? key,
    this.title,
    this.description,
    this.spacing,
    this.alignment
  }) : super(key: key);

  final String? title;
  final String? description;
  final double? spacing;
  final CrossAxisAlignment? alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment ?? CrossAxisAlignment.center,
      children: [
        TitleText(text: title ?? ''),
        SizedBox(height: spacing ?? 15,),
        DescriptionText(text: description ?? ''),
      ],
    );
  }

}