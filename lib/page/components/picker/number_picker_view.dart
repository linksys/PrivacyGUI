import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:numberpicker/numberpicker.dart';

const double _kItemExtent = 32.0;

class NumberPickerView extends ConsumerStatefulWidget {
  const NumberPickerView(
      {Key? key,
      required this.title,
      required this.value,
      required this.min,
      required this.max,
      required this.step,
      required this.callback})
      : super(key: key);
  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged callback;

  @override
  ConsumerState<NumberPickerView> createState() => _NumberPickerViewState();
}

class _NumberPickerViewState extends ConsumerState<NumberPickerView> {
  int pickerNumber = 0;

  @override
  void initState() {
    super.initState();
    pickerNumber = widget.value;
    logger.d('minutes: $pickerNumber');
  }

  Future _showAndroidDialog(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
              child: Container(
                  color: Colors.black38,
                  height: 300,
                  width: 200,
                  child: AndroidPicker(
                    current: pickerNumber,
                    min: widget.min,
                    max: widget.max,
                    step: widget.step,
                    callback: (value) {
                      setState(() {
                        pickerNumber = value;
                        widget.callback(pickerNumber);
                      });
                    },
                  )));
        });
  }

  void _showIOSDialog() {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              // The Bottom margin is provided to align the popup above the system navigation bar.
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              // Provide a background color for the popup.
              color: CupertinoColors.systemBackground.resolveFrom(context),
              // Use a SafeArea widget to avoid system overlaps.
              child: SafeArea(
                top: false,
                child: IOSPicker(
                    current: pickerNumber,
                    min: widget.min,
                    max: widget.max,
                    step: widget.step,
                    callback: (value) {
                      setState(() {
                        pickerNumber = value;
                        widget.callback(pickerNumber);
                      });
                    }),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppText.bodyMedium(
        widget.title,
        color: const Color.fromRGBO(0, 0, 0, 0.2),
      ),
      const AppGap.small2(),
      TextButton(
          onPressed: () {
            if (Platform.isAndroid) {
              _showAndroidDialog(context);
            } else if (Platform.isIOS) {
              _showIOSDialog();
            }
          },
          style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 0)),
          child: Text(pickerNumber.toString(),
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: Colors.black))),
      const AppGap.small3(),
      Image.asset('assets/images/line.png')
    ]);
  }
}

class AndroidPicker extends ConsumerStatefulWidget {
  const AndroidPicker(
      {Key? key,
      required this.current,
      required this.min,
      required this.max,
      required this.step,
      required this.callback})
      : super(key: key);
  final int current;
  final int min;
  final int max;
  final int step;
  final ValueChanged callback;

  @override
  AndroidPickerState createState() => AndroidPickerState();
}

class AndroidPickerState extends ConsumerState<AndroidPicker> {
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    if (widget.current != _currentValue) {
      _currentValue = widget.current;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        NumberPicker(
          value: _currentValue,
          minValue: widget.min,
          maxValue: widget.max,
          onChanged: (value) => setState(() {
            _currentValue = value;
            widget.callback(_currentValue);
          }),
        ),
      ],
    );
  }
}

class IOSPicker extends ConsumerStatefulWidget {
  const IOSPicker(
      {Key? key,
      required this.current,
      required this.min,
      required this.max,
      required this.step,
      required this.callback})
      : super(key: key);
  final int current;
  final int min;
  final int max;
  final int step;
  final ValueChanged callback;

  @override
  ConsumerState<IOSPicker> createState() => _IOSPickerState();
}

class _IOSPickerState extends ConsumerState<IOSPicker> {
  late List<int> nums;

  @override
  void initState() {
    super.initState();
    nums = List.generate((widget.max - widget.min + 1) ~/ widget.step,
        (index) => index * widget.step + widget.min,
        growable: true);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController:
          FixedExtentScrollController(initialItem: widget.current),
      magnification: 1.22,
      squeeze: 1.2,
      useMagnifier: true,
      itemExtent: _kItemExtent,
      // This is called when selected item is changed.
      onSelectedItemChanged: (int selectedItem) {
        widget.callback(nums[selectedItem]);
      },
      children: List<Widget>.generate(nums.length, (int index) {
        return Center(
          child: Text(
            nums[index].toString(),
          ),
        );
      }),
    );
  }
}
