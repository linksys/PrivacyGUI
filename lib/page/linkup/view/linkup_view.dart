import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

const tempData = {
  "subject": "Here's what we are working on next...",
  "contents": [
    {
      "category": "Features",
      "items": [
        {
          "title": "Privacy Pledge",
          "body":
              "We DO NOT monitor, collect, or store your browsing and application use data."
        },
        {
          "title": "Linksys Cognitive™ Mesh",
          "body":
              "Set up your reliable whole home mesh system in a matter of minutes."
        },
        {
          "title": "Linksys Cognitive™ Experience",
          "body":
              "Make your connectivity issues disappear like magic with the Linksys support team."
        },
        {
          "title": "Safe Browsing",
          "body": "Block adult content with a single tap."
        }
      ]
    },
    {
      "category": "Products",
      "items": [
        {
          "title": "New WiFi 6e Routers",
          "body":
              "Blazing fast and reliable connectivity with the latest WiFi 6e laptops, tablets and smartphones."
        }
      ]
    }
  ]
};

class LinkupView extends ConsumerStatefulWidget {
  const LinkupView({super.key});

  @override
  ConsumerState<LinkupView> createState() => _LinkupViewState();
}

class _LinkupViewState extends ConsumerState<LinkupView> {
  late final Future<Map<String, dynamic>> _future;

  @override
  initState() {
    super.initState();
    _future =
        Future.delayed(const Duration(seconds: 1)).then((value) => tempData);
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      child: FutureBuilder(
          future: _future,
          builder: ((context, snapshot) {
            // Check for errors
            if (snapshot.hasError) {
              // TODO Something wrong here
              return const Center(
                child: AppText.descriptionMain('Unexceped error'),
              );
            }

            // Once complete, show your application
            if (snapshot.connectionState == ConnectionState.done) {
              final data = snapshot.data;
              if (data == null) {
                return const Center(
                  child: AppText.descriptionMain('No news!'),
                );
              }
              return ListView(
                shrinkWrap: true,
                primary: false,
                children: [
                  const Center(
                    child: AppText.screenName('Linksys linkup'),
                  ),
                  const AppGap.regular(),
                  AppText.descriptionMain(data['subject'] ?? ''),
                  const AppGap.big(),
                  ...List.from(data['contents']).map((content) {
                    return ExpansionTile(
                      initiallyExpanded: true,
                      title: AppText.tags(content['category']),
                      children: List.from(content['items'])
                          .map((item) => AppSimplePanel(
                                title: item['title'],
                                description: item['body'],
                              ))
                          .toList(),
                    );
                  }).toList(),
                ],
              );
            }

            // Otherwise, show something whilst waiting for initialization to complete
            return const AppFullScreenSpinner();
          })),
    );
  }
}
