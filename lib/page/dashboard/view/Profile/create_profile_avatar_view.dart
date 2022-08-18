import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';

import '../../../../localization/localization_hook.dart';
import '../../../../route/model/base_path.dart';
import '../../../../route/navigation_cubit.dart';
import '../../../components/views/arguments_view.dart';

class CreateProfileAvatarView extends ArgumentsStatefulView {
  const CreateProfileAvatarView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<CreateProfileAvatarView> createState() =>
      _CreateProfileAvatarViewState();
}

class _CreateProfileAvatarViewState extends State<CreateProfileAvatarView> {
  final TextEditingController _textController = TextEditingController();
  Avatar _selectedAvatar = Avatar(imageUrl: '', isSelected: false);
  final _avatars = [
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
        alignment: CrossAxisAlignment.start,
        header: BaseAppBar(
          title: Text(
            getAppLocalizations(context).add_profile,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => NavigationCubit.of(context).pop(),
            ),
          ],
          action: const [
            SizedBox(
              width: 60,
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Flexible(
                child: GridView.count(
                  crossAxisCount: 3,
                  children: _avatarsView(),
                ),
              ),
              const SizedBox(height: 70),
              PrimaryButton(
                text: getAppLocalizations(context).done,
                onPress: () {
                  final next = widget.next ?? UnknownPath();
                  NavigationCubit.of(context).popTo(next);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _avatarsView() {
    return List.generate(
      _avatars.length,
      (i) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        child: Container(
          decoration: _selectedAvatar == _avatars[i]
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
            icon: Image.asset(_avatars[i].imageUrl),
            onPressed: () {
              setState(() {
                _selectedAvatar = _avatars[i];
              });
            },
          ),
        ),
      ),
    );
  }
}

class Avatar {
  String imageUrl;
  bool isSelected;

  Avatar({required this.imageUrl, required this.isSelected});
}
