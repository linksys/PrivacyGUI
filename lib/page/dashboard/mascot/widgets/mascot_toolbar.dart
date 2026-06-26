import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

/// Toolbar action types.
enum MascotToolbarAction {
  print,
  themeStudio,
  faq,
  aiAssistant,
}

/// Callback when a toolbar action is tapped.
typedef OnToolbarAction = void Function(MascotToolbarAction action);

/// Compact toolbar for utility functions.
///
/// Displays icons for: Print, Theme Studio (optional), FAQ, AI Assistant
class MascotToolbar extends StatelessWidget {
  final OnToolbarAction? onAction;
  final bool showThemeStudio;
  final Color iconColor;

  const MascotToolbar({
    super.key,
    this.onAction,
    this.showThemeStudio = false,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: iconColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(
            icon: Icons.print,
            tooltip: loc(context).printReport,
            color: iconColor,
            onTap: () => onAction?.call(MascotToolbarAction.print),
          ),
          if (showThemeStudio)
            _ToolbarButton(
              icon: Icons.palette,
              tooltip: loc(context).themeStudio,
              color: iconColor,
              onTap: () => onAction?.call(MascotToolbarAction.themeStudio),
            ),
          _ToolbarButton(
            icon: Icons.help_outline,
            tooltip: loc(context).faq,
            color: iconColor,
            onTap: () => onAction?.call(MascotToolbarAction.faq),
          ),
          _ToolbarButton(
            icon: Icons.auto_awesome,
            tooltip: loc(context).aiAssistant,
            color: iconColor,
            onTap: () => onAction?.call(MascotToolbarAction.aiAssistant),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 24,
            color: color,
          ),
        ),
      ),
    );
  }
}
