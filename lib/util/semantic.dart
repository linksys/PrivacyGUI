import 'package:privacy_gui/core/utils/extension.dart';

enum SemanticIdentifierType {
  text,
  button,
  appSwitch,
  dialog,
  spinner,
  checkbox,
}

String semanticIdentifier(
    {required String tag,
    required String description}) {
  return 'now-$tag-$description'.kebab();
}
