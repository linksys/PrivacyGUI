import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:linksys_core/theme/_theme.dart';

enum AppWidgetState {
  inactive,
  hovered,
  pressed,
  disabled,
  focus,
}

class AppWidgetStateColorSet extends Equatable {
  final Color? inactive;
  final Color? hovered;
  final Color? pressed;
  final Color? disabled;
  final Color? focus;

  const AppWidgetStateColorSet({
    this.inactive,
    this.hovered,
    this.pressed,
    this.disabled,
    this.focus,
  });

  factory AppWidgetStateColorSet.transparent() => const AppWidgetStateColorSet(
    inactive: ConstantColors.transparent,
    hovered: ConstantColors.transparent,
    pressed: ConstantColors.transparent,
    disabled: ConstantColors.transparent,
    focus: ConstantColors.transparent,
  );

  Color? resolve(AppWidgetState state) {
    switch (state) {
      case AppWidgetState.inactive:
        return inactive;
      case AppWidgetState.hovered:
        return hovered;
      case AppWidgetState.pressed:
        return pressed;
      case AppWidgetState.disabled:
        return disabled;
      case AppWidgetState.focus:
        return focus;
    }
  }

  @override
  List<Object?> get props => [
    inactive,
    hovered,
    pressed,
    disabled,
    focus,
  ];
}