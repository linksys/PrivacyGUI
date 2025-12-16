import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A switch trigger tile with title, optional subtitle, description and a toggle switch.
///
/// This component was migrated from privacygui_widgets to decouple dependencies.
class AppSwitchTriggerTile extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? description;
  final bool value;
  final BoxDecoration? decoration;
  final EdgeInsets? padding;
  final bool showSwitchIcon;
  final Future Function(bool)? event;
  final void Function(bool)? onChanged;
  final bool toggleInCenter;
  final String? semanticLabel;

  const AppSwitchTriggerTile({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.decoration,
    this.padding,
    this.showSwitchIcon = false,
    required this.value,
    this.event,
    this.onChanged,
    this.toggleInCenter = false,
    this.semanticLabel,
  });

  @override
  State<AppSwitchTriggerTile> createState() => _AppSwitchTriggerTileState();
}

class _AppSwitchTriggerTileState extends State<AppSwitchTriggerTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.decoration,
      padding: widget.padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.title,
                          if (widget.subtitle != null) widget.subtitle!,
                        ],
                      ),
                    ),
                    if (!widget.toggleInCenter) _buildToggle(),
                  ],
                ),
                if (widget.description != null) ...[
                  AppGap.lg(),
                  widget.description!
                ],
              ],
            ),
          ),
          if (widget.toggleInCenter) ...[AppGap.lg(), _buildToggle()],
        ],
      ),
    );
  }

  Future<bool> _process(bool value) async {
    setState(() {
      _isLoading = true;
    });

    await widget.event?.call(value);

    setState(() {
      _isLoading = false;
    });
    return value;
  }

  Widget _buildToggle() {
    return _isLoading
        ? const CircularProgressIndicator()
        : AppSwitch(
            value: widget.value,
            onChanged: widget.onChanged != null
                ? (value) {
                    _process(value).then((value) {
                      widget.onChanged?.call(value);
                    });
                  }
                : null,
          );
  }
}
