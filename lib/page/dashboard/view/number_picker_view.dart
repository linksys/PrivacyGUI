import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class NumberPickerView extends StatefulWidget {
  NumberPickerView(
      {Key? key,
      required this.title,
      required this.value,
      required this.min,
      required this.max,
      required this.step,
      required this.callback})
      : super(key: key);
  final String title;
  int value = 0;
  int min;
  int max;
  int step;
  ValueChanged callback;

  @override
  State<NumberPickerView> createState() => _NumberPickerViewState();
}

class _NumberPickerViewState extends State<NumberPickerView> {
  int pickerNumber = 0;

  @override
  void initState() {
    super.initState();
    pickerNumber = widget.value;
  }

  Future _showIntegerDialog(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.title, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 11),
      TextButton(
          onPressed: () => _showIntegerDialog(context),
          child: Text(pickerNumber.toString()),
          style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 0))),
      const SizedBox(height: 6),
      Image.asset('assets/images/line.png')
    ]);
  }
}

typedef ValueChanged<T> = void Function(T value);

class AndroidPicker extends StatefulWidget {
  AndroidPicker(
      {Key? key,
        required this.current,
      required this.min,
      required this.max,
      required this.step,
      required this.callback})
      : super(key: key);
  int current;
  int min;
  int max;
  int step;
  ValueChanged callback;

  @override
  AndroidPickerState createState() => AndroidPickerState();
}

class AndroidPickerState extends State<AndroidPicker> {
  int _currentValue = 0;


  @override
  void initState() {
    super.initState();
    if(widget.current != null && widget.current != _currentValue) {
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
