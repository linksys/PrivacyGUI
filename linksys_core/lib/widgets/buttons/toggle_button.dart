import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:linksys_core/widgets/base/padding.dart';

import 'button.dart';

enum AppIconToggleStatus { on, off }

enum AppTweenAnimationData {
  // Rotation
  leftRotate90(1),
  leftRotate180(2),
  leftRotate270(3),
  leftRotate360(4),
  rightRotate90(-1),
  rightRotate180(-2),
  rightRotate270(-3),
  rightRotate360(-4);

  const AppTweenAnimationData(this.value);

  final int value;

  AppTweenAnimationData get reverse =>
      AppTweenAnimationData.values.firstWhere((element) => element.value == -value);
}

class AppIconToggleButton extends StatelessWidget {
  const AppIconToggleButton({
    super.key,
    required this.icon1,
    required this.icon2,
    this.animation = AppTweenAnimationData.leftRotate360,
    this.padding,
    this.onTap,
  });

  final IconData icon1;
  final IconData icon2;
  final AppTweenAnimationData animation;
  final AppEdgeInsets? padding;
  final void Function(AppIconToggleStatus)? onTap;

  @override
  Widget build(BuildContext context) {
    return BaseIconToggleButton(
      icon1: icon1,
      icon2: icon2,
      padding: padding,
      onTap: onTap,
      animatedSwitcherTransitionBuilder:
          (child, anim) =>
          RotationTransition(
            turns: child.key == ValueKey(icon1.codePoint)
                ? _resolveAnimation(animation).animate(anim)
                : _resolveAnimation(animation.reverse).animate(anim),
            child: ScaleTransition(scale: anim, child: child),
          ),
    );
  }

  Tween<double> _resolveAnimation(AppTweenAnimationData animation) {
    switch (animation) {
      case AppTweenAnimationData.leftRotate90:
        return Tween<double>(begin: 0, end: 0.25);
      case AppTweenAnimationData.leftRotate180:
        return Tween<double>(begin: 0, end: 0.5);
      case AppTweenAnimationData.leftRotate270:
        return Tween<double>(begin: 0, end: 0.75);
      case AppTweenAnimationData.leftRotate360:
        return Tween<double>(begin: 0, end: 1);
      case AppTweenAnimationData.rightRotate90:
        return Tween<double>(begin: 1, end: 0.75);
      case AppTweenAnimationData.rightRotate180:
        return Tween<double>(begin: 1, end: 0.5);
      case AppTweenAnimationData.rightRotate270:
        return Tween<double>(begin: 1, end: 0.25);
      case AppTweenAnimationData.rightRotate360:
        return Tween<double>(begin: 1, end: 0);
    }
  }
}

class BaseIconToggleButton extends StatefulWidget {
  const BaseIconToggleButton({
    super.key,
    required this.icon1,
    required this.icon2,
    this.animatedSwitcherTransitionBuilder =
        AnimatedSwitcher.defaultTransitionBuilder,
    this.padding,
    this.onTap,
  });

  final AppEdgeInsets? padding;
  final IconData icon1;
  final IconData icon2;
  final AnimatedSwitcherTransitionBuilder animatedSwitcherTransitionBuilder;
  final void Function(AppIconToggleStatus)? onTap;

  @override
  State<BaseIconToggleButton> createState() => _BaseIconToggleButtonState();
}

class _BaseIconToggleButtonState extends State<BaseIconToggleButton> {
  AppIconToggleStatus _status = AppIconToggleStatus.on;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: widget.animatedSwitcherTransitionBuilder,
      //     (child, anim) => RotationTransition(
      //   turns: child.key == const ValueKey('icon1')
      //       ? Tween<double>(begin: 1, end: 0).animate(anim)
      //       : Tween<double>(begin: 0, end: 1).animate(anim),
      //   child: ScaleTransition(scale: anim, child: child),
      // ),
      child: _status == AppIconToggleStatus.on
          ? AppIconButton(
        icon: widget.icon1,
        key: ValueKey(widget.icon1.codePoint),
        padding: widget.padding,
        onTap: _onTap,
      )
          : AppIconButton(
        icon: widget.icon2,
        key: ValueKey(widget.icon2.codePoint),
        padding: widget.padding,
        onTap: _onTap,
      ),
    );
  }

  void _onTap() {
    setState(() {
      _status = _status == AppIconToggleStatus.on
          ? AppIconToggleStatus.off
          : AppIconToggleStatus.on;
    });
    widget.onTap?.call(_status);
  }
}
