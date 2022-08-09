
import 'package:flutter/material.dart';
import 'package:linksys_moab/route/model/model.dart';

abstract class ArgumentsBaseStatefulView<T> extends StatefulWidget {
  final Map<String, T> args;
  const ArgumentsBaseStatefulView({Key? key, this.args = const {}}) : super(key: key);

}
abstract class ArgumentsBaseStatelessView<T> extends StatelessWidget {
  final Map<String, T> args;
  const ArgumentsBaseStatelessView({Key? key, this.args = const {}}) : super(key: key);

}
abstract class ArgumentsStatefulView extends ArgumentsBaseStatefulView<dynamic> {
  final BasePath? next;
  const ArgumentsStatefulView({Key? key, super.args, this.next}) : super(key: key);

}

abstract class ArgumentsStatelessView extends ArgumentsBaseStatelessView<dynamic> {
  final BasePath? next;
  const ArgumentsStatelessView({Key? key, super.args, this.next}) : super(key: key);

}
