import 'package:collection/collection.dart';

enum RuleMode {
  init,
  adding,
  editing,
  ;

  static RuleMode reslove(String value) =>
      RuleMode.values.firstWhereOrNull((element) => element.name == value) ??
      RuleMode.init;
}
