import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/avatars/avatar.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/base/icon.dart';
import 'package:linksys_core/widgets/buttons/toggle_button.dart';
import 'package:linksys_core/widgets/check_box/check_box.dart';
import 'package:linksys_core/widgets/container/slide_actions_container.dart';
import 'package:linksys_core/widgets/modal/modal.dart';
import 'package:linksys_core/widgets/progress_bar/progress_bar.dart';
import 'package:linksys_core/widgets/switch/switch.dart';
import 'package:linksys_core/widgets/text/app_styled_text.dart';
import 'package:linksys_core/widgets/toast/app_toast.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_core/widgets/_widgets.dart';

part 'appbar_stories.dart';
part 'button_stories.dart';
part 'checkbox_stories.dart';
part 'icon_stories.dart';
part 'switch_stories.dart';
part 'text_stories.dart';
part 'theme_stories.dart';
part 'progress_bar_stories.dart';
part 'toast_stories.dart';
part 'avatar_stories.dart';
part 'modal_stories.dart';
part 'input_stories.dart';
part 'container_stories.dart';

void main() => runApp(const MyApp());

final _plugins = initializePlugins(
  contentsSidePanel: true,
  knobsSidePanel: true,
  initialDeviceFrameData: DeviceFrameData(
    device: Devices.ios.iPhone13,
  ),
);

/// Use this wrapper to wrap each story into a [MaterialApp] widget.
Widget linksysMaterialWrapper(BuildContext _, Widget? child) => MaterialApp(
      theme: ThemeData.light().copyWith(backgroundColor: ConstantColors.primaryLinksysWhite),
      darkTheme: ThemeData.dark().copyWith(backgroundColor: ConstantColors.primaryLinksysBlack),
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      home: Home(child: child ?? Container()),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Storybook(
        wrapperBuilder: linksysMaterialWrapper,
        initialStory: 'Theme/Colors',
        plugins: _plugins,
        stories: [
          ...themeStories(),
          ...iconStories(),
          ...avatarStories(),
          ...textStories(),
          ...buttonStories(),
          ...switchStories(),
          ...checkboxStories(),
          ...toastStories(),
          ...modalStories(),
          ...inputStories(),
          ...containerStories(),
          ...appBarStories(),
        ],
      );
}

class Home extends StatefulWidget {
  const Home({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // bool isDark = false;
  // AppThemeColorMode colorMode = AppThemeColorMode.light;
  // final window = WidgetsBinding.instance.window;

  // AppThemeColorMode getColorMode() {
  //   final themeMode = context.watch<ThemeModeNotifier>().value;
  //   final brightness = themeMode == ThemeMode.system
  //       ? MediaQuery.platformBrightnessOf(context)
  //       : themeMode == ThemeMode.light
  //           ? Brightness.light
  //           : Brightness.dark;
  //   return (brightness == Brightness.light)
  //       ? AppThemeColorMode.light
  //       : AppThemeColorMode.dark;
  // }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveTheme(
      // colorMode: getColorMode(),
      child: Scaffold(
        body: SafeArea(
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
