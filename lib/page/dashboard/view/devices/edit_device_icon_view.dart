import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/profile/profile_select_avatar_view.dart';
import 'package:linksys_moab/route/_route.dart';

class EditDeviceIconView extends ArgumentsStatefulView {
  const EditDeviceIconView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<EditDeviceIconView> createState() => _EditDeviceIconViewState();
}

class _EditDeviceIconViewState extends State<EditDeviceIconView> {
  Avatar _selectedIcon = Avatar(imageUrl: '', isSelected: false);
  final _icons = [
    Avatar(imageUrl: 'assets/images/img_profile_icon_1.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_2.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_3.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_3.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_1.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_2.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_2.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_3.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_1.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_1.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_2.png', isSelected: false),
    Avatar(imageUrl: 'assets/images/img_profile_icon_3.png', isSelected: false),
  ];

  @override
  Widget build(BuildContext context) {
    return BasePageView.bottomSheetModal(
      bottomSheet: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BaseAppBar(
          leading: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => NavigationCubit.of(context).pop(),
            ),
          ],
          action: [
            box(60),
            SimpleTextButton(
              text: getAppLocalizations(context).done,
              onPressed: () {
                bool isReturnable = widget.args['return'] ?? false;
                if (isReturnable) {
                  NavigationCubit.of(context)
                      .popWithResult(_selectedIcon.imageUrl);
                }
              },
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 38),
              Text(
                getAppLocalizations(context).select_an_image,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              Flexible(
                child: GridView.count(
                  crossAxisCount: 3,
                  children: _avatarsView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _avatarsView() {
    return List.generate(
      _icons.length,
      (i) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        child: Container(
          decoration: _selectedIcon == _icons[i]
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black,
                    width: 3,
                  ),
                )
              : const ShapeDecoration(
                  shape: CircleBorder(),
                ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 84,
            icon: Image.asset(_icons[i].imageUrl),
            onPressed: () {
              setState(() {
                _selectedIcon = _icons[i];
              });
            },
          ),
        ),
      ),
    );
  }
}
