import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/string_mapping.dart';

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

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // iconTheme:
        // IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
        title: Text(
          getAppLocalizations(context).connection_type,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: BasicLayout(
        content: Column(
          children: [
            box24(),
            ..._supportedList
                .map((e) => toConnectionTypeData(context, e))
                .map((connectionType) {
              return ListTile(
                title: Text(connectionType.title),
                subtitle: Text(connectionType.description),
                trailing: SizedBox(
                  child: connectionType.type == _selected
                      ? Image.asset('assets/images/icon_check_black.png')
                      : null,
                  height: 36,
                  width: 36,
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
