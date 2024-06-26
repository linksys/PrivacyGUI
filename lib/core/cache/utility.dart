import 'package:privacy_gui/core/jnap/actions/better_action.dart';

const noCacheJNAPRegex = '(?:/Set)';

bool isMatchedJNAPNoCachePolicy(JNAPAction action) {
  RegExp exp = RegExp(noCacheJNAPRegex);
  return exp.hasMatch(action.actionValue);
}
