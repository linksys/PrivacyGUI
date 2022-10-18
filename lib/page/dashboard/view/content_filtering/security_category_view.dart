import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/secure_profile.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/customs/app_icon_view.dart';
import 'package:linksys_moab/page/components/customs/popup_button.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';

import 'package:linksys_moab/util/in_app_browser.dart';
import 'package:styled_text/styled_text.dart';
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
            ],
          ),
          box16(),
          Text(
            _category.description,
          ),
          box36(),
          Card(
            color: MoabColor.dashboardDisabled,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                    'Websites',
                    style: Theme.of(context).textTheme.headline2,
                  )),
                  PopupButton(
                    icon: Icon(Icons.info_outlined),
                    content: StyledText(
                        text: 'Websites are reviewed and categorized by Fortinet, a cyber security company.  To check a website’s categorization, visit <link1 href="https://fortiguard.com/webfilter">fortiguard.com/webfilter</link1> and enter the URL.',
                        style: Theme
                            .of(context)
                            .textTheme
                            .headline3
                            ?.copyWith(color: Theme
                            .of(context)
                            .colorScheme
                            .tertiary)
                            .copyWith(height: 1.5),
                        tags: {
                          'link1': StyledTextActionTag(
                                  (String? text, Map<String?, String?> attrs) {
                                String? link = attrs['href'];
                                MoabInAppBrowser.withDefaultOption().openUrlRequest(
                                    urlRequest: URLRequest(
                                        url: Uri.parse(link!)
                                    )
                                );
                              }
                              ,style: const TextStyle(color: Colors.blue)),
                        }
                    )
                  ),
                  createStatusButton(context, _category.status, onPressed: () {
                    setState(() {
                      _category = _category.copyWith(
                          status:
                          CFSecureCategory.switchStatus(_category.status));
                    });
                  })
                ],
              ),
            ),
          ),
          box8(),
          Card(color: MoabColor.dashboardDisabled, child: _appSection()),
          box36(),
          SimpleTextButton(
            text: 'Send feedback',
            onPressed: () {},
            padding: EdgeInsets.zero,
          ),
          Text('Suggest a category or app'),
        ],
      ),
    );
  }

  Widget _appSection() {
    logger.d('app count: ${_category.apps.length}');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                  child: Text(
                'App (${_category.apps.length})',
                style: Theme.of(context).textTheme.headline2,
              )),
              IconButton(onPressed: () {
                NavigationCubit.of(context).push(CFAppSearchPath());
              }, icon: Icon(Icons.search)),
              createStatusButton(
                context,
                _category.getAppSummaryStatus(),
              )
            ],
          ),
        ),
        dividerWithPadding(padding: EdgeInsets.symmetric(horizontal: 16)),
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
