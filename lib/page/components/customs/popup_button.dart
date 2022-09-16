import 'package:flutter/material.dart';
import 'package:linksys_moab/utils.dart';

class PopupButton extends StatefulWidget {
  final Icon icon;
  final Widget content;
  final BorderRadius? borderRadius;
  final Color backgroundColor;

  const PopupButton({
    Key? key,
    required this.icon,
    required this.content,
    this.borderRadius,
    this.backgroundColor = const Color(0xFFF67C0B9),
  })  : super(key: key);

  @override
  _PopupButtonState createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton>
    with SingleTickerProviderStateMixin {
  late GlobalKey _key;
  bool isMenuOpen = false;
  late Offset buttonPosition;
  late Size buttonSize;
  late OverlayEntry _overlayEntry;
  late BorderRadius _borderRadius;
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
    _borderRadius = widget.borderRadius ?? BorderRadius.circular(4);
    _key = LabeledGlobalKey("button_icon");
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
    buttonPosition = renderBox.localToGlobal(Offset.zero);
  }

  void closeMenu() {
    _overlayEntry.remove();
    _animationController.reverse();
    isMenuOpen = !isMenuOpen;
  }

  void openMenu() {
    findButton();
    _animationController.forward();
    _overlayEntry = _overlayEntryBuilder();
    Overlay.of(context)?.insert(_overlayEntry);
    isMenuOpen = !isMenuOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      decoration: BoxDecoration(
        color: Color(0x00000000),
        borderRadius: _borderRadius,
      ),
      child: IconButton(
        icon: widget.icon,
        onPressed: () {
          if (isMenuOpen) {
            closeMenu();
          } else {
            openMenu();
          }
        },
      ),
    );
  }

  OverlayEntry _overlayEntryBuilder() {
    return OverlayEntry(
      builder: (context) {
        final screenSize = Utils.getScreenSize(context);
        double maxWidth = screenSize.width / 2;
        double left = buttonPosition.dx + maxWidth > screenSize.width
            ? maxWidth - 20
            : buttonPosition.dx;
        return GestureDetector(
          onTap: () {
            closeMenu();
          },
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0x00000000),
                ),
              ),
              Positioned(
                top: buttonPosition.dy + buttonSize.height,
                left: left,
                width: maxWidth,
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topCenter,
                        // child: ClipPath(
                        //   clipper: ArrowClipper(),
                        //   child: Container(
                        //     width: 17,
                        //     height: 17,
                        //     color: widget.backgroundColor ?? Color(0xFFF),
                        //   ),
                        // ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.backgroundColor,
                            borderRadius: _borderRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: widget.content,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
