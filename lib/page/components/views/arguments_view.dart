
import 'package:flutter/material.dart';

abstract class ArgumentsBaseStatefulView<T> extends StatefulWidget {
  final Map<String, T>? args;
  const ArgumentsBaseStatefulView({Key? key, this.args}) : super(key: key);

}
abstract class ArgumentsBaseStatelessView<T> extends StatelessWidget {
  final Map<String, T>? args;
  const ArgumentsBaseStatelessView({Key? key, this.args}) : super(key: key);

}
abstract class ArgumentsStatefulView extends ArgumentsBaseStatefulView<dynamic> {
  const ArgumentsStatefulView({Key? key, super.args}) : super(key: key);

}

abstract class ArgumentsStatelessView extends ArgumentsBaseStatelessView<dynamic> {
  const ArgumentsStatelessView({Key? key, super.args}) : super(key: key);

}