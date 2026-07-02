import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dialog for editing WiFi radio channel settings.
///
/// The channel is chosen from an [AppDropdown] whose options are built
/// synchronously from [WifiRadioUIModel.possibleChannels] (already fetched at
/// dashboard load time — no per-dialog fetch, loading, or error state).
///
/// Returns a `({int channel, bool autoChannel})` record on Apply, or `null`
/// on Cancel or when the selection is unchanged (no-op).
class WifiChannelDialog extends StatefulWidget {
  final WifiRadioUIModel radio;

  const WifiChannelDialog({super.key, required this.radio});

  @override
  State<WifiChannelDialog> createState() => _WifiChannelDialogState();
}

class _WifiChannelDialogState extends State<WifiChannelDialog> {
  /// Sentinel dropdown value representing the "Auto (recommended)" option.
  static const int _autoValue = -1;

  /// Currently-selected dropdown value; [_autoValue] means Auto.
  late int _selected;

  /// Manual channels available for this radio's band, sorted ascending.
  late final List<int> _channels;

  bool get _autoChannel => _selected == _autoValue;

  bool get _hasManualChannels => _channels.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _channels = widget.radio.possibleChannels;
    // AC5: a stored channel that is no longer selectable defaults to Auto
    // (no ghost value is ever shown).
    final storedChannelSelectable = !widget.radio.autoChannelEnable &&
        _channels.contains(widget.radio.channel);
    _selected = storedChannelSelectable ? widget.radio.channel : _autoValue;
  }

  /// 5 GHz DFS channels (IEEE 802.11h). Used to annotate options with "· DFS".
  static const _dfsChannels5 = {
    52, 56, 60, 64, //
    100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144,
  };

  bool _isDfs(int channel) =>
      widget.radio.band == '5GHz' && _dfsChannels5.contains(channel);

  String _labelFor(int value) {
    if (value == _autoValue) return loc(context).channelAutoRecommended;
    final suffix = _isDfs(value) ? ' ${loc(context).channelDfsSuffix}' : '';
    return '$value$suffix';
  }

  @override
  Widget build(BuildContext context) {
    // AC2/AC6: options are Auto + the band's manual channels. When there are
    // no manual channels the dropdown collapses to a single locked Auto entry.
    final items = <int>[_autoValue, ..._channels];

    // AC3: Auto switch ON => dropdown disabled (shows Auto).
    //      Auto switch OFF => dropdown enabled.
    // AC6: no manual channels => dropdown is always disabled (locked to Auto).
    final dropdownEnabled = _hasManualChannels && !_autoChannel;

    return AlertDialog(
      title: Text('${loc(context).channel} — ${widget.radio.band}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(loc(context).autoChannel),
              AppSwitch(
                value: _autoChannel,
                // AC6: with no manual channels there is nothing to switch to,
                // so the toggle is disabled and Auto is enforced.
                onChanged: _hasManualChannels
                    ? (value) => setState(() {
                          if (value) {
                            _selected = _autoValue;
                          } else {
                            // Turning Auto OFF: restore the stored channel when
                            // still selectable, otherwise pick the first one.
                            _selected = _channels.contains(widget.radio.channel)
                                ? widget.radio.channel
                                : _channels.first;
                          }
                        })
                    : null,
              ),
            ],
          ),
          AppGap.lg(),
          // The UI-kit AppDropdown only marks itself Semantics(enabled:false)
          // when onChanged is null — its tap gesture stays wired, so the menu
          // still opens (upstream bug linksys/privacyGUI-UI-kit#2). Wrap it in
          // an IgnorePointer to truly block interaction when disabled, while
          // keeping onChanged null for correct semantics.
          IgnorePointer(
            ignoring: !dropdownEnabled,
            child: AppDropdown<int>(
              items: items,
              value: _selected,
              label: loc(context).channel,
              itemAsString: _labelFor,
              // AC3: selecting Auto in the dropdown flips the switch back ON.
              onChanged: dropdownEnabled
                  ? (value) {
                      if (value != null) setState(() => _selected = value);
                    }
                  : null,
            ),
          ),
          AppGap.sm(),
          // Per mockup, always surface the channel the router is actually using
          // — in both Auto and manual modes — whenever manual options exist.
          if (!_hasManualChannels)
            AppText.bodySmall(loc(context).channelNoManualOptions)
          else
            AppText.bodySmall(
                loc(context).channelCurrentlyUsing(widget.radio.channel)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc(context).cancel),
        ),
        FilledButton(
          onPressed: _onApply,
          child: Text(loc(context).apply),
        ),
      ],
    );
  }

  void _onApply() {
    final autoChannel = _autoChannel;
    // When Auto is selected the concrete channel is irrelevant to firmware;
    // keep the existing value so the returned record is stable.
    final channel = autoChannel ? widget.radio.channel : _selected;

    // AC4: selection equal to the stored value is a no-op — return null so the
    // caller issues no mutation.
    final unchanged = autoChannel == widget.radio.autoChannelEnable &&
        (autoChannel || channel == widget.radio.channel);
    if (unchanged) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop((channel: channel, autoChannel: autoChannel));
  }
}
