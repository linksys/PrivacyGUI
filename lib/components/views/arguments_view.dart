import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// abstract class ArgumentsBaseStatefulView<T> extends ConsumerStatefulWidget {
//   final Map<String, T> args;
//   const ArgumentsBaseStatefulView({Key? key, this.args = const {}})
//       : super(key: key);
// }

// abstract class ArgumentsBaseStatelessView<T> extends ConsumerWidget {
//   final Map<String, T> args;
//   const ArgumentsBaseStatelessView({Key? key, this.args = const {}})
//       : super(key: key);
// }

// abstract class ArgumentsConsumerStatefulView
//     extends ArgumentsBaseStatefulView<dynamic> {
//   final BasePath? next;
//   const ArgumentsConsumerStatefulView({Key? key, super.args, this.next})
//       : super(key: key);
// }

// abstract class ArgumentsConsumerStatelessView
//     extends ArgumentsBaseStatelessView<dynamic> {
//   final BasePath? next;
//   const ArgumentsConsumerStatelessView({Key? key, super.args, this.next})
//       : super(key: key);
// }

abstract class ArgumentsBaseConsumerStatefulView<T>
    extends ConsumerStatefulWidget {
  final Map<String, T> args;
  const ArgumentsBaseConsumerStatefulView({Key? key, this.args = const {}})
      : super(key: key);
}

abstract class ArgumentsConsumerStatefulView
    extends ArgumentsBaseConsumerStatefulView<dynamic> {
  const ArgumentsConsumerStatefulView({
    Key? key,
    super.args,
  }) : super(key: key);
}

abstract class ArgumentsBaseConsumerStatelessView<T> extends ConsumerWidget {
  final Map<String, T> args;
  const ArgumentsBaseConsumerStatelessView({Key? key, this.args = const {}})
      : super(key: key);
}

abstract class ArgumentsConsumerStatelessView
    extends ArgumentsBaseConsumerStatelessView<dynamic> {
  const ArgumentsConsumerStatelessView({
    Key? key,
    super.args,
  }) : super(key: key);
}
