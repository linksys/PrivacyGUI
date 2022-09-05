import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/customs/customs.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/model/dashboard_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

import '../../../../design/colors.dart';
import '../../../../localization/localization_hook.dart';
import '../../../components/views/arguments_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_home_view.dart';

class ProfileOverviewView extends ArgumentsStatefulView {
  const ProfileOverviewView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ProfileOverviewView> createState() => _ProfileOverviewViewState();
}

class _ProfileOverviewViewState extends State<ProfileOverviewView> {

  final _blockedItems = [
    BlockedItem(category: 'Adult content', count: 10),
    BlockedItem(category: 'Streaming', count: 3),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        return BasePageView(
          scrollable: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          child: BasicLayout(
            header: ProfileHeader(
              profile: state.selectedProfile!,
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box36(),
                ProfileOverviewItemView(
                  icon: Image.asset(
                    'assets/images/icon_wifi.png',
                    width: 24,
                    height: 24,
                  ),
                  description:
                      getAppLocalizations(context).time_remaining_today('1:15'),
                  onPress: () {},
                ),
                box16(),
                ProfileOverviewItemView(
                  icon: Image.asset(
                    'assets/images/icon_clock.png',
                    width: 24,
                    height: 24,
                  ),
                  description:
                      getAppLocalizations(context).access_until_time_today('11pm'),
                  onPress: () {},
                ),
                box16(),
                ProfileOverviewItemView(
                  icon: Image.asset(
                    'assets/images/icon_block.png',
                    width: 24,
                    height: 24,
                  ),
                  description:
                      getAppLocalizations(context).count_blocked_this_week('13'),
                  padding: 12,
                  onPress: () {},
                ),
                box16(),
                SizedBox(
                  height: _blockedItems.length * 45,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _blockedItems.length,
                    itemBuilder: (context, index) => InkWell(
                      child: BlockedItemView(
                        blockedItem: _blockedItems[index],
                      ),
                      onTap: () {},
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  _divider() {
    return Container(
      width: double.infinity,
      height: 1,
      decoration: const BoxDecoration(color: MoabColor.placeholderGrey),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({Key? key, required this.profile}) : super(key: key);
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            SimpleTextButton(
                onPressed: () {
                  NavigationCubit.of(context).push(ProfileEditPath());
                }, text: getAppLocalizations(context).edit),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Hero(
              tag: 'profile-${profile.id}',
              child: SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(11),
                      child: Image.asset(
                        profile.icon,
                        width: 81,
                        height: 81,
                      ),
                    ),
                    Image.asset(
                      'assets/images/icon_pause.png',
                      width: 36,
                      height: 36,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getAppLocalizations(context).online,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                box8(),
                Text(
                  getAppLocalizations(context).number_of_devices(profile.devices.length),
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }
}

class ProfileOverviewItemView extends StatelessWidget {
  const ProfileOverviewItemView({
    Key? key,
    this.icon,
    this.description = '',
    this.padding = 5,
    this.onPress,
  }) : super(key: key);

  final String description;
  final double padding;
  final VoidCallback? onPress;
  final Image? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon ?? const Center(),
            box8(),
            Text(description),
          ],
        ),
      ],
    );
  }
}

class BlockedItem {
  String category;
  int count;

  BlockedItem({required this.category, required this.count});
}

class BlockedItemView extends StatelessWidget {
  const BlockedItemView({
    Key? key,
    required this.blockedItem,
    this.icon,
  }) : super(key: key);

  final BlockedItem blockedItem;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: MoabColor.placeholderGrey,
                width: 1,
              ),
            ),
            child: Wrap(
              children: [
                Text(blockedItem.category),
                const SizedBox(width: 7),
                Text(blockedItem.count.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
