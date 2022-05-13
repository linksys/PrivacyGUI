import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class ShowMeHowView extends StatelessWidget {
  const ShowMeHowView({Key? key}) : super(key: key);

  static const routeName = '/show_me_how';

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      appBar: _appBar(context),
      child: BasicLayout(
        header: Text(
          'Remove any old router and cables in your setup area.',
          style: Theme.of(context).textTheme.headline3?.copyWith(
              color: Theme.of(context).colorScheme.primary),
        ),
        content: _content(context),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary
      ),
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 19,),
        StepView(
          stepIcon: _stepIcon(context, '1'),
          text: 'On your parent node, use the port labeled “Internet” to connect one end of the ethernet cable',
          image: Container(
            alignment: Alignment.centerLeft,
            child: Image.asset('assets/images/step_1.png'),
          ),
        ),
        const SizedBox(height: 24,),
        StepView(
          stepIcon: _stepIcon(context, '2'),
          text: 'Connect the other end of the ethernet cable to any open port on your modem. Make sure your modem has power.',
          image: Container(
            alignment: Alignment.centerRight,
            child: Image.asset('assets/images/step_2.png'),
          ),
        ),
        const SizedBox(height: 24,),
        StepView(
          stepIcon: _stepIcon(context, '3'),
          text: 'Be sure the cables are secure and snapped in place'
        ),
      ],
    );
  }

  Widget _stepIcon(BuildContext context, String text) {
    return Container(
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromRGBO(121, 197, 255, 1.0),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headline2?.copyWith(
            color: Theme.of(context).colorScheme.background),
      ),
    );
  }
}

class StepView extends StatelessWidget {
  const StepView({
    Key? key,
    required this.stepIcon,
    required this.text,
    this.image
  }) : super(key: key);

  final Widget stepIcon;
  final String text;
  final Widget? image;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stepIcon,
        const SizedBox(width: 8,),
        _content(context, text),
      ],
    );
  }

  Widget _content(BuildContext context, String text) {
    return Flexible(
      child: Column(
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.headline3?.copyWith(
                color: Theme.of(context).colorScheme.primary),
          ),
          image ?? Container(),
        ],
      ),
    );
  }
}