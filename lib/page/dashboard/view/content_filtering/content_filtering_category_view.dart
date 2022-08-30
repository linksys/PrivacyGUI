import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/space/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/model.dart';
import 'package:linksys_moab/route/route.dart';

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
  late CFFilterCategory _category;

  @override
  void initState() {
    super.initState();
    _category = widget.args['selected'] as CFFilterCategory;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              NavigationCubit.of(context).pop();
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
              createStatusButton(context, _category.status)
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
    return ListView.separated(
      itemBuilder: (context, index) => ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(4))),
        ),
        title: Text(_category.apps[index].name),
        trailing: createStatusButton(context, _category.apps[index].status),
      ),
      separatorBuilder: (_, __) => SizedBox(
        width: 16,
      ),
      itemCount: _category.apps.length,
      shrinkWrap: true,
    );
  }
}
