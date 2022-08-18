import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';

import '../../../../design/colors.dart';
import '../../../../localization/localization_hook.dart';
import '../../../components/views/arguments_view.dart';
import '../dashboard_home_view.dart';

class ProfileOverviewView extends ArgumentsStatefulView {
  const ProfileOverviewView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ProfileOverviewView> createState() => _ProfileOverviewViewState();
}

class _ProfileOverviewViewState extends State<ProfileOverviewView> {
  late final Profile profile;

  final _blockedItems = [
    BlockedItem(category: 'Adult content', count: 10),
    BlockedItem(category: 'Streaming', count: 3),
  ];

  @override
  void initState() {
    super.initState();

    profile = widget.args['profile'];
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: ProfileHeader(
          profile: profile,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 39,
            ),
            ProfileOverviewItemView(
              title: getAppLocalizations(context).time_limits,
              description:
                  getAppLocalizations(context).time_remaining_today('1:15'),
              onPress: () {},
            ),
            _divider(),
            const SizedBox(height: 21),
            ProfileOverviewItemView(
              title: getAppLocalizations(context).internet_schedules,
              description:
                  getAppLocalizations(context).access_until_time_today('11pm'),
              onPress: () {},
            ),
            _divider(),
            const SizedBox(height: 31),
            ProfileOverviewItemView(
              title: getAppLocalizations(context).content_filtered,
              description:
                  getAppLocalizations(context).count_blocked_this_week('13'),
              padding: 12,
              onPress: () {},
            ),
            SizedBox(
              height: _blockedItems.length * 45,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _blockedItems.length,
                itemBuilder: (context, index) => GestureDetector(
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
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
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
            const SizedBox(width: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "2 " + getAppLocalizations(context).devices,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('iPhone XR, chromebook'),
                const SizedBox(height: 7),
                Text(
                  getAppLocalizations(context).online,
                  style: const TextStyle(
                    color: MoabColor.primaryBlue,
                    fontWeight: FontWeight.bold,
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
    this.title = '',
    this.description = '',
    this.padding = 5,
    this.onPress,
  }) : super(key: key);

  final String title;
  final String description;
  final double padding;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.navigate_next),
          ],
        ),
        SizedBox(height: padding),
        Text(description),
        const SizedBox(height: 20),
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
      child: Container(
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
            icon ?? Image.asset('assets/images/icon_blocked.png'),
            const SizedBox(width: 8),
            Text(blockedItem.category),
            const SizedBox(width: 7),
            Text(blockedItem.count.toString()),
          ],
        ),
      ),
    );
  }
}
