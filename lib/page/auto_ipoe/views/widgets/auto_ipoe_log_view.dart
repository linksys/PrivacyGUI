import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../../models/auto_ipoe_models.dart';

/// Read-only diagnostics shared by the inline Internet and PnP forms.
class AutoIPoELogView extends StatefulWidget {
  const AutoIPoELogView(
      {super.key,
      required this.log,
      required this.onRefresh,
      this.compact = false});
  final AutoIPoELog log;
  final bool compact;
  final Future<bool> Function() onRefresh;

  @override
  State<AutoIPoELogView> createState() => _AutoIPoELogViewState();
}

class _AutoIPoELogViewState extends State<AutoIPoELogView> {
  bool _expanded = false;
  bool _refreshing = false;
  bool _failed = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _failed = false;
    });
    var success = false;
    try {
      success = await widget.onRefresh();
    } catch (_) {
      // Keep the last readable log and report the failed refresh.
    }
    if (mounted) {
      setState(() {
        _refreshing = false;
        _failed = !success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = loc(context);
    final linkStyle = TextButton.styleFrom(
      backgroundColor: Colors.transparent,
      overlayColor: widget.compact ? Colors.transparent : null,
      padding: const EdgeInsets.symmetric(vertical: 8),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
      shape: const RoundedRectangleBorder(),
      textStyle: TextStyle(
        decoration: TextDecoration.underline,
        fontSize: widget.compact
            ? (Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) * 0.7
            : null,
      ),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: AppSpacing.md, children: [
        TextButton(
          key: const ValueKey('auto-ipoe-log-toggle'),
          style: linkStyle,
          child: Text(_expanded ? l.autoIpoeHideLog : l.autoIpoeShowLog),
          onPressed: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) _refresh();
          },
        ),
      ]),
      if (_expanded) ...[
        AppText.titleMedium(l.autoIpoeLogTitle),
        if (_refreshing) const LinearProgressIndicator(),
        if (_failed) AppText.bodySmall(l.failedToLoadSettings),
        AppGap.md(),
        SizedBox(
          height: 280,
          child: SingleChildScrollView(
            child: SelectableText(
              widget.log.content.isEmpty
                  ? l.autoIpoeNoLogOutputYet
                  : widget.log.content,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    ]);
  }
}
