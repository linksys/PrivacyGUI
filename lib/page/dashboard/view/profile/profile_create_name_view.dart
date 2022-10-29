import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/profile_group_path.dart';

import '../../../../design/colors.dart';
import '../../../../localization/localization_hook.dart';
import '../../../../route/model/base_path.dart';
import '../../../../route/model/dashboard_path.dart';
import '../../../../route/navigation_cubit.dart';
import '../../../components/views/arguments_view.dart';

class CreateProfileNameView extends ArgumentsStatefulView {
  const CreateProfileNameView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<CreateProfileNameView> createState() => _CreateProfileNameViewState();
}

class _CreateProfileNameViewState extends State<CreateProfileNameView> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BasePageView.bottomSheetModal(
      bottomSheet: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          action: [
            TextButton(
              onPressed: () {
                context.read<ProfilesCubit>().updateCreatedProfile(name: _textController.text,);
                final next = widget.next ?? UnknownPath();
                NavigationCubit.of(context).push(CreateProfileDevicesSelectedPath()
                  ..next = next);
              },
              child: Text(
                getAppLocalizations(context).next,
                style:
                    const TextStyle(fontSize: 13, color: MoabColor.primaryBlue),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: Column(
            children: [
              const SizedBox(height: 81),
              InputField(
                titleText: getAppLocalizations(context).profile_name,
                controller: _textController,
                customPrimaryColor: Colors.black,
              ),
              const SizedBox(height: 36),
              Text(getAppLocalizations(context).add_profile_name_description),
            ],
          ),
        ),
      ),
    );
  }
}
