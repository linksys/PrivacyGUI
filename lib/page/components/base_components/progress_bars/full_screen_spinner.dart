
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';

class FullScreenSpinner extends StatelessWidget {
  final String? text;
  final Color? background;
  final Color? color;
  const FullScreenSpinner({Key? key, this.text, this.background, this.color}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: background ?? Theme.of(context).backgroundColor),
      child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: color ?? Theme.of(context).primaryColor,),
          const SizedBox(height: 8,),
          DescriptionText(text: text ?? ''),
        ],
      ),),
    );
  }
}