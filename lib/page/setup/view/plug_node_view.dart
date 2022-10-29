import 'package:flutter/cupertino.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/_route.dart';


import '../../components/base_components/button/primary_button.dart';
import 'package:linksys_moab/route/model/_model.dart';

class PlugNodeView extends StatelessWidget {
  PlugNodeView({
    Key? key,
  }) : super(key: key);

  //TODO: This svg file does not work
  // final Widget image = SvgPicture.asset(
  //   'assets/images/plug_node.svg',
  // );

  // Remove this if the upper svg image is fixed
  final Widget image = Image.asset('assets/images/plug_node.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).plug_node_view_title,
        ),
        content: _content(),
        footer: PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: () => NavigationCubit.of(context).push(SetupParentWiredPath()),
        ),
      ),
    );
  }

  Widget _content() {
    return Stack(
      children: [
        Container(
          alignment: Alignment.bottomRight,
          child: image,
        ),
        Column(
          children: const [
            Spacer(),
            // TODO: Add on press method
            SizedBox(
              height: 79,
            ),
          ],
        ),
      ],
    );
  }
}
