import 'dart:async';

import 'package:flutter/material.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart'
    as snackbar;
import 'package:privacy_gui/util/error_code_helper.dart';

mixin PageSnackbarMixin<T extends StatefulWidget> on State<T> {
  void showErrorMessageSnackBar(Object? error) {
    final errorMessage = switch (error.runtimeType) {
          JNAPError => errorCodeHelper(context, (error as JNAPError).result),
          TimeoutException => loc(context).generalError,
          _ => loc(context).unknownError,
        } ??
        loc(context).unknownErrorCode((error as JNAPError).result);

    showFailedSnackBar(errorMessage);
  }

  void showChangesSavedSnackBar() {
    showSuccessSnackBar(loc(context).changesSaved);
  }

  void showSharedCopiedSnackBar() {
    snackbar.showSimpleSnackBar(context, loc(context).sharedCopied);
  }

  void showSuccessSnackBar(String message) {
    snackbar.showSuccessSnackBar(context, message);
  }

  void showFailedSnackBar(String message) {
    snackbar.showFailedSnackBar(context, message);
  }
}
