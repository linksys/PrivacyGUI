import 'package:flutter/material.dart';

class DayPickerView extends StatefulWidget {
  const DayPickerView({Key? key}) : super(key: key);

  @override
  State<DayPickerView> createState() => _DayPickerViewState();
}

class _DayPickerViewState extends State<DayPickerView> {
  Map<String, bool> days = {};

  @override
  void initState() {
    days['Su'] = false;
    days['Mo'] = false;
    days['Tu'] = false;
    days['We'] = false;
    days['Th'] = true;
    days['Fr'] = false;
    days['Sa'] = false;
    super.initState();
  }

  void changeStatus(String key) {
    setState(() {
      days[key] = !days[key]!;
    });
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
