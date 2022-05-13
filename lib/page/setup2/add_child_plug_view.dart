import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class AddChildPlugView extends StatelessWidget {
  AddChildPlugView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final void Function() onNext;

  //TODO: This svg file does not work
  // final Widget image = SvgPicture.asset(
  //   'assets/images/linksys_logo_large_white.svg',
  //   semanticsLabel: 'Setup Finished',
  // );
  final Widget image = Image.asset('assets/images/plug_node.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Plug child node into a power source',
        ),
        content: Container(
          child: Stack(
            children: [
              Positioned(
                bottom: -45,
                right: 0,
                child: image,
              ),
              Positioned(
                bottom: 40,
                left: 0,
                child: SimpleTextButton(
                  text: 'Placement guide',
                  onPressed: () {
                    //TODO: onPressed Action
                  }
                ),
              )
            ],
          ),
          alignment: Alignment.bottomCenter,
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: 'Next',
              onPress: onNext,
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
