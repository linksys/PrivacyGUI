import 'package:flutter/material.dart';

enum AppPopupVerticalPosition {
  top(-1.0),
  bottom(1.0),
  ;

  final double value;
  const AppPopupVerticalPosition(this.value);
}

class AppPopupButtonController {
  void open() {}
  void close() {}
  void markNeedBuilds() {}
}

/// A button that opens a popup overlay.
///
/// This component was migrated from privacygui_widgets to decouple dependencies.
class AppPopupButton extends StatefulWidget {
  final Widget button;
  final Widget Function(AppPopupButtonController) builder;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final AppPopupVerticalPosition verticalPosition;
  final BuildContext? parent;
  final double? maxWidth;
  final double? maxHeight;

  const AppPopupButton({
    super.key,
    required this.button,
    required this.builder,
    this.borderRadius,
    this.backgroundColor,
    this.verticalPosition = AppPopupVerticalPosition.bottom,
    this.parent,
    this.maxWidth = 500,
    this.maxHeight,
  });

  @override
  PopupButtonState createState() => PopupButtonState();
}

class PopupButtonState extends State<AppPopupButton>
    with SingleTickerProviderStateMixin
    implements AppPopupButtonController {
  late GlobalKey _key;
  bool isMenuOpen = false;
  late Offset buttonPosition;
  late Size buttonSize;
  late OverlayEntry _overlayEntry;
  late BorderRadius _borderRadius;
  late AnimationController _animationController;

  final _link = LayerLink();

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // Decoupled from CustomTheme.of(context).radius.asBorderRadius().small
    _borderRadius = widget.borderRadius ?? BorderRadius.circular(4);
    _key = LabeledGlobalKey("${widget.button.hashCode}");
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  findButton() {
    RenderBox renderBox = _key.currentContext?.findRenderObject() as RenderBox;
    buttonSize = renderBox.size;
    buttonPosition = renderBox.localToGlobal(
      Offset.zero,
    );
  }

  @override
  void close() {
    _overlayEntry.remove();
    _animationController.reverse();
    isMenuOpen = !isMenuOpen;
  }

  @override
  void open() {
    findButton();
    _animationController.forward();
    _overlayEntry = _overlayEntryBuilder();
    Overlay.of(widget.parent ?? context).insert(_overlayEntry);
    isMenuOpen = !isMenuOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      decoration: BoxDecoration(
        color: const Color(0x00000000),
        borderRadius: _borderRadius,
      ),
      child: InkWell(
        child: CompositedTransformTarget(
          link: _link,
          child: AbsorbPointer(child: widget.button),
        ),
        onTap: () {
          if (isMenuOpen) {
            close();
          } else {
            open();
          }
        },
      ),
    );
  }

  OverlayEntry _overlayEntryBuilder() {
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
              ),
              child: GestureDetector(
                onTap: () {
                  close();
                },
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: _resloveTargetAlignment(),
              followerAnchor: _resloveFollowerAlignment(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight:
                            widget.maxHeight ?? constraints.maxHeight * 0.7,
                        maxWidth:
                            widget.maxWidth ?? constraints.maxWidth * 0.7),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.backgroundColor ??
                              Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: _borderRadius,
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: widget.builder(this)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Alignment _resloveTargetAlignment() {
    final screenSize = MediaQuery.of(context).size;
    double maxWidth = screenSize.width / 2;
    bool rEdge = buttonPosition.dx + maxWidth > screenSize.width;
    return Alignment(rEdge ? 1.0 : -1.0, widget.verticalPosition.value);
  }

  Alignment _resloveFollowerAlignment() {
    final screenSize = MediaQuery.of(context).size;
    double maxWidth = screenSize.width / 2;
    bool rEdge = buttonPosition.dx + maxWidth > screenSize.width;
    return Alignment(rEdge ? 1.0 : -1.0, -1 * widget.verticalPosition.value);
  }

  @override
  void markNeedBuilds() {
    _overlayEntry.markNeedsBuild();
  }
}
