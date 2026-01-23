import 'package:flutter/material.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'color_circle.dart';
import 'simple_color_picker.dart';

void showColorPickerDialog({
  required BuildContext context,
  required Color? currentColor,
  required ValueChanged<Color> onPick,
}) {
  // Use routerKey context to ensure dialog shows over the app
  final dialogContext = routerKey.currentContext ?? context;

  showDialog(
    useRootNavigator: true,
    context: dialogContext,
    builder: (context) {
      final colors = [
        Colors.red,
        Colors.pink,
        Colors.purple,
        Colors.deepPurple,
        Colors.indigo,
        Colors.blue,
        Colors.lightBlue,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
        Colors.yellow,
        Colors.amber,
        Colors.orange,
        Colors.deepOrange,
        Colors.brown,
        Colors.grey,
        Colors.blueGrey,
        Colors.black,
        Colors.white,
      ];

      return DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: const Text('Pick Color'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Presets'),
                    Tab(text: 'Custom'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Presets
                      SingleChildScrollView(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: colors.map((c) {
                            return ColorCircle(
                              key: ValueKey('color-override-${c.toString()}'),
                              color: c,
                              isSelected: currentColor == c,
                              showLabel: false,
                              onTap: () {
                                onPick(c);
                                Navigator.of(context).pop();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      // Custom Selector
                      SimpleColorPicker(
                        initialColor: currentColor ?? Colors.blue,
                        onColorChanged: onPick,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
