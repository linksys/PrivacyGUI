

import 'package:linksys_moab/network/mqtt/command_spec/impl/fake_spec.dart';

import '../mqtt_base_command.dart';

class CounterCommand extends MqttCommand {
  CounterCommand({required int counter})
      : super(spec: CounterCommandSpec(counter: counter));

  @override
  String get responseTopic => 'immediately/response';

  @override
  String get topic => 'immediately';

  @override
  Duration get responseTimeout => const Duration(seconds: 5);
}

class CounterDelay5Command extends CounterCommand {
  CounterDelay5Command({required super.counter});

  @override
  String get responseTopic => 'delay/5s/response';

  @override
  String get topic => 'delay/5s';
}

class CounterDelay10Command extends CounterCommand {
  CounterDelay10Command({required super.counter});

  @override
  String get responseTopic => 'delay/10s/response';

  @override
  String get topic => 'delay/10s';
}
