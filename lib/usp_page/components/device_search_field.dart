import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Determines which device field is used as the selection value.
enum DeviceSearchMode {
  /// Returns the device's IPv4 address on selection.
  ipv4,

  /// Expands each device's IPv6 addresses into separate options.
  /// Returns the selected IPv6 address string.
  ipv6,

  /// Returns the device's MAC address on selection.
  mac,
}

/// A single autocomplete option derived from [DeviceUIModel].
class _DeviceOption {
  final String displayName;
  final String value;
  final String subtitle;
  final bool isOnline;

  const _DeviceOption({
    required this.displayName,
    required this.value,
    required this.subtitle,
    required this.isOnline,
  });
}

/// Reusable device search/autocomplete field.
///
/// Provides prefix-based matching against a list of [DeviceUIModel]s.
/// The [mode] determines which field is extracted on selection:
/// - [DeviceSearchMode.ipv4]: one option per device, returns IPv4 address
/// - [DeviceSearchMode.ipv6]: one option per IPv6 address per device
/// - [DeviceSearchMode.mac]: one option per device, returns MAC address
///
/// Searches across device name, MAC, and the relevant address field.
class DeviceSearchField extends StatefulWidget {
  final List<DeviceUIModel> devices;
  final DeviceSearchMode mode;
  final TextEditingController controller;
  final String? labelText;
  final ValueChanged<String>? onSelected;
  final int maxSuggestions;

  const DeviceSearchField({
    super.key,
    required this.devices,
    required this.mode,
    required this.controller,
    this.labelText,
    this.onSelected,
    this.maxSuggestions = 30,
  });

  @override
  State<DeviceSearchField> createState() => _DeviceSearchFieldState();
}

class _DeviceSearchFieldState extends State<DeviceSearchField> {
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

  List<_DeviceOption> _buildOptions() {
    final options = <_DeviceOption>[];
    for (final device in widget.devices) {
      switch (widget.mode) {
        case DeviceSearchMode.ipv4:
          if (device.ip.isEmpty) continue;
          options.add(_DeviceOption(
            displayName: device.displayName,
            value: device.ip,
            subtitle: device.mac,
            isOnline: device.isActive,
          ));
        case DeviceSearchMode.ipv6:
          for (final addr in device.ipv6Addresses) {
            options.add(_DeviceOption(
              displayName: device.displayName,
              value: addr,
              subtitle: device.mac,
              isOnline: device.isActive,
            ));
          }
        case DeviceSearchMode.mac:
          options.add(_DeviceOption(
            displayName: device.displayName,
            value: device.mac,
            subtitle: device.ip,
            isOnline: device.isActive,
          ));
      }
    }
    return options;
  }

  bool _matches(_DeviceOption option, String query) {
    final lq = query.toLowerCase();
    return option.displayName.toLowerCase().contains(lq) ||
        option.value.toLowerCase().contains(lq) ||
        option.subtitle.toLowerCase().contains(lq);
  }

  @override
  Widget build(BuildContext context) {
    final allOptions = _buildOptions();

    return RawAutocomplete<_DeviceOption>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable.empty();
        return allOptions
            .where((o) => _matches(o, query))
            .take(widget.maxSuggestions);
      },
      displayStringForOption: (option) => option.value,
      onSelected: (option) {
        widget.controller.text = option.value;
        widget.controller.selection = TextSelection.collapsed(
          offset: option.value.length,
        );
        widget.onSelected?.call(option.value);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return AppTextField(
          controller: controller,
          focusNode: focusNode,
          hintText: widget.labelText,
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 480),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            option.isOnline
                                ? Icons.circle
                                : Icons.circle_outlined,
                            size: 8,
                            color: option.isOnline ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  option.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  option.value,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            option.subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
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
}
