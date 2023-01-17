import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:linksys_core/theme/_theme.dart';

part 'stories/appbar_stories.dart';
part 'stories/button_stories.dart';
part 'stories/checkbox_stories.dart';
part 'stories/icon_stories.dart';
part 'stories/switch_stories.dart';
part 'stories/text_stories.dart';
part 'stories/theme_stories.dart';
part 'stories/progress_bar_stories.dart';
part 'stories/toast_stories.dart';
part 'stories/avatar_stories.dart';
part 'stories/modal_stories.dart';
part 'stories/input_stories.dart';
part 'stories/container_stories.dart';
part 'stories/panel_stories.dart';

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
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      // supportedLocales: AppLocalizations.supportedLocales,
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
          ...panelStories(),
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
