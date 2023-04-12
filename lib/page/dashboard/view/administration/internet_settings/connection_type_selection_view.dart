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
    List<Widget> supportedList = _supportedList
        .map((e) => toConnectionTypeData(context, e))
        .map((connectionType) {
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
    }).toList();
    return StyledLinksysPageView(
      scrollable: true,
      title: getAppLocalizations(context).connection_type,
      child: LinksysBasicLayout(
        content: Column(
          children: [
            const LinksysGap.semiBig(),

            // TODO: Need to fix

            // for (String supportedType in _supportedList)
            //   _buildPanel(supportedType),

            // _buildPanel(_supportedList[0]),
            // _buildPanel(_supportedList[1]),
            // _buildPanel(_supportedList[2]),
            // _buildPanel(_supportedList[3]),
            // _buildPanel(_supportedList[4]),
            // _buildPanel(_supportedList[5]),

            // SizedBox(
            //   height: (174.0) * _supportedList.length,
            //   child: ListView.builder(
            //     shrinkWrap: true,
            //     physics: const NeverScrollableScrollPhysics(),
            //     itemCount: _supportedList.length,
            //     itemBuilder: (context, index) =>
            //         _buildPanel(_supportedList[index]),
            //   ),
            // ),

            // ..._supportedList
            //     .map((e) => toConnectionTypeData(context, e))
            //     .map((connectionType) {
            //   // return AppSimplePanel(
            //   //   title: connectionType.title,
            //   //   description: connectionType.description,
            //   // );

            //   return AppPanelWithTrailWidget(
            //     title: connectionType.title,
            //     description: connectionType.description,
            //     trailing: Center(
            //       child: connectionType.type == _selected
            //           ? AppIcon.regular(
            //               icon: AppTheme.of(context)
            //                   .icons
            //                   .characters
            //                   .checkDefault,
            //             )
            //           : null,
            //     ),
            //     onTap: _disabled.contains(connectionType.type)
            //         ? null
            //         : () {
            //             setState(() {
            //               _selected = connectionType.type;
            //             });
            //             NavigationCubit.of(context).popWithResult(_selected);
            //           },
            //   );

            ..._supportedList
                .map((e) => toConnectionTypeData(context, e))
                .map((connectionType) {
              return ListTile(
                title: Text(connectionType.title),
                subtitle: Text(connectionType.description),
                trailing: SizedBox(
                  height: 36,
                  width: 36,
                  child: connectionType.type == _selected
                      ? AppIcon(
                          icon: AppTheme.of(context)
                              .icons
                              .characters
                              .checkDefault,
                        )
                      : null,
                ),
                contentPadding: const EdgeInsets.only(bottom: 24),
                enabled: !_disabled.contains(connectionType.type),
                onTap: _disabled.contains(connectionType.type)
                    ? null
                    : () {
                        setState(() {
                          _selected = connectionType.type;
                        });
                        NavigationCubit.of(context).popWithResult(_selected);
                      },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
