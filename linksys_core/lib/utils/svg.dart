import 'package:flutter_svg/flutter_svg.dart';

exactAssetPicture(String assetPath) =>
    ExactAssetPicture(
        SvgPicture.svgStringDecoderBuilder,
        assetPath, package: 'linksys_core');