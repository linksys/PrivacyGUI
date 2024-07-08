import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/string_mapping.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class ConnectionTypeSelectionView extends ArgumentsConsumerStatefulView {
  const ConnectionTypeSelectionView({super.key, super.args});

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
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).connectionType,
      child: AppBasicLayout(
        content: Column(
          children: [
            ..._supportedList
                .map((e) => toConnectionTypeData(context, e))
                .map((connectionType) {
              return Opacity(
                opacity: _disabled.contains(connectionType.type) ? 0.5 : 1.0,
                child: AppSettingCard(
                  title: connectionType.title,
                  //   description: connectionType.description,
                  trailing: Icon(connectionType.type == _selected
                      ? LinksysIcons.check
                      : LinksysIcons.chevronRight),
                  onTap: _disabled.contains(connectionType.type)
                      ? null
                      : () {
                          setState(() {
                            _selected = connectionType.type;
                          });
                          context.pop(_selected);
                        },
                ),
              );
            }).expand<Widget>((element) sync* {
              yield element;
              yield const AppGap.small2();
            }).toList(),
          ],
        ),
      ),
    );
  }
}
