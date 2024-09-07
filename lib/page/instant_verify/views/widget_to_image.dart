import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

/// We can use this class to convert any widget to an image.
/// It works even with widgets that are not visible on the screen.
class WidgetToImage {
  /// Creates an image from the given widget.
  ///
  /// Parameters:
  /// - widget: The widget to convert into an image.
  /// - wait: Optional duration to wait before capturing the image.
  /// - logicalSize: The logical size of the widget. Defaults to the window's physical size divided by the device pixel ratio.
  /// - imageSize: The desired size of the output image. Defaults to the window's physical size.
  ///
  /// Returns:
  /// A [Uint8List] representing the image data in PNG format, or null if the conversion failed.
  static Future<Uint8List?> createImageFromWidget(
      BuildContext context, Widget widget,
      {Duration? wait, Size? logicalSize, Size? imageSize}) async {
    final repaintBoundary = RenderRepaintBoundary();
    // Calculate logicalSize and imageSize if not provided
    final view = View.of(context);
    logicalSize ??= ui.window.physicalSize / ui.window.devicePixelRatio;
    imageSize ??= ui.window.physicalSize;
    // Ensure logicalSize and imageSize have the same aspect ratio
    assert(logicalSize.aspectRatio == imageSize.aspectRatio,
        'logicalSize and imageSize must not be the same');
    // Create the render tree for capturing the widget as an image
    final renderView = RenderView(
      view: ui.window,
      child: RenderPositionedBox(
          alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        size: logicalSize,
        devicePixelRatio: 1,
      ),
    );
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();
    // Attach the widget's render object to the render tree
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        )).attachToRenderTree(buildOwner);
    buildOwner.buildScope(rootElement);
    // Delay if specified
    if (wait != null) {
      await Future.delayed(wait);
    }
    // Build and finalize the render tree
    buildOwner
      ..buildScope(rootElement)
      ..finalizeTree();
    // Flush layout, compositing, and painting operations
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    // Capture the image and convert it to byte data
    final image = await repaintBoundary.toImage(
        pixelRatio: imageSize.width / logicalSize.width);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    // Return the image data as Uint8List
    return byteData?.buffer.asUint8List();
  }
}
