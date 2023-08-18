import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SelectProtocolView extends ArgumentsConsumerStatelessView {
  const SelectProtocolView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SelectProtocolContentView(
      args: super.args,
    );
  }
}

class SelectProtocolContentView extends ArgumentsConsumerStatefulView {
  const SelectProtocolContentView({super.key, super.args});

  @override
  ConsumerState<SelectProtocolContentView> createState() =>
      _SelectProtocolContentViewState();
}

class _SelectProtocolContentViewState
    extends ConsumerState<SelectProtocolContentView> {
  late String _selected;
  static const List<String> _keys = ['UDP', 'TCP', 'BOTH'];

  @override
  void initState() {
    _selected = widget.args['selected'] ?? 'UDP';
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).single_port_forwarding,
      child: AppBasicLayout(
        content: Column(
          children: [
            const AppGap.semiBig(),
            ..._keys.map((e) => InkWell(
                  onTap: () {
                    setState(() {
                      _selected = e;
                    });
                    context.pop(_selected);
                  },
                  child: AppPanelWithValueCheck(
                    title: getProtocolTitle(e),
                    valueText: ' ',
                    isChecked: _selected == e,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String getProtocolTitle(String key) {
    if (key == 'UDP') {
      return getAppLocalizations(context).udp;
    } else if (key == 'TCP') {
      return getAppLocalizations(context).tcp;
    } else {
      return getAppLocalizations(context).udp_and_tcp;
    }
  }
}
