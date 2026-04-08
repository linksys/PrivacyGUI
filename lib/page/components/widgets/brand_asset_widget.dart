import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A widget that renders brand assets with automatic SVG/raster format detection
///
/// Automatically chooses between SvgPicture.asset() for .svg files and
/// Image.asset() for raster formats (PNG, WebP, etc.)
class BrandAssetWidget extends StatelessWidget {
  /// Asset path to render
  final String path;

  /// Height of the rendered asset
  final double height;

  /// Color tint for raster images (Image.asset)
  final Color? color;

  /// Color filter for SVG images (SvgPicture.asset)
  final ColorFilter? colorFilter;

  const BrandAssetWidget({
    super.key,
    required this.path,
    required this.height,
    this.color,
    this.colorFilter,
  });

  @override
  Widget build(BuildContext context) {
    // Handle both SVG and raster image formats
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        height: height,
        colorFilter: colorFilter,
      );
    } else {
      return Image.asset(
        path,
        height: height,
        color: color,
      );
    }
  }
}