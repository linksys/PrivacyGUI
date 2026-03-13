import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A single autocomplete suggestion.
///
/// Domain-decoupled: convert your domain models to [AutoCompleteOption]
/// at the call site.
class AutoCompleteOption {
  /// Primary display text (e.g., device name).
  final String label;

  /// The value written to the controller on selection.
  final String value;

  /// Secondary info displayed on the trailing side (e.g., MAC address).
  final String? subtitle;

  /// Whether the item is active/online. Controls the status indicator dot.
  final bool isActive;

  const AutoCompleteOption({
    required this.label,
    required this.value,
    this.subtitle,
    this.isActive = true,
  });
}

/// Builds the visual content of a single option row in the dropdown.
///
/// The tap handling (selection + controller update) is managed internally;
/// this builder only controls the visual appearance.
typedef AutoCompleteOptionBuilder = Widget Function(
  BuildContext context,
  AutoCompleteOption option,
);

/// Decorator widget that adds autocomplete overlay to any text input child.
///
/// Monitors the [controller] for text changes and displays a filtered dropdown
/// of matching [options] below the [child] widget. On selection, the chosen
/// value is written back to the [controller].
///
/// The [child] can be any widget containing a text input — e.g.,
/// `AppTextField`, `AppIpv4TextField` (4-segment), `AppIPv6TextField`, or any
/// custom input field — as long as they share the same [controller].
///
/// ```dart
/// SelectAutoComplete(
///   options: myOptions,
///   controller: _ipController,
///   child: AppIpv4TextField(controller: _ipController),
/// )
/// ```
class SelectAutoComplete extends StatefulWidget {
  final List<AutoCompleteOption> options;
  final TextEditingController controller;
  final ValueChanged<String>? onSelected;
  final AutoCompleteOptionBuilder? optionBuilder;
  final int maxSuggestions;
  final Widget child;

  const SelectAutoComplete({
    super.key,
    required this.options,
    required this.controller,
    required this.child,
    this.onSelected,
    this.optionBuilder,
    this.maxSuggestions = 30,
  });

  @override
  State<SelectAutoComplete> createState() => _SelectAutoCompleteState();
}

class _SelectAutoCompleteState extends State<SelectAutoComplete> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _hasFocus = false;
  bool _suppressUpdate = false;
  List<AutoCompleteOption> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(SelectAutoComplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    if (oldWidget.options != widget.options) {
      _updateOptions();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _hideOverlay();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Filter & overlay lifecycle
  // ---------------------------------------------------------------------------

  void _onTextChanged() {
    if (_suppressUpdate) return;
    _updateOptions();
  }

  void _updateOptions() {
    final query = widget.controller.text.trim();
    if (query.isEmpty || !_hasFocus) {
      _hideOverlay();
      return;
    }

    final lq = query.toLowerCase();
    _filteredOptions = widget.options
        .where((o) =>
            o.label.toLowerCase().contains(lq) ||
            o.value.toLowerCase().contains(lq) ||
            (o.subtitle?.toLowerCase().contains(lq) ?? false))
        .take(widget.maxSuggestions)
        .toList();

    if (_filteredOptions.isEmpty) {
      _hideOverlay();
    } else {
      _showOrUpdateOverlay();
    }
  }

  void _showOrUpdateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  void _selectOption(AutoCompleteOption option) {
    _suppressUpdate = true;
    widget.controller.text = option.value;
    widget.controller.selection = TextSelection.collapsed(
      offset: option.value.length,
    );
    _suppressUpdate = false;
    _hideOverlay();
    widget.onSelected?.call(option.value);
  }

  // ---------------------------------------------------------------------------
  // Overlay
  // ---------------------------------------------------------------------------

  Widget _buildOverlay() {
    final targetWidth = _getTargetWidth();

    return CompositedTransformFollower(
      link: _layerLink,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      showWhenUnlinked: false,
      child: TextFieldTapRegion(
        child: Align(
          alignment: Alignment.topLeft,
          child: AppSurface(
            variant: SurfaceVariant.elevated,
            borderRadius: 8,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 280,
                maxWidth: targetWidth ?? 480,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = _filteredOptions[index];
                  return InkWell(
                    onTap: () => _selectOption(option),
                    child: widget.optionBuilder?.call(context, option) ??
                        _buildDefaultOptionTile(context, option),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultOptionTile(
      BuildContext context, AutoCompleteOption option) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>();
    final statusColor = option.isActive
        ? colorScheme?.semanticSuccess
        : colorScheme?.onSurface.withValues(alpha: 0.38);
    final secondaryColor = colorScheme?.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AppIcon.font(
            option.isActive ? Icons.circle : Icons.circle_outlined,
            size: 8,
            color: statusColor,
          ),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelMedium(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppText.bodySmall(
                  option.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: secondaryColor,
                ),
              ],
            ),
          ),
          if (option.subtitle != null) ...[
            AppGap.sm(),
            AppText.bodyExtraSmall(
              option.subtitle!,
              color: secondaryColor,
            ),
          ],
        ],
      ),
    );
  }

  double? _getTargetWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onFocusChange: (hasFocus) {
          _hasFocus = hasFocus;
          if (!hasFocus) {
            _hideOverlay();
          } else {
            _updateOptions();
          }
        },
        child: widget.child,
      ),
    );
  }
}
