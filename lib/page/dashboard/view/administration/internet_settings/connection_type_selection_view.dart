import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/string_mapping.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class ConnectionTypeSelectionView extends ArgumentsConsumerStatefulView {
  const ConnectionTypeSelectionView({super.key, super.next, super.args});

  @override
  ConsumerState<ConnectionTypeSelectionView> createState() =>
      _ConnectionTypeSelectionViewState();
}

class _ConnectionTypeSelectionViewState
    extends ConsumerState<ConnectionTypeSelectionView> {
  late final List<String> _supportedList;
  late final List<String> _disabled;
  String _selected = '';

  @override
  void initState() {
    _supportedList = widget.args['supportedList'] ?? [];
    _disabled = widget.args['disabled'] ?? [];
    _selected = widget.args['selected'] ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledLinksysPageView(
      scrollable: true,
      title: getAppLocalizations(context).connection_type,
      child: LinksysBasicLayout(
        content: Column(
          children: [
            const LinksysGap.semiBig(),
            ..._supportedList
                .map((e) => toConnectionTypeData(context, e))
                .map((connectionType) {
              return InkWell(
                onTap: _disabled.contains(connectionType.type)
                    ? null
                    : () {
                        setState(() {
                          _selected = connectionType.type;
                        });
                        ref
                            .read(navigationsProvider.notifier)
                            .popWithResult(_selected);
                      },
                child: AppPanelWithValueCheck(
                  title: connectionType.title,
                  description: connectionType.description,
                  valueText: '',
                  isChecked: connectionType.type == _selected,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
