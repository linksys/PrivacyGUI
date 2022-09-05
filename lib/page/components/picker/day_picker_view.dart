import 'package:flutter/material.dart';
import 'package:linksys_moab/utils.dart';

const List<String> weeklyId = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

class DayPickerView extends StatefulWidget {
  const DayPickerView({
    Key? key,
    this.weeklyBool = const [
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
    this.onChanged,
  }) : super(key: key);

  final List<bool> weeklyBool;
  final Function(List<bool> changed)? onChanged;

  @override
  State<DayPickerView> createState() => _DayPickerViewState();
}

class _DayPickerViewState extends State<DayPickerView> {
  Map<String, bool> days = {};

  @override
  void initState() {
    super.initState();
    days = widget.weeklyBool.asMap().map((key, value) => MapEntry(weeklyId[key], value));
  }

  void changeStatus(String key) {
    setState(() {
      days[key] = !days[key]!;
    });
    widget.onChanged?.call(List.from(days.values));
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var item in days.keys)
        Expanded(
            child: GestureDetector(
          child: Container(
              height: 46,
              margin: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                  color: days[item]!
                      ? const Color.fromRGBO(151, 151, 151, 1.0)
                      : Colors.transparent,
                  border: Border.all(
                      color: const Color.fromRGBO(0, 0, 0, 0.2), width: 1)),
              child: Center(
                  child: Text(item,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)))),
          onTap: () => changeStatus(item),
        ))
    ]);
  }
}
