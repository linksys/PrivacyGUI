import 'package:flutter/material.dart';

class HiddenPasswordWidget extends StatefulWidget {
  final String password;
  const HiddenPasswordWidget({
    Key? key,
    required this.password
  }): super(key: key);

  @override
  _HiddenPasswordWidgetState createState() => _HiddenPasswordWidgetState();
}

class _HiddenPasswordWidgetState extends State<HiddenPasswordWidget> {
  bool isPwSecure = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _getPasswordContent(),
          style: Theme.of(context).textTheme.headline2,
        ),
        const SizedBox(
          width: 6,
        ),
        InkWell(
          child: isPwSecure
              ? Image.asset('assets/images/eye_open.png')
              : Image.asset('assets/images/eye_close.png'),
          onTap: () {
            setState(() {
              isPwSecure = !isPwSecure;
            });
          },
        ),
      ],
    );
  }

  String _getPasswordContent() {
    String result = widget.password;
    if (isPwSecure) {
      for (var i = 0; i < result.length - 2; i++) {
        result = result.replaceRange(i, i + 1, '*');
      }
    }
    return result;
  }
}