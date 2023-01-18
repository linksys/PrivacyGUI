import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';

class OptionCard extends StatelessWidget {
  const OptionCard({
    Key? key,
    required this.title,
    required this.description,
    this.minHeight = 120,
    this.onPress,
  }): super(key: key);

  final String title;
  final String description;
  final double minHeight;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor,
          ),
        ),
        constraints: BoxConstraints(
          minHeight: minHeight,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headline3?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor
                    ),
                  ),
                  box16(),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            box36(),
            Image.asset(
              'assets/images/arrow_point_to_right.png',
              width: 10,
              height: 10,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}