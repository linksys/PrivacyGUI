import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/theme/material/color_tonal_palettes.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

///
/// LogoType - Define the type of logo to display
/// logo - Only display the logo
/// title - Only display the title
/// both - Display both the logo and title
///
enum LogoType {
  logo,
  title,
  both;

  static LogoType fromString(String name) {
    return values.firstWhere((element) => element.name == name,
        orElse: () => title);
  }

  static LogoType fromEnvironment() {
    const type = String.fromEnvironment('logo', defaultValue: 'title');
    return fromString(type);
  }
}

class LogoWidget extends StatefulWidget {
  const LogoWidget({Key? key}) : super(key: key);

  @override
  State<LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<LogoWidget> {
  late final LogoType logoType;

  @override
  void initState() {
    super.initState();
    logoType = LogoType.fromEnvironment();
  }

  @override
  Widget build(BuildContext context) {
    final widget = switch (logoType) {
      LogoType.logo => _buildLogo(),
      LogoType.title => AppText.titleLarge(loc(context).appTitle,
          color: Color(neutralTonal.get(100))),
      LogoType.both => Row(mainAxisSize: MainAxisSize.min, children: [
          _buildLogo(),
          AppText.titleLarge(loc(context).appTitle,
              color: Color(neutralTonal.get(100))),
        ]),
    };
    return widget;
  }

  Widget _buildLogo() {
    const extension =
        String.fromEnvironment('logo_extension', defaultValue: 'svg');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Image.asset('assets/logo_brand.$extension', height: 84, width: 84,
          errorBuilder: (context, error, stackTrace) {
        return SvgPicture.asset('assets/logo_brand.svg', height: 84, width: 84,
            errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        });
      }),
    );
  }
}
