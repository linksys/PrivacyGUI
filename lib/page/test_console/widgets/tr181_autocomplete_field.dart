import 'package:flutter/material.dart';
import 'package:privacy_gui/generated/tr181_paths.g.dart';

/// Autocomplete text field for TR-181 device model paths.
///
/// Wraps [RawAutocomplete] with prefix-based matching against the full
/// TR-181 path list (~8K entries). Supports optional type filtering
/// and comma-separated multi-path input for the GET operation.
class Tr181AutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final Set<Tr181PathType>? pathTypeFilter;
  final int maxSuggestions;
  final bool supportsMultiple;
  final int maxLines;

  const Tr181AutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    this.pathTypeFilter,
    this.maxSuggestions = 50,
    this.supportsMultiple = false,
    this.maxLines = 1,
  });

  @override
  State<Tr181AutocompleteField> createState() => _Tr181AutocompleteFieldState();
}

class _Tr181AutocompleteFieldState extends State<Tr181AutocompleteField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Extract the active query segment (after the last comma for multi-mode).
  String _activeQuery(String text) {
    if (!widget.supportsMultiple) return text.trim();
    final lastComma = text.lastIndexOf(',');
    return (lastComma >= 0 ? text.substring(lastComma + 1) : text).trim();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Tr181PathEntry>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        final query = _activeQuery(textEditingValue.text);
        if (query.isEmpty) return const Iterable.empty();
        final lowerQuery = query.toLowerCase();
        return tr181Paths
            .where((e) =>
                widget.pathTypeFilter == null ||
                widget.pathTypeFilter!.contains(e.type))
            .where((e) => e.path.toLowerCase().startsWith(lowerQuery))
            .take(widget.maxSuggestions);
      },
      displayStringForOption: (entry) => entry.path,
      onSelected: (entry) {
        if (widget.supportsMultiple) {
          final text = widget.controller.text;
          final lastComma = text.lastIndexOf(',');
          final prefix =
              lastComma >= 0 ? '${text.substring(0, lastComma + 1)} ' : '';
          widget.controller.text = '$prefix${entry.path}';
          widget.controller.selection = TextSelection.collapsed(
            offset: widget.controller.text.length,
          );
        } else {
          widget.controller.text = entry.path;
          widget.controller.selection = TextSelection.collapsed(
            offset: entry.path.length,
          );
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 600),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final entry = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.path,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(entry),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(Tr181PathEntry entry) {
    final (label, color) = switch (entry.type) {
      Tr181PathType.object => ('OBJ', Colors.blueGrey),
      Tr181PathType.parameter when entry.access == Tr181Access.readOnly => (
          'RO',
          Colors.green
        ),
      Tr181PathType.parameter => ('RW', Colors.orange),
      Tr181PathType.command => ('CMD', Colors.purple),
      Tr181PathType.event => ('EVT', Colors.teal),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
