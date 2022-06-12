import 'package:flutter/cupertino.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/selectable_item.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class LoginOTPMethodsView extends StatefulWidget {
  const LoginOTPMethodsView(
      {Key? key, required this.onTextNext, required this.onEmailNext})
      : super(key: key);

  final void Function() onTextNext;
  final void Function() onEmailNext;

  @override
  _ChooseOTPMethodsState createState() => _ChooseOTPMethodsState();
}

class _ChooseOTPMethodsState extends State<LoginOTPMethodsView> {
  final List<String> _methods = [
    'Text',
    'Email',
  ];
  late String selectedMethod;

  @override
  void initState() {
    super.initState();
    selectedMethod = _methods.first;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Where should we send your code?',
        ),
        content: Column(
          children: [
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _methods.length,
                itemBuilder: (context, index) => GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SelectableItem(
                          text: _methods[index],
                          isSelected: selectedMethod == _methods[index],
                          height: 66,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedMethod = _methods[index];
                        });
                      },
                    )),
            const SizedBox(
              height: 61,
            ),
            PrimaryButton(
              text: 'Send',
              onPress: selectedMethod == _methods.first
                  ? widget.onTextNext
                  : widget.onEmailNext,
            )
          ],
        ),
      ),
    );
  }
}
