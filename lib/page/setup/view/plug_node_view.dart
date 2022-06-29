import 'package:flutter/cupertino.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../components/base_components/button/primary_button.dart';

class PlugNodeView extends StatelessWidget {
  PlugNodeView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final VoidCallback onNext;

  static const routeName = '/plug_node';

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
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: AppLocalizations.of(context)!.plug_node_view_title,
        ),
        content: _content(),
        footer: PrimaryButton(
          text: AppLocalizations.of(context)!.next,
          onPress: onNext,
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
