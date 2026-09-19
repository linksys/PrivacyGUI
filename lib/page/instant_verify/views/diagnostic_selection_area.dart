import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/copy_text.dart';

/// Copy the Flutter selection, including on router origins where the browser's
/// asynchronous clipboard API is unavailable or denied.
class DiagnosticSelectionArea extends StatefulWidget {
  const DiagnosticSelectionArea({super.key, required this.child});
  final Widget child;

  @override
  State<DiagnosticSelectionArea> createState() =>
      _DiagnosticSelectionAreaState();
}

class _DiagnosticSelectionAreaState extends State<DiagnosticSelectionArea> {
  String? _selection;
  final _selectionFocus = FocusNode();
  static int _webAreas = 0;
  static bool _restoreBrowserMenu = false;
  static Future<void> _menuChange = Future<void>.value();

  @override
  void initState() {
    super.initState();
    if (kIsWeb && _webAreas++ == 0) {
      _menuChange = _menuChange.then((_) async {
        _restoreBrowserMenu = BrowserContextMenu.enabled;
        if (_restoreBrowserMenu) await BrowserContextMenu.disableContextMenu();
      });
    }
  }

  @override
  void dispose() {
    if (kIsWeb && --_webAreas == 0) {
      _menuChange = _menuChange.then((_) async {
        if (_restoreBrowserMenu) await BrowserContextMenu.enableContextMenu();
      });
    }
    _selectionFocus.dispose();
    super.dispose();
  }

  Future<void> _copy([String? selectedText]) async {
    final text = selectedText ?? _selection;
    if (text == null || text.isEmpty) return;
    final copied = await copyDiagnosticText(text);
    if (!copied && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
        content: Text(
            'Copy was blocked by your browser. Allow clipboard access and try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Actions(
        actions: {
          CopySelectionTextIntent: _CopyDiagnosticAction(
            hasSelection: () =>
                _selectionFocus.hasPrimaryFocus &&
                _selection?.isNotEmpty == true,
            copy: _copy,
          ),
        },
        child: SelectionArea(
          focusNode: _selectionFocus,
          onSelectionChanged: (content) => _selection = content?.plainText,
          contextMenuBuilder: (context, region) {
            final selectedText = _selection;
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: region.contextMenuAnchors,
              buttonItems: region.contextMenuButtonItems
                  .map((item) => item.type == ContextMenuButtonType.copy
                      ? ContextMenuButtonItem(
                          type: ContextMenuButtonType.copy,
                          onPressed: () {
                            _copy(selectedText);
                            region.hideToolbar();
                          })
                      : item)
                  .toList(),
            );
          },
          child: widget.child,
        ),
      );
}

class _CopyDiagnosticAction extends Action<CopySelectionTextIntent> {
  _CopyDiagnosticAction({required this.hasSelection, required this.copy});
  final bool Function() hasSelection;
  final Future<void> Function() copy;

  @override
  Object? invoke(CopySelectionTextIntent intent) {
    if (hasSelection()) return copy();
    // Preserve copying from editable fields embedded inside diagnostics.
    return callingAction?.invoke(intent);
  }
}
