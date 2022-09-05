import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';

import '../../../../design/colors.dart';
import '../../../../localization/localization_hook.dart';
import '../../../../route/model/base_path.dart';
import '../../../../route/model/dashboard_path.dart';
import '../../../../route/navigation_cubit.dart';
import '../../../components/views/arguments_view.dart';

class ProfileEditNameAvatarView extends ArgumentsStatefulView {
  const ProfileEditNameAvatarView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<ProfileEditNameAvatarView> createState() =>
      _ProfileEditNameAvatarViewState();
}

class _ProfileEditNameAvatarViewState extends State<ProfileEditNameAvatarView> {
  final TextEditingController _textController = TextEditingController();
  late String _iconPath;

  @override
  void initState() {
    _textController.text =
        context.read<ProfilesCubit>().state.selectedProfile?.name ?? '';
    _iconPath = context.read<ProfilesCubit>().state.selectedProfile?.icon ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(getAppLocalizations(context).name,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
        actions: [
          TextButton(
              onPressed: () {},
              child: Text(getAppLocalizations(context).save,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: MoabColor.textButtonBlue))),
        ],
      ),
      child:
          BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
        return Column(
          children: [
            box36(),
            Hero(
              tag: 'profile-${state.selectedProfile?.id}',
              child: SizedBox(
                width: 92,
                height: 92,
                child: Image.asset(
                  _iconPath ?? '',
                  width: 81,
                  height: 81,
                ),
              ),
            ),
            SimpleTextButton(
                text: getAppLocalizations(context).change,
                onPressed: () {
                  showPopup(
                    context: context,
                    config: CreateProfileAvatarPath()..args = {'return': true},
                  ).then((value) {
                    setState(() {
                      _iconPath = value;
                    });
                  });
                }),
            box16(),
            InputField(
              titleText: getAppLocalizations(context).profile_name,
              controller: _textController,
              customPrimaryColor: Colors.black,
            ),
          ],
        );
      }),
    );
  }
}
