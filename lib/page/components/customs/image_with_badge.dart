import 'package:flutter/cupertino.dart';

class ImageWithBadge extends StatelessWidget {
  const ImageWithBadge({
    Key? key,
    required this.imagePath,
    this.badgePath,
    required this.imageSize,
    this.badgeSize,
    this.offset = 8,
  }) : super(key: key);

  final String imagePath;
  final String? badgePath;
  final double imageSize;
  final double? badgeSize;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: imageSize + offset,
      height: imageSize + offset,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Padding(
            padding: EdgeInsets.all(offset),
            child: Image.asset(
              imagePath,
              width: imageSize,
              height: imageSize,
            ),
          ),
          if (badgePath != null)
            Image.asset(
              badgePath!,
              width: badgeSize,
              height: badgeSize,
            ),
        ],
      ),
    );
  }
}
