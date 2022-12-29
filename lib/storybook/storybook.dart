import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_moab/storybook/_storybook.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      // theme: MoabTheme.mainLightModeData,
      // darkTheme: MoabTheme.mainDarkModeData,
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
          ...textStories(),
          ...buttonStories(),
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
  AppThemeColorMode getColorMode() {
    final themeMode = context.watch<ThemeModeNotifier>().value;
    final brightness = themeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : themeMode == ThemeMode.light
            ? Brightness.light
            : Brightness.dark;
    return (brightness == Brightness.light)
        ? AppThemeColorMode.light
        : AppThemeColorMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveTheme(
      colorMode: getColorMode(),
      child: Scaffold(
        body: SafeArea(
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
