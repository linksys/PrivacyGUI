import 'dart:convert';

import 'package:linksys_moab/network/model/command_spec/command_spec.dart';

abstract class FakeCommandSpec extends CommandSpec<Map<String, dynamic>> {
  @override
  Map<String, dynamic> response(String raw) {
    return json.decode(raw) as Map<String, dynamic>;
  }
}

class CounterCommandSpec extends FakeCommandSpec {
  final int counter;

  CounterCommandSpec({required this.counter});

  @override
  String payload() {
    return json.encode({
      'id': uuid,
      'counter': counter
    });
  }

}