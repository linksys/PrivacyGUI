import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Types of loadable buttons/widgets
enum LoadableWidgetType {
  primaryButton,
  primaryOutlineButton,
  textButton,
  appSwitch,
}

/// Controller interface for managing loading state externally
abstract class AppLoadableWidgetController {
  void showSpinner();
  void hideSpinner();
}

/// A widget that shows a loading spinner while an async operation is in progress.
/// Composed component using ui_kit components, decoupled from privacygui_widgets.
class AppLoadableWidget extends StatefulWidget {
  final LoadableWidgetType type;
  final Size? spinnerSize;
  final String? semanticsLabel;
  final bool showSpinnerWhenTap;
  // Button
  final String? title;
  final Widget? icon;
  final Future Function(AppLoadableWidgetController controller)? onTap;
  final Size? buttonSize;
  final EdgeInsets? padding;
  // Switch
  final bool? value;
  final Future Function(AppLoadableWidgetController controller, dynamic)?
      onChanged;

  const AppLoadableWidget({
    super.key,
    required this.type,
    this.spinnerSize,
    this.semanticsLabel,
    this.title,
    this.icon,
    this.onTap,
    this.buttonSize,
    this.padding,
    this.value,
    this.onChanged,
    this.showSpinnerWhenTap = true,
  });

  factory AppLoadableWidget.primaryButton({
    Key? key,
    required String title,
    Size? spinnerSize,
    String? semanticsLabel,
    Widget? icon,
    Future Function(AppLoadableWidgetController controller)? onTap,
    Size? buttonSize,
    bool showSpinnerWhenTap = true,
  }) =>
      AppLoadableWidget(
        key: key,
        type: LoadableWidgetType.primaryButton,
        title: title,
        spinnerSize: spinnerSize,
        semanticsLabel: semanticsLabel,
        icon: icon,
        onTap: onTap,
        buttonSize: buttonSize,
        showSpinnerWhenTap: showSpinnerWhenTap,
      );

  factory AppLoadableWidget.primaryOutlineButton({
    Key? key,
    required String title,
    Size? spinnerSize,
    String? semanticsLabel,
    Widget? icon,
    Future Function(AppLoadableWidgetController controller)? onTap,
    Size? buttonSize,
    bool showSpinnerWhenTap = true,
  }) =>
      AppLoadableWidget(
        key: key,
        type: LoadableWidgetType.primaryOutlineButton,
        title: title,
        spinnerSize: spinnerSize,
        semanticsLabel: semanticsLabel,
        icon: icon,
        onTap: onTap,
        buttonSize: buttonSize,
        showSpinnerWhenTap: showSpinnerWhenTap,
      );

  factory AppLoadableWidget.textButton({
    Key? key,
    required String title,
    Size? spinnerSize,
    String? semanticsLabel,
    Widget? icon,
    Future Function(AppLoadableWidgetController controller)? onTap,
    Size? buttonSize,
    EdgeInsets? padding,
    bool showSpinnerWhenTap = true,
  }) =>
      AppLoadableWidget(
        key: key,
        type: LoadableWidgetType.textButton,
        title: title,
        spinnerSize: spinnerSize,
        semanticsLabel: semanticsLabel,
        icon: icon,
        onTap: onTap,
        buttonSize: buttonSize,
        padding: padding,
        showSpinnerWhenTap: showSpinnerWhenTap,
      );

  factory AppLoadableWidget.appSwitch({
    Key? key,
    required bool value,
    Size? spinnerSize,
    String? semanticsLabel,
    Future Function(AppLoadableWidgetController controller, dynamic)? onChanged,
    bool showSpinnerWhenTap = true,
  }) =>
      AppLoadableWidget(
        key: key,
        type: LoadableWidgetType.appSwitch,
        spinnerSize: spinnerSize,
        semanticsLabel: semanticsLabel,
        value: value,
        onChanged: onChanged,
        showSpinnerWhenTap: showSpinnerWhenTap,
      );

  @override
  State<AppLoadableWidget> createState() => _AppLoadableWidgetState();
}

class _AppLoadableWidgetState extends State<AppLoadableWidget>
    implements AppLoadableWidgetController {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SizedBox(
            height: widget.spinnerSize?.height ?? 36,
            width: widget.spinnerSize?.width ?? 36,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: '${widget.semanticsLabel} spinner',
              ),
            ),
          )
        : switch (widget.type) {
            LoadableWidgetType.primaryButton => AppButton.primary(
                key: widget.key,
                label: widget.title ?? '',
                icon: widget.icon,
                onTap: widget.onTap != null
                    ? () {
                        _processOnTap();
                      }
                    : null,
              ),
            LoadableWidgetType.primaryOutlineButton => AppButton.primaryOutline(
                key: widget.key,
                label: widget.title ?? '',
                icon: widget.icon,
                onTap: widget.onTap != null
                    ? () {
                        _processOnTap();
                      }
                    : null,
              ),
            LoadableWidgetType.textButton => AppButton.text(
                key: widget.key,
                label: widget.title ?? '',
                icon: widget.icon,
                onTap: widget.onTap != null
                    ? () {
                        _processOnTap();
                      }
                    : null,
              ),
            LoadableWidgetType.appSwitch => AppSwitch(
                key: widget.key,
                value: widget.value ?? false,
                onChanged: widget.onChanged != null
                    ? (value) {
                        _processOnChanged(value);
                      }
                    : null,
              ),
          };
  }

  Future<void> _processOnTap() async {
    if (widget.showSpinnerWhenTap) {
      showSpinner();
    }
    await widget.onTap?.call(this);

    hideSpinner();
  }

  Future<bool> _processOnChanged(bool value) async {
    if (widget.showSpinnerWhenTap) {
      showSpinner();
    }

    await widget.onChanged?.call(this, value);

    hideSpinner();
    return value;
  }

  @override
  void hideSpinner() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void showSpinner() {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
  }
}
