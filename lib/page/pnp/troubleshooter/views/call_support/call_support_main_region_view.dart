import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

enum CallSupportRegion {
  us(phone: '(800) 326-7114'),
  canada(phone: '1-800-326-7114'),
  latinAmerica(),
  mexico(phone: '01 800 681 1811'),
  europe(),
  belgium(phone: '022 008 298'),
  denmark(phone: '43 68 22 10'),
  netherlands(phone: '020 206 1522'),
  norway(phone: '241 59849'),
  sweden(phone: '08 517 616 68'),
  uk(phone: '02 030 274 625'),
  middleEastAndAfrica(),
  saudiArabia(phone: '800 844 5905 / 800 850 0629'),
  unitedArabEmirates(phone: '04 455 6801'),
  asiaPacific(),
  taiwan(phone: '+886-2-2656-3377'),
  hongkong(phone: '800 901 205'),
  china(phone: '4006189612'),
  japan(phone: '+81-368514359'),
  singapore(phone: '+65 3158 6277'),
  australia(phone: '1 800 605 971'),
  newZealand(phone: '0800 441 528');

  final String? phone;

  const CallSupportRegion({
    this.phone,
  });

  List<CallSupportRegion> moreRegions() {
    switch (this) {
      case latinAmerica:
        return [
          mexico,
        ];
      case europe:
        return [
          belgium,
          denmark,
          netherlands,
          norway,
          sweden,
          uk,
        ];
      case middleEastAndAfrica:
        return [
          saudiArabia,
          unitedArabEmirates,
        ];
      case asiaPacific:
        return [
          taiwan,
          hongkong,
          china,
          japan,
          singapore,
          australia,
          newZealand,
        ];
      default:
        return [];
    }
  }

  String getTitle(BuildContext context) {
    switch (this) {
      case us:
        return 'United States';
      case canada:
        return 'Canada';
      case latinAmerica:
        return 'Latin America';
      case mexico:
        return 'Mexico';
      case europe:
        return 'Europe';
      case belgium:
        return 'Belgium';
      case denmark:
        return 'Denmark';
      case netherlands:
        return 'Netherlands';
      case norway:
        return 'Norway';
      case sweden:
        return 'Sweden';
      case uk:
        return 'United Kingdom';
      case middleEastAndAfrica:
        return 'Middle East and Africa';
      case saudiArabia:
        return 'Saudi Arabia';
      case unitedArabEmirates:
        return 'United Arab Emirates';
      case asiaPacific:
        return 'Asia Pacific';
      case taiwan:
        return 'Taiwan';
      case hongkong:
        return 'Hong Kong';
      case china:
        return 'China';
      case japan:
        return 'Japan';
      case singapore:
        return 'Singapore';
      case australia:
        return 'Australia';
      case newZealand:
        return 'New Zealand';
      default:
        return '';
    }
  }
}

class CallSupportMainRegionView extends ArgumentsConsumerStatelessView {
  const CallSupportMainRegionView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StyledAppPageView(
      title: loc(context).callSupportSelectionTitle,
      enableSafeArea: (left: true, top: false, right: true, bottom: true),
      child: AppBasicLayout(
        content: ResponsiveLayout(
          desktop: _desktopLayout(),
          mobile: _mobileLayout(),
        ),
      ),
    );
  }

  List<CallSupportRegion> getMainRegions() => CallSupportRegion.values
      .where((element) => (element == CallSupportRegion.us ||
          element == CallSupportRegion.canada ||
          element.phone == null))
      .toList();

  Widget _desktopLayout() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Spacing.semiSmall,
        crossAxisSpacing: Spacing.semiBig,
        childAspectRatio: 5.8,
      ),
      itemCount: getMainRegions().length,
      itemBuilder: (context, index) => _buildRegionCard(context, index),
    );
  }

  Widget _mobileLayout() {
    return ListView.builder(
      itemCount: getMainRegions().length,
      itemBuilder: (context, index) => _buildRegionCard(context, index),
    );
  }

  AppCard _buildRegionCard(BuildContext context, int index) {
    final mainRegionList = getMainRegions();
    final region = mainRegionList[index];
    return AppCard(
      onTap: () {
        if (region == CallSupportRegion.us ||
            region == CallSupportRegion.canada) {
          _showCallInfoAlert(
            context,
            name: region.getTitle(context),
            number: region.phone ?? '',
          );
        } else {
          final moreRegions = region.moreRegions();
          if (moreRegions.isNotEmpty) {
            context.pushNamed(
              RouteNamed.callSupportMoreRegion,
              extra: {
                'main': region.getTitle(context),
                'moreRegions': moreRegions,
              },
            );
          }
        }
      },
      child: Row(
        children: [
          Expanded(
            child: AppText.titleMedium(
              region.getTitle(context),
            ),
          ),
          if (region != CallSupportRegion.us &&
              region != CallSupportRegion.canada)
            const Icon(LinksysIcons.chevronRight),
        ],
      ),
    );
  }

  Future<void> _showCallInfoAlert(
    BuildContext context, {
    required String name,
    required String number,
  }) {
    return showSimpleAppOkDialog(
      context,
      title: name,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LinksysIcons.contact,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const AppGap.regular(),
                  AppText.titleLarge(
                    number,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 40,
                  top: Spacing.semiSmall,
                ),
                child: AppText.bodyMedium(
                    loc(context).callSupportDetailTwentyFourSeven),
              ),
            ],
          ),
          const AppGap.extraBig(),
          AppText.bodyLarge(loc(context).callSupportDetailDesc),
        ],
      ),
    );
  }
}