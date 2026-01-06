import 'dart:convert';
import 'package:privacy_gui/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/support/faq_data.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class FaqListView extends ArgumentsConsumerStatefulView {
  const FaqListView({super.key});

  @override
  ConsumerState<FaqListView> createState() => _FaqListViewState();
}

class _FaqListViewState extends ConsumerState<FaqListView> {
  List<FaqCategory> categories = [
    FaqSetupCategory(),
    FaqConnectivityCategory(),
    FaqSpeedCategory(),
    FaqPasswordCategory(),
    FaqHardwareCategory(),
  ];

  @override
  void initState() {
    super.initState();
    ref.read(menuController).setTo(NaviType.support);
  }

  @override
  Widget build(BuildContext context) {
    final supImgPath =
        Theme.of(context).brightness == Brightness.dark ? 'assets/brand/brand_img_sup_dark' : 'assets/brand/brand_img_sup';
    return StyledAppPageView(
      title: loc(context).faqs,
      backState: StyledBackState.none,
      menuWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: Spacing.small2,
            runSpacing: Spacing.small2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FutureBuilder<String?>(
                future: BrandUtils.resolveAsset(supImgPath),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.asset(
                      snapshot.data!,
                      height: 48,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              AppText.bodySmall(loc(context).faqLookingFor),
            ],
          ),
          const AppGap.medium(),
          AppTextButton.noPadding(
            loc(context).faqVisitLinksysSupport,
            identifier:
                'now-faq-link-${FaqItem.faqVisitLinksysSupport.displayString(context).kebab()}',
            onTap: () {
              gotoOfficialWebUrl(FaqItem.faqVisitLinksysSupport.url,
                  locale: ref.read(appSettingsProvider).locale);
            },
          ),
        ],
      ),
      menuOnRight: true,
      pageContentType: PageContentType.flexible,
      child: (context, constraints) {
        return SizedBox(
          width: 9.col,
          child: ListView(
            primary: true,
            shrinkWrap: true,
            children: [
              // LinksysSearchComponent(),
              // const AppGap.medium(),
              ...categories.map((category) => Column(
                    children: [
                      _buildExpansionCard(
                        title: category.displayString(context),
                        children: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: category.items
                              .map((item) => AppTextButton(
                                    item.displayString(context),
                                    identifier:
                                        'now-faq-${item.displayString(context).kebab()}',
                                    onTap: () {
                                      gotoOfficialWebUrl(item.url,
                                          locale: ref
                                              .read(appSettingsProvider)
                                              .locale);
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                      const AppGap.small2(),
                    ],
                  )),
            ],
          ),
        );
      },
    );
  }

  AppExpansionCard _buildExpansionCard({
    required String title,
    required Widget children,
  }) {
    return AppExpansionCard(
      title: title,
      identifier: 'now-faq-${title.kebab()}',
      expandedIcon: LinksysIcons.add,
      collapsedIcon: LinksysIcons.remove,
      children: [
        Row(
          children: [
            Expanded(child: children),
          ],
        ),
      ],
    );
  }
}

// (將上面定義的 SearchResult class 貼在這裡)
class SearchResult {
  final String title;
  final int? id;
  final String type;

  SearchResult({
    required this.title,
    required this.id,
    required this.type,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      id: json['id'],
      type: json['type'] ?? '',
    );
  }
}

// class LinksysSearchComponent extends StatefulWidget {
//   const LinksysSearchComponent({Key? key}) : super(key: key);

//   @override
//   State<LinksysSearchComponent> createState() => _LinksysSearchComponentState();
// }

// class _LinksysSearchComponentState extends State<LinksysSearchComponent> {

//   Future<List<SearchResult>> _fetchSearchResults(String keyword) async {
//     if (keyword.isEmpty) {
//       return [];
//     }

//     final apiUrl =
//         'https://support.linksys.com/get_related_kb_forums/?text=$keyword';

//     List<SearchResult> results = [];
//     try {
//       final response = await http.get(Uri.parse(apiUrl));

//       if (response.statusCode == 200) {
//         final data = json.decode(utf8.decode(response.bodyBytes));
//         final List<dynamic> resultsJson = data;

//         results =
//             resultsJson.map((json) => SearchResult.fromJson(json)).toList();
//       } else {
//         print('Failed to load search results: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Network error: $e');
//     } finally {}
//     return results;
//   }

//   void _launchURL(SearchResult result) async {
//     final url =
//         'https://support.linksys.com/${result.type}/article/${result.id}-en/';
//     gotoOfficialWebUrl(url);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: SearchAnchor(
//         viewBarPadding: EdgeInsets.zero,
//         builder: (context, controller) => SearchBar(
//           controller: controller,
//           hintText: 'Search in Linksys support',
//           onChanged: (value) {},
//           onSubmitted: (value) {
//             controller.openView();
//           },
//           leading: Icon(Icons.search),
//         ),
//         suggestionsBuilder: (context, controller) async {
//           final suggestion = await _fetchSearchResults(controller.text);
//           return suggestion.map((result) => ListTile(
//                 title: Text(result.title),
//                 onTap: () => _launchURL(result),
//               ));
//         },
//       ),
//     );
//   }
// }
