import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/string_mapping.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class ConnectionTypeSelectionView extends ArgumentsStatefulView {
  const ConnectionTypeSelectionView({super.key, super.next, super.args});

  @override
  State<ConnectionTypeSelectionView> createState() =>
      _ConnectionTypeSelectionViewState();
}

class _ConnectionTypeSelectionViewState
    extends State<ConnectionTypeSelectionView> {
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

  Widget _buildPanel(String supportedType) {
    final connectionType = toConnectionTypeData(context, supportedType);
    return AppPanelWithTrailWidget(
      title: connectionType.title,
      description: connectionType.description,
      trailing: Center(
        child: connectionType.type == _selected
            ? AppIcon.regular(
                icon: AppTheme.of(context).icons.characters.checkDefault,
              )
            : null,
      ),
      onTap: _disabled.contains(connectionType.type)
          ? null
          : () {
              setState(() {
                _selected = connectionType.type;
              });
              NavigationCubit.of(context).popWithResult(_selected);
            },
    );
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
                        NavigationCubit.of(context).popWithResult(_selected);
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
