// A read-only refusal reaches the user as its own message.
//
// Most save flows show a failure through errorCodeHelper. Without a case for the
// read-only code, a refused write would surface as "Unknown error
// (_ErrorReadOnlyMode)", which tells the user nothing about why.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/util/error_code_helper.dart';

import '../common/testable_router.dart';

void main() {
  testWidgets('the read-only code has its own message', (tester) async {
    String? message;
    await tester.pumpWidget(testableSingleRoute(
      child: Builder(builder: (context) {
        message = errorCodeHelper(context, errorReadOnlyMode);
        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle();

    expect(message, 'Unavailable in read-only mode');
  });
}
