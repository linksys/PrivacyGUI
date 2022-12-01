import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/dashboard/view/_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/page/landing/view/_view.dart';
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
      theme: MoabTheme.mainLightModeData,
      darkTheme: MoabTheme.mainDarkModeData,
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      home: Scaffold(body: Center(child: child)),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Storybook(
        wrapperBuilder: linksysMaterialWrapper,
        initialStory: 'Screens/Scaffold',
        plugins: _plugins,
        stories: [
          Story(
            name: 'Screens/Scaffold',
            description: 'Story with scaffold and different knobs.',
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(
                  context.knobs.text(
                    label: 'Title',
                    initial: 'Scaffold',
                    description: 'The title of the app bar.',
                  ),
                ),
                elevation: context.knobs.nullable.slider(
                  label: 'AppBar elevation',
                  initial: 4,
                  min: 0,
                  max: 10,
                  description: 'Elevation of the app bar.',
                ),
                backgroundColor: context.knobs.nullable.options(
                  label: 'AppBar color',
                  initial: Colors.blue,
                  description: 'Background color of the app bar.',
                  options: const [
                    Option(
                      label: 'Blue',
                      value: Colors.blue,
                      description: 'Blue color',
                    ),
                    Option(
                      label: 'Green',
                      value: Colors.green,
                      description: 'Green color',
                    ),
                  ],
                ),
              ),
              body: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                    context.knobs.sliderInt(
                      label: 'Items count',
                      initial: 2,
                      min: 1,
                      max: 5,
                      description: 'Number of items in the body container.',
                    ),
                    (_) => const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Hello World!'),
                    ),
                  ),
                ),
              ),
              floatingActionButton: context.knobs.boolean(
                label: 'FAB',
                initial: true,
                description: 'Show FAB button',
              )
                  ? FloatingActionButton(
                      onPressed: () {},
                      child: const Icon(Icons.add),
                    )
                  : null,
            ),
          ),
          Story(
            name: 'Screens/Counter',
            description: 'Demo Counter app with about dialog.',
            builder: (context) => CounterPage(
              title: context.knobs.text(label: 'Title', initial: 'Counter'),
              enabled: context.knobs.boolean(label: 'Enabled', initial: true),
            ),
          ),
          Story(
            name: 'Widgets/Text',
            description: 'Simple text widget.',
            builder: (context) => const Center(child: Text('Simple text')),
          ),
          Story(
            name: 'Story/Nested/Multiple/Times/First',
            builder: (context) => const Center(child: Text('First')),
          ),
          Story(
            name: 'Story/Nested/Multiple/Times/Second',
            builder: (context) => const Center(child: Text('Second')),
          ),
          Story(
            name: 'Story/Nested/Multiple/Third',
            builder: (context) => const Center(child: Text('Third')),
          ),
          Story(
            name: 'Story/Nested/Multiple/Fourth',
            builder: (context) => const Center(child: Text('Fourth')),
          ),
          Story(
            name: 'Home view',
            builder: (context) => const HomeView(),
          ),
          Story(
            name: 'Outline Text',
            builder: (context) => Text(
              "1234567890",
              style: TextStyle(
                  inherit: true,
                  fontSize: 48.0,
                  color: Theme.of(context).backgroundColor,
                  shadows: [
                    Shadow(
                        // bottomLeft
                        offset: Offset(-1.5, -1.5),
                        color: Colors.white),
                    Shadow(
                        // bottomRight
                        offset: Offset(1.5, -1.5),
                        color: Colors.white),
                    Shadow(
                        // topRight
                        offset: Offset(1.5, 1.5),
                        color: Colors.white),
                    Shadow(
                        // topLeft
                        offset: Offset(-1.5, 1.5),
                        color: Colors.white),
                  ]),
            ),
          ),
          Story(
            name: 'Setting tiles',
            builder: (context) => SafeArea(
              child: Column(
                children: [
                  administrationSection(
                    title: 'Section tile header',
                    content: Column(
                      children: [
                        SettingTile(
                          title: Text('title'),
                          value: Switch.adaptive(value: false, onChanged: (value) {}),
                        ),
                        SettingTileTwoLine(
                          title: Text('title'),
                          value: Switch.adaptive(value: false, onChanged: (value) {}),
                        ),
                        SettingTileWithDescription(
                            title: Text('title'),
                            value: Switch.adaptive(value: false, onChanged: (value) {}),
                            description: Text('description')),
                      ],
                    ),
                  ),
                  SettingTileTwoLine(
                    title: Text('title'),
                    value: Switch.adaptive(value: false, onChanged: (value) {}),
                  ),
                  SettingTileWithDescription(
                      title: Text('title'),
                      value: Switch.adaptive(value: false, onChanged: (value) {}),
                      description: Text('description')),
                ],
              ),
            ),
          ),
        ],
      );
}

class CounterPage extends StatefulWidget {
  const CounterPage({
    Key? key,
    required this.title,
    this.enabled = true,
  }) : super(key: key);

  final String title;
  final bool enabled;

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  void _incrementCounter() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.help),
              onPressed: () => showAboutDialog(
                context: context,
                applicationName: 'Storybook',
                applicationVersion: '0.0.1',
                applicationIcon: const Icon(Icons.book),
                applicationLegalese: 'MIT License',
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
        floatingActionButton: widget.enabled
            ? FloatingActionButton(
                onPressed: _incrementCounter,
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              )
            : null,
      );
}
