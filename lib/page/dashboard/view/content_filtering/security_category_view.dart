import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/security/app_icon_manager.dart';
import 'package:linksys_moab/util/logger.dart';

import 'component.dart';

typedef ValueChanged<T> = void Function(T value);

class ContentFilteringCategoryView extends ArgumentsStatefulView {
  const ContentFilteringCategoryView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ContentFilteringCategoryView> createState() =>
      _ContentFilteringCategoryViewState();
}

class _ContentFilteringCategoryViewState
    extends State<ContentFilteringCategoryView> {
  late CFSecureCategory _category;

  @override
  void initState() {
    super.initState();
    _category = widget.args['selected'] as CFSecureCategory;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      scrollable: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              // NavigationCubit.of(context).pop();
              NavigationCubit.of(context).popWithResult(_category);
            }),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box16(),
          Row(
            children: [
              Expanded(
                  child: Text(
                _category.name,
                style: Theme.of(context).textTheme.headline2,
              )),
              createStatusButton(context, _category.status, onPressed: () {
                setState(() {
                  _category = _category.copyWith(
                      status: CFSecureCategory.switchStatus(_category.status));
                });
              })
            ],
          ),
          box16(),
          Text(
            _category.description,
          ),
          box36(),
          _appSection(),
        ],
      ),
    );
  }

  Widget _appSection() {
    logger.d('app count: ${_category.apps.length}');
    return Column(
      children: [
        ..._category.apps.map((e) => ListTile(
            leading: AppIconView(appId: e.icon,),
            title: Text(e.name),
            trailing: createStatusButton(context, e.status, onPressed: () {
              setState(() {
                final newOne =
                    e.copyWith(status: CFSecureCategory.switchStatus(e.status));
                _category.apps.replaceRange(_category.apps.indexOf(e),
                    _category.apps.indexOf(e) + 1, [newOne]);
              });
            })))
      ],
    );
  }
}

class AppIconView extends StatefulWidget {
  const AppIconView({
    Key? key,
    this.appId = '0',
  }) : super(key: key);

  final String appId;

  @override
  State<AppIconView> createState() => _AppIconViewState();
}

class _AppIconViewState extends State<AppIconView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: FutureBuilder<Uint8List>(
            future: AppIconManager.instance().getIconByte(widget.appId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(snapshot.data!);
              } else if (snapshot.hasError) {
                return const Icon(Icons.cancel);
              } else {
                return const CircularProgressIndicator(
                  color: MoabColor.placeholderGrey,
                );
              }
            }),
      ),
    );
  }
}
