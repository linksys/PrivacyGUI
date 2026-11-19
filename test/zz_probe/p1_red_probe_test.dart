// A probe for #1802 P1, never to be merged: a failing test must block a PR
// into dev-1.3.6 through ruleset "required checks (1.x)".
import 'package:test/test.dart';

void main() {
  test('fails on purpose', () => expect(1, 2));
}
